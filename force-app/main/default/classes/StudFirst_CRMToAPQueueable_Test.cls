/*******************************************************************************
* @author       Suman Gunaganti
* @date        	19/12/2019         
* @description  test class for StudFirst_CRMToAPQueueable
* @group        Test class
* @revision
*******************************************************************************/
@isTest(isParallel=true)
private class StudFirst_CRMToAPQueueable_Test {
    static testMethod void Test_StudFirst_CRMToAPQueueable() {
        string requestJson = '{"enquiryRecordId":"00533535353535",'+
							 '"agentOrgUnitId":"AGENT-X",'+
							 '"applicantId": "43343",'+
							 '"personId":"937535612954",'+
							 '"subject":"Test",'+
							 '"messageBody":"test email body",'+
							 '"attachmentLinks":"links"}';
        SingleRequestMock fakeResponse = new SingleRequestMock(200,
                                                     'Complete',
                                                     '{"success":true,"message":"Message has been successfully submitted"}',
                                                     null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        IntegrationSettings_CRMToAP__c is = new IntegrationSettings_CRMToAP__c();
        is.Enable_Mock__c = False;
        is.Timeout__c = '12000';
        is.Base_Url__c = 'https://agent.apps.monash.edu/api';
        is.Path__c = '/v1/message';
        is.Method__c = 'POST';
        is.Header_ContentType__c = 'application/json';
        is.Header_ClientId__c = 'jdgeN2gHXYj8oN1zOd8LwdbyDc1rA6dH';
        is.Header_ClientSecret__c = '7HWi14w47ucFzxgC4Yg7ybTWHhtYSRPk';
        Insert Is;
        Test.startTest();
        StudFirst_CRMToAPQueueable queueJob = new StudFirst_CRMToAPQueueable(JSON.serialize(requestJson));
        Id jobID = System.enqueueJob(queueJob);
        System.assert(jobID != Null, 'ERROR# Job not enqueued');
        Test.stopTest();
    }

    static testMethod void Test_StudFirst_CRMToAPQueueable_Error() {
        string requestJson = '{"enquiryRecordId":"00533535353535",'+
							 '"agentOrgUnitId":"AGENT-X",'+
							 '"applicantId": "43343",'+
							 '"personId":"937535612954",'+
							 '"subject":"Test",'+
							 '"messageBody":"test email body",'+
							 '"attachmentLinks":"links"}';
        SingleRequestMock fakeResponse = new SingleRequestMock(220,
                                                     'Error',
                                                     '{"success":false,"message":"Message Error"}',
                                                     null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        IntegrationSettings_CRMToAP__c is = new IntegrationSettings_CRMToAP__c();
        is.Enable_Mock__c = False;
        is.Timeout__c = '12000';
        is.Base_Url__c = 'https://agent.apps.monash.edu/api';
        is.Path__c = '/v1/message';
        is.Method__c = 'POST';
        is.Header_ContentType__c = 'application/json';
        is.Header_ClientId__c = 'jdgeN2gHXYj8oN1zOd8LwdbyDc1rA6dH';
        is.Header_ClientSecret__c = '7HWi14w47ucFzxgC4Yg7ybTWHhtYSRPk';
        Insert Is;
        Test.startTest();
        StudFirst_CRMToAPQueueable queueJob = new StudFirst_CRMToAPQueueable(JSON.serialize(requestJson));
        Id jobID = System.enqueueJob(queueJob);
        System.assert(jobID != Null, 'ERROR# Job not enqueued');
        Test.stopTest();
        List<Exception_Log__c> exlogs = [SELECT Id FROM Exception_Log__c];
        System.assert(!exlogs.isEmpty(), 'ERROR# exception log should be created');
    }
}