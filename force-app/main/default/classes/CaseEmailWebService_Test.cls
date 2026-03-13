/**
 * @author Tom Gangemi
 * @date July.2023
 *
 * @revision
 *     2023-07-12  - Tom Gangemi - SA-2339 - Case Email Web Service Initial Version
 **/

@IsTest
private class CaseEmailWebService_Test {

    @IsTest
    static void testValidateRequest() {
        CaseEmailWebService.Request req = new CaseEmailWebService.Request();

        try {
            CaseEmailWebService.validateRequest(req, 'INVALID_ACTION');
            Assert.fail('Exception expected');
        } catch (CaseEmailWebService.RequestException e) {
            Assert.areEqual(CaseEmailWebService.ERROR_INVALID_ACTION, e.getMessage());
        }

        CaseEmailWebService.EmailMessageRequest emr = new CaseEmailWebService.EmailMessageRequest();
        req.emails = new CaseEmailWebService.EmailMessageRequest[]{emr};

        try {
            CaseEmailWebService.validateRequest(req, CaseEmailWebService.ACTION_SEND_EMAIL);
            Assert.fail('Exception expected');
        } catch (CaseEmailWebService.RequestException e) {
            Assert.areEqual(CaseEmailWebService.ERROR_MISSING_BODY, e.getMessage());
        }

        emr.htmlBody = 'Something';
        emr.subject = 'Hello';

        try {
            CaseEmailWebService.validateRequest(req, CaseEmailWebService.ACTION_SEND_EMAIL);
            Assert.fail('Exception expected');
        } catch (CaseEmailWebService.RequestException e) {
            Assert.areEqual(CaseEmailWebService.ERROR_MISSING_FROM_ADDRESS, e.getMessage());
        }

        emr.contentDocumentIds = new Id[]{UserInfo.getUserId()};
        emr.fromAddress = 'example@monash.edu';
        emr.toAddresses = new String[]{'test@example.com'};

        try {
            CaseEmailWebService.validateRequest(req, CaseEmailWebService.ACTION_SEND_EMAIL);
            Assert.fail('Exception expected');
        } catch (CaseEmailWebService.RequestException e) {
            Assert.isTrue(e.getMessage().startsWith(CaseEmailWebService.ERROR_INVALID_CONTENT_DOCUMENT_ID), e.getMessage());
        }
    }

