/**
 * @description Test class for AgentManagementWebService
 * @date        27/09/2023  
 * @author      Vinothraja
 * @group       Admissions
 * @revision
 *  APR.09.2024     Nick Guia        - added test coverage for GET method
 *  MAY.07.2024     Kai-Fan Hsieh    - added code to populate contact firstname and lastname OOTB fields
 */
@isTest(isParallel=true)
public with sharing class AgentManagementWebService_Test {

    @TestSetup
    static void makeData() {

        AgentPortalTestDataFactory factory = new AgentPortalTestDataFactory();

        TriggerCommon.disableTrigger('Country_Attribute__c');
        TriggerCommon.disableTrigger('Account');
        TriggerCommon.disableTrigger('Contact');
        TriggerCommon.disableTrigger('User');

        // STEP 1 - Create Agent Onboarding Settings
       	insert AgentPortalTestDataBuilder.factory.createAgentOnboardingSettings();

        // STEP 2 - Create a test Agent Portal User
        AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();
        // reuse the same country as the portal user, so we don't have to recreate
        Account delegatorAgency = factory.createAgencyAccount(portalUser.country); 
        delegatorAgency.Name = 'Delegator Agency';
        insert delegatorAgency;

        // create an account partner
        List<AccountPartner>  apList = new List<AccountPartner>();
        AccountPartner ap = new AccountPartner(
            AccountFromId = portalUser.acc.Id,
            AccountToId = delegatorAgency.Id,
            Role = 'Delegator'
        );
        apList.add(ap);
        insert ap; // this auto creates the inverse relationship

        TriggerCommon.enableTrigger('Country_Attribute__c');
        TriggerCommon.enableTrigger('Account');
        TriggerCommon.enableTrigger('Contact');
        TriggerCommon.enableTrigger('User');
    }

    /**
     * @description when a null parameter is provided on GET, the response JSON should indicate
     * that this is not allowed.
     */
    @isTest
    static void handleGetShouldReturnErrorResponseWhenParameterIsNull() {

        // GIVEN : a rest request with null parameter
        RestRequest req = new RestRequest();
        req.httpMethod = 'GET';
        req.params.put('userName', null);

        RestResponse resp = new RestResponse();
        
        RestContext.request = req;
        RestContext.response = resp;


        Test.startTest();

        // WHEN : handleGet
        AgentManagementWebService.handleGet();

        Test.stopTest();

        // THEN : validate response
        String responseBodyStr = RestContext.response.responseBody.toString();
        APNG_WebServicePayload.APNG_AgentManagementWebService_GetResponse responseObj = (APNG_WebServicePayload.APNG_AgentManagementWebService_GetResponse) JSON.deserialize(
            responseBodyStr, 
            APNG_WebServicePayload.APNG_AgentManagementWebService_GetResponse.class
        );
        Assert.areEqual(false, responseObj.success, 'Unexpected response value');
        Assert.areEqual('Invalid null parameter for username', responseObj.description, 'Unexpected response value');
    }

    /**
     * @description test that the GET method would return a positive response
     */
    @isTest
    static void handleGetShouldReturnPositiveResponse() {

        // GIVEN : a rest request with the agent's username
        User agentUser = AgentPortalTestDataFactory.util.getAgentUser();

        RestRequest req = new RestRequest();
        req.httpMethod = 'GET';
        req.params.put('userName', agentUser.Username);

        RestResponse resp = new RestResponse();
        
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();

        // WHEN : handleGet
        System.runAs(agentUser) {
            AgentManagementWebService.handleGet();
        }

        Test.stopTest();

        // THEN : validate response
        String responseBodyStr = RestContext.response.responseBody.toString();
        APNG_WebServicePayload.APNG_AgentManagementWebService_GetResponse responseObj = (APNG_WebServicePayload.APNG_AgentManagementWebService_GetResponse) JSON.deserialize(
            responseBodyStr, 
            APNG_WebServicePayload.APNG_AgentManagementWebService_GetResponse.class
        );
        Assert.areEqual(agentUser.Id, responseObj.userRecord?.Id, 'Unexpected user detail');
        Assert.isTrue(responseObj.userLoginList.isEmpty(), 'Unexpected frozen user');
        Assert.areEqual(agentUser.Contact.Id, responseObj.contactRecord.Id, 'Unexpected contact Id');
        Assert.areEqual(agentUser.Contact.AccountId, responseObj.accountRecord.Id, 'Unexpected account Id');
        // there should only be 1 based on test setup
        Assert.areEqual(1, responseObj.accountPartnerList.size(), 'Unexpected number of account partners'); 
    }

    /**
    * @description Test checking creation of Agency Contact - Positive Scenario
    */ 
    @isTest
    private static void shouldAllowCreationOfAgencyContactsByAuthorisedAgent() {
        // GIVEN
		// A Branch Manager
		User agent = AgentPortalTestDataFactory.util.getAgentUser();
        // A Valid Payload
        AgentPortalPayload.CreateAgentRequest car = AgentPortalTestDataBuilder.factory.createAgentRequest();
        String response;
		System.runAs(agent){
			Test.startTest();
                // WHEN
                // The BM creates an Agent (Contact) for the Agency
                try {
                    AgentPortalTestDataBuilder.AgentPayload agentPayload = new AgentPortalTestDataBuilder.AgentPayload()
                                                                        .setParam('requestType', 'createContact')
                                                                        .setHttpMethod('POST')
                                                                        .setRequestBody(car);
                    AgentManagementWebService.createAgent();
                    response = agentPayload.getResponse();
                } catch(Exception ex) {
                    Assert.isTrue(true, ex.getMessage() );	        
                }
            Test.stopTest();
       	}
        
        // THEN
        // The Agency Contact is created
        // WebService Response check
		Map<String, Object> mapResponse = (Map<String, Object>) JSON.deserializeUntyped(response);
        Assert.areEqual(mapResponse.get('message'),'Contact successfully created!', 'Agency Contact is not created' );
        Map<String, Object> con = (Map<String, Object>) mapResponse.get('AgentManagement');
        Assert.areEqual((String)con.get('First_Name__c'),car.agent.firstName, 'Agency Contact is not created' );
        // Record check
        Assert.isFalse([SELECT id FROM Contact WHERE email = 'frrank.7@testemail.com' LIMIT 1]?.isEmpty(), 'Agency Contact is not created' );
    }
    /**
    * @description Test checking creation of Agency Contact - Negative Scenario
    * Non Delegated Admins trying to create Agents
    */ 
    @isTest
    private static void shouldNotAllowUnauthorisedAgentToCreateAgencyContacts() {
		// GIVEN
		// A non - Delegated Admin
		User agent = AgentPortalTestDataFactory.util.getAgentUser();
        TriggerCommon.disableTrigger('Contact');
            Contact agentContact = new Contact(id = agent.ContactId, Agency_Contact_Roles__c = 'Counsellor');
            update agentContact;
        TriggerCommon.enableTrigger('Contact');
        // A Payload to create an Agent
        AgentPortalPayload.CreateAgentRequest car = AgentPortalTestDataBuilder.factory.createAgentRequest();
        System.runAs(agent){
            Test.startTest();
            	// WHEN
            	// An Agent Contact is created
                try {
                    AgentPortalTestDataBuilder.AgentPayload agentPayload = new AgentPortalTestDataBuilder.AgentPayload()
                                                                        .setParam('requestType', 'createContact')
                                                                        .setHttpMethod('POST')
                                                                        .setRequestBody(car);
                    AgentManagementWebService.createAgent();
                } catch(AgentPortalPayload.BadRequestException ex) {
                    // THEN
                    // Create Agency contact fails
                    // WebService Response check
                    Assert.areEqual(ex.getMessage(), 'You are not authorised to create Users under this Agency', 'Unauthorised Agent is able to create Agency contacts' );	        
                }
            Test.stopTest();
        }
        
        // THEN
        // Create Agent contact fails
        // Record check
        Assert.isTrue([SELECT id FROM Contact WHERE email = 'frrank.7@testemail.com' AND lastName = 'Seven' LIMIT 1]?.isEmpty(), 'Unauthorised Agent is able to create Agency contacts' );
    }
    /**
    * @description Test checking creation of Agency Contact - Negative Scenario
    * Trying to create Branch Managers
    */ 
    @isTest
    private static void shouldNotAllowAgentsToCreateBranchManagers() {
		// GIVEN
		// A Delegated Admin
		User agent = AgentPortalTestDataFactory.util.getAgentUser();
        // A Payload to create an Agency Contact
        AgentPortalPayload.CreateAgentRequest car = AgentPortalTestDataBuilder.factory.createAgentRequest();
        car.agent.roles = new List<String> {'Counsellor', 'Branch Manager'}; // Role as Branch Manager

        System.runAs(agent){
	        Test.startTest();
                // WHEN
                // A Branch Manager is created
                try {
                    AgentPortalTestDataBuilder.AgentPayload agentPayload = new AgentPortalTestDataBuilder.AgentPayload()
                                                                        .setParam('requestType', 'createContact')
                                                                        .setHttpMethod('POST')
                                                                        .setRequestBody(car);
                    AgentManagementWebService.createAgent();
                } catch(AgentPortalPayload.BadRequestException ex) {
                    // THEN
                    // Create Agency contact fails
                    // WebService Response check
                    Assert.areEqual(ex.getMessage(), 'Branch Managers and Principal Agents cannot be created from Portal', 'Agents are able to create Branch Managers' );	        
                }
            Test.stopTest();
        }
        
        // THEN
        // Create Agent contact fails
        // Record check
        Assert.isTrue([SELECT Agency_Contact_Roles__c FROM Contact WHERE email = 'frrank.7@testemail.com' LIMIT 1]?.isEmpty(), 'Agents are able to create Branch Managers' );
    }
    /**
    * @description Test checking creation of Agency Contact - Negative Scenario
    * Trying to create duplicate Agents
    */ 
    @isTest
    private static void shouldNotCreateDuplicateAgent() {
		// GIVEN
		// A Delegated Admin
		User agent = AgentPortalTestDataFactory.util.getAgentUser();
        
        // A Payload to create an Agency Contact
        AgentPortalPayload.CreateAgentRequest car = AgentPortalTestDataBuilder.factory.createAgentRequest();
        AgentPortalPayload.Email officialEmail = new AgentPortalPayload.Email();
        officialEmail.type = 'Official';
        officialEmail.email = 'TestEmail@testemail.com'; // an existing user's email
        car.agent.email= new List<AgentPortalPayload.Email> {officialEmail};

        System.runAs(agent){
	        Test.startTest();
				// WHEN
				// An agent with duplicate email id is created
                try {
                    AgentPortalTestDataBuilder.AgentPayload agentPayload = new AgentPortalTestDataBuilder.AgentPayload()
                                                                        .setParam('requestType', 'createContact')
                                                                        .setHttpMethod('POST')
                                                                        .setRequestBody(car);
                    AgentManagementWebService.createAgent();
                } catch(AgentPortalPayload.BadRequestException ex) {
                    // THEN
                    // Create Agency contact fails
                    // WebService Response check
                    Assert.areEqual(ex.getMessage(),'Another agent with the same email already exists', 'Agents are able to create Duplicate Agents' );
                }
	        Test.stopTest();
        }
        
        // THEN
        // Create Agency contact fails
        // Record check
        Assert.isTrue([SELECT id, Agency_Contact_Roles__c FROM Contact WHERE email = 'TestEmail@testemail.com' AND lastName = 'five' LIMIT 1]?.isEmpty(), 'Agents are able to create Duplicate Agents' );
    }    
    /**
    * @description Test checking creation of Agency User - Positive Scenario
    */ 
    @isTest
    private static void delegatedAdminsCanCreateAgents() {
        // GIVEN
        // A Valid Agent - Delegated Admin
		User agent = AgentPortalTestDataFactory.util.getAgentUser();
        // A Valid Agency Contact
        Contact agencyContact = getAgencyContact(agent.Contact.AccountId);
        String response;
        AgentPortalTestDataBuilder.AgentPayload agentPayload;

        System.runAs(agent){
            insert agencyContact;
            // A valid Payload
            agentPayload = new AgentPortalTestDataBuilder.AgentPayload()
                            .setParam('contactId', agencyContact.Id)
                            .setParam('requestType', 'enableAsUser')
                            .setHttpMethod('POST');

            Test.startTest();
            	// WHEN
            	// Enables the contact as user
    	        AgentManagementWebService.createAgent();
            	response = agentPayload.getResponse();
	        Test.stopTest();
        }
        
        // THEN
        // The User is successfully created
        // WebService Response check
		Map<String, Object> mapResponse = (Map<String, Object>) JSON.deserializeUntyped(response);
        Assert.areEqual(mapResponse.get('message'),'User successfully created!', 'Valid Agent is not created' );
        Map<String, Object> usr = (Map<String, Object>) mapResponse.get('AgentManagement');
        Assert.areEqual((String)usr.get('FirstName'),agencyContact.First_Name__c, 'Valid Agent is not created' );
        // Record check
        Assert.isFalse([SELECT id FROM User WHERE Email = 'frrank.7@testemail.com' LIMIT 1]?.isEmpty(), 'Valid Agent is not created' );
    }
    /**
    * @description Test checking creation of Agency User - Negative Scenario
    * Duplicate user check
    */ 
    @isTest
    private static void shouldNotCreateDuplicateUsers() {
        // GIVEN
        // A Valid Agent
		User agent = AgentPortalTestDataFactory.util.getAgentUser();
        // A Valid contact and a duplicate contact
        Contact agencyContact =getAgencyContact(agent.Contact.AccountId);
        Contact duplicateContact = getAgencyContact(agent.Contact.AccountId);
        AgentPortalTestDataBuilder.AgentPayload agentPayload;
        String response;
        System.runAs(agent){
            insert new List<Contact> {agencyContact, duplicateContact};
            agentPayload = new AgentPortalTestDataBuilder.AgentPayload()
                            .setParam('contactId', agencyContact.Id)
                            .setParam('requestType', 'enableAsUser')
                            .setHttpMethod('POST');
            // First contact enabled as user
            AgentManagementWebService.createAgent();
            
            Test.startTest();
            	// WHEN
            	// Duplicate contact is enabled as user
	            agentPayload.setParam('contactId', duplicateContact.Id);
    	        AgentManagementWebService.createAgent();
            	response = agentPayload.getResponse();
	        Test.stopTest();
        }
		
        // THEN
        // User creation fails
        // WebService Response check
        Map<String, String> mapResponse = (Map<String, String>) JSON.deserialize(response, Map<String, String>.class);
        Assert.areEqual(mapResponse.get('message'),'Email/Username already exists', 'Duplicate user is created' );
        // Record check
        Assert.isTrue([SELECT id FROM User WHERE contactId =: duplicateContact.Id]?.isEmpty(), 'Duplicate user is created' );
    }
    /**
    * @description Test checking managing Agency User - Positive Scenario
    * Changing Contact details
    */ 
    @isTest
    private static void canUpdateAgencyContactDetails() {
        // GIVEN
        // A Valid Agent
		User agent = AgentPortalTestDataFactory.util.getAgentUser();

        // A Valid Agency Contact
        Contact agencyContact = getAgencyContact(agent.Contact.AccountId);

        String response;
        AgentPortalPayload.ManageAgentRequest mar;
        System.runAs(agent){
            insert agencyContact;
	        Test.startTest();
                // A Payload to update an Agent
                mar = AgentPortalTestDataBuilder.factory.manageAgentRequest(agencyContact.Id);
                AgentPortalPayload.Email officialEmail = new AgentPortalPayload.Email();
                officialEmail.type = 'Official';
                officialEmail.email = 'frrank.8@testemail.com'; 
                mar.agent.email= new List<AgentPortalPayload.Email> {officialEmail};
                mar.agent.roles = new List<String> {'Counsellor'};
                // WHEN
                // The Agency Contact is updated - Details
                AgentPortalTestDataBuilder.AgentPayload agentPayload = new AgentPortalTestDataBuilder.AgentPayload()
                                                                        .setHttpMethod('PATCH')
                                                                        .setRequestBody(mar);
                AgentManagementWebService.manageAgent();
            	response = agentPayload.getResponse();
	        Test.stopTest();        
        }
        
        // THEN
        // The Agency Contact's details are updated
        // WebService Response check
		Map<String, Object> mapResponse = (Map<String, Object>) JSON.deserializeUntyped(response);
        Assert.areEqual(mapResponse.get('message'),'Agent successfully updated!', 'Agency Contact details are not updated' );
        Map<String, Object> con = (Map<String, Object>) mapResponse.get('AgentManagement');
        Assert.areEqual('frrank.8@testemail.com', (String)con.get('Email'), 'Agency Contact details are not updated' );
        // Record check
        Assert.areEqual('frrank.8@testemail.com', [SELECT email FROM Contact WHERE id =:agencyContact.id LIMIT 1]?.email, 'Agency Contact details are not updated' );
    }
    /**
    * @description Test checking managing Agency User - Positive Scenario
    */ 
    @isTest
    private static void canUpdateAgencyContactRoles() {
        // GIVEN
        // A Valid Agent
		User agent = AgentPortalTestDataFactory.util.getAgentUser();

        // A Valid Agency Contact
        Contact agencyContact = getAgencyContact(agent.Contact.AccountId);

        AgentPortalPayload.ManageAgentRequest mar;
        String response;

        System.runAs(agent){
            insert agencyContact;
            AgentPortalTestDataBuilder.AgentPayload agentPayload = new AgentPortalTestDataBuilder.AgentPayload()
                                                                        .setParam('contactId', agencyContact.Id)
                                                                        .setParam('requestType', 'enableAsUser')
                                                                        .setHttpMethod('POST');
            AgentManagementWebService.createAgent();

	        Test.startTest();
                // A Payload to update an Agent
                mar = AgentPortalTestDataBuilder.factory.manageAgentRequest(agencyContact.Id);
                mar.agent.roles = new List<String> {'Counsellor', 'Delegated Admin'};
                agentPayload = new AgentPortalTestDataBuilder.AgentPayload()
                                                                        .setHttpMethod('PATCH')
                                                                        .setRequestBody(mar);

                // WHEN
                // The Agency Contact is updated - Adding Delegated Admin role
                AgentManagementWebService.manageAgent();
            	response = agentPayload.getResponse();
	        Test.stopTest();        
        }
        
        // THEN
        // The Agency Contact Role is updated
        // WebService Response check
		Map<String, Object> mapResponse = (Map<String, Object>) JSON.deserializeUntyped(response);
        Assert.areEqual(mapResponse.get('message'),'Agent successfully updated!', 'Agency Contact Role is not updated' );
        Map<String, Object> con = (Map<String, Object>) mapResponse.get('AgentManagement');
        Assert.isTrue(((String)con.get('Agency_Contact_Roles__c')).containsIgnoreCase('Delegated Admin'), 'Agency Contact Role is not updated' );
        // Record check      
        String updatedRole = [SELECT Agency_Contact_Roles__c FROM Contact WHERE id = :agencyContact.id LIMIT 1]?.Agency_Contact_Roles__c;
        Assert.isTrue(updatedRole.containsIgnoreCase('Delegated Admin'), 'Agency Contact Role is not updated');
    }
    /**
    * @description Test checking managing Agency User - Positive Scenario
    * Freezing an user
    */ 
    @isTest
    private static void canFreezeUsers() {
        // GIVEN
        // A Valid Agent
		User agent = AgentPortalTestDataFactory.util.getAgentUser();

        // A Valid Agency Contact
        Contact agencyContact = getAgencyContact(agent.Contact.AccountId);
        
        // A Valid payload
		String response;
        User agentUser;
        System.runAs(agent){
            insert agencyContact;
	        Test.startTest();        
                AgentPortalTestDataBuilder.AgentPayload agentPayload = new AgentPortalTestDataBuilder.AgentPayload()
                                                                        .setParam('contactId', agencyContact.Id)
                                                                        .setParam('requestType', 'enableAsUser')
                                                                        .setHttpMethod('POST');
                AgentManagementWebService.createAgent();

                // WHEN
                // The Agency User is updated - Freeze User
                agentUser = [SELECT id FROM User WHERE email = 'frrank.7@testemail.com' LIMIT 1];
                try {
                    AgentPortalPayload.ManageAgentRequest mar = AgentPortalTestDataBuilder.factory.manageAgentRequest(agentUser.Id);
                    mar.agent.isFrozen = true;
                    agentPayload = agentPayload.setHttpMethod('PATCH').setRequestBody(mar);
	                AgentManagementWebService.manageAgent();                
	            	response = agentPayload.getResponse();
                } catch(Exception ex) {
                    Assert.isTrue(false, ex.getMessage());
                }
	        Test.stopTest();        
        }
        
        // THEN
        // The Agency User is Frozen
        // WebService Response check
		Map<String, Object> mapResponse = (Map<String, Object>) JSON.deserializeUntyped(response);
        Assert.areEqual(mapResponse.get('message'),'Agent successfully updated!', 'Agent is not frozen' );
        // Record check            
        Assert.isTrue([SELECT isFrozen FROM UserLogin WHERE UserId = :agentUser.Id]?.isFrozen, 'Agent is not frozen' );        
    }
    /**
    * @description Test checking managing Agency User - Positive Scenario
    * Deactivating an user
    */ 
    @isTest
    private static void canDeactivateUsers() {
        // GIVEN
        // A Valid Agent
		User agent = AgentPortalTestDataFactory.util.getAgentUser();

        // A Valid Agency Contact
        Contact agencyContact = getAgencyContact(agent.Contact.AccountId);
        // A Valid payload
		String response;
        User agentUser;
        System.runAs(agent){
            insert agencyContact;
	        Test.startTest();        
		        AgentPortalTestDataBuilder.AgentPayload agentPayload = new AgentPortalTestDataBuilder.AgentPayload()
                    														.setParam('contactId', agencyContact.Id)
												                            .setParam('requestType', 'enableAsUser');

                AgentManagementWebService.createAgent();
                                
                // WHEN
                // The Agency User is updated - Deactivation
                agentUser = [SELECT id FROM User WHERE email = 'frrank.7@testemail.com' LIMIT 1];
                try {
                    AgentPortalPayload.ManageAgentRequest mar = AgentPortalTestDataBuilder.factory.manageAgentRequest(agentUser.Id);
                    mar.agent.isActive = false;
                    agentPayload.setHttpMethod('PATCH').setRequestBody(mar);
	                AgentManagementWebService.manageAgent();                
	            	response = agentPayload.getResponse();
                } catch(Exception ex) {
                    Assert.isTrue(true, ex.getMessage());
                }
	        Test.stopTest();        
        }
        
        // THEN
        // The Agency User is deactivated
        // WebService Response check
		Map<String, Object> mapResponse = (Map<String, Object>) JSON.deserializeUntyped(response);
        Assert.areEqual(mapResponse.get('message'),'Agent successfully updated!', 'Agent is not deactivated' );
        // Record check
        Assert.isFalse([SELECT isActive FROM User WHERE id = :agentUser.Id LIMIT 1]?.isActive, 'Agent is not deactivated' );
    }     
    /**
    * @description Test checking managing Agency User - Negative Scenario
    * - When the requesting Agent is not authorised to manage Agents in an Agency
    */ 
    @isTest
    private static void shouldNotAllowUnauthorisedAgentToManageAgency() {
		// GIVEN
		// A Valid Agent - Not a Delegated Admin
		User agent = AgentPortalTestDataFactory.util.getAgentUser();
        TriggerCommon.disableTrigger('Contact');
        Contact agentContact = new Contact(id = agent.ContactId, Agency_Contact_Roles__c = 'Counsellor');
        update agentContact;
        TriggerCommon.enableTrigger('Contact');
		// A Valid Contact
        Contact agencyContact = getAgencyContact(agent.Contact.AccountId);
        // A Payload to update an Agent
        
        System.runAs(agent){
            insert agencyContact;
            
			// WHEN
			// A non-delegated Admin updates an Agent
			Test.startTest();
            try {
                    AgentPortalPayload.ManageAgentRequest mar = AgentPortalTestDataBuilder.factory.manageAgentRequest(agencyContact.Id);
                    mar.agent.firstName = 'Unfrank';
                    AgentPortalTestDataBuilder.AgentPayload agentPayload = new AgentPortalTestDataBuilder.AgentPayload()
                                                                                .setHttpMethod('PATCH').setRequestBody(mar);
	                AgentManagementWebService.manageAgent();
                } catch(AgentPortalPayload.BadRequestException ex) {
                    // THEN
                    // The Agent Contact is not updated
                    // WebService Response check
                    Assert.areEqual(ex.getMessage(),'You are not authorised to edit Users under this Agency', 'Unauthorised Agent is able to update other Agents');
                }
            Test.stopTest();
        }
        
        // THEN
        // The Agent Contact is not updated
        // Record check
        Assert.areEqual(agencyContact.FirstName, [SELECT First_Name__c FROM Contact WHERE id =:agencyContact.id LIMIT 1]?.First_Name__c , 'Unauthorised Agent is able to update other Agents' );
    }
    /**
    * @description Test checking managing Agency User - Negative Scenario
    * - When a Branch manager or Principal Agent is updated
    */ 
    @isTest
    private static void shouldNotAllowBMorPAToBeUpdated() {
		// GIVEN
		// A Valid Agent 
		User agent = AgentPortalTestDataFactory.util.getAgentUser();

        // A Valid Contact
        Contact agencyContactTwo = getAgencyContact(agent.Contact.AccountId);
        agencyContactTwo.Agency_Contact_Roles__c = 'Principal Agent;Counsellor';

        System.runAs(agent){
            insert agencyContactTwo;
                            
            Test.startTest();
                try {
                    // A Payload to update an Agent
                    AgentPortalPayload.ManageAgentRequest mar = AgentPortalTestDataBuilder.factory.manageAgentRequest(agencyContactTwo.Id);
                    mar.agent.roles = new List<String> {'Counsellor'};
                    AgentPortalTestDataBuilder.AgentPayload agentPayload = new AgentPortalTestDataBuilder.AgentPayload()
                                                                                .setHttpMethod('PATCH').setRequestBody(mar);
                    // WHEN
                    // A Branch manager or Principal Agent is updated
	                AgentManagementWebService.manageAgent();                             
                } catch(AgentPortalPayload.BadRequestException ex) {
                    // THEN
                    // Agency User is not updated
                    // WebService Response check
                    Assert.areEqual(ex.getMessage(),'Branch Managers and Principal Agents cannot be updated', 'BM/PA updated');
                }
            Test.stopTest();
        }
        
        // THEN
        // Agent Contact is not updated
        // Record check
        Assert.areEqual('Principal Agent;Counsellor'.toLowerCase(), [SELECT Agency_Contact_Roles__c FROM Contact WHERE id = :agencyContactTwo.id LIMIT 1]?.Agency_Contact_Roles__c.toLowerCase(), 'BM/PA updated' );
    }   
    /**
    * @description Test checking managing Agency User - Negative Scenario
    * - When a new Agent is created, with an existing user's email
    */ 
    @isTest
    private static void shouldNotAllowAgentUsersWithSameEmail() {
		// GIVEN
		// A Valid Agent 
		User agent = AgentPortalTestDataFactory.util.getAgentUser();

        // A Valid Contact
        Contact agencyContactTwo = getAgencyContact(agent.Contact.AccountId);

        // A Payload to update an Agent
        AgentPortalTestDataBuilder.AgentPayload agentPayload;

        System.runAs(agent){
            insert agencyContactTwo;

            Test.startTest();
				// Contact has a valid user
                agentPayload = new AgentPortalTestDataBuilder.AgentPayload()
                            .setParam('contactId', agencyContactTwo.Id)
                            .setParam('requestType', 'enableAsUser')
                            .setHttpMethod('POST');
                AgentManagementWebService.createAgent();
            	// WHEN
                // Updating email of a contact with existing user
                try {
                    AgentPortalPayload.ManageAgentRequest mar = AgentPortalTestDataBuilder.factory.manageAgentRequest(agencyContactTwo.Id);
                                        
                    AgentPortalPayload.Email officialEmail = new AgentPortalPayload.Email();
                    officialEmail.type = 'Official';
                    officialEmail.email = 'frrank.8@testemail.com';
                    mar.agent.email= new List<AgentPortalPayload.Email> {officialEmail};
                    mar.agent.roles = new List<String> {'Counsellor'};
                        
                    agentPayload.setHttpMethod('PATCH').setRequestBody(mar);
	                AgentManagementWebService.manageAgent();                
                } catch(AgentPortalPayload.BadRequestException ex) {
                    // THEN
                    // Agency User is not updated
                    // WebService Response check
                    Assert.areEqual(ex.getMessage(),'User already exists for this contact. Email cannot be updated', 'User updated with duplicate email');
                }
            Test.stopTest();
        }
        // THEN
        // Agency User is not updated
        // Record check
        Assert.areEqual('frrank.7@testemail.com', [SELECT email FROM Contact WHERE id =:agencyContactTwo.Id LIMIT 1]?.email, 'User updated with duplicate email' );
    }

    private static Contact getAgencyContact(Id accountId){
        String testFirstName = 'Frank';
        String testLastName = 'Lee';
        return new Contact(
            Salutation ='Mr',
            First_Name__c = testFirstName,
            FirstName = testFirstName,
            Last_Name__c = testLastName,
            LastName = testLastName,
            Email = 'frrank.7@testemail.com',
            Agency_Contact_Roles__c = 'Counsellor',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Agency Contact').getRecordTypeId(),
            AccountId = accountId);
    }
}