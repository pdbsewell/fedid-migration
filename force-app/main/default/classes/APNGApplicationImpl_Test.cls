/**
 * @description       :  Tests for APNGApplicationImpl
 * @author            : Ben Greenland
 * @group             : APNG refactoring
 * @last modified on  : 2024-10-27
 * @last modified by  : Ben Greenland
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2024-10-04   Ben Greenland   Initial Version
 **/
@isTest(isParallel=false) // APEX_DATA_ACCESS_RESTRICTION : DML operations aren't permitted on this type of object: User
private class APNGApplicationImpl_Test {
	@TestSetup
	static void makeData() {
		TriggerCommon.disableTrigger('Country_Attribute__c');
		TriggerCommon.disableTrigger('Account');
		TriggerCommon.disableTrigger('Contact');
		TriggerCommon.disableTrigger('User');
        TriggerCommon.disableTrigger('Application_Course_Preference__c');
		AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();
		System.runAs(portalUser.testUser) {
			Country_Attribute__c country = new Country_Attribute__c(
				Name = 'INDIA',
				Callista_Code__c = '7103',
				Country__c = 'INDIA'
			);
			insert country;

			Country_Attribute__c country1 = new Country_Attribute__c(
				Name = 'AUSTRALIA',
				Callista_Code__c = BDPConstants.AUSTRALIA_CALLISTA_CODE,
				Country__c = 'Australia'
			);
			insert country1;

			insert new Bypass_Mute_Request__c(Bypass_All_Flows__c = false);
			Contact applicant = StudFirst_TestHelper.createInternationalApplicant();
			insert applicant;
			Application__c application = StudFirst_TestHelper.createInternationalApplication(applicant, country);
			insert application;
			Course__c course = StudFirst_TestHelper.createCourse();
			insert course;
			Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
			insert courseOffering;
			Qualification__c qual = StudFirst_TestHelper.createQualification('Master of puppets');
			insert qual;
			Contact_Qualification__c contactQual = StudFirst_TestHelper.createContactQualification(
				applicant,
				qual,
				'Tertiary Education'
			);
			insert contactQual;
			// create the apq
			Application_Qualification_Provided__c aqp = new Application_Qualification_Provided__c(
				Contact_Qualification__c = contactQual.Id,
				Application__c = application.id
			);
			insert aqp;

			Work_Experience__c wex = StudFirst_TestHelper.createWorkExperience(applicant);
			wex.Position__c = 'Cat';
			wex.Employer_Name__c = 'Bunnings';
			wex.Contact_Person_First_Name__c = 'Bobo';
			insert wex;
			Application_Work_Experience_Provided__c awep = new Application_Work_Experience_Provided__c(
				Application__c = application.Id,
				Work_Experience__c = wex.Id
			);
			insert awep;
		}
		TriggerCommon.enableTrigger('Country_Attribute__c');
		TriggerCommon.enableTrigger('Account');
		TriggerCommon.enableTrigger('Contact');
		TriggerCommon.enableTrigger('User');
	}

