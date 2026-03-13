/**
 * @description     Test class for TaskDupCheckHelper.cls
 * @author          J.Mapanao
 * @date            22/05/2019
 * 
 * @revision
 *                  25.FEB.2020 - J.Mapanao         - Added logic to handle account merge before the contact merge test case
 *                  07.JUL.2020 - KL                - Removing parallel test execution as it is affected by this known 
 *                                                  behaviour, see https://trailblazer.salesforce.com/ideaView?id=0873A000000lGvtQAE.  Also added existing logic from
 *                                                  TaskPartialMatchCtrl_Test.test_showDupContacts() to increase test coverage for this sibling class.
 *                  04.AUG.2020 - KL                - Additional checks for customised behaviour of boolean fields during a merge, part of SFTLG-996
 */
//@isTest(isParallel=true)
@isTest
private class TaskDupCheckHelper_Test {
    
    /*
     * @description This method will verify that existing contacts will be merged to Application's Applicant
     *              Expected result: Existing contacts will be merged to Application's Applicant (Contact record)
     */
    static testMethod void testMergeContacts() {
        List<Application__c> applications = new List<Application__c>([SELECT Id, Applicant__c, Applicant__r.Id FROM Application__c]);
        System.assert(applications.size() > 0, '### No test application record retrieved. Insertion of test data failed.');
        // Get application's applicant then clone then update the birthdate of newly clone contact
        Contact masterContact = [SELECT Id, FirstName, LastName, MobilePhone, Email, Monash_Email_Address__c, Birthdate, SAP_Staff_Id__c FROM Contact WHERE Id =: applications.get(0).Applicant__r.Id];
        System.assert(masterContact != null && masterContact.Id != null, '### Error fetching contact from application.');
        Id householdAccountRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Household_Account').getRecordTypeId();
        List<Account> accounts = new List<Account>();
        for (Integer i=1 ; i<10; i++) {
            Account temp_Account = new Account(
                Name = 'Test Account' + i,
                RecordTypeId = householdAccountRecTypeId
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
        Test.startTest();
        TaskDupCheckHelper helper = new TaskDupCheckHelper();
        helper.init(masterContact.Id, dupContactIds);
        Test.stopTest();
        List<Contact> remainingDupContacts = new List<Contact>([SELECT Id FROM Contact WHERE Id IN: dupContactIds]);
        System.assert(
            remainingDupContacts.isEmpty(),
            '### Error! Merge functionality did not work!'
        );
        Contact mergedContact = [SELECT Id, DoNotCall, isAskMonashCreated__c, Deleted_In_Source__c FROM Contact WHERE Id = :applications.get(0).Applicant__r.Id LIMIT 1];
        System.assertEquals(true, mergedContact.DoNotCall, 'Assertion failed for Boolean OR during merge operation');
        System.assertEquals(true, mergedContact.isAskMonashCreated__c, 'Assertion failed for Boolean AND during merge operation - positive');
        System.assertEquals(false, mergedContact.Deleted_In_Source__c, 'Assertion failed for Boolean AND during merge operation');
    }

    /*
     * @description This method will verify that existing contacts will be merged to Application's Applicant
     *              Expected result: Existing contacts will be merged to Application's Applicant (Contact record)
     */
    static testMethod void testMergeContactsWithCommUser() {
        List<Application__c> applications = new List<Application__c>([SELECT Id, Applicant__c, Applicant__r.Id FROM Application__c]);
        System.assert(applications.size() > 0, '### No test application record retrieved. Insertion of test data failed.');
        // Get application's applicant then clone then update the birthdate of newly clone contact
        Contact masterContact = [SELECT Id, FirstName, LastName, MobilePhone, Email, Monash_Email_Address__c, Birthdate, SAP_Staff_Id__c, AccountId FROM Contact WHERE Id =: applications.get(0).Applicant__r.Id];
        System.assert(masterContact != null && masterContact.Id != null, '### Error fetching contact from application.');
        Id householdAccountRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Household_Account').getRecordTypeId();
        List<Account> accounts = new List<Account>();
        for (Integer i=1 ; i<10; i++) {
            Account temp_Account = new Account(
                Name = 'Test Account' + i,
                RecordTypeId = householdAccountRecTypeId
            );
            accounts.add(temp_Account);
        }
        insert accounts;
        Set<String> accountIds = new Set<String>();
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
        TaskDupCheckHelper helper = new TaskDupCheckHelper();
        helper.init(masterContact.Id, dupContactIds);
        Test.stopTest();
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
    
    static testMethod void test_showDupContacts() {
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
        List<TaskPartialMatchCtrl.ColumnDefinitionWrapper> result = TaskPartialMatchCtrl.getDataTableColumns();
        System.assert(result != null && !result.isEmpty(), '### Error! No field sets retrieved from Contact for Partial Match');
        List<Contact> duplicateContacts = TaskPartialMatchCtrl.showDupContacts(applications.get(0).Id, 30, 0);
        System.assert(
            duplicateContacts != null && !duplicateContacts.isEmpty(),
            '### Error! No duplicate contact retrieved!'
        );
        Test.stopTest();
    }

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
}