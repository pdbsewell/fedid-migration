/**
* @author Seeva
* @date 22.07.2023
*
* @description       : Helper class for Admissions Perfect Match Merging and Potential Match Merging.
 * @author            : Seeva
 * @group             : MyApp
 * @Revision  : 
 * Modifications Log 
 * Ver   Date         Author          Modification
 * **/
public class AdmissionsDupCheckHelper {
@TestVisible
    private Map<Id, User> mapUserContactId {get; set;}
    @TestVisible
    private Map<String, Person_Merge_Mapping__mdt> mdtPersonMapping {get; set;}
    @TestVisible
    private Set<Id> contactIds {get; set;}
    private final Map<String, Schema.SObjectField> mapConFieldUpdateAccess = Schema.SObjectType.Contact.fields.getMap();
    @TestVisible
    private Map<String,String> contactIdAccountIdMap;

    static final String DUPLICATE_PARTIAL_MATCH_NAME = 'Contact_Potential_Match';
    static final String DUPLICATE_LOOSE_MATCH_NAME = 'Contact_Loose_Match';
    @TestVisible
    private static Id householdAccountRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Household_Account').getRecordTypeId();
    
    public AdmissionsDupCheckHelper() {
        contactIds = new Set<Id>();
    }
    public void init(Id masterConId, Set<Id> conIds) {
        if (masterConId != null && conIds != null) {
            populateMDTMergeMapping();
            
            Contact masterCon = null;
            List<Contact> childContacts = new List<Contact>();
            Boolean anyCommUserFound = false;
            
            contactIds.addAll(conIds);
            contactIds.add(masterConId);

            // Get the collection of contact Id - account map using contactIds
            contactIdAccountIdMap = new Map<String,String>(retrieveContactIdAccountIdMap());
            
            retrieveUsersCommunity();
            
            // Iterate in all perfect match contact records
            Map<Id,Contact> contactMap = new Map<Id,Contact>(retrieveContacts());
            
            // Set the master contact (which is the Contact from the Application record)
            if (contactMap.containsKey(masterConId)) {
                masterCon = contactMap.get(masterConId);
            }
            List<Contact> victimContacts = new List<Contact>();
            List<String> accountIds = new List<String>();
            for (Contact contact : contactMap.values()) {
                if (contact.Id != masterConId) {
                    // Check if the duplicate match has active community user
                    // if found, exclude for merging
                    if (mapUserContactId.containsKey(contact.Id)) {
                        // Flag that there is a community user found
                        anyCommUserFound = true;
                        continue;
                    }
                    //MAPPING THE PERSON_ID_UNIQUE__C FIELD OF CONTACT TO MASTER CONTACT(APPS CONTACT), IF THERE IS NO ASSOCIATED USER WITH THE PERFECT MATCH FOUND
                    if (String.isBlank(masterCon.Person_ID_unique__c) && String.isNotBlank(contact.Person_ID_unique__c)) {
                        masterCon.Person_ID_unique__c = contact.Person_ID_unique__c;
                    }
                    //SURVIVING CONTACT IS THE APP'S CONTACT WITH PERSON_ID_UNIQUE FROM THE PERFECT MATCH(NOW VICTIM CONTACT)
                    String survivingContactId = masterCon.Id;
                    String victimContactId = contact.Id;
                    
                    // First, merge the account. If account merge fails, still continue to merge the contact
                    if (contactIdAccountIdMap.containsKey(survivingContactId) && contactIdAccountIdMap.get(survivingContactId) != null
                            && contactIdAccountIdMap.containsKey(victimContactId) && contactIdAccountIdMap.get(victimContactId) != null) {
                        String survivingAccountId = contactIdAccountIdMap.get(survivingContactId);
                        String victimAccountId = contactIdAccountIdMap.get(victimContactId);

                        if (String.isNotBlank(survivingAccountId) && String.isNotBlank(victimAccountId)) {
                            MergeAccountUtil accountMergeHandler = new MergeAccountUtil();
                            Account masterAccount = new Account(Id = contactIdAccountIdMap.get(survivingContactId));
                            Account accountToMerge = new Account(Id = contactIdAccountIdMap.get(victimContactId));
                            // log state of Account records prior to merging.  
                            List<Async_Process__e> accountMergeEventsToPub = new List<Async_Process__e>();
                            Async_Process__e accountMergeEvt = createAccountMergePayload(masterAccount, accountToMerge);
                            accountMergeEventsToPub.add(accountMergeEvt);
                            EventBus.publish(accountMergeEventsToPub);
                           // SEEVA- CALLING PLATFORM METHOD TO MERGE Account
                           ContactmergeController.mergeAccount( survivingAccountId,  victimAccountId,  survivingContactId);
                        }
                    }
                    // log state of contact records prior to merging. 
					List<Async_Process__e> contactMergeEventsToPub = new List<Async_Process__e>();
                    Async_Process__e contactMergeEvt = createContactMergePayload(masterCon, contact);
                    contactMergeEventsToPub.add(contactMergeEvt);
                    EventBus.publish(contactMergeEventsToPub);
                    //SEEVA- Calling Platform method to merge Contact
                    ContactmergeController.mergeContact(survivingContactId, victimContactId);
                }
            }          
        }
    }
    @TestVisible
    private static Async_Process__e createAccountMergePayload(Account survivor, Account victim) {
        Async_Process__e evt;
        AsyncProcessPayload payload = new AsyncProcessPayload();
        payload.put ('SurvivingAccountJSON', JSON.serializePretty(survivor));
        payload.put ('VictimAccountJSON', JSON.serializePretty(victim));

        evt = new Async_Process__e (
            Process_Name__c = 'LoggingServices.LogAccountMerge',
            Parameter__c = payload.serialize()
        );

        return evt;
    }