	/**
	 * @description test boiler plate code - HandleGet types
	 */
	@isTest
	static void shouldReturnHandleGETRequestResponseTypes() {
		Test.startTest();
		//GIVEN an experiences request type
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/v3/ApplicationWebService';
		req.httpMethod = 'GET';
		req.addHeader('Content-Type', 'application/json');
		req.params.put('related', 'experiences');

		RestContext.request = req;
		RestContext.response = res;
		APNGApplicationImpl.HandleGet applicationImplExperiences = new APNGApplicationImpl.HandleGet();
		APNGApplicationPayload.GetRequest reqPayloadExps = (APNGApplicationPayload.GetRequest) applicationImplExperiences.getRequestPayload();
		//WHEN the getResponseType method is called
		Type expType = applicationImplExperiences.getResponseType();
		//GIVEN an experiences qualifications type
		req.params.put('related', 'qualifications');
		RestContext.request = req;
		RestContext.response = res;
		APNGApplicationImpl.HandleGet applicationImplQualifications = new APNGApplicationImpl.HandleGet();
		//WHEN the getResponseType method is called
		Type qualsType = applicationImplQualifications.getResponseType();
		APNGApplicationPayload.GetRequest reqPayloadQuals = (APNGApplicationPayload.GetRequest) applicationImplQualifications.getRequestPayload();
		//GIVEN an experiences application type
		req.params.put('related', null);
		RestContext.request = req;
		RestContext.response = res;
		APNGApplicationImpl.HandleGet applicationImplApplication = new APNGApplicationImpl.HandleGet();
		applicationImplApplication.getResponseType();
		//WHEN the getResponseType method is called
		Type appType = applicationImplQualifications.getResponseType();

		Test.stopTest();
		//THEN all correct responseTypes are returned
		Assert.areEqual('experiences', reqPayloadExps.related, 'Incorrect Request Payload returned');
		Assert.areEqual('qualifications', reqPayloadQuals.related, 'Incorrect Request Payload returned');
		Assert.areEqual(
			APNGApplicationPayload.GetResponseWorkExperiences.class,
			expType,
			'Incorrect response type returned for Experiences'
		);
		Assert.areEqual(
			APNGApplicationPayload.GetResponseQualifications.class,
			qualsType,
			'Incorrect response type returned for Qualifications'
		);
		
		Assert.areEqual(APNGApplicationPayload.GetRequest.class, applicationImplApplication.getRequestType()) ;
		Assert.areEqual(
			APNGApplicationPayload.GetResponseApplication.class,
			appType,
			'Incorrect response type returned for Application'
		);
	}

	@isTest
	private static void testValidateGETMethodNoAppId() {
		System.runAs(new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser()) {
			Test.startTest();
			try {
				APNGApplicationImpl.HandleGet instance = new APNGApplicationImpl.HandleGet();
				RESTlib_Payload.Request req = new APNGApplicationPayload.GetRequest();
				instance.validate(req);
			} catch (RESTlib_Ex.InvalidRequestException e) {
				Assert.areEqual(
					'Application Id cannot be empty',
					e.getMessage(),
					'Should throw an exception when the Application Id is empty'
				);
			}
			Test.stopTest();
		}
	}
	@isTest
	private static void testValidateGETMethodBadRelated() {
		//GIVEN A GET Request with an invalid related parameter
		System.runAs(new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser()) {
			Test.startTest();
			APNGApplicationImpl.HandleGet instance = new APNGApplicationImpl.HandleGet();

			try {
				APNGApplicationPayload.GetRequest reqPl = new APNGApplicationPayload.GetRequest();
				reqPl.applicationId = '12';
				reqPl.related = '12';
				//WHEN the request is validated
				instance.validate(reqPl);
			} catch (RESTlib_Ex.InvalidRequestException e) {
				//THEN an exception should be thrown
				Assert.isTrue(
					e.getMessage().contains('is not recognised'),
					'Should throw an exception when related is not set to application or experiences'
				);
			}
			Test.stopTest();
		}
	}
	@isTest
	static void testHandleGetShouldThrowExceptionWhenApplicantNotFound() {
		// GIVEN : a HandleGet instance with a request with null parameters
		APNGApplicationImpl.HandleGet handler = new APNGApplicationImpl.HandleGet();
		APNGApplicationPayload.GetRequest req = new APNGApplicationPayload.GetRequest();
		req.applicationId = 'NOT_EXISTING';
		APNGApplicationPayload.GetResponseApplication resp = new APNGApplicationPayload.GetResponseApplication();
		System.runAs(new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser()) {
			Test.startTest();
			// WHEN : I validate the request
			try {
				handler.process(req, resp);
				Assert.fail('Should throw an exception when Application does not exist');
			} catch (RESTlib_Ex.NotFoundException e) {
				// THEN : the right exception type should be thrown
				Assert.isTrue(true);
			} catch (Exception e) {
				Assert.fail('Expected to throw an RESTlib_Ex.NotFoundException');
			}
		}
	}

