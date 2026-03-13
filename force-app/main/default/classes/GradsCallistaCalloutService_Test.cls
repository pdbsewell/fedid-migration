/**
 * @description     Test class for the GradsCallistaCalloutService class
 * @group           Grads
 * @revision        2024-09-23 - Tom Gangemi - Initial version
 */
@IsTest(IsParallel=true)
public class GradsCallistaCalloutService_Test {

    @IsTest
    static void testSubmitApplication() {
        // GIVEN - We have a new application (no transaction number)
        GradsCallistaCalloutService.AppReqBody body = new GradsCallistaCalloutService.AppReqBody();
        body.graduationApplication = new GradsCallistaCalloutService.AppReqGraduationApplication();

        String studentId = 'S001';
        String awardId = fflib_IDGenerator.generate(Graduation_Award__c.SObjectType);

        // Set up the mock callout
        setMockSuccessApp('12345');

        // WHEN - We submit the application
        GradsCallistaCalloutService.ApplicationCalloutResult result = GradsCallistaCalloutService.submitApplication(
            body, studentId, awardId
        );

        // THEN - The application should be submitted successfully
        Assert.isTrue(result.success, 'Callout should be successful');
        Assert.areEqual('12345', result.transactionNo, 'Transaction number should match');
        Assert.areEqual('POST', result.request.getMethod(), 'HTTP method should be POST for create');
    }

    @IsTest
    static void testSubmitDocument() {
        // GIVEN - We have a document to submit
        String studentId = 'S001';
        String applicationId = 'A001';
        String docId = 'D001';
        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            VersionData = Blob.valueOf('Test content'),
            PathOnClient = 'test.txt'
        );

        // Set up the mock callout
        setMockSuccess('{"document": {"id": "D001"}}');

        // WHEN - We submit the document
        GradsCallistaCalloutService.DocumentCalloutResult result = GradsCallistaCalloutService.submitDocument(studentId, applicationId, docId, cv);

        // THEN - The document should be submitted successfully
        Assert.isTrue(result.success, 'Document submission should be successful');
        Assert.areEqual('D001', result.documentId, 'Document ID should match');
    }

    @IsTest
    static void testGetEligibility() {
        // GIVEN - We have a student with one course attempt
        String studentId = 'S001';
        String mockResponseBody = '{"graduationEligibilityDetails": {"courseAttempts": [{"courseCode": "CS101", "courseVersionNumber": 1, "courseTitle": "Intro to CS"}]}}';

        // Set up the mock callout
        setMockSuccess(mockResponseBody);

        // WHEN - We check the student's eligibility
        GradsCallistaCalloutService.EligibilityCalloutResult result = GradsCallistaCalloutService.getEligibility(studentId);

        // THEN - The eligibility check should be successful
        Assert.isTrue(result.success, 'Eligibility check should be successful');
        Assert.isNotNull(result.eligibilityDetails, 'Eligibility details should not be null');
        Assert.areEqual(1, result.eligibilityDetails.courseAttempts.size(), 'Should have one course attempt');
        Assert.areEqual('CS101', result.eligibilityDetails.courseAttempts[0].courseCode, 'Course code should match');
    }

    @IsTest
    static void testErrorScenarios() {
        // GIVEN - We have a http callout that fails
        setMockFailure('Internal Server Error');

        // WHEN - We make a callout
        GradsCallistaCalloutService.EligibilityCalloutResult result = GradsCallistaCalloutService.getEligibility('S001');

        // THEN - The callout should fail with the correct error message
        Assert.isFalse(result.success, 'Callout should fail');
        Assert.areEqual('Internal Server Error', result.errorMessage, 'Error message should match');

        // GIVEN - We have a successful callout with invalid JSON
        setMockSuccess('<html>Invalid JSON</html>');

        // WHEN - We make a callout
        result = GradsCallistaCalloutService.getEligibility('S001');

        // THEN - The callout should fail with a JSON exception
        Assert.isFalse(result.success, 'Callout should fail');
        Assert.areEqual(result.ex.getTypeName(), 'System.JSONException', 'Exception type should be JSON');
    }

    public static void setMockSuccessApp(String transactionNo) {
        setMockSuccess('{"transactionNo": "'+transactionNo+'"}');
    }
    public static void setMockSuccess(String body) {
        Test.setMock(HttpCalloutMock.class, new MockCallistaResp(200, body));
    }
    public static void setMockFailure(String errorMessage) {
        Test.setMock(HttpCalloutMock.class, new MockCallistaResp(500, '{"description": "'+errorMessage+'"}'));
    }

    /**
     * Mock HTTP callout responses. Can enqueue multiple responses and will cycle through them.
     */
    public class MockCallistaResp implements HttpCalloutMock {
        private final List<HttpResponse> responses;
        private Integer currentIndex;
        public Integer callCount;

        public MockCallistaResp() {
            responses = new List<HttpResponse>();
            currentIndex = 0;
            callCount = 0;
        }

        public MockCallistaResp(Integer statusCode, String body) {
            this();
            addResponse(statusCode, body);
        }

        public MockCallistaResp addResponse(Integer statusCode, String body) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            responses.add(res);
            return this;
        }

        public HttpResponse respond(HttpRequest req) {
            // get next response from list, if index out of bounds, wrap around to start
            HttpResponse res = responses[currentIndex];
            res.setHeader('Content-Type', 'application/json');
            currentIndex = currentIndex + 1 >= responses.size() ? 0 : currentIndex + 1;
            callCount++;
            return res;
        }

        public void reset() {
            currentIndex = 0;
        }
    }
}