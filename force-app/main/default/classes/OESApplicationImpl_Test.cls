/**
 * @description Test class for OESApplicationImpl
 * @author      Nick Guia
 * @since       MAY.6.2024
 * @group      OES Application Web Service
 * @last modified on  : 2024-10-26
 * @last modified by  : Ben Greenland
 */
@isTest(isParallel=false) // APEX_DATA_ACCESS_RESTRICTION. courseOffering__c data sharing issue
private class OESApplicationImpl_Test {
	@TestSetup
	static void makeData() {
		TriggerCommon.disableTrigger('Country_Attribute__c');
		TriggerCommon.disableTrigger('Account');
		TriggerCommon.disableTrigger('Contact');
		TriggerCommon.disableTrigger('User');
		AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();
		PermissionSet oesPs = [
			SELECT Id
			FROM PermissionSet
			WHERE Name = 'OES_Permission_Set'
		];
		PermissionSetAssignment psa = new PermissionSetAssignment(
			AssigneeId = portalUser.testUser.Id,
			PermissionSetId = oesPs.Id
		); // avoid MIXED_DML_OPERATION
		System.runAs(new User(Id = UserInfo.getUserId())) {
			insert psa;
		}
		System.runAs(portalUser.testUser) {
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
		// Reference data - Course
		Course__c course = StudFirst_TestHelper.createCourse();
		course.name = 'E6001';
		course.Course_Code__c = 'E6001_11';
		course.Version__c = '11';
		insert course;

		// Reference data - Course Offering
		List<Course_Offering__c> courseOfferings = new List<Course_Offering__c>();

		Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
		courseOffering.Course_Code__c = 'E6001';
		courseOffering.Active__c = true;
		courseOffering.Course_Version_Number__c = 1;
		courseOffering.Admission_Calendar_Type__c = 'ADM-0';
		courseOffering.Location_Code__c = 'CLAYTON';
		courseOffering.Attendance_Type__c = 'FT';
		courseOffering.Attendance_Mode__c = 'IN';
		courseOffering.Admission_Category__c = 'UG-CSP';
		courseOffering.Academic_CI_Sequence_Number__c = 1111;
		courseOffering.Admission_CI_Sequence_Number__c = 1111;
		courseOffering.Citizenship_Type__c = 'DOM-AUS';
		courseOffering.Unit_Set_Code__c = null;
		courseOffering.Unit_Set_Version__c = null;
		courseOffering.Admission_Calendar_Description__c = 'CrOf0';
		courseOfferings.add(courseOffering);

		Course_Offering__c coRec = StudFirst_TestHelper.createCourseOffering(course);
		coRec.Course_Code__c = 'E6001';
		coRec.Course_Version_Number__c = 1;
		coRec.Admission_Calendar_Type__c = 'ADM-0';
		coRec.Location_Code__c = 'CLAYTON';
		coRec.Attendance_Type__c = 'FT';
		coRec.Attendance_Mode__c = 'IN';
		coRec.Admission_Category__c = 'UG-CSP';
		coRec.Academic_CI_Sequence_Number__c = 1111;
		coRec.Admission_CI_Sequence_Number__c = 1111;
		coRec.Unit_Set_Code__c = null;
		coRec.Unit_Set_Version__c = null;
		coRec.Citizenship_type__c = 'INT-TEP';
		coRec.Admission_Calendar_Description__c = 'CrOf1';
		coRec.Active__c = true;

		courseOfferings.add(coRec);

		Course_Offering__c coRec2 = StudFirst_TestHelper.createCourseOffering(course);
		coRec2.Course_Code__c = 'E6001';
		coRec2.Course_Version_Number__c = 1;
		coRec2.Admission_Calendar_Type__c = 'ADM-0';
		coRec2.Location_Code__c = 'CLAYTON';
		coRec2.Attendance_Type__c = 'FT';
		coRec2.Attendance_Mode__c = 'EX';
		coRec2.Admission_Category__c = 'UG-CSP';
		coRec2.Academic_CI_Sequence_Number__c = 1111;
		coRec2.Admission_CI_Sequence_Number__c = 1111;
		coRec2.Unit_Set_Code__c = null;
		coRec2.Unit_Set_Version__c = null;
		coRec2.Citizenship_type__c = 'INT-TEP';
		coRec2.Admission_Calendar_Description__c = 'CrOf2';
		coRec2.Active__c = true;

		courseOfferings.add(coRec2);

		Course_Offering__c oesCourseOffering1 = StudFirst_TestHelper.createCourseOffering(course);
		oesCourseOffering1.Course_Type__c = '21'; // any type that is not PD
		oesCourseOffering1.Portal_Available__c = true;
		oesCourseOffering1.Default_Admission_Category_Ind__c = true;
		oesCourseOffering1.Location_Code__c = 'ONLINE';
		oesCourseOffering1.Fee_Category__c = 'AU_DOM_MO';
		oesCourseOffering1.Course_Offering_UID__c = 'CO-COCOID1';
		oesCourseOffering1.Active__c = true;
		oesCourseOffering1.Mix_Unique_Id__c = AgentPortalTestDataFactory.util.generateRandomString(10);
		courseOfferings.add(oesCourseOffering1);
		insert courseOfferings;

		TriggerCommon.disableTrigger('Account');
		TriggerCommon.enableTrigger('Contact');
		// create LOV
		List<List_of_Values__c> lovList = new List<List_of_Values__c>{
			new List_of_Values__c(
				Unique_Key__c = 'SATISFIED-ADM_DOC_STATUS',
				Value__c = 'SATISFIED',
				System_Code__c = 'SATISFIED',
				Type__c = 'ADM_DOC_STATUS'
			),
			new List_of_Values__c(
				Unique_Key__c = 'OFFER-ADM_OUTCOME_STATUS',
				Value__c = 'OFFER',
				System_Code__c = 'OFFER',
				Type__c = 'ADM_OUTCOME_STATUS'
			),
			new List_of_Values__c(
				Unique_Key__c = 'QUALIFIED-ADM_ENTRY_QUAL_STATUS',
				Value__c = 'QUALIFIED',
				System_Code__c = 'QUALIFIED',
				Type__c = 'ADM_ENTRY_QUAL_STATUS'
			),
			new List_of_Values__c(
				Unique_Key__c = 'PENDING-ADM_OFFER_RESP_STATUS',
				Value__c = 'PENDING',
				System_Code__c = 'PENDING',
				Type__c = 'ADM_OFFER_RESP_STATUS'
			)
		};
		upsert lovList;
		User userx = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1];

		System.runAs(userx) {
			//Share Course offering with the OES user by Apex Managed sharing -To get around limitation as sharing rules are not evaluated in Test classes
			Course_offering__Share coshare = new Course_offering__Share();
			coshare.ParentId = coRec.Id;
			coshare.UserOrGroupId = portalUser.testUser.Id;
			coshare.AccessLevel = 'Read';
			coshare.RowCause = Schema.Course_offering__Share.RowCause.Manual;
			Database.insert(coshare, false);
		}

		TriggerCommon.enableTrigger('Country_Attribute__c');
		TriggerCommon.enableTrigger('Account');
		TriggerCommon.enableTrigger('Contact');
		TriggerCommon.enableTrigger('User');
	}

