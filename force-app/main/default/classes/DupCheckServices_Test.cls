/**
* @author KL
* @date 22.05.2020
*
* @group Duplicate Management
*
* @description Sibling test class for service class providing features needed for Duplicate Management
*
* @revision
*           22.05.2020 - KL: Initial Create
*           22.07.2020 - KL: Updated assert conditions to suit changes due to SFTLG-995
*/
@isTest(isParallel=true)
public class DupCheckServices_Test {

    @testSetup static void setup() {
        // TO DO: when time permits, should refactor student first related testing data prep into a common utility / TDF
        
        // PERFECT Match Scenario

        //Create test contact 1
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

        //Create test contact 2
        Contact testContactDup = new Contact();
        testContactDup.FirstName = 'Test FirstName';
        testContactDup.LastName = 'Test LastName';
        testContactDup.MobilePhone = '0481977625';
        testContactDup.Email = 'testemail001@monash.edu';
        testContactDup.Birthdate = Date.today().addYears(-11);
        testContactDup.SAP_Staff_Id__c = '';
        insert testContactDup;
        System.assert(testContactDup.Id != null, '### Insert Test Contact Dup Failed.');
        
        //Create Application
        Application__c testApplication = new Application__c();
        testApplication.Applicant__c = testContactDup.Id;
        testApplication.Status__c = 'Draft';
        insert testApplication;
        System.assert(testApplication.Id != null, '### Insert Test Application Failed.');

        // POTENTIAL Match Scenario

        //Create test contact 3
        Contact testContact3 = new Contact();
        testContact3.FirstName = 'Anothertest FirstName';
        testContact3.LastName = 'Anothertest LastName';
        testContact3.MobilePhone = '0481000000';
        testContact3.Email = 'Anothertest@monash.edu';
        testContact3.Monash_Email_Address__c = 'Anothertest@monash.edu';
        testContact3.Birthdate = Date.today().addYears(-11);
        testContact3.SAP_Staff_Id__c = '';
        insert testContact3;
        System.assert(testContact3.Id != null, '### Insert Test Contact Failed.');

        //Create test contact 4
        Contact testContact4 = new Contact();
        testContact4.FirstName = 'Anothertest FirstName';
        testContact4.LastName = 'Anothertest LastName';
        testContact4.MobilePhone = '0481000000';
        testContact4.Email = 'Anothertest@monash.edu';
        testContact4.Birthdate = Date.today().addYears(-11);
        testContact4.Birthdate = Date.today().adddays(1);
        testContact4.SAP_Staff_Id__c = '';
        insert testContact4;
        System.assert(testContact4.Id != null, '### Insert Test Contact Failed.');

        //Create Application
        Application__c testApplication2 = new Application__c();
        testApplication2.Applicant__c = testContact4.Id;
        testApplication2.Status__c = 'Draft';
        insert testApplication2;
        System.assert(testApplication2.Id != null, '### Insert Test Application Failed.');

        //Create test contact 5
        Contact testContact5 = new Contact();
        testContact5.FirstName = 'Anothertest FirstName';
        testContact5.LastName = 'Anothertest LastName1';
        testContact5.MobilePhone = '0481000000';
        testContact5.Email = 'Anothertest1@monash.edu';
        testContact5.Birthdate = Date.today().addYears(-11);
        testContact5.Birthdate = Date.today().adddays(1);
        testContact5.SAP_Staff_Id__c = '';
        insert testContact5;
        System.assert(testContact5.Id != null, '### Insert Test Contact Failed.');

        //Create Application
        Application__c testApplication3 = new Application__c();
        testApplication3.Applicant__c = testContact5.Id;
        testApplication3.Status__c = 'Draft';
        insert testApplication3;
        System.assert(testApplication3.Id != null, '### Insert Test Application Failed.');

    }
    
