/**
 * @author
 * @description Test class for EnglishTestApiService
 * @group       Admissions - English Test
 * @revision    15/12/2024 - APRivera - Created
 * @revision   10/04/2025 - APRivera - Added the usage on Provider attribute
 */

@IsTest(IsParallel=true)
public class EnglishTestApiServiceTest {

    /**
     * Test the `makeGetCall` method for a success (200 response) with ResponseWrapper included.
     */
    @IsTest
    static void testMakeGetCall_SuccessWithResponseWrapper() {
        // Set the mock implementation
        Test.setMock(HttpCalloutMock.class, new EnglishTestApiMock());

        // Prepare the test input using the TestReportFormWrapper
        EnglishTestVerificationPayload.TestReportFormWrapper testReportForm = new EnglishTestVerificationPayload.TestReportFormWrapper(
                'IELTS',
                'IELTS Online (Academic)',
                '123456',
                Date.newInstance(1990, 1, 1),
                'John',
                'Doe',
                null,
                null,
                Date.newInstance(2024, 6, 1),
                true,
                Date.newInstance(2024, 1, 1),
                Date.newInstance(2024, 12, 31)
        );


        // Call the service method
        EnglishTestVerificationPayload payload = EnglishTestApiService.makeGetCall(testReportForm);

        // Get the appropriate validator
        EnglishTestProviderValidation validator = EnglishTestProviderValidationFactory.getValidator(EnglishTestProviderType.IELTS);

        EnglishTestVerificationPayload response = validator.validate(payload,testReportForm);

        // Validate the payload fields
        Assert.areNotEqual(response, null, 'ResponseWrapper should not be null.');
        Assert.areNotEqual(payload, null, 'Payload should not be null.');
        Assert.areNotEqual(EnglishTestProviderType.PEARSON, null, 'Provide should not be null.');
        Assert.areNotEqual(EnglishTestProviderType.TOEFL, null, 'Provide should not be null.');
        Assert.areNotEqual(payload, null, 'ResponseWrapper should not be null.');
        Assert.isTrue(payload.message != null, 'ResponseWrapper message should not be null.');


    }

    /**
     * Test the `makeGetCall` method for failure (e.g., 400 response) with appropriate ResponseWrapper.
     */
    @IsTest
    static void testMakeGetCall_FailureWithResponseWrapper() {
        // Set the mock implementation to simulate a 400 error
        Test.setMock(HttpCalloutMock.class, new EnglishTestApiMock.Failure());

        // Prepare the input using the TestReportFormWrapper
        EnglishTestVerificationPayload.TestReportFormWrapper testReportForm = new EnglishTestVerificationPayload.TestReportFormWrapper(
                'IELTS',
                'IELTS Online (Academic)',
                'InvalidTestNumber',
                Date.newInstance(1990, 1, 1),
                'Invalid',
                'User',
                null,
                null,
                Date.newInstance(2024, 6, 1),
                false,
                Date.newInstance(2024, 5, 1),
                Date.newInstance(2024, 12, 1)
        );


        // Execute the service method and expect a generated ResponseWrapper
        EnglishTestVerificationPayload payload = EnglishTestApiService.makeGetCall(testReportForm);

        // Validate the ResponseWrapper fields
        Assert.areNotEqual(payload, null, 'Payload should not be null.');
        Assert.areNotEqual(payload, null, 'ResponseWrapper should not be null.');
        Assert.areEqual(false, payload.success, 'ResponseWrapper status should indicate error.');
    }

    /**
     * Test the `generateResponse` method directly to validate ResponseWrapper population.
     */
    @IsTest
    static void testGenerateResponse() {
        // Call the method to generate a response with ResponseWrapper
        EnglishTestVerificationPayload newPayload = new EnglishTestVerificationPayload();
        EnglishTestVerificationPayload payload = EnglishTestApiService.generateResponse(newPayload,'error', 'Error occurred during processing.', true);

        // Verify the returned payload
        Assert.areNotEqual(payload, null, 'Payload should not be null.');
        Assert.areNotEqual(payload, null, 'ResponseWrapper should not be null.');
        Assert.areEqual(false, payload.success, 'ResponseWrapper status should be set correctly.');
        Assert.areEqual('Error occurred during processing.', payload.message, 'ResponseWrapper message should match the input.');
    }

    /**
     * Test the `makeGetCall` method for invalid JSON response with appropriate exception scenario.
     */
    @IsTest
    static void testMakeGetCall_InvalidJSONWithResponseWrapper() {
        // Set the custom mock to simulate an invalid JSON response
        Test.setMock(HttpCalloutMock.class, new EnglishTestApiMock.InvalidResponse());

        // Prepare the test input
        EnglishTestVerificationPayload.TestReportFormWrapper testReportForm = new EnglishTestVerificationPayload.TestReportFormWrapper(
                'InvalidType',
                'InvalidType',
                'InvalidJSON',
                Date.newInstance(2000, 1, 1),
                'Invalid',
                'Data',
                null,
                null,
                Date.newInstance(2024, 6, 1),
                true,
                Date.newInstance(2022, 1, 1),
                Date.newInstance(2022, 12, 1)
        );


        // Execute the method and validate the generated ResponseWrapper
        EnglishTestVerificationPayload payload = EnglishTestApiService.makeGetCall(testReportForm);

        // Validate the ResponseWrapper
        Assert.areNotEqual(payload, null, 'Payload should not be null.');
        Assert.areNotEqual(payload, null, 'ResponseWrapper should not be null.');
        Assert.areEqual(false, payload.success, 'ResponseWrapper status should indicate error.');
        Assert.isTrue(payload.message.contains('Failed to parse English Test API response'), 'ResponseWrapper message should indicate JSON parsing error.');
    }

