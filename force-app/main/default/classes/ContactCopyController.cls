/**
 * @description       : Controller for Mass Contact Copy tool
 * @date              : 2024-06-01
 * @group             : Mass Contact Copy
 * @author            : Sachin Shetty
 * @last modified on  : 2024-08-14
 * @last modified by  : Sachin Shetty
 * @revision
 *      2024-06-01  Sachin Shetty   -   Created
 *      2024-08-14  Sachin Shetty   -   Update to query more records than the passed limit since the
 *                                      number of business unit specific duplicates are limited
 *      2024-10-03  Sachin Shetty   -   Update to control number of DRS records queried
**/
public with sharing class ContactCopyController extends TriggerAbstract {

    private static final String EVENTTAG = 'Mass Contact Copy';
    private static final String ALUMNI = 'Alumni';
    private static final String RECORD_TYPE_PROSPECTIVE_STUDENT = 'Prospective_Student';

    /**
    * @author Sachin Shetty
    * @description Fetch duplicate contact details
    * @param duplicateRule 
    * @param businessUnit 
    * @param limitSize 
    * @return Object
    * @revision    2024-06-01 - Sachin Shetty - Created
    **/
    @AuraEnabled
    public static Object retrieveDuplicateContactData(String duplicateRule, String businessUnit, Integer limitSize) {
        Object result;
        
        // Retrieve the MCC SOQL Limit parameter from custom setting
        Integer SOQLLIMIT = Integer.ValueOf(massContactCopySOQLLimit);
        
        try {
            Map<Id, DuplicateRecordSet> dupRecSetById = new Map<Id, DuplicateRecordSet>([SELECT Id, Name, (Select Id, RecordId from DuplicateRecordItems)
                                                                                FROM DuplicateRecordSet
                                                                                WHERE (DuplicateRule.MasterLabel LIKE :duplicateRule OR Parent.Name LIKE :duplicateRule ) 
                                                                                AND RecordCount = 2
                                                                                LIMIT :SOQLLIMIT]);


            Set<Id> contactIds = new Set<Id>();
            Map<Id, List<Id>> contactIdsByDrsIds = new Map<Id, List<Id>>();
            for(DuplicateRecordSet drs : dupRecSetById.values()){
                List<Id> contactRecordIds = new List<Id>();
                for(DuplicateRecordItem dri : drs.duplicateRecordItems) {
                    contactIds.add(dri.recordId);
                    contactRecordIds.add(dri.recordId);
                }
                contactIdsByDrsIds.put(drs.Id, contactRecordIds);
            }
            Map<Id, Contact> contactDetails = new Map<Id, Contact>([SELECT First_Name__c, Preferred_Name__c, Last_Name__c, Email, Personal_Email__c, MobilePhone, Birthdate, Gender__c, Pronouns_V2__c, Record_Type_Developer_Name__c, Contact_Profile__c, Person_ID__c, Exclude_From_Merge__c
                                                                    FROM Contact 
                                                                    WHERE Id in :contactIds
                                                                    ORDER BY First_Name__c]);
                                                                    
            List<Payload> payLoadData = new List<Payload>();
            Integer count = 0;
            String alumString = 'Alumni;';
            for( Id drsId : dupRecSetById.keySet()){

                // Prepare DRS record details
                Payload dd = new Payload();
                dd.drsId = '/'+drsId;
                dd.drsName = dupRecSetById.get(drsId).Name;
                dd.excludeFromMerge = 'false';

                // Collect duplicate contacts associated with the DRS record
                List<Contact> relContacts = new List<Contact>();
                for(Id conId : contactIdsByDrsIds.get(drsId)){
                    relContacts.add(contactDetails.get(conId));
                }

                // Duplicate contacts with different person Ids are out of scope
                if(relContacts.size() == 2 && 
                relContacts[0]?.Person_ID__c != null && relContacts[1]?.Person_ID__c != null &&
                relContacts[0]?.Person_ID__c != relContacts[1]?.Person_ID__c){
                    continue;
                }

                // Get 'Exclude from Merge' info of associated contact
                if(((relContacts[0]?.Exclude_From_Merge__c != null) && relContacts[0].Exclude_From_Merge__c) || ((relContacts[1]?.Exclude_From_Merge__c != null) && relContacts[1].Exclude_From_Merge__c)){
                    dd.excludeFromMerge = 'true';
                }

                if(relContacts.size() == 2 && count < limitSize){

                    // Collect Advancement duplicate contacts
                    if(businessUnit == 'Advancement'){
                        String relContact1Profile = relContacts[0]?.Contact_Profile__c;
                        String relContact2Profile = relContacts[1]?.Contact_Profile__c;
                        if((relContact1Profile != null && (relContact1Profile == ALUMNI || relContact1Profile.contains(alumString) || relContact1Profile.endsWith(ALUMNI))) ||
                        (relContact2Profile != null && (relContact2Profile == ALUMNI || relContact2Profile.contains(alumString) || relContact2Profile.endsWith(ALUMNI)))){
                            dd.contactData = relContacts;
                            payLoadData.add(dd);
                            count++;
                        }
                    }

                    // Collect Prospective Students duplicate contacts
                    else if(businessUnit == 'Prospective Students'){
                        String relContact1RecType = relContacts[0]?.Record_Type_Developer_Name__c;
                        String relContact2RecType = relContacts[1]?.Record_Type_Developer_Name__c;
                        if((relContact1RecType != null && relContact1RecType.contains(RECORD_TYPE_PROSPECTIVE_STUDENT)) ||
                        (relContact2RecType != null && relContact2RecType.contains(RECORD_TYPE_PROSPECTIVE_STUDENT))){
                            dd.contactData = relContacts;
                            payLoadData.add(dd);
                            count++;
                        }
                    }

                    else{
                        dd.contactData = relContacts;
                        payLoadData.add(dd);
                        count++;
                    }
                }
            }

            result = payLoadData;
        } catch (Exception ex) {
            Map<String,Object> errorMap = new Map<String,Object>();
            errorMap.put('error', 'Something went wrong getting information. Please contact your administrator.');
            Nebula.Logger.error('An unexpected error occurred while trying to prepare duplicate contacts payload', ex).addTag(EVENTTAG);
            Nebula.Logger.saveLog();
            result = errorMap;
        }

        return result;
    }

    /**
     * @author      Sachin Shetty
     * @description Delete DRS records, insert contact points, and update the contact records
     * @param       drsIds - DRS record Ids to delete
     * @param       contactsToUpdate - Contact records to update
     * @return      List<Contact>
     * @revision    2024-06-01 - Sachin Shetty - Created
     */
    @AuraEnabled
    public static List<Contact> deleteDRSAndUpdateContacts(List<String> drsIds, List<Contact> contactsToUpdate){
        if(contactsToUpdate == null || contactsToUpdate.isEmpty()) {
            return null;
        }

        List<DuplicateRecordSet> drsRecordsToDelete = new List<DuplicateRecordSet>();
        for(String drsId : drsIds){
            drsRecordsToDelete.add(
                new DuplicateRecordSet(Id = drsId)
            );
        }

        if(!drsRecordsToDelete.isEmpty()){
            try {
                delete drsRecordsToDelete;
            } catch(Exception e) {
                Nebula.Logger.error('Error deleting DRS record', e).addTag(EVENTTAG);
            }
        }
        
        try {
            update contactsToUpdate;
        } catch(Exception e) {
            Nebula.Logger.error('Error updating contact records', e).addTag(EVENTTAG);
        }

        Nebula.Logger.saveLog();

        return contactsToUpdate;
    }

   /**
     * @author      Sachin Shetty
     * @description Update Contact points
     * @param       newPhoneRecords - Phone records to update
     * @param       newEmailRecords - Email records to update
     * @return      void
     * @revision    2024-07-25 - Sachin Shetty - Created
     */
    @AuraEnabled
    public static void updateContactPoints(List<Phone__c> newPhoneRecords, List<Email__c> newEmailRecords){
        if((newPhoneRecords == null || newPhoneRecords.isEmpty()) && (newEmailRecords == null || newEmailRecords.isEmpty())){
            return;
        }
        
        updatePhoneRecords(newPhoneRecords);
        updateEmailRecords(newEmailRecords);
        
        return;
    }
    
   /**
     * @author      Sachin Shetty
     * @description Update Phone records
     * @param       newPhoneRecords - Phone records to update
     * @return      void
     * @revision    2024-07-25 - Sachin Shetty - Created
     */
    private static void updatePhoneRecords(List<Phone__c> newPhoneRecords) {
        
        List<String> phoneContactIds = new List<String>();
        for(Phone__c phone : newPhoneRecords){
            phoneContactIds.add(phone.Contact__c);
        }
        
        DateTime oneMinuteBack = System.now().addSeconds(-60);
        List<Phone__c> phoneRecords = [SELECT Id, Name, Channel__c, Classification__c, Contact__c, Country__c, Country_Code__c, End_Date__c, External_System_ID__c, Is_Active__c, Is_Deleted__c, Is_Primary__c, Primary_set_by__c,Source__c, Start_Date__c, Type__c, Verification_Status__c
                                       FROM Phone__c
                                      WHERE Contact__c in :phoneContactIds AND CreatedDate >= :oneMinuteBack];
        
        List<Phone__c> phoneRecordsForUpdate = new List<Phone__c>();
        
        for(Phone__c nPhone : newPhoneRecords){
            for(Phone__c uPhone : phoneRecords){
                if(nPhone.Contact__c == uPhone.Contact__c && nPhone.Name == uPhone.Name){
                    Phone__c updatedPhoneRec = new Phone__c();
                    updatedPhoneRec = uPhone;
                    updatedPhoneRec.Channel__c = nPhone.Channel__c;
                    updatedPhoneRec.Classification__c = nPhone.Classification__c;
                    updatedPhoneRec.Country__c = nPhone.Country__c;
                    updatedPhoneRec.Country_Code__c = nPhone.Country_Code__c;
                    updatedPhoneRec.End_Date__c = nPhone.End_Date__c;
                    updatedPhoneRec.External_System_ID__c = nPhone.External_System_ID__c;
                    updatedPhoneRec.Is_Active__c = nPhone.Is_Active__c;
                    updatedPhoneRec.Is_Deleted__c = nPhone.Is_Deleted__c;
                    updatedPhoneRec.Is_Primary__c = nPhone.Is_Primary__c;
                    updatedPhoneRec.Primary_set_by__c = nPhone.Primary_set_by__c;
                    updatedPhoneRec.Source__c = (nPhone.Source__c == 'Callista') ? 'Undefined' : nPhone.Source__c;
                    updatedPhoneRec.Start_Date__c = nPhone.Start_Date__c;
                    updatedPhoneRec.Type__c = nPhone.Type__c;
                    updatedPhoneRec.Verification_Status__c = nPhone.Verification_Status__c;
                    
                    phoneRecordsForUpdate.add(updatedPhoneRec);
                }
            }
        }
        
        try {
            update phoneRecordsForUpdate;
        } catch(Exception e) {
            Nebula.Logger.error('Error updating phone records', e).addTag(EVENTTAG);
        }
        Nebula.Logger.saveLog();
        
        return;
    }
    
   /**
     * @author      Sachin Shetty
     * @description Update Email records
     * @param       newEmailRecords - Email records to update
     * @revision    2024-07-25 - Sachin Shetty - Created
     */
    private static void updateEmailRecords(List<Email__c> newEmailRecords) {
        
        List<String> emailContactIds = new List<String>();
        for(Email__c email : newEmailRecords){
            emailContactIds.add(email.Contact__c);
        }
        
        DateTime oneMinuteBack = System.now().addSeconds(-60);
        List<Email__c> emailRecords = [SELECT Id, Name, Channel__c, Classification__c, Contact__c, End_Date__c, External_System_ID__c, Is_Active__c, Is_Deleted__c, Is_Primary__c, Primary_set_by__c,Source__c, Start_Date__c, Unreachable__c, Unreachable_Reason__c, Verification_Status__c
                                       FROM Email__c
                                      WHERE Contact__c in :emailContactIds AND CreatedDate >= :oneMinuteBack];
        
        List<Email__c> emailRecordsForUpdate = new List<Email__c>();
        
        for(Email__c nEmail : newEmailRecords){
            for(Email__c uEmail : emailRecords){
                if(nEmail.Contact__c == uEmail.Contact__c && nEmail.Name == uEmail.Name){
                    Email__c updatedEmailRec = new Email__c();
                    updatedEmailRec = uEmail;
                    updatedEmailRec.Channel__c = nEmail.Channel__c;
                    updatedEmailRec.Classification__c = nEmail.Classification__c;
                    updatedEmailRec.End_Date__c = nEmail.End_Date__c;
                    updatedEmailRec.External_System_ID__c = nEmail.External_System_ID__c;
                    updatedEmailRec.Is_Active__c = nEmail.Is_Active__c;
                    updatedEmailRec.Is_Deleted__c = nEmail.Is_Deleted__c;
                    updatedEmailRec.Is_Primary__c = nEmail.Is_Primary__c;
                    updatedEmailRec.Primary_set_by__c = nEmail.Primary_set_by__c;
                    updatedEmailRec.Source__c = (nEmail.Source__c == 'Callista')? 'Undefined' : nEmail.Source__c;
                    updatedEmailRec.Start_Date__c = nEmail.Start_Date__c;
                    updatedEmailRec.Unreachable__c = nEmail.Unreachable__c;
                    updatedEmailRec.Unreachable_Reason__c = nEmail.Unreachable_Reason__c;
                    updatedEmailRec.Verification_Status__c = nEmail.Verification_Status__c;
                    
                    emailRecordsForUpdate.add(updatedEmailRec);
                }
            }
        }
        
        try {
            update emailRecordsForUpdate;
        } catch(Exception e) {
            Nebula.Logger.error('Error updating email records', e).addTag(EVENTTAG);
        }
        Nebula.Logger.saveLog();
        
        return;
    }

    /**
     * @author      Sachin Shetty
     * @description Retrieve the Contact Point records associated with the contact
     * @param       contactPointValue - ContactPoint value on the record that needs to be retrieved
     * @param       contactId - Contact Id of the contact associated with the contact point
     * @param       objectApiName - Contact Point object api name
     * @return      SObject
     * @revision    2024-06-01 - Sachin Shetty - Created
     */
    @AuraEnabled
    public static SObject fetchContactPointRecord(String contactPointValue,String contactId, String objectApiName){

        if(contactPointValue == null || contactId == null || objectApiName == null) {
            return null;
        }

        List<String> emailFields = new List<String>(Email__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap().keySet());
        List<String> phoneFields = new List<String>(Phone__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap().keySet());
        String soql = '';
        if(objectApiName == 'Email__c'){
            soql += ' SELECT ' + String.join(emailFields, ',');
            soql += ' FROM Email__c';
        }
        else if(objectApiName == 'Phone__c'){
            soql += ' SELECT ' + String.join(phoneFields, ',');
            soql += ' FROM Phone__c';
        }
        soql += ' WHERE Contact__c = :contactId AND Name = :contactPointValue WITH SYSTEM_MODE LIMIT 1';

        List<SObject> result = new List<SObject>();
        try {
            result = (List<SObject>)Database.query(soql);
        } catch(Exception e) {
            Nebula.Logger.error('Error querying contact point record', e).addTag(EVENTTAG);
        }
        return (SObject)result.get(0).clone(false, true, true, false);
    }

    /**
     * @author      Sachin Shetty
     * @description DuplicateConAutomationSetting__c to control the filters for Duplicate Automation records
     * @param       N/A
     * @return      DuplicateConAutomationSetting__c record
     * @revision    2024-10-03 - Sachin Shetty - Created
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
     * @description Static reference to MCC_SOQL_Limit__c field in the DuplicateConAutomationSetting__c custom setting
     * @param       N/A
     * @return      String
     * @revision    2024-10-03 - Sachin Shetty - Created
     */
    public static String massContactCopySOQLLimit {
        get {
            if (massContactCopySOQLLimit == null) {
                // if setting is not present, make default blank
                massContactCopySOQLLimit = (
                    dupSetting != null
                    ? String.valueOf(dupSetting.MCC_SOQL_Limit__c != null 
                        ? dupSetting.MCC_SOQL_Limit__c 
                        : '0')
                    : '0'
                );
            }
            return massContactCopySOQLLimit;
        } set;
    }


    public class Payload {
        @AuraEnabled
        public String drsName {get; set;}
        @AuraEnabled
        public String drsId {get; set;}
        @AuraEnabled
        public String excludeFromMerge {get; set;}
        @AuraEnabled
        public List<Contact> contactData {get; set;}
    }
}