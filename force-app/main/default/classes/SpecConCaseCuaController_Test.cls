/**
 * @description Test class for the SpecConCaseCuaController class
 * @group       SpecCon
 * @revision    2025-02-06 - Initial version
 */
@IsTest(IsParallel=true)
public class SpecConCaseCuaController_Test {

    @TestSetup
    public static void setupTestData() {
        TriggerCommon.disableTrigger('Contact');
        TriggerCommon.disableTrigger('Case');
        TriggerCommon.disableTrigger('Case_Unit_Attempt__c');

        Contact con = new Contact(
            LastName = 'Person',
            Email = 'test.person@example.com',
            Person_ID_unique__c = 'S001'
        );
        insert con;

        Unit_Offering__c uo = new Unit_Offering__c(
            Name = 'Test Unit',
            UOO_ID__c = 'UO001',
            Unit_Code__c = 'TEST101',
            Unit_Version__c = '1.0'
        );
        insert uo;

        Course__c course = new Course__c(
            Course_Code__c = 'A0501_1',
            Type__c = 'Course-All'
        );
        insert course;

        Course_Attempt__c ca = new Course_Attempt__c(
            Contact__c = con.Id,
            Location__c = 'MALAYSIA',
            Course__c = course.Id
        );
        insert ca;

        Unit_Attempt__c ua = new Unit_Attempt__c(
            Student__c = con.Id,
            Course_Attempt__c = ca.Id,
            Unit_Offering__c = uo.Id,
            Location__c = 'MALAYSIA',
            Calendar_Type__c = 'S1-01',
            Unit_Code__c = 'ATS2143',
            CI_Sequence_Number__c = '9137'
        );
        insert ua;

        Case cse = new Case(
            ContactId = con.Id,
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Web - Monash Forms',
            Reason = 'Other',
            Type = 'Other'
        );
        insert cse;

        Case_Unit_Attempt__c testCua = new Case_Unit_Attempt__c(
            Enquiry__c = cse.Id,
            Unit_Attempt__c = ua.Id,
            Moodle_Assessment_ID__c = 'Q001',
            Assessment_Due_Date_New__c = Date.today().addDays(7)
        );
        insert testCua;

        TriggerCommon.enableTrigger('Contact');
        TriggerCommon.enableTrigger('Case');
        TriggerCommon.enableTrigger('Case_Unit_Attempt__c');
    }

    public static void setupMocks() {
        // Mock quiz attempts response
        String quizAttemptsResponse = '{"attempts": [' +
            '{"id": 1, "assessmentType": "quiz", "assessmentId": 123, "quizId": 1, ' +
            '"attempt": 1, "uniqueId": 1, "status": "finished", ' +
            '"timeStart": "2025-02-06T10:00:00Z", "timeFinish": "2025-02-06T11:00:00Z", ' +
            '"timeModified": "2025-02-06T11:00:00Z", "timeModifiedOffline": "2025-02-06T11:00:00Z", ' +
            '"sumGrades": 80, "gradedNotificationSentTime": "2025-02-06T11:01:00Z"}], ' +
            '"noOfAllowableUserOverriddenAttempts": 3, "warnings": []}';

        // Mock assessments response
        String assessmentsResponse = '[{' +
            '"id": "Q001", ' +
            '"unitOfferingId": "UO001", ' +
            '"unitCode": "TEST101", ' +
            '"type": "quiz", ' +
            '"name": "Test Quiz", ' +
            '"numberOfAllowedAttempts": 2' +
            '}]';

        // Set up the mock responses
        Test.setMock(HttpCalloutMock.class, new MockMoodleService(new Map<String, String>{
            'attempts' => quizAttemptsResponse,
            'assessments' => assessmentsResponse,
            'extension' => '{}'
        }));
    }

    @IsTest
    static void testGetQuizAttemptInfo() {
        // GIVEN - We have a CUA and mocked responses
        setupMocks();
        Case_Unit_Attempt__c testCua = [SELECT Id FROM Case_Unit_Attempt__c LIMIT 1];

        // WHEN - We get quiz attempt info
        Test.startTest();
        SpecConCaseCuaController.QuizAttemptInfo result =
            SpecConCaseCuaController.getQuizAttemptInfo(testCua.Id);
        Test.stopTest();

        // THEN - We should get the correct attempt information
        Assert.areEqual(1, result.attemptsTaken, 'Should have one attempt taken');
        Assert.areEqual(3, result.attemptsAllowedOverride, 'Should have three attempts allowed');
    }

    @IsTest
    static void testGetQuizAllowableAttempts() {
        // GIVEN - We have a CUA and mocked responses
        setupMocks();
        Case_Unit_Attempt__c testCua = [SELECT Id FROM Case_Unit_Attempt__c LIMIT 1];

        // WHEN - We get allowable attempts
        Test.startTest();
        Integer result = SpecConCaseCuaController.getQuizAllowableAttempts(testCua.Id);
        Test.stopTest();

        // THEN - We should get the correct number of allowed attempts
        Assert.areEqual(2, result, 'Should have two allowed attempts');
    }

    @IsTest
    static void testUpdateAttemptsAllowed() {
        // GIVEN - We have a CUA and mocked responses
        setupMocks();
        Case_Unit_Attempt__c testCua = [SELECT Id FROM Case_Unit_Attempt__c LIMIT 1];

        // WHEN - We update the allowed attempts
        Test.startTest();
        SpecConCaseCuaController.updateAttemptsAllowed(testCua.Id, 5);
        Test.stopTest();

        // THEN - The CUA should be updated with success status
        testCua = [SELECT Moodle_Integration_Status__c FROM Case_Unit_Attempt__c WHERE Id = :testCua.Id];
        Assert.areEqual(
            Label.Moodle_Integration_Status_Success,
            testCua.Moodle_Integration_Status__c,
            'Integration status should be success'
        );
    }

    @IsTest
    static void testErrorHandling() {
        // GIVEN - We have a CUA and error mock response
        Case_Unit_Attempt__c testCua = [SELECT Id FROM Case_Unit_Attempt__c LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockMoodleService(new Map<String, String>{
            'attempts' => '{"error": "Failed"}',
            'extension' => '{"error": "Failed"}'
        }, 400));

        // WHEN/THEN - Methods should throw appropriate exceptions
        Test.startTest();
        try {
            SpecConCaseCuaController.getQuizAttemptInfo(testCua.Id);
            Assert.fail('Should have thrown an exception');
        } catch(AuraHandledException e) {
            // Expected
        }

        try {
            SpecConCaseCuaController.updateAttemptsAllowed(testCua.Id, 5);
            Assert.fail('Should have thrown an exception');
        } catch(AuraHandledException e) {
            // Expected
        }
        Test.stopTest();
    }

    /**
     * Mock service that returns different responses based on the endpoint
     */
    public class MockMoodleService implements HttpCalloutMock {
        private Map<String, String> responses;
        private Integer statusCode;

        public MockMoodleService(Map<String, String> responses) {
            this(responses, 200);
        }

        public MockMoodleService(Map<String, String> responses, Integer StatusCode) {
            this.responses = responses;
            this.statusCode = StatusCode;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if(req.getEndpoint().contains('/attempts')) {
                res.setBody(responses.get('attempts'));
            } else if(req.getEndpoint().contains('/assessments')) {
                res.setBody(responses.get('assessments'));
            } else if(req.getEndpoint().contains('/extensions')) {
                res.setBody(responses.get('extension'));
            }

            res.setStatusCode(statusCode);
            return res;
        }
    }
}