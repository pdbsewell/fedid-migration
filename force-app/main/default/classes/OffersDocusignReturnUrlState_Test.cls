/**
 * @description Test class for OffersDocusignReturnUrlState
 */
@isTest(isParallel=true)
public class OffersDocusignReturnUrlState_Test {
    
    @isTest
    static void shouldReturnCorrectStateForApplicantOver18() {
        String applicantState = OffersDocusignReturnUrlState.applicantState(false, null);
        System.assertEquals('over18', applicantState, 'Expected over18');
    }

    @isTest
    static void shouldReturnCorrectStateForApplicantUnder18AndGuardianDigitalSign() {
        String applicantState = OffersDocusignReturnUrlState.applicantState(true, 'Yes');
        System.assertEquals('u18wGuardianEmail', applicantState, 'Expected u18wGuardianEmail');
    }

    @isTest
    static void shouldReturnCorrectStateForApplicantUnder18AndGuardianNotDigitalSign() {
        String applicantState = OffersDocusignReturnUrlState.applicantState(true, 'No');
        System.assertEquals('u18woGuardianEmail', applicantState, 'Expected u18woGuardianEmail');
    }

}