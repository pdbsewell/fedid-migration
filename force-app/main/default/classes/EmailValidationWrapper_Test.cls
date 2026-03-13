/**
 * @author      Sachin Shetty
 * @description Test Class for EmailValidationWrapper
 * @group       Test Class
 * @revision    2022-08-31 - Sachin Shetty - Created
**/
@isTest(isParallel=true)
public class EmailValidationWrapper_Test {

    // Test for code coverage, no logic in the code, just fetching the confidence level, verbose output and their descriptions
    @isTest
    static void testConfidenceLevelVerboseOutputDescriptions() {
        // Given
        // When
        Map<String, Map<String, String>> confidenceLevelAndDescriptions = EmailValidationWrapper.verboseOutputDescriptionsByConfidence;
        
        // Then
        System.assertNotEquals(null, confidenceLevelAndDescriptions, 'Wrapper not returned');
        System.assert(confidenceLevelAndDescriptions.containsKey('verified'), 'Confidence value does not exist');
        System.assert(confidenceLevelAndDescriptions.get('verified').containsKey('verified'), 'Verbose output value does not exist');
        System.assertEquals('The mailbox exists, is reachable, and is not known to be illegitimate or disposable.',confidenceLevelAndDescriptions.get('verified').get('verified'), 'Incorrect Verbose output description');
    }

    @isTest
    static void testShowGenericErrorMessageDecision() {
        // Given
        // insert custom settings
        EDQ_Settings__c experianSettings = EDQ_Settings__c.getOrgDefaults();
        experianSettings.Email_Validation_Show_Generic_Error__c = true;
        insert experianSettings;

        // When
        Boolean result = EmailValidationWrapper.showGenericErrorMessage;

        // Then
        System.assertEquals(true, result, 'Incorrect validation message decision returned');
    }

    // Test for code coverage, no logic in the code, just fetching the wrapper
    @isTest
    static void testGetEmailWrapper() {
        // Given
        // When
        EmailValidationWrapper.EmailWrapper emailWrapper = new EmailValidationWrapper.EmailWrapper();
        
        // Then
        System.assertNotEquals(null, emailWrapper, 'Wrapper not returned');
    }

}