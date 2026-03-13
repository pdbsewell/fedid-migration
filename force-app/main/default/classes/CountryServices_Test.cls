/* @description       : Provides test coverage to CuntryServices class.
 * @author            : Ken McGuire
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2023-02-12   Ken McGuire    Created
 * 20.3.2023	Ken McGuire - country of birth replace ISO with SAAC
 * 
**/
@isTest(isParallel=true)
private class CountryServices_Test {
    @testSetup
    static void setup() {
        // insert test country attribute records
		createTestCountryAttributes();
    }
    
    private static void createTestCountryAttributes() {
   		List<Country_Attribute__c> countryAttributes = new List<Country_Attribute__c>{
            new Country_Attribute__c(
                Country__c = 'United States of America',
                Callista_Country__c = 'United States of America',
                ISO_Alpha_2__c = 'US',
                ISO_Alpha_3__c = 'USA',
                Numeric_Country_Code__c = '001'
            ),
                new Country_Attribute__c(
                    Country__c = 'Australia',
                     Callista_Country__c = 'Australia',
                    ISO_Alpha_2__c = 'AU',
                    ISO_Alpha_3__c = 'AUS',
                    Numeric_Country_Code__c = '002'
                ),
                new Country_Attribute__c(
                    Country__c = 'India',
                    Callista_Country__c = 'India',
                    ISO_Alpha_2__c = 'IN',
                    ISO_Alpha_3__c = 'IND',
                    Numeric_Country_Code__c = '003'
                )
                };
    	insert countryAttributes;
    }

    @isTest
    static void testSearchCountry() {
        // given
        String testCountry = 'INDIA';
        // when
        String foundCountry = CountryServices.getCountryName(testCountry,CountryServices.FORMAT_ISO);
        // then
        System.assertEquals('India', foundCountry,'should find India');
    }
    
    @isTest
    static void testSearchCountryByCode() {
        // given
        String testCountry = '003';
        // when
        String foundCountry = CountryServices.getCountryName(testCountry,CountryServices.FORMAT_ISO);
        // then
        System.assertEquals('India', foundCountry,'should find India');
    }    
    
    @isTest
    static void testSearchCountryBySAAC() {
        // given
        String testCountry = '003';
        // when
        String foundCountry = CountryServices.getCountryName(testCountry,CountryServices.FORMAT_SAAC);
        // then
        System.assertEquals('India', foundCountry,'should find India');
    }  
    
    @isTest
    static void testGetCountryOptionsSAAC() {
        // when
        List<Map<String,String>> options = CountryServices.getCountryAttributeOptions(CountryServices.FORMAT_SAAC,false);
        // then
        System.assertEquals(3, options.size(),'Should be three options');
        System.AssertEquals('Australia',options[0].get(CountryServices.FIELD_LABEL),'First option should be Australia');
    }
        
    @isTest
    static void testGetCountryOptionsISO() {
        // when
        List<Map<String,String>> options = CountryServices.getCountryAttributeOptions(CountryServices.FORMAT_ISO,false);
        // then
        System.assertEquals(3, options.size(),'Should be three options');
        System.AssertEquals('Australia',options[0].get(CountryServices.FIELD_LABEL),'First option should be Australia');
    }
    
    @isTest
    static void testGetCountryOptionsWithEmptyOption() {
        // when
        List<Map<String,String>> options = CountryServices.getCountryAttributeOptions(CountryServices.FORMAT_ISO,true);
        // then
        System.assertEquals(4, options.size(),'Should be three options');
        System.AssertEquals(CountryServices.EMPTY_OPTION,options[0].get(CountryServices.FIELD_LABEL),'First option should be the empty option');
    }
    
    
    @isTest
    static void testGetCountry() {
        // given
        String testCountry = 'united states of america';
        // when
        Country_Attribute__c foundCountry = CountryServices.getCountry(testCountry);
        // then 
        System.assertEquals('United States of America', foundCountry.country__c,'should find United States of America');
    }
    
    @isTest
    static void testSearhMustStartWithString() {
        // given
        String testCountry = 'States';
        // when
        Country_Attribute__c foundCountry = CountryServices.getCountry(testCountry);
        // then 
        System.assertEquals(null, foundCountry,'should not search for containment');
    }
    
    @isTest
    static void getCountryId() {
        // given
         String testCountry = 'united states of america';
        // when
        Id foundCountryId = CountryServices.getCountryId(testCountry);
        // then 
        System.assertNotEquals(null, foundCountryId,'should find country Id');
    }
    
    @isTest
    static void getCountryIdForFormat() {
        // given
         String testCountry = 'united states of america';
        // when
        Id foundCountryId = CountryServices.getCountryId(testCountry,CountryServices.FORMAT_ISO);
        // then 
        System.assertNotEquals(null, foundCountryId,'should find country Id');
    }
}