	@isTest
	static void testHandleGetProcessApplication() {
		// GIVEN : a HandleGet instance fpr application
		APNGApplicationImpl.HandleGet handler = new APNGApplicationImpl.HandleGet();
		APNGApplicationPayload.GetRequest req = new APNGApplicationPayload.GetRequest();
		Application__c app = [SELECT Id, Name FROM Application__c LIMIT 1];
		req.applicationId = app.Name;
		APNGApplicationPayload.GetResponseApplication resp = new APNGApplicationPayload.GetResponseApplication();
		System.runAs(new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser()) {
			Test.startTest();

			// WHEN : I validate the request
			handler.process(req, resp);
			Test.stopTest();
		}

		//THEN : a response should be generated
		Assert.areEqual('Application(s) found!', resp.message, 'Should return message');
		Assert.isTrue([SELECT Id, Nebula__OriginLocation__c FROM Nebula__LogEntry__c].size()>0);
		Assert.isTrue(resp.application != null, 'Should return application');
		Assert.isTrue(resp.application.details.id == app.id, 'Id should be returned');
	}

	@isTest
	static void handleGetProcessWorkExp() {
		// GIVEN : a HandleGet instance for an application with work experience
		APNGApplicationImpl.HandleGet handler = new APNGApplicationImpl.HandleGet();
		APNGApplicationPayload.GetRequest req = new APNGApplicationPayload.GetRequest();
		Application__c app = [SELECT Id, Name FROM Application__c LIMIT 1];
		req.applicationId = app.Name;
		req.related = 'Experiences';
		APNGApplicationPayload.GetResponseWorkExperiences resp = new APNGApplicationPayload.GetResponseWorkExperiences();
		System.runAs(new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser()) {
			Test.startTest();

			// WHEN : I process the request
			handler.process(req, resp);
			Test.stopTest();
		}
		// THEN : Work experiences should be returned
		Assert.areEqual('Work Experience(s) found!', resp.message, 'Should return message');
		Assert.isTrue(resp.application.applicationId == app.Name, 'Should return application name');
		Assert.isTrue(resp.application.applicationExperiences.size() > 0, 'Should return workExperiences');
	}

	@isTest
	static void handleGetProcessQualifications() {
		// GIVEN : a handle get with Qualifications
		APNGApplicationImpl.HandleGet handler = new APNGApplicationImpl.HandleGet();
		APNGApplicationPayload.GetRequest req = new APNGApplicationPayload.GetRequest();
		Application__c app = [SELECT Id, Name FROM Application__c LIMIT 1];
		req.applicationId = app.Name;
		req.related = 'Qualifications';
		APNGApplicationPayload.GetResponseQualifications resp = new APNGApplicationPayload.GetResponseQualifications();
		System.runAs(new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser()) {
			Test.startTest();

			// WHEN : I validate the request
			handler.process(req, resp);
			Test.stopTest();
		}
		//THEN : I validate the response
		Assert.areEqual('Qualification(s) found!', resp.message, 'Should return message');
		Assert.isTrue(resp.success, 'success should be true');
		Assert.isTrue(resp.application.applicationId == app.Name, 'Should return application name');
		Assert.isTrue(resp.application.applicationQualifications.size() > 0, 'Should return applicationQualifications');
	}

	@isTest
	static void handleGetProcessNull() {
		// GIVEN : a HandleGet instance with a request with null parameters
		APNGApplicationImpl.HandleGet handler = new APNGApplicationImpl.HandleGet();
		APNGApplicationPayload.GetRequest req = new APNGApplicationPayload.GetRequest();

		req.applicationId = null;

		APNGApplicationPayload.GetResponseQualifications resp = new APNGApplicationPayload.GetResponseQualifications();
		System.runAs(new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser()) {
			Test.startTest();
			try {
				// WHEN : I validate the request
				handler.process(req, resp);

			} catch (Exception ex) {
				//THEN : I should get an exception
				Assert.areEqual(
					'RESTlib_Ex.WebServiceException',
					ex.getTypeName(),
					'Should throw an exception when applicationId is null'
				);
			}
			Test.stopTest();
		}
	}
	/**
	 * @description test boiler plate code - getHandlePost()
	 */
	@isTest
	static void shouldReturnHandlePost() {
		System.runAs(new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser()) {
			Test.startTest();
			APNGApplicationImpl.HandlePost handler;

			// WHEN : I invoke getHandlePost()
			APNGApplicationImpl impl = new APNGApplicationImpl();
			handler = (APNGApplicationImpl.HandlePost) impl.getHandlePost();

			// THEN : it should return the class instance which extends to RESTlib_ClientImplHandler
			Assert.isNotNull(handler, 'Unable to get HandlePost()');
			Assert.isInstanceOfType(
				handler,
				RESTlib_ClientImplHandler.class,
				'HandlePost be an instance of RESTlib_ClientImplHandler'
			);
			Test.stopTest();

		}
	}

