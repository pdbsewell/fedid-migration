/*
 * author       J.Mapanao
 * date         18.DEC.2019
 * description  Sibling test class for StudFirst_SubmitEnquirySummary.cls
 * revision     18.DEC.2019 - J.Mapanao - Initial Created
 * 15/03/2024 - Mac Domingo   - EPCP-3307 Change integration endpoint for Mule 4
 */
@isTest(isParallel=true)
private class StudFirst_SubmitEnquirySummary_Test {
    @IsTest
    static void test_SendRequest_EnableMockFalse() {
        Contact test_Contact = StudFirst_TestHelper.createApplicant();
        insert test_Contact;

        String admissionsRecType = CommonServices.recordTypeId('Case', 'Admissions');
        Case caseRec = new  Case(SuppliedName = 'testName',
                                 SuppliedPhone = '0400000000',
                                 SuppliedEmail = 'testformEmail@monash.edu',
                                 ContactId = test_Contact.Id,
                                 AccountId = null,
                                 RecordTypeId = admissionsRecType,
                                 Notify_Agent__c = true);
        insert caseRec;

        EmailMessage emlMsg = new EmailMessage( ParentId = caseRec.id,
                                                FromAddress = 'testfrom@testmonash.edu',
                                                FromName = 'testSender',
                                                Subject = 'testSubject',
                                                HtmlBody = '<b>test body</b>',
                                                ToAddress = 'testEndpoint@monash.edu',
                                                Incoming = true);
        insert emlMsg;

        EmailMessage emailMsg = [SELECT Id, Parent.CaseNumber, ToAddress, FromAddress, CcAddress, Subject, TextBody FROM EmailMessage WHERE Id =: emlMsg.Id];

        StudFirst_DocumentDTO doc = new StudFirst_DocumentDTO();
        // External Applicant Id
        doc.externalApplicantId = 'externalApplicantId';
        // Agent
        doc.Agent = new StudFirst_DocumentDTO.Agent();
        doc.Agent.agentPersonId = 'AGENT_PERSON_ID';
        // Document
        doc.document = new StudFirst_DocumentDTO.Document();
        doc.document.type = 'CRM_EMAIL';
        doc.document.filename = emailMsg.Parent.CaseNumber + '_Email_' + emailMsg.Id;
        doc.document.contentType = 'text/plain';
        doc.document.comments = 'Enquiry Source: ' + emailMsg.Parent.CaseNumber;
        

        String docBody = 'From: ' + emailMsg.FromAddress + '\n';
        docBody += 'Sent: ' + 'emlMsg.MessageDate.format()' + '\n';
        docBody += 'To: ' + emailMsg.ToAddress + '\n';
        if (emailMsg.CcAddress != null) {
            docBody += 'CC: ' + emailMsg.CcAddress + '\n';
        }
        if (emailMsg.Subject != null) {
            docBody += 'Subject: ' + emailMsg.Subject + '\n';
        }
        docBody += '\n' + emailMsg.TextBody;

        Blob documentBlob = Blob.valueOf(docBody);
        doc.document.binary = EncodingUtil.base64Encode(documentBlob);

        //set mock response
        //Test.setMock(HttpCalloutMock.class, new StudFirst_MockHttpResponseGenerator());
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('StudFirst_SubmitEnquirySummaryMockResp');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        //Submit Summary text file to Callista
        StudFirst_SubmitEnquirySummary.sendRequest(JSON.serialize(doc), doc.externalApplicantId);
        Test.stopTest();
        List<Exception_Log__c> exLog = [SELECT Id FROM Exception_Log__c WHERE Object_Name__c = 'sendRequest'];
        System.assertEquals(1,exLog.size(),'ERROR: Error on callout mock');
    }