    @TestVisible
    private static Async_Process__e createContactMergePayload(Contact survivor, Contact victim) {

        Async_Process__e evt;
        AsyncProcessPayload payload = new AsyncProcessPayload();
        payload.put ('SurvivingContactJSON', JSON.serializePretty(survivor));
        payload.put ('VictimContactJSON', JSON.serializePretty(victim));

        evt = new Async_Process__e (
            Process_Name__c = 'LoggingServices.LogContactMerge',
            Parameter__c = payload.serialize()
        );

        return evt;
    }

    /**
     * Retrieves Contacts with fields configured from Custom Metadata
     * @return Contacts
    */
    @TestVisible
    private void retrieveUsersCommunity() {
        mapUserContactId = new Map<Id, User>();
        List<User> users = [SELECT Id, ContactId, Username, FirstName, LastName, Email,
                            CommunityNickname, Alias, TimeZoneSidKey, LocaleSidKey,
                            EmailEncodingKey, LanguageLocaleKey, ProfileId
                            FROM User WHERE ContactId IN:contactIds];
        if (users != null) {
            for (User usr : users) {
                mapUserContactId.put(usr.ContactId, usr);
            }
        }
    }


    /**
     * Retrieves MDT data for Contact Mapping
     * If Field is added it will override Master with child value
    */
    @TestVisible
    private void populateMDTMergeMapping() {
        if (mdtPersonMapping == null) {
            mdtPersonMapping = new Map<String, Person_Merge_Mapping__mdt>();
            
            // get mapping definition for each field
            List<Person_Merge_Mapping__mdt> lPMM = Person_Merge_Mapping__mdt.getall().values();
            
            if (lPMM != null) {
                // get all fields from Contact Sobject
                Set<String> contactFields = Schema.SObjectType.Contact.fields.getMap().keyset();
                
                for (Person_Merge_Mapping__mdt mdt : lPMM) {
                    // only add valid fields i.e. metadata entry has to refer to a valid field
                    if(contactFields.contains(mdt.SObjectField__c.toLowerCase())) {
                        mdtPersonMapping.put(mdt.SObjectField__c, mdt);
                    }
                }
            }
        }
        LogUtilityException.debug('AdmissionsDupCheckHelper.populateMDTMergeMapping:' + mdtPersonMapping);
    }
    
    /**
     * Retrieves Contacts with fields configured from Custom Metadata
     * @return Contacts
    */
    @TestVisible
    private List<Contact> retrieveContacts() {
        String soql = 'SELECT Id';
        if (!mdtPersonMapping.isEmpty()) {
            List<String> sFields = new List<String>(mdtPersonMapping.keySet());
            if(!mdtPersonMapping.containsKey('Person_ID_unique__c')){
                sFields.add('Person_ID_unique__c');
            }
            soql += ',';
            soql += String.join( sFields, ',' );
        }
        soql += ' FROM Contact';
        soql += ' WHERE Id IN:contactIds';
        soql += ' ORDER BY Person_ID_unique__c NULLS LAST, LastModifiedDate';
        LogUtilityException.debug('AdmissionsDupCheckHelper.retrieveContacts:' + soql);
        return Database.query(soql);
    }

