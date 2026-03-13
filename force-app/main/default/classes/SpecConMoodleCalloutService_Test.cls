/**
 * @description Test class for the SpecConMoodleCalloutService class
 * @group       SpecCon
 * @revision    2025-02-06 - Initial version
 */
@IsTest(IsParallel=true)
public class SpecConMoodleCalloutService_Test {

    @IsTest
    static void testGetQuizAttempts() {
        // GIVEN - We have a student and quiz ID
        String studentId = 'S001';
        String quizId = 'Q001';
        // Mock response should match QuizAttemptsWrapper structure exactly
        String mockResponseBody = '{"attempts": [{"id": 1, "assessmentType": "quiz", "assessmentId": 123, "quizId": 1, "attempt": 1, "uniqueId": 1, "status": "finished", "timeStart": "2025-02-06T10:00:00Z", "timeFinish": "2025-02-06T11:00:00Z", "timeModified": "2025-02-06T11:00:00Z", "timeModifiedOffline": "2025-02-06T11:00:00Z", "sumGrades": 80, "gradedNotificationSentTime": "2025-02-06T11:01:00Z"}], "noOfAllowableUserOverriddenAttempts": 3, "warnings": []}';

        // Set up the mock callout
        setMockSuccess(mockResponseBody);

        // WHEN - We get the quiz attempts
        SpecConMoodleCalloutService.QuizAttemptsResult result =
            SpecConMoodleCalloutService.getQuizAttempts(studentId, quizId);

        // THEN - The quiz attempts should be retrieved successfully
        Assert.isTrue(result.success, 'Quiz attempts retrieval should be successful');
        Assert.isNotNull(result.quizAttempts, 'Quiz attempts should not be null');
        Assert.areEqual(1, result.quizAttempts.attempts.size(), 'Should have one attempt');
        Assert.areEqual(3, result.quizAttempts.noOfAllowableUserOverriddenAttempts, 'Should have correct number of allowable attempts');
        Assert.areEqual(80, result.quizAttempts.attempts[0].sumGrades, 'Grade should match');
    }

    @IsTest
    static void testGetAssessments() {
        // GIVEN - We have a student and unit offering ID
        String studentId = 'S001';
        String unitOfferingId = 'UO001';
        String mockResponseBody = '[{"id": "A001", "unitOfferingId": "UO001", "unitCode": "TEST101", "type": "quiz", "name": "Test Quiz", "weight": "40"}]';

        // Set up the mock callout
        setMockSuccess(mockResponseBody);

        // WHEN - We get the assessments
        SpecConMoodleCalloutService.AssessmentsResults result =
            SpecConMoodleCalloutService.getAssessments(studentId, unitOfferingId);

        // THEN - The assessments should be retrieved successfully
        Assert.isTrue(result.success, 'Assessments retrieval should be successful');
        Assert.isNotNull(result.assessments, 'Assessments should not be null');
        Assert.areEqual(1, result.assessments.size(), 'Should have one assessment');
        Assert.areEqual('TEST101', result.assessments[0].unitCode, 'Unit code should match');
        Assert.areEqual('40', result.assessments[0].weight, 'Weight should match');
    }

    @IsTest
    static void testPostQuizExtension() {
        // GIVEN - We have a quiz extension request
        String studentId = 'S001';
        String quizId = 'Q001';
        Integer numAttempts = 5;
        Date closingDate = Date.today().addDays(7);
        String location = 'MALAYSIA';

        // Set up the mock callout
        setMockSuccess('{}');

        // WHEN - We post the quiz extension
        SpecConMoodleCalloutService.QuizExtensionResult result =
            SpecConMoodleCalloutService.postQuizExtension(studentId, quizId, numAttempts, closingDate, location);

        // THEN - The extension should be posted successfully
        Assert.isTrue(result.success, 'Quiz extension should be successful');
        Assert.isTrue(result.request.getBody().contains('"noOfAllowableAttempts":5'), 'Request should include number of attempts');
    }

    @IsTest
    static void testCreateNewLocalDueDatetime() {
        // GIVEN - We have different locations
        Date testDate = Date.newInstance(2025, 2, 6);

        // WHEN/THEN - Test different locations
        Datetime melb = SpecConMoodleCalloutService.createNewLocalDueDatetime(testDate, 'MELBOURNE');
        Datetime malaysia = SpecConMoodleCalloutService.createNewLocalDueDatetime(testDate, 'MALAYSIA');
        Datetime indonesia = SpecConMoodleCalloutService.createNewLocalDueDatetime(testDate, 'INDONESIA');
        Datetime prato = SpecConMoodleCalloutService.createNewLocalDueDatetime(testDate, 'PRATO');

        // All locations should return different times due to timezone differences
        Assert.areNotEqual(melb, malaysia, 'Melbourne and Malaysia times should differ');
        Assert.areNotEqual(melb, indonesia, 'Melbourne and Indonesia times should differ');
        Assert.areNotEqual(melb, prato, 'Melbourne and Prato times should differ');
    }

    @IsTest
    static void testErrorScenarios() {
        // GIVEN - We have a http callout that fails
        setMockFailure('Internal Server Error');

        // WHEN - We make a callout
        SpecConMoodleCalloutService.QuizAttemptsResult result =
            SpecConMoodleCalloutService.getQuizAttempts('S001', 'Q001');

        // THEN - The callout should fail with the correct error message
        Assert.isFalse(result.success, 'Callout should fail');
        Assert.areEqual('Internal Server Error', result.errorMessage, 'Error message should match');

        // GIVEN - We have a successful callout with invalid JSON
        setMockSuccess('<html>Invalid JSON</html>');

        // WHEN - We make a callout
        result = SpecConMoodleCalloutService.getQuizAttempts('S001', 'Q001');

        // THEN - The callout should fail with a JSON exception
        Assert.isFalse(result.success, 'Callout should fail');
        Assert.areEqual(result.ex.getTypeName(), 'System.JSONException', 'Exception type should be JSON');
    }

    private static void setMockSuccess(String body) {
        Test.setMock(HttpCalloutMock.class, new MockMoodleResp(200, body));
    }

    private static void setMockFailure(String errorMessage) {
        Test.setMock(HttpCalloutMock.class, new MockMoodleResp(500, '{"description": "'+errorMessage+'"}'));
    }

    /**
     * Mock HTTP callout responses
     */
    private class MockMoodleResp implements HttpCalloutMock {
        private final Integer statusCode;
        private final String body;

        public MockMoodleResp(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }
}