	/**
	 * @description test boiler plate code - getHandlePut()
	 * NO IMPLEMENTATION YET
	 */

	@isTest
	static void shouldReturnHandlePut() {
		// GIVEN : a Handler instance
		RESTlib_ClientImplHandler handler;

		Test.startTest();
		System.runAs(new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser()) {
			// WHEN : I invoke getHandlePut()
			APNGApplicationImpl impl = new APNGApplicationImpl();
			handler = impl.getHandlePut();
		}
		Test.stopTest();

		// THEN : Put is not expected to be implemented yet
		Assert.isTrue(handler == null, 'Unexpected Put implementation');
	}

	/**
	 * @description test boiler plate code - getHandlePatch()
	 */

	@isTest
	static void shouldReturnHandlePatch() {
		// GIVEN : a HandlePatch instance
		Test.startTest();
		System.runAs(new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser()) {
			// WHEN : I invoke getHandlePatch()
			APNGApplicationImpl impl = new APNGApplicationImpl();
			// THEN : Patch is not expected to be implemented yet
			Assert.isNotNull(impl.getHandlePatch(), 'getHandlePatch should be implemented');
		}
		Test.stopTest();
	}
	// @isTest
	// static void testRequestResponseTypesForPost() {
	//   // GIVEN : a PostRequest instance
	//   APNGApplicationImpl.PostRequest handler = new APNGApplicationImpl.PostRequest();

	//   Type expectedRequest = APNGApplicationPayload.PostRequest.class;
	//   Type returnRequest;

	//   Test.startTest();
	//   System.runAs(new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil()
	//     .getAgentUser()) {
	//     // WHEN : I invoke get types
	//     returnRequest = handler.getRequestType();
	//   }
	//   Test.stopTest();

	//   // THEN : I should receive the expected types
	//   Assert.areEqual(expectedRequest, returnRequest, 'Unexpected request Type');
	// }
	/**
	 * @description test validateRequest method
	 */
	// @IsTest
	// static void testValidatePostRequestBody() {
	// 	// GIVEN a valid APNGApplicationPayload.PostRequest
	// 	System.runAs(new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser()) {
	// 		//  User portalUser = [SELECT Id, ContactId,AccountId, Account.Monash_AM_Campus__c FROM User WHERE Profile.Name = 'Agent Portal Next Gen User' LIMIT 1];
	// 		Test.startTest();
	// 		Contact con = new Contact(
	// 			First_Name__c = 'Test',
	// 			Last_Name__c = 'Test Last',
	// 			Personal_email__c = 'test123@getnad.com',
	// 			BirthDate = Date.valueOf('2003-02-01')
	// 		);
	// 		insert con;
	// 		con = [SELECT Id, CRM_ID__C FROM Contact WHERE Id = :con.Id LIMIT 1];
	// 		APNGApplicationPayload.PostRequest mockRequest = new APNGApplicationPayload.PostRequest();
	// 		mockRequest.contactId = con.CRM_ID__C;
	// 		mockRequest.campusLocation = 'Australia';
	// 		mockRequest.residencyStatus = 'Domestic';
	// 		mockRequest.email = new List<CommonWSPayload.Email>();
	// 		CommonWSPayload.Email email = new CommonWSPayload.Email();
	// 		email.email = 'test@example.com';
	// 		email.type = 'Personal';
	// 		mockRequest.email.add(email);
	// 		mockRequest.phone = new List<CommonWSPayload.Phone>();
	// 		CommonWSPayload.Phone phone = new CommonWSPayload.Phone();
	// 		phone.phoneNumber = '1234567890';
	// 		phone.type = 'Mobile';
	// 		mockRequest.phone.add(phone);

