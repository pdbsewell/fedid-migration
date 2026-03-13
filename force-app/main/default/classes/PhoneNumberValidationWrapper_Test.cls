/**
 * @author      Sachin Shetty
 * @description Test Class for PhoneNumberValidationWrapper
 * @group       Test Class
 * @revision    2022-10-12 - Sachin Shetty - Removed country attribute related test method
 *              2022-09-06 - Sachin Shetty - Created
**/
@isTest(isParallel=true)
public class PhoneNumberValidationWrapper_Test {
    
    // Test for code coverage, no logic in the code, just fetching the confidence level and their descriptions
    @isTest
    static void testConfidenceLevelDescriptions() {
        // Given
        // When
        Map<String, String> confidenceLevelAndDescriptions = PhoneNumberValidationWrapper.confidenceLevelDescriptions;
        
        // Then
        System.assertNotEquals(null, confidenceLevelAndDescriptions, 'Wrapper not returned');
        System.assert(confidenceLevelAndDescriptions.containsKey('Verified'), 'Confidence value does not exist');
        System.assertEquals('Number format validated and number verified.',confidenceLevelAndDescriptions.get('Verified'), 'Incorrect confidence level description');
    }

    @isTest
    static void testShowGenericErrorMessageDecision() {
        // Given
        // insert custom settings
        EDQ_Settings__c experianSettings = EDQ_Settings__c.getOrgDefaults();
        experianSettings.Phone_Validation_Show_Generic_Error__c = true;
        insert experianSettings;

        // When
        Boolean result = PhoneNumberValidationWrapper.showGenericErrorMessage;

        // Then
        System.assertEquals(true, result, 'Incorrect validation message decision returned');
    }

    // Test for code coverage, no logic in the code, just fetching the wrapper
    @isTest
    static void testGetPhoneNumberWrapper() {
        // Given
        // When
        PhoneNumberValidationWrapper.PhoneNumberWrapper phoneWrapper = new PhoneNumberValidationWrapper.PhoneNumberWrapper();
        
        // Then
        System.assertNotEquals(null, phoneWrapper, 'Wrapper not returned');
    }
}