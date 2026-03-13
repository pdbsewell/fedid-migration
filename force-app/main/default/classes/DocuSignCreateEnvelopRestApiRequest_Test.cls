/**
 * @description Test class for DocuSignCreateEnvelopRestApiRequest
 */
@isTest(isParallel=true)
public class DocuSignCreateEnvelopRestApiRequest_Test {

    private static final String SUCCESS_RESPONSE_ENVELOP_ID = 'b68d85fe-180b-4a5d-9480-da98030389d5';

    @isTest
    static void blankAcccountIdProvidedForCreateEnvelopTest() {
        try {
            DocuSignCreateEnvelopRestApiRequest request = new DocuSignCreateEnvelopRestApiRequest();
            request.createEnvelop('',  new DocuSignCreateEnvelopsReqBody());
            System.assert(false, 'Exception expected due to blank account id.');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'IllegalArgumentException expected due to blank account id.');
        } catch (Exception e) {
            System.assert(false, 'IllegalArgumentException expected instead of generic exception.');
        }
    }

    @isTest
    static void nullAcccountIdProvidedForCreateEnvelopTest() {
        try {
            DocuSignCreateEnvelopRestApiRequest request = new DocuSignCreateEnvelopRestApiRequest();
            request.createEnvelop(null,  new DocuSignCreateEnvelopsReqBody());
            System.assert(false, 'Exception expected due to account id = null.');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'IllegalArgumentException expected due to null account id.');
        } catch (Exception e) {
            System.assert(false, 'IllegalArgumentException expected instead of generic exception.');
        }
    }

    @isTest
    static void nullRequestBodyProvidedForCreateEnvelopTest() {
        try {
            DocuSignCreateEnvelopRestApiRequest request = new DocuSignCreateEnvelopRestApiRequest();
            request.createEnvelop('12345-284djdj',  null);
            System.assert(false, 'Exception expected due to null request body');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'IllegalArgumentException expected due to null request body.');
        } catch (Exception e) {
            System.assert(false, 'IllegalArgumentException expected instead of generic exception.');
        }
    }

    @isTest
    static void blankAccountIdAndnullRequestBodyProvidedForCreateEnvelopTest() {
        try {
            DocuSignCreateEnvelopRestApiRequest request = new DocuSignCreateEnvelopRestApiRequest();
            request.createEnvelop('',  null);
            System.assert(false, 'Exception expected due to null request body and blank account Id');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'IllegalArgumentException expected due to null request body and blank account Id.');
        } catch (Exception e) {
            System.assert(false, 'IllegalArgumentException expected instead of generic exception.');
        }
    }

    /**
     * @description This test method tests the response when the callout results in successful 201 response
     */
    @isTest 
    static void success201ResponseReturnedTest() {
        Test.setMock(HttpCalloutMock.class, new DocuSignCreateEnvelopRestApiRequest_Test.DocuSignCreateEnvSuccessResMock());
        DocuSignCreateEnvelopRestApiRequest request = new DocuSignCreateEnvelopRestApiRequest();
        request.createEnvelop('6a6b498e-b3d8-4d1b-ade2-68ca24f09b10', new DocuSignCreateEnvelopsReqBody());
        System.assert(true, 'Expected a success response with a success response mock');
    }

    /**
     * @description This test method tests the response when the callout results in an error
     */
    @isTest 
    static void invalidRequestReturnedTest() {
        Test.setMock(HttpCalloutMock.class, new DocuSignCreateEnvelopRestApiRequest_Test.DocuSignCreateEnvErrResMock());

        try {
            DocuSignCreateEnvelopRestApiRequest request = new DocuSignCreateEnvelopRestApiRequest();
            request.createEnvelop('6a6b498e-b3d8-4d1b-ade2-68ca24f09b10', new DocuSignCreateEnvelopsReqBody());
            System.assert(false, 'Exception expected due an mock error response.'); 
        } catch (DocuSignCreateEnvelopsReqException e) {
            System.assert(true, 'DocuSignCreateEnvelopRestApiRequestException expected due to an mock error response.');
        } catch (Exception e) {
            System.assert(false, 'DocuSignCreateEnvelopRestApiRequestException was expected instead of generic exception.');
        }
    }

    /**
     * @description This test method tests the response when the callout results in an error
     */
    @isTest 
    static void unauthRequestReturnedTest() {
        Test.setMock(HttpCalloutMock.class, new DocuSignCreateEnvelopRestApiRequest_Test.DocuSignCreateEnvelopUnauthorizedResMock());

        try {
            DocuSignCreateEnvelopRestApiRequest request = new DocuSignCreateEnvelopRestApiRequest();
            request.createEnvelop('6a6b498e-b3d8-4d1b-ade2-68ca24f09b10', new DocuSignCreateEnvelopsReqBody());
            System.assert(false, 'Exception expected due an mock 401 error response.'); 
        } catch (DocuSignUnauthorizedAccessException e) {
            System.assert(true, 'DocuSignUnauthorizedAccessException expected due to an mock 401 error response.');
        } catch (Exception e) {
            System.assert(false, 'DocuSignUnauthorizedAccessException was expected instead of generic exception.');
        }
    }

    @isTest
    static void shouldReturnEnvelopIdAfterCreateEnvelopSuccessResponse () {
        Test.setMock(HttpCalloutMock.class, 
            new DocuSignCreateEnvelopRestApiRequest_Test.DocuSignCreateEnvSuccessResMock());

        DocuSignCreateEnvelopRestApiRequest request = new DocuSignCreateEnvelopRestApiRequest();
        request.createEnvelop('6a6b498e-b3d8-4d1b-ade2-68ca24f09b10', 
            new DocuSignCreateEnvelopsReqBody());
        System.assertEquals(SUCCESS_RESPONSE_ENVELOP_ID, 
            request.getEnvelopId(), 
            'Expected envelopId from getEnvelopId to match envelop Id in mock success response');
    }

    /** 
     * @description Mock success response based on 
     * https://developers.docusign.com/esign-rest-api/reference/Envelopes/Envelopes/create#responses
     */
    private class DocuSignCreateEnvSuccessResMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse successResponse = new HttpResponse();
            successResponse.setHeader('Content-Type', 'application/json');
            successResponse.setBody('{"envelopeId":"' + SUCCESS_RESPONSE_ENVELOP_ID + '","uri":"/envelopes/b68d85fe-180b-4a5d-9480-da98030389d5","statusDateTime":"2019-12-12T00:14:44.0500000Z","status":"sent"}');
            successResponse.setStatusCode(201);
            return successResponse;
        }

    }


    /** 
     * @description Mock error response based on 
     * https://developers.docusign.com/esign-rest-api/reference/Envelopes/Envelopes/create#responses
     */
    private class DocuSignCreateEnvErrResMock implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse successResponse = new HttpResponse();
            successResponse.setHeader('Content-Type', 'application/json');
            successResponse.setBody('{"errorCode":"INVALID_REQUEST_PARAMETER","message":"The request contained at least one invalid parameter. Invalid value for \'status\' in envelope definition.  Only \'sent\' or \'created\' (default) are allowed."}');
            successResponse.setStatusCode(400);
            return successResponse;
        }
    }


    /** 
     * @description Mock error response for 401 unauthorized
     */
    private class DocuSignCreateEnvelopUnauthorizedResMock implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse successResponse = new HttpResponse();
            successResponse.setHeader('Content-Type', 'application/json');
            successResponse.setBody('{"errorCode": "AUTHORIZATION_INVALID_TOKEN","message": "The access token provided is expired, revoked or malformed."}');
            successResponse.setStatusCode(401);
            return successResponse;
        }
    }
}