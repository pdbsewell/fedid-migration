/**
 * @description       : HTTP Callout to MIX/RPA
 * @author            : rajesh.punjabi@monash.edu
 * @group             : 
 * @revision          : 28/06/22 - Rajesh Punjabi 
 *                    : 25/02/25 - Matthew Maramot Updated Callout Headers (EPCP-4204)
**/
public with sharing class CourseDisconCalloutService {

    public static String sendCallout(String strRequestBodyJSON) {
        String strResponse = null;
        HttpResponse oHttpResponse = null;
        HttpRequest oHTTPRequest = null;
        List<Integer> iHTTPResponseStatus = new  List<Integer>{200,201,204};

        try{
            MIX_RPA_Settings__c oMixConfiguration = GetMixConfiguration();

            if (oMixConfiguration != null) {
                //Create Request
                Http oHttp = new Http();
                oHTTPRequest = new HttpRequest();
                oHTTPRequest.setEndpoint('callout:MIX_RPA_Integration/v1/uipath/queue-items');
                oHTTPRequest.setMethod('POST');
                //Set headers
                oHTTPRequest.setHeader('Content-Type', 'application/json');
                oHTTPRequest.setHeader('X-UIPATH-OrganizationUnitId', oMixConfiguration.Course_Discontinuation_Org_Unit_Id__c);
                
                oHTTPRequest.setBody(strRequestBodyJSON);
                
                oHttpResponse = oHttp.send(oHTTPRequest);
                
                if(iHTTPResponseStatus.contains(oHttpResponse.getStatusCode())){
                    strResponse = System.Label.SS_ProcessDiscontinuationSuccessMessage;
                }
                else{
                    String strJSONResponse = JSON.serializePretty(oHttpResponse.getBody());
                    LogUtilityException.logExceptionMSG('Class: CourseDisconCalloutService', 'sendCallout', strJSONResponse);
                    LogUtilityException.logExceptionMSG('Class: CourseDisconCalloutService', 'sendCallout-JSON', strRequestBodyJSON);
                    strResponse = System.Label.SS_ProcessDiscontinuationFailedMessage;
                }
            }
            return strResponse;
        }
        catch (System.CalloutException ex){
            LogUtilityException.logException(ex, 'Class: CourseDisconCalloutService');
            LogUtilityException.logExceptionMSG('Class: CourseDisconCalloutService', 'sendCallout-JSON', strRequestBodyJSON);
            return  System.Label.SS_ProcessDiscontinuationFailedMessage;
        }
    }

    public static MIX_RPA_Settings__c GetMixConfiguration() {
        return [
            SELECT Id, Course_Discontinuation_Org_Unit_Id__c FROM MIX_RPA_Settings__c LIMIT 1
        ];
	}
}