	/**
	 * @description create test CDM for ACP
	 * @return `AgentPortalPayload.CDM_ApplicationCoursePreference`
	 */
	private static AgentPortalPayload.CDM_ApplicationCoursePreference createAcpCDM() {
		AgentPortalPayload.CDM_ApplicationCoursePreference cdm = new AgentPortalPayload.CDM_ApplicationCoursePreference();
		cdm.basisForAdmissionType = '311: HIGHER EDUCATION COURSE (COMPLETE/INCOMPLETE, AUST/OS)';
		cdm.documentationStatus = 'Satisfied';
		cdm.outcomeStatus = 'Offer';
		cdm.entryQualificationStatus = 'Qualified';
		cdm.offerResponseStatus = 'Pending';
		cdm.offerDate = Date.today().addDays(-5);
		cdm.actualOfferResponseDate = Date.today();
		return cdm;
	}

	/**
	 * (implies vice-versa)
	 * should throw an AgentPortalPayload.ApplicantException when Offer date
	 * is greater than Offer response date
	 */
	@isTest
	static void shouldThrowEceptionWhenOfferDateGreaterThanResponseDate() {
		// GIVEN : an offer date greater than response date
		Date offerDate = Date.today();
		Date responseDate = Date.today().addDays(-1);

		Test.startTest();

		// WHEN : I run the validation
		try {
			OESApplicationImpl.validateOfferAndResponseDate(offerDate, responseDate);
			Assert.fail('Unable to throw an Invalid Exception');
		} catch (AgentPortalPayload.ApplicantException e) {
			// THEN : AgentPortalPayload.ApplicantException should be thrown
			Assert.isTrue(true);
		} catch (Exception e) {
			Assert.fail('Unexpected exception thrown');
		}

		Test.stopTest();
	}

