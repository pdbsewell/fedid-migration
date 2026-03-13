/**
 * @description     Test class for TaskPartialMatchCtrl.cls
 * @author          J.Mapanao
 * @date            24/05/2019
 * 
 * @revision
 *                  25.MAY.2020 KL: changes for epic SFTLG-802
 */
@isTest(isParallel=true)
private class TaskPartialMatchCtrl_Test {
    
    /*
     * @description This method will test if there is field set (used for column definition) exists for TaskPartialMatch.cmp
     *              Expected result: Retrieve field set from Contact where api name is Partial_Match_Field_Sets
     */
    static testMethod void test_getDataTableColumns() {
        Test.startTest();
        List<TaskPartialMatchCtrl.ColumnDefinitionWrapper> result = TaskPartialMatchCtrl.getDataTableColumns();
        System.assert(
            result != null && !result.isEmpty(),
            '### Error! No field sets retrieved from Contact for Partial Match'
        );
        Test.stopTest();
    }

    /*
     * @description This method will check if Application's Applicant exists
     *              Expected result: Application's Applicant will be retrieved
     */
    static testMethod void test_showMasterContact() {
        List<Application__c> applications = [SELECT Id FROM Application__c];
        System.assert(applications != null && !applications.isEmpty(), '### Error! No Application retrieved!');
        List<TaskPartialMatchCtrl.ColumnDefinitionWrapper> result = TaskPartialMatchCtrl.getDataTableColumns();
        System.assert(result != null && !result.isEmpty(), '### Error! No field sets retrieved from Contact for Partial Match');
        Test.startTest();
        List<Contact> masterContact = TaskPartialMatchCtrl.showMasterContact(applications.get(0).Id);
        System.assert(
            masterContact != null && !masterContact.isEmpty(),
            '### Error! No master contact retrieved!'
        );
        Test.stopTest();
    }

    /*
     * @description This method will check if there are potential duplicate contact records for Application's Applicant
     *              Expected result: return a list of potential duplicate contact records
     */
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

    /*
     * @description This method will verify that existing contacts will be merged to Application's Applicant
     *              Expected result: Existing contacts will be merged to Application's Applicant (Contact record)
     */
    static testMethod void test_mergeContacts() {

        //Enable Roll up / down and break up
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Down__c = true;
        cs.Enable_Roll_Up__c = true;
        cs.EnableChannelBreakUp__c = true;
        upsert cs;

        List<Application__c> applications = new List<Application__c>([SELECT Id, Applicant__c, Applicant__r.Id FROM Application__c]);
        System.assert(applications.size() > 0, '### No test application record retrieved. Insertion of test data failed.');
        // Get application's applicant then clone then update the birthdate of newly clone contact
        Contact masterContact = [SELECT Id, FirstName, LastName, MobilePhone, Email, Monash_Email_Address__c, Birthdate, SAP_Staff_Id__c FROM Contact WHERE Id =: applications.get(0).Applicant__r.Id];
        System.assert(masterContact != null && masterContact.Id != null, '### Error fetching contact from application.');
        // Create Parent Accounts
        List<Account> accounts = new List<Account>();
        for (Integer i=1 ; i<6; i++) {
            Account temp_Account = new Account(
                Name = 'Test Account' + i
            );
            accounts.add(temp_Account);
        }
        insert accounts;
        // Create duplicate contacts
        List<Contact> temp_duplicateContacts = new List<Contact>();
        for (Integer i=1 ; i<6; i++) {
            Contact temp_Contact = masterContact.clone(false,false,false,false);
            temp_Contact.AccountId = accounts.get(i-1).Id;
            temp_Contact.Birthdate = masterContact.Birthdate.addDays(i);
            temp_Contact.Email = 'test@test.com';
            temp_duplicateContacts.add(temp_Contact);
        }
        insert temp_duplicateContacts;
        List<Id> dupContactIds = new List<Id>();
        for (Contact dupCon : temp_duplicateContacts) {
            if (dupCon.Id != null)
                dupContactIds.add(dupCon.Id);
        }
        Test.startTest();
        TaskPartialMatchCtrl.mergeContacts(applications.get(0).Id, JSON.serialize(dupContactIds));
        Test.stopTest();
        List<Contact> remainingDupContacts = new List<Contact>([SELECT Id FROM Contact WHERE Id IN: dupContactIds]);
        System.assert(
            remainingDupContacts.isEmpty(),
            '### Error! Merge functionality did not work!'
        );
    }

    @testSetup static void setup() {
        // Create test account
        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        insert testAccount;
        System.assert(testAccount.Id != null, '### Insert Test Account Failed.');
        
        //Create test contact
        Contact testContact = new Contact();
        testContact.FirstName = 'Test FirstName';
        testContact.LastName = 'Test LastName';
        testContact.MobilePhone = '0481977625';
        testContact.Email = 'testemail001@monash.edu';
        testContact.Monash_Email_Address__c = 'testemailmonash@monash.edu';
        testContact.Birthdate = Date.today().addYears(-11);
        testContact.SAP_Staff_Id__c = '';
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