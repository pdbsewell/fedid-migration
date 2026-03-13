/*******************************************************************************
 * @author       Shalini mendu
 * @date         21 June 2019
 * @description  Test class to cover CRMDocumentSubmitWS
 * @revision  23 Oct 2019 - SFTN-384-Documents are not getting sent from AP to CRM and not to Callista(Changing the request parameters
 * from record ID's to auto numbers for security reasons.)
 *******************************************************************************/
@isTest(isParallel=false)//APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object: ContentWorkspace
public class CRMDocumentSubmitWS_Test {

    @isTest
    static void testPositiveCRMDocumentSubmit() {

        //Create a new Contact for testing
        Contact c = StudFirst_TestHelper.createApplicant();
        c.Citizenship__c = MyApplicationUtilities.DOMESTIC;
        Date dtToday = Date.today();
        c.Birthdate = dtToday.addYears(-20);
        insert c;

        // create application for contact
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        app.Fee_Payment__c = true;
        insert app;
		
        app = [SELECT id, Name FROM application__c WHERE id = :app.id LIMIT 1];
        	
        CONTACT retCon = [SELECT CRM_Id__c FROM CONTACT WHERE ID=:c.id ];
        application__c retApp = [SELECT name FROM application__c WHERE ID=:app.id ];

        ObdDocumentPayload.ObdDocumentPayloadRequest req = new ObdDocumentPayload.ObdDocumentPayloadRequest();
        req.agentPersonId = 'agent001';
        req.externalApplicantId = retCon.CRM_Id__c;
        req.applicationId = retApp.Name;
        req.contentType = 'image/jpg';
        req.fileName = 'testfile.jpg';
        req.binaryString = 'y4flddddld';
        req.comments = 'Test comments';

        RestRequest rReq = new RestRequest();
        rReq.httpMethod = 'POST';
        rReq.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.request = rReq;
        ObdDocumentPayload.ObdDocumentPayloadResponse resp = new ObdDocumentPayload.ObdDocumentPayloadResponse();

        Test.startTest();
            resp = CRMDocumentSubmitWS.postMessage();
        Test.stopTest();
        System.assertEquals( 'Success', resp.status, 'Document upload failed');
        System.assertEquals( retApp.Id , [select Application__c from Contact_Document__c].Application__c, 'Application reference not attached to the Contact Document created');
    }

    @isTest
    static void testNegativeCRMDocumentSubmit() {
        ObdDocumentPayload.ObdDocumentPayloadRequest req = new ObdDocumentPayload.ObdDocumentPayloadRequest();
        req.agentPersonId = 'agent001';
        req.externalApplicantId = '123333'; //Random non existing number
        req.applicationId = 'AAAAAAAA'; //Random non existing number
        req.contentType = 'image/jpg';
        req.fileName = 'testfile.jpg';
        req.binaryString = 'y4flddddld';
        req.comments = 'Test comments';

        RestRequest rReq = new RestRequest();
        rReq.httpMethod = 'POST';
        rReq.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.request = rReq;
        ObdDocumentPayload.ObdDocumentPayloadResponse resp = new ObdDocumentPayload.ObdDocumentPayloadResponse();

        Test.startTest();
        	resp = CRMDocumentSubmitWS.postMessage();
        Test.stopTest();
        System.assertEquals(resp.status, 'Error');
    }

}