    @IsTest
    static void test_SendRequest_EnableMockTrue() {
        IntegrationSettings_SubmitApplication__c is = IntegrationSettings_SubmitApplication__c.getInstance(UserInfo.getOrganizationId());
        is.Enable_Mock__c = true;
        update is;
        //System.assertEquals('erwqweqw',JSON.serialize(is),'ERROR: Not true');

        Contact test_Contact = StudFirst_TestHelper.createApplicant();
        insert test_Contact;

        String admissionsRecType = CommonServices.recordTypeId('Case', 'Admissions');
        Case caseRec = new  Case(SuppliedName = 'testName',
                                 SuppliedPhone = '0400000000',
                                 SuppliedEmail = 'testformEmail@monash.edu',
                                 ContactId = test_Contact.Id,
                                 AccountId = null,
                                 RecordTypeId = admissionsRecType,
                                 Notify_Agent__c = true);
        insert caseRec;

        EmailMessage emlMsg = new EmailMessage( ParentId = caseRec.id,
                                                FromAddress = 'testfrom@testmonash.edu',
                                                FromName = 'testSender',
                                                Subject = 'testSubject',
                                                HtmlBody = '<b>test body</b>',
                                                ToAddress = 'testEndpoint@monash.edu',
                                                Incoming = true);
        insert emlMsg;

        EmailMessage emailMsg = [SELECT Id, Parent.CaseNumber, ToAddress, FromAddress, CcAddress, Subject, TextBody FROM EmailMessage WHERE Id =: emlMsg.Id];

        StudFirst_DocumentDTO doc = new StudFirst_DocumentDTO();
        // External Applicant Id
        doc.externalApplicantId = 'externalApplicantId';
        // Agent
        doc.Agent = new StudFirst_DocumentDTO.Agent();
        doc.Agent.agentPersonId = 'AGENT_PERSON_ID';
        // Document
        doc.document = new StudFirst_DocumentDTO.Document();
        doc.document.type = 'CRM_EMAIL';
        doc.document.filename = emailMsg.Parent.CaseNumber + '_Email_' + emailMsg.Id;
        doc.document.contentType = 'text/plain';
        doc.document.comments = 'Enquiry Source: ' + emailMsg.Parent.CaseNumber;
        

        String docBody = 'From: ' + emailMsg.FromAddress + '\n';
        docBody += 'Sent: ' + 'emlMsg.MessageDate.format()' + '\n';
        docBody += 'To: ' + emailMsg.ToAddress + '\n';
        if (emailMsg.CcAddress != null) {
            docBody += 'CC: ' + emailMsg.CcAddress + '\n';
        }
        if (emailMsg.Subject != null) {
            docBody += 'Subject: ' + emailMsg.Subject + '\n';
        }
        docBody += '\n' + emailMsg.TextBody;

        Blob documentBlob = Blob.valueOf(docBody);
        doc.document.binary = EncodingUtil.base64Encode(documentBlob);

        //set mock response
        //Test.setMock(HttpCalloutMock.class, new StudFirst_MockHttpResponseGenerator());
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('StudFirst_SubmitEnquirySummaryMockResp');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        //Submit Summary text file to Callista
        StudFirst_SubmitEnquirySummary.sendRequest(JSON.serialize(doc), doc.externalApplicantId);
        Test.stopTest();
        List<Exception_Log__c> exLog = [SELECT Id FROM Exception_Log__c WHERE Object_Name__c = 'sendRequest'];
        System.assertEquals(1,exLog.size(),'ERROR: Error on callout mock');
    }

    @TestSetup
    static void makeData(){
        IntegrationSettings_SubmitApplication__c is = new IntegrationSettings_SubmitApplication__c();
        is.Base_Url__c = 'https://mix-dev.monash.edu';
        is.Path__c = '/la/v1/admissions/applications';
        is.Method__c = 'POST';
        is.Header_ClientId__c = 'c8411f0ca73a4ae6a0c7081a1336630f';
        is.Header_ClientSecret__c = 'cd2d5b9e26fa4999A33FF6A7F12D65AD';
        is.Header_ContentType__c = 'application/json';
        is.Mock_Endpoint_Applications__c = 'http://monash.getsandbox.com/la/v1/admissions/applications';
        is.Enable_Mock__c = false;
        is.Timeout__c = '12000';

        insert is;
    }
}