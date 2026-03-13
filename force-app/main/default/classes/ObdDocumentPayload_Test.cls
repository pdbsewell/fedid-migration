/**
 * @author Trent De Laney
 * @date 19 Dec 2019 at 10:20:12 am
 * @group Test Class
 * @description Covers the response message for the Document submission to Callista. Needs to be covered line by line for Salesforce to pick up the coverage
 */
@IsTest
public with sharing class ObdDocumentPayload_Test {
    @IsTest
    public static void test_AssignPropertyValuesReq(){
        ObdDocumentPayload.ObdDocumentPayloadRequest req = new ObdDocumentPayload.ObdDocumentPayloadRequest();
        System.assertNotEquals(null, req, 'Unable to create Document Request Payload');
        req.agentPersonId = '111';
        req.externalApplicantId = '111';
        req.applicationId = '111';
        req.contentType = 'mime';
        req.fileName = 'test.jpg';
        req.binaryString = '1234567890';
        req.comments = 'Test Comment';
        req.documentChecklistId = '888';
        req.documentType = 'Proof';
    }
    @IsTest
    public static void test_AssignPropertyValuesRes(){
        ObdDocumentPayload.ObdDocumentPayloadResponse res = new ObdDocumentPayload.ObdDocumentPayloadResponse();
        System.assertNotEquals(null, res, 'Unable to create Document Response Payload');
        res.status = 'Test';
        res.error = 'Test';
    }
}