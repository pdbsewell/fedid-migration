/**
 * @description Test class for DocuSignGetSigningUrlRestApiRequest
 */
@isTest(isParallel=true)
public class DocuSignGetSigningUrlRestApiRequest_Test {

    @isTest
    static void shouldThrowIllegalArgumentExceptionWhenAccountIdIsBlank() {
        try {
            DocuSignGetSigningUrlRestApiRequest req = new DocuSignGetSigningUrlRestApiRequest();
            req.getSigningUrl('', 'a4a0efdd-c2a4-4218-b89a-e8336102f2e7', new DocuSignGetSigningUrlRequestBody());
            System.assert(false, 'Expected an illegal argument exception due to blank DocuSign account Id value');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected an IllegalArgumentException');
        } catch (Exception e) {
            System.assert(false, 'Expected an IllegalArgumentException instead of Exception due to blank account id value');
        }
    }

    @isTest
    static void shouldThrowIllegalArgumentExceptionWhenAccountIdIsNull() {
        try {
            DocuSignGetSigningUrlRestApiRequest req = new DocuSignGetSigningUrlRestApiRequest();
            req.getSigningUrl(null, 'a4a0efdd-c2a4-4218-b89a-e8336102f2e7', new DocuSignGetSigningUrlRequestBody());
            System.assert(false, 'Expected an illegal argument exception due to null DocuSign account Id value');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected an IllegalArgumentException');
        } catch (Exception e) {
            System.assert(false, 'Expected an IllegalArgumentException instead of Exception due to null account id value');
        }
    }

    @isTest
    static void shouldThrowIllegalArgumentExceptionWhenEnvelopIdIsBlank() {
        try {
            DocuSignGetSigningUrlRestApiRequest req = new DocuSignGetSigningUrlRestApiRequest();
            req.getSigningUrl('6a6b498e-b3d8-4d1b-ade2-68ca24f09b10', '', new DocuSignGetSigningUrlRequestBody());
            System.assert(false, 'Expected an illegal argument exception due to blank DocuSign envelop Id value');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected an IllegalArgumentException');
        } catch (Exception e) {
            System.assert(false, 'Expected an IllegalArgumentException instead of Exception due to blank envelop id value');
        }
    }

    @isTest
    static void shouldThrowIllegalArgumentExceptionWhenEnvelopIdIsNull() {
        try {
            DocuSignGetSigningUrlRestApiRequest req = new DocuSignGetSigningUrlRestApiRequest();
            req.getSigningUrl('6a6b498e-b3d8-4d1b-ade2-68ca24f09b10', null, new DocuSignGetSigningUrlRequestBody());
            System.assert(false, 'Expected an illegal argument exception due to null DocuSign envelop Id value');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected an IllegalArgumentException');
        } catch (Exception e) {
            System.assert(false, 'Expected an IllegalArgumentException instead of Exception due to null envelop id value');
        }
    }

    @isTest
    static void shouldThrowIllegalArgumentExceptionWhenAccountIdAndEnvelopIdIsBlank() {
        try {
            DocuSignGetSigningUrlRestApiRequest req = new DocuSignGetSigningUrlRestApiRequest();
            req.getSigningUrl('', '', new DocuSignGetSigningUrlRequestBody());
            System.assert(false, 'Expected an illegal argument exception due to blank DocuSign account Id and envelop Id values');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected an IllegalArgumentException');
        } catch (Exception e) {
            System.assert(false, 'Expected an IllegalArgumentException instead of Exception due to blank account id and envelop id values');
        }
    }

    @isTest
    static void shouldThrowIllegalArgumentExceptionWhenAccountIdAndEnvelopIdIsNull() {
        try {
            DocuSignGetSigningUrlRestApiRequest req = new DocuSignGetSigningUrlRestApiRequest();
            req.getSigningUrl(null, null, new DocuSignGetSigningUrlRequestBody());
            System.assert(false, 'Expected an illegal argument exception due to null DocuSign account Id and envelop Id values');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected an IllegalArgumentException');
        } catch (Exception e) {
            System.assert(false, 'Expected an IllegalArgumentException instead of Exception due to null account id and envelop id values');
        }
    }

    @isTest
    static void shouldReturnSigningUrlOnSuccessResponse() {
        Test.setMock(HttpCalloutMock.class, new DocuSignGetSigningUrlRestApiRequest_Test.DocuSignGetSigningUrlSuccessResMock());
        DocuSignGetSigningUrlRestApiRequest req = new DocuSignGetSigningUrlRestApiRequest();
        String signingUrl = req.getSigningUrl('6a6b498e-b3d8-4d1b-ade2-68ca24f09b10', 'f674275e-c929-4447-92cf-a920750abed8', new DocuSignGetSigningUrlRequestBody());
        System.assertNotEquals(null, signingUrl, 'Expected a signing URL to be returned as the request is successful');
    }