	/**
	 * should throw an AgentPortalPayload.ApplicantException when
	 * offerResponseStatus is not in the accepted list.
	 */
	@isTest
	static void shouldThrowEceptionWhenOfferResponseStatusInvalid() {
		// GIVEN
		String offerResponseStatus = 'some offer response status';

		Test.startTest();

		// WHEN : I run the validation
		try {
			OESApplicationImpl.validateOfferResponseStatus(offerResponseStatus);
			Assert.fail('Unable to throw an Invalid Exception');
		} catch (AgentPortalPayload.ApplicantException e) {
			// THEN : AgentPortalPayload.ApplicantException should be thrown
			Assert.isTrue(true);
		} catch (Exception e) {
			Assert.fail('Unexpected exception thrown');
		}

		Test.stopTest();
	}

	/**
	 * should throw an AgentPortalPayload.ApplicantException when
	 * entryQualStatus is not in the accepted list.
	 */
	@isTest
	static void shouldThrowEceptionWhenEntryQualificationInvalid() {
		// GIVEN
		String entryQualStatus = 'some entry qual status';

		Test.startTest();

		// WHEN : I run the validation
		try {
			OESApplicationImpl.validateEntryQualificationStatus(entryQualStatus);
			Assert.fail('Unable to throw an Invalid Exception');
		} catch (AgentPortalPayload.ApplicantException e) {
			// THEN : AgentPortalPayload.ApplicantException should be thrown
			Assert.isTrue(true);
		} catch (Exception e) {
			Assert.fail('Unexpected exception thrown');
		}

		Test.stopTest();
	}

	/**
	 * should throw an AgentPortalPayload.ApplicantException when
	 * outcomeStatus is not in the accepted list.
	 */
	@isTest
	static void shouldThrowEceptionWhenOutcomeStatusInvalid() {
		// GIVEN
		String outcomeStatus = 'some outcome status';

		Test.startTest();

		// WHEN : I run the validation
		try {
			OESApplicationImpl.validateOutcomeStatus(outcomeStatus);
			Assert.fail('Unable to throw an Invalid Exception');
		} catch (AgentPortalPayload.ApplicantException e) {
			// THEN : AgentPortalPayload.ApplicantException should be thrown
			Assert.isTrue(true);
		} catch (Exception e) {
			Assert.fail('Unexpected exception thrown');
		}

		Test.stopTest();
	}

	/**
	 * should throw an AgentPortalPayload.ApplicantException when
	 * documentationStatus is not in the accepted list.
	 */
	@isTest
	static void shouldThrowEceptionWhenDocumentationStatusInvalid() {
		// GIVEN
		String documentationStatus = 'some documentation status';

		Test.startTest();

		// WHEN : I run the validation
		try {
			OESApplicationImpl.validateDocumentationStatus(documentationStatus);
			Assert.fail('Unable to throw an Invalid Exception');
		} catch (AgentPortalPayload.ApplicantException e) {
			// THEN : AgentPortalPayload.ApplicantException should be thrown
			Assert.isTrue(true);
		} catch (Exception e) {
			Assert.fail('Unexpected exception thrown');
		}

		Test.stopTest();
	}

	/**
	 * should throw an AgentPortalPayload.ApplicantException when
	 * basisForAdmissionType is not in the accepted list.
	 */
	@isTest
	static void shouldThrowEceptionWhenBasisForAdmissionTypeInvalid() {
		// GIVEN
		String basisForAdmissionType = 'some basis for admission type';

		Test.startTest();

		// WHEN : I run the validation
		try {
			OESApplicationImpl.validateBasisForAdmissionType(basisForAdmissionType);
			Assert.fail('Unable to throw an Invalid Exception');
		} catch (AgentPortalPayload.ApplicantException e) {
			// THEN : AgentPortalPayload.ApplicantException should be thrown
			Assert.isTrue(true);
		} catch (Exception e) {
			Assert.fail('Unexpected exception thrown');
		}

		Test.stopTest();
	}

