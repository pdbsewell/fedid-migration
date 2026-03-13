/**
@author Cartick Sub
@date 11 August 2020
@group Student Letters
@description Test class for StudentLettersHelper
@revision Initial version 11 August 2020
          Cartick Sub - 1 October 2020 - Add test method for Student Letter Log query
**/

@isTest(isParallel=true)
public class StudentLettersHelper_Test {
    
    /**
    @description Mock tests the HTTP callout to get student letter entitlements
    **/
    @isTest
    public static void validateGetEntitlementsFromAPI() {

        // Insert test Contact
        Contact testContact = (Contact)MonConTestDataFactory.createSObject(new Contact(), true);

        Test.startTest();

        // Ensure HTTP callout in next block is handled by mock response generator
        Test.setMock(HttpCalloutMock.class, new StudentLettersMockResponseGenerator());

        // Call method being tested
        String response = StudentLettersHelper.getEntitlementsFromAPI(testContact.Person_ID_unique__c);

        // Response should be that hard coded in mock response generator
        String actualValue = response;
        String expectedValue = '{"_links": {"_self": {"href": ""}},"entitlements": []}'; 
        System.assertEquals(actualValue, expectedValue);
        
        Test.stopTest();
    }

    @isTest
    public static void validateGetStudentLetterLogsFromSF() {

        Test.startTest();

        // Insert Contact
        Contact testContact = (Contact)MonConTestDataFactory.createSObject(new Contact(), true);

        // Insert Chat 365 Log - should auto-link to Contact under its trigger
        Chat_365_Log__c testChat365Log = (Chat_365_Log__c)MonConTestDataFactory.createSObject(new Chat_365_Log__c(), true);

        // Insert Chat 365 Detail Log
        Chat_365_Log_Detail__c testChat365LogDetail = (Chat_365_Log_Detail__c)MonConTestDataFactory.createSObject(new Chat_365_Log_Detail__c(), false);
        testChat365LogDetail.Chat_365_Log__c = testChat365Log.Id;
        insert testChat365LogDetail;

        // Insert Student Letter Log - should auto-link to same Contact as parent Chat 365 Log under trigger
        Student_Letter_Log__c testStudentLetterLog = new Student_Letter_Log__c(
            Chat_365_Log__c = testChat365Log.Id,
            Chat_365_Log_Detail__c = testChat365LogDetail.Id,
            Session_Id__c = testChat365Log.Session_Id__c,
            Channel__c = 'Chatbot',
            Letter_Description__c = 'MYEQ0202_ENROLMENT_VERIFICATION',
            Message__c = 'Test',
            Payment_Method__c = 'Test',
            Letter_Status__c = 'Completed'
        );
        insert testStudentLetterLog;

        // Call method being tested
        List<Student_Letter_Log__c> listStudentLetterLogsFromMethod = new List<Student_Letter_Log__c>();
        listStudentLetterLogsFromMethod = StudentLettersHelper.getStudentLetterLogsFromSF(testContact.Id);

        Test.stopTest();

        List<Student_Letter_Log__c> listStudentLetterLogsFromDB = new List<Student_Letter_Log__c>();
        listStudentLetterLogsFromDB = [SELECT Id FROM Student_Letter_Log__c];

        System.assertEquals(listStudentLetterLogsFromDB.size(), listStudentLetterLogsFromMethod.size(), 'Incorrect number of Student Letter Logs found in DB');
    }
}