    /**
     * @description     Retrieves contact id and account id map
     * @return          Map<Id,Id> temp_contactIdAccountIdMap
    */
    @TestVisible
    private Map<String,String> retrieveContactIdAccountIdMap() {
        Map<String,String> temp_contactIdAccountIdMap = new Map<String,String>();
        for (Contact contact : [SELECT Id, AccountId FROM Contact WHERE Id IN: contactIds]) {
            temp_contactIdAccountIdMap.put(contact.Id, contact.AccountId);
        }
        return temp_contactIdAccountIdMap;
    }

    /**
     * @description     Method to find potential duplicate contacts
     * @param           Contact con
     * @return          Set<Id> contactIds
     */
    public static Set<Id> findPotentialDuplicateContacts(Contact con) {
        LogUtilityException.debug('AdmissionsDupCheckHelper.findPotentialDuplicateContacts--con:' + JSON.serializePretty(con));
        Set<Id> duplicateContactIds = new Set<Id>();

        // Find if there are Potential Match and/or Loose Match and/or email search and/or person id match
        Set<Id> potentialMatchContactIds = new Set<Id>();
        Set<Id> looseMatchContactIds = new Set<Id>();
        Set<Id> emailSearchSOSLContactIds = new Set<Id>();
        Set<Id> emailSearchContactPointContactIds = new Set<Id>();
        Set<Id> personIdMatchContactIds = new Set<Id>();

        // Collect all emails to use for SOSL and search in Email__c SObject
        Set<String> contactEmails = new Set<String>();
        if (con.Email != null) {
            contactEmails.add(con.Email);
        }
        if (con.Personal_Email__c != null) {
            contactEmails.add(con.Personal_Email__c);
        }
        if (con.Monash_Email_Address__c != null) {
            contactEmails.add(con.Monash_Email_Address__c);
        }

        // Potential Match
        potentialMatchContactIds = findDuplicateContacts(new Set<Id>{con.Id}, DUPLICATE_PARTIAL_MATCH_NAME);
        // Loose Match
        looseMatchContactIds = findDuplicateContacts(new Set<Id>{con.Id}, DUPLICATE_LOOSE_MATCH_NAME);
        // Email Search SOSL (in Contact SObject only)
        emailSearchSOSLContactIds = findPotentialDuplicateContactsByEmailSOSL(contactEmails);
        // Remove the current contact id if included in the result
        // as current contact should be be included as part of found possible duplicate
        if (!emailSearchSOSLContactIds.isEmpty() && emailSearchSOSLContactIds.contains(con.Id)) {
            emailSearchSOSLContactIds.remove(con.Id);
        }
        // Email Search (in Email__c SObject)
        emailSearchContactPointContactIds = findPotentialDuplicateContactsInEmailByEmail(contactEmails);
        // Remove the current contact id if included in the result
        // as current contact should be be included as part of found possible duplicate
        if (!emailSearchContactPointContactIds.isEmpty() && emailSearchContactPointContactIds.contains(con.Id)) {
            emailSearchContactPointContactIds.remove(con.Id);
        }
        // Search in Person Id
        personIdMatchContactIds = findPotentialDuplicateContactsByPreviousPersonId(con.Previous_Monash_ID__c);
        // Remove the current contact id if included in the result
        // as current contact should be be included as part of found possible duplicate
        if (!personIdMatchContactIds.isEmpty() && personIdMatchContactIds.contains(con.Id)) {
            personIdMatchContactIds.remove(con.Id);
        }

        // Consolidate all contact Ids
        if (!potentialMatchContactIds.isEmpty()) {
            duplicateContactIds.addAll(potentialMatchContactIds);
        }
        if (!looseMatchContactIds.isEmpty()) {
            duplicateContactIds.addAll(looseMatchContactIds);
        }
        if (!emailSearchSOSLContactIds.isEmpty()) {
            duplicateContactIds.addAll(emailSearchSOSLContactIds);
        }
        if (!emailSearchContactPointContactIds.isEmpty()) {
            duplicateContactIds.addAll(emailSearchContactPointContactIds);
        }
        if (!personIdMatchContactIds.isEmpty()) {
            duplicateContactIds.addAll(personIdMatchContactIds);
        }
        LogUtilityException.debug('AdmissionsDupCheckHelper.findPotentialDuplicateContacts--duplicates:' + JSON.serializePretty(duplicateContactIds));
        return duplicateContactIds;
    }

