/**
 * @author      APRivera
 * @description Specific to TOEFL validation
 * @group       Admissions
 * @revision   15/12/2024 - APRivera - Created
 * @revision   14/04/2025 - APRivera - Included validation on Test Type
 */

public with sharing class TOEFLProviderValidation implements EnglishTestProviderValidation {

    /**
     * Validates the provided EnglishTestVerificationPayload against the provided test report form.
     * @param payload The EnglishTestVerificationPayload object containing details to be validated.
     * @param testReportForm Wrapper class for managing test report data, including personal details.
     * @return Boolean indicating whether the validation was successful (true) or unsuccessful (false).
     */
    public EnglishTestVerificationPayload validate(EnglishTestVerificationPayload payload,EnglishTestVerificationPayload.TestReportFormWrapper testReportForm) {
        String status ='';
        String message = '';
        String mappedTestReportFormTestType;

        // Convert payload test type to uppercase for case-insensitive comparison
        if (payload.testType != null && testReportForm.TestType != null) {
            String testFormTestTypeUpper = String.valueOf(testReportForm.TestType).replaceAll('[()-]', '').toUpperCase();
            String payloadTestTypeUpper = String.valueOf(payload.testType).replaceAll('[()-]', '');

            if (testFormTestTypeUpper == 'TOEFL ESSENTIALS') {
                mappedTestReportFormTestType = 'E';
            } else if (testFormTestTypeUpper == 'TOEFL IBT' || testFormTestTypeUpper == 'TOEFL IBT PAPER BASED EDITION') {
                mappedTestReportFormTestType = 'I';
            } 

            // First, validate test type
            if (mappedTestReportFormTestType != payloadTestTypeUpper) {
                status = 'fail';
                message = 'Test Type does not match - Verification unsuccessful';
                return EnglishTestApiService.generateResponse(payload, status, message, false);
            }
        }

        // Validate date of birth
        if (payload.dateOfBirth != testReportForm.DOB) {
            status = 'fail';
            message = 'Date of birth does not match - Verification unsuccessful';
            return EnglishTestApiService.generateResponse(payload, status, message, false);
        }

        // Name validation scenarios
        String payloadFirstName = payload.firstName != null ? String.valueOf(payload.firstName).toUpperCase() : '';
        String payloadLastName = payload.lastName != null ? String.valueOf(payload.lastName).toUpperCase() : '';
        String testFirstName = testReportForm.FirstName != null ? String.valueOf(testReportForm.FirstName).toUpperCase() : '';
        String testLastName = testReportForm.LastName != null ? String.valueOf(testReportForm.LastName).toUpperCase() : '';
        String testPreviousFirstName = testReportForm.PreviousFirstName != null ? String.valueOf(testReportForm.PreviousFirstName).toUpperCase() : '';
        String testPreviousLastName = testReportForm.PreviousLastName != null ? String.valueOf(testReportForm.PreviousLastName).toUpperCase() : '';

        if (payloadFirstName == testFirstName && payloadLastName == testLastName) {
            status = 'success';
            message = 'Direct match - Verification successful';
        } else if (payloadLastName == testLastName && payloadFirstName == testPreviousFirstName) {
            status = 'success';
            message = 'Match with previous first name - Verification successful';
        } else if (payloadFirstName == testFirstName && payloadLastName == testPreviousLastName) {
            status = 'success';
            message = 'Match with previous last name - Verification successful';
        } else if (payloadFirstName == testPreviousFirstName && payloadLastName == testPreviousLastName) {
            status = 'success';
            message = 'Match with previous first & last names - Verification successful';
        } else {
            // Validation unsuccessful
            status = 'fail';
            message = 'Verification unsuccessful';
        }

        // Additional TOEFL-specific validations can be added here
        return EnglishTestApiService.generateResponse(payload, status, message, false);
    }

}