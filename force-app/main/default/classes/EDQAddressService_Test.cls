/**
 * @author      Sachin Shetty
 * @description Test Class for EDQAddressService
 * @group       Test Class
 * @revision    2022-06-17 - Sachin Shetty - Created
 **/
@isTest(isParallel=true)
public class EDQAddressService_Test {
    /**
     * @author                      Sachin Shetty
     * @created                     2022-06-17
     * @description                 Test Mock for EDQAddressService search address
     */
    public class EDQAddressServiceSearchAddressSuccessResMock implements HttpCalloutMock {
        /**
         * @author                      Sachin Shetty
         * @created                     2022-06-17
         * @description                 Test Response when EDQAddressService search address has been called
         */
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"result":{"more_results_available":false,"confidence":"Verified match","suggestions":[{"global_address_key":"Test-address-key","text":"Test suggested address","matched":[],"format":"format"}]}}');
            response.setStatusCode(200);
            return response;
        }
    }
    /**
     * @author                      Sachin Shetty
     * @created                     2022-06-17
     * @description                 Test Mock for EDQAddressService format address
     */
    public class EDQAddressServiceFormatAddressSuccessResMock implements HttpCalloutMock {
        /**
         * @author                      Sachin Shetty
         * @created                     2022-06-17
         * @description                 Test Response when EDQAddressService format address has been called
         */
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"result":{"global_address_key":"Test-global-address-key","confidence":"Verified match","address":{"address_line_1":"U 2  700 Blackburn Rd","address_line_2":"","address_line_3":"","locality":"NOTTING HILL","region":"VIC","postal_code":"3168","country":"AUSTRALIA"}}}');
            response.setStatusCode(200);
            return response;
        }
    }
    /**
     * @author                      Sachin Shetty
     * @created                     2022-06-17
     * @description                 Test Mock for unauthorized access
     */
    private class EDQAddressServiceUnauthorizedAccessMock implements HttpCalloutMock {
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
     * @created                     2022-08-24
     * @description                 Test Mock for miscellaneous errors
     */
    private class EDQAddressServiceMiscErrorMock implements HttpCalloutMock {
        /**
         * @author                      Sachin Shetty
         * @created                     2022-08-24
         * @description                 Test Response when EDQAddressService search returns other errors
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
     * @created                     2022-08-24
     * @description                 Test Mock for unavailable service
     */
    private class EDQAddressServiceUnavailableMock implements HttpCalloutMock {
        /**
         * @author                      Sachin Shetty
         * @created                     2022-08-24
         * @description                 Test Response when EDQAddressService validate is called but Experian service is unavailable
         */
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"result":{"confidence": "Service Unavailable"}}');
            response.setStatusCode(503);
            return response;
        }
    }
    /**
     * @author                      Sachin Shetty
     * @created                     2022-09-26
     * @description                 Test Mock for insufficient Experian credits
     */
    private class EDQAddressServiceInsufficientExperianCreditsMock implements HttpCalloutMock {
        /**
         * @author                      Sachin Shetty
         * @created                     2022-09-06
         * @description                 Test Response when EDQAddressService validate is called but the Experian credits are insufficient
         */
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"result":{"confidence": "Forbidden"}}');
            response.setStatusCode(403);
            return response;
        }
    }
    @isTest
    static void testSearchAddressSuccessResponse() {
        // Given
        Test.setMock(HttpCalloutMock.class, new EDQAddressService_Test.EDQAddressServiceSearchAddressSuccessResMock());
        // When
        EDQAddressService req = new EDQAddressService();
        EDQAddressDAO.AddressResponse response = req.searchAddress('Test su', 'AUS');
        // Then
        System.assertEquals(1, response?.result?.suggestions.size(), 'Expected a single suggestion to be returned as the request is successful');
        System.assertEquals('Test-address-key', response?.result?.suggestions[0].global_address_key, 'Incorrect address key returned');
        System.assertEquals('Test suggested address', response?.result?.suggestions[0].text, 'Incorrect suggested address returned');
    }

    @isTest
    static void testSearchAddressUnauthorizedAccessException() {
        Test.setMock(HttpCalloutMock.class, new EDQAddressService_Test.EDQAddressServiceUnauthorizedAccessMock());
        try {
            EDQAddressService req = new EDQAddressService();
            EDQAddressDAO.AddressResponse response = req.searchAddress('Test su', 'AUS');
        }
        catch (Exception e) {
            System.assertNotEquals(null,
                                e,
                                'Expected UnauthorizedAccess Exception');
        }
    }

    @isTest
    static void testSearchAddressMiscErrorException() {
        // Given
        Test.setMock(HttpCalloutMock.class, new EDQAddressService_Test.EDQAddressServiceMiscErrorMock());
        // When
        try {
            EDQAddressService req = new EDQAddressService();
            EDQAddressDAO.AddressResponse response = req.searchAddress('Test su', 'AUS');
        }
        catch (Exception e) {
            // Then
            System.assertNotEquals(null,
                                e,
                                'Expected Miscellaneous Error Exception');
        }
    }

    @isTest
    static void testSearchAddressUnavailableService() {
        // Given
        Test.setMock(HttpCalloutMock.class, new EDQAddressService_Test.EDQAddressServiceUnavailableMock());
        // When
        EDQAddressService req = new EDQAddressService();
        EDQAddressDAO.AddressResponse response = req.searchAddress('Test su', 'AUS');
        // Then
        System.assertNotEquals(null, response?.result, 'Response did not have a result');
        System.assertEquals('Service Unavailable', response.result?.confidence, 'Expected Confidence value Service Unavailable not returned');
    }

    @isTest
    static void testSearchAddressInsufficientExperianCredits() {
        // Given
        Test.setMock(HttpCalloutMock.class, new EDQAddressService_Test.EDQAddressServiceInsufficientExperianCreditsMock());
        // When
        EDQAddressService req = new EDQAddressService();
        EDQAddressDAO.AddressResponse response = req.searchAddress('Test su', 'AUS');
        // Then
        System.assertNotEquals(null, response?.result, 'Response did not have a result');
        System.assertEquals('Forbidden', response.result?.confidence, 'Expected Confidence value Forbidden not returned');
    }

    @isTest
    static void testFormatAddressSuccessResponse() {
        // Given
        Test.setMock(HttpCalloutMock.class, new EDQAddressService_Test.EDQAddressServiceFormatAddressSuccessResMock());
        // When
        EDQAddressService req = new EDQAddressService();
        EDQAddressDAO.AddressFormatResponse response = req.formatAddress('Test-global-address-key');
        // Then
        System.assertEquals('U 2  700 Blackburn Rd', response?.result?.address.address_line_1, 'Incorrect address_line_1 returned');
        System.assertEquals('AUSTRALIA', response?.result?.address.country, 'Incorrect country returned');
    }

    @isTest
    static void testFormatAddressUnauthorizedAccessException() {
        Test.setMock(HttpCalloutMock.class, new EDQAddressService_Test.EDQAddressServiceUnauthorizedAccessMock());
        try {
            EDQAddressService req = new EDQAddressService();
            EDQAddressDAO.AddressFormatResponse response = req.formatAddress('Test-global-address-key');
        }
        catch (Exception e) {
            System.assert (false, 'Expected UnauthorizedAccess Exception');
        }
    }

    @isTest
    static void testFormatAddressMiscErrorException() {
        // Given
        Test.setMock(HttpCalloutMock.class, new EDQAddressService_Test.EDQAddressServiceMiscErrorMock());
        // When
        try {
            EDQAddressService req = new EDQAddressService();
            EDQAddressDAO.AddressFormatResponse response = req.formatAddress('Test-global-address-key');
        }
        catch (Exception e) {
            // Then
            System.assert (false, 'Expected Miscellaneous Error Exception');
        }
    }

    @isTest
    static void testFormatAddressUnavailableService() {
        // Given
        Test.setMock(HttpCalloutMock.class, new EDQAddressService_Test.EDQAddressServiceUnavailableMock());
        // When
        EDQAddressService req = new EDQAddressService();
        EDQAddressDAO.AddressFormatResponse response = req.formatAddress('Test-global-address-key');
        // Then
        System.assertNotEquals(null, response?.result, 'Response did not have a result');
        System.assertEquals('Service Unavailable', response.result?.confidence, 'Expected Confidence value Service Unavailable');
    }

    @isTest
    static void testFormatAddressInsufficientExperianCredits() {
        // Given
        Test.setMock(HttpCalloutMock.class, new EDQAddressService_Test.EDQAddressServiceInsufficientExperianCreditsMock());
        // When
        EDQAddressService req = new EDQAddressService();
        EDQAddressDAO.AddressFormatResponse response = req.formatAddress('Test-global-address-key');
        // Then
        System.assertNotEquals(null, response?.result, 'Response did not have a result');
        System.assertEquals('Forbidden', response.result?.confidence, 'Expected Confidence value Forbidden');
    }

    @isTest
    static void testGetCountry() {
        // Given : A test country is inserted
        List<Country_Attribute__c> countryAttributes = new List<Country_Attribute__c>{
            new Country_Attribute__c(
                Country__c = 'United States of America',
                Callista_Country__c = 'United States of America',
                ISO_Alpha_2__c = 'US',
                ISO_Alpha_3__c = 'USA',
                Numeric_Country_Code__c = '001'
            )
        };
    	insert countryAttributes;

        String testCountry = 'united states of america';
        // When
        Country_Attribute__c foundCountry = EDQAddressService.retrieveCountryRecord(testCountry);

        // Then : The country attribute record matching the passed country name is returned
        System.assertEquals('United States of America', foundCountry.country__c,'should find United States of America');
    }
}