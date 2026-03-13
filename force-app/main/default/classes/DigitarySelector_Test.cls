/**
 * @description       : Test class for DigitarySelector
 * @author            : Kai-Fan Hsieh
 * @since             : 23-07-2024
 */
@isTest(isParallel=false) //APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object: User: []
private class DigitarySelector_Test {

    /**
     * @description : Test to verify if the Digitary Integration feature is enabled
     */
    @isTest
    static void testIsDigitaryIntegrationEnabled() {
        // Given: A feature switch record with Digitary Integration enabled
        Feature_Switch__c fs = new Feature_Switch__c();
        fs.Digitary_Integration__c = true;
        insert fs;

        // When: Checking if the Digitary Integration feature is enabled
        System.runAs(StudFirst_TestHelper.createContactAndCommunityUser()) {
            Test.startTest();
            Boolean result = new DigitarySelector().isDigitaryIntegrationEnabled();
            Test.stopTest();
            // Then: The result should be true, indicating the feature is enabled
            Assert.isTrue(result, 'Digitary Integration feature should be enabled');
        }
    }

    /**
     * @description : Test to select Digitary Credential Providers based on country code
     */
    @isTest
    static void testSelectDigitaryCredentialProviders() {
        // Given: A country code 'CN'
        String countryCode = 'CN';

        // When: Selecting credential providers for the given country code
        System.runAs(StudFirst_TestHelper.createContactAndCommunityUser()) {
            Test.startTest();
            System_Settings__mdt result = new DigitarySelector().selectCredentialProviders(countryCode);
            Test.stopTest();
            // Then: The result's key should match the given country code
            Assert.areEqual(countryCode, result.Key__c, 'Country code should match to key');
        }
    }

    /**
     * @description : Test to select Digitary Polling Interval
     */
    @isTest
    static void testSelectDigitaryDocumentPollingInterval() {
        // When: Selecting Digitary document polling interval
        System.runAs(StudFirst_TestHelper.createContactAndCommunityUser()) {
            Test.startTest();
            System_Settings__mdt result = new DigitarySelector().selectDocumentPollingInterval();
            Test.stopTest();
            // Then: The result's value should not be null
            Assert.areNotEqual(null, result.Value__c, 'Country code should match to key');
        }
    }
}