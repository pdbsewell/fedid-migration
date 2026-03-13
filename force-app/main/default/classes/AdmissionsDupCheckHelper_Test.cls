/**
 * @description     Test class for AdmissionsDupCheckHelper.cls
 * @author          Seeva
 * @date            27/07/2023
 * 
 * @revision
 */
@isTest
public class AdmissionsDupCheckHelper_Test {
    @testSetup static void setup() {
        // Create test account
        Id householdAccountRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Household_Account').getRecordTypeId();
        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        testAccount.RecordTypeId = householdAccountRecTypeId;
        insert testAccount;
        System.assert(testAccount.Id != null, '### Insert Test Account Failed.');
        System.debug('### setup - testAccount value: '+ testAccount.Id);
        //Create test contact
        Contact testContact = new Contact();
        testContact.AccountId = testAccount.Id;
        testContact.FirstName = 'Test FirstName';
        testContact.LastName = 'Test LastName';
        testContact.MobilePhone = '0481977625';
        testContact.Email = 'testemail001@monash.edu';
        testContact.Monash_Email_Address__c = 'testemailmonash@monash.edu';
        testContact.Birthdate = Date.today().addYears(-11);
        testContact.SAP_Staff_Id__c = '';
        testContact.Previous_Monash_ID__c = 'PRV123';
        testContact.DoNotCall = false;
        testContact.isAskMonashCreated__c = true;
        testContact.Deleted_In_Source__c = false;
        insert testContact;
        System.assert(testContact.Id != null, '### Insert Test Contact Failed.');
        
        //Create Application
        Application__c testApplication = new Application__c();
        testApplication.Applicant__c = testContact.Id;
        testApplication.Status__c = 'Draft';
        insert testApplication;
        System.assert(testApplication.Id != null, '### Insert Test Application Failed.');
    }
/*
     * @description     This method will verify that existing contacts will be merged to Application's Applicant
     *  Expected result: Existing contacts will be merged to Application's Applicant (Contact record)
     */
    static testMethod void testMergeContacts() {
        //GIVEN: Contacts with Accounts of Household Record Types and an Application Record
        List<Application__c> applications = new List<Application__c>([SELECT Id, Applicant__c, Applicant__r.Id FROM Application__c]);
        System.assert(applications.size() > 0, '### No test application record retrieved. Insertion of test data failed.');
        // Get application's applicant then clone then update the birthdate of newly clone contact
        Contact masterContact = [SELECT Id, FirstName, LastName, MobilePhone, Email, Monash_Email_Address__c, Birthdate, SAP_Staff_Id__c FROM Contact WHERE Id =: applications.get(0).Applicant__r.Id];
        System.assert(masterContact != null && masterContact.Id != null, '### Error fetching contact from application.');
        
        List<Account> accounts = new List<Account>();
        for (Integer i=1 ; i<10; i++) {
            Account temp_Account = new Account(
                Name = 'Test Account' + i
            );
            accounts.add(temp_Account);
        }
        insert accounts;

        // Create duplicate contacts
        List<Contact> temp_duplicateContacts = new List<Contact>();
        for (Integer i=1 ; i<10; i++) {
            Contact temp_Contact = masterContact.clone(false,false,false,false);
            temp_Contact.AccountId = accounts.get(i-1).Id;
            temp_Contact.Birthdate = masterContact.Birthdate.addDays(i);
            temp_Contact.DoNotCall = true;
            temp_Contact.isAskMonashCreated__c = true;
            temp_Contact.Deleted_In_Source__c = true;
            temp_duplicateContacts.add(temp_Contact);
        }
        insert temp_duplicateContacts;
        Set<Id> dupContactIds = new Set<Id>();
        for (Contact dupCon : temp_duplicateContacts) {
            if (dupCon.Id != null)
                dupContactIds.add(dupCon.Id);
        }
        //WHEN Contacts with the same name, email, personal email, monash email address are are merged
        Test.startTest();
        AdmissionsDupCheckHelper helper = new AdmissionsDupCheckHelper();
        helper.init(masterContact.Id, dupContactIds);
        Test.stopTest();
        List<Contact> remainingDupContacts = new List<Contact>([SELECT Id FROM Contact WHERE Id IN: dupContactIds]);
        System.assert(
            remainingDupContacts.isEmpty(),
            '### Error! Merge functionality did not work!'
        );
        //THEN: The applicants contact details surives and the other contact was deleted
        Contact mergedContact = [SELECT Id, DoNotCall, isAskMonashCreated__c, Deleted_In_Source__c FROM Contact WHERE Id = :applications.get(0).Applicant__r.Id LIMIT 1];
        System.assertEquals(true, mergedContact.DoNotCall, 'Assertion failed for Boolean OR during merge operation');
        System.assertEquals(true, mergedContact.isAskMonashCreated__c, 'Assertion failed for Boolean AND during merge operation - positive');
        System.assertEquals(false, mergedContact.Deleted_In_Source__c, 'Assertion failed for Boolean AND during merge operation');
    }

