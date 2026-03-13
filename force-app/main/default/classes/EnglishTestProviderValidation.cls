/**
 * @author      APRivera
 * @description Defines a contract with a single method validate() that accepts an EnglishTestVerificationPayload object.
 * @group       Admissions - English Test
 * @revision   15/12/2024 - APRivera - Created
 */

public interface EnglishTestProviderValidation {
    /**
     * Validates the provided EnglishTestVerificationPayload object.
     * @param payload The EnglishTestVerificationPayload object containing details to be validated.
     * @param testReportForm Wrapper class for managing test report data, including personal details.
     * @return Boolean indicating whether the validation was successful (true) or unsuccessful (false).
     * @throws CalloutException if validation fails.
     */
    EnglishTestVerificationPayload validate(EnglishTestVerificationPayload payload, EnglishTestVerificationPayload.TestReportFormWrapper testReportForm);
}