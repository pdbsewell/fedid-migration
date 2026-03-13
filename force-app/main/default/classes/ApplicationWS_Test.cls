/**
 * @description       :
 * @author            : Ben Greenland
 * @group             :
 * @last modified on  : 2024-10-27
 * @last modified by  : Ben Greenland
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2024-10-04   Ben Greenland   Initial Version
 **/
@isTest(isParallel=false) // APEX_DATA_ACCESS_RESTRICTION // permission set assignment
public with sharing class ApplicationWS_Test {
	@TestSetup
	static void makeData() {
		TriggerCommon.disableTrigger('Country_Attribute__c');
		TriggerCommon.disableTrigger('Account');
		TriggerCommon.disableTrigger('Contact');
		TriggerCommon.disableTrigger('User');
		TriggerCommon.disableTrigger('Application__c');
		TriggerCommon.disableTrigger('Application_Course_Preference__c');
		TriggerCommon.disableTrigger('Course_Offering__c');

		// STEP 1 - create a test Agent Portal User
		AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();

		// STEP 2 - create a test Application (data model) as the portal user
		Contact con = AgentPortalTestDataBuilder.factory.createApplicantContact();
		con.First_Name__c = 'John';
		con.Last_Name__c = 'Wick';
		con.Salutation = 'Mr';
		con.Pronouns_V2__c = 'He/Him/His';
		con.Suffix = 'Jr';
		con.Preferred_Name__c = 'J';
		con.Gender__c = 'M';
		con.OtherStreet = '123 Some other st';
		con.OtherCity = 'Clayton';
		con.OtherState = 'Victoria';
		con.OtherCountry = 'Australia';
		con.OtherPostalCode = '3168';
		con.HomePhone = '04444444444';
		con.Previous_Surname__c = 'Some Previous Surname';
		con.Previous_Monash_ID__c = 'PREVIOUS_ID';
		con.Previously_Studied_at_Monash__c = false;
		con.Aboriginal_or_Torres_Strait_Islander__c = 'NO';
		con.CountryOfBirth__c = portalUser.country.Id; // DEFAULTS TO AUSTRALIA

		Course__c course = StudFirst_TestHelper.createCourse();
		insert course;
		Course_Offering__c co = StudFirst_TestHelper.createCourseOffering(course);
		insert co;
		//Share Course offering with the Agent user by Apex Managed sharing -To get around limitation as sharing rules are not evaluated in Test classes
		Course_offering__Share coshare = new Course_offering__Share();
		coshare.ParentId = co.Id;
		coshare.UserOrGroupId = portalUser.testUser.Id;
		coshare.AccessLevel = 'Read';
		coshare.RowCause = Schema.Course_offering__Share.RowCause.Manual;
		Database.insert(coshare, false);
		Qualification__c qual = StudFirst_TestHelper.createQualification('Master of puppets');
		insert qual;
		// create an Application outside the builder so we can set status to Submitted
		Application__c sObjApp = AgentPortalTestDataBuilder.factory.createApplication(null);

		AgentPortalTestDataBuilder.Application testApplication = new AgentPortalTestDataBuilder.Application()
			.withAgent(portalUser)
			.withApplicant(con)
			.withCourseOffering(co)
			.withApplication(sObjApp)
			.build();

		TriggerCommon.enableTrigger('Application__c');
		TriggerCommon.enableTrigger('Application_Course_Preference__c');
		TriggerCommon.enableTrigger('Country_Attribute__c');
		TriggerCommon.enableTrigger('Account');
		TriggerCommon.enableTrigger('Contact');
		TriggerCommon.enableTrigger('User');
		TriggerCommon.enableTrigger('Course_Offering__c');

		/**
		 * STEP 3 - build Person 360 for the Applicant
		 * Affiliations and CPAs are important so the Agent gets access to the Contact.
		 */
		Person360.Person360Builder p360Builder = new Person360.Person360Builder(con);
		// Affiliation
		p360Builder.withAffiliation(testApplication.applicantAffiliation);
		// Contact Points
		p360Builder.buildAddress()
			.withClassification('Private')
			.withStreetName(con.MailingStreet)
			.withCity(con.MailingCity)
			.withCountry(con.MailingCountry)
			.withState(con.MailingState)
			.withPostCode(con.MailingPostalCode);
		p360Builder.buildEmail().withClassification('Private').withEmailId(con.Email);
		p360Builder.buildPhone().withClassification('Private').withPhoneNumber(con.Phone);
		// finalise - build and commit
		Person360 p360 = p360Builder.build();
		BaseClass bc = new Person360BuilderDirector().resolveDependencies(p360).getBaseClass();
		Boolean isSuccess = bc.commitRecords();
		Assert.isTrue(isSuccess, 'Unable to create Person 360 records for the Applicant');
	}

	@isTest
	static void apngHandleGetShouldReturnPositiveResponseWhenGetByName() {
		// GIVEN : a Rest Request for Get Applicant API
		Application__c app = [
			SELECT Id, Name, External_Reference_Id__c
			FROM Application__c
			LIMIT 1
		];
		// Set HTTP context
		RestRequest req = new RestRequest();
		req.params.put('applicationId', app.Name);
		RestResponse res = new RestResponse();
		req.requestURI = '/v3/ApplicationWebService';
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;

		User agentUser = AgentPortalTestDataFactory.util.getAgentUser();
		APNGApplicationPayload.GetResponseApplication respObj;
		req.requestBody = Blob.valueOf(JSON.serialize(req));

		Test.startTest();
		// WHEN : Get Applicant API is invoked by an APNG user
		System.runAs(agentUser) {
			ApplicationWS.handleGet();

			respObj = (APNGApplicationPayload.GetResponseApplication) JSON.deserialize(
				RestContext.response.responseBody.toString(),
				APNGApplicationPayload.GetResponseApplication.class
			);
		}
		Test.stopTest();

		// THEN : assert that the right contact was returned
		Assert.areEqual(true, respObj.success, 'Invalid return value');
		Assert.areEqual(app.Id, respObj.application.details.Id, 'Invalid return value');
	}
	@isTest
	static void apngHandleGetShouldReturnNegativeBadName() {
		// GIVEN : a nonexistant Applicationname
		String badName = 'bandName';
		// Set HTTP context
		RestRequest req = new RestRequest();
		req.params.put('applicationId', badName);
		RestResponse res = new RestResponse();
		req.requestURI = '/v3/ApplicationWebService';
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;

		User agentUser = AgentPortalTestDataFactory.util.getAgentUser();
		APNGApplicationPayload.PostResponse respObj;

		Test.startTest();
		// WHEN : Get Applicant API is invoked by an APNG user
		System.runAs(agentUser) {
			ApplicationWS.handleGet();
			respObj = (APNGApplicationPayload.PostResponse) JSON.deserialize(
				RestContext.response.responseBody.toString(),
				APNGApplicationPayload.PostResponse.class
			);
		}
		Test.stopTest();
		// THEN : assert that the right contact was returned
		Assert.areEqual(404, respObj.statusCode, 'Unexpected response');
	}
	@IsTest
	static void testProcessRequest() {
		// GIVEN
		User agentUser = AgentPortalTestDataFactory.util.getAgentUser();

		System.runAs(agentUser) {
			// Create a test contact
			Contact testContact = [SELECT Id, CRM_ID__C FROM Contact LIMIT 1];

			// Create a mock request
			RestRequest req = new RestRequest();
			RestResponse res = new RestResponse();

			// Create a valid PostRequest
			APNGApplicationPayload.PostRequest postRequest = new APNGApplicationPayload.PostRequest();
			postRequest.contactId = testContact.CRM_ID__C;
			postRequest.campusLocation = 'Australia';
			postRequest.residencyStatus = 'DOM-SUN.A';

			// Create Email without constructor
			CommonWSPayload.Email testEmail = new CommonWSPayload.Email();
			testEmail.email = 'test@example.com';
			testEmail.type = 'Personal';
			postRequest.email = new List<CommonWSPayload.Email>{ testEmail };

			// Create Phone without constructor
			CommonWSPayload.Phone testPhone = new CommonWSPayload.Phone();
			testPhone.phoneNumber = '1234567890';
			testPhone.type = 'Mobile';
			postRequest.phone = new List<CommonWSPayload.Phone>{ testPhone };

			// Serialize the request and set it as the request body
			String jsonBody = JSON.serialize(postRequest);
			req.requestBody = Blob.valueOf(jsonBody);
			req.httpMethod = 'POST';

			// Set up the RestContext
			RestContext.request = req;
			RestContext.response = res;

			// WHEN
			Test.startTest();
			ApplicationWS.handlePost();
			Test.stopTest();

			// THEN
			// Deserialize the response
			String responseBody = res.responseBody.toString();
			APNGApplicationPayload.PostResponse response = (APNGApplicationPayload.PostResponse) JSON.deserialize(
				responseBody,
				APNGApplicationPayload.PostResponse.class
			);
			// Assert the response
			Assert.isNotNull(response, 'Response should not be null');
			Assert.isNotNull(response?.application, 'Application in response should not be null');
			Assert.isNotNull(response.application.id, 'Application ID should not be null');
			Assert.areEqual(true, response.success, 'Status code should be 201 (Created)');
		}
	}

	/**
	 * @description Test APNG POST
	 * @author Ben Greenland | 2024-09-04
	 **/
	@IsTest
	private static void testHandlePost() {
		//GIVEN AN agent user
		User agentUser = AgentPortalTestDataFactory.util.getAgentUser();
		System.runAs(agentUser) {
			Test.startTest();
			RestRequest req = new RestRequest();
			RestResponse res = new RestResponse();
			req.requestURI = '/v3/ApplicationWebService';
			req.httpMethod = 'POST';
			req.requestBody = Blob.valueOf('{"test":"test"}');

			RestContext.request = req;
			RestContext.response = res;
			//WHEN i create a post request
			ApplicantWS.handlePost();
			//THEN resosnse not null
			Assert.isNotNull(RestContext.response, 'response null');
			Test.stopTest();
		}
	} /**
	 * @description Test APNG POST
	 * @author Ben Greenland | 2024-09-04
	 **/
	@IsTest
	private static void testHandlePatch() {
		//GIVEN AN agent user
		User agentUser = AgentPortalTestDataFactory.util.getAgentUser();
		System.runAs(agentUser) {
			Test.startTest();
			RestRequest req = new RestRequest();
			RestResponse res = new RestResponse();
			req.requestURI = '/v3/ApplicationWebService';
			req.httpMethod = 'PATCH';
			req.requestBody = Blob.valueOf('{"test":"test"}');

			RestContext.request = req;
			RestContext.response = res;
			//WHEN i create a post request
			ApplicantWS.handlePatch();
			//THEN resosnse not null
			Assert.isNotNull(RestContext.response, 'response null');
			Test.stopTest();
		}
	}
}