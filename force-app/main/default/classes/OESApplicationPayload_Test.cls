/**
 * @description       : OESApplicationPayload_Test
 * @author            : Ben Greenland
 * @group             : OES Application Web
 * @last modified on  : 2024-10-27
 * @last modified by  : Ben Greenland
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2024-10-27   Ben Greenland   Initial Version
 **/
@isTest(isParallel=false) // APEX_DATA_ACCESS_RESTRICTION // Course Offering sharing rule
private class OESApplicationPayload_Test {
	static AgentPortalTestDataBuilder.AgentPortalUser portalUser;
	@TestSetup
	static void makeData() {
		TriggerCommon.disableTrigger('Country_Attribute__c');
		TriggerCommon.disableTrigger('Account');
		TriggerCommon.disableTrigger('Contact');
		TriggerCommon.disableTrigger('User');
		portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();
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

		Course_Offering__c courseOffering_1 = StudFirst_TestHelper.createCourseOffering(course);
		courseOffering_1.Course_Code__c = 'E6001';
		courseOffering_1.Course_Version_Number__c = 1;
		courseOffering_1.Admission_Calendar_Type__c = 'ADM-0';
		courseOffering_1.Location_Code__c = 'CLAYTON';
		courseOffering_1.Attendance_Type__c = 'FT';
		courseOffering_1.Attendance_Mode__c = 'IN';
		courseOffering_1.Admission_Category__c = 'UG-CSP';
		courseOffering_1.Academic_CI_Sequence_Number__c = 1111;
		courseOffering_1.Admission_CI_Sequence_Number__c = 1111;
		courseOffering_1.Unit_Set_Code__c = null;
		courseOffering_1.Unit_Set_Version__c = null;
		courseOffering_1.Citizenship_type__c = 'INT-TEP';
		courseOffering_1.Admission_Calendar_Description__c = 'CrOf1';
		courseOffering_1.Active__c = true;

		courseOfferings.add(courseOffering_1);

		Course_Offering__c courseOffering_2 = StudFirst_TestHelper.createCourseOffering(course);
		courseOffering_2.Course_Code__c = 'E6001';
		courseOffering_2.Course_Version_Number__c = 1;
		courseOffering_2.Admission_Calendar_Type__c = 'ADM-0';
		courseOffering_2.Location_Code__c = 'CLAYTON';
		courseOffering_2.Attendance_Type__c = 'FT';
		courseOffering_2.Attendance_Mode__c = 'EX';
		courseOffering_2.Admission_Category__c = 'UG-CSP';
		courseOffering_2.Academic_CI_Sequence_Number__c = 1111;
		courseOffering_2.Admission_CI_Sequence_Number__c = 1111;
		courseOffering_2.Unit_Set_Code__c = null;
		courseOffering_2.Unit_Set_Version__c = null;
		courseOffering_2.Citizenship_type__c = 'INT-TEP';
		courseOffering_2.Admission_Calendar_Description__c = 'CrOf2';
		courseOffering_2.Active__c = true;

		courseOfferings.add(courseOffering_2);

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
			coshare.ParentId = courseOffering_1.Id;
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

	@IsTest
	static void testPostRequest() {
		// GIVEN a PostRequest object
		OESApplicationPayload.PostRequest req = new OESApplicationPayload.PostRequest();

		// WHEN setting its properties
		req.campusLocation = 'Test Campus';
		req.residencyStatus = 'Domestic';
		req.contactId = '003000000000001AAA';
		req.phone = new List<CommonWSPayload.Phone>();
		CommonWSPayload.Phone phone = new CommonWSPayload.Phone();
		phone.phoneNumber = '1234567890';
		phone.type = 'Mobile';
		req.phone.add(phone);
		req.externalReferenceId = 'EXT-001';
		req.agentNotes = 'Test notes';
		req.email = new List<CommonWSPayload.Email>();
		CommonWSPayload.Email email = new CommonWSPayload.Email();
		email.email = 'test@example.com';
		email.type = 'Personal';
		req.email.add(email);
		req.delegatorOrgUnitCode = 'TEST-001';

		// THEN the properties should be set correctly
		Assert.areEqual('Test Campus', req.campusLocation, 'Invalid campus location');
		Assert.areEqual('Domestic', req.residencyStatus, 'Invalid residency status');
		Assert.areEqual('003000000000001AAA', req.contactId, 'Invalid contact ID');
		Assert.areEqual(1, req.phone.size(), 'Invalid phone size');
		Assert.areEqual('EXT-001', req.externalReferenceId, 'Invalid external reference ID');
		Assert.areEqual('Test notes', req.agentNotes, 'Invalid agent notes');
		Assert.areEqual(1, req.email.size(), 'Invalid email size');
		Assert.areEqual('TEST-001', req.delegatorOrgUnitCode, 'Invalid delegator org unit code');
	}

	@IsTest
	static void testPostResponse() {
		// GIVEN a PostResponse object
		OESApplicationPayload.PostResponse res = new OESApplicationPayload.PostResponse();

		// WHEN setting its properties
		res.application = new OESApplicationPayload.ApplicationPostResponse();
		res.message = 'Success';

		// THEN the properties should be set correctly
		Assert.isNotNull(res.application);
		Assert.areEqual('Success', res.message);
	}

	@IsTest
	static void testCreateApplicationRecord() {
		// GIVEN a PostRequest object with test data
		OESApplicationPayload.PostRequest req = new OESApplicationPayload.PostRequest();
		req.campusLocation = 'Test Campus';
		req.residencyStatus = 'DOM-SUN.A';
		req.contactId = [SELECT Id FROM Contact LIMIT 1].Id;
		req.externalReferenceId = 'EXT-001';
		req.agentNotes = 'Test notes';
		req.delegatorOrgUnitCode = 'TEST-001';

		// WHEN creating an Application__c record
		Test.startTest();
		User userx = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1];
		Application__c app;
		System.runAs(userx) {
			app = OESApplicationPayload.createApplicationRecord(req);
		}
		Test.stopTest();

		// THEN the Application__c record should be created with correct data
		Assert.areEqual(req.campusLocation, app.Campus_Location__c, 'Invalid campus location');
		Assert.areEqual('DOM-SUN.A', app.Residency_Sub_status__c, 'Invalid residency sub status');
		Assert.areEqual('DOM-SUN', app.Residency_Status__c, 'Invalid residency status');
		Assert.areEqual(req.contactId, app.Applicant__c, 'Invalid applicant ID');
		Assert.areEqual(AgentPortalConstants.APP_CREATE_STATUS, app.Status__c, 'Invalid application status');
		Assert.areEqual(AgentPortalConstants.OES_CREATE_SOURCE, app.Source_System__c, 'Invalid source system');
		Assert.areEqual(req.externalReferenceId, app.External_Reference_Id__c, 'Invalid external reference ID');
		Assert.areEqual(req.agentNotes, app.Agent_Notes__c, 'Invalid agent notes');
		Assert.areEqual(req.delegatorOrgUnitCode, app.Delegator_Org_Unit_Code__c, 'Invalid delegator org unit code');
		Assert.areEqual(AgentPortalConstants.APP_CREATE_TYPE, app.Type_of_Study__c, 'Invalid type of study');
	}