    @IsTest
    static void testHandleValidation_SuccessCase() {
        // Step 1: Prepare a valid JSON payload for TestReportFormWrapper
        String strJson = '{"Provider":"IELTS","TestType":"IELTS Online (Academic)","TestReportNumber":"123","DOB":"1995-01-01","PreviousFirstName":"John","PreviousLastName":"Wicked","FirstName":"John","LastName":"Doe","DateCompleted":"2024-06-01","PhotoFlag":false,"StartDate":"2024-06-01","EndDate":"2024-06-01"}';

        // Step 2: Mock the dependencies
        // Step 2.1: Mock the API call response
        HttpCalloutMock mockAPIResponse = new EnglishTestApiMock();
        Test.setMock(HttpCalloutMock.class, mockAPIResponse);

        //Create test contact record - applicant record
        Contact contactRecord = new Contact();
        contactRecord.FirstName = 'First';
        contactRecord.LastName = 'Last';
        contactRecord.Residency_Status__c = 'INT-TEP';
        contactRecord.MailingCountry = 'AUSTRALIA';
        insert contactRecord;

        //Create test application data
        Application__c testApplication = new Application__c();
        testApplication.Applicant__c = contactRecord.Id;
        testApplication.Passport_Number__c = 'A1234567';
        testApplication.Campus_Location__c = null;
        testApplication.Visa_Type__c = null;
        testApplication.Australian_Immigration_Office_Issued__c = null;
        testApplication.Visa_Number__c = null;
        testApplication.Passport_Number__c = null;
        testApplication.Visa_Start_Date__c = null;
        testApplication.Visa_End_Date__c = null;
        testApplication.Refused_entry_visa_to_any_country__c = null;
        testApplication.Breached_visa_condition__c = null;
        testApplication.Medical_health_prevent_visa__c = null;
        testApplication.Protection_visa_in_any_country__c = null;
        testApplication.Convicted_of_crime_offence__c = null;
        insert testApplication;

        // Step 3: Prepare input parameters
        Id contactId = contactRecord.Id; // Valid Contact ID format
        Id applicationId = testApplication.Id; // Valid Application ID format

        Id recId = Schema.SObjectType.Qualification__c.getRecordTypeInfosByDeveloperName().get('Admission_Test').getRecordTypeId();
        Qualification__c qual = new Qualification__c(Qualification_Name__c='IELTS', Available_on_Portal__c= true,Callista_Code__c = 'IELTS01', RecordTypeId = recId);
        insert qual;

        String qualification = qual.Id;
        Boolean isCompleted = true;
        String provider = 'IELTS';
        String englishRequirement = 'I have completed a Monash approved English test';

        // Step 4: Call the method under test
        Test.startTest();
        EnglishTestVerificationPayload response = EnglishTestApiService.handleValidation(strJson, contactId, applicationId, qualification, isCompleted, provider, englishRequirement);
        Test.stopTest();

        // Step 5: Validate the results
        // Assert the response object is not null
        Assert.areNotEqual(response, null, 'Returned response should not be null.');

        // Step 6: Validate specific attributes in the response (mocked data)
        Assert.areEqual('IELTS', response.provider, 'The test type provider should be set to IELTS.');
        Assert.areNotEqual(response.testNumber, null, 'The test number should not be null.');
        Assert.areNotEqual(response.overallScore, null, 'The overall score should not be null.');
        Assert.areNotEqual(response.listeningScore, null, 'The listening score should not be null.');
        Assert.areNotEqual(response.speakingScore, null, 'The speaking score should not be null.');
        Assert.areNotEqual(response.readingScore, null, 'The reading score should not be null.');
        Assert.areNotEqual(response.writingScore, null, 'The writing score should not be null.');
    }



    @IsTest
    static void testGetContactQualificationById() {
        // Step 1: Setup Test Data
        Contact newContact = new Contact(LastName='testContact', Contact_Profile__c = 'Alumni');
        insert newContact;

        Qualification__c newQual = new Qualification__c(Qualification_Name__c = 'Bachelor of Science', Callista_Code__c='123123');
        insert newQual;
        // Create a sample Contact_Qualification__c record
        Contact_Qualification__c qualification = new Contact_Qualification__c(
                Qualification__c = newQual.Id,
                Verification_Status__c = 'Verified',
                Expected_date_of_completion__c = Date.today().addYears(1),
                Contact__c= newContact.Id
        );
        insert qualification;

        // Step 2: Call the method being tested
        Test.startTest();
        Contact_Qualification__c result = EnglishTestApiService.getContactQualificationById(qualification.Id);
        Test.stopTest();

        // Step 3: Assertions
        Assert.areNotEqual(null, result, 'The result should not be null.');
        Assert.areEqual('Verified', result.Verification_Status__c, 'The verification status should match.');
    }


    @IsTest
    static void testGetEnglishVerificationCustomSetting() {
        // Step 1: Setup Test Data
        // Create a test record for Feature_Switch__c (Custom Setting)
        Feature_Switch__c featureSwitch = new Feature_Switch__c(
                English_Verification__c = true
        );
        insert featureSwitch;

        // Step 2: Call the method under test
        Test.startTest();
        Feature_Switch__c result = EnglishTestApiService.getEnglishVerificationCustomSetting();
        Test.stopTest();

        // Step 3: Assertions
        Assert.areNotEqual(null, result, 'The result should not be null.');
    }


}