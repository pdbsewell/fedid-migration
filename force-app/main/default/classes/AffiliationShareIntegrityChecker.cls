/**
 * @description       : Checks Affiliations of sharing significance for integrity issues 
 * @author            : Peter Sewell
 * Modifications Log 
 * Date         Author          Modification
 * 2023-12-25 - Peter Sewell    Initial Version
 * 2023-01-31 - Peter Sewell    Resolvce gov. limit exception (run out of heap space)
**/
public without sharing class AffiliationShareIntegrityChecker implements Database.Batchable<SObject>, Database.Stateful {

    // Batch job id
    private String jobId;

    // Consts
    private static final string CACHE_NS = 'AFFILCHK'; // Pseudo namespace for session cache

    // Constructor params
    private Boolean checkInactiveAffiliations;  // If true, check that only active affiliations grant sharing
    private Boolean isRepairMode;               // If true run a check then a repair, otherwise check only


    // Two maps are used to accumulate contactshare and affiliation 'keys' (not to be confused with the composite keys)
    // These keys enable comparison of two sets in the finish method, keys are a composite of 'contactId,accountId,shareMode'.
    // Map values are ContactShare Id (in shareMap) and Affiliation__c Id (in affiliationMap)
    private Map<String, String> sharesMap;
    private Map<String, String> affiliationsMap;

    // Used in report generation to populate Group Name field
    private Map<Id, String> groupIdToGroupNameMap;

    // Datetime marker used as a filter such that affiliations created/modified after batch starts are not included
    private Datetime dateMarker;

    // Wrapper for affiliations and shares needing repair
    private class RepairManifest {
        Public Map<String, Affiliation__c> affiliations;
        Public Map<String, ContactShare> shares;
    }

    // Wrapper for cached summary results
    private class SummaryResults {
        Public Integer analysedElements;
        Public Integer discrepancies;

        SummaryResults(Integer e, Integer d) {
            analysedElements = e;
            discrepancies = d;
        }
    }

    // Wrapper for analysis status returned to LWC
    public class JobStatus {
        @AuraEnabled
        public String status;

        @AuraEnabled
        public Integer jobItemsProcessed;

        @AuraEnabled
        public Integer totalJobItems;

        @AuraEnabled
        public Integer elementsAnalysed;

        @AuraEnabled
        public Integer discrepancies;

        @AuraEnabled
        public String reportFileId;
    }
    
    // Constructor 
    //
    public AffiliationShareIntegrityChecker(Boolean isRepairMode, Boolean checkInactiveAffiliations) {
        this.isRepairMode = isRepairMode;
        this.checkInactiveAffiliations = checkInactiveAffiliations;
        this.sharesMap = new Map<String, String>();
        this.affiliationsMap = new Map<String, String>();
        this.groupIdToGroupNameMap = new Map<Id, String>();
        this.dateMarker = DateTime.now();
    }

    // Seed the batch with the 'universe' of partner-enabled account Group Ids 
    // Affiliations and contact shares of sharing significance will exist within this universe
    //
    public Database.QueryLocator start(Database.BatchableContext batchContext) {

        // Find all the groups auto created when an account is partner enabled 
        // These are what we are interested in analysing as all sharing is to one of these groups
        // The group has a relatedid referencing the account's Role, in turn associated with the 
        // partner-enabled account. i.e.
        // Partner Account->Role->Public Group
        // Affiliations link contact to the account, while the associated ContactShare links the contact the public group
        
        // Firstly round up all the roles of interest...
        List<Id> roleIds = new List<Id>();
        for (UserRole ur : [SELECT Id FROM UserRole WHERE DeveloperName LIKE '%PartnerUser']) {
            roleIds.add(ur.Id);
        }
        // ..then their associated public groups
        String query = 'SELECT Id, DeveloperName, relatedid ' +
                        'FROM Group ' +
                        'WHERE RelatedId IN :roleIds ' +
                        'ORDER by CreatedDate desc';
        query = test.isRunningTest() ? query + ' LIMIT 10' : query;
        return Database.getQueryLocator(query);
    }

    // For each Group Id find then accumulate the related and relevant affiliation and contactshares
    // storing the keys in the related map
    // 'key' in this case is contactid,accountid,sharelevel
    // and used for comparing sets of affiliations to contactshares
    public void execute(Database.BatchableContext batchContext, List<Group> scope) {
        
        // Store Job Id, we'll be using this in finish() to generate a unique Report File Title
        this.jobId = batchContext.getJobId();

        // Create a map of Group Id -> the associated partner-enabled Account Id 
        Map<Id, Id> partnerGroupIdToAccountIdMap = createPartnerGroupIdToAccountIdMap(scope);

        // Find and add relevant ContactShare keys to the global map
        // i.e. manual contact shares where the share is to one of the groups associated to a partner enabled account
        for (ContactShare cs : [SELECT Id, UserOrGroupId, ContactAccessLevel, ContactId
                                FROM ContactShare 
                                WHERE UserOrGroupId IN :partnerGroupIdToAccountIdMap.keyset() 
                                AND RowCause = 'Manual'
                                AND LastModifiedDate <= :this.dateMarker]) {
            Id partnerAccountId = partnerGroupIdToAccountIdMap.get(cs.UserOrGroupId);
            String comparisonKey = cs.ContactId + ',' + partnerAccountId + ',' + cs.ContactAccessLevel;
            this.sharesMap.put(comparisonKey, cs.Id);
        }

        // Find and add relevant affiliation keys to the global map
        // i.e. affiliations of sharing significance where the affiliation is to a partner enabled account
        for (Affiliation__c af : [SELECT Id, Contact__c, Account__c, Account__r.Name, Contact__r.Name, 
                                    Share_Contact_to_Account_Role__c, Share_Force_Recalculation__c,
                                    isActive__c, Is_Active__c, Composite_Key__c, Sharing_Composite_Key__c,
                                    RecordTypeId
                                  FROM Affiliation__c 
                                  WHERE Account__c IN :partnerGroupIdToAccountIdMap.values() 
                                  AND Share_Contact_to_Account_Role__c IN ('Read', 'Edit')
                                  AND LastModifiedDate <= :this.dateMarker]) {
            String comparisonKey = af.Contact__c + ',' + af.Account__c + ',' + getAffiliationShareComponent(af);          
            this.affiliationsMap.put(comparisonKey, af.Id);
        }

        // Add items to groupIdToGroupNameMap for later use in report genertation
        addItemsGroupIdToGroupNameMap(scope);
    }

    // Finish method is where we check the integrity of shares against affiliations
    // To do this we compare the keysets from our two maps - ContactShare vs Affiliations
    // 100% integrity requires the two sets be identical 
    // Differences need to be repaired
    //
    // To determine integrity we do a bit of ven diagramming
    //   S = set of contactshare keys
    //   A = set of affiliation keys
    //   Shares without a matching affiliation = S /\ A'
    //   Affiliations without a matching Share = A /\ S'
    //
    public void finish(Database.BatchableContext batchContext) {

        Integer elementsAnalysed = this.sharesMap.size() + this.affiliationsMap.size();
        RepairManifest toRepair = new RepairManifest();

        toRepair.shares = getContactSharesToRepair();
        toRepair.affiliations = getAffiliationsToRepair();

        this.sharesMap.clear();
        this.affiliationsMap.clear();

        // Remove any shares listed for deletion that are associated to: 
        // 1. An inactive affiliation (Inactive affils will be auto-deleted when the inactive affiliation is set to unshared) OR
        // 2. An affiliation with a bad composite or sharing key (we dont want to delete contact shares for these, just regenerate the keys)
        for (String afKey : toRepair.affiliations.keySet()) {
            if (afKey.endsWithIgnoreCase('Inactive') || afKey.endsWithIgnoreCase('BadKey')) {
                String regExp = '(?:Inactive|BadKey)';
                String csKey1 = afKey.replaceAll(regExp, 'Read');
                String csKey2 = afKey.replaceAll(regExp, 'Edit');
                toRepair.shares.remove(csKey1);
                toRepair.shares.remove(csKey2);
            }
        }

        if (this.isRepairMode) { 
            repairAffiliationsAndShares(toRepair);
        }

        createCSVFile(generateReportCSV(toRepair), 'AFFIL_INTEGRITY_REPORT_' + this.jobId);
        putCacheResultSummary(elementsAnalysed, toRepair);
    }

    // Repair actions:
    // 1. Delete orphaned ContactShares
    // 2. Remove sharing from "inactive" affiliations (which in turn auto deletes the ContactShare)
    // 3. Regenerate composite and sharing keys where there is a bad key
    // 4. (Re) Create ContactShares for orphaned Affiliations
    private void repairAffiliationsAndShares(RepairManifest toRepair) {
        Map<String, ContactShare> sharesToDelete = toRepair.shares;
        Map<String, Affiliation__c> affilsToUpdate = toRepair.affiliations;

        // 1. Delete orphaned ContactShares
        deleteContactShares(sharesToDelete.values());

        // Get and Repair Affiliations
        for (String affilKey : affilsToUpdate.keySet()) {
            Affiliation__c affiliationToRepair = affilsToUpdate.get(affilKey);
            // 2. Remove sharing
            if (affilKey.endsWithIgnoreCase('Inactive')) {
                affiliationToRepair.Share_Contact_to_Account_Role__c = 'No Sharing';  
            }
            // 3. Regenerate composite and sharing keys
            else if (affilKey.endsWithIgnoreCase('BadKey')) {
                if(isCompositeKeyInScope(affiliationToRepair)){
                    affiliationToRepair.Composite_Key__c = ContactPointUtility.getAffiliationKey(affiliationToRepair);
                }        
                affiliationToRepair.Sharing_Composite_Key__c = ContactPointUtility.getAffiliationSharingKey(affiliationToRepair);
            } 
            // 4. (Re) Create ContactShares
            else {
                affiliationToRepair.Share_Force_Recalculation__c = this.dateMarker;   
            }
        }
        updateAffiliationRecords(affilsToUpdate.values());
    }

    // Return map of ContactShares to repair (delete)
    private Map<String, ContactShare> getContactSharesToRepair() {
        Map<String, ContactShare> shares = new  Map<String, ContactShare>();

        // Create set of Ids of ContactShares needing repair (deletion)
        Map<Id, String> csIdsToDelete = new Map<Id, String> ();
        for (String csKey : this.sharesMap.keySet()) {
            if (!this.affiliationsMap.containsKey(csKey)) {
                csIdsToDelete.put(this.sharesMap.get(csKey), csKey);
            }
        }

        // Get the associated contactshare records and populate the map 
        for (ContactShare cs : [SELECT Id, ContactId, Contact.Name, UserOrGroupId, ContactAccessLevel
                               FROM ContactShare 
                               WHERE Id IN :csIdsToDelete.keySet()]) {
            shares.put(csIdsToDelete.get(cs.Id), cs);
        }

        return shares;
    }

    // Return map of Affiliations to repair (delete)
    private Map<String, Affiliation__c> getAffiliationsToRepair() {
        Map<String, Affiliation__c> affils = new  Map<String, Affiliation__c>();

        // Create set of Ids of Affiliations needing repair 
        Map<Id, String> afIdsToRepair = new Map<Id, String>();
        for (String afKey : this.affiliationsMap.keySet()) {
            if (!this.sharesMap.containsKey(afKey)) {
                afIdsToRepair.put(this.affiliationsMap.get(afKey), afKey);
            }
        }

        // Get the associated affiliation records and populate the map 
        for (Affiliation__c af : [SELECT Id, Contact__c, Account__c, Account__r.Name, Contact__r.Name, 
                                         Share_Contact_to_Account_Role__c, Share_Force_Recalculation__c,
                                         isActive__c, Is_Active__c, Composite_Key__c, Sharing_Composite_Key__c,
                                         RecordTypeId
                                  FROM Affiliation__c 
                                  WHERE Id IN :afIdsToRepair.keySet()]) {
            affils.put(afIdsToRepair.get(af.Id), af);
        }

        return affils;
    }

    // Return true if composite key is used for this affiliation type
    private static Boolean isCompositeKeyInScope(Affiliation__c affil) {
        Id applicantrecordTypeId = Schema.SObjectType.Affiliation__c.getRecordTypeInfosByName().get('Applicant').getRecordTypeId();
        if(applicantrecordTypeId == affil.RecordTypeId){
            return true;
        }    
        return false;
    }

    // Store summary of result in org cache
    private void putCacheResultSummary(Integer elementsAnalysed, RepairManifest toRepair) {
        Integer discrepanciesFound = toRepair.shares.size() + toRepair.affiliations.size();
        SummaryResults results = new SummaryResults(elementsAnalysed, discrepanciesFound);
        Cache.Org.put(CACHE_NS + this.jobId, results);
    }

    // Retrieve summary of result stored in org cache
    public static SummaryResults getCacheResultSummary(String jobId) {
        SummaryResults results = (SummaryResults)Cache.Org.get(CACHE_NS + jobId);
        return results;
    }

    // Create CSV file from CSV string
    private static void createCSVFile(String versionData, String title) {
        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';                   // denotes resides on Salesforce
        cv.Title = title;                       
        cv.PathOnClient = title + '.csv';    
        cv.VersionData = Blob.valueOf(versionData); //file data
        insert cv;
    }

    // Return the ContentDocumentId of the report file
    //
    private static Id getReportFileId(String jobId) {
        Id reportFileId = null;
        String title = 'AFFIL_INTEGRITY_REPORT_' + jobId;
        for (ContentDocument cd : [SELECT Id from ContentDocument WHERE Title = :title]){
            reportFileId = cd.Id;
        }
        return reportFileId;
    }

    // Create a CSV listing the integrity problems
    //
    private String generateReportCSV(RepairManifest toReport) {
        
        String reportCSVString = '';// The accumulated CSV string

        //  Generate header row
        List<String> headerRow = new  List<String>{
            'Entity',
            'Id',
            'Contact Id',
            'Contact Name',
            'Account or Group Id',
            'Account or Group Name',
            'Share Mode',
            'Composite Key',
            'Sharing Key (legacy)',
            'Integrity Problem',
            'Resolution'
        };
        reportCSVString += String.join(headerRow,',') + '\n';

        // Generate rows
        String rowTemplate = '"{0}","{1}","{2}","{3}","{4}","{5}","{6}","{7}","{8}","{9}","{10}"\n';
        String problem;
        String resolution;

        // Create Share rows
        for (String csKey : toReport.shares.keySet()) {
            ContactShare cs = toReport.shares.get(csKey);
            problem = 'No Valid Affiliation';
            resolution = 'Delete ContactShare';
            reportCSVString += String.format(rowTemplate, new List<Object> {
                'Contact Share',
                cs.Id,
                cs.ContactId,
                cs.Contact.Name,
                cs.UserOrGroupId,
                this.groupIdToGroupNameMap.get(cs.UserOrGroupId),
                cs.ContactAccessLevel,
                'N/A',
                'N/A',
                problem,
                resolution
            });
        }

        // Create Affiliation rows
        for (String afKey : toReport.affiliations.keySet()) {
            Affiliation__c af = toReport.affiliations.get(afKey);
            
            if (afKey.endsWithIgnoreCase('Inactive')) {
                problem = 'Inactive Affiliation is Shared';
                resolution = 'Set Affiliation to No Sharing';
            } else if (afKey.endsWithIgnoreCase('BadKey')) {
                problem = 'Affiliation has Bad Key';
                resolution = 'Regenerate Keys';
            } else {
                problem = 'Affiliation has no ContactShare';
                resolution = 'Regenerate ContactShare';
            }

            reportCSVString += String.format(rowTemplate, new List<Object> {
                'Affiliation',
                af.id,
                af.Contact__c,
                af.Contact__r.Name,
                af.Account__c,
                af.Account__r.Name,
                af.Share_Contact_to_Account_Role__c,
                af.Composite_Key__c,
                af.Sharing_Composite_Key__c,
                problem,
                resolution
            });            
        }

        // Remove trailing \n
        return reportCSVString.substring(0, reportCSVString.length() - 1);
    }

    // Delete the ContactShares
    //
    public void deleteContactShares(List<ContactShare> recordsToDelete) {
    
        Database.DeleteResult[] deleteResults = Database.delete(recordsToDelete, false);

        for (Integer i = 0; i < deleteResults.size(); i++) {
            if (!deleteResults[i].isSuccess()) {
                // Log an error message for the failed delete
                for (Database.Error error : deleteResults[i].getErrors()) {
                    LogUtilityException.logExceptionMSG(
                        'ContactShare', 
                        recordsToDelete[i].Id, 
                        'Failed to delete record with Id ' + recordsToDelete[i].Id +'. Error message: ' + error.getMessage()
                    );
                }
            }
        }
    }

    // Update the Affiliations
    //
    public void updateAffiliationRecords(List<Affiliation__c> recordsToUpdate) {
        
        Database.SaveResult[] updateResults = Database.update(recordsToUpdate, false);

        for (Integer i = 0; i < updateResults.size(); i++) {
            if (!updateResults[i].isSuccess()) {
                // Log an error message for the failed update
                for (Database.Error error : updateResults[i].getErrors()) {
                    LogUtilityException.logExceptionMSG(
                        'Affiliation__c', 
                        recordsToUpdate[i].Id, 
                        'Failed to update record with Id ' + recordsToUpdate[i].Id +'. Error message: ' + error.getMessage()
                    );
                }
            }
        }
    }

    // Create map of partner enabled account Group Id -> associated Account id
    //
    private static Map<Id, Id> createPartnerGroupIdToAccountIdMap(List<Group> grps) {
        Map<Id, Id> partnerGroupIdToAccountIdMap = new Map<Id, Id>();
        Map<Id, Id> partnerGroupIdToRoleIdMap = createMapPartnerGroupIdToRoleId(grps);
        Map<Id, Id> partnerRoleIdToAccountIdMap = createMapPartnerRoleIdToAccountId(partnerGroupIdToRoleIdMap.values());

        for (Group grp : grps) {
            Id partnerAccountId = partnerRoleIdToAccountIdMap.get(partnerGroupIdToRoleIdMap.get(grp.Id));
            if (partnerAccountId == null) {
                continue;
            }
            partnerGroupIdToAccountIdMap.put(grp.Id, partnerAccountId);
        }
        return partnerGroupIdToAccountIdMap;
    }

    // Create map of partner enabled account Group Id -> associated Role id
    //
    private static Map<Id, Id> createMapPartnerGroupIdToRoleId(List<Group> grps) {
        Map<Id, Id> partnerGroupIdToRoleIdMap = new Map<Id, Id>();
        for (Group grp : grps) {
            partnerGroupIdToRoleIdMap.put(grp.Id, grp.RelatedId);
        }
        return partnerGroupIdToRoleIdMap;
    }

    // Create map of partner-enabled account Role Id -> associated Account Id
    //
    private static Map<Id, Id> createMapPartnerRoleIdToAccountId(List<Id> roleIds) {
        Map<Id, Id> partnerRoleIdToAccountIdMap = new  Map<Id, Id>();
        for (UserRole role : [SELECT Id, PortalAccountId FROM UserRole WHERE Id IN :roleIds AND PortalAccountId <> null]) {
            partnerRoleIdToAccountIdMap.put(role.Id, role.PortalAccountId);
        }
        return partnerRoleIdToAccountIdMap;
    }

    // Add items to the groupIdToGroupNameMap for later use in report genertation
    //
    private void addItemsGroupIdToGroupNameMap(List<Group> groups) {
        for (Group grp : groups) {
            this.groupIdToGroupNameMap.put(grp.Id, grp.DeveloperName);
        }
    }

    // Return share component of the affiliation key, taking into account if 
    // checkInactiveAffiliations is enabled
    //
    private String getAffiliationShareComponent(Affiliation__c affil) {
        Boolean isAffilActive = isAffiliationActive(affil);
        Boolean isGoodKey = isGoodCompositeKey(affil);

        if (!isAffilActive) {
            return 'Inactive';
        }

       if (!isGoodKey) {
            return 'BadKey';
        }

        return affil.Share_Contact_to_Account_Role__c;
    }

    // Return true if affiliation is active
    //
    private Boolean isAffiliationActive(Affiliation__c affil) {
        // Effectively active if batch is running in ignore active flag mode
        if (!this.checkInactiveAffiliations) {
            return true;
        }
        // Both active flags must be active for affil to be considered active
        return affil.isActive__c && affil.Is_Active__c;
    }

    // Return true if affiliation has both a good composite key (legacy) and a good sharing composite key
    //
    private Boolean isGoodCompositeKey(Affiliation__c affil) {

        // Composite_Key__c only in scope where affiliation record type is Applicant
        if ((isCompositeKeyInScope(affil)) && 
            (affil.Composite_Key__c != ContactPointUtility.getAffiliationKey(affil))) {
            return false;
        }
        // Sharing Composite Key in scope for all record types
        if (affil.Sharing_Composite_Key__c != ContactPointUtility.getAffiliationSharingKey(affil)) {
            return false;
        }
        return true;
    }

    // Start the batch job 
    //
    @AuraEnabled(cacheable=false)
    public static String startBatchJob(Boolean isRepairMode, Boolean checkInactiveAffiliations) {
        Boolean repairMode = isRepairMode == null ? false : isRepairMode;
        Boolean checkInactiveAffils = checkInactiveAffiliations == null ? false : checkInactiveAffiliations;
        AffiliationShareIntegrityChecker batchJob = new AffiliationShareIntegrityChecker(repairMode, checkInactiveAffils);
        return Database.executeBatch(batchJob, 200);
    }

    // Query job status
    //
    @AuraEnabled(cacheable=false)
    public static JobStatus getBatchJobStatus(String jobId) {
        JobStatus js = new JobStatus();
        try {
            // Get status of Async Job
            AsyncApexJob j = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, ExtendedStatus FROM AsyncApexJob WHERE Id = :jobId];
            js.status = j.Status; // default status is the status field pulled from AsyncApexJob object
            js.jobItemsProcessed = j.JobItemsProcessed;
            js.totalJobItems = j.TotalJobItems;

            // From the calling LWC perspective, status is not 'completed'
            // until the disprepancy results are available from org cache 
            // AND the report file is availailable to download
            if (j.Status == 'Completed' ) {
                SummaryResults results = AffiliationShareIntegrityChecker.getCacheResultSummary(jobId);
                js.discrepancies = results?.discrepancies;   
                js.elementsAnalysed = results?.analysedElements;   
                js.reportFileId = AffiliationShareIntegrityChecker.getReportFileId(jobId);          
                // check if discrepancy stats are in cache and report file is available
                if (js.discrepancies == null || js.reportFileId == null) {
                    js.status = 'Getting results'; // If not, change status
                } 
            }  
        } catch(DmlException e) {
            LogUtilityException.logException(e,'Could not retrieve batch job: ' + jobId);
        }
        return js;
    }
}