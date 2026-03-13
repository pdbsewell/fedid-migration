/**
 * @description      : Allow MIX integration to access (inbound/outbound) SF data.
 * @author            : Angelo Rivera
 * @group             : Student Admin
 * @version           : Modifications Log
 * Ver   Date           Author              Modification
 * 1.0   21-10-2021 - Angelo Rivera - Initial Creation
**/

@RestResource(UrlMapping='/CorrelationServices/*')
global without sharing class CorrelationService {

    @HttpPost
    webService static String updateData(String correlation_id, String action_result, String message) {
        String strReturn;

        if(correlation_id != null){
            try {
                Id recId = Id.valueOf(correlation_id);
                // case
                if(Schema.Case.SObjectType == recId.getSobjectType()){
                    // logic here
                    Case cse = [SELECT Id FROM  Case WHERE Id =: recId];
                    if(message != null){
                        cse.Integration_Status__c = message;
                        Database.update(cse);
                    }
                    strReturn = 'Success';
                }else{
                    strReturn = 'Error';
                    LogUtilityException.logExceptionMSG('Error', 'correlation_id - ' + correlation_id, 'Invalid Correlation Id' );
                }
            } catch (Exception e) {
                strReturn = 'Error';
                LogUtilityException.logExceptionMSG('Error', 'CorrelationService - ' + correlation_id, e.getMessage());
            }
        }else{
            strReturn = 'Error';
            LogUtilityException.logExceptionMSG('Error', 'correlation_id - ' + correlation_id, 'Invalid Correlation Id');
        }
        return strReturn;
    }
}