    /*
     * @description     This method will verify that existing contacts will be queried and flagged as duplicate
     *  Expected result: Query will get all Contact where their Account is Household Account
     */
    static testMethod void testFindDuplicateContacts() {
        //GIVEN: Contacts with Accounts of Household Record Types
        Id householdAccountRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Household_Account').getRecordTypeId();
        
        List<Application__c> applications = new List<Application__c>([SELECT Id, Applicant__c, Applicant__r.Id FROM Application__c]);
        System.assert(applications.size() > 0, '### No test application record retrieved. Insertion of test data failed.');
        // Get application's applicant then clone then update the birthdate of newly clone contact
        Contact masterContact = [SELECT Id, FirstName, LastName, MobilePhone, Email, Monash_Email_Address__c, Birthdate, SAP_Staff_Id__c FROM Contact WHERE Id =: applications.get(0).Applicant__r.Id];
        System.assert(masterContact != null && masterContact.Id != null, '### Error fetching contact from application.');
        
        List<Account> accounts = new List<Account>();
        for (Integer i=1 ; i<10; i++) {
            Account temp_Account = new Account(
                Name = 'Test Account' + i
            );
            accounts.add(temp_Account);
        }
        insert accounts;

        //WHEN Contacts with the same name, email, personal email, monash email address are created with its Account recordtype set as Household
        // Create duplicate contacts
        List<Contact> temp_duplicateContacts = new List<Contact>();
        for (Integer i=1 ; i<10; i++) {
            Contact temp_Contact = masterContact.clone(false,false,false,false);        
            temp_Contact.AccountId = accounts.get(i-1).Id;
            temp_Contact.Birthdate = masterContact.Birthdate.addDays(i);      
            temp_Contact.DoNotCall = true;
            temp_Contact.Email = 'testemail001@monash.edu';
            temp_Contact.Personal_Email__c = 'peronsaltestemail@yopmail.com';
            temp_Contact.Monash_Email_Address__c = 'testemailmonash@monash.edu';
            temp_Contact.isAskMonashCreated__c = true;
            temp_Contact.Previous_Monash_ID__c = 'PRV123';
            temp_Contact.Deleted_In_Source__c = true;
            
            temp_duplicateContacts.add(temp_Contact);
        }
        insert temp_duplicateContacts;        

        Set<Id> dupContactIds = new Set<Id>();
        for (Contact dupCon : temp_duplicateContacts) {
            if (dupCon.Id != null)
                dupContactIds.add(dupCon.Id);
        }

        Email__c emailRec = new Email__c();
        emailRec.Contact__c = temp_duplicateContacts[2].Id;
        emailRec.Name = 'testemail001@monash.edu';
        insert emailRec;
       
        Test.startTest();
        AdmissionsDupCheckHelper.findPotentialDuplicateContacts(temp_duplicateContacts[2]);
        Test.stopTest();
        //THEN: They will be flagged as duplicate contacts
        List<Contact> remainingDupContacts = new List<Contact>([SELECT Id, Email, Monash_Email_Address__c, Previous_Monash_ID__c FROM Contact WHERE Id IN :dupContactIds]);
        System.assert(remainingDupContacts.size() == 9, 'Wrong duplicate count');
    }

