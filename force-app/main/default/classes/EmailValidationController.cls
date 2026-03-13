/**
 * @author      Sachin Shetty
 * @description Apex controller class for actions required on emailValidationEDQ lwc
 * @group       Controllers
 * @testclass   EmailValidationController_Test
 * @revision    2022-10-17 - Sachin Shetty - Update to uniquely identify each guest user
 *              2022-10-04 - Sachin Shetty - Rate limiting changes
 *              2022-08-26 - Sachin Shetty - Created
**/
public with sharing class EmailValidationController {

    private static final string ERROR_PROCESSING_REQUEST = 'Experian - Rate limit exception validating email address.';

    /**
     * @author      Sachin Shetty
     * @description Returns the email DAO for the entered number
     * @param       String email
     * @param       String customSettingName
     * @param       String guestKey
     * @return      Object
     * @revision    2022-10-17 - Sachin Shetty - Update to uniquely identify each guest user
     *              2022-10-04 - Sachin Shetty - Rate limiting changes
     *              2022-08-26 - Sachin Shetty - Created
     */
    @AuraEnabled
    public static EDQEmailDAO.EmailResponse validate(String email, String customSettingName, String guestKey){
        if(String.isBlank(email)) return null;

        try{
            if(!ExperianUtility.IPCheckExceedsLimit(customSettingName, guestKey)){
                EDQEmailService stub = new EDQEmailService();
                return stub.validateEmail(email);
            }
            else{
                LogUtilityException.logExceptionMSG('EmailValidationController.validate', email, ERROR_PROCESSING_REQUEST);
                return null;
            }
        }catch (Exception ex) {
            return createErrorResp(ex);
        }
    }
    @TestVisible
    private static EDQEmailDAO.EmailResponse createErrorResp(Exception ex){
        LogUtilityException.logException(ex);
        EDQEmailDAO.EmailResponse fakeRsp = new EDQEmailDAO.EmailResponse();
        fakeRsp.result = new EDQEmailDAO.EmailResult();
        fakeRsp.result.confidence = 'undeliverable';
        fakeRsp.result.verbose_output = ex.getMessage();
        return fakeRsp;
    }
    /**
     * @author      Sachin Shetty
     * @description Returns the Email validation wrapper
     * @return      EmailWrapper
     * @revision    2022-08-26 - Sachin Shetty - Created
     */
    @AuraEnabled
    public static EmailValidationWrapper.EmailWrapper getEmailWrapper() {
        return new EmailValidationWrapper.EmailWrapper();
    }

    /**
     * @author      Sachin Shetty
     * @description Returns the Map of Confidence values by Verbose Output values and their description
     * @return      Map<String, Map<String, String>>
     * @revision    2022-08-29 - Sachin Shetty - Created
     */
    @AuraEnabled
    public static Map<String, Map<String, String>> getVerboseOutputDescriptionsByConfidence() {
        return EmailValidationWrapper.verboseOutputDescriptionsByConfidence;
    }

    /**
     * @author      Sachin Shetty
     * @description Returns generic error message boolean value
     * @return      Boolean
     * @revision    2022-08-31 - Sachin Shetty - Created
     */
    @AuraEnabled
    public static Boolean getShowGenericErrorMessageDecision() {
        return EmailValidationWrapper.showGenericErrorMessage;
    }
}