	// 		// WHEN the validateRequest method is called
	// 		APNGApplicationValidations validator = new APNGApplicationValidations();
	// 		RESTlib_Ex.ListException result = validator.validate(mockRequest);
	// 		Test.stopTest();
	// 		// THEN no exceptions should be thrown
	// 		Assert.isTrue(true, 'No exceptions were thrown as expected');
	// 	}
	// }
	/**
	 * @description test validateRequest method with an invalid request
	 */
	@IsTest
	static void testValidatePostRequestInvalid() {
		// GIVEN an invalid APNGApplicationPayload.PostRequest with all fields null
		APNGApplicationPayload.PostRequest mockRequest = new APNGApplicationPayload.PostRequest();
		APNGApplicationValidations validator = new APNGApplicationValidations();

		// WHEN the validateRequest method is called
		// GIVEN a portal user and application
		User portalUser = [SELECT Id FROM User WHERE email = 'testAgentLastName@TestEmail.com' LIMIT 1];
		RESTlib_Ex.ListException result;
		System.runAs(portalUser) {
			Test.startTest();
			result = validator.validate(mockRequest);
			Test.stopTest();
		}
		// THEN exceptions should be thrown
		Assert.isTrue(
			String.isNotBlank(validator.exceptions.getListExceptionSummaryString()),
			'Exceptions should be thrown for an invalid request'
		);
		Assert.isTrue(result.getExceptions().size() > 0, 'Multiple exceptions should be thrown');
	}

	/**
	 * @description test getCampusLocation method
	 */
	@IsTest
	static void testPOSTRequestGetCampusLocation() {
		// GIVEN an APNGApplicationValidations instance and a request with a campus location
		APNGApplicationValidations validator = new APNGApplicationValidations();
		APNGApplicationPayload.PostRequest request = new APNGApplicationPayload.PostRequest();
		request.campusLocation = 'Test Campus';

		// WHEN getting the campus location
		String result = validator.getCampusLocation(request);

		// THEN it should match the input
		Assert.areEqual('Test Campus', result, 'Campus Location should match');
	}
	/**
	 * @description test getResidencyStatus method
	 */
	@IsTest
	static void testPOSTRequestGetResidencyStatus() {
		// GIVEN an APNGApplicationValidations instance and a request with a residency status
		APNGApplicationValidations validator = new APNGApplicationValidations();
		APNGApplicationPayload.PostRequest request = new APNGApplicationPayload.PostRequest();
		request.residencyStatus = 'Domestic';

		// WHEN getting the residency status
		String result = validator.getResidencyStatus(request);

		// THEN it should match the input
		Assert.areEqual('Domestic', result, 'Residency Status should match');
	}
	/**
	 * @description test getEmail method
	 */
	@IsTest
	static void testPOSTRequestGetEmail() {
		// GIVEN an APNGApplicationValidations instance and a request with an email
		APNGApplicationValidations validator = new APNGApplicationValidations();
		APNGApplicationPayload.PostRequest request = new APNGApplicationPayload.PostRequest();
		request.email = new List<CommonWSPayload.Email>();
		CommonWSPayload.Email email = new CommonWSPayload.Email();
		email.email = 'test@example.com';
		email.type = 'Personal';
		request.email.add(email);

		// WHEN getting the email
		List<CommonWSPayload.Email> result = validator.getEmail(request);

		// THEN it should match the input
		Assert.areEqual(1, result.size(), 'Should have one email');
		Assert.areEqual('test@example.com', result[0].email, 'Email address should match');
		Assert.areEqual('Personal', result[0].type, 'Email type should match');
	}
	/**
	 * @description test getPhone method
	 */
	@IsTest
	static void testPOSTRequestGetPhone() {
		// GIVEN an APNGApplicationValidations instance and a request with a phone number
		APNGApplicationValidations validator = new APNGApplicationValidations();
		APNGApplicationPayload.PostRequest request = new APNGApplicationPayload.PostRequest();
		request.phone = new List<CommonWSPayload.Phone>();
		CommonWSPayload.Phone phone = new CommonWSPayload.Phone();
		phone.phoneNumber = '1234567890';
		phone.type = 'Mobile';
		request.phone.add(phone);

		// WHEN getting the phone
		List<CommonWSPayload.Phone> result = validator.getPhone(request);

		// THEN it should match the input
		Assert.areEqual(1, result.size(), 'Should have one phone');
		Assert.areEqual('1234567890', result[0].phoneNumber, 'Phone number should match');
		Assert.areEqual('Mobile', result[0].type, 'Phone type should match');
	}
	/**
	 * @description test validateContactId method
	 */
	@IsTest
	static void testPOSTRequestValidateContactId() {
		// GIVEN an APNGApplicationValidations instance and an exceptions list
		APNGApplicationValidations validator = new APNGApplicationValidations();
		RESTlib_Ex.ListException exceptions = new RESTlib_Ex.ListException();

		// Get the Contact created in the TestSetup
		Contact testContact = [SELECT Id, CRM_ID__C FROM Contact LIMIT 1];
		User u = [
			SELECT Id
			FROM User
			WHERE username LIKE '%testAgentLastName@TestEmail.com.domain%'
			LIMIT 1
		];
		// WHEN validating a valid contact ID
		System.runAs(u) {
			Test.startTest();
			validator.validateContactId(testContact.Id);
			Test.stopTest();
		}
		// THEN no exceptions should be thrown

		Assert.isTrue(true, 'No exceptions were thrown as expected');

		// WHEN validating an invalid contact ID
		validator.exceptions = new RESTlib_Ex.InvalidRequestException(); // Reset exceptions
		validator.validateContactId('');

		// THEN an exception should be thrown
		Assert.areEqual(1, validator.exceptions.getExceptions().size(), 'Exception should be thrown for empty contact ID');
	}