    @IsTest
    static void testSendEmail() {
        // setup test data
        ContentVersion cv1 = new ContentVersion(
            Title          = 'Doc1',
            PathOnClient   = 'Doc1.txt',
            VersionData    = Blob.valueOf('Test Content 1')
        );
        ContentVersion cv2 = new ContentVersion(
            Title          = 'Doc2',
            PathOnClient   = 'Doc2.txt',
            VersionData    = Blob.valueOf('Test Content 2')
        );
        ContentVersion cv3 = new ContentVersion(
            Title          = 'Doc3',
            PathOnClient   = 'Doc3.txt',
            VersionData    = Blob.valueOf('Test Content 3')
        );
        insert new ContentVersion[]{cv1, cv2, cv3};
        ContentDocument[] contentDocs = [SELECT Id FROM ContentDocument ORDER BY Title ASC];

        Case case1 = new Case(Subject = 'Test Case 1');
        Case case2 = new Case(Subject = 'Test Case 2');
        Case case3 = new Case(Subject = 'Test Case 3');
        TriggerCommon.disableTrigger('Contact');
        insert new Case[]{case1, case2, case3};
        TriggerCommon.enableTrigger('Contact');

        // create request 1 - should result in 2 EmailMessages, each linked to a case (case1's email with thread id)
        CaseEmailWebService.EmailMessageRequest emailReq1 = new CaseEmailWebService.EmailMessageRequest();
        emailReq1.htmlBody = 'Email Body';
        emailReq1.subject = 'Hello Test 1';
        emailReq1.toAddresses = new String[]{'example@monash.edu'};
        emailReq1.fromAddress = [SELECT Address FROM OrgWideEmailAddress LIMIT 1].Address;
        emailReq1.replyToCaseId = case1.Id;
        emailReq1.caseIds = new Id[]{case1.Id, case2.Id};
        emailReq1.contentDocumentIds = new Id[]{contentDocs[0].Id, contentDocs[1].Id};

        // create request 2 - should result in 1 EmailMessages, linked to case
        CaseEmailWebService.EmailMessageRequest emailReq2 = emailReq1.clone();
        emailReq2.subject = 'Hello Test 2';
        emailReq2.replyToCaseId = null;
        emailReq2.caseIds = new Id[]{case3.Id};
        emailReq2.contentDocumentIds = new Id[]{contentDocs[2].Id};

        // create request 3 - should result in 1 EmailMessages, not linked to case
        CaseEmailWebService.EmailMessageRequest emailReq3 = emailReq1.clone();
        emailReq3.subject = 'Hello Test 3';
        emailReq3.replyToCaseId = null;
        emailReq3.caseIds = null;
        emailReq3.contentDocumentIds = null;

        CaseEmailWebService.Request req = new CaseEmailWebService.Request();
        req.emails = new CaseEmailWebService.EmailMessageRequest[]{emailReq1, emailReq2, emailReq3};

        // submit request
        RestContext.request = new RestRequest();
        RestContext.request.requestURI = '/services/apexrest/CaseEmailService/v1/SendEmail';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.response = new RestResponse();
        Test.startTest();
        CaseEmailWebService.handlePost();
        Test.stopTest();

        String respBody = RestContext.response.responseBody != null ? RestContext.response.responseBody.toString() : '';
        Assert.areEqual(200, RestContext.response.statusCode, respBody);
        Assert.areEqual('', respBody);

        EmailMessage[] emailResults = [
            SELECT ParentId, Subject, ToAddress, FromAddress, ThreadIdentifier,
                (SELECT Title FROM AttachedContentDocuments ORDER BY Title ASC)
            FROM EmailMessage
        ];

        Assert.areEqual(4, emailResults.size());
        Map<Id,EmailMessage> messagesByParentId = new Map<Id,EmailMessage>();
        for(EmailMessage em :emailResults) {
            if(em.Subject == emailReq3.subject) {
                Assert.isNull(em.ParentId);
            } else {
                Assert.isNotNull(em.ParentId);
                messagesByParentId.put(em.ParentId, em);
            }
        }
        // email 1 case 1
        Assert.areEqual(emailReq1.subject, messagesByParentId.get(case1.Id).Subject);
        Assert.isNotNull(messagesByParentId.get(case1.Id).ThreadIdentifier, 'Email 1 for case should have thread identifier');
        Assert.areEqual(emailReq1.toAddresses[0], messagesByParentId.get(case1.Id).ToAddress);
        Assert.areEqual(emailReq1.fromAddress, messagesByParentId.get(case1.Id).FromAddress);
        Assert.areEqual(2, messagesByParentId.get(case1.Id).AttachedContentDocuments.size());
        Assert.areEqual(cv1.Title, messagesByParentId.get(case1.Id).AttachedContentDocuments[0].Title);
        // email 1 case 2
        Assert.areEqual(emailReq1.subject, messagesByParentId.get(case2.Id).Subject);
        Assert.areEqual(2, messagesByParentId.get(case2.Id).AttachedContentDocuments.size());
        Assert.isNull(messagesByParentId.get(case2.Id).ThreadIdentifier, 'Email 1 for case 2 should not have thread identifier');
        // email 2 case 3
        Assert.areEqual(1, messagesByParentId.get(case3.Id).AttachedContentDocuments.size());
        Assert.areEqual(emailReq2.subject, messagesByParentId.get(case3.Id).Subject);
    }
}