	/**
	 * (Positive) should not throw any exceptions when all expected values are in place.
	 * (Negative) covered in their own respective test methods
	 */
	@isTest
	static void shouldNotThrowEceptionWhenAllValuesAreValid() {
		// GIVEN : an ACP CDM with valid values
		AgentPortalPayload.CDM_ApplicationCoursePreference acpCDM = createAcpCDM();

		Test.startTest();

		// WHEN : I run all the validations
		try {
			OESApplicationImpl.validateCdmAcp(acpCDM);

			// THEN : no errors
			Assert.isTrue(true);
		} catch (AgentPortalPayload.ApplicantException e) {
			Assert.fail('Unexpected exception thrown');
		} catch (Exception e) {
			Assert.fail('Unexpected exception thrown');
		}

		Test.stopTest();
	}

	/**
	 * If the CDM values passed all the validations, it should be parsed
	 * into an ACP Object
	 */
	@isTest
	static void shouldPraseCDMtoACPWhenAllValuesAreValid() {
		// GIVEN : an ACP CDM with valid values
		AgentPortalPayload.CDM_ApplicationCoursePreference acpCDM = createAcpCDM();
		Application_Course_Preference__c acp;

		Test.startTest();

		// WHEN : I run all the validations and parse to ACP
		try {
			OESApplicationImpl.validateCdmAcp(acpCDM);
			acp = OESApplicationImpl.parseCdmToAcp(acpCDM);
		} catch (AgentPortalPayload.ApplicantException e) {
			Assert.fail('Unexpected exception thrown');
		} catch (Exception e) {
			Assert.fail('Unexpected exception thrown');
		}

		Test.stopTest();

		// THEN : I should receive an ACP with all the expected values
		Assert.isNotNull(acp, 'Unexpected null ACP');
		Assert.areEqual(acpCDM.basisForAdmissionType, acp.Basis_For_Adminssion_Type__c, 'Unexpected field mapping value');
		Assert.areEqual(
			'SATISFIED-ADM_DOC_STATUS',
			acp.Documentation_Status_LOV__r.Unique_Key__c,
			'Unexpected field mapping value'
		);
		Assert.areEqual(
			'OFFER-ADM_OUTCOME_STATUS',
			acp.Outcome_Status_LOV__r.Unique_Key__c,
			'Unexpected field mapping value'
		);
		Assert.areEqual(
			'QUALIFIED-ADM_ENTRY_QUAL_STATUS',
			acp.Entry_Qualification_Status_LOV__r.Unique_Key__c,
			'Unexpected field mapping value'
		);
		Assert.areEqual(
			'PENDING-ADM_OFFER_RESP_STATUS',
			acp.Offer_Response_Status_LOV__r.Unique_Key__c,
			'Unexpected field mapping value'
		);
		Assert.areEqual(acpCDM.offerDate, acp.Offer_Date__c, 'Unexpected field mapping value');
		Assert.areEqual(
			acpCDM.actualOfferResponseDate,
			acp.Actual_Offer_Response_Date__c,
			'Unexpected field mapping value'
		);
	}

	/**
	 * @description test validateRequest method
	 */
	@IsTest
	static void testValidateRequest() {
		// GIVEN a valid OESApplicationPayload.PostRequest

		User u = [
			SELECT id
			FROM User
			WHERE username LIKE '%testAgentLastName@TestEmail.com.domain%'
			LIMIT 1
		];

		System.runAs(u) {
			//  User portalUser = [SELECT Id, ContactId,AccountId, Account.Monash_AM_Campus__c FROM User WHERE Profile.Name = 'Agent Portal Next Gen User' LIMIT 1];

			Contact con = new Contact(
				First_Name__c = 'Test',
				Last_Name__c = 'Test Last',
				Personal_email__c = 'test123@getnad.com',
				BirthDate = Date.valueOf('2003-02-01')
			);
			insert con;
			con = [SELECT Id, CRM_ID__C FROM Contact WHERE Id = :con.Id LIMIT 1];
			OESApplicationPayload.PostRequest mockRequest = new OESApplicationPayload.PostRequest();
			mockRequest.contactId = con.CRM_ID__C;
			mockRequest.campusLocation = 'Australia';
			mockRequest.residencyStatus = 'Domestic';
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

			// WHEN the validateRequest method is called
			RESTlib_Ex.ListException validateResult;
			Test.startTest();
			OESApplicationValidations validator = new OESApplicationValidations();
			RESTlib_Ex.ListException result = validator.validate(mockRequest);
			try {
				OESApplicationImpl.HandlePost handler = new OESApplicationImpl.HandlePost();
				handler.validate((RESTlib_Payload.Request) mockRequest);
			} catch (RESTlib_Ex.ListException e) {
				validateResult = e;
			}
			Test.stopTest();
			// THEN no exceptions should be thrown

			if (result != null) {
				Assert.fail('Exceptions were thrown for a valid request: ' + result.getExceptions());
			} else {
				Assert.isTrue(true, 'No exceptions were thrown as expected');
			}
			Assert.isNull(validateResult, 'Exceptions were thrown for a valid request');
		}

	}

