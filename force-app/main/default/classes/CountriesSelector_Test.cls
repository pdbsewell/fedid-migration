/**
 * @author      Kristian Vegerano
 * @description Test class for CountriesSelector class
 * @group       Test Class
 * @revision    16/09/2019 - Kristian Vegerano - Created
 * @revision    2/08/2022 - Ken McGuire - SFTG-2700
 */
@isTest(isParallel=true)
public with sharing class CountriesSelector_Test {
    /**
     * @description Setup test data
     */
    @testSetup 
    static void setup() {
        List<Country_Attribute__c> countryTestData = new List<Country_Attribute__c>();
        countryTestData.add(new Country_Attribute__c(Name = 'AUSTRALIA',
                                                     Callista_Code__c = BDPConstants.AUSTRALIA_CALLISTA_CODE,
                                                     Country__c = 'Australia',
                                                     NumericPhoneCode__c = '61',
                                                     SFDC_SMS_Unsupported__c = true));
        countryTestData.add(new Country_Attribute__c(Name = 'ENGLAND',
                                                     Callista_Code__c = '2102',
                                                     Country__c = 'United Kingdom', 
                                                     NumericPhoneCode__c = '44',
                                                     SFDC_SMS_Unsupported__c = false,
                                                     Sanctioned_by_Salesforce__c = true));
        insert countryTestData;
    }

    /**
     * @description Test select countries by Id
     */
    @isTest 
    static void test_SelectById() {
        //Initialize variables
        Set<Id> countriesIds = new Set<Id>();
        List<Country_Attribute__c> testCountriesList = new List<Country_Attribute__c>();

        //Retrieve existing account ids
        for(Country_Attribute__c loopCountry : [SELECT Id FROM Country_Attribute__c LIMIT 10]){
            countriesIds.add(loopCountry.Id);
        }

        //Start test process
	 	Test.startTest();
            testCountriesList.addAll(new CountriesSelector().selectById(countriesIds));
	 	Test.stopTest();

        //Start assertion
        Assert.areEqual(2, testCountriesList.size());
    }    

    /**
     * @description Test select countries by Id
     */
    @isTest 
    static void test_SelectByNameOverridePermissions() {
        //Initialize variables
        Set<String> countriesName = new Set<String>();
        List<Country_Attribute__c> testCountriesList = new List<Country_Attribute__c>();

        //Retrieve existing countries ids
        for(Country_Attribute__c loopCountry : [SELECT Id, Name FROM Country_Attribute__c LIMIT 10]){
            countriesName.add(loopCountry.Name);
        }

        //Start test process
	 	Test.startTest();
            testCountriesList.addAll(new CountriesSelector(true).selectByName(countriesName));
	 	Test.stopTest();

        //Start assertion
        Assert.areEqual(2, testCountriesList.size());
    }   
    
     /**
     * @description Test select countries by Id
     */
    @isTest 
    static void test_SelectAllOverridePermissions() {
        //Initialize variables
        List<Country_Attribute__c> testCountriesList = new List<Country_Attribute__c>();

        //Start test process
	 	Test.startTest();
            testCountriesList.addAll(new CountriesSelector(true).selectAll());
	 	Test.stopTest();

        //Start assertion
        Assert.areEqual(2, testCountriesList.size());
    }   
    /*
     * @author       Ken McGuire
     * @date         3.Aug.2022
     * @description  Tests construction of country list
     */
	@IsTest
    // Given (includes duplicate record)
    static void test_ConstructCountryList() {
     	List<Country_Attribute__c> countryTestData = new List<Country_Attribute__c>();
        countryTestData.add(new Country_Attribute__c(Name = 'AUSTRALIA',
                                                     ShortName__c = 'Australia',
                                                     Callista_Code__c = BDPConstants.AUSTRALIA_CALLISTA_CODE,
                                                     NumericPhoneCode__c = '61',
                                                     Blocked__c = false, 
                                                     Country__c = 'Australia'));
        countryTestData.add(new Country_Attribute__c(Name = 'ENGLAND',
                                                     ShortName__c = 'United Kingdom',
                                                     Callista_Code__c = '2102',
                                                     NumericPhoneCode__c = '42',
                                                     Blocked__c = false, 
                                                     Country__c = 'United Kingdom'));
        countryTestData.add(new Country_Attribute__c(Name = 'UK',
                                                     ShortName__c = 'United Kingdom',
                                                     NumericPhoneCode__c = '42',
                                                     Callista_Code__c = '2103',
                                                     Blocked__c = false, 
                                                     Country__c = 'United Kingdom'));
        insert countryTestData;  
        // When 
        List<Country_Attribute__c> countryList = CountriesSelector.validCountryList();
        // Then
        Assert.areEqual(2, countryList.size(),'Duplicate value should not appear in list');
    }

    /*
     * @author       Peter Sewell
     * @date         27.Nov.2023
     * @description  Tests sfdc sms unsupported flag
     */
	@IsTest
    static void test_IsSfdcSmsUnsupported() {

        //Start test process
	 	Test.startTest();
            Assert.areEqual(new CountriesSelector().isSfdcSmsUnsupported('+61'), true,'Country code +61 should not be supported');
            Assert.areEqual(new CountriesSelector().isSfdcSmsUnsupported('61'), true,'Country code 61 should not be supported');
            Assert.areEqual(new CountriesSelector().isSfdcSmsUnsupported('+44'), false,'Country code +44 should be supported');
            Assert.areEqual(new CountriesSelector().isSfdcSmsUnsupported('44'), false,'Country code 44 should be supported');
            Assert.areEqual(new CountriesSelector().isSfdcSmsUnsupported('99999999999'), false,'Country code 99999999999 should be supported');
            Assert.areEqual(new CountriesSelector().isSfdcSmsUnsupported(null), false,'Null country code should return false');
	 	Test.stopTest();
    }

    /*
     * @author       Vishal Gupta
     * @date         15.Nov.2025
     * @description  Tests sfdc sacntioned countries
     */
	@IsTest
    static void test_IsSfdcSacntioned() {

        //Start test process
	 	Test.startTest();
            Assert.areEqual(new CountriesSelector().isSanctionedBySFDC('+61'), false,'Country code +61 should not be supported');
            Assert.areEqual(new CountriesSelector().isSanctionedBySFDC('61'), false,'Country code 61 should not be supported');
            Assert.areEqual(new CountriesSelector().isSanctionedBySFDC('+44'), true,'Country code +44 should be supported');
            Assert.areEqual(new CountriesSelector().isSanctionedBySFDC('44'), true,'Country code 44 should be supported');
	 	Test.stopTest();
    }
    
    /*
     * @author       Vishal Gupta
     * @date         15.Nov.2025
     * @description  select all countries
     */
    @isTest 
    static void test_SelectAllCountries() {
        //Given: we have Countries listed in Country_Attribute object
        List<Country_Attribute__c> countryTestData = new List<Country_Attribute__c>();
        countryTestData.add(new Country_Attribute__c(Name = 'AUSTRALIA',
                                                     ShortName__c = 'Australia',
                                                     Callista_Code__c = BDPConstants.AUSTRALIA_CALLISTA_CODE,
                                                     NumericPhoneCode__c = '61',
                                                     Blocked__c = false, 
                                                     Country__c = 'Australia'));
        countryTestData.add(new Country_Attribute__c(Name = 'ENGLAND',
                                                     ShortName__c = 'United Kingdom',
                                                     Callista_Code__c = '2102',
                                                     NumericPhoneCode__c = '42',
                                                     Blocked__c = false, 
                                                     Country__c = 'United Kingdom'));
        countryTestData.add(new Country_Attribute__c(Name = 'UK',
                                                     ShortName__c = 'United Kingdom',
                                                     NumericPhoneCode__c = '42',
                                                     Callista_Code__c = '2103',
                                                     Blocked__c = false, 
                                                     Country__c = 'United Kingdom'));
        insert countryTestData;
        List<Country_Attribute__c> testCountriesList = new List<Country_Attribute__c>();

        //When: we query the object
	 	Test.startTest();
            testCountriesList.addAll(new CountriesSelector(true).selectAllCountries());
	 	Test.stopTest();

        //Then: it should return the country data
        Assert.areEqual(2, testCountriesList.size());
    }

    /*
     * @author       Vishal Gupta
     * @date         15.Nov.2025
     * @description  select valid countries
     */
    @isTest 
    static void test_SelectValidCountries() {
        //Given: we have Countries listed in Country_Attribute object
        List<Country_Attribute__c> countryTestData = new List<Country_Attribute__c>();
        countryTestData.add(new Country_Attribute__c(Name = 'AUSTRALIA',
                                                     ShortName__c = 'Australia',
                                                     Callista_Code__c = BDPConstants.AUSTRALIA_CALLISTA_CODE,
                                                     NumericPhoneCode__c = '61',
                                                     Blocked__c = false, 
                                                     Country__c = 'Australia'));
        countryTestData.add(new Country_Attribute__c(Name = 'ENGLAND',
                                                     ShortName__c = 'United Kingdom',
                                                     Callista_Code__c = '2102',
                                                     NumericPhoneCode__c = '42',
                                                     Blocked__c = false, 
                                                     Country__c = 'United Kingdom'));
        countryTestData.add(new Country_Attribute__c(Name = 'UK',
                                                     ShortName__c = 'United Kingdom',
                                                     NumericPhoneCode__c = '42',
                                                     Callista_Code__c = '2103',
                                                     Blocked__c = false, 
                                                     Country__c = 'United Kingdom'));
        insert countryTestData;
        List<Country_Attribute__c> testCountriesList = new List<Country_Attribute__c>();

        //When: we query the object
	 	Test.startTest();
            testCountriesList.addAll(CountriesSelector.validCountryList());
	 	Test.stopTest();

        //Then: it should return the country data
        Assert.areEqual(2, testCountriesList.size());
    }
}