	@IsTest
	static void testApplicationPostResponse() {
		// GIVEN an Application__c record
		Application__c app = new Application__c(
			Applicant__c = [SELECT Id FROM Contact LIMIT 1]
			.Id,
			Status__c = 'Draft',
			Source_System__c = 'OES',
			Campus_Location__c = 'Australia',
			Residency_Sub_status__c = 'DOM-SUN.A',
			Residency_Status__c = 'DOM-SUN'
		);
		insert app;

		// WHEN creating an ApplicationPostResponse
		OESApplicationPayload.ApplicationPostResponse response = new OESApplicationPayload.ApplicationPostResponse();
		response.populateFromApplication(app);

		// THEN the ApplicationPostResponse should be populated correctly
		Assert.areEqual(app.Id, response.id, 'Invalid application ID');
		Assert.areEqual(app.Name, response.name, 'Invalid application name');
		Assert.areEqual(app.Applicant__c, response.applicantId, 'Invalid applicant ID');
		Assert.areEqual(app.Status__c, response.status, 'Invalid status');
		Assert.areEqual(app.Source_System__c, response.sourceSystem, 'Invalid source system');
		Assert.areEqual(app.Campus_Location__c, response.campusLocation, 'Invalid campus location');
		Assert.areEqual(app.Residency_Sub_status__c, response.residencySubStatus, 'Invalid residency sub status');
		Assert.areEqual(app.Residency_Status__c, response.residencyStatus, 'Invalid residency status');
	}

