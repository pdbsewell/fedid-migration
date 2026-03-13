/**
 * @description         : HTTP Callout to MIX/RPA
 * @author              : Seeva
 * @group               : 
 * @revision 01/03/2023 : Seeva
 * @         25/02/2025 : Matthew Maramot - Updated Callout Headers (EPCP-4204) 
**/
public with sharing class COERequestCalloutService {
/**
 * @description         : HTTP Callout to MIX/RPA
 * @author              : Seeva
 * @group               : 
 * @revision 01/03/2023 : Seeva
 * @         25/02/2025 : Matthew Maramot - Updated Callout Headers (EPCP-4204) 
**/
    public static String sendCallout(String strRequestBodyJSON) {
        String strResponse = null;
        HttpResponse oHttpResponse = null;
        HttpRequest oHTTPRequest = null;
        List<Integer> iHTTPResponseStatus = new  List<Integer>{200,201,204};

        try{
            MIX_RPA_Settings__c oMixConfiguration = GetMixConfiguration();////CUSTOM SETTING RECORD WHICH CONTAINS ORG ID AND TENANT NAME USED FOR API CALL
            if (oMixConfiguration != null) {
                //Create Request
                Http oHttp = new Http();
                oHTTPRequest = new HttpRequest();
                oHTTPRequest.setEndpoint('callout:MIX_RPA_Integration/v1/uipath/queue-items');
                oHTTPRequest.setMethod('POST');
                //Set headers
                oHTTPRequest.setHeader('Content-Type', 'application/json');
                oHTTPRequest.setHeader('X-UIPATH-OrganizationUnitId', oMixConfiguration.COE_Org_Unit_ID__c);
                oHTTPRequest.setBody(strRequestBodyJSON);
                oHttpResponse = oHttp.send(oHTTPRequest);
                if(iHTTPResponseStatus.contains(oHttpResponse.getStatusCode())){
                    strResponse = System.Label.ProcessCOERequestSuccessMessage;
                }
                else{
                    String strJSONResponse = JSON.serializePretty(oHttpResponse.getBody());
                    LogUtilityException.logExceptionMSG('Class: COERequestCalloutService', 'sendCallout', strJSONResponse);
                    LogUtilityException.logExceptionMSG('Class: COERequestCalloutService', 'sendCallout-JSON', strRequestBodyJSON);
                    strResponse = System.Label.SS_ProcessDiscontinuationFailedMessage;
                }
            }
            return strResponse;
        }
        catch (System.CalloutException ex){
            LogUtilityException.logException(ex, 'Class: COERequestCalloutService');
            LogUtilityException.logExceptionMSG('Class: COERequestCalloutService', 'sendCallout-JSON', strRequestBodyJSON);
            return  System.Label.SS_ProcessDiscontinuationFailedMessage;
        }
    }
/**
 * @description         : TO FETCH THE CUSTOM SETTING MIX_RPA_Settings__c RECORD
 * @author              :  Seeva
 * @group               : 
 * @revision 01/03/2023 : Seeva
 * @         25/02/2025 : Matthew Maramot - Updated to use a single MIX RPA custom setting + removed Tenant Name (EPCP-4204) 
**/
    public static MIX_RPA_Settings__c GetMixConfiguration() {
        MIX_RPA_Settings__c[] settings = [
            SELECT Id, COE_Org_Unit_ID__c FROM MIX_RPA_Settings__c LIMIT 1
        ];
        return settings.size() > 0 ? settings[0] : null;
	}
}