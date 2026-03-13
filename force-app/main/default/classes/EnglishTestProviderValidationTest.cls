/**
 * @author      APRivera
 * @description Test class for EnglishTestProviderValidation
 * @group       Admissions - English Test
 * @revision   15/12/2024 - APRivera - Created
 */

@IsTest(IsParallel=true)
public class EnglishTestProviderValidationTest {

    /**
     * Tests the `validate` method with valid inputs (IELTS implementation).
     */
    @IsTest
    static void testValidate_ValidPayload_IELTS() {
        // Arrange: Create an instance of a concrete `EnglishTestProviderValidation` implementation (e.g., IELTSProviderValidation)
        EnglishTestProviderValidation providerValidator = new IELTSProviderValidation();

        // Create a valid `EnglishTestVerificationPayload`
        EnglishTestVerificationPayload payload = new EnglishTestVerificationPayload();
        payload.provider = EnglishTestProviderType.IELTS.name(); // Ensure type match
        payload.testNumber = '123456789';
        payload.testType = 'Academic';
        payload.testDate = Date.newInstance(2023, 10, 1);
        payload.firstName = 'John';
        payload.lastName = 'Doe';

        // Create a valid `TestReportFormWrapper`
        EnglishTestVerificationPayload.TestReportFormWrapper testReportForm = createTestReportForm('Jane', 'Smith', Date.newInstance(1990, 1, 1));

        // Act: Call the `validate` method
        Test.startTest();
        EnglishTestVerificationPayload response = providerValidator.validate(payload, testReportForm);
        Test.stopTest();

        // Assert
        Assert.areNotEqual(response,null);
    }

    private static EnglishTestVerificationPayload.TestReportFormWrapper createTestReportForm(
            String firstName, String lastName, Date dob) {
        EnglishTestVerificationPayload.TestReportFormWrapper testReportForm =
                new EnglishTestVerificationPayload.TestReportFormWrapper();
        testReportForm.FirstName = firstName;
        testReportForm.LastName = lastName;
        testReportForm.DOB = dob;
        return testReportForm;
    }
}