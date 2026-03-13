/**
 * @description Test class for the SpecConFlowSetAttempts class
 * @group       SpecCon
 * @author      tom.gangemi@monash.edu
 * @revision    2025-02-10 - Initial version
 */
@IsTest
public class SpecConFlowSetAttempts_Test {

    @TestSetup
    static void setup() {
        SpecConCaseCuaController_Test.setupTestData();
    }

    @IsTest
    static void testSetQuizExtensionSuccess() {
        // GIVEN - Setup test data and mock responses
        SpecConCaseCuaController_Test.setupMocks();
        Case_Unit_Attempt__c testCua = [SELECT Id FROM Case_Unit_Attempt__c LIMIT 1];
        SpecConFlowSetAttempts.QuizAttemptInfo qai = new SpecConFlowSetAttempts.QuizAttemptInfo();
        qai.cuaId = testCua.Id;
        qai.numberOfAttemptsAllowable = 5;

        // WHEN - Call setQuizExtension
        Test.startTest();
        List<String> results = SpecConFlowSetAttempts.setQuizExtension(new List<SpecConFlowSetAttempts.QuizAttemptInfo>{qai});
        Test.stopTest();

        // THEN - Verify success
        Assert.areEqual(1, results.size(), 'Should return one result');
        Assert.isNull(results[0], 'Result should be null for success');
        Case_Unit_Attempt__c updatedCua = [SELECT Moodle_Integration_Status__c FROM Case_Unit_Attempt__c WHERE Id = :testCua.Id];
        Assert.areEqual(Label.Moodle_Integration_Status_Success, updatedCua.Moodle_Integration_Status__c, 'Status should be success');
    }

    @IsTest
    static void testSetQuizExtensionError() {
        // GIVEN - Setup error mock
        Case_Unit_Attempt__c testCua = [SELECT Id FROM Case_Unit_Attempt__c LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new SpecConCaseCuaController_Test.MockMoodleService(new Map<String, String>{
            'attempts' => '{"error": "Failed"}',
            'extension' => '{"error": "Failed"}'
        }, 400));

        SpecConFlowSetAttempts.QuizAttemptInfo qai = new SpecConFlowSetAttempts.QuizAttemptInfo();
        qai.cuaId = testCua.Id;
        qai.numberOfAttemptsAllowable = 5;

        // WHEN - Call setQuizExtension
        Test.startTest();
        List<String> results = SpecConFlowSetAttempts.setQuizExtension(new List<SpecConFlowSetAttempts.QuizAttemptInfo>{qai});
        Test.stopTest();

        // THEN - Verify error message
        Assert.areEqual(1, results.size(), 'Should return one result');
        Assert.areEqual('Failed to update moodle', results[0], 'Should return error message');
    }
}