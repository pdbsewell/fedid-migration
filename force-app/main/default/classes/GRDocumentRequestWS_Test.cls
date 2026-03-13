/**
 * @description Covers the GRDocumentRequestWS class
 * @author Vishal Gupta
 * @since 29/10/2024
 */
@isTest(isParallel=true)
private class GRDocumentRequestWS_Test {
    /**
     * @description Tests the getClientImplFactory method to verify the correct client implementation factory is returned.
     */
    @IsTest
    private static void testGetClientImplFactory() {
        // Given : init GRDocumentRequestWS
        RESTlib_ClientImplFactory clientImplFactory;
        GRDocumentRequestWS grDocumentRequestWS = new GRDocumentRequestWS();
        // When : get client implementation factory
        Test.startTest();
        clientImplFactory = grDocumentRequestWS.getClientImplFactory();
        Test.stopTest();
        // Then : instance of ApplicationDocumentImplFactory should be returned
        Assert.isTrue(clientImplFactory instanceof GRDocumentRequestImplFactory, 'Expected GRDocumentRequestImplFactory instance');
    }

    /**
     * @description Tests the handlePost method to verify it handles a POST request correctly.
     */
    @isTest
    private static void testHandlePost() {
        // Given : init post request
        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;

        // When : calling post method for GRDocumentRequestWS as digitary API user
        Test.startTest();
        GRDocumentRequestWS.handlePost();
        Test.stopTest();
        // Then : success status should be false as delivery Id is missing
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        GRDocumentRequestPayload.PostResponse customResponse =
            (GRDocumentRequestPayload.PostResponse) JSON.deserialize(responseBodyString, GRDocumentRequestPayload.PostResponse.class);
        Assert.isFalse(customResponse.success, 'Expected success status to be false');
    }
}