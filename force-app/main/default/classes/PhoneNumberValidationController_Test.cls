/**
 * @author      Sachin Shetty
 * @description Test Class for AddressSearchController
 * @group       Test Class
 * @revision    2022-10-12 - Sachin Shetty - Updated country attribute related test methods
 *              2022-06-17 - Sachin Shetty - Created
**/
@isTest(isParallel=true)
public class PhoneNumberValidationController_Test {

    @isTest
    static void testGetTopCountriesList()
    {
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
            List<Country_Attribute__c> listResults = PhoneNumberValidationController.getTopCountriesList();
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
    static void testGetRestOfTheCountriesList()
    {
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
            List<Country_Attribute__c> listResults = PhoneNumberValidationController.getRestOfTheCountriesList();
        Test.stopTest();

        // Then
        System.assertEquals(1, listResults.size(), 'Incorrect number of Country Attributes returned');
        System.assertEquals('ABC', listResults.get(0).ISO_Alpha_3__c, 'Incorrect Country ISO 3 code');
    }

    @isTest
    static void testValidatePhoneNumberSuccess() {
        // Given
        Test.setMock(HttpCalloutMock.class, new EDQPhoneNumberService_Test.EDQPhoneNumberServiceSearchAddressSuccessResMock());

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
            EDQPhoneNumberDAO.PhoneNumberResponse response = PhoneNumberValidationController.validate('2016477962', 'USA', RECORD_NAME, key);
        Test.stopTest();

        // Then
        System.assertNotEquals(null, response?.result, 'Response did not have a result');
        System.assertEquals('12016477962', response?.result?.validated_phone_number, 'Incorrect phone number returned');
        System.assertEquals('Mobile', response?.result?.phone_type, 'Incorrect phone type returned');
    }

    // Test for code coverage, no logic in the code, just fetching the wrapper
    @isTest
    static void testGetPhoneNumberWrapper()
    {
        // Given
        // When
        PhoneNumberValidationWrapper.PhoneNumberWrapper phoneNumberWrapper = PhoneNumberValidationController.getPhoneNumberWrapper();
        
        // Then
        System.assertNotEquals(null, phoneNumberWrapper, 'Wrapper not returned');
    }

    // Test for code coverage, no logic in the code, just fetching the confidence level and their descriptions
    @isTest
    static void testConfidenceLevelDescriptions()
    {
        // Given
        // When
        Map<String, String> confidenceLevelAndDescriptions = PhoneNumberValidationController.getConfidenceLevelDescriptions();
        
        // Then
        System.assertNotEquals(null, confidenceLevelAndDescriptions, 'Wrapper not returned');
        System.assert(confidenceLevelAndDescriptions.containsKey('Verified'), 'Confidence value does not exist');
        System.assertEquals('Number format validated and number verified.', confidenceLevelAndDescriptions.get('Verified'), 'Invalid description for the confidence value');
    }

    @isTest
    static void testShowGenericErrorMessageDecision() {
        // Given
        // insert custom settings
        EDQ_Settings__c experianSettings = EDQ_Settings__c.getOrgDefaults();
        experianSettings.Phone_Validation_Show_Generic_Error__c = true;
        insert experianSettings;

        // When
        Test.startTest();
            Boolean result = PhoneNumberValidationController.getShowGenericErrorMessageDecision();
        Test.stopTest();

        // Then
        System.assertEquals(true, result, 'Incorrect validation message decision returned');
    }

    @isTest
    static void testValidatePhoneRateLimitBlock() {
        // Given
        Test.setMock(HttpCalloutMock.class, new EDQPhoneNumberService_Test.EDQPhoneNumberServiceSearchAddressSuccessResMock());

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
            EDQPhoneNumberDAO.PhoneNumberResponse response1 = PhoneNumberValidationController.validate('2016477962', 'USA', RECORD_NAME, key);
            EDQPhoneNumberDAO.PhoneNumberResponse response2 = PhoneNumberValidationController.validate('2016477962', 'USA', RECORD_NAME, key);
        Test.stopTest();
        
        // Then
        System.assertEquals(null, response2, 'Expected Experian phone validation to be blocked by rate limit');
    }

    @isTest
    static void testCatchException() {
        // Given
        EDQPhoneNumberDAO.PhoneNumberResponse resp;
        // When
        Test.startTest();
        resp = PhoneNumberValidationController.createErrorResp(new LogUtilityException('Fake Error'));
        Test.stopTest();
        // Then
        System.assertNotEquals(null, resp, 'Error Creating Catch Response');
        
    }
}