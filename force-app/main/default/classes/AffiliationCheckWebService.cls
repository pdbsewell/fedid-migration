/**
 * @Class              : AffiliationCheckWebService.cls
 * @Description        : Webservice class for resolving Affiliation checks between Contacts and Agents. 
 *                       Complete details on https://docs.google.com/spreadsheets/d/1QGJ4Wnme_wOp1TY5oFqUIVdMKB0CgQ0aWt4OTBcIrlw/edit#gid=0
 * @Author             : Vinothraja
 * @Group              : Admissions
 * @Revision           : 
 * 2023-02-17     Vinothraja   Created 
 * 2023-11-22     Vinothraja   Added logging of API requests
 */
@RestResource(urlMapping='/v2/AffiliationCheckWebService')
global with sharing class AffiliationCheckWebService {
    static Feature_Switch__c fs = Feature_Switch__c.getInstance();
    /**
	 * @description     Checks whether the contact and agent can be affiliated or not
	 * @param           JSON that can be serialized into AgentPortalPayload.CheckAffiliationRequest object
	 * @return          JSON that follows AgentPortalPayload.CheckAffiliationResponse object
	 */
    @HttpGet
    global static void checkAffiliation() {
        //Initialize 
        RestRequest request = RestContext.request;
        AgentPortalPayload.CheckAffiliationRequest requestWrapper = new AgentPortalPayload.CheckAffiliationRequest(request.params);
        AgentPortalPayload.CheckAffiliationResponse responseWrapper = new AgentPortalPayload.CheckAffiliationResponse();
        RestContext.response.addHeader('Content-Type', 'application/json');
       
        try {
            if (fs.Enable_Detailed_Logs_for_APNG__c) {
                LogUtilityException.logExceptionMSG('ApplicantWebService', 'handleGetApplicantDetails', JSON.serializePretty(request.params));
            }
            // set Affiliation Status to Response
            if (requestWrapper.isValid){
                responseWrapper.affiliationStatus = new AffiliationCheckService(requestWrapper.contactId, requestWrapper.agencyId, requestWrapper.campusLocation, null).result;
            }
        } catch (Exception ex) {
            // set Error response 
            responseWrapper.exceptionRecord = ex;
            // Log the exception
            LogUtilityException.logException(ex, 'Failed to check Affiliations for: ' + requestWrapper.contactId);
        }

        // Construct Response
        RestContext.response.responseBody = responseWrapper.responseBody;
    }
}