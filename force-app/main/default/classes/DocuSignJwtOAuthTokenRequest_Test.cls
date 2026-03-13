/**
 * @dsecription Test class for DocuSignJwtOAuthTokenRequest
 */
@isTest(isParallel=true)
public class DocuSignJwtOAuthTokenRequest_Test {

    private static final string ACCESS_TOKEN = 'eyJ0eXAiOiJNVCIsImFsZyI6IlJTMjU2Iiwia2lkIjoiNjgxODVmZjEtNGU1MS00Y2U5LWFmMWMtNjg5ODEyMjAzMzE3In0.AQoAAAABAAUABwAA-UAagZXXSAgAAGEFfImV10gCAI-38Nr0jqtIiVLylJ0biEMVAAEAAAAYAAIAAAAFAAAAHQAAAA0AJAAAADQzMjBlNDJlLTI4OWEtNDc4NC04NzAwLTZiMjY4YTYxYzkzYyIAJAAAADQzMjBlNDJlLTI4OWEtNDc4NC04NzAwLTZiMjY4YTYxYzkzYxIAAQAAAAYAAABqd3RfYnIjACQAAAA0MzIwZTQyZS0yODlhLTQ3ODQtODcwMC02YjI2OGE2MWM5M2M.lJBwTThqWQaqwWqvCNX8Km0_loCsDY8pQikCrTGSHfwCmslCcvwRDC65vw_RD-xBAxbVntntbP3e0McDBbiK0kOOJnZz5TAk-4gEFOVQPg__t5rR5ooKcDjwOC2QasAd7IVDoX1Qj-yPCoK_FaGsBJy0tW7_FQgfspgXGmdzpxq6E7s-ifiTHhp-COmnw0MKau8YkF0gFU5IGJXpkk0FAsjtYN-Q_uteAXuiIFPwX4pWVNTR7eFDtFGvBpWoGR9ePrH5MzgNGtX60uvvbyRTJcjZfvzf6TkjiUywEUOVS37R3TgaIcGRcJnLFRXyeQ3wIIlrGK8Do9xVj7uMO4bZig';

    @isTest
    static void shouldReturnAccessTokenOnSuccess() {
        Test.setMock(HttpCalloutMock.class, new DocuSignJwtOAuthTokenRequest_Test.DocuSignJwtOAuthTokenRequestSuccessResponseMock());
        DocuSignJwtOAuthTokenRequest tokenRequest = new DocuSignJwtOAuthTokenRequest();
        System.assertNotEquals(null, tokenRequest.getAccessToken(), 'Expected an access token as the response from DocuSign was successful.');
    }

    private class DocuSignJwtOAuthTokenRequestSuccessResponseMock implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse successResponse = new HttpResponse();
            successResponse.setHeader('Content-Type', 'application/json');
            successResponse.setBody('{"access_token":"' + ACCESS_TOKEN + '","token_type":"Bearer","expires_in":3600}');
            successResponse.setStatusCode(200);
            return successResponse;
        }
    }

}