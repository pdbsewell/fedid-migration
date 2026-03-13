/**
 * @Class              : ApplicationDocumentsWebService.cls
 * @Description        : Webservice class for Managing Application's Documents
 * @Author             : Ken McGuire
 * @Group              : Admissions
 * @Revision           : 2023-07-28     Ken McGuire   Created 
 */
@RestResource(urlMapping='/v2/ApplicationDocumentsWebService')
global with sharing class ApplicationDocumentsWebService {
    /**
	 * @description     Lists all Application Document(s) based on filter criteria. Supports sort and pagination 
	 * @param           JSON that can be serialized into AgentPortalPayload.ListApplicationDocumentsRequest object
	 * @return          JSON that follows AgentPortalPayload.ListApplicationDocumentsResponse object
	 */
    @HttpGet
    global static void getDocumentChecklist() {
        //Initialize 
        AgentPortalPayload.ListApplicationDocumentsRequest requestWrapper;
        AgentPortalPayload.ListDocumentChecklistResponse responseWrapper = new AgentPortalPayload.ListDocumentChecklistResponse();
        RestRequest request = RestContext.request;
        RestContext.response.addHeader('Content-Type', 'application/json');
        
        try {
            //deserialize request
            requestWrapper = new AgentPortalPayload.ListApplicationDocumentsRequest(request.params);
            Nebula.Logger.info('requestWrapper ' + requestWrapper);

            // set Contact to Response
            if (requestWrapper.isValid){

                // Build checkilst
                DocumentChecklistAssessmentServices.runRules('Application Assessment', requestWrapper.application.id);
                // set the response
                responseWrapper.DocumentationChecklist = requestWrapper.process();
            }
        } catch (Exception ex) {
            // set Error response 
            responseWrapper.exceptionRecord = ex;
            // Log the exception
            Nebula.logger.error( 'Failed to find Application Document for Application:'+ ex.getMessage(), ex);
        }

        // Construct Response
        RestContext.response.responseBody = responseWrapper.responseBody;
        Nebula.Logger.info('responseBody ' + responseWrapper.responseBody);
        Nebula.Logger.saveLog();
    }
}