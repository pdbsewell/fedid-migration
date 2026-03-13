/*******************************************************************************
* @author       Shalini Mendu
* @date         27/03/2023
* @description  Create/Update/Delete services for Affiliation__c records
* @Revision     09/02/2024 - SMen- Removed deprecated methods
                             Added new methods
*********************************************************************************/
/**
 * TODO: 
 * TECH DEBT # 1
 *  Composite Key in Affiliation is a new field introduced to accommodate for similar contact > account combinations
 *  but for a different record type. This is only being actively populated within Contact Merge Tool but is not yet
 *  being set withing AffiliationTrigger (most records are still blank) + the data load step required to cutover
 *  because of this, we will have to query existing Affiliations using Contact > Account > RecordTypeId combination,
 *  rather than the composite key. Once this is resolved, Tech debt#2 can be done.
 * TECH DEBT # 2
 *  we are unable to use the external id to run an upsert at this stage
 *  because we don't want to overwrite the Affiliation start date with today()
 *  if they already exist. Ideally, blank start dates should be prepopulated in AffiliationTrigger,
 *  but since that isn't in place yet, we will have to work around that.
 *  Once Affiliation Start Date is being defaulted, this can be simplified to:
 *  - transpose Application into an Affiliation
 *  - do not populate Start Dates to prevent inadvertently updating them with today()
 *  - if start date is blank, affiliation trigger will default it to today(); and
 *  - existing Affiliation Start Dates will never be overwritten
 */
public class AffiliationManageService {

    public static final Id AFFILIATION_RECORDTYPE_APPLICANT = Schema.SObjectType.Affiliation__c.getRecordTypeInfosByDeveloperName()
                                                            .get('Applicant')
                                                            .getRecordTypeId();

    public AffiliationManageService() {}

    /**
    * @description insert or update affiliations based on Application details
    * @author Nick Guia | 25-08-2023 
    * @param List<Application__c> app 
    **/
    public void upserAffiliationsFromApplication(List<Application__c> appList) {
        if(appList == null) {
            throw new AffiliationManageServiceDeveloperException('Invalid null parameter :' + appList);
        }

        // STEP 1: collect the list of contact and account IDs to query existing Affiliations
        ApplicationContactAccountCollection collection = collectContactAndAccountIds(appList);

        // STEP 2 : query existing Affiliations based on the collection (Tech Debt #1)
        Map<String, Affiliation__c> existingAffiliationsByCompositeKey = new Map<String, Affiliation__c>();
        for(Affiliation__c iAff : selectAffiliations(collection.contactIds, collection.accountIds)) {
            // assume Composite Key is blank
            iAff.Composite_Key__c = ContactPointUtility.getAffiliationKey(iAff);
            existingAffiliationsByCompositeKey.put(iAff.Composite_Key__c, iAff);
        }
        System.debug('collection=='+collection);
        // STEP 3 : transpose each application into an affiliation and check if they already exist via the composite key mapping
        List<Affiliation__c> insertAffiliationList = new List<Affiliation__c>();
        List<Affiliation__c> updateAffiliationList = new List<Affiliation__c>();

        for(Application__c app : appList) {

            /**
             * always build a new Affiliation in memory to run an insert or update.
             * this allows us to build the external key based on the centralised rules
             * within ContactPointUtility.getAffiliationKey()
             */
            System.debug('appList=='+app);
            Affiliation__c newAff = new Affiliation__c();
            newAff.Contact__c = app.Applicant__c;
            newAff.Account__c = app.Agent__c;
            newAff.RecordTypeId = AFFILIATION_RECORDTYPE_APPLICANT;
            newAff.Composite_Key__c = ContactPointUtility.getAffiliationKey(newAff);
            newAff.Is_Active__c = true;
            newAff.Roles__c = getSourceSystem(app);
            newAff.Share_Contact_to_Account_Role__c = getAccessLevel(app);
            System.debug('updateAffiliationList=='+updateAffiliationList);
            System.debug('insertAffiliationList=='+insertAffiliationList);

            // if already exists, update; otherwise, populate start date and insert
            if(existingAffiliationsByCompositeKey.containsKey(newAff.Composite_Key__c)) {
                newAff.Id = existingAffiliationsByCompositeKey.get(newAff.Composite_Key__c).Id;
                updateAffiliationList.add(newAff);
            } else {
                newAff.Start_Date__c = System.today();
                insertAffiliationList.add(newAff);
            }
        }

        try {
            if(!insertAffiliationList.isEmpty()) {
                insert insertAffiliationList;
            }
    
            if(!updateAffiliationList.isEmpty()) {
                update updateAffiliationList;
            }
        } catch(Exception e) {
            throw new AffiliationManageServiceException('Unable to Insert or Update Affiliations : ' + e.getMessage());
            // catch the exception on your main class and log
        }
    }