	@IsTest
	static void testPatchRequest() {
        TriggerCommon.disableTrigger('Country_Attribute__c');
		TriggerCommon.disableTrigger('Account');
		TriggerCommon.disableTrigger('Contact');
		TriggerCommon.disableTrigger('User');

		// create a test Agent Portal User
		// Call the validateWorkExperience method
		portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();
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
		AgentPortalTestDataBuilder.Application testApplication = new AgentPortalTestDataBuilder.Application()
			.withAgent(portalUser)
			.withCourseOffering(co)
			.build();

		// Retrieve test data
		ApplicationWSWrapper.CDM_CourseOffering coCDM = new ApplicationWSWrapper.CDM_CourseOffering();
		coCDM.crmRecordId = co.Id;
		coCDM.courseOfferingUid = co.Course_Offering_UID__c;
		coCDM.applicationRecord = testApplication.app;
		testApplication.app.Status__c = 'Submitted';
		update testApplication.app;
		//  Minimum ACP

		System.runAs(portalUser.testUser) {
			Test.startTest();
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
			//GIVEN: OESApplicationPayload.PatchRequest payload is constructed with the required data/json
			// Create a PatchRequest object
			OESApplicationPayload.PatchRequest patchRequest = new OESApplicationPayload.PatchRequest();
			OESApplicationPayload.CDM_Application application = new OESApplicationPayload.CDM_Application();
			application.applicationId = [SELECT id, name FROM Application__c WHERE Id = :testApplication.app.Id].Name;
			application.crmContactId = testApplication.applicant.Id;
			application.applicationStatus = 'Submitted';
			application.visa = new ApplicationWSWrapper.CDM_Visa();
			application.visa.startDate = '13-06-2019';
			application.coursePreferences = new List<OESApplicationPayload.CDM_ApplicationCoursePreference>{ acpCDM };
			try {
				patchRequest = new OESApplicationPayload.PatchRequest(application);
				patchRequest.application = application;
			   //WHEN: process method is called on the OES update webservice method
				// Process application in draft
				patchRequest.process();
			} catch (RESTlib_Ex.WebServiceException e) {
				Nebula.Logger.error('RESTlib_Ex.InvalidRequestException occured while OESApplicationPayload.process()', e);
			}
			Test.stopTest();
			//THEN: Assert that ACP has been updated with the apppropriate Basis Admission Type and Offer Lapse date values
			Application_Course_Preference__c acp = [SELECT ID ,Basis_For_Adminssion_Type__c,Offer_Response_Date__c FROM Application_Course_Preference__c 
													WHERE Basis_For_Adminssion_Type__c='311' LIMIT 1];
			Assert.areEqual('311', acp.Basis_For_Adminssion_Type__c, 'Invalid Basis Admission Type updated');
			Assert.areEqual( Date.today(), acp.Offer_Response_Date__c, 'Invalid Offer_Response_Date__c updated');

		}
        TriggerCommon.enableTrigger('Country_Attribute__c');
		TriggerCommon.enableTrigger('Account');
		TriggerCommon.enableTrigger('Contact');
		TriggerCommon.enableTrigger('User');
	}
}