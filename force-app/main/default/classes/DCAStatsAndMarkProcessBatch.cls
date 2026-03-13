/**
 * @author      Sachin Shetty
 * @description Pull the DCA stats and mark DRS records for processing
 * @group       Batch
 * @testclass   DCAStatsAndMarkProcessBatch_Test.cls
 * @revision    2022-09-14 - Sachin Shetty - Created
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.1   2024-01-31   Sachin Shetty   Logic to exclude contacts from being merged
 * 1.2   2024-02-15   Sachin Shetty   Added segmentation logic
 * 1.3   2024-02-23   Sachin Shetty   Fix for error - Too many DML rows: 10001
 *              
**/
public with sharing class DCAStatsAndMarkProcessBatch implements Database.Batchable<sObject>, Database.Stateful{
    public static final String ALUMNI_PORTAL_PERMISSION_SET = 'Alumni_Portal_Permission_Set';
    public static final String CUSTOMER_COMMUNITY_MY_APPLICATION = 'Customer_Community_My_Application';
    public static final String CUSTOMER_COMMUNITY_ASK_MONASH_STUDENT = 'Customer_Community_Ask_Monash_Student';
    public static final String NO_COMMUNITY_PERMISSIONSET = 'no community permissionset';
    public static final String ONE_COMMUNITY_PERMISSIONSET = 'one community permissionset';
    public static final String MYAPP_AND_ASKMONASH_PERMISSIONSET = 'myapp and askmonash permissionset';
    public static final String ADVANCEMENTS_SEGMENT = 'Contact_Profile__c INCLUDES(\'Alumni\',\'Alumni No Degree\')';
    public static final String PROSPECTIVE_STUDENTS_SEGMENT = 'Record_Type_Developer_Name__c = \'Prospective_Student\'';
    public static final String DUPLICATE_RULE_CONTACT_PERFECT_MATCH = 'Contact Perfect Match';
    public static final String DUPLICATE_RULE_CONTACT_POTENTIAL_MATCH = 'Contact Potential Match';

    public Integer noCommPermsetCount = 0;
    public Integer oneContactCommPermsetCount = 0;
    public Integer myappAskMonCount = 0;
    public Integer myappAlumCount = 0;
    public Integer alumAskMonCount = 0;
    public Integer allPermsCount = 0;
    public Integer excludedFromMergeCount = 0;
    public Integer inScopeDRSRecordsCount = 0;
    public Integer recordsMarkedForMergeCount = 0;
    public Map<Id,Map<Id,List<String>>> listOfpermsetsByContactIdBydrsId = new Map<Id,Map<Id,List<String>>>();
    public Set<Id> noCommPermsetDRSIds = new Set<Id>();
    public Set<Id> oneContactCommPermsetDRSIds = new Set<Id>();
    public Set<Id> myappAskMonashDRSIds = new Set<Id>();
    public String escapedDuplicateRuleName = '';
    
    public DCAStatsAndMarkProcessBatch() {
        noCommPermsetCount = 0;
        oneContactCommPermsetCount = 0;
        myappAskMonCount = 0;
        myappAlumCount = 0;
        alumAskMonCount = 0;
        allPermsCount = 0;
        excludedFromMergeCount = 0;
        inScopeDRSRecordsCount = 0;
        recordsMarkedForMergeCount = 0;
        listOfpermsetsByContactIdBydrsId = new Map<Id,Map<Id,List<String>>>();
        noCommPermsetDRSIds = new Set<Id>();
        oneContactCommPermsetDRSIds = new Set<Id>();
        myappAskMonashDRSIds = new Set<Id>();
    }

    /**
    * Implement start method (from interface) to create a query and return the QueryLocator
    */
    public Database.QueryLocator start(Database.BatchableContext BC) {
        escapedDuplicateRuleName = SandboxPostRefresh.escapeSoqlSpecialCharactersInLike(duplicateRuleName);
        String query = 'SELECT Id,(Select Id, RecordId from DuplicateRecordItems LIMIT 5) FROM DuplicateRecordSet WHERE (DuplicateRule.MasterLabel LIKE \''+escapedDuplicateRuleName+'\' OR Parent.Name LIKE \''+escapedDuplicateRuleName+'%\')AND RecordCount > 1';
        return Database.getQueryLocator(query);
    }

    /**
    * Implement execute method (from interface) to run the business logic
    */
    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        if (!scope.isEmpty()) {
            Set<Id> idsToMark = new Set<Id>();
            idsToMark = this.collectStats(scope);
            updateProcessField(idsToMark);
        }
    }

    /**
    * Implement finsh method (from interface) to wrap up processing.
    */
    public void finish(Database.BatchableContext BC) {
        this.printStats();
    }

    /**
     * @author      Sachin Shetty
     * @description Collect DCA stats before printing them
     * @param       scope - Duplicate Record Set records
     * @return      Set of DRS record ids to be flagged for processing
     * @revision    2022-09-14 - Sachin Shetty - Created
     *              2024-01-31 - Sachin Shetty - Logic to exclude contacts from being merged
     *              2024-02-26 - Sachin Shetty - Too many DML rows: 10001
     */
    public Set<Id> collectStats(List<SObject> scope){
        Map<Id,List<DuplicateRecordItem>> drsItemsBydrsId = new Map<Id,List<DuplicateRecordItem>>();
        Set<Id> drsIds = new Set<Id>();
        for(DuplicateRecordSet drsrecord: (List<DuplicateRecordSet>)scope){
            drsIds.add(drsrecord.Id);	
            drsItemsBydrsId.put(drsrecord.Id,drsrecord.DuplicateRecordItems);
        }
           
        Set<Id> contactIds = new Set<Id>();
        contactIds = this.getContactIds(drsIds);

        Map<Id, List<String>> psaListbyContactId = new Map<Id, List<String>>();
        psaListbyContactId = this.getPsaListbyContactId(contactIds);

        this.getListOfpermsetsByContactIdBydrsId(drsItemsBydrsId, psaListbyContactId);

        List<Contact> contatactsList = this.getContactRecords(contactIds);

        Map<String, String> perIdByConId = new Map<String, String>();
        perIdByConId = this.getPersonIdByConId(contatactsList);

        // Collect contact Ids marked to be excluded from merge
        Set<Id> mergeExcludedContactIds = this.getMergeExcludedContactIds(contatactsList);
        
        List<Id> drsRecordIds = new List<Id>(drsItemsBydrsId.keyset());
        
        Set<Id> idsToMark = new Set<Id>();
        idsToMark = this.prepareStats(drsRecordIds, perIdByConId, mergeExcludedContactIds);

        return idsToMark;
    }

    /**
     * @author      Sachin Shetty
     * @description Get the ContactIds associated with the DRS records
     * @param       drsIds - Duplicate Record Set Ids
     * @return      Set<Id>
     * @revision    2022-09-14 - Sachin Shetty - Created
     */
    public Set<Id> getContactIds(Set<Id> drsIds){
        Set<Id> contactIds = new Set<Id>();
        Map<Id, DuplicateRecordSet> mapOfDuplicateRecordSets = DM_DuplicateRecordSet.getMapOfDuplicateRecordSet(drsIds);
            
        for(DuplicateRecordSet drs : mapOfDuplicateRecordSets.values()){
            if(drs.duplicateRecordItems != null){
                for(DuplicateRecordItem dri : drs.duplicateRecordItems) {
                    contactIds.add(dri.recordId);
                }
            }
        }

        return contactIds;
    }

    /**
     * @author      Sachin Shetty
     * @description Get the map of permissionset assignment list by contact Ids
     * @param       contactIds - Set of contact ids associated with the DRS records
     * @return      Map<Id, List<String>> 
     * @revision    2022-09-14 - Sachin Shetty - Created
     */
    public Map<Id, List<String>> getPsaListbyContactId(Set<Id> contactIds){
        Map<Id, List<String>> psaListbyContactId = new Map<Id, List<String>>();

        for(List<PermissionSetAssignment> psaList : [SELECT PermissionSet.Name, Assignee.ContactId  FROM PermissionSetAssignment WHERE Assignee.ContactId IN:contactIds AND (PermissionSet.Name =:ALUMNI_PORTAL_PERMISSION_SET OR PermissionSet.Name =:CUSTOMER_COMMUNITY_MY_APPLICATION  OR PermissionSet.Name =:CUSTOMER_COMMUNITY_ASK_MONASH_STUDENT)]){
            for(PermissionSetAssignment psa : psaList){
                Id contactId = psa.Assignee.ContactId;
                if(!psaListbyContactId.containsKey(contactId)){
                    psaListbyContactId.put(contactId, new List<String>());
                }
                psaListbyContactId.get(contactId).add(psa.PermissionSet.Name);
            }
        }
        return psaListbyContactId;
    }

    /**
     * @author      Sachin Shetty
     * @description Get the map of permissionset assignment list by contact Ids by DRS record ids
     * @param       drsItemsBydrsId - Map of DuplicateRecordItem list by DuplicateRecordSet Id
     * @param       psaListbyContactId - Map of permissionset assignment list by contact Id
     * @return      void
     * @revision    2022-09-14 - Sachin Shetty - Created
     */
    public void getListOfpermsetsByContactIdBydrsId(Map<Id,List<DuplicateRecordItem>> drsItemsBydrsId, Map<Id, List<String>> psaListbyContactId){
        for(Id drsid : drsItemsBydrsId.keyset()){
            for(DuplicateRecordItem drsi : drsItemsBydrsId.get(drsid) ){
                if(!listOfpermsetsByContactIdBydrsId.containsKey(drsid)){
                    listOfpermsetsByContactIdBydrsId.put(drsid, new Map<Id,List<String>>());
                }
                if(psaListbyContactId.containsKey(drsi.RecordId)){
                    listOfpermsetsByContactIdBydrsId.get(drsid).put(drsi.RecordId, psaListbyContactId.get(drsi.RecordId));
                }
                else{
                    listOfpermsetsByContactIdBydrsId.get(drsid).put(drsi.RecordId, new List<String>());
                }
            }
        }
    }

    /**
     * @author      Sachin Shetty
     * @description Get the list on contacts
     * @param       contactIds - Set of contact Ids
     * @return      List<Contact>
     * @revision    2024-01-31 - Sachin Shetty - Created
     *              2024-02-15 - Sachin Shetty - Added segmentation logic
     */
    public List<Contact> getContactRecords(Set<Id> contactIds){
        List<Contact> contactsList = new List<Contact>();
        List<String> filterString = new List<String>();

        String searchString = 'SELECT Id, person_Id__c, Exclude_From_Merge__c FROM Contact WHERE ';
        if(!contactIds.isEmpty()){
            filterString.add('Id IN: contactIds');

            // Segmentation applicable only to 'Contact Potential Match'
            if(duplicateRuleName == DUPLICATE_RULE_CONTACT_POTENTIAL_MATCH){
            
                // Condition to process segments
                // Advancements segment
                if(segmentation == '1'){
                    filterString.add(ADVANCEMENTS_SEGMENT);
                }
                // Prospective Students segment - Inactive
                /*if(segmentation == '2'){
                    filterString.add(PROSPECTIVE_STUDENTS_SEGMENT);
                }*/
                else{
                    return contactsList;
                }
            }

            // All filter assembly
            for(String s: filterString) {
                searchString += s + ' AND ';
            }

            // Database query (Remove the last rouge 'AND')
            String finalQueryString = searchString.mid(0,searchString.lastIndexOf(' AND '));

            List<sObject> result = Database.query(finalQueryString);

            // Parsing to Contact sObject
            contactsList = (List<Contact>) result;
        }
        return contactsList;
    }

    /**
     * @author      Sachin Shetty
     * @description Get the map of contact Id by associated person Id
     * @param       contactsList - List of contact records
     * @return      Map<String, String>
     * @revision    2022-09-14 - Sachin Shetty - Created
     *              2024-01-31 - Sachin Shetty - Input parameter changed
     */
    public Map<String, String> getPersonIdByConId(List<Contact> contactsList){
        Map<String, String> perIdByConId = new Map<String, String>();
        for(Contact ct : contactsList){
            perIdByConId.put(ct.Id, ct.person_Id__c);
        }
        return perIdByConId;
    }

    /**
     * @author      Sachin Shetty
     * @description Collect contact Ids marked to be excluded from merge
     * @param       contactsList - List of contact records
     * @return      Map<String, String>
     * @revision    2024-01-31 - Sachin Shetty - Created
     */
    public Set<Id> getMergeExcludedContactIds(List<Contact> contactsList){
        Set<Id> contactIds = new Set<Id>();
        for(Contact contactRecord : contactsList){
            if(contactRecord.Exclude_From_Merge__c){
                contactIds.add(contactRecord.Id);
            }
        }
        return contactIds;
    }

    /**
     * @author      Sachin Shetty
     * @description Collect stats for each category
     * @param       drsRecordIds - List of DRS record ids
     * @param       perIdByConId - Map of contact Id by associated person Id
     * @param       mergeExcludedContactIds - Set of Contact Ids marked to be excluded from merge
     * @return      Set<Id>
     * @revision    2022-09-14 - Sachin Shetty - Created
     *              2024-01-31 - Sachin Shetty - Input parameter added, count of excluded contact ids
     *              2024-02-26 - Sachin Shetty - Too many DML rows: 10001
     */
    public Set<Id> prepareStats(List<Id> drsRecordIds, Map<String, String> perIdByConId, Set<Id> mergeExcludedContactIds){

        Set<String> contactIds = perIdByConId.keySet();
        Set<Id> idsToMark = new Set<Id>();
        List<String> lowerCaseCategories = new List<String>();
        lowerCaseCategories = getLowerCaseCategories();

        for(Integer i=0; i<drsRecordIds.size();i++){
            List<Id> conIds = new List<Id>(listOfpermsetsByContactIdBydrsId.get(drsRecordIds[i]).keySet());
            Map<Id,List<String>> permSetsByConIds = listOfpermsetsByContactIdBydrsId.get(drsRecordIds[i]);
            if(conIds.size() == 2 && (contactIds.contains(conIds[0]) || contactIds.contains(conIds[1]))){
                List<String> firstList = permSetsByConIds.get(conIds[0]);
                List<String> secondList = permSetsByConIds.get(conIds[1]);
                String personId1 = perIdByConId.get(conIds[0]);
                String personId2 = perIdByConId.get(conIds[1]);
                if(String.isNotBlank(personId1) && String.isNotBlank(personId2) && personId1 != personId2){
                    continue;
                }
                else{
                    // Count of DRS records with contact/s excluded from merging
                    if(mergeExcludedContactIds.contains(conIds[0]) || mergeExcludedContactIds.contains(conIds[1])){
                        excludedFromMergeCount++;
                        continue;
                    }
                    List<String> combinedCommPermSets = new List<String>();
                    if(firstList.isEmpty() && secondList.isEmpty()){
                        noCommPermsetCount++;
                        noCommPermsetDRSIds.add(drsRecordIds[i]);
                        // Collect DRS ids for update
                        if(lowerCaseCategories.contains(NO_COMMUNITY_PERMISSIONSET)){
                            idsToMark.add(drsRecordIds[i]);
                            recordsMarkedForMergeCount++;
                        }
                        inScopeDRSRecordsCount++;
                    }
                    
                    if((firstList.isEmpty() && !secondList.isEmpty()) || (!firstList.isEmpty() && secondList.isEmpty())){
                        oneContactCommPermsetCount++;
                        oneContactCommPermsetDRSIds.add(drsRecordIds[i]);
                        // Collect DRS ids for update
                        if(lowerCaseCategories.contains(ONE_COMMUNITY_PERMISSIONSET)){
                            idsToMark.add(drsRecordIds[i]);
                            recordsMarkedForMergeCount++;
                        }
                        inScopeDRSRecordsCount++;
                    }			
                                
                    if((firstList.contains(CUSTOMER_COMMUNITY_MY_APPLICATION) && secondList.contains(CUSTOMER_COMMUNITY_ASK_MONASH_STUDENT)) || 
                        (firstList.contains(CUSTOMER_COMMUNITY_ASK_MONASH_STUDENT) && secondList.contains(CUSTOMER_COMMUNITY_MY_APPLICATION))){
                        combinedCommPermSets.addAll(firstList);
                        combinedCommPermSets.addAll(secondList);
                        if(!combinedCommPermSets.contains(ALUMNI_PORTAL_PERMISSION_SET)){
                            myappAskMonCount++;
                            myappAskMonashDRSIds.add(drsRecordIds[i]);
                            // Collect DRS ids for update
                            if(lowerCaseCategories.contains(MYAPP_AND_ASKMONASH_PERMISSIONSET)){
                                idsToMark.add(drsRecordIds[i]);
                                recordsMarkedForMergeCount++;
                            }
                            inScopeDRSRecordsCount++;
                        }
                    }
                    if((firstList.contains(CUSTOMER_COMMUNITY_MY_APPLICATION) && secondList.contains(ALUMNI_PORTAL_PERMISSION_SET)) || (firstList.contains(ALUMNI_PORTAL_PERMISSION_SET) && secondList.contains(CUSTOMER_COMMUNITY_MY_APPLICATION))){
                        combinedCommPermSets.addAll(firstList);
                        combinedCommPermSets.addAll(secondList);
                        if(!combinedCommPermSets.contains(CUSTOMER_COMMUNITY_ASK_MONASH_STUDENT)){
                            myappAlumCount++;  
                        }
                    }
                    if((firstList.contains(ALUMNI_PORTAL_PERMISSION_SET) && secondList.contains(CUSTOMER_COMMUNITY_ASK_MONASH_STUDENT)) || (firstList.contains(CUSTOMER_COMMUNITY_ASK_MONASH_STUDENT) && secondList.contains(ALUMNI_PORTAL_PERMISSION_SET))){
                        combinedCommPermSets.addAll(firstList);
                        combinedCommPermSets.addAll(secondList);
                        if(!combinedCommPermSets.contains(CUSTOMER_COMMUNITY_MY_APPLICATION)){
                            alumAskMonCount++;
                        }
                    }
                    
                    if(!firstList.isEmpty() && !secondList.isEmpty()){
                        combinedCommPermSets.addAll(firstList);
                        combinedCommPermSets.addAll(secondList);
                        if(firstList.contains(ALUMNI_PORTAL_PERMISSION_SET) && secondList.contains(CUSTOMER_COMMUNITY_ASK_MONASH_STUDENT) && combinedCommPermSets.contains(CUSTOMER_COMMUNITY_MY_APPLICATION)){
                            allPermsCount++; 
                        }
                    }
                }
            }
        }

        return idsToMark;
    }
    
    /**
     * @author      Sachin Shetty
     * @description DuplicateConAutomationSetting__c to control the filters for Duplicate Automation records
     * @param       N/A
     * @return      DuplicateConAutomationSetting__c record
     * @revision    2022-09-14 - Sachin Shetty - Created
     */
    public static DuplicateConAutomationSetting__c dupSetting {
        get {
            if (dupSetting == null) {
                // look in custom setting
                dupSetting = DuplicateConAutomationSetting__c.getValues('DuplicateContactSetting');
            }
            return dupSetting;
        } set;
    }

    /**
     * @author      Sachin Shetty
     * @description Static reference to duplicateRuleName in the DuplicateConAutomationSetting__c custom setting
     * @param       N/A
     * @return      String
     * @revision    2022-09-14 - Sachin Shetty - Created
     */
    public static String duplicateRuleName {
        get {
            if (duplicateRuleName == null) {
                // if setting is not present, make default Contact Perfect Match
                duplicateRuleName = (
                    dupSetting != null
                    ? String.valueOf(dupSetting.duplicateRuleName__c != null 
                        ? dupSetting.DuplicateRuleName__c 
                        : DUPLICATE_RULE_CONTACT_PERFECT_MATCH)
                    : DUPLICATE_RULE_CONTACT_PERFECT_MATCH
                );
            }
            return duplicateRuleName;
        } set;
    }

    /**
     * @author      Sachin Shetty
     * @description Static reference to DRS_Categories_To_Be_Marked__c field in the DuplicateConAutomationSetting__c custom setting
     * @param       N/A
     * @return      List<String>
     * @revision    2022-09-14 - Sachin Shetty - Created
     */
    public static List<String> DRSCategories {
        get {
            if (DRSCategories == null) {
                String duplicateRecordCategories = dupSetting.DRS_Categories_To_Be_Marked__c;
                if(!String.isBlank(duplicateRecordCategories)){
                    DRSCategories = duplicateRecordCategories.split(',');
                }
            }
            return DRSCategories;
        } set;
    }
    
    /**
     * @author      Sachin Shetty
     * @description Method to convert categories to lower case categories
     * @param       N/A
     * @return      List<String>
     * @revision    2024-02-23 - Sachin Shetty - Created
     */
    public static List<String> getLowerCaseCategories() {
        List<String> lowerCaseCategories = new List<String>();
        if(DRSCategories != null){
            for(String category : DRSCategories){
                lowerCaseCategories.add(category.toLowerCase());
            }
        }
        return lowerCaseCategories;
    }

    /**
     * @author      Sachin Shetty
     * @description Static reference to Segmentation__c field in the DuplicateConAutomationSetting__c custom setting
     * @param       N/A
     * @return      String
     * @revision    2024-02-07 - Sachin Shetty - Created
     */
    public static String segmentation {
        get {
            if (segmentation == null) {
                // if setting is not present, make default blank
                segmentation = (
                    dupSetting != null
                    ? String.valueOf(dupSetting.Segmentation__c != null 
                        ? dupSetting.Segmentation__c 
                        : '')
                    : ''
                );
            }
            return segmentation;
        } set;
    }

    /**
     * @author      Sachin Shetty
     * @description Prints the stats
     * @param       N/A
     * @return      void
     * @revision    2022-09-14 - Sachin Shetty - Created
     *              2024-01-31 - Sachin Shetty - Count of excluded contact ids
     */
    public void printStats(){
        system.debug('Total Duplicate Record Sets :'+listOfpermsetsByContactIdBydrsId.size());
        system.debug('Total Duplicate Record Sets in-scope :'+inScopeDRSRecordsCount);
        system.debug('Total Duplicate Record Sets flagged for merge :'+recordsMarkedForMergeCount);
        system.debug('Duplicate Record Sets without any Community Permission List :'+noCommPermsetCount);
        system.debug('Duplicate Records Sets with My.App/ Alumni/ Ask.Monash :'+oneContactCommPermsetCount);
        system.debug('Duplicate Records Sets with My.App and Alumni :'+myappAlumCount);
        system.debug('Duplicate Records Sets with My.App and Ask.Monash :'+myappAskMonCount);
        system.debug('Duplicate Records Sets with Alumni and Ask.Monash :'+alumAskMonCount);
        system.debug('Duplicate Records Sets with My.App, Ask.Monash and Alumni :'+allPermsCount);
        system.debug('Duplicate Records Sets excluded from merging :'+excludedFromMergeCount);
    }

    /**
     * @author      Sachin Shetty
     * @description Mark Process__c field on DuplicateRecordSet for the supplied ids
     * @param       idsToMark - Set of DRS record ids whose Process__c field needs to be marked
     * @return      void
     * @revision    2022-09-14 - Sachin Shetty - Created
     */
    public void updateProcessField(Set<Id> idsToMark){
        if(idsToMark == null || idsToMark.isEmpty()) return;

        List<DuplicateRecordSet> drsRecords = [SELECT Id, Process__c FROM DuplicateRecordSet WHERE Id IN :idsToMark];

        for(DuplicateRecordSet drsRecord :drsRecords){
            drsRecord.Process__c = true;
        }
        update drsRecords;
    }
}