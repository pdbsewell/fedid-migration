/**
 * @author      APRivera
 * @description Test class for EnglishTestProviderValidationFactory
 * @group       Admissions - English Test
 * @revision   15/12/2024 - APRivera - Created
 */

@IsTest(IsParallel=true)
private class EnglishTestProviderValidationFactoryTest {


    /**
     * Test that the factory method returns the correct validator for the IELTS provider.
     */
    @IsTest
    static void testGetValidator_IELTS() {
        // Call the factory method with the EnglishTestProviderType.IELTS enum
        EnglishTestProviderValidation validator = EnglishTestProviderValidationFactory.getValidator(EnglishTestProviderType.IELTS);

        // Verify the result is not null and is of type IELTSProviderValidation
        Assert.areNotEqual(null, validator, 'Validator should not be null for IELTS provider.');
        Assert.isTrue(
                validator instanceof IELTSProviderValidation,
                'Expected the validator to be an instance of IELTSProviderValidation.'
        );
    }

}