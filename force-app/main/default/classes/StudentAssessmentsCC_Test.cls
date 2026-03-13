/**
 * @description      : Test class for UpdateMoodleCC
 * @author            : Angelo Rivera
 * @group             : Test Class
 * @last modified on  : 04-10-2021
 * @last modified by  : Angelo Rivera
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   04-10-2021 - Angelo Rivera - Initial Creation
**/

@IsTest(IsParallel=true)
private class StudentAssessmentsCC_Test {

    @IsTest
    static void testGetAssessments() {

        //Create test contact to associate the enquiry with
        Contact testContact = (Contact)MonConTestDataFactory.createSObject(new Contact(), true);

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

        Unit_Offering__c uo = new Unit_Offering__c();
        uo.Unit_Code__c = '123';
        uo.Unit_Version__c = '1';
        uo.Title__c = 'Test';
        uo.UOO_ID__c = '12345';
        insert uo;

        Unit_Attempt__c ua = new Unit_Attempt__c();
        ua.Name = 'test';
        ua.Course_Attempt__c = ca.Id;
        ua.Unit_Code__c = '12345';
        ua.Calendar_Type__c = '123';
        ua.CI_Sequence_Number__c = '123';
        ua.Unit_Offering__c = uo.Id;
        insert ua;

        Id cuaRecType = Schema.SObjectType.Case_Unit_Attempt__c.getRecordTypeInfosByDeveloperName().get('Special_Consideration').getRecordTypeId();
        Case_Unit_Attempt__c cua = new Case_Unit_Attempt__c();
        cua.RecordTypeId = cuaRecType;
        cua.Enquiry__c = cse.Id;
        cua.Origin__c = 'Moodle eLMS';
        cua.Status__c = 'Approved Extension';
        cua.Assessment_Type__c = 'Assignment';
        cua.Moodle_Assessment_ID__c = '1234567';
        cua.Assessment_Due_Date_Original__c = System.today();
        cua.Assessment_Due_Date_New__c = System.today();
        cua.Requested_Outcome__c = 'Assignment Extension';
        cua.Unit_Attempt__c = ua.Id;
        insert cua;

        Test.startTest();
        SingleRequestMock fakeResponse = new SingleRequestMock(200,
                'Success',
                '[\n' +
                        '  {\n' +
                        '    "id": 336481,\n' +
                        '    "cmid": 6373370,\n' +
                        '    "unitOfferingId": 1950992,\n' +
                        '    "type": "Forums",\n' +
                        '    "name": "Announcements",\n' +
                        '    "dueDate": "1970-01-01T00:00:00Z",\n' +
                        '    "cutoffDate": "1970-01-01T00:00:00Z"\n' +
                        '  },\n' +
                        '  {\n' +
                        '    "id": 336482,\n' +
                        '    "cmid": 6373371,\n' +
                        '    "unitOfferingId": 1950992,\n' +
                        '    "type": "Forums",\n' +
                        '    "name": "General Discussion Forum",\n' +
                        '    "dueDate": "1970-01-01T00:00:00Z",\n' +
                        '    "cutoffDate": "1970-01-01T00:00:00Z"\n' +
                        '  }' +
                        ']',
                null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Id cuaId = [SELECT Id FROM Case_Unit_Attempt__c LIMIT 1].Id;
        List<StudentAssessmentWrapper> strReturn = StudentAssessmentsCC.retrieveAssessments(cuaId);
        Test.stopTest();

        System.assertNotEquals(null, strReturn);
    }
}