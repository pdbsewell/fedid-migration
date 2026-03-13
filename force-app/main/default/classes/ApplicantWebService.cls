/**
 * @Class              : ApplicantWebService.cls
 * @Description        : Webservice class for Managing Applicants
 * @Author             : Vinothraja
 * @Group              : Admissions
 * @Revision           : 
 * 2023-02-14     Vinothraja   Created 
 * 2023-11-22     Vinothraja   Added logging of API requests
 */
@RestResource(urlMapping='/v2/ApplicantWebService')
global with sharing class ApplicantWebService {
    static Feature_Switch__c fs = Feature_Switch__c.getInstance();
    /**
	 * @description     creates an Applicant 
	 * @param           JSON that can be serialized into AgentPortalPayload.CreateApplicantRequest object
	 * @return          JSON that follows AgentPortalPayload.CreateApplicantResponse object
	 */
    @HttpPost
    global static void handleCreateApplicant() {
        // Initialize 
        AgentPortalPayload.CreateApplicantRequest requestWrapper;
        AgentPortalPayload.CreateApplicantResponse responseWrapper = new AgentPortalPayload.CreateApplicantResponse();
        RestRequest request = RestContext.request;
        RestContext.response.addHeader('Content-Type', 'application/json');
       
        try {
            // Deserialize request
            requestWrapper = (AgentPortalPayload.CreateApplicantRequest) JSON.deserialize(request.requestBody.toString(), 
                                                                                                             AgentPortalPayload.CreateApplicantRequest.class);

            if (fs.Enable_Detailed_Logs_for_APNG__c) {
                LogUtilityException.logExceptionMSG('ApplicantWebService', 'handleCreateApplicant', request.requestBody.toString());
            }
            // check validity of request
            if (requestWrapper.isValid) {
                // create Contact and set to Response
                responseWrapper.contactRecord = AgentPortalServices.createApplicant(requestWrapper.asContact(), UserInfo.getUserId());
            }

        } catch (Exception ex) {
            // Set error response 
            responseWrapper.exceptionRecord = ex;
            // Log the exception
            LogUtilityException.logException(ex, String.format('Applicant failed to create with: FirstName: {0},  LastName: {1}', 
                                                        new List<String> {requestWrapper.applicant.firstName,requestWrapper.applicant.lastName}));
        }

        // Set response
        RestContext.response.responseBody = responseWrapper.responseBody;
    }
    /**
	 * @description     Gets Applicant details based on CRM id or Name
	 * @param           JSON that can be serialized into AgentPortalPayload.GetApplicantDetailsRequest object
	 * @return          JSON that follows AgentPortalPayload.GetApplicantDetailsResponse object
	 */
    @HttpGet
    global static void handleGetApplicantDetails() {
        //Initialize 
        RestRequest request = RestContext.request;
        AgentPortalPayload.GetApplicantDetailsRequest requestWrapper;
        AgentPortalPayload.GetApplicantDetailsResponse responseWrapper = new AgentPortalPayload.GetApplicantDetailsResponse();
        RestContext.response.addHeader('Content-Type', 'application/json');
        
        try {
            //deserialize request
            requestWrapper = new AgentPortalPayload.GetApplicantDetailsRequest(request.params);
            if (fs.Enable_Detailed_Logs_for_APNG__c) {
                LogUtilityException.logExceptionMSG('ApplicantWebService', 'handleGetApplicantDetails', JSON.serializePretty(request.params));
            }
            if (requestWrapper.isValid){
                // set result to Response
                if (requestWrapper.crmContactId != null) {
                    responseWrapper.applicant = AgentPortalServices.getApplicantDetails(requestWrapper.crmContactId);
                }
                if (requestWrapper.applicantName != null) {
                    responseWrapper.pageSize = requestWrapper.searchLimit;
                    responseWrapper.pageOffset = requestWrapper.searchOffset;
                    responseWrapper.applicants = AgentPortalServices.searchApplicants(requestWrapper.applicantName, AgentPortalConstants.MAX_SEARCH_LIMIT, AgentPortalConstants.DEFAULT_SEARCH_OFFSET);
                }
            }
        } catch (Exception ex) {
            // set Error response 
            responseWrapper.exceptionRecord = ex;
            // Log the exception
            LogUtilityException.logException(ex, 'Failed to find Applicant for Id: ' + requestWrapper.crmContactId);
        }

        // Construct Response
        RestContext.response.responseBody = responseWrapper.responseBody;
    }
    /**
	 * @description     Updates an Applicant
	 * @param           JSON that can be serialized into AgentPortalPayload.UpdateApplicantRequest object
	 * @return          JSON that follows AgentPortalPayload.UpdateApplicantResponse object
	 */
    @HttpPatch
    global static void handleUpdateApplicant() {
        //Initialize 
        AgentPortalPayload.UpdateApplicantRequest requestWrapper;
        AgentPortalPayload.UpdateApplicantResponse responseWrapper = new AgentPortalPayload.UpdateApplicantResponse();
        RestRequest request = RestContext.request;
        RestContext.response.addHeader('Content-Type', 'application/json');
       
        try {
            //deserialize request
            requestWrapper = new AgentPortalPayload.UpdateApplicantRequest(request.requestBody.toString());
            if (fs.Enable_Detailed_Logs_for_APNG__c) {
                LogUtilityException.logExceptionMSG('ApplicantWebService', 'handleUpdateApplicant', request.requestBody.toString());
            }
            // check validity of request
            if (requestWrapper.isValid) {
                // update Contact and set to Response
                responseWrapper.contactRecord = AgentPortalServices.updateApplicant(requestWrapper.asContact());
            }
        } catch (Exception ex) {
            // set Error response 
            responseWrapper.exceptionRecord = ex;
            // Log the exception
            LogUtilityException.logException(ex, 'Failed to update Applicant');
        }

        // Construct Response
        RestContext.response.responseBody = responseWrapper.responseBody;
    }
}