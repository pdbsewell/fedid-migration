/**
 * @Class              : ApplicationWebService.cls
 * @Description        : Webservice class for Managing Applications 
 * @Author             : Vinothraja
 * @Group              : Admissions
 * @Revision           : 
 * 2023-02-17     Vinothraja   Created
 * 2023-11-22     Vinothraja   Added logging of API requests
 */
@RestResource(urlMapping='/v2/ApplicationWebService')
global with sharing class ApplicationWebService {
    static Feature_Switch__c fs = Feature_Switch__c.getInstance();
    /**
	 * @description     creates an Application 
	 * @param           JSON that can be serialized into AgentPortalPayload.CreateApplicationRequest object
	 * @return          JSON that follows AgentPortalPayload.CreateApplicationResponse object
	 */
    @HttpPost
    global static void handleCreateApplication() {
        // Initialize 
        AgentPortalPayload.CreateApplicationRequest requestWrapper;
        AgentPortalPayload.CreateApplicationResponse responseWrapper = new AgentPortalPayload.CreateApplicationResponse();
        RestRequest request = RestContext.request;
        RestContext.response.addHeader('Content-Type', 'application/json');
       
        try {
            // Deserialize request
            requestWrapper = (AgentPortalPayload.CreateApplicationRequest) JSON.deserialize(request.requestBody.toString(), 
                                                                                                             AgentPortalPayload.CreateApplicationRequest.class);

            if (fs.Enable_Detailed_Logs_for_APNG__c) {
                LogUtilityException.logExceptionMSG('ApplicationWebService', 'handleCreateApplication', request.requestBody.toString());
            }
            //  validate request
            if (requestWrapper.isValid) {
                // create application and set to Response
                responseWrapper.applicationRecord = AgentPortalServices.createApplication(requestWrapper.asApplication(), requestWrapper.applicantEmail, requestWrapper.applicantPhone);
            }

        } catch (Exception ex) {
            // Set error response 
            responseWrapper.exceptionRecord = ex;
            // Log the exception
            LogUtilityException.logException(ex, String.format('Application failed to create with: Campus Location: {0} and Residency Status: {1} for Contact: {2}', 
                            new List<String>{requestWrapper.campusLocation, requestWrapper.residencyStatus, requestWrapper.contactId}));
        }

        // Set response
        RestContext.response.responseBody = responseWrapper.responseBody;
    }

    /**
	 * @description     Gets details and related info of an Application based on  
	 * @param           JSON that can be serialized into AgentPortalPayload.GetApplicationDetailsRequest object
	 * @return          JSON that follows AgentPortalPayload.GetApplicationDetailsResponse object
	 */
    @HttpGet
    global static void handleGetApplicationDetails() {
        //Initialize 
        RestRequest request = RestContext.request;
        AgentPortalPayload.GetApplicationDetailsRequest requestWrapper = new AgentPortalPayload.GetApplicationDetailsRequest(request.params);
        AgentPortalPayload.GetApplicationDetailsResponse responseWrapper = new AgentPortalPayload.GetApplicationDetailsResponse();
        RestContext.response.addHeader('Content-Type', 'application/json');
       
        try {
            if (fs.Enable_Detailed_Logs_for_APNG__c) {
                LogUtilityException.logExceptionMSG('ApplicationWebService', 'handleGetApplicationDetails', JSON.serializePretty(request.params));
            }
            // set Application details and related to Response
            if (requestWrapper.isValid){
                // set results to Response based on Request Type
                switch on requestWrapper.requestType.toLowerCase() {
                    when  'qualifications' {
                        responseWrapper.qualifications = AgentPortalServices.getContactQualificationsByApplicationId(requestWrapper.applicationId);
                    }
                    when  'experiences' {
                        responseWrapper.workExperiences = AgentPortalServices.getWorkExperiencesByApplicationId(requestWrapper.applicationId);
                    }
                    when else {
                        responseWrapper.details = AgentPortalServices.getApplicationDetails(requestWrapper.applicationId);
                    }
                }
            } 
        } catch (Exception ex) {
            // set Error response 
            responseWrapper.exceptionRecord = ex;
            // Log the exception
            LogUtilityException.logException(ex, 'Failed to find details for Application:' + requestWrapper.applicationId);
        }

        // Construct Response
        RestContext.response.responseBody = responseWrapper.responseBody;
    }
    /**
	 * @description     Updates an Application
	 * @param           JSON that can be serialized into AgentPortalPayload.UpdateApplicationRequest object
	 * @return          JSON that follows AgentPortalPayload.UpdateApplicationResponse object
	 */
    @HttpPatch
    global static void handleUpdateApplication() {
        //Initialize 
        AgentPortalPayload.UpdateApplicationRequest requestWrapper;
        AgentPortalPayload.UpdateApplicationResponse responseWrapper = new AgentPortalPayload.UpdateApplicationResponse();
        RestRequest request = RestContext.request;
        RestContext.response.addHeader('Content-Type', 'application/json');
       
        try {
            //deserialize request
            requestWrapper = (AgentPortalPayload.UpdateApplicationRequest) JSON.deserialize(request.requestBody.toString(), 
                                                                                                             AgentPortalPayload.UpdateApplicationRequest.class);

            if (fs.Enable_Detailed_Logs_for_APNG__c) {
                LogUtilityException.logExceptionMSG('ApplicationWebService', 'handleUpdateApplication', request.requestBody.toString());
            }


            requestWrapper.init();
            if (requestWrapper.isValid){
                // update Application and set it to Response
                responseWrapper.updateStatus = requestWrapper.process();
            }
        } catch (Exception ex) {
            // set Error response 
            responseWrapper.exceptionRecord = ex;
            // Log the exception
            LogUtilityException.logException(ex, 'Failed to update Application'); 
        }

        // Construct Response
        RestContext.response.responseBody = responseWrapper.responseBody;
    }
}