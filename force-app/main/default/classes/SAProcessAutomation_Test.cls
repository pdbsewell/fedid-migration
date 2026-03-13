/**
 * @description       : Test Class for SAProcessAutomation
 * @author            : Angelo Rivera
 * @group             : Test Class
 * @last modified on  : 2021-01-21
 * @last modified by  : Angelo Rivera
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2021-01-21 - Angelo Rivera   - Initial Creation
 * 1.1   2025-02-25 - Matthew Maramot - EPCP-4204 Updated API version + Assert methods
**/

@IsTest
private class SAProcessAutomation_Test {
    @IsTest
    static void testWIProcessAutomation() {
        //Create MIX_RPA_Settings
        MonConTestDataFactory.createSObject(new MIX_RPA_Settings__c(), true);

        //Create test contact to associate the enquiry with
        Contact testContact = (Contact)MonConTestDataFactory.createSObject(new Contact(), true);
        Id caseRecType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Special_Consideration').getRecordTypeId();
        Case cse = (Case)MonConTestDataFactory.createSObject(new Case());
        cse.SuppliedEmail = 'testEmail@test.edu';
        cse.Enquiry_Type__c = 'Special Circumstances';
        cse.RecordTypeId = caseRecType;
        insert cse;

        Course__c crs = (Course__c)MonConTestDataFactory.createSObject(new Course__c(), true);

        Course_Attempt__c ca = new Course_Attempt__c();
        ca.Name = 'Test Course Attempt';
        ca.Course__c = crs.Id;
        ca.Contact__c = testContact.Id;
        insert ca;

        Unit_Attempt__c ua = new Unit_Attempt__c();
        ua.Unit_Code__c = 'UU1027';
        ua.Title__c = 'Test Unit Attempt';
        ua.Teaching_Period__c = '1';
        ua.Academic_Year__c  = '2021';
        ua.Grade__c = 'C';
        ua.Course_Attempt__c = ca.Id;
        ua.Calendar_Type__c = 'Test';
        ua.CI_Sequence_Number__c = '123214';
        insert ua;

        Id recType = Schema.SObjectType.Case_Unit_Attempt__c.getRecordTypeInfosByDeveloperName().get('Special_Circumstance').getRecordTypeId();
        Case_Unit_Attempt__c cua = new Case_Unit_Attempt__c();
        cua.RecordTypeId = recType;
        cua.WI_Status__c = 'Approved';
        cua.Unit_Attempt__c = ua.Id;
        cua.Enquiry__c = cse.Id;
        insert cua;

        //GIVEN: A Withdrawn Incomplete case exists
        Test.startTest();

        //WHEN: The call out is initiated
        String strReturn = SAProcessAutomation.wiProcessAutomation(cse.Id);
        Test.stopTest();

        //THEN: We obtain success message
        Assert.areEqual('Approved units are successfully sent for grade update to Callista.', strReturn);
    }
}