    @isTest
    static void shouldThrowDocuSignGetSignUrlReqFailExceptionOnUnknownResponse() {
        Test.setMock(HttpCalloutMock.class, new DocuSignGetSigningUrlRestApiRequest_Test.DocuSignGetSigningUrlUnknownEnvelopResMock());
        try {
            DocuSignGetSigningUrlRestApiRequest req = new DocuSignGetSigningUrlRestApiRequest();
            String signingUrl = req.getSigningUrl('6a6b498e-b3d8-4d1b-ade2-68ca24f09b10', 'f674275e-c929-4447-92cf-a920750abed8', new DocuSignGetSigningUrlRequestBody());
            System.assert(false, 'Expected a DocuSignGetSignUrlReqFailException because the mock response from DocuSign is an error');
        } catch (DocuSignGetSignUrlReqFailException e) {
            System.assert(true, 'Expected DocuSignGetSignUrlReqFailException exception');
        } catch (Exception e) {
            System.assert(false, 'Expected DocuSignGetSignUrlReqFailException exception instead of Exception');
        }
    }

    @isTest
    static void shouldThrowDocuSignGetSignUrlReqFailExceptionOnInvalidResponse() {
        Test.setMock(HttpCalloutMock.class, new DocuSignGetSigningUrlRestApiRequest_Test.DocuSignGetSigningUrlDoesNotExistOrInvalidEnvelopResMock());
        try {
            DocuSignGetSigningUrlRestApiRequest req = new DocuSignGetSigningUrlRestApiRequest();
            String signingUrl = req.getSigningUrl('6a6b498e-b3d8-4d1b-ade2-68ca24f09b10', 'f674275e-c929-4447-92cf-a920750abed8', new DocuSignGetSigningUrlRequestBody());
            System.assert(false, 'Expected a DocuSignGetSignUrlReqFailException because the mock response from DocuSign is an error');
        } catch (DocuSignGetSignUrlReqFailException e) {
            System.assert(true, 'Expected DocuSignGetSignUrlReqFailException exception');
        } catch (Exception e) {
            System.assert(false, 'Expected DocuSignGetSignUrlReqFailException exception instead of Exception');
        }
    }

    @isTest
    static void shouldThrowDocuSignUnauthorizedAccessExceptionOnAccessError() {
        Test.setMock(HttpCalloutMock.class, new DocuSignGetSigningUrlRestApiRequest_Test.DocuSignGetSigningUrlUnauthorizedResMock());
        try {
            DocuSignGetSigningUrlRestApiRequest req = new DocuSignGetSigningUrlRestApiRequest();
            String signingUrl = req.getSigningUrl('6a6b498e-b3d8-4d1b-ade2-68ca24f09b10', 'f674275e-c929-4447-92cf-a920750abed8', new DocuSignGetSigningUrlRequestBody());
            System.assert(false, 'Expected a DocuSignUnauthorizedAccessException because the mock response from DocuSign is 401 Unauthorized');
        } catch (DocuSignUnauthorizedAccessException e) {
            System.assert(true, 'Expected DocuSignUnauthorizedAccessException exception');
        } catch (Exception e) {
            System.assert(false, 'Expected DocuSignUnauthorizedAccessException exception instead of Exception');
        }
    }

    /** 
     * @description Mock error response based on 
     * https://developers.docusign.com/esign-rest-api/reference/Envelopes/EnvelopeViews/createRecipient
     */
    private class DocuSignGetSigningUrlSuccessResMock implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {

