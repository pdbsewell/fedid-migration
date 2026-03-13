/**
 * @description Test class for SpecConFlowGetAttempts
 * @group       SpecCon
 * @author      tom.gangemi@monash.edu
 * @revision    2025-02-10 - Initial version
 */
@IsTest
public class SpecConFlowGetAttempts_Test {

    @TestSetup
    static void setup() {
        SpecConCaseCuaController_Test.setupTestData();
    }

    @IsTest
    static void testGetQuizAttemptInfoSuccess() {
        // GIVEN - Setup test data and mock responses
        SpecConCaseCuaController_Test.setupMocks();
        Case_Unit_Attempt__c testCua = [SELECT Id, Assessment_Attempts_Taken__c, Assessment_Attempts_Allowable__c FROM Case_Unit_Attempt__c LIMIT 1];
        Id cuaId = testCua.Id;

        // WHEN - Call getQuizAttemptInfo
        Test.startTest();
        List<SpecConFlowGetAttempts.QuizAttemptInfo> results = SpecConFlowGetAttempts.getQuizAttemptInfo(new List<Id>{cuaId});
        Test.stopTest();

        // THEN - Verify data from mock
        Assert.areEqual(1, results.size(), 'Should return one result');
        SpecConFlowGetAttempts.QuizAttemptInfo qai = results[0];
        Assert.areEqual(1, qai.attemptsTaken, 'Attempts taken should be 1');
        Assert.areEqual(3, qai.attemptsAllowed, 'Attempts allowed should be overridden to 3');
        Assert.isFalse(qai.moodleUnreachable, 'Moodle should be reachable');
    }

    @IsTest
    static void testGetQuizAttemptInfoMoodleUnreachable() {
        // GIVEN - Setup error mock
        Case_Unit_Attempt__c testCua = [SELECT Id, Assessment_Attempts_Taken__c, Assessment_Attempts_Allowable__c FROM Case_Unit_Attempt__c LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new SpecConCaseCuaController_Test.MockMoodleService(new Map<String, String>{
            'attempts' => '{"error": "Failed"}',
            'extension' => '{"error": "Failed"}'
        }, 400));
        Id cuaId = testCua.Id;

        // WHEN - Call getQuizAttemptInfo
        Test.startTest();
        List<SpecConFlowGetAttempts.QuizAttemptInfo> results = SpecConFlowGetAttempts.getQuizAttemptInfo(new List<Id>{cuaId});
        Test.stopTest();

        // THEN - Verify fallback to CUA fields
        Assert.areEqual(1, results.size(), 'Should return one result');
        SpecConFlowGetAttempts.QuizAttemptInfo qai = results[0];
        Assert.isTrue(qai.moodleUnreachable, 'Moodle should be unreachable');
        Assert.areEqual(Integer.valueOf(testCua.Assessment_Attempts_Taken__c), qai.attemptsTaken, 'Attempts taken should come from CUA');
        Assert.areEqual(Integer.valueOf(testCua.Assessment_Attempts_Allowable__c), qai.attemptsAllowed, 'Attempts allowed should come from CUA');
    }
}