	/**
	 * @description Tests the validateCdmAcp method with invalid data
	 */
	@IsTest
	static void testValidateCdmAcpWithInvalidData() {
		// GIVEN an invalid CDM_ApplicationCoursePreference
		AgentPortalPayload.CDM_ApplicationCoursePreference invalidCdm = new AgentPortalPayload.CDM_ApplicationCoursePreference();
		invalidCdm.basisForAdmissionType = 'Invalid Type';
		invalidCdm.documentationStatus = 'Invalid Status';
		invalidCdm.outcomeStatus = 'Invalid Outcome';
		invalidCdm.entryQualificationStatus = 'Invalid Entry Qual';
		invalidCdm.offerResponseStatus = 'Invalid Offer Response';
		invalidCdm.offerDate = Date.today().addDays(1);
		invalidCdm.actualOfferResponseDate = Date.today();

		Test.startTest();
		// WHEN validateCdmAcp is called with invalid data
		try {
			OESApplicationImpl.validateCdmAcp(invalidCdm);
			Assert.fail('Should have thrown an exception for invalid data');
		} catch (AgentPortalPayload.ApplicantException e) {
			// THEN appropriate exceptions should be thrown
			String errorMessage = e.getMessage();
			// Check for each invalid field in the error message
			Assert.isTrue(errorMessage.contains('Invalid Type'));
		}
		Test.stopTest();
	}

	/**
	 * @description Tests the parseCdmToAcp method
	 */
	@IsTest
	static void testParseCdmToAcp() {
		// GIVEN a valid CDM_ApplicationCoursePreference
		AgentPortalPayload.CDM_ApplicationCoursePreference validCdm = createAcpCDM();

		Test.startTest();
		// WHEN parseCdmToAcp is called
		Application_Course_Preference__c acp = OESApplicationImpl.parseCdmToAcp(validCdm);
		Test.stopTest();

		// THEN the ACP object should be correctly populated
		Assert.areEqual(
			validCdm.basisForAdmissionType,
			acp.Basis_For_Adminssion_Type__c,
			'Basis for admission type should match'
		);
		Assert.areEqual(
			'SATISFIED-ADM_DOC_STATUS',
			acp.Documentation_Status_LOV__r.Unique_Key__c,
			'Documentation status should match'
		);
	}

	/**
	 * @description test boiler plate code - getHandlePost()
	 */
	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
	@isTest
	static void shouldReturnHandlePost() {
		// GIVEN : a HandlePost instance
		OESApplicationImpl.HandlePost handler;

		Test.startTest();

		// WHEN : I invoke getHandlePost()
		OESApplicationImpl impl = new OESApplicationImpl();
		handler = (OESApplicationImpl.HandlePost) impl.getHandlePost();

		Test.stopTest();

		// THEN : it should return the class instance which extends to RESTlib_ClientImplHandler
		Assert.isNotNull(handler, 'Unable to get HandlePost()');
		Assert.isInstanceOfType(
			handler,
			RESTlib_ClientImplHandler.class,
			'HandleGet be an instance of RESTlib_ClientImplHandler'
		);
	}

