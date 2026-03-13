/**
 * @description       : Test class for DigitaryServices
 * @author            : Kai-Fan Hsieh
 * @last modified on  : 17-07-2024
 * @last modified by  : Kai-Fan Hsieh
**/
@IsTest(IsParallel=false) //APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object: User: []
private class DigitaryServices_Test {
    private static final String CSSD_URL = 'https://my.chsi.com.cn';

    @TestSetup
    static void setup() {
        //Setup test data
        Environment_Settings__c envSettings = new Environment_Settings__c();
        envSettings.CssdURL__c = CSSD_URL;
        insert envSettings;
    }

    /**
     * @description : Test to verify if the Digitary Integration feature is enabled
     */
    @IsTest
    static void testIsDigitaryIntegrationEnabled() {
        // Given: A feature switch record with Digitary Integration enabled
        Feature_Switch__c fs = new Feature_Switch__c();
        fs.Digitary_Integration__c = true;
        insert fs;

        // When : Run the code under test as the Digitary API test user and check if the Digitary Integration feature is enabled
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            Test.startTest();
            Boolean result = DigitaryServices.isDigitaryIntegrationEnabled();
            Test.stopTest();
            // Then: The result should be true, indicating the feature is enabled
            Assert.isTrue(result, 'Digitary Integration feature should be enabled');
        }
    }

    /**
     * @description : Test to verify if the Digitary Integration feature is disabled for user who does not have integration - digitary custom permission assigned
     */
    @IsTest
    static void testIsDigitaryIntegrationDisabled() {
        // Given: A feature switch record with Digitary Integration enabled
        Feature_Switch__c fs = new Feature_Switch__c();
        fs.Digitary_Integration__c = true;
        insert fs;

        // When : Run the code under test as the My.App user
        System.runAs(StudFirst_TestHelper.createContactAndPartnerPortalUser()) {
            Test.startTest();
            Boolean result = DigitaryServices.isDigitaryIntegrationEnabled();
            Test.stopTest();
            // Then: The result should be false, indicating the feature is disabled
            Assert.isFalse(result, 'Digitary Integration feature should be disabled');
        }
    }

    /**
     * @description : Test to handle exception when checking if Digitary Integration feature is enabled
     */
    @IsTest
    static void testIsDigitaryIntegrationEnabledWithException() {
        // Given: A mocked DigitarySelector that throws a QueryException
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        DigitarySelector mockDigitarySelector = (DigitarySelector) mocks.mock(DigitarySelector.class);
        mocks.startStubbing(); // Stubbing start
        mocks.when(mockDigitarySelector.isDigitaryIntegrationEnabled()).thenThrow(new QueryException());
        mocks.stopStubbing(); // Stubbing end
        DigitaryServices.digitarySelector = mockDigitarySelector;
        AuraHandledException expectedException;

        // When: Attempting to check if the Digitary Integration feature is enabled
        try {
            System.runAs(StudFirst_TestHelper.createContactAndCommunityUser()) {
                Test.startTest();
                DigitaryServices.isDigitaryIntegrationEnabled();
                Test.stopTest();
            }
        } catch (AuraHandledException ex) {
            expectedException = ex;
        }

        // Then: An AuraHandledException should be thrown
        Assert.areNotEqual(null, expectedException, 'AuraHandledException should be thrown');
    }

    /**
     * @description : Test to retrieve Digitary Credential Providers based on country code and qualification type
     */
    @IsTest
    static void testRetrieveDigitaryCredentialProviders() {
        // Given: A country code 'CN' and a qualification type 'Tertiary Education'
        String countryCode = 'CN';
        String qualificationType = 'Tertiary Education';
        Feature_Switch__c fs = new Feature_Switch__c();
        fs.Digitary_Integration__c = true;
        insert fs;

        // When : Run the code under test as the Digitary API test user and retrieve credential providers for the given country code and qualification type
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            Test.startTest();
            List<DigitaryServices.CredentialProviderCmtWrapper> results = DigitaryServices.retrieveCredentialProvider(countryCode, qualificationType);
            Test.stopTest();
            // Then: The result list should contain one item with the matching country code
            Assert.areEqual(1, results.size(), 'Country code should match to key');
            Assert.areEqual(CSSD_URL, results[0].providerUrl, 'Provider Url should match');
        }
    }

    /**
     * @description : Test to handle exception when retrieving Digitary Credential Providers
     */
    @IsTest
    static void testRetrieveDigitaryCredentialProvidersWithException() {
        // Given: A mocked DigitarySelector that throws a QueryException
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        DigitarySelector mockDigitarySelector = (DigitarySelector) mocks.mock(DigitarySelector.class);
        mocks.startStubbing(); // Stubbing start
        mocks.when(mockDigitarySelector.isDigitaryIntegrationEnabled()).thenThrow(new QueryException());
        mocks.stopStubbing(); // Stubbing end
        DigitaryServices.digitarySelector = mockDigitarySelector;
        AuraHandledException expectedException;

        // When: Attempting to retrieve credential providers with null parameters
        try {
            System.runAs(StudFirst_TestHelper.createContactAndCommunityUser()) {
                Test.startTest();
                DigitaryServices.retrieveCredentialProvider(null, null);
                Test.stopTest();
            }
        } catch (AuraHandledException ex) {
            expectedException = ex;
        }

        // Then: An AuraHandledException should be thrown
        Assert.areNotEqual(null, expectedException, 'AuraHandledException should be thrown');
    }

    /**
     * @description : Test to retrieve Digitary Document Polling Interval
     */
    @IsTest
    static void testRetrieveDigitaryDocumentPollingInterval() {
        // When : Run the code under test as the My.App portal user to retrieve the document polling interval
        System.runAs(StudFirst_TestHelper.createContactAndPartnerPortalUser()) {
            Test.startTest();
            Long result = DigitaryServices.retrieveDocumentPollingInterval();
            Test.stopTest();
            // Then: The result list should contain one item with the matching country code
            Assert.areNotEqual(null, result, 'Digitary Document Polling Interval should not be null');
        }
    }

    /**
     * @description : Test to handle exception when retrieving Digitary Document Polling Interval
     */
    @IsTest
    static void testRetrieveDigitaryDocumentPollingIntervalWithException() {
        // Given: A mocked DigitarySelector that throws a QueryException
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        DigitarySelector mockDigitarySelector = (DigitarySelector) mocks.mock(DigitarySelector.class);
        mocks.startStubbing(); // Stubbing start
        mocks.when(mockDigitarySelector.selectDocumentPollingInterval()).thenThrow(new QueryException());
        mocks.stopStubbing(); // Stubbing end
        DigitaryServices.digitarySelector = mockDigitarySelector;
        AuraHandledException expectedException;

        // When : Run the code under test as the My.App portal user to retrieve the document polling interval
        try {
            System.runAs(StudFirst_TestHelper.createContactAndCommunityUser()) {
                Test.startTest();
                DigitaryServices.retrieveDocumentPollingInterval();
                Test.stopTest();
            }
        } catch (AuraHandledException ex) {
            expectedException = ex;
        }

        // Then: An AuraHandledException should be thrown
        Assert.areNotEqual(null, expectedException, 'AuraHandledException should be thrown');
    }

   
     /**
     * @description : Test retrieveContactQualCountry
     */
    @IsTest
    static void testRetrieveContactQualCountry() {
     // GIVEN : Community user data and Contact qualification data is created
        User applicant = StudFirst_TestHelper.createCommunityUser();

        //Create test contact
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

          Country_Attribute__c china = new Country_Attribute__c(Name = 'CHINA',
                                                                 Callista_Code__c = '5203',
                                                                 ISO_Alpha_2__c = 'CN',
                                                                 Country__c = 'CHINA');
                                                                 insert china;
        //Create Qualifications
        Qualification__c qual1 = StudFirst_TestHelper.createQualification('Secondary');
        insert qual1;

        //Create Contact Qualifications
        Contact_Qualification__c cq1 = StudFirst_TestHelper.createContactQualification(c, qual1, 'Secondary Education');
        cq1.Qualification_Country__c = china.Id;
        insert cq1;      
        // When : Run the code under test as the My.App portal user to retrieve the  Qualification country code
        String isoCode = null;
       
            System.runAs(applicant) {
                Test.startTest();
                    isoCode = DigitaryServices.retrieveContactQualCountryISO(cq1.Id);
                Test.stopTest();
            }
    
        // Then: ISO Country code must be returned.
        Assert.areEqual('CN', isoCode , 'Country code mus be CN');
    }

}