    /**
     * @description     Find duplicates
     * @param           
     *                  Set<Id> set_contactIds - salesforce contact ids
     *                  String duplicateRuleName
     * @return          Set<Id> set_duplicateResultContactIds
     */
    public static Set<Id> findDuplicateContacts(Set<Id> set_contactIds, String duplicateRuleName) {
        List<Id> list_contactIds = new List<Id>(set_contactIds);
        Set<Id> set_duplicateResultContactIds = new Set<Id>();
        // Check for Perfect Match
        Datacloud.FindDuplicatesResult[] perfectMatchResults = Datacloud.FindDuplicatesByIds.findDuplicatesByIds(list_contactIds);

        for (Datacloud.FindDuplicatesResult findDupeResult : perfectMatchResults) {
            for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
                if (dupeResult.getDuplicateRule().equals(duplicateRuleName)) {
                    for (Datacloud.MatchResult matResults : dupeResult.getMatchResults()) {
                        if (matResults.getRule().equals(duplicateRuleName) && matResults.getMatchRecords() != null && matResults.getMatchRecords().size() > 0) {
                            for (Datacloud.MatchRecord matchRec : matResults.getMatchRecords()) {
                                Contact con = (Contact) matchRec.getRecord();
                                if (con != null && con.Id != null) {
                                    set_duplicateResultContactIds.add(con.Id);
                                }
                            }
                        }
                    }
                }
            }
        }
        LogUtilityException.debug('AdmissionsDupCheckHelper.findDuplicateContacts--' + 'duplicateRuleName:' + set_duplicateResultContactIds);
        LogUtilityException.debug('AdmissionsDupCheckHelper.findDuplicateContacts--set_duplicateResultContactIds:' + set_duplicateResultContactIds);
        return set_duplicateResultContactIds;
    }

    /**
     * @description         Find any of the email addresses on the new contact (Personal email, Monash Email & Email) matches
     *                      with any of the email addresses on one or more existing contacts (Personal email, Monash Email & Email)
     * @param               String s_email
     * @return              Set<Id> contactIds
     */
    public static Set<Id> findPotentialDuplicateContactsByEmailSOSL(Set<String> emails) {
        Set<Id> contactIds = new Set<Id>();
        String emails_key = '';
        for (String emai : emails) {
            emails_key += emai + ' OR ';
        }
        if (String.isNotBlank(emails_key)) {
            emails_key = emails_key.removeEnd(' OR ');
            LogUtilityException.debug('AdmissionsDupCheckHelper.findPotentialDuplicateContactsByEmailSOSL:' + emails_key);
            List<List<SObject>> searchList = [FIND :emails_key in EMAIL FIELDS RETURNING Contact (Id, Account.RecordTypeId WHERE Account.RecordTypeId = :householdAccountRecTypeId)];
            for (List<SObject> loop_list : searchList) {
                for (SObject loop_sObj : loop_list) {
                    contactIds.add((Id) loop_sObj.get('Id'));
                }
            }
        }
        LogUtilityException.debug('AdmissionsDupCheckHelper.findPotentialDuplicateContactsByEmailSOSL:' + contactIds);
        return contactIds;
    }

    /**
     * @description         Find any of the email addresses on the new contact (Personal email, Monash Email & Email) matches
     *                      with any of the email addresses on one or more existing Email records (Name)
     * @param               Set<String> emails
     * @return              Set<Id> contactIds
     */
    public static Set<Id> findPotentialDuplicateContactsInEmailByEmail(Set<String> emails) {
        Set<Id> contactIds = new Set<Id>();
        for (Email__c loop_email : [SELECT Id, Name, Contact__c, Contact__r.Id FROM Email__c WHERE Name IN: emails AND Contact__r.Account.RecordTypeId = :householdAccountRecTypeId]) {
            contactIds.add(loop_email.Contact__r.Id);
        }
        LogUtilityException.debug('AdmissionsDupCheckHelper.findPotentialDuplicateContactsInEmailByEmail:' + contactIds);
        return contactIds;
    }

    /**
     * @description         Find potential duplicate contact using
     *                      'Previous Monash ID' (Previous_Monash_ID__c) field
     *                      on the new contact matches with 'Person ID' (Person_ID__c)
     *                      on existing contact
     * @param               String previousMonashId
     * @return              Set<Id> contactIds
     */
    public static Set<Id> findPotentialDuplicateContactsByPreviousPersonId(String previousMonashId) {
        Set<Id> contactIds = new Set<Id>();
        if (String.isNotBlank(previousMonashId)) {
            for (Contact loop_contact : [SELECT Id FROM Contact WHERE Person_ID__c =: previousMonashId AND Account.RecordTypeId = :householdAccountRecTypeId]) {
                contactIds.add(loop_contact.Id);
            }
        }
        LogUtilityException.debug('AdmissionsDupCheckHelper.findPotentialDuplicateContactsByPreviousPersonId:' + contactIds);
        return contactIds;
    }
}