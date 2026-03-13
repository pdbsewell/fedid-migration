/**
 * @author      APRivera
 * @description A factory class with a static method getValidator(EnglishTestProviderType provider) to return an appropriate EnglishTestProviderValidation implementation based on the EnglishTestProviderType.
 * @group       Admissions - English Test
 * @revision   15/12/2024 - APRivera - Created
 */

public class EnglishTestProviderValidationFactory {
    /**
     * Returns the appropriate validator implementation based on the provider type.
     * @param provider The provider from the EnglishTestVerificationPayload.
     * @return An implementation of EnglishTestProviderValidation.
     */
    public static EnglishTestProviderValidation getValidator(EnglishTestProviderType provider) {

        if (provider == EnglishTestProviderType.IELTS) {
            return new IELTSProviderValidation();
        } else if (provider == EnglishTestProviderType.TOEFL) {
            return new TOEFLProviderValidation();
        }

//            todo: next releases
//        if (provider == EnglishTestProviderType.TOEFL) {
//            return new TOFELProviderValidation();
//        } if (provider == EnglishTestProviderType.PEARSON) {
//            return new PearsonProviderValidation();
//        }
        return null;
    }
}