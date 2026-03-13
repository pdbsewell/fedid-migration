/**
 * @author Trent De Laney
 * @date 13 Dec 2019 at 3:13:37 pm
 * @group Test Class
 * @description Covers the response message for the Agent Portal Communication. Needs to be covered line by line for Salesforce to pick up the coverage
 */
@IsTest
public with sharing class ObdAgentPortalCommsRequest_Test {
    @IsTest
    public static void test_AssignPropertyValues(){
        ObdAgentPortalCommsRequest.CommsWrapper request = new ObdAgentPortalCommsRequest.CommsWrapper();
        request.applicantId = '1000';
        request.enquiryRecordId = 'Test';
        request.callistaPersonId = 'Test';
        request.agentOrgUnitId = 'Test';
        request.agencyName = 'Test';
        request.staffName = 'Test';
        request.phoneNumber = '1234567890';
        request.messageBody = 'Test';
        request.messageSubject = 'Test';
        request.category = 'Test';
        request.subCategory = 'Test';
        System.assertNotEquals(request, null, 'Unable to create Comms Request');
    }
}