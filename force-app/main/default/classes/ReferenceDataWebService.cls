/**
 * @Class              : ReferenceDataWebService.cls
 * @Description        : Webservice class for providing Reference Data to Agent Portal 
 * @Author             : Vinothraja
 * @Group              : Admissions
 * @Revision           : 
 * 2023-03-07     Vinothraja   Created 
 * 2023-11-22     Vinothraja   Added logging of API requests
 */
@RestResource(urlMapping='/v2/ReferenceDataWebService')
global with sharing class ReferenceDataWebService {
    static Feature_Switch__c fs = Feature_Switch__c.getInstance();
    /**
	 * @description     Gets reference data based on the request body/query params
	 * @param           JSON that can be serialized into AgentPortalPayload.ReferenceDataRequest object
	 * @return          JSON that follows AgentPortalPayload.ReferenceDataResponse object
	 */
    @HttpGet
    global static void getReferenceData() {
        //Initialize 
        RestRequest request = RestContext.request;
        AgentPortalPayload.ReferenceDataRequest requestWrapper = new AgentPortalPayload.ReferenceDataRequest(request.params);
        AgentPortalPayload.ReferenceDataResponse responseWrapper = new AgentPortalPayload.ReferenceDataResponse(requestWrapper.requestType);
        RestContext.response.addHeader('Content-Type', 'application/json');

        try {
            if (fs.Enable_Detailed_Logs_for_APNG__c) {
                LogUtilityException.logExceptionMSG('ReferenceDataWebService', 'getReferenceData', JSON.serializePretty(request.params));
            }
            if (requestWrapper.isValid){
                // set results to Response based on Request Type
                switch on requestWrapper.requestType.toLowerCase() {
                    when  'residencystatus' {
                        responseWrapper.referenceDataRecords = AgentPortalServices.getResidencyStatus(UserInfo.getUserId());
                    }
                }
            }
        } catch (Exception ex) {
            // set Error response 
            responseWrapper.exceptionRecord = ex;
            // Log the exception
            LogUtilityException.logException(ex, 'Failed to find records for : ' + requestWrapper.requestType); 
        }

        // Construct Response
        RestContext.response.responseBody = responseWrapper.responseBody;
    } 
}