            String docuSignGeneratedUrl = 'https://demo.docusign.net/Signing/MTRedeem/v1/12ef24bb-42dd-4810-9077-c5f2eb90befd?slt=eyJ0eXAiOiJNVCIsImFsZyI6IlJTMjU2Iiwia2lkIjoiNjgxODVmZjEtNGU1MS00Y2U5LWFmMWMtNjg5ODEyMjAzMzE3In0.AQUAAAABAAMABwAA0EaFx5PXSAgAgJd-N8iT10gYAAEAAAAAAAAAIQB5AwAAeyJUb2tlbklkIjoiYzMyZjkwZDAtOGYyMy00MzZhLWFlNTctN2Q1MDgxZGRkZjAxIiwiU3ViamVjdCI6bnVsbCwiU3ViamVjdFR5cGUiOm51bGwsIkV4cGlyYXRpb24iOiIyMDIwLTAxLTA3VDIzOjIwOjQzKzAwOjAwIiwiSXNzdWVkQXQiOiIyMDIwLTAxLTA3VDIzOjE1OjQ0LjA0MzQwMTcrMDA6MDAiLCJSZXNvdXJjZUlkIjoiZjY3NDI3NWUtYzkyOS00NDQ3LTkyY2YtYTkyMDc1MGFiZWQ4IiwiTGFiZWwiOm51bGwsIlNpdGVJZCI6bnVsbCwiUmVzb3VyY2VzIjoie1wiRW52ZWxvcGVJZFwiOlwiZjY3NDI3NWUtYzkyOS00NDQ3LTkyY2YtYTkyMDc1MGFiZWQ4XCIsXCJBY3RvclVzZXJJZFwiOlwiMzk2OGQ2YTEtNjg4My00YzIxLWE3N2UtNTcwN2ZjYTE5Yzg3XCIsXCJSZWNpcGllbnRJZFwiOlwiMGMzODNlNmMtNGNhNC00NjdiLTg2YjQtM2I5MTM1YTEyMTE0XCIsXCJGYWtlUXVlcnlTdHJpbmdcIjpcInQ9OGJlNjU1ZWItZDJlYy00ODU3LTkyZDEtYWQ2MjA1NTVmYTgwXCJ9IiwiT0F1dGhTdGF0ZSI6bnVsbCwiVG9rZW5UeXBlIjoxLCJBbGxvd1JlY2lwaWVudFVzZXJzIjpmYWxzZSwiQXVkaWVuY2UiOiIyNWUwOTM5OC0wMzQ0LTQ5MGMtOGU1My0zYWIyY2E1NjI3YmYiLCJTY29wZXMiOm51bGwsIlJlZGlyZWN0VXJpIjoiaHR0cHM6Ly9kZW1vLmRvY3VzaWduLm5ldC9TaWduaW5nL1N0YXJ0SW5TZXNzaW9uLmFzcHgiLCJIYXNoQWxnb3JpdGhtIjowLCJIYXNoU2FsdCI6bnVsbCwiSGFzaFJvdW5kcyI6MCwiVG9rZW5TZWNyZXRIYXNoIjpudWxsLCJUb2tlblN0YXR1cyI6MCwiRXh0ZXJuYWxDbGFpbXNSZXF1ZXN0ZWQiOm51bGwsIlRyYW5zYWN0aW9uSWQiOm51bGwsIlRyYW5zYWN0aW9uRXZlbnRDYWxsYmFja1VybCI6bnVsbCwiSXNTaW5nbGVVc2UiOmZhbHNlfQ.gvOQTZI_98RemIsZukHWJC_6ZIGGsc3Jr6dB6GykLXoFwAkWm192dp7lBRhYgpG9K9wphy4fiNBYrT4S2nXcf-UfonaDPFH1j8AEejRzsg9eQj17n7L1uLZQsN4Y6xT23jmo4W24tfBzWhLnxqnV-s08gE7I543d2jdh_CKXuhOZbJ-V4osD0iAsP0j4RboRET2tPSCPkugoRe_VD6OINl3EdIM4g4vEaA85pnheNqhUxvy25tRRlbLZFWRrrD6LcOYGM2dTWu36kioede-EJsvw3Kb_r047L-aOISzWawh0paMEskfZ8khrG3bneuiLqcHLVu84tPHSGGsK0Ne7sQ';

            HttpResponse successResponse = new HttpResponse();
            successResponse.setHeader('Content-Type', 'application/json');
            successResponse.setBody('{"url": "' + docuSignGeneratedUrl + '"}');
            successResponse.setStatusCode(201);
            return successResponse;
        }
    }

    /** 
     * @description Mock error response when the recipient does not have a known envelop
     * This could be due to mismatches in the parameters provided and the data provided in 
     * the envelop generation
     */
    private class DocuSignGetSigningUrlUnknownEnvelopResMock implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse successResponse = new HttpResponse();
            successResponse.setHeader('Content-Type', 'application/json');
            successResponse.setBody('{"errorCode": "UNKNOWN_ENVELOPE_RECIPIENT","message": "The recipient you have identified is not a valid recipient of the specified envelope."');
            successResponse.setStatusCode(400);
            return successResponse;
        }
    }

    /** 
     * @description Mock error response when the envelop does not exist or there are rights issues
     * For example, if the envelop id is incorrect
     */
    private class DocuSignGetSigningUrlDoesNotExistOrInvalidEnvelopResMock implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse successResponse = new HttpResponse();
            successResponse.setHeader('Content-Type', 'application/json');
            successResponse.setBody('{"errorCode": "ENVELOPE_DOES_NOT_EXIST","message": "The envelope specified either does not exist or you have no rights to it."}');
            successResponse.setStatusCode(400);
            return successResponse;
        }
    }

    /** 
     * @description Mock error response based on 
     * https://developers.docusign.com/esign-rest-api/reference/Envelopes/EnvelopeViews/createRecipient
     */
    private class DocuSignGetSigningUrlUnauthorizedResMock implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse successResponse = new HttpResponse();
            successResponse.setHeader('Content-Type', 'application/json');
            successResponse.setBody('{"errorCode": "AUTHORIZATION_INVALID_TOKEN","message": "The access token provided is expired, revoked or malformed."}');
            successResponse.setStatusCode(401);
            return successResponse;
        }
    }


}