	@IsTest
	static void testProcessRequest() {
		// GIVEN a valid OESApplicationPayload.PostRequest

		User u = [
			SELECT id
			FROM User
			WHERE username LIKE '%testAgentLastName@TestEmail.com.domain%'
			LIMIT 1
		];

		System.runAs(u) {
			Contact con = new Contact(
				First_Name__c = 'Test',
				Last_Name__c = 'Test Last',
				Personal_email__c = 'test123@getnad.com',
				BirthDate = Date.valueOf('2003-02-01')
			);
			insert con;
			con = [SELECT Id, CRM_ID__C FROM Contact WHERE Id = :con.Id LIMIT 1];
			OESApplicationPayload.PostRequest mockRequest = new OESApplicationPayload.PostRequest();
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
			OESApplicationPayload.PostResponse respObj = new OESApplicationPayload.PostResponse();
			Test.startTest();

			try {
				OESApplicationImpl.HandlePost handler = new OESApplicationImpl.HandlePost();
				handler.process((RESTlib_Payload.Request) mockRequest, respObj);
			} catch (RESTlib_Ex.ListException e) {
				validateResult = e;
			}
			Test.stopTest();
			// THEN no exceptions should be thrown
			Assert.isNull(validateResult, 'Exceptions were thrown for a valid request');
			Assert.isTrue([SELECT Id, Nebula__OriginLocation__c FROM Nebula__LogEntry__c].size()>0);

		}

	}

	@IsTest
	static void testProcessNegativeRequest() {
		// GIVEN a valid OESApplicationPayload.PostRequest

		User u = [
			SELECT id
			FROM User
			WHERE username LIKE '%testAgentLastName@TestEmail.com.domain%'
			LIMIT 1
		];

		System.runAs(u) {
			Contact con = new Contact(
				First_Name__c = 'Test',
				Last_Name__c = 'Test Last',
				Personal_email__c = 'test123@getnad.com',
				BirthDate = Date.valueOf('2003-02-01')
			);
			insert con;
			con = [SELECT Id, CRM_ID__C FROM Contact WHERE Id = :con.Id LIMIT 1];
			OESApplicationPayload.PostRequest mockRequest = new OESApplicationPayload.PostRequest();
			mockRequest.contactId = con.CRM_ID__C;
			mockRequest.campusLocation = 'Australia';
			mockRequest.residencyStatus = 'WrongresidencyStatus';
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
			RESTlib_Ex.WebServiceException validateResult;
			OESApplicationPayload.PostResponse respObj = new OESApplicationPayload.PostResponse();
			Test.startTest();

			try {
				OESApplicationImpl.HandlePost handler = new OESApplicationImpl.HandlePost();
				handler.process((RESTlib_Payload.Request) mockRequest, respObj);
			} catch (RESTlib_Ex.WebServiceException e) {
				validateResult = e;
			}
			Test.stopTest();
			// THEN no exceptions should be thrown
			Assert.isNotNull(validateResult.getMessage(), 'Exceptions were not thrown for a invalid request');
		}

	}
	@isTest
	static void shouldReturnHandlePosttResponseTypes() {
		// GIVEN : a HandleGet instance
		OESApplicationImpl.HandlePost handler = new OESApplicationImpl.HandlePost();

		Type expectedRequest = OESApplicationPayload.PostRequest.class;
		Type expectedResponse = OESApplicationPayload.PostResponse.class;
		Type returnRequest;
		Type returnResponse;

		Test.startTest();

		// WHEN : I invoke get types
		returnRequest = handler.getRequestType();
		returnResponse = handler.getResponseType();

		Test.stopTest();

		// THEN : I should receive the expected types
		Assert.areEqual(expectedRequest, returnRequest, 'Unexpected request Type');
		Assert.areEqual(expectedResponse, returnResponse, 'Unexpected response Type');
	}
	@isTest
	static void shouldReturnHandlePatch() {
		// GIVEN : a Handler instance
		RESTlib_ClientImplHandler handler;

		Test.startTest();
		System.runAs(new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser()) {
			// WHEN : I invoke getHandlePut()
			APNGApplicationImpl impl = new APNGApplicationImpl();
			handler = impl.getHandlePatch();
		}
		Test.stopTest();

		// THEN : Patch should have implemented
		Assert.isTrue(handler != null, 'Patch should have implementation');

	}