    /**
    * @description ogic to decide the role that will be assigned to the Affiliation
    * @author Nick Guia | 25-08-2023 
    * @param Application__c app 
    * @return String 
    **/
    @TestVisible
    private String getSourceSystem(Application__c app) {
        // works for hybrid
        return (app.Source_System__c == 'Partner') ? 'Partner' : 'Agent';
    }

    /**
    * @description logic to decide the sharing privileges that will be assigned to the user
    * @author Nick Guia | 25-08-2023 
    * @param Application__c app 
    * @return String 
    **/
    @TestVisible
    private String getAccessLevel(Application__c app) {
        //Add affiliations with WRITE access - for fresh applications before submission
        return (app.Callista_Application_Id__c == null) ? AffiliationTriggerHandler.EDIT_SHARE : AffiliationTriggerHandler.READ_SHARE;
    }

    /**
    * @description retrieve contact and account IDs from Applications
    * @author Nick Guia | 25-08-2023 
    * @param List<Application__c> appList 
    * @return ApplicationContactAccountCollection 
    **/
    @TestVisible
    private ApplicationContactAccountCollection collectContactAndAccountIds(List<Application__c> appList) {
        ApplicationContactAccountCollection collection = new ApplicationContactAccountCollection();

        for(Application__c iApp : appList) {
            collection.contactIds.add(iApp.Applicant__c);
            collection.accountIds.add(iApp.Agent__c);
        }
        return collection;
    }

    /**
    * @description query existing affiliations (Tech Debt#1)
    * @author Nick Guia | 25-08-2023 
    * @param Set<Id> contactIds 
    * @param Set<Id> accountIds 
    * @return List<Affiliation__c> 
    **/
    @TestVisible
    private List<Affiliation__c> selectAffiliations(Set<Id> contactIds, Set<Id> accountIds) {
        return [SELECT Id, Contact__c, Account__c, Share_Contact_to_Account_Role__c, Is_Active__c, Roles__c, Start_Date__c, RecordTypeId, Composite_Key__c
                FROM Affiliation__c
                WHERE Contact__c IN :contactIds 
                AND Account__c IN :accountIds
                AND RecordTypeId = :AFFILIATION_RECORDTYPE_APPLICANT];
    }

    @TestVisible
    private class ApplicationContactAccountCollection {
        Set<Id> contactIds { get; set; }
        Set<Id> accountIds { get; set; }

        public ApplicationContactAccountCollection() {
            this.contactIds = new Set<Id>();
            this.accountIds = new Set<Id>();
        }
    }

   
    /**
    * @description Build No Sharing Affiliation__c object from
    * the provided Application__c fields
    * @author Shalini Mendu | 09-02-2024 
    * @param Applicaiton__c app 
    * @return Affiliation__c 
    **/
    public Affiliation__c removeAgencyAccessFromApplication(Application__c app)
    {
       //Set default values on the Affiliation__c
        Affiliation__c aff = setApplicantRecordTypeAffiliationDefaults(app);
        //Update Affiliation__c record
        aff.Is_Active__c = false;
        aff.Share_Contact_to_Account_Role__c = NO_ACCESS_LEVEL;
        aff.End_date__c = System.today();
        return aff;
    }

     /**
    * @description Set default values which are used as a utility on Affiliation__c
    * @author Shalini Mendu | 09-02-2024 
    * @param Applicaiton__c app 
    * @return Affiliation__c 
    **/
    public Affiliation__c setApplicantRecordTypeAffiliationDefaults(Application__c app)
    {
        //Update field values on Affiliation__c
        Affiliation__c aff = new Affiliation__c();
        aff.Contact__c = app.Applicant__c;
        aff.Account__c = app.Agent__c;
        aff.RecordTypeId = AFFILIATION_RECORDTYPE_APPLICANT;
        new AffiliationService().populateCompositeKey(aff);
        aff.Roles__c = getSourceSystem(app);
        return aff;
    }

    /**
    * @description Build READ Sharing Affiliation__c object from
    * the provided Application__c fields
    * @author Shalini Mendu | 09-02-2024 
    * @param Applicaiton__c app 
    * @return Affiliation__c 
    **/
    public Affiliation__c createAgencyAccessFromApplication(Application__c app)
    {
        Affiliation__c aff = setApplicantRecordTypeAffiliationDefaults(app);
        aff.Is_Active__c = true;
        aff.Share_Contact_to_Account_Role__c = READ_ACCESS_LEVEL;
        aff.End_date__c = null;
        return  aff;
    }

    public static final Boolean ACTIVE_STATUS = true;
    public static final Boolean INACTIVE_STATUS = false;
    public static final String WRITE_ACCESS_LEVEL = 'Edit';
    public static final String READ_ACCESS_LEVEL = 'Read';
    public static final String NO_ACCESS_LEVEL = 'No Sharing';
    public static final String PARTNER_LEVEL = 'Partner';
    public static final String AGENT_LEVEL = 'Agent';

    public class AffiliationManageServiceException extends Exception {}

    public class AffiliationManageServiceDeveloperException extends Exception {}
}