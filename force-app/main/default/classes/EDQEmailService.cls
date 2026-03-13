/**
 * @author      Sachin Shetty 
 * @description Service class for validating email address
 * @group       Services
 * @testclass   EDQEmailService_Test
 * @revision    2022-08-26 - Sachin Shetty - Created
 *              2023-12-04 - Sachin Shetty - Added validate method that gets called from lwc
 *              2024-02-06 - Sachin Shetty - 'Timed Out' error handling added
**/
public with sharing class EDQEmailService {

    public final string EMAIL_VALIDATION_NOT_AUTHORIZED_MESSAGE = 'Experian email validation authentication failed.';
    public final string EMAIL_VALIDATION_UNSUCCESSFUL_MESSAGE = 'Experian email validation unsuccessful';
    public final string EXPERIAN_SERVICE_UNAVAILABLE = 'Experian service unavailable';
    public final string EXPERIAN_CREDITS_INSUFFICIENT = 'Invalid authentication token or insufficient Experian credits';
    public final string RESPONSE_FROM_MESSAGE = 'response from Experian';
    public final string RESPONSE_STATUS_CODE_MESSAGE = 'Response status code';

    /**
     * @author      Sachin Shetty
     * @description Callout to Experian to validate an email address
     * @param       String email address
     * @return      Object
     * @revision    2022-08-26 - Sachin Shetty - Created
     *              2024-02-06 - Sachin Shetty - 'Timed Out' error handling added
     */
    public EDQEmailDAO.EmailResponse validateEmail(String email) {

        EDQEmailDAO.EmailRequest reqDAO = new EDQEmailDAO.EmailRequest(email);
        String jbodyReq = JSON.serializePretty(reqDAO);
        //
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:EDQService/email/validate/v2');
        req.setMethod('POST');
        req.setBody(jbodyReq);
        req.setHeader('Auth-Token','{!$Credential.Password}');
        req.setHeader('Add-Metadata','true');
        req.setHeader('Reference-Id','validateEmail:'+UserInfo.getUserId());
        req.setHeader('Timeout-Seconds','6');
        req.setHeader('Content-Type','application/json');

        EDQEmailDAO.EmailResponse emailValidationResult = null;
        try{
            Http http = new Http();
            HTTPResponse response = http.send(req);
            String resultString = response.getBody();
            emailValidationResult = (EDQEmailDAO.EmailResponse)JSON.deserialize(resultString, EDQEmailDAO.EmailResponse.class);
            EDQEmailDAO.EmailResult result = new EDQEmailDAO.EmailResult();

            if(Label.Mock_Experian_Service_Unavailable == 'true' || Label.Mock_Insufficient_Experian_Credits == 'true'){
                emailValidationResult.result.email = email;
                emailValidationResult.result.did_you_mean = new List<String>();
                emailValidationResult.metadata.domain_detail.type = '';
                if(Label.Mock_Experian_Service_Unavailable == 'true'){
                    emailValidationResult.result.confidence = 'service unavailable';
                    emailValidationResult.result.verbose_output = 'service unavailable';
                    response.setStatusCode(503);
                }
                if(Label.Mock_Insufficient_Experian_Credits == 'true'){
                    emailValidationResult.result.confidence = 'forbidden';
                    emailValidationResult.result.verbose_output = 'forbidden';
                    response.setStatusCode(403);
                }
            }
            switch on response.getStatusCode() {
                when 200 { // indicates success response
                    emailValidationResult = (EDQEmailDAO.EmailResponse)JSON.deserialize(resultString, EDQEmailDAO.EmailResponse.class);
                }
                when 401 { // indicates invalid authorization
                    LogUtilityException.logExceptionMSG('EDQEmailService.validateEmail' ,'Endpoint: \n' + req.getEndpoint(), EMAIL_VALIDATION_NOT_AUTHORIZED_MESSAGE);
                    throw new EDQUnauthorizedAccessException(EMAIL_VALIDATION_NOT_AUTHORIZED_MESSAGE);
                }
                when 403 { // indicates invalid authentication token or insufficient Experian credits
                    emailValidationResult.result = result;
                    emailValidationResult.result.confidence = 'forbidden';
                    emailValidationResult.result.verbose_output = 'forbidden';
                    emailValidationResult.result.email = email;
                    LogUtilityException.logExceptionMSG('EDQEmailService.validateEmail' ,'Endpoint: \n' + req.getEndpoint(), EXPERIAN_CREDITS_INSUFFICIENT);
                }
                when 408 { // Your request has timed out (the web server failed to respond in the specified time frame). Try submitting another request.
                    emailValidationResult = (EDQEmailDAO.EmailResponse)JSON.deserialize(resultString, EDQEmailDAO.EmailResponse.class);
                    LogUtilityException.logExceptionMSG('EDQEmailService.validateEmail' ,'Endpoint: \n' + req.getEndpoint(), 'Request Timed Out');
                }
                when 503 { // indicates Experian service unavailable
                    emailValidationResult.result = result;
                    emailValidationResult.result.confidence = 'service unavailable';
                    emailValidationResult.result.verbose_output = 'service unavailable';
                    emailValidationResult.result.email = email;
                    LogUtilityException.logExceptionMSG('EDQEmailService.validateEmail' ,'Endpoint: \n' + req.getEndpoint(), EXPERIAN_SERVICE_UNAVAILABLE);
                }
                when else {
                    String errorMessage = EMAIL_VALIDATION_UNSUCCESSFUL_MESSAGE + ' for email address : ' + email
                                            + '. ' + RESPONSE_STATUS_CODE_MESSAGE + ': ' + String.valueOf(response.getStatusCode())
                                            + ', ' + RESPONSE_FROM_MESSAGE + ': ' + response.getBody();
                    LogUtilityException.logExceptionMSG('EDQEmailService.validateEmail' ,'Endpoint: \n' + req.getEndpoint(), errorMessage);
                    throw new EDQUnauthorizedAccessException(errorMessage);
                }
            }
        }
        catch (Exception e){
            LogUtilityException.logException(e,'EDQEmailService.validateEmail');
            LogUtilityException.throwMSG(e.getMessage());
        }
        return emailValidationResult;
    }    

    /**
     * @author      Sachin Shetty
     * @description Callout to Experian to validate an email address
     * @param       String email
     * @return      Object
     * @revision    2023-12-04 - Sachin Shetty - Created
     */
    @AuraEnabled
    public static EDQEmailDAO.EmailResponse validate(String email){
        try {
            return new EDQEmailService().validateEmail(email);
        } catch (Exception e) {
            LogUtilityException.logException(e,'EDQEmailService.validate');
            LogUtilityException.throwMSG(e.getMessage());
            return null;
        }
    }

    public class EDQUnauthorizedAccessException extends Exception {}
}