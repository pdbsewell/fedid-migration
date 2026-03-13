/**
 * @description Covers the ApplicationDocumentContentWS class
 * @author Kai-Fan Hsieh
 * @since 08/08/2024
 */
@isTest(isParallel=true)
private class ApplicationDocumentContentWS_Test {
    /**
     * @description Tests the getClientImplFactory method to verify the correct client implementation factory is returned.
     */
    @IsTest
    private static void testGetClientImplFactory() {
        // Given : init ApplicationDocumentWS
        RESTlib_ClientImplFactory clientImplFactory;
        ApplicationDocumentContentWS applicationDocumentContentWS = new ApplicationDocumentContentWS();
        // When : get client implementation factory
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            Test.startTest();
            clientImplFactory = applicationDocumentContentWS.getClientImplFactory();
            Test.stopTest();
        }
        // Then : instance of ApplicationDocumentImplFactory should be returned
        Assert.isTrue(clientImplFactory instanceof ApplicationDocumentContentImplFactory, 'Expected ApplicationDocumentContentImplFactory instance');
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

        // When : calling post method for ApplicationDocumentContentWS as digitary API user
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            Test.startTest();
            ApplicationDocumentContentWS.handlePost();
            Test.stopTest();
        }
        // Then : success status should be false as delivery Id is missing
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        DigitaryApplicationDocumentPayload.PostResponse customResponse =
            (DigitaryApplicationDocumentPayload.PostResponse) JSON.deserialize(responseBodyString, DigitaryApplicationDocumentPayload.PostResponse.class);
        Assert.isFalse(customResponse.success, 'Expected success status to be false');
    }
}