    /*
     * @description     This method will verify that existing contacts will be merged to Application's Applicant
     * Expected result: Existing contacts will be merged to Application's Applicant (Contact record)
     */
    static testMethod void testMergeContactsWithCommUser() {
        //GIVEN: Application has a Contact
        List<Application__c> applications = new List<Application__c>([SELECT Id, Applicant__c, Applicant__r.Id FROM Application__c]);
        System.assert(applications.size() > 0, '### No test application record retrieved. Insertion of test data failed.');
        // Get application's applicant then clone then update the birthdate of newly clone contact
        Contact masterContact = [SELECT Id, FirstName, LastName, MobilePhone, Email, Monash_Email_Address__c, Birthdate, SAP_Staff_Id__c, AccountId FROM Contact WHERE Id =: applications.get(0).Applicant__r.Id];
        System.assert(masterContact != null && masterContact.Id != null, '### Error fetching contact from application.');
        
        List<Account> accounts = new List<Account>();
        for (Integer i=1 ; i<10; i++) {
            Account temp_Account = new Account(
                Name = 'Test Account' + i
            );
            accounts.add(temp_Account);
        }
        insert accounts;
        Set<String> accountIds = new Set<String>();
        //WHEN: Community users are created, with similar values as the contact record associated with the application
        // Create duplicate contacts. No community user
        List<Contact> temp_duplicateContacts = new List<Contact>();
        for (Integer i=1 ; i<10; i++) {
            Contact temp_Contact = masterContact.clone(false,false,false,false);
            temp_Contact.AccountId = accounts.get(i-1).Id;
            temp_Contact.Birthdate = masterContact.Birthdate.addDays(i);
            temp_Contact.Person_ID_unique__c = 'PERSONUNIQUEID'+i;
            temp_duplicateContacts.add(temp_Contact);
            accountIds.add(accounts.get(i-1).Id);
        }
        insert temp_duplicateContacts;
        Set<Id> dupContactIds = new Set<Id>();
        for (Contact dupCon : temp_duplicateContacts) {
            if (dupCon.Id != null)
                dupContactIds.add(dupCon.Id);
        }
        // Create duplicate contacts. With Community User
        List<Contact> temp_duplicateContactsWithCommUser = new List<Contact>();
        for (Integer i=11 ; i<15; i++) {
            Contact temp_Contact = masterContact.clone(false,false,false,false);
            temp_Contact.Birthdate = masterContact.Birthdate.addDays(i);
            temp_Contact.AccountId = masterContact.AccountId;
            temp_duplicateContactsWithCommUser.add(temp_Contact);
        }
        insert temp_duplicateContactsWithCommUser;
        Integer counter = 1;
        for (Contact dupCon : temp_duplicateContactsWithCommUser) {
            if (dupCon.Id != null){
                setUpCommunity(dupCon, counter);
                dupContactIds.add(dupCon.Id);
                counter++;
            }
        }
        Test.startTest();
        AdmissionsDupCheckHelper helper = new AdmissionsDupCheckHelper();
        helper.init(masterContact.Id, dupContactIds);
        Test.stopTest();
        //THEN: The merge will be skipped
        List<Contact> remainingDupContacts = new List<Contact>([SELECT Id FROM Contact WHERE Id IN: dupContactIds]);
        System.debug('### testMergeContactsWithCommUser - remainingDupContacts value: '+ remainingDupContacts);
        System.assert(remainingDupContacts.size() == 4, '### Error! Merge functionality did not work!');
    }

    /**
     * Create Community User
     * @param conRec Contact Record
     */
    private static void setUpCommunity(Contact conRec, Integer iCnt) {
        Profile p = [SELECT Id FROM Profile WHERE Name = :UserServices.CUSTOMER_COMMUNITY_PROFILE_COMMON LIMIT 1];
        User u = new user();
        u.ProfileId = p.Id;
        u.LastName = conRec.LastName;
        u.Email = conRec.Email;
        u.ContactId = conRec.Id;
        u.Alias = 'testAl' + iCnt;
        u.Username = 'testComm@community.com' + iCnt;
        u.CommunityNickname = 'comm1234' + iCnt;
        u.LocaleSidKey = 'en_US';
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.LanguageLocaleKey = 'en_US';
        u.EmailEncodingKey = 'UTF-8';
        u.IsActive = true;
        insert u;
        System.assertNotEquals(null, u.Id, 'Community User Failed');
    }
    /*
     * @description     This method will create duplicate contacts to test showDupContacts method 
     * 					which displays duplicate contacts of Application's applicant
     *  Expected result: Duplicate contacts created will be added to the list duplicateContacts
     */
    static testMethod void test_showDupContacts() {
        //GIVEN: Duplicate Contacts are created
        List<Application__c> applications = new List<Application__c>([SELECT Id, Applicant__c, Applicant__r.Id FROM Application__c]);
        System.assert(applications.size() > 0, '### No test application record retrieved. Insertion of test data failed.');
        // Get application's applicant then clone then update the birthdate of newly clone contact
        Contact masterContact = [SELECT Id, FirstName, LastName, MobilePhone, Email, Monash_Email_Address__c, Birthdate, SAP_Staff_Id__c FROM Contact WHERE Id =: applications.get(0).Applicant__r.Id];
        System.assert(masterContact != null && masterContact.Id != null, '### Error fetching contact from application.');
        Contact cloneContact = masterContact.clone(false,false,false,false);
        cloneContact.Birthdate = masterContact.Birthdate.addDays(1);
        insert cloneContact;
        System.assert(cloneContact.Id != null, '### Insert clone contact failed.');
        Test.startTest();
        //WHEN: System searches for potential/partial duplicates
        List<TaskPartialMatchCtrl.ColumnDefinitionWrapper> result = TaskPartialMatchCtrl.getDataTableColumns();
        System.assert(result != null && !result.isEmpty(), '### Error! No field sets retrieved from Contact for Partial Match');
        List<Contact> duplicateContacts = TaskPartialMatchCtrl.showDupContacts(applications.get(0).Id, 30, 0);
        //THEN: Duplicates contacts will be shown on the table
        System.assert(
            duplicateContacts != null && !duplicateContacts.isEmpty(),
            '### Error! No duplicate contact retrieved!'
        );
        Test.stopTest();
    }
}