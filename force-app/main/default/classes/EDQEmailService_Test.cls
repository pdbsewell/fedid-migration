/**
 * @author      Sachin Shetty
 * @description Test Class for EDQEmailService
 * @group       Test Class
 * @revision    2022-08-26 - Sachin Shetty - Created
**/
@isTest(isParallel=true)
public class EDQEmailService_Test {

    /**
     * @author                      Sachin Shetty
     * @created                     2022-08-26
     * @description                 Test Mock for EDQEmailService search email
     */
    public class EDQEmailServiceValidationSuccessResMock implements HttpCalloutMock {
       
        /**
         * @author                      Sachin Shetty
         * @created                     2022-08-26
         * @description                 Test Response when EDQEmailService search email has been called
         */
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"result":{"email":"test@gmail.com","confidence":"verified","verbose_output":"verified"}, "metadata":{"domain_detail":{"type":"consumer"}}}');
            response.setStatusCode(200);
            return response; 
        }
    }

    /**
     * @author                      Sachin Shetty
     * @created                     2022-08-29
     * @description                 Test Mock for EDQEmailService search address invalid email and suggestion
     */
    public class EDQEmailServiceValidationSuccessResDidYouMeanMock implements HttpCalloutMock {
       
        /**
         * @author                      Sachin Shetty
         * @created                     2022-08-29
         * @description                 Test Response when EDQEmailService search email has been called
         */
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"result":{"email":"test@gmail.con","confidence":"unreachable","verbose_output":"unreachable", "did_you_mean":["test@gmail.com"]}}');
            response.setStatusCode(200);
            return response; 
        }
    }

    /**
     * @author                      Sachin Shetty
     * @created                     2022-08-26
     * @description                 Test Mock for unauthorized access
     */
    private class EDQEmailServiceUnauthorizedAccessMock implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"errorCode": "AUTHORIZATION_INVALID_TOKEN","message": "The access token provided is expired, revoked or malformed."}');
            response.setStatusCode(401);
            return response;
        }
    }

    /**
     * @author                      Sachin Shetty
     * @created                     2022-08-26
     * @description                 Test Mock for miscellaneous errors 
     */
    private class EDQEmailServiceMiscErrorMock implements HttpCalloutMock {
        
        /**
         * @author                      Sachin Shetty
         * @created                     2022-08-26
         * @description                 Test Response when EDQEmailService search returns other errors
         */
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"errorCode": "MISCELLANEOUS_ERROR","message": "Internal Server Error."}');
            response.setStatusCode(500);
            return response;
        }
    }

    /**
     * @author                      Sachin Shetty
     * @created                     2022-08-26
     * @description                 Test Mock for unavailable service
     */
    private class EDQEmailServiceUnavailableMock implements HttpCalloutMock {
        
        /**
         * @author                      Sachin Shetty
         * @created                     2022-08-26
         * @description                 Test Response when EDQEmailService validate is called but Experian service is unavailable
         */
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"result":{"confidence": "service unavailable"}}');
            response.setStatusCode(503);
            return response;
        }
    }

    /**
     * @author                      Sachin Shetty
     * @created                     2022-08-31
     * @description                 Test Mock for insufficient Experian credits
     */
    private class EDQEmailInsufficientExperianCreditsMock implements HttpCalloutMock {
        
        /**
         * @author                      Sachin Shetty
         * @created                     2022-08-31
         * @description                 Test Response when EDQEmailService validate is called but the Experian credits are insufficient 
         */
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"result":{"confidence": "forbidden"}}');
            response.setStatusCode(403);
            return response;
        }
    }

    /**
     * @author                      Sachin Shetty
     * @created                     2024-02-06
     * @description                 Test Mock for EDQEmailService search email with Timed Out error response
     */
    public class EDQEmailServiceUnknownStatus implements HttpCalloutMock {
       
        /**
         * @author                      Sachin Shetty
         * @created                     2024-02-06
         * @description                 Test Response when EDQEmailService with Timed Out error response
         */
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"result":{"email":"test@edmundrice.org","confidence":"unknown","verbose_output":"timeout"}}');
            response.setStatusCode(408);
            return response; 
        }
    }

    @isTest
    static void testValidateEmailSuccessResponse() {
        // Given
        Test.setMock(HttpCalloutMock.class, new EDQEmailService_Test.EDQEmailServiceValidationSuccessResMock());

        // When
        EDQEmailService req = new EDQEmailService();
        EDQEmailDAO.EmailResponse response = req.validateEmail('test@gmail.com');

        // Then
        System.assertNotEquals(null, response?.result, 'Response did not have a result');
        System.assertEquals('test@gmail.com', response?.result?.email, 'Validated email did not match');
        System.assertEquals('verified', response?.result?.confidence, 'Incorrect confidence value returned');
        System.assertEquals('verified', response?.result?.verbose_output, 'Incorrect verbose output returned');
        System.assertEquals('consumer', response?.metadata?.domain_detail?.type, 'Incorrect confidence value returned');
    }

    @isTest
    static void testValidateEmailSuccessSuggestionResponse() {
        // Given
        Test.setMock(HttpCalloutMock.class, new EDQEmailService_Test.EDQEmailServiceValidationSuccessResDidYouMeanMock());

        // When
        EDQEmailService req = new EDQEmailService();
        EDQEmailDAO.EmailResponse response = req.validateEmail('test@gmail.con');

        // Then
        System.assertNotEquals(null, response?.result, 'Response did not have a result');
        System.assertEquals('test@gmail.con', response?.result?.email, 'Email did not match');
        System.assertEquals('unreachable', response?.result?.confidence, 'Incorrect confidence value returned');
        System.assertEquals(1, response?.result?.did_you_mean.size(), 'Incorrect confidence value returned');
        System.assertEquals('test@gmail.com', response?.result?.did_you_mean.get(0), 'Incorrect suggestion returned');
    }

    @isTest
    static void testValidateEmailUnauthorizedAccessException() {
        Test.setMock(HttpCalloutMock.class, new EDQEmailService_Test.EDQEmailServiceUnauthorizedAccessMock());
        try {
            EDQEmailService req = new EDQEmailService();
            EDQEmailDAO.EmailResponse response = req.validateEmail('test@gmail.com');
        } 
        catch (Exception e) {
            System.assertNotEquals(null,
                                e,
                                'Expected UnauthorizedAccess Exception');
        }
    }

    @isTest
    static void testValidateEmailMiscErrorException() {
        // Given
        Test.setMock(HttpCalloutMock.class, new EDQEmailService_Test.EDQEmailServiceMiscErrorMock());
        
        // When
        try {
            EDQEmailService req = new EDQEmailService();
            EDQEmailDAO.EmailResponse response = req.validateEmail('test@gmail.com');
        } 
        catch (Exception e) {
            // Then
            System.assertNotEquals(null,
                                e,
                                'Expected Miscellaneous Error Exception');
        }
    }

    @isTest
    static void testValidateEmailUnavailableService() {
        // Given
        Test.setMock(HttpCalloutMock.class, new EDQEmailService_Test.EDQEmailServiceUnavailableMock());
        
        // When
        EDQEmailService req = new EDQEmailService();
        EDQEmailDAO.EmailResponse response = req.validateEmail('test@gmail.com');

        // Then
        System.assertNotEquals(null, response?.result, 'Response did not have a result');
        System.assertEquals('test@gmail.com', response?.result?.email, 'Validated email did not match');
        System.assertEquals('service unavailable', response.result?.confidence, 'Expected Confidence value Service Unavailable');
    }

    @isTest
    static void testValidateEmailInsufficientExperianCredits() {
        // Given
        Test.setMock(HttpCalloutMock.class, new EDQEmailService_Test.EDQEmailInsufficientExperianCreditsMock());
        
        // When
        EDQEmailService req = new EDQEmailService();
        EDQEmailDAO.EmailResponse response = req.validateEmail('test@gmail.com');

        // Then
        System.assertNotEquals(null, response?.result, 'Response did not have a result');
        System.assertEquals('test@gmail.com', response?.result?.email, 'Validated email did not match');
        System.assertEquals('forbidden', response.result?.confidence, 'Expected Confidence value forbidden');
    }

    @isTest
    static void testValidateMethod() {

        // Given : Mock experian validation callout
        Test.setMock(HttpCalloutMock.class, new EDQEmailService_Test.EDQEmailServiceValidationSuccessResMock());

        // When : Email address is supplied for validation
        EDQEmailDAO.EmailResponse response = EDQEmailService.validate('test@gmail.com');
        
        // Then : The supplied phone number is validated
        Assert.isNotNull(response?.result, 'Response did not have a result');
        Assert.areEqual('test@gmail.com', response?.result?.email, 'Validated email did not match');
    }

    @isTest
    static void testValidateEmailUnknownStatus() {
        // Given : Mock experian validation callout
        Test.setMock(HttpCalloutMock.class, new EDQEmailService_Test.EDQEmailServiceUnknownStatus());

        // When : Email address is supplied for validation
        EDQEmailService req = new EDQEmailService();
        EDQEmailDAO.EmailResponse response = req.validateEmail('test@edmundrice.org');

        // Then  : The supplied phone number is validated, the confidence is set to 'unknown'
        Assert.isNotNull(response?.result, 'Response did not have a result');
        Assert.areEqual('test@edmundrice.org', response?.result?.email, 'Validated email did not match');
        Assert.areEqual('unknown', response?.result?.confidence, 'Incorrect confidence value returned');
    }
}