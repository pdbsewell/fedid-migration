/**
 * @author      Sachin Shetty
 * @description Test Class for ExperianUtility
 * @group       Test Class
 * @revision    2022-10-17 - Sachin Shetty - Update to uniquely identify each guest user
 *              2022-10-12 - Sachin Shetty - Added country attribute related test methods
 *              2022-10-04 - Sachin Shetty - Created
**/
@isTest(isParallel=true)
public class ExperianUtility_Test {

    @isTest
    static void testGetMinimumSecondsBetweenInvocations() {
        // Given
        String FORM_NAME = 'test';
        Integer MINIMUM_SECS = 5;

        // insert a custom setting test record
        IP_Rate_Limit_Settings__c rateLimitSetting = new IP_Rate_Limit_Settings__c(
            Name = FORM_NAME,
            Min_Secs_Between_Invocations__c = MINIMUM_SECS
        );
        upsert rateLimitSetting;

        // When
        Test.startTest();
            Integer result1 = ExperianUtility.getMinimumSecondsBetweenInvocations(FORM_NAME);
            Integer result2 = ExperianUtility.getMinimumSecondsBetweenInvocations('Random string');
        Test.stopTest();

        // Then
        System.assertEquals(MINIMUM_SECS, result1, 'Unexpected value returned by getMinimumSecondsBetweenInvocations');
        System.assertEquals(0, result2, 'Unexpected value returned by getMinimumSecondsBetweenInvocations, expected zero(0)');
    }

    @isTest
    static void testIPCheckExceedsLimit() {
        // Given
        String FORM_NAME = 'test';
        Integer MINIMUM_SECS = 300;
        String key = 'testkey';

        // insert a custom setting test record
        IP_Rate_Limit_Settings__c rateLimitSetting = new IP_Rate_Limit_Settings__c(
            Name = FORM_NAME,
            Min_Secs_Between_Invocations__c = MINIMUM_SECS,
            Limit_Non_Guest_Users__c = true
        );
        insert rateLimitSetting;

        // When
        Test.startTest();
            Boolean result1 = ExperianUtility.IPCheckExceedsLimit(FORM_NAME, key);
            Boolean result2 = ExperianUtility.IPCheckExceedsLimit(FORM_NAME, key);
        Test.stopTest();

        // Then
        System.assertEquals(false, result1, 'Unexpected value returned by IPCheckExceedsLimit, expected false');
        System.assertEquals(true, result2, 'Unexpected value returned by IPCheckExceedsLimit, expected true'); // Invoked again within 300 seconds, returns true(limit exceeded)
    }

    @isTest
    static void testGetAllCountries()
    {
        // Given
        // get a test country
        Schema.DescribeFieldResult fieldResult = Country_Attribute__c.Country__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntry = fieldResult.getPicklistValues();
        Schema.PicklistEntry testCountry = picklistEntry[0];

        // insert a test record
        Country_Attribute__c countryAttr = new Country_Attribute__c(
            Country__c = testCountry.getValue(),
            ISO_Alpha_2__c = 'AB',
            ISO_Alpha_3__c = 'ABC'
        );
        insert countryAttr;

        // insert custom settings with frequently used countries
        EDQ_Settings__c experianSettings = EDQ_Settings__c.getOrgDefaults();
        experianSettings.Top_Countries__c = 'AUSTRALIA,CHINA,INDIA,ITALY,MALAYSIA,SOUTH AFRICA';
        insert experianSettings;

        // When
        Test.startTest();
            List<Country_Attribute__c> listResults = ExperianUtility.allCountries;
        Test.stopTest();

        // Then
        System.assertEquals(1, listResults.size(), 'Incorrect number of Country Attributes returned');
        System.assertEquals(testCountry.getValue(), listResults.get(0).Country__c, 'Incorrect Country name');
        System.assertEquals('AB', listResults.get(0).ISO_Alpha_2__c, 'Incorrect Country ISO 2 code');
    }

    @isTest
    static void testFrequentlyUsedCountries()
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
            List<Country_Attribute__c> listResults = ExperianUtility.topCountriesList;
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
    static void testRestCountries()
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
            List<Country_Attribute__c> listResults = ExperianUtility.restOfTheCountriesList;
        Test.stopTest();

        // Then
        System.assertEquals(1, listResults.size(), 'Incorrect number of Country Attributes returned');
        System.assertEquals('ABC', listResults.get(0).ISO_Alpha_3__c, 'Incorrect Country ISO 3 code');
    }
}