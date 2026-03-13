/**
 * @author      APRivera
 * @description Test class for EnglishTestApiService
 * @group       Admissions - English Test
 * @revision   14-04-2025 - APRivera - Created
 * @revision   28-04-2025 - APRivera - Updated test coverage
 */

@IsTest(IsParallel=true)
private class TOEFLProviderValidationTest {

    @IsTest
    static void testValidate_DOBMismatch() {
        // Arrange
        EnglishTestVerificationPayload payload = createPayload('John', 'Doe', Date.newInstance(1990, 1, 1));
        EnglishTestVerificationPayload.TestReportFormWrapper testReportForm = createTestReportForm('John', 'Doe', Date.newInstance(1995, 10, 27)); // Different DOB

        // Act
        EnglishTestProviderValidation validator = EnglishTestProviderValidationFactory.getValidator(EnglishTestProviderType.TOEFL);
        EnglishTestVerificationPayload response = validator.validate(payload,testReportForm);

        // Assert
        Assert.areEqual(false, response.success, 'Expected validation to fail due to DOB mismatch');
        Assert.areEqual('Date of birth does not match - Verification unsuccessful', response.message);
    }
    @IsTest
    static void testValidate_TestTypeMismatch() {
        // Arrange
        EnglishTestVerificationPayload payload = createPayload('John', 'Doe', Date.newInstance(1990, 1, 1));
        EnglishTestVerificationPayload.TestReportFormWrapper testReportForm = createTestReportForm('John', 'Doe', Date.newInstance(1990, 1, 1));
        testReportForm.TestType  = 'TOEFL TEST';
        // Act
        EnglishTestProviderValidation validator = EnglishTestProviderValidationFactory.getValidator(EnglishTestProviderType.TOEFL);
        EnglishTestVerificationPayload response = validator.validate(payload,testReportForm);

        // Assert
        Assert.areEqual(false, response.success, 'Expected validation to fail due to Test Type mismatch');
        Assert.areEqual('Test Type does not match - Verification unsuccessful', response.message);
    }

    @IsTest
    static void testValidate_DirectMatch() {
        // Arrange
        EnglishTestVerificationPayload payload = createPayload('John', 'Doe', Date.newInstance(1990, 1, 1));
        EnglishTestVerificationPayload.TestReportFormWrapper testReportForm = createTestReportForm('John', 'Doe', Date.newInstance(1990, 1, 1));

        // Act
        EnglishTestProviderValidation validator = EnglishTestProviderValidationFactory.getValidator(EnglishTestProviderType.TOEFL);
        EnglishTestVerificationPayload response = validator.validate(payload,testReportForm);

        // Assert
        Assert.areEqual(true, response.success, 'Expected validation to succeed due to direct match');
        Assert.areEqual('Direct match - Verification successful', response.message);
    }

    @IsTest
    static void testValidate_DirectMatchTestType_I() {
        // Arrange
        EnglishTestVerificationPayload payload = createPayload('John', 'Doe', Date.newInstance(1990, 1, 1));
        payload.testType = 'I';
        EnglishTestVerificationPayload.TestReportFormWrapper testReportForm = createTestReportForm('John', 'Doe', Date.newInstance(1990, 1, 1));
        testReportForm.TestType = 'TOEFL IBT';
        // Act
        EnglishTestProviderValidation validator = EnglishTestProviderValidationFactory.getValidator(EnglishTestProviderType.TOEFL);
        EnglishTestVerificationPayload response = validator.validate(payload,testReportForm);

        // Assert
        Assert.areEqual(true, response.success, 'Expected validation to succeed due to direct match');
        Assert.areEqual('Direct match - Verification successful', response.message);
    }

    @IsTest
    static void testValidate_DirectMatchTestType_IBT_Paper() {
        // Arrange
        EnglishTestVerificationPayload payload = createPayload('John', 'Doe', Date.newInstance(1990, 1, 1));
        payload.testType = 'I';
        EnglishTestVerificationPayload.TestReportFormWrapper testReportForm = createTestReportForm('John', 'Doe', Date.newInstance(1990, 1, 1));
        testReportForm.TestType = 'TOEFL IBT PAPER BASED EDITION';
        // Act
        EnglishTestProviderValidation validator = EnglishTestProviderValidationFactory.getValidator(EnglishTestProviderType.TOEFL);
        EnglishTestVerificationPayload response = validator.validate(payload,testReportForm);

        // Assert
        Assert.areEqual(true, response.success, 'Expected validation to succeed due to direct match');
        Assert.areEqual('Direct match - Verification successful', response.message);
    }

