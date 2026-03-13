/**
 * @author     Sachin Shetty
 * @description Apex controller class for actions required on phoneNumberValidationEDQ lwc
 * @group       Controllers
 * @testclass   PhoneNumberValidationController_Test
 * @revision    2022-10-17 - Sachin Shetty - Update to uniquely identify each guest user
 *              2022-10-12 - Sachin Shetty - Changed references from PhoneNumberValidationWrapper to ExperianUtility to fetch country attributes
 *              2022-10-03 - Sachin Shetty - Rate Limiting related changes
 *              2022-09-06 - Sachin Shetty - Support for generic validation message
 *              2022-08-03 - Sachin Shetty - Created
**/
public with sharing class PhoneNumberValidationController {

    private static final string ERROR_PROCESSING_REQUEST = 'Experian - Rate limit exception validating phone number.';

    /**
     * @author      Sachin Shetty
     * @description Returns the frequently used countries list
     * @return      List<Country_Attribute__c>
     * @revision    2022-10-12 - Sachin Shetty - Created
     */
    @AuraEnabled
    public static List<Country_Attribute__c> getTopCountriesList() {
        return ExperianUtility.topCountriesList;
    }

    /**
     * @author      Sachin Shetty
     * @description Returns the list of countries excluding the frequently used ones
     * @return      List<Country_Attribute__c>
     * @revision    2022-10-12 - Sachin Shetty - Created
     */
    @AuraEnabled
    public static List<Country_Attribute__c> getRestOfTheCountriesList() {
        return ExperianUtility.restOfTheCountriesList;
    }

    /**
     * @author      Sachin Shetty
     * @description Returns the phone number DAO for the entered number
     * @param       String phoneNumber
     * @param       String countryIsoCode
     * @param       String customSettingName
     * @param       String guestKey
     * @return      Object
     * @revision    2022-10-17 - Sachin Shetty - Update to uniquely identify each guest user
     *              2022-10-03 - Sachin Shetty - Rate Limiting related changes
     *              2022-08-03 - Sachin Shetty - Created
     */
    @AuraEnabled
    public static EDQPhoneNumberDAO.PhoneNumberResponse validate(String phoneNumber, String countryIsoCode, String customSettingName, String guestKey){
        try{
            if(!ExperianUtility.IPCheckExceedsLimit(customSettingName, guestKey)){
                EDQPhoneNumberService stub = new EDQPhoneNumberService();
                return stub.validatePhoneNumber(phoneNumber, countryIsoCode);
            }
            else{
                LogUtilityException.logExceptionMSG('PhoneNumberValidationController.validate', phoneNumber, ERROR_PROCESSING_REQUEST);
                return null;
            }
        }catch (Exception ex) {
            return createErrorResp(ex);
        }
    }
    @TestVisible
    private static EDQPhoneNumberDAO.PhoneNumberResponse createErrorResp(Exception ex){
        LogUtilityException.logException(ex);
        EDQPhoneNumberDAO.PhoneNumberResponse fakeRsp = new EDQPhoneNumberDAO.PhoneNumberResponse();
        fakeRsp.result = new EDQPhoneNumberDAO.PhoneNumberResult();
        fakeRsp.result.confidence = 'undeliverable';
        return fakeRsp;
    }
    /**
     * @author      Sachin Shetty
     * @description Returns the PhoneNumber validation wrapper
     * @return      PhoneNumberWrapper
     * @revision    2022-08-03 - Sachin Shetty - Created
     */
    @AuraEnabled
    public static PhoneNumberValidationWrapper.PhoneNumberWrapper getPhoneNumberWrapper() {
        return new PhoneNumberValidationWrapper.PhoneNumberWrapper();
    }

    /**
     * @author      Sachin Shetty
     * @description Returns the confidence level values and their description
     * @return      Map<String, String>
     * @revision    2022-08-09 - Sachin Shetty - Created
     */
    @AuraEnabled
    public static Map<String, String> getConfidenceLevelDescriptions() {
        return PhoneNumberValidationWrapper.confidenceLevelDescriptions;
    }

    /**
     * @author      Sachin Shetty
     * @description Returns generic error message boolean value
     * @return      Boolean
     * @revision    2022-09-06 - Sachin Shetty - Created
     */
    @AuraEnabled
    public static Boolean getShowGenericErrorMessageDecision() {
        return PhoneNumberValidationWrapper.showGenericErrorMessage;
    }
}