    static testMethod void submitPerfectMatch() {

        List<Application__c> application = new List<Application__c>([SELECT Id, Applicant__c, Applicant__r.Id, Status__c  FROM Application__c WHERE Applicant__r.Email = 'testemail001@monash.edu']);
        System.assert(application.size() > 0, '### No test application record fetched. Insertion of test data failed.');
        Test.startTest();
        application.get(0).Status__c = MyApplicationUtilities.APP_PENDING_MERGE_STATUS;
        update application.get(0);
        Test.stopTest();
        List<Contact> originalContact = new List<Contact>([SELECT Id FROM Contact WHERE Email = 'testemail001@monash.edu']);
        // System.assertEquals(0, originalContact.size(), '### Error: victim record still exists!');
        // changes to accomodate SFTLG-995.  Original logic above uses unique value from victim record in a merge to determine that the victim no longer exists after merge, 
        // SOQL selects using victim specific value, and assert 0 rows returned. with 995, the non-null value in the victim v.s. the null on the survivor is retained and preserved.
        // change logic to use email, and assert only 1 record
        System.assertEquals(1, originalContact.size(), '### Error: victim record still exists!');
        System.assertEquals(MyApplicationUtilities.APP_SENT_FOR_SUBMIT_STATUS, [SELECT Status__c  FROM Application__c WHERE Id = :application.get(0).Id].Status__c, '### Error: application record status not set correctly!');

    }

    static testMethod void submitPartialMatch() {
        
        List<Application__c> application = new List<Application__c>([SELECT Id, Applicant__c, Applicant__r.Id, Status__c  FROM Application__c WHERE Applicant__r.Email = 'Anothertest@monash.edu']);
        System.assert(application.size() > 0, '### No test application record fetched. Insertion of test data failed.');
        Test.startTest();
        application.get(0).Status__c = MyApplicationUtilities.APP_PENDING_MERGE_STATUS;
        update application.get(0);
        Test.stopTest();        
        List<Application__c> updatedApplication = new List<Application__c>([SELECT Id, Applicant__c, Applicant__r.Id, Status__c, Task_Duplicate_Check__c  FROM Application__c WHERE Applicant__r.Email = 'Anothertest@monash.edu']);
        System.assertEquals('Required', updatedApplication.get(0).Task_Duplicate_Check__c, '### Error: application record not flagged with potential duplicate!');
        System.assertEquals(MyApplicationUtilities.APP_PENDING_MERGE_STATUS, [SELECT Status__c  FROM Application__c WHERE Id = :application.get(0).Id].Status__c, '### Error: application record status not set correctly!');
        		
    }

    static testMethod void mergePartialMatch() {

        Test.startTest();
        Date dupContactBirthdate = Date.today().addYears(-11);
        dupContactBirthdate = Date.today().adddays(1);
        List<Application__c> updatedApplication = new List<Application__c>([SELECT Id, Applicant__c, Applicant__r.Id, Status__c, Task_Duplicate_Check__c  FROM Application__c WHERE Applicant__r.Email = 'Anothertest@monash.edu']);
        List<Contact> dupContact = [SELECT Id FROM Contact WHERE Email = 'Anothertest@monash.edu' AND Birthdate = :dupContactBirthdate];
        System.assert(dupContact.size() > 0, '### Fetch duplicate contact failed.');
        List<Id> dupContactIdList = new List<Id>();
        dupContactIdList.add(dupContact.get(0).Id);
        TaskPartialMatchCtrl.mergeContacts(updatedApplication.get(0).Id, JSON.serialize(dupContactIdList));
        Test.getEventBus().deliver();        
        Test.stopTest();        
    }

    static testMethod void submitNoMatch() {

        List<Application__c> application = new List<Application__c>([SELECT Id, Applicant__c, Applicant__r.Id, Status__c  FROM Application__c WHERE Applicant__r.LastName = 'Anothertest LastName1']);
        System.assert(application.size() > 0, '### No test application record fetched. Insertion of test data failed.');
        Test.startTest();
        application.get(0).Status__c = MyApplicationUtilities.APP_PENDING_MERGE_STATUS;
        update application.get(0);
        Test.stopTest();
        List<Application__c> updatedApplication = new List<Application__c>([SELECT Id, Applicant__c, Applicant__r.Id, Status__c, Task_Duplicate_Check__c  FROM Application__c WHERE Applicant__r.LastName = 'Anothertest LastName1']);
        System.assertEquals('Not Required', updatedApplication.get(0).Task_Duplicate_Check__c, '### Error: application record not flagged with potential duplicate!');
        
    }

}