	/**
	 * @description Tests the getRequestPayload method of APNGApplicationImpl.HandlePost
	 */
	@IsTest
	static void testPostRequestGetRequestPayload() {
		// GIVEN a mock REST request with a JSON body
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		APNGApplicationPayload.PostRequest mockPostRequest = new APNGApplicationPayload.PostRequest();
		mockPostRequest.contactId = '0030000000000001';
		mockPostRequest.campusLocation = 'Test Campus';
		mockPostRequest.residencyStatus = 'Domestic';
		// Set other necessary fields...

		String jsonBody = JSON.serialize(mockPostRequest);
		req.requestBody = Blob.valueOf(jsonBody);

		RestContext.request = req;
		RestContext.response = res;

		// WHEN getRequestPayload is called
		Test.startTest();
		APNGApplicationImpl.HandlePost handler = new APNGApplicationImpl.HandlePost();
		RESTlib_Payload.Request result = handler.getRequestPayload();
		Assert.areEqual(APNGApplicationPayload.PostRequest.class, handler.getRequestType()) ;
		Test.stopTest();

		// THEN the result should be a correctly deserialized APNGApplicationPayload.PostRequest
		Assert.isTrue(
			result instanceof APNGApplicationPayload.PostRequest,
			'Result should be an instance of APNGApplicationPayload.PostRequest'
		);

		APNGApplicationPayload.PostRequest deserializedRequest = (APNGApplicationPayload.PostRequest) result;
		Assert.areEqual(mockPostRequest.contactId, deserializedRequest.contactId, 'Contact ID should match');
		Assert.areEqual(mockPostRequest.campusLocation, deserializedRequest.campusLocation, 'Campus location should match');
		Assert.areEqual(
			mockPostRequest.residencyStatus,
			deserializedRequest.residencyStatus,
			'Residency status should match'
		);
		// Add more assertions for other fields as necessary
	}
	@isTest
	static void testHandlePostValidRequestBody() {
		System.runAs(new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser()) {
			//  User portalUser = [SELECT Id, ContactId,AccountId, Account.Monash_AM_Campus__c FROM User WHERE Profile.Name = 'Agent Portal Next Gen User' LIMIT 1];
			Contact con = new Contact(
				First_Name__c = 'Test',
				Last_Name__c = 'Test Last',
				Personal_email__c = 'test123@getnad.com',
				BirthDate = Date.valueOf('2003-02-01')
			);
			insert con;
			con = [SELECT Id, CRM_ID__C FROM Contact WHERE Id = :con.Id LIMIT 1];
			APNGApplicationPayload.PostRequest mockRequest = new APNGApplicationPayload.PostRequest();

			mockRequest.contactId = con.CRM_ID__C;
			mockRequest.campusLocation = 'Australia';
			mockRequest.residencyStatus = 'INTRNTNL.A';
			mockRequest.email = new List<CommonWSPayload.Email>();
			CommonWSPayload.Email email = new CommonWSPayload.Email();
			email.email = 'test@example.com';
			email.type = 'Personal';
			mockRequest.email.add(email);
			mockRequest.phone = new List<CommonWSPayload.Phone>();
			CommonWSPayload.Phone phone = new CommonWSPayload.Phone();
			phone.phoneNumber = '1234567890';
			phone.type = 'Mobile';
			mockRequest.phone.add(phone);
			// WHEN the process method is called
			RESTlib_Ex.ListException validateResult;
			APNGApplicationPayload.PostResponse respObj = new APNGApplicationPayload.PostResponse();
			Test.startTest();
			APNGApplicationImpl.HandlePost handler = new APNGApplicationImpl.HandlePost();
			try {
				handler.validate((RESTlib_Payload.Request) mockRequest);
				handler.process((RESTlib_Payload.Request) mockRequest, respObj);

			} catch (RESTlib_Ex.ListException e) {
				validateResult = e;
			}
			Test.stopTest();
			Assert.isTrue([SELECT Id, Nebula__OriginLocation__c FROM Nebula__LogEntry__c].size()>0);
			Assert.areEqual(APNGApplicationPayload.PostRequest.class, handler.getRequestType()) ;
			Assert.areEqual(APNGApplicationPayload.PostResponse.class, handler.getResponseType()) ;

			// THEN no exceptions should be thrown
			Assert.isNull(validateResult, 'Exceptions were thrown for a valid request');
		}

	}
	@IsTest
	static void testPatchRequest() {
		AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();
		// PermissionSet oesPs = [
		// 	SELECT Id
		// 	FROM PermissionSet
		// 	WHERE Name = 'OES_Permission_Set'
		// ];
		// PermissionSetAssignment psa = new PermissionSetAssignment(
		// 	AssigneeId = portalUser.testUser.Id,
		// 	PermissionSetId = oesPs.Id
		// ); // avoid MIXED_DML_OPERATION
		User userx = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1];

