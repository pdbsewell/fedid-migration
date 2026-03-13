/**
 * @description Test class for DocuSignUpdateEnvelopRestApiRequest
 */
@isTest(isParallel=true)
public class DocuSignUpdateEnvelopRestApiRequest_Test {

    private static final String ACCOUNT_ID = 'f2c59a64-adb8-4845-808f-2a3f369f1f3b';
    private static final String ENVELOP_ID = '70846aae-e5ce-40e7-b960-d2c24d1f5013';

    @isTest
    static void shouldThrowIllegalArgumentExceptionIfAccountIdIsMissing() {

        DocuSignUpdateEnvelopsReqBody reqBody = new DocuSignUpdateEnvelopsReqBody();
        reqBody.status = 'voided';

        try {
            DocuSignUpdateEnvelopRestApiRequest req = 
                new DocuSignUpdateEnvelopRestApiRequest();
            req.updateEnvelop('', ENVELOP_ID, reqBody);
            System.assert(false, 
                'Expected an IllegalArgumentException because account id is missing');
        } catch (IllegalArgumentException e) {
            System.assert(true, 
                'Expected an IllegalArgumentException because account id is missing');
        } catch (Exception e) {
            System.assert(false, 
                'Expected IllegalArgumentException instead of exception');
        }

    }

    @isTest
    static void shouldThrowIllegalArgumentExceptionIfEnvelopIdIsMissing() {

        DocuSignUpdateEnvelopsReqBody reqBody = new DocuSignUpdateEnvelopsReqBody();
        reqBody.status = 'voided';

        try {
            DocuSignUpdateEnvelopRestApiRequest req = 
                new DocuSignUpdateEnvelopRestApiRequest();
            req.updateEnvelop(ACCOUNT_ID, '', reqBody);
            System.assert(false, 
                'Expected an IllegalArgumentException because envelop id is missing');
        } catch (IllegalArgumentException e) {
            System.assert(true, 
                'Expected an IllegalArgumentException because envelop id is missing');
        } catch (Exception e) {
            System.assert(false, 
                'Expected IllegalArgumentException instead of exception');
        }

    }

    @isTest
    static void shouldThrowIllegalArgumentExceptionIfRequestBodyIsNull() {

        try {
            DocuSignUpdateEnvelopRestApiRequest req = 
                new DocuSignUpdateEnvelopRestApiRequest();
            req.updateEnvelop(ACCOUNT_ID, ENVELOP_ID, null);
            System.assert(false, 
                'Expected an IllegalArgumentException because request body is null');
        } catch (IllegalArgumentException e) {
            System.assert(true, 
                'Expected an IllegalArgumentException because request body is null');
        } catch (Exception e) {
            System.assert(false, 
                'Expected IllegalArgumentException instead of exception');
        }

    }

    @isTest
    static void shouldThrowAuthorizationExceptionWhen401ResponseIsReturned() {
        
        DocuSignUpdateEnvelopsReqBody reqBody = new DocuSignUpdateEnvelopsReqBody();
        reqBody.status = 'voided';

        Test.setMock(HttpCalloutMock.class, 
            new DocuSignUpdateEnvelopRestApiRequest_Test.DocuSignUpdateEnvelopUnauthorizedResMock());
        try {
            DocuSignUpdateEnvelopRestApiRequest req = 
                new DocuSignUpdateEnvelopRestApiRequest();
            req.updateEnvelop(ACCOUNT_ID, ENVELOP_ID, reqBody);
            System.assert(false, 
                'Expected an DocuSignUnauthorizedAccessException because of 401 response');
        } catch (DocuSignUnauthorizedAccessException e) {
            System.assert(true, 
                'Expected an DocuSignUnauthorizedAccessException because of 401 response');
        } catch (Exception e) {
            System.assert(false, 
                'Expected DocuSignUnauthorizedAccessException instead of exception');
        }

    }

    @isTest
    static void shouldThrowDocuSignUpdateEnvelopsReqExceptionWhen400ResponseIsReturned() {
        
        DocuSignUpdateEnvelopsReqBody reqBody = new DocuSignUpdateEnvelopsReqBody();
        reqBody.status = 'voided';

        Test.setMock(HttpCalloutMock.class, 
            new DocuSignUpdateEnvelopRestApiRequest_Test.DocuSignUpdateEnvelopErrorResMock());
        try {
            DocuSignUpdateEnvelopRestApiRequest req = 
                new DocuSignUpdateEnvelopRestApiRequest();
            req.updateEnvelop(ACCOUNT_ID, ENVELOP_ID, reqBody);
            System.assert(false, 
                'Expected an DocuSignUpdateEnvelopsReqException because of 400 response');
        } catch (DocuSignUpdateEnvelopsReqException e) {
            System.assert(true, 
                'Expected an DocuSignUpdateEnvelopsReqException because of 400 response');
        } catch (Exception e) {
            System.assert(false, 
                'Expected DocuSignUpdateEnvelopsReqException instead of exception');
        }

    }

    @isTest
    static void shouldSuccessWithUpdateWhenDataIsValid() {
        DocuSignUpdateEnvelopsReqBody reqBody = new DocuSignUpdateEnvelopsReqBody();
        reqBody.status = 'voided';

        Test.setMock(HttpCalloutMock.class, 
            new DocuSignUpdateEnvelopRestApiRequest_Test.DocuSignUpdateEnvelopSuccessResMock());
        try {
            DocuSignUpdateEnvelopRestApiRequest req = 
                new DocuSignUpdateEnvelopRestApiRequest();
            req.updateEnvelop(ACCOUNT_ID, ENVELOP_ID, reqBody);
            System.assert(true, 
                'Expecting no exceptions as data is provided and 200 response');
        } catch (Exception e) {
            System.assert(false, 
            'Expecting no exceptions as data is provided and 200 response');
        }
    }

    /** 
     * @description Mock success response
     */
    private class DocuSignUpdateEnvelopSuccessResMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse successResponse = new HttpResponse();
            successResponse.setHeader('Content-Type', 'application/json');
            successResponse.setBody('{"envelopeId": "70846aae-e5ce-40e7-b960-d2c24d1f5013"}');
            successResponse.setStatusCode(200);
            return successResponse;
        }

    }


    /** 
     * @description Mock error response, e.g. if envelop id was invalid
     */
    private class DocuSignUpdateEnvelopErrorResMock implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse successResponse = new HttpResponse();
            successResponse.setHeader('Content-Type', 'application/json');
            successResponse.setBody('{"errorCode": "INVALID_REQUEST_PARAMETER","message": "The request contained at least one invalid parameter. Invalid value specified for envelopeId."}');
            successResponse.setStatusCode(400);
            return successResponse;
        }
    }


    /** 
     * @description Mock error response for 401 unauthorized
     */
    private class DocuSignUpdateEnvelopUnauthorizedResMock implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse successResponse = new HttpResponse();
            successResponse.setHeader('Content-Type', 'application/json');
            successResponse.setBody('{"errorCode": "AUTHORIZATION_INVALID_TOKEN","message": "The access token provided is expired, revoked or malformed."}');
            successResponse.setStatusCode(401);
            return successResponse;
        }
    }


}