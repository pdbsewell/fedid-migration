/**
 * @author Trent De Laney
 * @date 19 Dec 2019 at 10:44:12 am
 * @group Test Class
 * @description Covers the response message for the Document submission to Callista. Needs to be covered line by line for Salesforce to pick up the coverage
 */
@IsTest
public with sharing class ObdSendDocumentsServiceRequest_Test {
    @IsTest
    public static void test_AssignPropertyValues(){
        ObdSendDocumentsServiceRequest req = new ObdSendDocumentsServiceRequest();
        System.assertNotEquals(null, req, 'Unable to create the Documents Service Request');
        req.source = 'Test';
        req.sourceTime = '1000';
        req.type = 'Test';
        req.events = new List<ObdSendDocumentsServiceRequest.AppDocument>();

        ObdSendDocumentsServiceRequest.AppDocument appDoc = new ObdSendDocumentsServiceRequest.AppDocument();
        appDoc.agentPersonId = '111';
        appDoc.applicantId = '111';
        appDoc.externalApplicantId = '111';
        appDoc.contentType = 'mime';
        appDoc.filename = 'Test.jpg';
        appDoc.id = 'test';
        appDoc.applicationDocumentId = '123456789';
        appDoc.contactDocumentId = '123456789';
        appDoc.documentType = 'pdf';
        appDoc.comments = 'Test Comment';
    }
}