	@IsTest
	static void testPatchRequest() {
		AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();
		PermissionSet oesPs = [
			SELECT Id
			FROM PermissionSet
			WHERE Name = 'OES_Permission_Set'
		];
		PermissionSetAssignment psa = new PermissionSetAssignment(
			AssigneeId = portalUser.testUser.Id,
			PermissionSetId = oesPs.Id
		); // avoid MIXED_DML_OPERATION
		User userx = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1];

		System.runAs(userx) {
			insert psa;
		}
		System.runAs(portalUser.testUser) {
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
		TriggerCommon.disableTrigger('Application_Course_Preference__c');
		TriggerCommon.disableTrigger('Application__c');

		AgentPortalTestDataBuilder.Application testApplication = new AgentPortalTestDataBuilder.Application()
			.withAgent(portalUser)
			.withCourseOffering(co)
			.build();

		// GIVEN : a HandleGet instance
		OESApplicationImpl.HandlePatch handler = new OESApplicationImpl.HandlePatch();

		Type returnRequest;
		Type returnResponse;

		
		System.runAs(portalUser.testUser) {
			// WHEN : I invoke get types
			returnRequest = handler.getRequestType();
			returnResponse = handler.getResponseType();

			// Retrieve test data
			ApplicationWSWrapper.CDM_CourseOffering coCDM = new ApplicationWSWrapper.CDM_CourseOffering();
			coCDM.crmRecordId = co.Id;
			coCDM.courseOfferingUid = co.Course_Offering_UID__c;
			coCDM.applicationRecord = testApplication.app;
			testApplication.app.Status__c = 'Submitted';
			update testApplication.app;
			//  Minimum ACP
			
			Application_Course_Preference__c minACP = new Application_Course_Preference__c(
				Applicant__c = testApplication.applicant.id,
				Application__c = testApplication.app.id,
				Course_Offering__c = co.id
			);
			insert minACP;
			OESApplicationPayload.CDM_ApplicationCoursePreference acpCDM = new OESApplicationPayload.CDM_ApplicationCoursePreference();
			acpCDM.crmRecordId = testApplication.acp.Id;
			acpCDM.courseOffering = coCDM;
			acpCDM.externalId = [SELECT Id, ACP_ID__c FROM Application_Course_Preference__c WHERE id = :minACP.Id].ACP_ID__c;
			acpCDM.applicationRecord = testApplication.app;
			acpCDM.basisForAdmissionType = '311: HIGHER EDUCATION COURSE (COMPLETE/INCOMPLETE, AUST/OS)';
			acpCDM.documentationStatus = 'Satisfied';
			acpCDM.outcomeStatus = 'Offer';
			acpCDM.entryQualificationStatus = 'Qualified';
			acpCDM.offerResponseStatus = 'Pending';
			acpCDM.offerDate = Date.today().addDays(-5);
			acpCDM.actualOfferResponseDate = Date.today();

			// Create a PatchRequest object
			OESApplicationPayload.PatchRequest patchRequest = new OESApplicationPayload.PatchRequest();
			OESApplicationPayload.CDM_Application application = new OESApplicationPayload.CDM_Application();
			application.applicationId = [SELECT id, name FROM Application__c WHERE Id = :testApplication.app.Id].Name;
			application.crmContactId = testApplication.applicant.Id;
			application.applicationStatus = 'Submitted';
			application.visa = new ApplicationWSWrapper.CDM_Visa();
			application.visa.startDate = '13-06-219';
			application.coursePreferences = new List<OESApplicationPayload.CDM_ApplicationCoursePreference>{ acpCDM };
			patchRequest.application = application;
			OESApplicationPayload.PatchResponse response = new OESApplicationPayload.PatchResponse();
			Test.startTest();
			try {
				// WHEN : I invoke process()
				handler.process((RESTlib_Payload.Request) patchRequest, response);
				// WHEN : I invoke validate()
				handler.validate((RESTlib_Payload.Request) patchRequest);
				TriggerCommon.enableTrigger('Application_Course_Preference__c');
				TriggerCommon.disableTrigger('Application__c');

			} catch (RESTlib_Ex.InvalidRequestException e) {
				// THEN : exceptions should be thrown
				Assert.isTrue(e.getMessage().contains('Script-thrown exception'));
			} catch (Exception e) {
				// THEN : no exceptions should be thrown
				 Assert.fail('Unexpected InvalidRequestException thrown. Exception was not expected');
			}
			Test.stopTest();
		}
	}
}