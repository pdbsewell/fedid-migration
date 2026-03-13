/**
 * @author      Sachin Shetty
 * @description Test Class for EmailValidationController
 * @group       Test Class
 * @revision    2022-10-17 - Sachin Shetty - Update to uniquely identify each guest user
 *              2022-10-04 - Sachin Shetty - Rate limiting changes
 *              2022-08-26 - Sachin Shetty - Created
**/
@isTest(isParallel=true)
public class EmailValidationController_Test {

    @isTest
    static void testValidateEmailaddressSuccess() {
        // Given
        Test.setMock(HttpCalloutMock.class, new EDQEmailService_Test.EDQEmailServiceValidationSuccessResMock());

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
            EDQEmailDAO.EmailResponse response = EmailValidationController.validate('test@gmail.com', RECORD_NAME, key);
        Test.stopTest();

        // Then
        System.assertNotEquals(null, response?.result, 'Response did not have a result');
        System.assertEquals('test@gmail.com', response?.result?.email, 'Validated email did not match');
        System.assertEquals('verified', response?.result?.confidence, 'Incorrect confidence value returned');
    }

    @isTest
    static void testValidateEmailaddressBlankEmail() {
        // Given
        String key = 'testkey';

        // When
        EDQEmailDAO.EmailResponse response = EmailValidationController.validate('', 'test', key);

        // Then
        System.assertEquals(null, response, 'Response should be null for blank email');
    }

    // Test for code coverage, no logic in the code, just fetching the wrapper
    @isTest
    static void testGetEmailWrapper() {
        // Given
        // When
        EmailValidationWrapper.EmailWrapper emailWrapper = EmailValidationController.getEmailWrapper();
        
        // Then
        System.assertNotEquals(null, emailWrapper, 'Wrapper not returned');
    }

    // Test for code coverage, no logic in the code, just fetching the confidence level, verbose output and their descriptions
    @isTest
    static void testConfidenceLevelVerboseOutputDescriptions() {
        // Given
        // When
        Map<String, Map<String, String>> confidenceLevelAndDescriptions = EmailValidationController.getVerboseOutputDescriptionsByConfidence();
        
        // Then
        System.assertNotEquals(null, confidenceLevelAndDescriptions, 'Wrapper not returned');
        System.assert(confidenceLevelAndDescriptions.containsKey('verified'), 'Confidence value does not exist');
        System.assert(confidenceLevelAndDescriptions.get('verified').containsKey('verified'), 'Verbose output value does not exist');
        System.assertEquals('The mailbox exists, is reachable, and is not known to be illegitimate or disposable.',confidenceLevelAndDescriptions.get('verified').get('verified'), 'Incorrect Verbose output description returned');
    }

    @isTest
    static void testShowGenericErrorMessageDecision() {
        // Given
        // insert custom settings
        EDQ_Settings__c experianSettings = EDQ_Settings__c.getOrgDefaults();
        experianSettings.Email_Validation_Show_Generic_Error__c = true;
        insert experianSettings;

        // When
        Boolean result = EmailValidationController.getShowGenericErrorMessageDecision();

        // Then
        System.assertEquals(true, result, 'Incorrect validation message decision returned');
    }

    @isTest
    static void testValidateEmailRateLimitBlock() {
        // Given
        Test.setMock(HttpCalloutMock.class, new EDQEmailService_Test.EDQEmailServiceValidationSuccessResMock());

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
            EDQEmailDAO.EmailResponse response1 = EmailValidationController.validate('test1@gmail.com', RECORD_NAME, key);
            EDQEmailDAO.EmailResponse response2 = EmailValidationController.validate('test1@gmail.com', RECORD_NAME, key);
        Test.stopTest();
        
        // Then
        System.assertEquals(null, response2, 'Expected Experian email validation to be blocked by rate limit');
    }
    
    @isTest
    static void testCatchException() {
        // Given
        EDQEmailDAO.EmailResponse resp;
        // When
        Test.startTest();
        resp = EmailValidationController.createErrorResp(new LogUtilityException('Fake Error'));
        Test.stopTest();
        // Then
        System.assertNotEquals(null, resp, 'Error Creating Catch Response');
        
    }

}