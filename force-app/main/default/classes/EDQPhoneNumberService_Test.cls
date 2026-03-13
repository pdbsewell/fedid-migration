/**
 * @author      Sachin Shetty
 * @description Test Class for EDQPhoneNumberService
 * @group       Test Class
 * @revision    2022-08-03 - Sachin Shetty - Created
 *              2023-12-04 - Sachin Shetty - Added validate method that gets called from lwc
**/
@isTest(isParallel=true)
public class EDQPhoneNumberService_Test {

    /**
     * @author                      Sachin Shetty
     * @created                     2022-08-03
     * @description                 Test Mock for EDQPhoneNumberService search address
     */
    public class EDQPhoneNumberServiceSearchAddressSuccessResMock implements HttpCalloutMock {
       
        /**
         * @author                      Sachin Shetty
         * @created                     2022-08-03
         * @description                 Test Response when EDQPhoneNumberService validate has been called
         */
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"result":{"validated_phone_number":12016477962,"formatted_phone_number":"(201) 647-7962","phone_type":"Mobile","confidence": "Verified","ported_date": "2019-08-21T00:00:00Z","disposable_number": "Yes"}}');
            response.setStatusCode(200);
            return response; 
        }
    }

    /**
     * @author                      Sachin Shetty
     * @created                     2022-08-03
     * @description                 Test Mock for unauthorized access
     */
    private class EDQPhoneNumberServiceUnauthorizedAccessMock implements HttpCalloutMock {
        
        /**
         * @author                      Sachin Shetty
         * @created                     2022-08-03
         * @description                 Test Response when EDQPhoneNumberService validate is called with invalid token
         */
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
     * @created                     2022-08-16
     * @description                 Test Mock for miscellaneous errors 
     */
    private class EDQPhoneNumberServiceMiscErrorMock implements HttpCalloutMock {
        
        /**
         * @author                      Sachin Shetty
         * @created                     2022-08-16
         * @description                 Test Response when EDQPhoneNumberService validate returns other miscellaneous errors
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
     * @created                     2022-08-16
     * @description                 Test Mock for unavailable service
     */
    private class EDQPhoneNumberServiceUnavailableMock implements HttpCalloutMock {
        
        /**
         * @author                      Sachin Shetty
         * @created                     2022-08-16
         * @description                 Test Response when EDQPhoneNumberService validate is called but Experian service is unavailable
         */
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"result":{"validated_phone_number":12016477962,"confidence": "Service Unavailable"}}');
            response.setStatusCode(503);
            return response;
        }
    }

    /**
     * @author                      Sachin Shetty
     * @created                     2022-09-06
     * @description                 Test Mock for insufficient Experian credits
     */
    private class EDQPhoneNumberInsufficientExperianCreditsMock implements HttpCalloutMock {
        
        /**
         * @author                      Sachin Shetty
         * @created                     2022-09-06
         * @description                 Test Response when EDQPhoneNumberService validate is called but the Experian credits are insufficient 
         */
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"result":{"validated_phone_number":12016477962,"confidence": "Forbidden"}}');
            response.setStatusCode(403);
            return response;
        }
    }

    @isTest
    static void testPhoneValidationSuccessResponse() {
        // Given
        Test.setMock(HttpCalloutMock.class, new EDQPhoneNumberService_Test.EDQPhoneNumberServiceSearchAddressSuccessResMock());

        // When
        EDQPhoneNumberService req = new EDQPhoneNumberService();
        EDQPhoneNumberDAO.PhoneNumberResponse response = req.validatePhoneNumber('2016477962', 'USA');

        // Then
        System.assertNotEquals(null, response?.result, 'Response did not have a result');
        System.assertEquals('12016477962', response?.result?.validated_phone_number, 'Incorrect phone number returned');
        System.assertEquals('Mobile', response?.result?.phone_type, 'Incorrect phone type returned');
    }

    @isTest
    static void testPhoneValidationUnauthorizedAccessException() {
        // Given
        Test.setMock(HttpCalloutMock.class, new EDQPhoneNumberService_Test.EDQPhoneNumberServiceUnauthorizedAccessMock());
        
        // When
        try {
            EDQPhoneNumberService req = new EDQPhoneNumberService();
            EDQPhoneNumberDAO.PhoneNumberResponse response = req.validatePhoneNumber('2016477962', 'USA');
        } 
        catch (Exception e) {
            // Then
            System.assertNotEquals(null,
                                e,
                                'Expected UnauthorizedAccess Exception');
        }
    }

    @isTest
    static void testPhoneValidationMiscErrorException() {
        // Given
        Test.setMock(HttpCalloutMock.class, new EDQPhoneNumberService_Test.EDQPhoneNumberServiceMiscErrorMock());
        
        // When
        try {
            EDQPhoneNumberService req = new EDQPhoneNumberService();
            EDQPhoneNumberDAO.PhoneNumberResponse response = req.validatePhoneNumber('2016477962', 'USA');
        } 
        catch (Exception e) {
            // Then
            System.assertNotEquals(null,
                                e,
                                'Expected Miscellaneous Error Exception');
        }
    }

    @isTest
    static void testPhoneValidationUnavailableService() {
        // Given
        Test.setMock(HttpCalloutMock.class, new EDQPhoneNumberService_Test.EDQPhoneNumberServiceUnavailableMock());
        
        // When
        EDQPhoneNumberService req = new EDQPhoneNumberService();
        EDQPhoneNumberDAO.PhoneNumberResponse response = req.validatePhoneNumber('2016477962', 'USA');

        // Then
        System.assertNotEquals(null, response?.result, 'Response did not have a result');
        System.assertEquals('2016477962', response.result?.formatted_phone_number, 'Incorrect phone number returned');
        System.assertEquals('Service Unavailable', response.result?.confidence, 'Expected Confidence value Service Unavailable');
    }

    @isTest
    static void testPhoneValidationInsufficientExperianCredits() {
        // Given
        Test.setMock(HttpCalloutMock.class, new EDQPhoneNumberService_Test.EDQPhoneNumberInsufficientExperianCreditsMock());
        
        // When
        EDQPhoneNumberService req = new EDQPhoneNumberService();
        EDQPhoneNumberDAO.PhoneNumberResponse response = req.validatePhoneNumber('2016477962', 'USA');

        // Then
        System.assertNotEquals(null, response?.result, 'Response did not have a result');
        System.assertEquals('2016477962', response.result?.formatted_phone_number, 'Incorrect phone number returned');
        System.assertEquals('Forbidden', response.result?.confidence, 'Expected Confidence value Forbidden');
    }

    @isTest
    static void testValidateMethod() {
        // Given : Mock experian validation callout
        Test.setMock(HttpCalloutMock.class, new EDQPhoneNumberService_Test.EDQPhoneNumberServiceSearchAddressSuccessResMock());

        // When : Phone number and CountryISO is supplied for validation
        EDQPhoneNumberDAO.PhoneNumberResponse response = EDQPhoneNumberService.validate('2016477962', 'USA');

        // Then : The supplied phone number is validated
        Assert.isNotNull(response?.result, 'Response did not have a result');
        Assert.areEqual('12016477962', response?.result?.validated_phone_number, 'Incorrect phone number returned');
    }
}