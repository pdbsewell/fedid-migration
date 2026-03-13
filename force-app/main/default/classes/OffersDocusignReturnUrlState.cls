/**
 * @description Class for any DocuSign states that needs to be maintained/used 
 * from Salesforce to DocuSign for Offers. The state is part of the return url 
 * that is created as part of the DocuSign envelop. This state provides 
 * information about the user's interactions before signing after they return 
 * to Salesforce from DocuSign
 * @group Offers DocuSign Signature
 */
public inherited sharing class OffersDocusignReturnUrlState {
    
    private static final String UNDER_18_WITH_GUARDIAN_DIGITAL_SIGN = 'u18wGuardianEmail';
    private static final String UNDER_18_WITHOUT_GUARDIAN_DIGITAL_SIGN = 'u18woGuardianEmail';
    private static final String OVER_18 = 'over18';

    /**
     * @description Provides the state attribute that can be used for the 
     * Docusign return url based on whether the applicant is: Under 18 and 
     * guardian will sign digital, under 18 and no digital signature for 
     * guardian and over 18
     * @param isUnder18 A boolean that indicates if the applicant is under 18 
     * years of age
     * @param isGuardianDigitalSign Whether the guardian will be digitally 
     * signing the offer. Valid values are: Yes, No (case insensitive)
     * @return Returns the state value as a string
     */
    public static String applicantState(boolean isUnder18, String isGuardianDigitalSign) {
        if (isUnder18) {
            if ('Yes'.equalsIgnoreCase(isGuardianDigitalSign)) {
                return UNDER_18_WITH_GUARDIAN_DIGITAL_SIGN;
            } else {
                return UNDER_18_WITHOUT_GUARDIAN_DIGITAL_SIGN;
            }
        } else {
            return OVER_18;
        }
    }

}