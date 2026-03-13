/*
 * SA-718 Test class to confirm SMSServices does execute error-free after revision.
 *                15.MAR.2024 VV > Update Mule4 endpoints.
 */
@isTest(isParallel=true)
private class SMSServices_Test {
    
    @isTest
    static void testErrorFreeExecution() {
        
        List<contact> contacts = TestHelper.createOrphanContactRecords(1);
        insert contacts;
        
        Test.startTest();
                
        SingleRequestMock fakeResponse = new SingleRequestMock(200,
                                                               'Complete',
                                                               '{"_links":{"_self":{"href":"/la/student-services/v2/students/30075009/personNotes"}},"notes":[{"type":"personNote","admissionApplicationId":null,"noteType":"MI-APPL","typeDescription":"MONASH INTERNATIONAL APPLICATION DETAILS","updateBy":"MKARIM","updateOn":"2018-11-01T13:50:40","text":"Test Notes","portalApplicationID":null}]}',
                                                               null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        HttpResponse result = SMSServices.invokeMIXAPICallout(String.valueOf(contacts[0].Id));
        
        SMSServices.mockPersonNotesResponse();
        SMSServices.mockPersonCitizenshipResponse();
        SMSServices.mockEncumbranceResponse();
        SMSServices.mockStudentCourseAttemptsResponse();
        SMSServices.mockApplicantCourseResponse();
        
        Test.stopTest();
        
    }
}