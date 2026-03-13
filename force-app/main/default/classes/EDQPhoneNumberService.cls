/**
 * @author      Sachin Shetty 
 * @description Service class for validating pone number
 * @group       Services
 * @revision    2022-08-03 - Sachin Shetty - Created
 *              2023-12-04 - Sachin Shetty - Added validate method that gets called from lwc
**/
public with sharing class EDQPhoneNumberService {

    public final string PHONENUMBER_VALIDATION_NOT_AUTHORIZED_MESSAGE = 'Experian phone number validation authentication failed.';
    public final string PHONENUMBER_VALIDATION_UNSUCCESSFUL_MESSAGE = 'Experian phone number validation unsuccessful';
    public final string EXPERIAN_SERVICE_UNAVAILABLE = 'Experian service unavailable';
    public final string EXPERIAN_CREDITS_INSUFFICIENT = 'Invalid authentication token or insufficient Experian credits';
    public final string RESPONSE_FROM_MESSAGE = 'response from Experian';
    public final string RESPONSE_STATUS_CODE_MESSAGE = 'Response status code';
    public final string NUMBER_OUTPUT_FORMAT = 'PLUS_E164';
    public final string CACHE_VALUE_DAYS = '30';

    /**
     * @author      Sachin Shetty
     * @description Callout to Experian to validate a phone number
     * @param       String phoneNumber
     * @param       String countryIsoCode
     * @return      Object
     * @revision    2022-08-03 - Sachin Shetty - Created
     */
    public EDQPhoneNumberDAO.PhoneNumberResponse validatePhoneNumber(String phoneNumber, String countryIsoCode) {

        // Request formatted as an object since 'number' field in the request is a reserved keyword in apex
        // and cannot declare it as a field in EDQPhoneNumberDAO
        Map<String, Object> reqDAO = new Map<String, Object>{
            'number' => phoneNumber,
            'output_format' => NUMBER_OUTPUT_FORMAT,
            'cache_value_days' => CACHE_VALUE_DAYS,            
            'country_iso' => countryIsoCode
        };

        String jbodyReq = JSON.serializePretty(reqDAO);
        //
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:EDQService/phone/validate/v2');
        req.setMethod('POST');
        req.setBody(jbodyReq);
        req.setHeader('Auth-Token','{!$Credential.Password}');
        req.setHeader('Add-Metadata','true');
        req.setHeader('Reference-Id','validatePhoneNumber:'+UserInfo.getUserId());
        req.setHeader('Timeout-Seconds','10');
        req.setHeader('Content-Type','application/json');

        EDQPhoneNumberDAO.PhoneNumberResponse phoneNumberValidationResult = null;
        try{
            Http http = new Http();
            HTTPResponse response = http.send(req);
            String resultString = response.getBody();            
            phoneNumberValidationResult = (EDQPhoneNumberDAO.PhoneNumberResponse)JSON.deserialize(resultString, EDQPhoneNumberDAO.PhoneNumberResponse.class);
            EDQPhoneNumberDAO.PhoneNumberResult result = new EDQPhoneNumberDAO.PhoneNumberResult();

            if(Label.Mock_Experian_Service_Unavailable == 'true' || Label.Mock_Insufficient_Experian_Credits == 'true'){
                phoneNumberValidationResult.result.validated_phone_number = '';
                phoneNumberValidationResult.result.formatted_phone_number = '';
                phoneNumberValidationResult.result.phone_type = '';
                phoneNumberValidationResult.result.ported_date = '';
                PhoneNumberValidationResult.result.disposable_number = '';
                if(Label.Mock_Experian_Service_Unavailable == 'true'){
                    PhoneNumberValidationResult.result.confidence = 'Service Unavailable';
                    response.setStatusCode(503);
                }
                if(Label.Mock_Insufficient_Experian_Credits == 'true'){
                    PhoneNumberValidationResult.result.confidence = 'Forbidden';
                    response.setStatusCode(403);
                }
            }
            switch on response.getStatusCode() {
                when 200 { // indicates success response
                    phoneNumberValidationResult = (EDQPhoneNumberDAO.PhoneNumberResponse)JSON.deserialize(resultString, EDQPhoneNumberDAO.PhoneNumberResponse.class);
                }
                when 401 { // indicates invalid authorization
                    LogUtilityException.logExceptionMSG('EDQPhoneNumberService.validatePhoneNumber' ,'Endpoint: \n' + req.getEndpoint(), PHONENUMBER_VALIDATION_NOT_AUTHORIZED_MESSAGE);
                    throw new EDQUnauthorizedAccessException(PHONENUMBER_VALIDATION_NOT_AUTHORIZED_MESSAGE);
                }
                when 403 { // indicates insufficient Experian credits
                    phoneNumberValidationResult.result = result;
                    phoneNumberValidationResult.result.confidence = 'Forbidden';
                    phoneNumberValidationResult.result.formatted_phone_number = phoneNumber;
                    LogUtilityException.logExceptionMSG('EDQPhoneNumberService.validatePhoneNumber' ,'Endpoint: \n' + req.getEndpoint(), EXPERIAN_CREDITS_INSUFFICIENT);
                }
                when 503 { // indicates Experian service unavailable
                    phoneNumberValidationResult.result = result;
                    phoneNumberValidationResult.result.confidence = 'Service Unavailable';
                    phoneNumberValidationResult.result.formatted_phone_number = phoneNumber;
                    LogUtilityException.logExceptionMSG('EDQPhoneNumberService.validatePhoneNumber' ,'Endpoint: \n' + req.getEndpoint(), EXPERIAN_SERVICE_UNAVAILABLE);
                }
                when else {
                    String errorMessage = PHONENUMBER_VALIDATION_UNSUCCESSFUL_MESSAGE + ' for phone number : ' + phoneNumber
                                            + '. ' + RESPONSE_STATUS_CODE_MESSAGE + ': ' + String.valueOf(response.getStatusCode())
                                            + ', ' + RESPONSE_FROM_MESSAGE + ': ' + response.getBody();
                    LogUtilityException.logExceptionMSG('EDQPhoneNumberService.validatePhoneNumber' ,'Endpoint: \n' + req.getEndpoint(), errorMessage);
                    throw new EDQUnauthorizedAccessException(errorMessage);
                }
            }
        }
        catch (Exception e){
            LogUtilityException.logException(e,'EDQPhoneNumberDAO.validatePhoneNumber');
            LogUtilityException.throwMSG(e.getMessage());
        }
        return phoneNumberValidationResult;
    }    

    /**
     * @author      Sachin Shetty
     * @description Callout to Experian to validate a phone number
     * @param       String phoneNumber
     * @param       String countryIsoCode
     * @return      Object
     * @revision    2023-12-04 - Sachin Shetty - Created
     */
    @AuraEnabled
    public static EDQPhoneNumberDAO.PhoneNumberResponse validate(String phoneNumber, String countryIsoCode){
        try {
            return new EDQPhoneNumberService().validatePhoneNumber(phoneNumber, countryIsoCode);
        } catch (Exception e) {
            LogUtilityException.logException(e,'EDQPhoneNumberService.validate');
            LogUtilityException.throwMSG(e.getMessage());
            return null;
        }
    }

    public class EDQUnauthorizedAccessException extends Exception {}
}