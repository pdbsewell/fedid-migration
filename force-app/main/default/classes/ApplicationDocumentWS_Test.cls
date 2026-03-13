/**
 * @description Covers the ApplicationDocumentWS class
 * @author Kai-Fan Hsieh
 * @since 26 June 2024
 */
@isTest(isParallel=true)
private class ApplicationDocumentWS_Test {
    /**
     * @description Tests the getClientImplFactory method to verify the correct client implementation factory is returned.
     */
    @IsTest
    private static void testGetClientImplFactory() {
        // Given : init ApplicationDocumentWS
        RESTlib_ClientImplFactory clientImplFactory;
        ApplicationDocumentWS applicationDocumentWS = new ApplicationDocumentWS();
        // When : get client implementation factory
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            Test.startTest();
            clientImplFactory = applicationDocumentWS.getClientImplFactory();
            Test.stopTest();
        }
        // Then : instance of ApplicationDocumentImplFactory should be returned
        Assert.isTrue(clientImplFactory instanceof ApplicationDocumentImplFactory, 'Expected ApplicationDocumentImplFactory instance');
    }

    /**
     * @description Tests the handlePost method to verify it handles a POST request correctly.
     */
    @isTest
    private static void testHandlePost() {
        // Given : init post request
        DigitaryApplicationDocumentPayload.PostRequest postRequestPayload = new DigitaryApplicationDocumentPayload.PostRequest();

        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));

        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;

        // When : calling post method for ApplicationDocumentWS as digitary API user
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            Test.startTest();
            ApplicationDocumentWS.handlePost();
            Test.stopTest();
        }
        // Then : success status should be false as reference number is missing
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        DigitaryApplicationDocumentPayload.PostResponse customResponse =
            (DigitaryApplicationDocumentPayload.PostResponse) JSON.deserialize(responseBodyString, DigitaryApplicationDocumentPayload.PostResponse.class);
        Assert.isFalse(customResponse.success, 'Expected success status to be false');
    }

    /**
     * @description Tests the handlePost method to verify it handles a POST request correctly.
     */
    @IsTest
    private static void testHandlePatch() {
        // Given : init patch request
        DigitaryApplicationDocumentPayload.PatchRequest patchRequestPayload = new DigitaryApplicationDocumentPayload.PatchRequest();

        RestRequest request = new RestRequest();
        request.httpMethod = 'PATCH';
        request.requestBody = Blob.valueOf(JSON.serialize(patchRequestPayload));

        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;

        // When : calling patch method for ApplicationDocumentWS as digitary API user
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            Test.startTest();
            ApplicationDocumentWS.handlePatch();
            Test.stopTest();
        }

        // Then : success status should be false as delivery Id is missing
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        DigitaryApplicationDocumentPayload.PatchResponse customResponse =
            (DigitaryApplicationDocumentPayload.PatchResponse) JSON.deserialize(responseBodyString, DigitaryApplicationDocumentPayload.PatchResponse.class);
        Assert.isFalse(customResponse.success, 'Expected success status to be false');
    }
}