    @IsTest
    static void testValidate_MatchWithPreviousFirstName() {
        // Arrange
        EnglishTestVerificationPayload payload = createPayload('John', 'Doe', Date.newInstance(1990, 1, 1));
        EnglishTestVerificationPayload.TestReportFormWrapper testReportForm = createTestReportForm('Jack', 'Doe', Date.newInstance(1990, 1, 1));
        testReportForm.PreviousFirstName = 'John'; // Previous first name matches

        // Act
        EnglishTestProviderValidation validator = EnglishTestProviderValidationFactory.getValidator(EnglishTestProviderType.TOEFL);
        EnglishTestVerificationPayload response = validator.validate(payload,testReportForm);

        // Assert
        Assert.areEqual(true, response.success, 'Expected validation to succeed due to previous first name match');
        Assert.areEqual('Match with previous first name - Verification successful', response.message);
    }

    @IsTest
    static void testValidate_MatchWithPreviousLastName() {
        // Arrange
        EnglishTestVerificationPayload payload = createPayload('John', 'Smith', Date.newInstance(1990, 1, 1));
        EnglishTestVerificationPayload.TestReportFormWrapper testReportForm = createTestReportForm('John', 'Doe', Date.newInstance(1990, 1, 1));
        testReportForm.PreviousLastName = 'Smith'; // Previous last name matches

        // Act
        EnglishTestProviderValidation validator = EnglishTestProviderValidationFactory.getValidator(EnglishTestProviderType.TOEFL);
        EnglishTestVerificationPayload response = validator.validate(payload,testReportForm);

        // Assert
        Assert.areEqual(true, response.success, 'Expected validation to succeed due to previous last name match');
        Assert.areEqual('Match with previous last name - Verification successful', response.message);
    }

    @IsTest
    static void testValidate_MatchWithPreviousFirstAndLastName() {
        // Arrange
        EnglishTestVerificationPayload payload = createPayload('Jack', 'Smith', Date.newInstance(1990, 1, 1));
        EnglishTestVerificationPayload.TestReportFormWrapper testReportForm = createTestReportForm('John', 'Doe', Date.newInstance(1990, 1, 1));
        testReportForm.PreviousFirstName = 'Jack';
        testReportForm.PreviousLastName = 'Smith';

        // Act
        EnglishTestProviderValidation validator = EnglishTestProviderValidationFactory.getValidator(EnglishTestProviderType.TOEFL);
        EnglishTestVerificationPayload response = validator.validate(payload,testReportForm);

        // Assert
        Assert.areEqual(true, response.success, 'Expected validation to succeed due to previous first and last name match');
        Assert.areEqual('Match with previous first & last names - Verification successful', response.message);
    }

    @IsTest
    static void testValidate_NoMatch() {
        // Arrange
        EnglishTestVerificationPayload payload = createPayload('John', 'Doe', Date.newInstance(1990, 1, 1));
        EnglishTestVerificationPayload.TestReportFormWrapper testReportForm = createTestReportForm('Jane', 'Smith', Date.newInstance(1990, 1, 1));

        // Act
        EnglishTestProviderValidation validator = EnglishTestProviderValidationFactory.getValidator(EnglishTestProviderType.TOEFL);
        EnglishTestVerificationPayload response = validator.validate(payload,testReportForm);

        // Assert
        Assert.areEqual(false, response.success, 'Expected validation to fail due to no valid matches');
        Assert.areEqual('Verification unsuccessful', response.message);
    }

    // Helper Methods to Create Test Data
    private static EnglishTestVerificationPayload createPayload(String firstName, String lastName, Date dob) {
        EnglishTestVerificationPayload payload = new EnglishTestVerificationPayload();
        payload.firstName = firstName;
        payload.lastName = lastName;
        payload.dateOfBirth = dob;
        payload.testType = 'E';
        return payload;
    }

    private static EnglishTestVerificationPayload.TestReportFormWrapper createTestReportForm(
            String firstName, String lastName, Date dob) {
        EnglishTestVerificationPayload.TestReportFormWrapper testReportForm =
                new EnglishTestVerificationPayload.TestReportFormWrapper();
        testReportForm.FirstName = firstName;
        testReportForm.LastName = lastName;
        testReportForm.DOB = dob;
        testReportForm.PreviousFirstName = null;
        testReportForm.PreviousLastName = null;
        testReportForm.TestType = 'TOEFL ESSENTIALS';
        return testReportForm;
    }
}