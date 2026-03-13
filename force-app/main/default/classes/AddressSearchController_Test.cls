/**
 * @author      Sachin Shetty
 * @description Test Class for AddressSearchController
 * @group       Test Class
 * @revision    2022-10-17 - Sachin Shetty   - Update to uniquely identify each guest user
 *              2022-10-12 - Sachin Shetty - Updated country attribute related test methods
 *              2022-10-04 - Sachin Shetty - Rate limiting changes
 *              2022-08-24 - Sachin Shetty - testGetCountryAttributes updated
 *              2022-06-17 - Sachin Shetty - Created
**/
@isTest(isParallel=true)
public class AddressSearchController_Test {
    
    @isTest
    static void testSearchAddressSuccess() {
        // Given
        Test.setMock(HttpCalloutMock.class, new EDQAddressService_Test.EDQAddressServiceSearchAddressSuccessResMock());

        // When
        Test.startTest();
            EDQAddressDAO.AddressResponse response = AddressSearchController.search('Test sug', 'AUS');
        Test.stopTest();

        // Then
        System.assertEquals(1, response?.result?.suggestions.size(), 'Expected a single suggestion to be returned as the request is successful');
        System.assertEquals('Test-address-key', response?.result?.suggestions[0]?.global_address_key, 'Incorrect address key returned');
        System.assertEquals('Test suggested address', response?.result?.suggestions[0]?.text, 'Incorrect suggested address returned');
    }

    @isTest
    static void testFormatAddressSuccess() {
        // Given
        Test.setMock(HttpCalloutMock.class, new EDQAddressService_Test.EDQAddressServiceFormatAddressSuccessResMock());

        String RECORD_NAME = 'test';
        Integer MINIMUM_SECS = 0;
        String key = 'testkey';

        // insert a custom setting test record
        IP_Rate_Limit_Settings__c rateLimitSetting = new IP_Rate_Limit_Settings__c(
            Name = RECORD_NAME,
            Min_Secs_Between_Invocations__c = MINIMUM_SECS,
            Limit_Non_Guest_Users__c = true
        );
        insert rateLimitSetting;

        // When
        Test.startTest();
            EDQAddressDAO.AddressFormatResponse response = AddressSearchController.format('Test-global-address-key', RECORD_NAME, key);
        Test.stopTest();
        
        // Then
        System.assertEquals('U 2  700 Blackburn Rd', response?.result?.address?.address_line_1, 'Incorrect address_line_1 returned');
        System.assertEquals('AUSTRALIA', response?.result?.address?.country, 'Incorrect country returned');
    }

    @isTest
    static void testFormatAddressRateLimitBlock() {
        // Given
        Test.setMock(HttpCalloutMock.class, new EDQAddressService_Test.EDQAddressServiceFormatAddressSuccessResMock());

        String RECORD_NAME = 'test';
        Integer MINIMUM_SECS = 60;
        String key = 'testkey';

        // insert a custom setting test record
        IP_Rate_Limit_Settings__c rateLimitSetting = new IP_Rate_Limit_Settings__c(
            Name = RECORD_NAME,
            Min_Secs_Between_Invocations__c = MINIMUM_SECS,
            Limit_Non_Guest_Users__c = true
        );
        insert rateLimitSetting;

        // When
        Test.startTest();
            EDQAddressDAO.AddressFormatResponse response1 = AddressSearchController.format('Test-global-address-key1', RECORD_NAME, key);
            EDQAddressDAO.AddressFormatResponse response2 = AddressSearchController.format('Test-global-address-key2', RECORD_NAME, key);
        Test.stopTest();
        
        // Then
        System.assertEquals(null, response2, 'Expected Experian format service to be blocked by rate limit');
    }

    @isTest
    static void testGetTopCountriesList() {
        // Given
        // get a test country
        Schema.DescribeFieldResult fieldResult = Country_Attribute__c.Country__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntry = fieldResult.getPicklistValues();
        Schema.PicklistEntry testCountry = picklistEntry[0];

        // insert test country attribute records
        List<Country_Attribute__c> countryAttributes = new List<Country_Attribute__c>{
            new Country_Attribute__c(
                Country__c = testCountry.getValue(),
                ISO_Alpha_2__c = 'AB',
                ISO_Alpha_3__c = 'ABC'
            ),
            new Country_Attribute__c(
                Country__c = 'AUSTRALIA',
                ISO_Alpha_2__c = 'AU',
                ISO_Alpha_3__c = 'AUS'
            ),
            new Country_Attribute__c(
                Country__c = 'INDIA',
                ISO_Alpha_2__c = 'IN',
                ISO_Alpha_3__c = 'IND'
            )
        };
        insert countryAttributes;

        // insert custom settings with frequently used countries
        EDQ_Settings__c experianSettings = EDQ_Settings__c.getOrgDefaults();
        experianSettings.Top_Countries__c = 'AUSTRALIA,CHINA,INDIA,ITALY,MALAYSIA,SOUTH AFRICA';
        insert experianSettings;

        // When
        Test.startTest();
            List<Country_Attribute__c> listResults = AddressSearchController.getTopCountriesList();
        Test.stopTest();
        
        List<String> countryAlpha3List = new List<String>();
        for(Country_Attribute__c country : listResults){
            countryAlpha3List.add(country.ISO_Alpha_3__c);
        }

        // Then
        System.assertEquals(2, countryAlpha3List.size(), 'Incorrect number of Country Attributes returned');
        System.assert(countryAlpha3List.contains('IND'), 'Incorrect Country ISO 3 code');
    }

    @isTest
    static void testGetRestOfTheCountriesList() {
        // Given
        // get a test country
        Schema.DescribeFieldResult fieldResult = Country_Attribute__c.Country__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntry = fieldResult.getPicklistValues();
        Schema.PicklistEntry testCountry = picklistEntry[0];

        // insert test country attribute records
        List<Country_Attribute__c> countryAttributes = new List<Country_Attribute__c>{
            new Country_Attribute__c(
                Country__c = testCountry.getValue(),
                ISO_Alpha_2__c = 'AB',
                ISO_Alpha_3__c = 'ABC'
            ),
            new Country_Attribute__c(
                Country__c = 'AUSTRALIA',
                ISO_Alpha_2__c = 'AU',
                ISO_Alpha_3__c = 'AUS'
            ),
            new Country_Attribute__c(
                Country__c = 'INDIA',
                ISO_Alpha_2__c = 'IN',
                ISO_Alpha_3__c = 'IND'
            )
        };
        insert countryAttributes;

        // insert custom settings with frequently used countries
        EDQ_Settings__c experianSettings = EDQ_Settings__c.getOrgDefaults();
        experianSettings.Top_Countries__c = 'AUSTRALIA,CHINA,INDIA,ITALY,MALAYSIA,SOUTH AFRICA';
        insert experianSettings;

        // When
        Test.startTest();
            List<Country_Attribute__c> listResults = AddressSearchController.getRestOfTheCountriesList();
        Test.stopTest();

        // Then
        System.assertEquals(1, listResults.size(), 'Incorrect number of Country Attributes returned');
        System.assertEquals('ABC', listResults.get(0).ISO_Alpha_3__c, 'Incorrect Country ISO 3 code');
    }

    // Test just for code coverage, no logic in the code, just fetching the wrapper
    @isTest
    static void testGetAddressWrapper()
    {
        // Given
        // When
        AddressSearchWrapper.AddressWrapper addWrapper = AddressSearchController.getAddressWrapper();
        
        // Then
        System.assertNotEquals(null, addWrapper, 'Wrapper not returned');
    }
}