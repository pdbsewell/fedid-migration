/**
 * @description       : Test methods for APNGApplicationPayload_
 * @author            : Ben Greenland
 * @group             :
 * @last modified on  : 2024-10-27
 * @last modified by  : Ben Greenland
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2024-10-02   Ben Greenland   Initial Version
 **/

@isTest(isParallel=false)//for permission set assignment
private class APNGApplicationPayload_Test {
	@TestSetup
	static void makeData() {
		TriggerCommon.disableTrigger('Country_Attribute__c');
		TriggerCommon.disableTrigger('Account');
		TriggerCommon.disableTrigger('Contact');
		TriggerCommon.disableTrigger('User');
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
			application.English_Language_Proficiency__c = 'Yes';
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

	@IsTest
	static void testPostRequest() {
		// GIVEN a PostRequest object
		APNGApplicationPayload.PostRequest req = new APNGApplicationPayload.PostRequest();
		Id contactId = fflib_IDGenerator.generate(Contact.SObjectType);
		// WHEN setting its properties
		req.campusLocation = 'Test Campus';
		req.residencyStatus = 'Domestic';
		req.contactId = contactId;
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
		Assert.areEqual('Test Campus', req.campusLocation, 'Campus location should match');
		Assert.areEqual('Domestic', req.residencyStatus, 'Residency status should match');
		Assert.areEqual(contactId, req.contactId, 'Contact ID should match');
		Assert.areEqual(1, req.phone.size(), 'Phone list size should match');
		Assert.areEqual('EXT-001', req.externalReferenceId, 'External reference ID should match');
		Assert.areEqual('Test notes', req.agentNotes, 'Agent notes should match');
		Assert.areEqual(1, req.email.size(), 'Email list size should match');
		Assert.areEqual('TEST-001', req.delegatorOrgUnitCode, 'Delegator org unit code should match');
	}

	@IsTest
	static void testPostResponse() {
		// GIVEN a PostResponse object
		APNGApplicationPayload.PostResponse res = new APNGApplicationPayload.PostResponse();

		// WHEN setting its properties
		res.application = new APNGApplicationPayload.ApplicationPostResponse();
		res.message = 'Success';

		// THEN the properties should be set correctly
		Assert.isNotNull(res.application);
		Assert.areEqual('Success', res.message);
	}

	@IsTest
	static void testCreateApplicationRecord() {
		// GIVEN a PostRequest object with test data
		APNGApplicationPayload.PostRequest req = new APNGApplicationPayload.PostRequest();
		req.campusLocation = 'Test Campus';
		req.residencyStatus = 'DOM-SUN.A';
		req.contactId = [SELECT CRM_ID__C FROM Contact LIMIT 1].Id;
		req.externalReferenceId = 'EXT-001';
		req.agentNotes = 'Test notes';
		req.delegatorOrgUnitCode = 'TEST-001';

		// WHEN creating an Application__c record
		Test.startTest();
		Application__c app;
		User u = new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser();
		// Create a test Applicant record
		System.runAs(u) {
			app = APNGApplicationPayload.createApplicationRecord(req);
		}
		Test.stopTest();

		// THEN the Application__c record should be created with correct data
		Assert.areEqual(req.campusLocation, app.Campus_Location__c);
		Assert.areEqual('DOM-SUN.A', app.Residency_Sub_status__c);
		Assert.areEqual('DOM-SUN', app.Residency_Status__c);
		Assert.areEqual(req.contactId, app.Applicant__c);
		Assert.areEqual(AgentPortalConstants.APP_CREATE_STATUS, app.status__c);
		Assert.areEqual(AgentPortalConstants.APP_CREATE_SOURCE, app.Source_System__c);
		Assert.areEqual(req.externalReferenceId, app.External_Reference_Id__c);
		Assert.areEqual(req.agentNotes, app.Agent_Notes__c);
		Assert.areEqual(req.delegatorOrgUnitCode, app.Delegator_Org_Unit_Code__c);
		Assert.areEqual(AgentPortalConstants.APP_CREATE_TYPE, app.Type_of_Study__c);
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
		APNGApplicationPayload.ApplicationPostResponse response = new APNGApplicationPayload.ApplicationPostResponse();
		response.populateFromApplication(app);

		// THEN the ApplicationPostResponse should be populated correctly
		Assert.areEqual(app.Id, response.id, 'Application ID should match');
		Assert.areEqual(app.Name, response.name, 'Application Name should match');
		Assert.areEqual(app.Applicant__c, response.applicantId, 'Applicant ID should match');
		Assert.areEqual(app.Status__c, response.status, 'Status should match');
		Assert.areEqual(app.Source_System__c, response.sourceSystem, 'Source System should match');
		Assert.areEqual(app.Campus_Location__c, response.campusLocation, 'Campus Location should match');
		Assert.areEqual(app.Residency_Sub_status__c, response.residencySubStatus, 'Residency Sub-status should match');
		Assert.areEqual(app.Residency_Status__c, response.residencyStatus, 'Residency Status should match');
	}

	@IsTest
	static void testAPNGApplicationPayload() {
		User u = new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser();
		// Create a test Applicant record

		System.runAs(u) {
			//GIVEN an Application__c
			Application__c app = ApplicationWSService.geApplicationById([SELECT Id FROM Application__c LIMIT 1].Id);
			// Instantiate ApplicationWrapper
			//WHEN we create an instance of ApplicationWrapper passing an Application__c
			APNGApplicationPayload.ApplicationWrapper appWrapper;
			appWrapper = new APNGApplicationPayload.ApplicationWrapper(app);
			// Verify fields
			//THEN all the fields should be assigned correctly
			assert.areEqual(app.Id, appWrapper.id, 'Application ID should match');
			assert.areEqual(app.Name, appWrapper.name, 'Application Name should match');
			assert.areEqual(app.Campus_Location__c, appWrapper.campusLocation, 'Campus Location should match');
			assert.areEqual(
				app.Callista_Application_Id__c,
				appWrapper.callistaApplicationId,
				'Callista Application ID should match'
			);
			assert.areEqual(app.Status__c, appWrapper.status, 'Status should match');
			assert.areEqual(app.Application_Type__c, appWrapper.applicationType, 'Application Type should match');
			assert.areEqual(app.Credit_Intention__c, appWrapper.creditIntention, 'Credit Intention should match');
			assert.areEqual(app.Applicant__r.Id, appWrapper.applicant.Id, 'Applicant ID should match');
			assert.areEqual(
				app.Sent_to_student_for_review_Timestamp__c,
				appWrapper.sentToStudentForReviewTimestamp,
				'Sent to Student for Review Timestamp should match'
			);
			assert.areEqual(
				app.Student_Accepted_Timestamp__c,
				appWrapper.studentAcceptedTimestamp,
				'Student Accepted Timestamp should match'
			);
			assert.areEqual(
				app.Agent_Accepted_Timestamp__c,
				appWrapper.agentAcceptedTimestamp,
				'Agent Accepted Timestamp should match'
			);
			assert.areEqual(app.AgentName__c, appWrapper.agentName, 'Agent Name should match');
			assert.areEqual(app.Visa_Type__c, appWrapper.visaType, 'Visa Type should match');
			assert.areEqual(
				app.Australian_Immigration_Office_Issued__c,
				appWrapper.australianImmigrationOfficeIssued,
				'Australian Immigration Office Issued should match'
			);
			assert.areEqual(app.Passport_Number__c, appWrapper.passportNumber, 'Passport Number should match');
			assert.areEqual(app.Visa_Number__c, appWrapper.visaNumber, 'Visa Number should match');
			assert.areEqual(app.Visa_Start_Date__c, appWrapper.visaStartDate, 'Visa Start Date should match');
			assert.areEqual(app.Visa_End_Date__c, appWrapper.visaEndDate, 'Visa End Date should match');
			assert.areEqual(
				app.Student_Pass_Availability__c,
				appWrapper.studentPassAvailability,
				'Student Pass Availability should match'
			);
			assert.areEqual(
				app.Refused_Entry_Visa_To_Any_Country__c,
				appWrapper.refusedEntryVisaToAnyCountry,
				'Refused Entry Visa to Any Country should match'
			);
			assert.areEqual(
				app.Breached_Visa_Condition__c,
				appWrapper.breachedVisaCondition,
				'Breached Visa Condition should match'
			);
			assert.areEqual(
				app.Medical_Health_Prevent_Visa__c,
				appWrapper.medicalHealthPreventVisa,
				'Medical Health Prevent Visa should match'
			);
			assert.areEqual(
				app.Protection_Visa_In_Any_Country__c,
				appWrapper.protectionVisaInAnyCountry,
				'Protection Visa in Any Country should match'
			);
			assert.areEqual(
				app.Convicted_Of_Crime_Offence__c,
				appWrapper.convictedOfCrimeOffence,
				'Convicted of Crime Offence should match'
			);
			assert.areEqual(
				app.Callista_Applicant_Id__c,
				appWrapper.callistaApplicantId,
				'Callista Applicant ID should match'
			);
			assert.areEqual(
				app.English_Language_Proficiency__c == 'Yes' ? true : false,
				appWrapper.englishLanguageProficiency,
				'English Language Proficiency should match'
			);
			assert.areEqual(app.Residency_Status__c, appWrapper.residencyStatus, 'Residency Status should match');
			assert.areEqual(app.Residency_Sub_status__c, appWrapper.residencySubStatus, 'Residency Sub-status should match');
			assert.areEqual(app.Source_System__c, appWrapper.sourceSystem, 'Source System should match');
			assert.areEqual(app.HasDisabilities__c, appWrapper.hasDisabilities, 'Has Disabilities should match');
			assert.areEqual(
				app.Existing_Aus_disability_support__c,
				appWrapper.existingAusDisabilitySupport,
				'Existing Aus Disability Support should match'
			);
			assert.areEqual(
				app.is_Principal_Course_Transfer__c,
				appWrapper.isPrincipalCourseTransfer,
				'Is Principal Course Transfer should match'
			);
			assert.areEqual(app.Is_Sponsored__c, appWrapper.isSponsored, 'Is Sponsored should match');
			assert.areEqual(app.Sponsor_Name__c, appWrapper.sponsorName, 'Sponsor Name should match');
			assert.areEqual(app.Sponsorship_Status__c, appWrapper.sponsorshipStatus, 'Sponsorship Status should match');
			assert.areEqual(app.Sponsorship_Type__c, appWrapper.sponsorshipType, 'Sponsorship Type should match');
			assert.areEqual(
				app.Sponsor_Scholarship_organisation__c,
				appWrapper.sponsorScholarshipOrganisation,
				'Sponsor Scholarship Organisation should match'
			);
			assert.areEqual(app.Fee_Payment_Mode__c, appWrapper.feePaymentMode, 'Fee Payment Mode should match');
			assert.areEqual(app.Fee_Amount__c, appWrapper.feeAmount, 'Fee Amount should match');
			assert.areEqual(app.Fee_Payment__c, appWrapper.feePayment, 'Fee Payment should match');
			assert.areEqual(app.Transaction_Amount__c, appWrapper.transactionAmount, 'Transaction Amount should match');
			assert.areEqual(app.Transaction_Date__c, appWrapper.transactionDate, 'Transaction Date should match');
			assert.areEqual(
				app.Transaction_Reference__c,
				appWrapper.transactionReference,
				'Transaction Reference should match'
			);
			assert.areEqual(app.Transaction_Source__c, appWrapper.transactionSource, 'Transaction Source should match');
			assert.areEqual(app.Fee_Waiver_Code__c, appWrapper.feeWaiverCode, 'Fee Waiver Code should match');
			assert.areEqual(app.Fee_Waiver_Redeemed__c, appWrapper.feeWaiverRedeemed, 'Fee Waiver Redeemed should match');
			assert.areEqual(app.Agent_Notes__c, appWrapper.agentNotes, 'Agent Notes should match');
			assert.areEqual(app.MyApp_User_Status__c, appWrapper.myAppUserStatus, 'MyApp User Status should match');
		}
	}

	@isTest
	public static void testWorkExperienceWrapper() {
		User u = new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser();
		System.runAs(u) {
			//GIVEN: an application with work Experiences
			Application__c app = [SELECT Id, Name FROM Application__c LIMIT 1];
			//WHEN : I retrieve the work experience wrapper
			APNGApplicationPayload.WorkExperiences experiences = APNGApplicationSelector.getWorkExperiencesByApplicationId(
				app.Name
			);
			//THEN : the work experience wrapper should contain the work experience data
			Assert.areNotEqual(null, experiences, 'Work experiences should not be null');
			assert.areEqual(1, experiences.applicationExperiences.size(), 'There should be one work experience');
			assert.areEqual('Cat', experiences.applicationExperiences[0].position, 'Position should match');
			assert.areEqual(
				'Bunnings',
				experiences.applicationExperiences[0].employerName,
				'employerName title should match'
			);
			assert.areEqual(Date.today(), experiences.applicationExperiences[0].startDate, 'Start date should match');
			assert.areEqual(Date.today(), experiences.applicationExperiences[0].endDate, 'End date should match');
			assert.areEqual('Bobo', experiences.applicationExperiences[0].contactPersonFirstName, 'Description should match');
			assert.areEqual(1, experiences.recordCount, 'record count not correct');
		}
	}

	@IsTest
	static void testContactQualificationWrapper() {
		Test.startTest();
		//GIVEN: an application with Qualification
		System.runAs(new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser()) {
			Application__c app = [SELECT Id, Name FROM Application__c LIMIT 1];
			//WHEN : I retrieve the Qualification wrapper

			APNGApplicationPayload.Qualifications quals = APNGApplicationSelector.getContactQualificationsByApplicationId(
				app.Name
			);

			//THEN : the Qualification wrapper should contain the Qualification data
			assert.areNotEqual(null, quals, 'Qualifications should not be null');
			assert.areEqual(1, quals.applicationQualifications.size(), 'There should be one Contact Qualification');
			assert.isTrue(
				quals.applicationQualifications[0].qualificationName.contains('Master'),
				'Qualification Name should match'
			);
			assert.areEqual(
				'Tertiary Education',
				quals.applicationQualifications[0].qualificationType,
				'Qualification Type should match'
			);
		}
		Test.stopTest();
	}

	@IsTest
	static void testACPWrapper() {
		Test.startTest();
		//GIVEN: an application with Course Preferences
		System.runAs(new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser()) {
			Application__c app = [
				SELECT Id, Name, Applicant__r.id
				FROM Application__c
				LIMIT 1
			];
			List<Application_Course_Preference__c> acpList = TestHelper.createACP(1, app.Applicant__r.id);
			acpList[0].Application__c = app.Id;
			insert acpList;
			//WHEN : I retrieve the Course Preference wrapper
			List<APNGApplicationPayload.ApplicationCoursePreference> acps = APNGApplicationSelector.getApplicationCoursePreferences(
				app.Name
			);
			//THEN : the Course Preference wrapper should contain the Course Preference data
			assert.areNotEqual(null, acps, 'acps should not be null');
			assert.areEqual(1, acps.size(), 'There should be one Contact acps');
		}
		Test.stopTest();
	}

	@IsTest
	static void testGetRequest() {
		Test.startTest();
		System.runAs(new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser()) {
			//GIVEN GetRequest
			APNGApplicationPayload.GetRequest gr = new APNGApplicationPayload.GetRequest();
			//WHEN values are set
			gr.applicationId = 'abc';
			gr.related = 'fish';
			//then correct values are returned
			Assert.areEqual('abc', gr.applicationId, 'applicationId should match');
			Assert.areEqual('fish', gr.related, 'related should match');
			//WHEN related is null
			APNGApplicationPayload.GetRequest gr1 = new APNGApplicationPayload.GetRequest();
			gr1.applicationId = 'abc';
			gr1.related = null;
			//THEN related should be ''
			Assert.areEqual('', gr1.related, 'related should be empty when null');
		}
		Test.stopTest();
	}

	@isTest
	static void testGetResponseApplication() {
		// GIVEN: An agent user and an application payload with agent notes
		Test.startTest();
		System.runAs(new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser()) {
			APNGApplicationPayload.GetResponseApplication gr = new APNGApplicationPayload.GetResponseApplication();
			APNGApplicationPayload.ApplicationWrapper application = new APNGApplicationPayload.ApplicationWrapper(
				new Application__c(Agent_Notes__c = 'rabbit')
			);
			APNGApplicationPayload.ApplicationDetails appdet = new APNGApplicationPayload.ApplicationDetails();
			appdet.details = application;
			// WHEN: The application details and message are set
			gr.application = appdet;
			gr.message = 'caught';
			// THEN: The agent notes should not be null and the message should match
			Assert.isNotNull(gr.application.details.agentNotes, 'agentNotes should not be null');
			Assert.areEqual('caught', gr.message, 'message should match');
		}
		Test.stopTest();
	}

	@isTest
	static void testGetResponseWorkExperiences() {
		// GIVEN: An agent user and a work experience payload with an external ID
		Test.startTest();
		System.runAs(new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser()) {
			APNGApplicationPayload.GetResponseWorkExperiences grWex = new APNGApplicationPayload.GetResponseWorkExperiences();
			APNGApplicationPayload.WorkExperienceWrapper wexw = new APNGApplicationPayload.WorkExperienceWrapper(
				new Work_Experience__c(External_ID__c = 'bike')
			);
			APNGApplicationPayload.WorkExperiences wex = new APNGApplicationPayload.WorkExperiences();
			wex.applicationExperiences = new List<APNGApplicationPayload.WorkExperienceWrapper>{ wexw };
			// WHEN: The work experience details and message are set
			grWex.application = wex;
			grWex.message = 'caught';
			// THEN: The external ID should not be null and the message should match
			Assert.isNotNull(grWex.application.applicationExperiences[0].externalId, 'externalId should not be null');
			Assert.areEqual('caught', grWex.message, 'message should match');
		}
		Test.stopTest();
	}
	@isTest
	static void testGetResponseQualifications() {
		// GIVEN: An agent user and a qualification payload with an institution name
		Test.startTest();
		System.runAs(new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser()) {
			APNGApplicationPayload.GetResponseQualifications grQuals = new APNGApplicationPayload.GetResponseQualifications();
			APNGApplicationPayload.ContactQualificationWrapper qualW = new APNGApplicationPayload.ContactQualificationWrapper(
				new Contact_Qualification__c(Institution_Name__c = 'bike')
			);
			APNGApplicationPayload.Qualifications quals = new APNGApplicationPayload.Qualifications();
			quals.applicationQualifications = new List<APNGApplicationPayload.ContactQualificationWrapper>{ qualW };
			// WHEN: The qualification details and message are set
			grQuals.application = quals;
			grQuals.message = 'caught';
			// THEN: The institution name should be correct and the message should match
			Assert.areEqual(
				'bike',
				grQuals.application.applicationQualifications[0].institutionName,
				'institutionName should be correct'
			);
			Assert.areEqual('caught', grQuals.message, 'message should match');
		}
		Test.stopTest();
	}
}