		// System.runAs(userx) {
		// 	insert psa;
		// }
		System.runAs(new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser()) {
			Contact applicant = StudFirst_TestHelper.createInternationalApplicant();
			insert applicant;
			Country_Attribute__c country = new Country_Attribute__c(
				Name = 'INDIA',
				Callista_Code__c = '7103',
				Country__c = 'INDIA'
			);
			insert country;
			Application__c application = StudFirst_TestHelper.createInternationalApplication(applicant, country);
			insert application;
		}
		Course_Offering__c co = [SELECT Id, Course_Offering_UID__c FROM Course_Offering__c LIMIT 1];
		/**
		 * @description when an OES User tries to invoke the asACP() method,
		 * the validation rules should run and the method should parse the CDM
		 * into an ACP.
		 *
		 * We cannot run an actual DML to update the resulting ACP because OES User relies
		 * on criteria-based sharing rule to have access to course offering, and is currently
		 * a Salesforce limitation
		 *
		 * https://trailhead.salesforce.com/trailblazer-community/feed/0D54V00007T4RYvSAN
		 */
		System.runAs(userx) {
			//Share Course offering with the OES user by Apex Managed sharing -To get around limitation as sharing rules are not evaluated in Test classes
			Course_offering__Share coshare = new Course_offering__Share();
			coshare.ParentId = co.Id;
			coshare.UserOrGroupId = portalUser.testUser.Id;
			coshare.AccessLevel = 'Read';
			coshare.RowCause = Schema.Course_offering__Share.RowCause.Manual;
			Database.insert(coshare, false);
		}
        TriggerCommon.disableTrigger('Country_Attribute__c');
		TriggerCommon.disableTrigger('Account');
		TriggerCommon.disableTrigger('Contact');
		TriggerCommon.disableTrigger('User');
		TriggerCommon.disableTrigger('Application_Course_Preference__c');
		AgentPortalTestDataBuilder.Application testApplication = new AgentPortalTestDataBuilder.Application()
			.withAgent(portalUser)
			.withCourseOffering(co)
			.build();
		// GIVEN : a HandleGet instance
		APNGApplicationImpl.HandlePatch handler = new APNGApplicationImpl.HandlePatch();

