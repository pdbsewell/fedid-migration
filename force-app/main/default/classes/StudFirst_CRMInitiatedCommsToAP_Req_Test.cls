/*******************************************************************************
* @author       Suman Gunaganti
* @date         17.Dec.2019
* @description  test class for StudFirst_CRMInitiatedCommsToAP_Req
* @revision		
*******************************************************************************/
@isTest(isParallel=true)
private class StudFirst_CRMInitiatedCommsToAP_Req_Test {
    @IsTest
    static void testBehavior() {
		string requestJson = '{"enquiryRecordId":"00533535353535",'+
							 '"agentOrgUnitId":"AGENT-X",'+
							 '"applicantId": "43343",'+
							 '"personId":"937535612954",'+
							 '"subject":"Test",'+
							 '"messageBody":"test email body",'+
							 '"attachmentLinks":"links"}';
        StudFirst_CRMInitiatedCommsToAP_Req request = (StudFirst_CRMInitiatedCommsToAP_Req)JSON.deserialize(requestJson, StudFirst_CRMInitiatedCommsToAP_Req.class);
        System.assert(request.enquiryRecordId == '00533535353535');
		System.assert(request.agentOrgUnitId == 'AGENT-X');
		System.assert(request.applicantId == '43343');
		System.assert(request.personId == '937535612954');
		System.assert(request.subject == 'Test');
		System.assert(request.messageBody == 'test email body');
		System.assert(request.attachmentLinks == 'links');
    }
}