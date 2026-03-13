/**
 * @description       : Test class for ProcessCourseIntermissionCC
 * @author            : Angelo Rivera
 * @group             : Test Class
 * @last modified on  : 2021-05-05
 * @last modified by  : Angelo Rivera
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2021-05-05 - Angelo Rivera - Initial Creation
 * 1.1   2021-06-24 - Inderpal Dhanoa - SA-667 Reason parameter in Payload
 * 1.2   2023-07-19 - Inderpal Dhanoa - MCT-154 Course Description in Payload
 * 1.3   2025-02-25 - Matthew Maramot - EPCP-4204 Updated API version + Assert methods
**/

@isTest(isParallel=true)
private class ProcessCourseIntermissionCC_Test {
    @IsTest
    static void testProcessCourseIntermission() {
        //Create MIX_RPA_Settings
        MonConTestDataFactory.createSObject(new MIX_RPA_Settings__c(), true);

        //Create test contact to associate the enquiry with
        Contact testContact = (Contact)MonConTestDataFactory.createSObject(new Contact(Email='testcontact@test.com'), true);

        Course__c crs = (Course__c)MonConTestDataFactory.createSObject(new Course__c(), true);

        Course_Attempt__c ca = new Course_Attempt__c();
        ca.Name = 'Test Course Attempt';
        ca.Course__c = crs.Id;
        ca.Contact__c = testContact.Id;
        ca.Location__c = 'Clayton';
        ca.Course_Attempt_Status__c = 'Enrolled';
        insert ca;

        Id caseRecType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Monash_Connect_Enquiry').getRecordTypeId();
        Case cse = (Case)MonConTestDataFactory.createSObject(new Case());
        cse.SuppliedEmail = 'testEmail@test.edu';
        cse.Enquiry_Type__c = 'Current Course';
        cse.Category_Level_1__c = 'International Visa';
        cse.Category_Level_1__c = 'Change of Residency';
        cse.RecordTypeId = caseRecType;
        cse.Course_Attempt__c = ca.Id;
        cse.ContactId = testContact.Id;
        insert cse;

		// GIVEN: A Case exists
        Test.startTest();
		
		//WHEN: A Callout is initiated
        SingleRequestMock fakeResponse = new SingleRequestMock(200,
                'Complete',
                '{\n' +
                        '  "queueDefinitionId": 625,\n' +
                        '  "referenceKey": "57ae5735-449c-4c08-bd96-9aa7b050a327",\n' +
                        '  "referenceId": "20202020-D6000",\n' +
                        '  "message": "Request submitted."\n' +
                        '}',
                null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        ProcessCourseIntermissionCC.ThisWrapper thisWrapper = ProcessCourseIntermissionCC.doInit(cse.Id);
        String sDate = '15/03/2021', eDate = '14/03/2021', crsCode='MARK1234', enrolmentExceptionsLine = '2020|24|24', secondaryReason = 'test Reason', secondaryReasonFreeText = 'secondary Reason Free Text', courseCodeKey = 'Test Course Description';

        String strReturn = ProcessCourseIntermissionCC.processCourseInformation(cse.Id,  crsCode,sDate, eDate,enrolmentExceptionsLine,secondaryReason, secondaryReasonFreeText, courseCodeKey);
        Test.stopTest();
		//THEN: The Return is not empty
        Assert.areEqual(thisWrapper.bValidContactEmail, true);
        Assert.areNotEqual(null, strReturn);
        Case updatedEnquiry = [SELECT Id, JSON_Payload__c FROM Case WHERE Id = :cse.Id];
        Assert.areEqual(updatedEnquiry.JSON_Payload__c, 'Test Course Description');
    }
}