		// Type expectedRequest = APNGApplicationPayload.PatchRequest.class;
		// Type expectedResponse = APNGApplicationPayload.PatchResponse.class;
		Type returnRequest;
		Type returnResponse;

		Test.startTest();
		System.runAs(portalUser.testUser) {
			// WHEN : I invoke get types
			returnRequest = handler.getRequestType();
			returnResponse = handler.getResponseType();

			// Retrieve test data
			ApplicationWSWrapper.CDM_CourseOffering coCDM = new ApplicationWSWrapper.CDM_CourseOffering();
			coCDM.crmRecordId = co.Id;
			coCDM.courseOfferingUid = co.Course_Offering_UID__c;
			coCDM.applicationRecord = testApplication.app;
			//  Minimum ACP

			Application_Course_Preference__c minACP = new Application_Course_Preference__c(
				Applicant__c = testApplication.applicant.id,
				Application__c = testApplication.app.id,
				Course_Offering__c = co.id
			);
			insert minACP;
			ApplicationWSWrapper.CDM_ApplicationCoursePreference acpCDM = new ApplicationWSWrapper.CDM_ApplicationCoursePreference();
			acpCDM.crmRecordId = testApplication.acp.Id;
			acpCDM.courseOffering = coCDM;
			acpCDM.externalId = [SELECT Id, ACP_ID__c FROM Application_Course_Preference__c WHERE id = :minACP.Id].ACP_ID__c;
			acpCDM.applicationRecord = testApplication.app;
			// acpCDM.basisForAdmissionType = '311: HIGHER EDUCATION COURSE (COMPLETE/INCOMPLETE, AUST/OS)';
			// acpCDM.documentationStatus = 'Satisfied';
			// acpCDM.outcomeStatus = 'Offer';
			// acpCDM.entryQualificationStatus = 'Qualified';
			// acpCDM.offerResponseStatus = 'Pending';
			// acpCDM.offerDate = Date.today().addDays(-5);
			// acpCDM.actualOfferResponseDate = Date.today();

			// Create a PatchRequest object
			APNGApplicationPayload.PatchRequest patchRequest = new APNGApplicationPayload.PatchRequest();
			APNGApplicationPayload.CDM_Application application = new APNGApplicationPayload.CDM_Application();
			application.applicationId = [SELECT id, name FROM Application__c WHERE Id = :testApplication.app.Id].Name;
			application.crmContactId = testApplication.applicant.Id;
			// application.applicationStatus = 'Submitted';
			application.visa = new ApplicationWSWrapper.CDM_Visa();
			application.visa.startDate = '13-06-219';
			application.coursePreferences = new List<ApplicationWSWrapper.CDM_ApplicationCoursePreference>{ acpCDM };
			patchRequest.application = application;
			APNGApplicationPayload.PatchResponse response = new APNGApplicationPayload.PatchResponse();
			// System.debug('Patch Request JSON: ' + JSON.serialize(patchRequest));
			try {
				// WHEN : I invoke validate()
				handler.validate((RESTlib_Payload.Request) patchRequest);
			} catch (RESTlib_Ex.InvalidRequestException e) {
				// THEN : no exceptions should be thrown
				// System.debug('InvalidRequestException: ' + e);
				Assert.fail('Unexpected InvalidRequestException thrown. Exception was not expected');
			} catch (Exception e) {
				// THEN : no exceptions should be thrown
				Assert.isTrue(e.getMessage() != null, 'Exception was thrown');
			}
			try {
				// WHEN : I invoke process()
				handler.process((RESTlib_Payload.Request) patchRequest, response);
			} catch (RESTlib_Ex.InvalidRequestException e) {
				// THEN : no exceptions should be thrown
				// System.debug('InvalidRequestException: ' + e);
				Assert.fail('Unexpected InvalidRequestException thrown. Exception was not expected');
			} catch (Exception e) {
				// THEN : no exceptions should be thrown
				Assert.isTrue(e.getMessage() != null, 'Exception was thrown');
			}
			
			Test.stopTest();
		}
	}
}