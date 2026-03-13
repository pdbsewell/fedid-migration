/**
@author Cartick Sub
@date 17 September 2020
@group Test classes
@description Sibling test class for StudentLetterLogTriggerHandler
@revision Initial version - 17 September 2020
**/

@isTest(isParallel=true)
public class StudentLetterLogTriggerHandler_Test {

    /**
    @description Test method to validate if, on insert of a Student Letter Log, it is linked to the Contact for its parent Chat 365 Log
    @revision Initial version 17 September 2020
    **/
    @IsTest
    public static void validateLinkContactOnInsert() {

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
            Session_Id__c = testChat365Log.Session_Id__c
        );
        insert testStudentLetterLog;

        Test.stopTest();

        // Retrieve Chat 365 Log and Student Letter Log from database
        List<Chat_365_Log__c> listChat365LogsFromDB = [SELECT Id, Contact__c FROM Chat_365_Log__c];
        List<Student_Letter_Log__c> listStudentLetterLogsFromDB = [SELECT Id, Contact__c FROM Student_Letter_Log__c];

        System.assertEquals(listChat365LogsFromDB[0].Contact__c, listStudentLetterLogsFromDB[0].Contact__c, 'Student Letter Log not linked to Contact');

    }

    /**
    @description Test method to validate if, on insert of a Student Letter Log, it is linked to the latest Enquiry for its parent Chat 365 Log
    @revision Initial version 17 September 2020
    **/
    @IsTest
    public static void validateLinkEnquiryOnInsert() {

        Test.startTest();

        // Insert Contact
        Contact testContact = (Contact)MonConTestDataFactory.createSObject(new Contact(), true);

        // Insert Chat 365 Log - should auto-link to Contact under its trigger
        Chat_365_Log__c testChat365Log = (Chat_365_Log__c)MonConTestDataFactory.createSObject(new Chat_365_Log__c(), true);

        // Insert Chat 365 Detail Log - should automatically create Enquiry under its trigger
        Chat_365_Log_Detail__c testChat365LogDetail = (Chat_365_Log_Detail__c)MonConTestDataFactory.createSObject(new Chat_365_Log_Detail__c(), false);
        testChat365LogDetail.Chat_365_Log__c = testChat365Log.Id;
        testChat365LogDetail.Intent__c = 1;
        insert testChat365LogDetail;

        // Insert two Enquiries
        /*Case testEnquiry1 = new Case(
            Chat_365_Log__c = testChat365Log.Id,
            Subject = 'Test 1'
        );
        insert testEnquiry1;

        Case testEnquiry2 = new Case(
            Chat_365_Log__c = testChat365Log.Id,
            Subject = 'Test 2'
        );
        insert testEnquiry2;*/

        // Insert Student Letter Log - should auto-link to Enquiry under trigger
        Student_Letter_Log__c testStudentLetterLog = new Student_Letter_Log__c(
            Chat_365_Log__c = testChat365Log.Id,
            Chat_365_Log_Detail__c = testChat365LogDetail.Id,
            Session_Id__c = testChat365Log.Session_Id__c,
            Enquiry__c = null
        );
        insert testStudentLetterLog;

        Test.stopTest();

        // Retrieve Enquiry and Student Letter Log from database
        List<Case> listEnquiryFromDB = [SELECT Id FROM Case];
        List<Student_Letter_Log__c> listStudentLetterLogsFromDB = [SELECT Id, Enquiry__c FROM Student_Letter_Log__c];

        System.assertEquals(listEnquiryFromDB[0].Id, listStudentLetterLogsFromDB[0].Enquiry__c, 'Student Letter Log not linked to Enquiry');

    }

    /**
    @description Test method to validate if, on insert of a Student Letter Log, it not linked to a Contact or Enquiry when that is not required
    @revision Initial version 17 September 2020
    **/
    @IsTest
    public static void validateLinkOnInsertNegative() {
        
        Test.startTest();

        // Insert Chat 365 Log - should not auto-link to Contact as no Contacts have been inserted
        Chat_365_Log__c testChat365Log = (Chat_365_Log__c)MonConTestDataFactory.createSObject(new Chat_365_Log__c(), true);

        // Insert Chat 365 Detail Log
        Chat_365_Log_Detail__c testChat365LogDetail = (Chat_365_Log_Detail__c)MonConTestDataFactory.createSObject(new Chat_365_Log_Detail__c(), false);
        testChat365LogDetail.Chat_365_Log__c = testChat365Log.Id;
        insert testChat365LogDetail;

        // Do not insert any Enquiries

        // Insert Student Letter Log - should not auto-link to Contact as parent Chat 365 Log Contact is blank
        Student_Letter_Log__c testStudentLetterLog = new Student_Letter_Log__c(
            Chat_365_Log__c = testChat365Log.Id,
            Chat_365_Log_Detail__c = testChat365LogDetail.Id,
            Session_Id__c = testChat365Log.Session_Id__c
        );
        insert testStudentLetterLog;

        Test.stopTest();

        // Retrieve Student Letter Log from database
        List<Student_Letter_Log__c> listStudentLetterLogsFromDB = [SELECT Id, Contact__c, Enquiry__c FROM Student_Letter_Log__c];

        System.assertEquals(null, listStudentLetterLogsFromDB[0].Contact__c, 'Student Letter Log should not be linked to Contact when parent Chat 365 Log is not');
        System.assertEquals(null, listStudentLetterLogsFromDB[0].Enquiry__c, 'Student Letter Log should not be linked to Enquiry when parent Chat 365 Log has none');
    }

}