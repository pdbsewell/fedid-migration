/*******************************************************************************
* @author       Seeva
* @date         28/7/2023
* @description  Test class for  AdmissionDupCheckServices
* @revision     
****************************************************************/
@isTest(isParallel=true)
public class AdmissionDupCheckServices_Test {
    @testSetup static void setup() {
        Feature_Switch__c fs = new  Feature_Switch__c();
        fs.Enable_Enhanced_Admissions_Contact_Merge__c = true;
        fs.Enable_CPA_for_Contact_Merge__c  = true;
        insert fs;
        // PERFECT Match Scenario
		
        //Create test contact 1
        List<Contact> contactToInsert = new List<contact>();
        Contact testContact = new Contact();
        testContact.FirstName = 'Test FirstName';
        testContact.LastName = 'Test LastName';
        testContact.MobilePhone = '0481977625';
        testContact.Email = 'testemail001@monash.edu';
        testContact.Monash_Email_Address__c = 'testemailmonash@monash.edu';
        testContact.Birthdate = Date.today().addYears(-11);
        testContact.SAP_Staff_Id__c = '';
		contactToInsert.add(testContact);
        
        //Create test contact 2
        Contact testContactDup = new Contact();
        testContactDup.FirstName = 'Test FirstName';
        testContactDup.LastName = 'Test LastName';
        testContactDup.MobilePhone = '0481977625';
        testContactDup.Email = 'testemail001@monash.edu';
        testContactDup.Birthdate = Date.today().addYears(-11);
        testContactDup.SAP_Staff_Id__c = '';
        contactToInsert.add(testContactDup);
        
        Contact testContact3 = new Contact();
        testContact3.FirstName = 'Anothertest FirstName';
        testContact3.LastName = 'Anothertest LastName';
        testContact3.MobilePhone = '0481000000';
        testContact3.Email = 'Anothertest@monash.edu';
        testContact3.Monash_Email_Address__c = 'Anothertest@monash.edu';
        testContact3.Birthdate = Date.today().addYears(-11);
        testContact3.SAP_Staff_Id__c = '';
        contactToInsert.add(testContact3);
        
        //Create test contact 4
        Contact testContact4 = new Contact();
        testContact4.FirstName = 'Anothertest FirstName';
        testContact4.LastName = 'Anothertest LastName';
        testContact4.MobilePhone = '0481000000';
        testContact4.Email = 'Anothertest@monash.edu';
        testContact4.Birthdate = Date.today().addYears(-11);
        testContact4.Birthdate = Date.today().adddays(1);
        testContact4.SAP_Staff_Id__c = '';
        contactToInsert.add(testContact4);
        
        Contact testContact5 = new Contact();
        testContact5.FirstName = 'Anothertest FirstName';
        testContact5.LastName = 'Anothertest LastName1';
        testContact5.MobilePhone = '0481000000';
        testContact5.Email = 'Anothertest1@monash.edu';
        testContact5.Birthdate = Date.today().addYears(-11);
        testContact5.Birthdate = Date.today().adddays(1);
        testContact5.SAP_Staff_Id__c = '';
        contactToInsert.add(testContact5);
        insert contactToInsert;
        
        //Create Application
        List<Application__c> applicationsToInsert = new List<Application__c>();
        Application__c testApplication = new Application__c();
        testApplication.Applicant__c = contactToInsert[0].Id;
        testApplication.Status__c = 'Draft';
        applicationsToInsert.add(testApplication);
        
        //Create Application
        Application__c testApplication2 = new Application__c();
        testApplication2.Applicant__c = contactToInsert[3].Id;
        testApplication2.Status__c = 'Draft';
        applicationsToInsert.add(testApplication2);

        //Create Application
        Application__c testApplication3 = new Application__c();
        testApplication3.Applicant__c = contactToInsert[4].Id;
        testApplication3.Status__c = 'Draft';
        applicationsToInsert.add(testApplication3);
        insert applicationsToInsert;
    
    }
    /**
     * @description - Test method to submit applications for corresponding perfect match contacts. 
     * In case of perfect match the application status should be "Sent for Submission" 
     */
    static testMethod void submitPerfectMatch() {

        List<Application__c> application = new List<Application__c>([SELECT Id, Applicant__c, Applicant__r.Id, Status__c  FROM Application__c WHERE Applicant__r.Email = 'testemail001@monash.edu']);
        System.assert(application.size() > 0, '### No test application record fetched. Insertion of test data failed.');
        Test.startTest();
        application.get(0).Status__c = MyApplicationUtilities.APP_PENDING_MERGE_STATUS;
        update application.get(0);
        Test.stopTest();
        List<Contact> originalContact = new List<Contact>([SELECT Id FROM Contact WHERE Email = 'testemail001@monash.edu']);
        System.assertEquals(1, originalContact.size(), '### Error: victim record still exists!');
        System.assertEquals(MyApplicationUtilities.APP_SENT_FOR_SUBMIT_STATUS, [SELECT Status__c  FROM Application__c WHERE Id = :application.get(0).Id].Status__c, '### Error: application record status not set correctly!');

    }
	/**
     * @description - Test method to submit applications for corresponding partial match contacts. 
     * In case of Partial match the application status is Submission on Hold (Duplicate Contact)  
     */
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
	/**
     * @description - Test method to test merge of partialmatch contacts. 
     * 
     */
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
	/**
     * @description - Test option for submission of application where no contact match is found. 
     * Expectation - In this scenario the Task_Duplicate_Check__c is 'Not Required' as no merge required.
     */
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