/**
 * @Class              : AgentManagementWebService.cls
 * @Description        : Webservice class to help Manage Agents in Agent Portal Next Gen
 * @Author             : Vinothraja
 * @Group              : Admissions
 * @Revision           : 
 * 2023-04-06     Vinothraja   Created 
 * 2023-11-22     Vinothraja   Added logging of API requests
 */
@RestResource(urlMapping='/v2/AgentManagementWebService')
global with sharing class AgentManagementWebService {

    static Feature_Switch__c fs = Feature_Switch__c.getInstance();

    /**
     * @description logic for handling GET requests within AgentManagementWebService.
     *  The method currently fetches the details of the user, related contact, agency, and AccountPartner records
     *  based on the username parameter
     */
    @HttpGet
    global static void handleGet() {
        RestRequest req = RestContext.request;
        APNG_WebServicePayload.APNG_AgentManagementWebService_GetResponse resp = new APNG_WebServicePayload.APNG_AgentManagementWebService_GetResponse();
        AgentManagementWebServiceHelper helper = new AgentManagementWebServiceHelper();

        try {
            /**
             * username may contain special characters, therefore custom param is used rather than a URI
             * subdirectory so we don't have to bother decoding.
             */
            String userName = req.params.get('userName');
            /**
             * throw a descriptive exception message 
             */
            if(String.isBlank(userName)) {
                throw new AgentManagementWebServiceException('Invalid null parameter for username');
            }
            /**
             * query records and build response payload
             */
            resp = helper.handleGetResponse(userName);
            resp.success = true;
        } catch(AgentManagementWebServiceException e) {
            /**
             * for throwing specific exception messages that do not contain sensitive information
             */
            Nebula.Logger.error(e.getMessage());
            resp.success = false;
            resp.error = e.getTypeName();
            resp.description = e.getMessage(); 
        } catch(Exception e) {
            /**
             * for throwing system generated exceptions - provide a generic error message instead
             * so we don't inadvertently expose any sensitive information
             */
            Nebula.Logger.error(e.getMessage());
            resp = (APNG_WebServicePayload.APNG_AgentManagementWebService_GetResponse) helper.getErrorResponse(e);
        }
        Nebula.Logger.saveLog();
        /**
         * finalise the response
         */
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(resp, true)); // suppress null
    }

    /**
	 * @description     Post method to enable a Agency Contact as User
	 * @param           JSON that can be serialized into AgentPortalPayload.CreateAgentRequest object
	 * @return          JSON that follows AgentPortalPayload.CreateAgentResponse object
	 */
    @HttpPost
    global static void createAgent() {
    	//Initialize                                           
        RestRequest request = RestContext.request;
        AgentPortalPayload.CreateAgentRequest requestWrapper = new AgentPortalPayload.CreateAgentRequest(request.params);
        AgentPortalPayload.CreateAgentResponse responseWrapper;
        RestContext.response.addHeader('Content-Type', 'application/json');

        try {
            if (fs.Enable_Detailed_Logs_for_APNG__c) {  
                LogUtilityException.logExceptionMSG('AgentManagementWebService', 'createAgent', JSON.serializePretty(request.params));
            }
            if (requestWrapper.requestType.equalsIgnoreCase('createContact')) {
                responseWrapper = new AgentPortalPayload.CreateAgentResponse('Contact');
                AgentPortalPayload.CreateAgentRequest requestBody = (AgentPortalPayload.CreateAgentRequest) JSON.deserialize(request.requestBody.toString(), 
                                                                                                             AgentPortalPayload.CreateAgentRequest.class);
                requestWrapper.agent = requestBody.agent;
                if (requestWrapper.isValid){
                    responseWrapper.contactRecord = AgentPortalServices.createAgencyContact(requestWrapper.asContact());
                }
            } 
            if (requestWrapper.requestType.equalsIgnoreCase('enableAsUser')) {
                responseWrapper = new AgentPortalPayload.CreateAgentResponse('User');
                if (requestWrapper.isValid){
                    responseWrapper.userRecord = AgentPortalServices.createAgentUser(requestWrapper.asUser(), requestWrapper.agentContact);
                }
            } 
        } catch (Exception ex) {
            // set Error response 
            responseWrapper.exceptionRecord = ex;
            // Log the exception
            if (requestWrapper.requestType.equalsIgnoreCase('createContact')) {
                LogUtilityException.logException(ex, 'Failed to create an Agency contact: ' + requestWrapper.asContact()); 
            } 
            if (requestWrapper.requestType.equalsIgnoreCase('enableAsUser')) {
                LogUtilityException.logException(ex, 'Failed to create an Agency User for this contact: ' + requestWrapper.asUser()); 
            }
        }
        
        // Construct Response
        RestContext.response.responseBody = responseWrapper.responseBody;
    } 
    /**
     * @description     Patch method to manage the agency user
     * @param           JSON that can be serialized into AgentPortalPayload.ManageAgentRequest object
     * @return          JSON that follows AgentPortalPayload.EnableAgentUserResponse object
	 */
    @HttpPatch
    global static void manageAgent() {
        //Initialize 
        RestRequest request = RestContext.request;
        AgentPortalPayload.ManageAgentRequest requestWrapper;
        AgentPortalPayload.ManageAgentResponse responseWrapper = new AgentPortalPayload.ManageAgentResponse();
        RestContext.response.addHeader('Content-Type', 'application/json');
        
        try {
            // Deserialize request
            requestWrapper = (AgentPortalPayload.ManageAgentRequest) JSON.deserialize(request.requestBody.toString(), 
                                                                                                             AgentPortalPayload.ManageAgentRequest.class);

            if (fs.Enable_Detailed_Logs_for_APNG__c) {
                LogUtilityException.logExceptionMSG('AgentManagementWebService', 'manageAgent', request.requestBody.toString());
            }
            if (requestWrapper.isValid){
                if (requestWrapper.requestType.equalsIgnoreCase('updateContact')) {
                    // Allow updating Agency contacts
                    Contact agentContact = new Contact(id = requestWrapper.agent.crmRecordId); 
                    if (requestWrapper.agent.firstName != null) agentContact.First_Name__c = requestWrapper.agent.firstName;
                    if (requestWrapper.agent.lastName != null) agentContact.Last_Name__c = requestWrapper.agent.lastName;
                    if (requestWrapper.agent.email != null) agentContact.Email = requestWrapper.agent.agentEmail;
                    if (requestWrapper.agent.roles != null) agentContact.Agency_Contact_Roles__c = String.join(requestWrapper.agent.roles, ';');
                    AgentPortalServices.systemContext.patch(new List<SObject> {agentContact});
                    responseWrapper.result = agentContact;
                } else if (requestWrapper.requestType.equalsIgnoreCase('changeRole')) {
                    // Accept Role and name changes, for contacts with users - email changes disallowed
                    Contact agentContact = new Contact(id = requestWrapper.agent.crmRecordId, Agency_Contact_Roles__c = String.join(requestWrapper.agent.roles, ';'));
                    if (requestWrapper.agent.firstName != null) {agentContact.First_Name__c = requestWrapper.agent.firstName; agentContact.FirstName = requestWrapper.agent.firstName;}
                    if (requestWrapper.agent.lastName != null) {agentContact.Last_Name__c = requestWrapper.agent.lastName; agentContact.LastName = requestWrapper.agent.lastName;}
                    AgentPortalServices.systemContext.patch(new List<SObject> {agentContact});
                    responseWrapper.result = agentContact;
                } else if (requestWrapper.requestType.equalsIgnoreCase('updateUser')) {
                    List<sObject> resultObjects = new List<SObject> ();
                    // Freeze/unfreeze agents
                    resultObjects.add(AgentPortalServices.freezeUnFreezeUser(requestWrapper.agent.crmRecordId, requestWrapper.agent.isFrozen));
                    if (requestWrapper.agent.isActive != null && !requestWrapper.agent.isActive){ // Accept only de-activate requests
                        User agent = new User(id = requestWrapper.agent.crmRecordId, IsActive = false);
                        AgentPortalServices.systemContext.patch(new List<SObject> {agent});
                        resultObjects.add(agent);
                    }
                    responseWrapper.result = resultObjects;
                }
            }
        } catch (Exception ex) {
            // set Error response 
            responseWrapper.exceptionRecord = ex;
            // Log the exception
            LogUtilityException.logException(ex, 'Failed to update the Agency User/Contact'); 
        }

        // Construct Response
        RestContext.response.responseBody = responseWrapper.responseBody;
    } 

    global class AgentManagementWebServiceException extends Exception {}
}