/**
 * @description       : Service class for the data entity preparation and merge process for each of the Duplicate Record Set records.
 * @author            : Sheeba T
 * @group             : Service class
 * @last modified on  : 2022-06-09
 * @last modified by  : Sachin shetty
 * Modifications Log 
 * Ver   Date         Author   Modification
 * 1.0   2022-02-10   Sheeba   Initial Version 
 * 1.1   2022-06-09   Sachin   Code refactor 
 * 1.2   2024-02-23   Sachin   Fix for error - Too many DML rows: 10001
**/
public with sharing class DuplicateRecordSetService {
    
    //Limits.getEmailInvokations asserts to be 0 in the testclass even if invoked in the same context. Hence the static variable emailLimitsUsed is used instead.
    @TestVisible static Integer emailLimitsUsed = 0;

    /**
     * Method Name     handleDuplicates
     * description     Core method to process the Duplicate Record Set records and publish next set of platform events to sequence merge methods.                 
     */
    public static void handleDuplicates(Set<Id> drsIds){

        String uniqueID = getUniqueId();
        
        Integer counter = 0;
        Map<Id, List<ContactMergeData>> mapOfEntityDataByDrs = getMapOfEntityDataByDrs(drsIds);
        Integer totalRecordCount = mapOfEntityDataByDrs.keyset().size();

        String logMessage = '';
        //Unique Id
        //CurrentCount 
        for(Id drsId : mapOfEntityDataByDrs.keySet()){
            counter++;
            List<ContactMergeData> entitydl = mapOfEntityDataByDrs.get(drsId);
            ContactMergeData primaryEntity;
            
            // user id containers
            Id primaryUserId;
            List<Id> primaryPermSetIds = new List<Id>();
            Id duplicateUsers;
            List<Id> duplicatePermSetIds = new List<Id>();
            List<ContactMergeController.MergeUserWrapper> dupUserNames = new List<ContactMergeController.MergeUserWrapper>();
            Set<Id> userIdAskMonash = new Set<Id>();
            // account id containers
            Id primaryAccountId;
            Id duplicateAccountIds;
            // contact id containers
            Id primaryContactId;
            Id duplicateContactIds;
            String primaryPersonId;
            String duplicatePersonId;

            // Exclude contacts from merge
            String primaryContactMergeExcluded;
            String duplicateContactMergeExcluded;

            // Advancements segmentation(Contacts with 'Contact Profile' values 'Alumni' or 'Alumni No Degree')
            String primaryContactProfile;
            String duplicateContactProfile;

            Boolean mergeUser;

            //For each entity's primary and duplicate information, proceed with User/Account/Contact merge
            for(ContactMergeData cmd : entitydl){
                if (cmd.isPrimary) {
                    // identity primary entity
                    primaryEntity = cmd;
                    // identity primary user and permission sets
                    if (cmd.userRecord != null) {
                        primaryUserId = cmd.userRecord.Id;
                        primaryPermSetIds = cmd.permissionSetIds;
                    }

                    // identify primary account
                    primaryAccountId = cmd.accountRecord.Id;

                    // identify primary contact
                    primaryContactId = cmd.contactRecord.Id;
                    primaryPersonId = cmd.contactRecord.person_Id__c;

                    // identify merge exclusion on primary contact
                    primaryContactMergeExcluded = cmd.excludedFromMerge;

                    // contact profile on primary contact
                    primaryContactProfile = cmd.contactRecord.Contact_Profile__c;
                } else {
                    // identify duplicate users and permission sets
                    if (cmd.userRecord != null) {
                        duplicateUsers = cmd.userRecord.Id;
                        //duplicateUsers.add(cmd.userRecord.Id);
                        duplicatePermSetIds = cmd.permissionSetIds;
                        //Checks for ASkMonash on Duplicates to exclude
                        
                        if(cmd.communityAccesses.size() == 1){
                            if(cmd.communityAccesses.contains('Ask Monash')){
                                userIdAskMonash.add(cmd.userRecord.Id);
                            }
                        }
                    }

                    // identify duplicate accounts
                    duplicateAccountIds = cmd.accountRecord.Id;

                    // identify duplicate contacts
                    duplicateContactIds = cmd.contactRecord.Id;
                    duplicatePersonId = cmd.contactRecord.person_Id__c;

                    // identify merge exclusion on duplicate contact
                    duplicateContactMergeExcluded = cmd.excludedFromMerge;

                    // contact profile on duplicate contact
                    duplicateContactProfile = cmd.contactRecord.Contact_Profile__c;
                }
            }
            if(primaryPersonId != null && primaryPersonId != '' && duplicatePersonId != null && duplicatePersonId != '' && primaryPersonId != duplicatePersonId){
                logMessage = 'Contact : DuplicateRecordSetService : Different person Ids found for Contacts. Remove from merge automation - primaryPersonId: ' + primaryPersonId + ' duplicatePersonId : ' + duplicatePersonId + ': DuplicateRecordSetService.handleDuplicates';
                Nebula.Logger.info(logMessage, drsId);
                LogUtilityException.addLogEvent('Contact', 'DuplicateRecordSetService', 'Different person Ids found for Contacts. Remove from merge automation - primaryPersonId: ' + primaryPersonId + ' duplicatePersonId : ' + duplicatePersonId , 'DuplicateRecordSetService.handleDuplicates');
            }
            else if(primaryContactMergeExcluded == 'Yes' || duplicateContactMergeExcluded == 'Yes'){
                logMessage = 'Contact : DuplicateRecordSetService : Contact excluded from merge. Remove from merge automation - primarycontactId: ' + primaryContactId + ' duplicateContactIds : ' + duplicateContactIds + ': DuplicateRecordSetService.handleDuplicates';
                Nebula.Logger.info(logMessage, drsId);
                LogUtilityException.addLogEvent('Contact', 'DuplicateRecordSetService', 'Contact excluded from merge. Remove from merge automation - primarycontactId: ' + primaryContactId + ' duplicateContactIds : ' + duplicateContactIds , 'DuplicateRecordSetService.handleDuplicates');
            }
            // Segmentation applicable only to 'Contact Potential Match' duplicate rule
            else if(duplicateRuleName == constants.DUPLICATE_RULE_CONTACT_POTENTIAL_MATCH && segmentation != '1'){ // Processing only advancements(alumni) records
                logMessage = 'Contact : DuplicateRecordSetService : Not Processing non-advancements(alumni) records. Remove from merge automation - primarycontactId: ' + primaryContactId + ' duplicateContactIds : ' + duplicateContactIds + ': DuplicateRecordSetService.handleDuplicates';
                Nebula.Logger.info(logMessage, drsId);
                LogUtilityException.addLogEvent('Contact', 'DuplicateRecordSetService', 'Not Processing non-advancements(alumni) records. Remove from merge automation - primarycontactId: ' + primaryContactId + ' duplicateContactIds : ' + duplicateContactIds , 'DuplicateRecordSetService.handleDuplicates');
            }
            else if(duplicateRuleName == constants.DUPLICATE_RULE_CONTACT_POTENTIAL_MATCH && segmentation == '1' && !(((primaryContactProfile != null) && primaryContactProfile.contains('Alumni')) || ((duplicateContactProfile != null) && duplicateContactProfile.contains('Alumni')))){
                logMessage = 'Contact : DuplicateRecordSetService : Contact not alumni or alumni no degree contact profile. Remove from merge automation - primarycontactId: ' + primaryContactId + ' duplicateContactIds : ' + duplicateContactIds + ': DuplicateRecordSetService.handleDuplicates';
                Nebula.Logger.info(logMessage, drsId);
                LogUtilityException.addLogEvent('Contact', 'DuplicateRecordSetService', 'Contact not alumni or alumni no degree contact profile. Remove from merge automation - primarycontactId: ' + primaryContactId + ' duplicateContactIds : ' + duplicateContactIds , 'DuplicateRecordSetService.handleDuplicates');
            }
            else{
                ContactMergeController.MergeUserWrapper mwrap;
                //Invoke Merge User method
                if(primaryUserId != null && duplicateUsers!= null){
                    List<Id> dPermSetIds = duplicatePermSetIds;
                    mwrap = ContactMergeController.mergeUser(primaryUserId, duplicateUsers, primaryPermSetIds, dPermSetIds);
                    mergeUser = true;
                }
                else{
                    logMessage = 'User : MergeUser : Cannot publish event for User merge due to insufficient attributes - primaryUserId: ' + primaryUserId + ' duplicateUser : ' + duplicateUsers + ': DuplicateRecordSetService.handleDuplicates';
                    Nebula.Logger.info(logMessage, drsId);
                    LogUtilityException.addLogEvent('User', 'MergeUser', 'Cannot publish event for User merge due to insufficient attributes - primaryUserId: ' + primaryUserId + ' duplicateUser : ' + duplicateUsers , 'DuplicateRecordSetService.handleDuplicates');
                    mergeUser = false;
                }

                if(primaryAccountId != null && duplicateAccountIds!= null){
                    //Dispatch platform event for merge account process
                    Duplicate_Contact_Event__e dc = DuplicateRecordSetService.createPayloadItem('MergeAccount', primaryAccountId, duplicateAccountIds, primaryContactId, null, null, null, null, 'DuplicateContactEventService.DuplicateContactAutomation');
                    if(dc != null){
                        EventBus.publish(dc);
                    }
                }
                else{
                    logMessage = 'Account : MergeAccount : Cannot publish event for Account merge due to insufficient attributes - primaryAccountId: ' + primaryAccountId + ' duplicateAccountId : ' + duplicateAccountIds + ': DuplicateRecordSetService.handleDuplicates';
                    Nebula.Logger.info(logMessage, drsId);
                    LogUtilityException.addLogEvent('Account', 'MergeAccount', 'Cannot publish event for Account merge due to insufficient attributes - primaryAccountId: ' + primaryAccountId + ' duplicateAccountId : ' + duplicateAccountIds , 'DuplicateRecordSetService.handleDuplicates');
                }

                if(primaryContactId != null && duplicateContactIds!= null){
                    //Dispatch platform event for merge contact process
                    Duplicate_Contact_Event__e dc = DuplicateRecordSetService.createPayloadItem('MergeContact', null, null, primaryContactId, duplicateContactIds, null, null, null, 'DuplicateContactEventService.DuplicateContactAutomation');
                    if(dc != null){
                        EventBus.publish(dc);
                    }
                }
                else{
                    logMessage = 'Contact : MergeContact : Cannot publish event for Contact merge due to insufficient attributes - primaryContactId: ' + primaryContactId + ' duplicateContactId : ' + duplicateContactIds + ': DuplicateRecordSetService.handleDuplicates';
                    Nebula.Logger.info(logMessage, drsId);
                    LogUtilityException.addLogEvent('Contact', 'MergeContact', 'Cannot publish event for Contact merge due to insufficient attributes - primaryContactId: ' + primaryContactId + ' duplicateContactId : ' + duplicateContactIds , 'DuplicateRecordSetService.handleDuplicates');
                }

                if(primaryContactId != null){
                    //Dispatch platform event for post merge process
                    Duplicate_Contact_Event__e dc = DuplicateRecordSetService.createPayloadItem('PostMerge', null, null, primaryContactId, null, counter, totalRecordCount, uniqueID, 'DuplicateContactEventService.DuplicateContactAutomation');
                    if(dc != null){
                        EventBus.publish(dc);
                    }
                }
                else{
                    logMessage = 'PostMerge : PostMerge : Cannot publish event for User merge due to insufficient attributes - primaryContactId: ' + primaryContactId + ': DuplicateRecordSetService.handleDuplicates';
                    Nebula.Logger.info(logMessage, drsId);
                    LogUtilityException.addLogEvent('PostMerge', 'PostMerge', 'Cannot publish event for User merge due to insufficient attributes - primaryContactId: ' + primaryContactId , 'DuplicateRecordSetService.handleDuplicates');
                }

                if(mwrap != null){
                    if(!userIdAskMonash.contains(mwrap.userId)){
                        dupUserNames.add(mwrap);
                    }
                }

                if(primaryUserId != null && dupUserNames != null && !dupUserNames.isEmpty()){
                    String strMergeUsers = JSON.serialize(dupUserNames);
                    ContactMergeController.sendMergeConfirmation(primaryUserId, strMergeUsers);
                    emailLimitsUsed = Limits.getEmailInvocations();
                }
                else{
                    logMessage = 'sendMergeConfirmation : sendMergeConfirmation : Skipped Sending Notification due to missing user info - dupUserNames: ' + dupUserNames + ' primaryUserId: ' +primaryUserId + ': DuplicateRecordSetService.handleDuplicates';
                    Nebula.Logger.info(logMessage, drsId);
                    LogUtilityException.addLogEvent('sendMergeConfirmation', 'sendMergeConfirmation', 'Skipped Sending Notification due to missing user info - dupUserNames: ' + dupUserNames + ' primaryUserId: ' +primaryUserId, 'DuplicateRecordSetService.handleDuplicates');
                }
            }
            LogUtilityException.publishAll();
            Nebula.Logger.saveLog();

        }
        
    }

    /**
     * Method Name     getUniqueId
     * description     Returns a unique Id based on AESKey and current time
     */
    public static String getUniqueId(){

        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        Datetime dt = System.now();
        String uniqueID = String.format('{0}-{1}', new List<String>{''+dt.getTime(), h});

        return uniqueID;
    }

    /**
     * Method Name     getMapOfEntityDataByDrs
     * description     Returns the Map of EntityData by DRS Id
     */
    public static Map<Id, List<ContactMergeData>> getMapOfEntityDataByDrs(Set<Id> drsIds){
        
        Map<Id, List<ContactMergeData>> mapOfEntityDataByDrs = new Map<Id, List<ContactMergeData>>();
        Set<Id> contactIds = new Set<Id>();

        Map<Id, DuplicateRecordSet> mapOfDuplicateRecordSets = DM_DuplicateRecordSet.getMapOfDuplicateRecordSet(drsIds);
        for(DuplicateRecordSet drs : mapOfDuplicateRecordSets.values()){
            if(drs.duplicateRecordItems != null){
                for(DuplicateRecordItem dri : drs.duplicateRecordItems) {
                    contactIds.add(dri.recordId);
                }
                //Prepare the map of entity data for each set of duplicate contacts in a Duplicate Record Set.
                List<ContactMergeData> entityDataList = getEntityData(contactIds);
                mapOfEntityDataByDrs.put(drs.Id, entityDataList);
            }
        }

        return mapOfEntityDataByDrs;
    }

    /*
     * Method Name: createPayloadItem
     * Description: method to create platform event payload for publishing events for merge methods.
     */
    public static Duplicate_Contact_Event__e createPayloadItem(String queueProcess, Id primaryAccountId, Id duplicateAccountId, Id primaryContactId, Id duplicateContactId, Integer counter, Integer totalRecordCount, String uniqueID, String processName) {
        Duplicate_Contact_Event__e dc;
        if (String.isNotBlank(processName)) {
            AsyncProcessPayload payload = new AsyncProcessPayload();
            payload.put('queueProcess', queueProcess);
            payload.put('primaryAccountId', primaryAccountId);
            payload.put('duplicateAccountId', duplicateAccountId);
            payload.put('primaryContactId', primaryContactId);
            payload.put('duplicateContactId', duplicateContactId);
            payload.put('counter', counter);
            payload.put('totalRecordCount', totalRecordCount);
            payload.put('uniqueId', uniqueId);

            dc = new Duplicate_Contact_Event__e(
                Process_Name__c = processName,
                Parameter__c = payload.serialize()
                );
        }
        return dc;
    }


    /*
     * Method Name: getEntityData
     * Description: method to query and generate the entity data wrapper that contains Contact, Account, and User object
     */
    public static List<ContactMergeData> getEntityData(Set<Id> contactIds) {
        List<ContactMergeData> entityDataList = new List<ContactMergeData>();
        
        if (!contactIds.isEmpty()) {    
            Map<Id,Contact> duplicatedContactList = new Map<Id,Contact>(
                ContactMergeHelper.getContacts(null, null, null, null, contactIds)
                );
            entityDataList = formDataList(duplicatedContactList);        
        }
        
        return entityDataList;
    }

    /**
     * Method Name: formDataList 
     * Description: Helper method to Form Data List 
     */
    @TestVisible
    private static List<ContactMergeData> formDataList(Map<Id,Contact> duplicatedContactList) {
        List<ContactMergeData> entityDataList = new List<ContactMergeData>();
        // get the users related to the contact
        Map<Id, User> userContactMap = new Map<Id, User>();
        for (User u : [SELECT Id, Username, FirstName, LastName, FederationIdentifier, Email, ContactId, LastLoginDate,
                       (SELECT Id, PermissionSetId, PermissionSet.Name, PermissionSet.Type FROM PermissionSetAssignments ORDER BY PermissionSet.Name)
                       FROM User WHERE ContactId IN:duplicatedContactList.keySet() AND IsActive = TRUE]) {
            userContactMap.put(u.ContactId, u);
        }
        // generate the list of entity data
        for (Contact con : duplicatedContactList.values()) {
            ContactMergeData data = new ContactMergeData(con, null, null);
            // map the user record
            if (userContactMap.containsKey(con.Id)) {
                data.linkUser(userContactMap.get(con.Id));
            }
            entityDataList.add(data);
        }
        if (!entityDataList.isEmpty()) {
            //Sort Data Final time records comes in
            entityDataList.sort();
            
            ContactMergeData dataWrap = entityDataList.get(0);
            dataWrap.isPrimary = true;
            dataWrap.primaryClass = 'success';
        }
        return entityDataList;
    }

    /**
     * @author      Sachin Shetty
     * @description DuplicateConAutomationSetting__c to control the filters for Duplicate Automation records
     * @param       N/A
     * @return      DuplicateConAutomationSetting__c record
     * @revision    2024-02-24 - Sachin Shetty - Created
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
     * @revision    2024-02-24 - Sachin Shetty - Created
     */
    public static String duplicateRuleName {
        get {
            if (duplicateRuleName == null) {
                // if setting is not present, make default Contact Perfect Match
                duplicateRuleName = (
                    dupSetting != null
                    ? String.valueOf(dupSetting.duplicateRuleName__c != null 
                        ? dupSetting.DuplicateRuleName__c 
                        : constants.DUPLICATE_RULE_CONTACT_PERFECT_MATCH)
                    : constants.DUPLICATE_RULE_CONTACT_PERFECT_MATCH
                );
            }
            return duplicateRuleName;
        } set;
    }

    /**
     * @author      Sachin Shetty
     * @description Static reference to Segmentation__c field in the DuplicateConAutomationSetting__c custom setting
     * @param       N/A
     * @return      String
     * @revision    2024-02-24 - Sachin Shetty - Created
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
}