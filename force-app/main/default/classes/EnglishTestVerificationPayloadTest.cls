/**
 * @author      APRivera
 * @description Test class for EnglishTestVerificationPayload
 * @group       Admissions - English Test
 * @revision   15/12/2024 - APRivera - Created
 */

@IsTest(IsParallel=true)
private class EnglishTestVerificationPayloadTest {
    private static final String VALID_JSON_RESPONSE = '{"provider":"IELTS","testType":"Academic","testDate":"2024-01-01","testNumber":"123456","lastName":"Doe","firstName":"John","dateOfBirth":"1990-05-20","listeningScore":8.5,"readingScore":7.5,"speakingScore":8.0,"writingScore":6.5,"overallScore":8.0,"validationResult":"Valid","photoBase64":"base64photo","photoMediaType":"image/jpeg","pdfBase64":"base64pdf"}';

    private static final String INVALID_JSON_RESPONSE = '{"provider":"IELTS","testType":"Academic","testDate":"2024-01-01","testNumber":"123456","lastName":"Doe","firstName":"John","dateOfBirth":"1990-05-20","listeningScore":8.5,"readingScore":7.5,"speakingScore":8.0,"writingScore":6.5,"overallScore":8.0,"validationResult":null}';

    private static final String EMPTY_JSON_RESPONSE = '{}';

    /**
     * Test object creation with valid payload data and assertions for all fields.
     */
    @IsTest
    static void testEnglishTestVerificationPayload_ValidData() {
        // Create a payload object and populate fields
        EnglishTestVerificationPayload payload = new EnglishTestVerificationPayload();
        payload.provider = 'IELTS';
        payload.testType = 'Academic';
        payload.testDate = Date.newInstance(2024, 1, 1);
        payload.testNumber = '123456';
        payload.lastName = 'Doe';
        payload.firstName = 'John';
        payload.dateOfBirth = Date.newInstance(1990, 5, 20);
        payload.listeningScore = 8.5;
        payload.readingScore = 7.5;
        payload.speakingScore = 8.0;
        payload.writingScore = 6.5;
        payload.overallScore = 8.0;
        payload.photoBase64 = 'base64photo';
        payload.photoMediaType = 'image/jpeg';
        payload.pdfBase64 = 'base64pdf';

        // Assert all fields are set correctly
        Assert.areEqual('IELTS', payload.provider);
        Assert.areEqual('Academic', payload.testType);
        Assert.areEqual(Date.newInstance(2024, 1, 1), payload.testDate);
        Assert.areEqual('123456', payload.testNumber);
        Assert.areEqual('Doe', payload.lastName);
        Assert.areEqual('John', payload.firstName);
        Assert.areEqual(Date.newInstance(1990, 5, 20), payload.dateOfBirth);
        Assert.areEqual(8.5, payload.listeningScore);
        Assert.areEqual(7.5, payload.readingScore);
        Assert.areEqual(8.0, payload.speakingScore);
        Assert.areEqual(6.5, payload.writingScore);
        Assert.areEqual(8.0, payload.overallScore);
        Assert.areEqual('base64photo', payload.photoBase64);
        Assert.areEqual('image/jpeg', payload.photoMediaType);
        Assert.areEqual('base64pdf', payload.pdfBase64);
    }

    /**
     * Test deserialization of a complete and valid JSON response.
     */
    @IsTest
    static void testDeserializationOfValidJson() {
        EnglishTestVerificationPayload payload = (EnglishTestVerificationPayload) JSON.deserialize(VALID_JSON_RESPONSE, EnglishTestVerificationPayload.class);

        // Assert all deserialized fields are as expected
        Assert.areEqual('IELTS', payload.provider);
        Assert.areEqual('Academic', payload.testType);
        Assert.areEqual(Date.newInstance(2024, 1, 1), payload.testDate);
        Assert.areEqual('123456', payload.testNumber);
        Assert.areEqual('Doe', payload.lastName);
        Assert.areEqual('John', payload.firstName);
        Assert.areEqual(Date.newInstance(1990, 5, 20), payload.dateOfBirth);
        Assert.areEqual(8.5, payload.listeningScore);
        Assert.areEqual(7.5, payload.readingScore);
        Assert.areEqual(8.0, payload.speakingScore);
        Assert.areEqual(6.5, payload.writingScore);
        Assert.areEqual(8.0, payload.overallScore);
    }


    /**
     * Test deserialization of an empty JSON payload.
     */
    @IsTest
    static void testDeserializationOfEmptyJson() {
        EnglishTestVerificationPayload payload = (EnglishTestVerificationPayload) JSON.deserialize(EMPTY_JSON_RESPONSE, EnglishTestVerificationPayload.class);

        // Assert all fields are null or set to their default values
        Assert.areEqual(null, payload.provider);
        Assert.areEqual(null, payload.testType);
        Assert.areEqual(null, payload.testDate);
        Assert.areEqual(null, payload.testNumber);
        Assert.areEqual(null, payload.lastName);
        Assert.areEqual(null, payload.firstName);
        Assert.areEqual(null, payload.dateOfBirth);
        Assert.areEqual(null, payload.photoBase64);
        Assert.areEqual(null, payload.photoMediaType);
        Assert.areEqual(null, payload.pdfBase64);
    }


    /**
     * Test creation and field population of TestReportFormWrapper.
     */
    @IsTest
    static void testTestReportFormWrapper() {
        // Default constructor
        EnglishTestVerificationPayload.TestReportFormWrapper wrapperDefault = new EnglishTestVerificationPayload.TestReportFormWrapper();

        // Assert all fields are null/default
        Assert.areEqual(null, wrapperDefault.TestReportNumber);
        Assert.areEqual(null, wrapperDefault.DOB);

        // Test parameterized constructor
        EnglishTestVerificationPayload.TestReportFormWrapper wrapper = new EnglishTestVerificationPayload.TestReportFormWrapper(
                'IELTS','Academic', 'TRN-001', Date.newInstance(1990, 12, 25), 'John', 'Doe', 'Johnny', 'Doeson', Date.newInstance(2024, 6, 1), true, Date.newInstance(2024, 1, 1), Date.newInstance(2024, 12, 31)
        );

        // Assert all fields populated correctly
        Assert.areEqual('IELTS', wrapper.Provider);
        Assert.areEqual('Academic', wrapper.TestType);
        Assert.areEqual('TRN-001', wrapper.TestReportNumber);
        Assert.areEqual(Date.newInstance(1990, 12, 25), wrapper.DOB);
        Assert.areEqual('John', wrapper.FirstName);
        Assert.areEqual('Doe', wrapper.LastName);
        Assert.areEqual('Johnny', wrapper.PreviousFirstName);
        Assert.areEqual('Doeson', wrapper.PreviousLastName);
        Assert.areEqual(Date.newInstance(2024, 6, 1), wrapper.DateCompleted);
        Assert.areEqual(true, wrapper.PhotoFlag);
        Assert.areEqual(Date.newInstance(2024, 1, 1), wrapper.StartDate);
        Assert.areEqual(Date.newInstance(2024, 12, 31), wrapper.EndDate);
    }

    /**
     * Test to ensure constructor does not throw any exceptions.
     */
    @IsTest
    static void testPayloadDefaultConstructor() {
        EnglishTestVerificationPayload payload = new EnglishTestVerificationPayload();
        Assert.areNotEqual(null, payload); // Ensure object is created successfully
    }
}