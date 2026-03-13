/**
 * @description       : Test class for ApplicationWSWrapper
 * @author            : Ben Greenland
 * @group             : Application Web service
 * @last modified on  : 2024-11-24
 * @last modified by  : Ben Greenland
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2024-11-24   Girish Kulkarni   Initial Version
 * 1.1   2024-11-24   Ben Greenland       Added test methods for CDM_WorkExperience, CDM_Qualification, and CDM_Payment and asApplicationRecord
 *
 *
 **/
@isTest(isparallel=false) // APEX_DATA_ACCESS_RESTRICTION  //required for permission set assignement
@SupressWarnings('PMD.ClassNamingConventions')
public with sharing class ApplicationWSWrapperTest {
	@TestSetup
	static void makeData() {
		TriggerCommon.disableTrigger('Country_Attribute__c');
		TriggerCommon.disableTrigger('Account');
		TriggerCommon.disableTrigger('Contact');
		TriggerCommon.disableTrigger('User');
		AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();
		// create OES user
		PermissionSet oesPs = [
			SELECT Id
			FROM PermissionSet
			WHERE Name = 'OES_Permission_Set'
		];
		PermissionSetAssignment psa = new PermissionSetAssignment(
			AssigneeId = portalUser.testUser.Id,
			PermissionSetId = oesPs.Id
		);

		// avoid MIXED_DML_OPERATION
		System.runAs(new User(Id = UserInfo.getUserId())) {
			insert psa;
		}

		// add an institution
		Institution__c testSchool = new Institution__c();
		testSchool.Country__c = 'Australia';
		testSchool.Institution_Country__c = [SELECT id FROM Country_Attribute__c WHERE Name = 'Australia' LIMIT 1].id;
		testSchool.Institution_Code__c = '835';
		testSchool.Institution_Name__c = 'CANNING COLLEGE AUSTRALIA';
		insert testSchool;
		Institution__c tertInsRec = new Institution__c();
		tertInsRec.Country__c = 'Australia';
		testSchool.Institution_Country__c = [SELECT id FROM Country_Attribute__c WHERE Name = 'Australia' LIMIT 1].id;
		tertInsRec.Institution_Code__c = '834';
		tertInsRec.Institution_Name__c = 'CANNING COLLEGE AUSTRALIA';
		tertInsRec.Type__c = 'Secondary';
		insert tertInsRec;
		// create a contact-qualification that is "draft"
		Country_Attribute__c country = new Country_Attribute__c(
			Name = 'INDIA',
			Callista_Code__c = '7103',
			Country__c = 'INDIA'
		);
		insert country;
		Country_Attribute__c auCountry = new Country_Attribute__c(
			Name = 'AUSTRALIA',
			Callista_Code__c = BDPConstants.AUSTRALIA_CALLISTA_CODE,
			Country__c = 'Australia'
		);
		insert auCountry;
		System.runAs(portalUser.testUser) {
			Contact applicant = StudFirst_TestHelper.createInternationalApplicant();
			insert applicant;
			Qualification__c testQualification = StudFirst_TestHelper.createQualification('Test Qualification');
			Contact_Qualification__c englishTestQua = StudFirst_TestHelper.createContactQualification(
				applicant,
				testQualification,
				'English Test'
			);
			englishTestQua.Contact__c = applicant.Id;
			englishTestQua.Institution_Code__c = testSchool.Institution_Code__c;
			englishTestQua.Institution_Name__c = testSchool.Institution_Name__c;
			englishTestQua.Other_Qualification__c = 'test of english';
			insert englishTestQua;
			// create a contact-qualification that is "completed"

			Application__c application = StudFirst_TestHelper.createInternationalApplication(applicant, auCountry);
			insert application;
			Work_Experience__c wex = StudFirst_TestHelper.createWorkExperience(applicant);
			Work_Experience__c wex1 = StudFirst_TestHelper.createWorkExperience(applicant);
			wex1.Position__c = 'CEO';
			wex1.Employer_Name__c = 'XYZ infotech';
			wex1.Country__c = country.Id;
			Work_Experience__c wex2 = StudFirst_TestHelper.createWorkExperience(applicant);
			wex2.Position__c = 'Developer';
			wex2.Employer_Name__c = 'ABC infotech';
			wex2.Country__c = auCountry.Id;
			insert new List<Work_Experience__c>{ wex, wex1, wex2 };
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

			Course_Offering__c oesCourseOfferingXX = StudFirst_TestHelper.createCourseOffering(course);
			oesCourseOfferingXX.Course_Type__c = '21'; // any type that is not PD
			oesCourseOfferingXX.Portal_Available__c = true;
			oesCourseOfferingXX.Default_Admission_Category_Ind__c = true;
			oesCourseOfferingXX.Location_Code__c = 'ONLINE';
			oesCourseOfferingXX.Fee_Category__c = 'AU_DOM_MO';
			oesCourseOfferingXX.Course_Offering_UID__c = 'CO-COCOID1OES';
			oesCourseOfferingXX.Active__c = true;
			oesCourseOfferingXX.Mix_Unique_Id__c = AgentPortalTestDataFactory.util.generateRandomString(10);
			insert oesCourseOfferingXX;

			Application_Course_Preference__c acp = new Application_Course_Preference__c();
			acp.Course_Offering__c = oesCourseOfferingXX.Id;
			acp.Application__c = application.Id;
			insert acp;
		}
		TriggerCommon.enableTrigger('Country_Attribute__c');
		TriggerCommon.enableTrigger('Account');
		TriggerCommon.enableTrigger('Contact');
		TriggerCommon.enableTrigger('User');
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
	}
	@isTest
	static void testAsApplicationRecord() {
		User portalUser = [SELECT Id FROM User WHERE email = 'testAgentLastName@TestEmail.com' LIMIT 1];

		System.runAs(portalUser) {
			Contact applicant = [SELECT Id, CRM_ID__c FROM Contact WHERE LastName = 'Chen' LIMIT 1];
			Application__c testApplication = [
				SELECT id, Applicant__c, Name, Status__c
				FROM Application__c
				WHERE Applicant__c = :applicant.Id
				LIMIT 1
			];

			// Create instance of CDM_Application
			String jsonTemplate = '{ "smsApplicantId": "", "crmContactId": "{0}", "applicationId": "{1}", "applicationStatus": "Draft", "agentNotes": "Test Notes", "applicationType": "Default", "residencyStatus": "INTRNTNL.B", "passportNumber": "123456", "hasDisability": { "code": "No" }, "existingDisabilitySupport": {}, "isPrincipalCourseTransfer": false, "hasRequestForScholarship": false, "hasRequestForAdvancedStanding": false, "englishLanguageProficiency": true, "sponsorScholarship": "", "sponsorStatus": {}, "visa": { "citizenship": { "crmRecordId": "{2}", "code": "AU", "value": "Australia" }, "type": {}, "visaNumber": "", "hasRefusedEntry": { "code": "No" }, "hasBreachedVisa": { "code": "No" }, "hasMedicalIssues": { "code": "No" }, "hasProtectionVisa": { "code": "No" }, "hasConvictedOfCrime": { "code": "No" }, "immigrationOfficeIssued": "" } }';

			Country_Attribute__c country = [
				SELECT Id
				FROM Country_Attribute__c
				WHERE Name = 'AUSTRALIA' AND Callista_Code__c = :BDPConstants.AUSTRALIA_CALLISTA_CODE
				LIMIT 1
			];

			// Replace placeholders in JSON
			jsonTemplate = jsonTemplate.replace('{0}', applicant.CRM_ID__c);
			jsonTemplate = jsonTemplate.replace('{1}', testApplication.Name);
			jsonTemplate = jsonTemplate.replace('{2}', country.Id);

			APNGApplicationPayload.CDM_Application cdmApp = new APNGApplicationPayload.CDM_Application();
			cdmApp = (APNGApplicationPayload.CDM_Application) JSON.deserialize(
				jsonTemplate,
				APNGApplicationPayload.CDM_Application.class
			);

			// WHEN converting to Application record
			Test.startTest();
			Application__c result = cdmApp.asApplicationRecord();
			Test.stopTest();

			// THEN verify the application record is created correctly
			Assert.areEqual(testApplication.Name, result.Name, 'Application name should match');
			Assert.areEqual('Draft', result.Status__c, 'Status should be Draft');
			Assert.areEqual('Test Notes', result.Agent_Notes__c, 'Agent notes should match');
			Assert.areEqual('Default', result.Application_Type__c, 'Application type should match');
			Assert.areEqual('INTRNTNL', result.Residency_Status__c, 'Residency status should match');
			Assert.areEqual('INTRNTNL.B', result.Residency_Sub_status__c, 'Residency sub-status should match');
			Assert.areEqual('123456', result.Passport_Number__c, 'Passport number should match');
			Assert.areEqual('No', result.HasDisabilities__c, 'Disability status should match');
			Assert.areEqual(false, result.is_Principal_Course_Transfer__c, 'Principal course transfer should match');
			Assert.areEqual(false, result.Is_Sponsored__c, 'Sponsorship status should match');
			Assert.areEqual('Yes', result.English_Language_Proficiency__c, 'English proficiency should match');
		}
	}
	@isTest
	static void testAddVisaDetailsToApplication() {
		// Create test data
		Application__c testApplication = new Application__c();
		insert testApplication;

		ApplicationWSWrapper.CDM_Visa visa = new ApplicationWSWrapper.CDM_Visa();
		visa.citizenship = new ApplicationWSWrapper.CDM_Country();
		visa.citizenship.uniqueCountryExternalId = '123';
		visa.citizenship.crmRecordId = '456';
		visa.singleEntryVisaCountry = new ApplicationWSWrapper.CDM_Country();
		// For APNG purposes
		visa.singleEntryVisaCountry.crmRecordId = '456';
		// For OES purposes
		visa.singleEntryVisaCountry.uniqueCountryExternalId = '456';
		visa.visaNumber = '789';
		visa.type = new ApplicationWSWrapper.CDM_VisaType();
		visa.type.code = 'TypeCode';
		visa.startDate = '2024-01-01';
		visa.endDate = '2024-12-31';
		visa.hasRefusedEntry = new ApplicationWSWrapper.CDM_Status();
		visa.hasRefusedEntry.code = 'No';
		visa.hasBreachedVisa = new ApplicationWSWrapper.CDM_Status();
		visa.hasBreachedVisa.code = 'No';
		visa.hasMedicalIssues = new ApplicationWSWrapper.CDM_Status();
		visa.hasMedicalIssues.code = 'No';
		visa.hasProtectionVisa = new ApplicationWSWrapper.CDM_Status();
		visa.hasProtectionVisa.code = 'No';
		visa.hasConvictedOfCrime = new ApplicationWSWrapper.CDM_Status();
		visa.hasConvictedOfCrime.code = 'No';
		visa.immigrationOfficeIssued = 'Office';
		visa.applicationRecord = testApplication;

		// Call the method
		Test.startTest();
		visa.addVisaDetailsToApplication();
		Test.stopTest();

		// Verify the results
		Assert.areEqual(
			'123',
			testApplication.Citizenship_Country__r.uniqueCountryExternalId__c,
			'Citizenship country external ID should match'
		);
		Assert.areEqual(
			'456',
			testApplication.Single_Entry_Visa__r.uniqueCountryExternalId__c,
			'Single entry visa country external ID should match'
		);
		Assert.areEqual('789', testApplication.Visa_Number__c, 'Visa number should match');
		Assert.areEqual('TypeCode', testApplication.Visa_Type__c, 'Visa type should match');
		Assert.areEqual(Date.valueOf('2024-01-01'), testApplication.Visa_Start_Date__c, 'Visa start date should match');
		Assert.areEqual(Date.valueOf('2024-12-31'), testApplication.Visa_End_Date__c, 'Visa end date should match');
		Assert.areEqual(
			'No',
			testApplication.Refused_entry_visa_to_any_country__c,
			'Refused entry visa status should match'
		);
		Assert.areEqual('No', testApplication.Breached_visa_condition__c, 'Breached visa condition status should match');
		Assert.areEqual(
			'No',
			testApplication.Medical_health_prevent_visa__c,
			'Medical health prevent visa status should match'
		);
		Assert.areEqual('No', testApplication.Protection_visa_in_any_country__c, 'Protection visa status should match');
		Assert.areEqual('No', testApplication.Convicted_of_crime_offence__c, 'Convicted of crime status should match');
		Assert.areEqual(
			'Office',
			testApplication.Australian_Immigration_Office_Issued__c,
			'Australian immigration office issued should match'
		);
	}

	@isTest
	static void testApplicationWrapperConstructor() {
		// GIVEN a portal user and application
		User portalUser = [SELECT Id FROM User WHERE email = 'testAgentLastName@TestEmail.com' LIMIT 1];

		System.runAs(portalUser) {
			// Query application with all required fields
			Application__c app = [
				SELECT
					Id,
					Name,
					Status__c,
					Campus_Location__c,
					Application_Type__c,
					Credit_Intention__c,
					Citizenship_Country__r.uniqueCountryExternalId__c,
					Citizenship_Country__r.Name,
					Citizenship_Country__r.Country__c,
					Citizenship_Country__r.ISO_Alpha_2__c,
					Citizenship_Country__r.Id,
					Single_Entry_Visa__r.uniqueCountryExternalId__c,
					Single_Entry_Visa__r.Name,
					Single_Entry_Visa__r.Country__c,
					Single_Entry_Visa__r.ISO_Alpha_2__c,
					Single_Entry_Visa__r.Id,
					Callista_Application_Id__c,
					LastModifiedDate,
					Agent_Notes__c,
					Residency_Status__c,
					Residency_Sub_status__c,
					Passport_Number__c,
					HasDisabilities__c,
					is_Principal_Course_Transfer__c,
					Is_Sponsored__c,
					English_Language_Proficiency__c,
					Fee_Payment_Mode__c,
					Fee_Amount__c,
					Transaction_Amount__c,
					Transaction_Date__c,
					Transaction_Source__c,
					Transaction_Reference__c,
					Fee_Payment__c,
					Fee_Waiver_Code__c,
					Fee_Waiver_Redeemed__c,
					Applicant__c,
					Applicant__r.Id,
					Applicant__r.CRM_ID__c,
					Sent_to_student_for_review_Timestamp__c,
					Student_Accepted_Timestamp__c,
					Agent_Accepted_Timestamp__c,
					AgentName__c,
					Visa_Type__c,
					Australian_Immigration_Office_Issued__c,
					Visa_Number__c,
					Visa_Start_Date__c,
					Visa_End_Date__c,
					Student_Pass_Availability__c,
					Refused_entry_visa_to_any_country__c,
					Breached_visa_condition__c,
					Medical_health_prevent_visa__c,
					Protection_visa_in_any_country__c,
					Convicted_of_crime_offence__c,
					Callista_Applicant_Id__c,
					Source_System__c,
					Existing_Aus_disability_support__c,
					Sponsor_Name__c,
					Sponsorship_Status__c,
					Sponsorship_Type__c,
					Sponsor_Scholarship_organisation__c,
					External_Reference_Id__c,
					Delegator_Org_Unit_Code__c,
					OwnerId,
					Owner.Name,
					MyApp_User_Status__c,
					English_Proficiency_Requirement__c,
					English_Program_Consideration__c
				FROM Application__c
				WHERE Applicant__r.LastName = 'Chen'
				LIMIT 1
			];

			// WHEN creating application wrapper
			Test.startTest();
			ApplicationWSWrapper.ApplicationWrapper appWrapper = new ApplicationWSWrapper.ApplicationWrapper(app);
			Test.stopTest();

			// THEN verify wrapper contains correct data
			Assert.areEqual(app.Name, appWrapper.name, 'Application name should match');
			Assert.areEqual(app.Status__c, appWrapper.status, 'Status should match');
			Assert.areEqual(app.Campus_Location__c, appWrapper.campusLocation, 'Campus location should match');
			Assert.areEqual(app.Callista_Application_Id__c, appWrapper.callistaApplicationId, 'Callista ID should match');
			Assert.areEqual(app.Application_Type__c, appWrapper.applicationType, 'Application type should match');
			Assert.areEqual(app.Credit_Intention__c, appWrapper.creditIntention, 'Credit intention should match');

			if (app.Citizenship_Country__r != null) {
				Assert.areEqual(
					app.Citizenship_Country__r.uniqueCountryExternalId__c,
					appWrapper.citizenshipCountry?.uniqueCountryExternalId,
					'Citizenship country should match'
				);
			}

			if (app.Single_Entry_Visa__r != null) {
				Assert.areEqual(
					app.Single_Entry_Visa__r.uniqueCountryExternalId__c,
					appWrapper.singleEntryVisa?.uniqueCountryExternalId,
					'Single entry visa country should match'
				);
			}
		}
	}

	@isTest
	static void testContactQualificationWrapperConstructor() {
		Contact_Qualification__c testQualification = new ContactQualificationsSelector()
			.selectByApplicationId(new Set<Id>{ [SELECT id FROM Application__c LIMIT 1].id })[0];
		OESApplicationPayload.PatchRequest patchRequest = new OESApplicationPayload.PatchRequest();
		patchRequest.application = new OESApplicationPayload.CDM_Application();
		// Create a list of qualifications

		// English Test Qualification
		ApplicationWSWrapper.CDM_Qualification qualification = new ApplicationWSWrapper.CDM_Qualification();
		qualification.type = new ApplicationWSWrapper.CDM_QualificationType();
		qualification.type.crmRecordId = fflib_IDGenerator.generate(Qualification__c.SObjectType);
		qualification.type.name = 'English Test';
		qualification.type.code = '';
		qualification.type.qualificationName = 'bachelor of commerce';
		qualification.type.qualificationUid = '122';
		Test.startTest(); // NOPMD
		ApplicationWSWrapper.ContactQualificationWrapper qualWrapper = new ApplicationWSWrapper.ContactQualificationWrapper(
			testQualification
		);
		Test.stopTest();

		// Verify the results
		Assert.isTrue(
			qualWrapper.qualificationName.toLowerCase().contains('master of puppets'),
			'Qualification name should match'
		);
	}

	@isTest
	static void testWorkExperienceWrapperConstructor() {
		// GIVEN a portal user and application with work experience
		User portalUser = [SELECT Id FROM User WHERE email = 'testAgentLastName@TestEmail.com' LIMIT 1];

		System.runAs(portalUser) {
			Contact applicant = [SELECT Id FROM Contact WHERE LastName = 'Chen' LIMIT 1];
			Application__c application = [
				SELECT Id, Name, Applicant__c
				FROM Application__c
				WHERE Applicant__c = :applicant.Id
				LIMIT 1
			];

			// Query existing work experience
			Work_Experience__c workExp = [
				SELECT Id, Position__c, Employer_Name__c, Start_Date__c, End_Date__c, Contact__c
				FROM Work_Experience__c
				WHERE Contact__c = :applicant.Id AND Employer_Name__c = 'XYZ infotech'
				LIMIT 1
			];

			// Create Application Work Experience link if it doesn't exist
			List<Application_Work_Experience_Provided__c> existingLinks = [
				SELECT Id
				FROM Application_Work_Experience_Provided__c
				WHERE Application__c = :application.Id AND Work_Experience__c = :workExp.Id
			];

			if (existingLinks.isEmpty()) {
				Application_Work_Experience_Provided__c appWorkExp = new Application_Work_Experience_Provided__c(
					Application__c = application.Id,
					Work_Experience__c = workExp.Id
				);
				insert appWorkExp;
			}

			Test.startTest();
			List<Work_Experience__c> workExperiences = ApplicationWSService.getWorkExperiencesByApplicationId(application.Id);
			Assert.isTrue(!workExperiences.isEmpty(), 'Work experiences should exist');

			ApplicationWSWrapper.WorkExperienceWrapper expWrapper = new ApplicationWSWrapper.WorkExperienceWrapper(
				workExperiences[0]
			);
			Test.stopTest();

			// THEN verify the wrapper contains correct data
			Assert.areEqual('CEO', expWrapper.position, 'Position should match');
			Assert.areEqual('XYZ infotech', expWrapper.employerName, 'Employer name should match');
			if (workExp.Start_Date__c != null) {
				Assert.areEqual(workExp.Start_Date__c, expWrapper.startDate, 'Start date should match');
			}
			if (workExp.End_Date__c != null) {
				Assert.areEqual(workExp.End_Date__c, expWrapper.endDate, 'End date should match');
			}
		}
	}
	@IsTest
	static void testCDMWorkExperience() {
		// GIVEN a contact and work experience data
		Contact applicant = [SELECT Id FROM Contact WHERE LastName = 'Chen' LIMIT 1];
		Country_Attribute__c country = [SELECT Id FROM Country_Attribute__c WHERE Country__c = 'Australia' LIMIT 1];

		// WHEN creating a work experience record through CDM
		ApplicationWSWrapper.CDM_WorkExperience workExp = new ApplicationWSWrapper.CDM_WorkExperience();
		workExp.position = 'Software Developer';
		workExp.employer = 'Tech Corp';
		workExp.startDate = '2023-01-01';
		workExp.endDate = '2023-12-31';
		workExp.countryObtained = new ApplicationWSWrapper.CDM_Country();
		workExp.countryObtained.crmRecordId = country.Id;
		workExp.applicantRecord = applicant;
		workExp.contactPerson = new ApplicationWSWrapper.CDM_Referee();
		workExp.contactPerson.firstName = 'John';
		workExp.contactPerson.lastName = 'Doe';
		workExp.contactAddress = 'test@test.com';
		workExp.contactPhone = '1234567890';
		Work_Experience__c result;
		AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();
		System.runAs(portalUser.testUser) {
			Test.startTest();
			result = workExp.asExperienceRecord();
			Test.stopTest();
		}
		// THEN verify the work experience record is created correctly
		Assert.areEqual('Software Developer', result.Position__c);
		Assert.areEqual('Tech Corp', result.Employer_Name__c);
		Assert.areEqual(Date.valueOf('2023-01-01'), result.Start_Date__c);
		Assert.areEqual(Date.valueOf('2023-12-31'), result.End_Date__c);
		Assert.areEqual(country.Id, result.Country__c);
	}

	@IsTest
	static void testCDMQualification() {
		// GIVEN a contact and qualification data
		Contact applicant = [SELECT Id FROM Contact WHERE LastName = 'Chen' LIMIT 1];
		Country_Attribute__c country = [SELECT Id FROM Country_Attribute__c WHERE Country__c = 'Australia' LIMIT 1];
		Qualification__c qual = [SELECT Id FROM Qualification__c LIMIT 1];

		// WHEN creating a qualification record through CDM
		ApplicationWSWrapper.CDM_Qualification cdmQual = new ApplicationWSWrapper.CDM_Qualification();
		cdmQual.type = new ApplicationWSWrapper.CDM_QualificationType();
		cdmQual.type.name = 'Tertiary Education';
		cdmQual.type.crmRecordId = qual.Id;
		cdmQual.startDate = '2020';
		cdmQual.endDate = '2023';
		cdmQual.countryObtained = new ApplicationWSWrapper.CDM_Country();
		cdmQual.countryObtained.crmRecordId = country.Id;
		cdmQual.applicantRecord = applicant;
		cdmQual.conferredDate = '2023-12-31';
		cdmQual.isEnglishInstruction = true;

		// Add test scores
		ApplicationWSWrapper.CDM_QualificationScore listeningScore = new ApplicationWSWrapper.CDM_QualificationScore();
		listeningScore.name = 'listening';
		listeningScore.value = '8.0';
		cdmQual.scores = new List<ApplicationWSWrapper.CDM_QualificationScore>{ listeningScore };
		Contact_Qualification__c result;
		AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();
		System.runAs(portalUser.testUser) {
			Test.startTest();
			result = cdmQual.asQualificationRecord();
			Test.stopTest();
		}
		// THEN verify the qualification record is created correctly
		Assert.areEqual(qual.Id, result.Qualification__c);
		Assert.areEqual('2020', result.First_Year_Enrolled__c);
		Assert.areEqual('2023', result.Last_Year_Enrolled__c);
		Assert.areEqual(Date.valueOf('2023-12-31'), result.Date_Achieved__c);
		Assert.areEqual(true, result.Instruction_in_English__c);
		Assert.areEqual('8.0', result.Listening__c);
	}

	@IsTest
	static void testCDMPayment() {
		// GIVEN an application
		Application__c app = [SELECT Id FROM Application__c LIMIT 1];

		// WHEN adding payment details through CDM
		ApplicationWSWrapper.CDM_Payment payment = new ApplicationWSWrapper.CDM_Payment();
		payment.mode = 'Credit Card';
		payment.amount = '100.00';
		payment.transactionAmount = '100.00';
		payment.datePaid = '2024-01-01';
		payment.transactionSource = 'Online';
		payment.transactionReference = 'REF123';
		payment.isPaid = true;
		payment.applicationRecord = app;

		Test.startTest();
		payment.addPaymentDetailsToApplication();
		Test.stopTest();

		// THEN verify payment details are added correctly
		Assert.areEqual('Credit Card', app.Fee_Payment_Mode__c);
		Assert.areEqual(100.00, app.Fee_Amount__c);
		Assert.areEqual(100.00, app.Transaction_Amount__c);
		Assert.areEqual(Date.valueOf('2024-01-01'), app.Transaction_Date__c);
		Assert.areEqual('Online', app.Transaction_Source__c);
		Assert.areEqual('REF123', app.Transaction_Reference__c);
		Assert.areEqual(true, app.Fee_Payment__c);
	}

	@IsTest
	static void testResolveYesNoPicklist() {
		// Test various scenarios
		Assert.areEqual('Yes', ApplicationWSWrapper.resolveYesNoPicklist(true));
		Assert.areEqual('No', ApplicationWSWrapper.resolveYesNoPicklist(false));
		Assert.areEqual(null, ApplicationWSWrapper.resolveYesNoPicklist(null));
	}

	@IsTest
	static void testCDMPaymentAddPaymentDetails() {
		// GIVEN a portal user and application
		User portalUser = [SELECT Id FROM User WHERE email = 'testAgentLastName@TestEmail.com' LIMIT 1];

		System.runAs(portalUser) {
			// Get existing application
			Application__c app = [
				SELECT
					Id,
					Name,
					Applicant__c,
					Status__c,
					Fee_Payment_Mode__c,
					Transaction_Source__c,
					Transaction_Reference__c,
					Fee_Payment__c,
					Fee_Waiver_Code__c,
					Transaction_Date__c,
					Fee_Amount__c,
					Transaction_Amount__c
				FROM Application__c
				WHERE Applicant__r.LastName = 'Chen'
				LIMIT 1
			];

			// Create CDM Payment
			ApplicationWSWrapper.CDM_Payment payment = new ApplicationWSWrapper.CDM_Payment();
			payment.mode = 'Credit Card';
			payment.amount = '500.00';
			payment.transactionAmount = '500.00';
			payment.transactionSource = 'Online';
			payment.transactionReference = 'REF123';
			payment.isPaid = true;
			payment.datePaid = '2024-01-15';
			payment.feeWaiverCode = new ApplicationWSWrapper.FeeWaiverCode();
			payment.feeWaiverCode.code = 'WAIVER1';
			payment.applicationRecord = app;

			// WHEN adding payment details
			Test.startTest();
			payment.addPaymentDetailsToApplication();
			update app; // Add this line to save the changes
			Test.stopTest();

			// THEN verify payment details are added correctly
			Application__c updatedApp = [
				SELECT
					Fee_Payment_Mode__c,
					Transaction_Source__c,
					Transaction_Reference__c,
					Fee_Payment__c,
					Fee_Waiver_Code__c,
					Transaction_Date__c,
					Fee_Amount__c,
					Transaction_Amount__c
				FROM Application__c
				WHERE Id = :app.Id
			];

			// Verify all payment fields
			Assert.areEqual('Credit Card', updatedApp.Fee_Payment_Mode__c, 'Payment mode should match');
			Assert.areEqual('Online', updatedApp.Transaction_Source__c, 'Transaction source should match');
			Assert.areEqual('REF123', updatedApp.Transaction_Reference__c, 'Transaction reference should match');
			Assert.areEqual(true, updatedApp.Fee_Payment__c, 'Fee payment should match');
			Assert.areEqual('WAIVER1', updatedApp.Fee_Waiver_Code__c, 'Fee waiver code should match');
			Assert.areEqual(Date.valueOf('2024-01-15'), updatedApp.Transaction_Date__c, 'Transaction date should match');
			Assert.areEqual(500.00, updatedApp.Fee_Amount__c, 'Fee amount should match');
			Assert.areEqual(500.00, updatedApp.Transaction_Amount__c, 'Transaction amount should match');
		}
	}

	@IsTest
	static void testCDMPaymentInvalidDateFormat() {
		// GIVEN a portal user and application
		User portalUser = [SELECT Id FROM User WHERE email = 'testAgentLastName@TestEmail.com' LIMIT 1];

		System.runAs(portalUser) {
			// Get existing application
			Application__c app = [
				SELECT
					Id,
					Name,
					Applicant__c,
					Status__c,
					Fee_Payment_Mode__c,
					Transaction_Source__c,
					Transaction_Reference__c,
					Fee_Payment__c,
					Fee_Waiver_Code__c,
					Transaction_Date__c
				FROM Application__c
				WHERE Applicant__r.LastName = 'Chen'
				LIMIT 1
			];

			// Create CDM Payment with invalid date
			ApplicationWSWrapper.CDM_Payment payment = new ApplicationWSWrapper.CDM_Payment();
			payment.mode = 'Credit Card';
			payment.amount = '100.00';
			payment.transactionSource = 'Online';
			payment.transactionReference = 'REF123';
			payment.isPaid = true;
			payment.datePaid = 'invalid-date-format'; // Invalid date format
			payment.applicationRecord = app;

			// WHEN adding payment details with invalid date
			Test.startTest();
			try {
				payment.addPaymentDetailsToApplication();
			} catch (Exception e) {
				Assert.isTrue(
				    e.getMessage().contains('Invalid date') ||
				    e.getMessage().contains('invalid date format'),
				    'Error message should mention invalid date format. Actual: ' + e.getMessage()
				);
			}
			Test.stopTest();

			// Verify the application wasn't updated with the invalid date
			Application__c updatedApp = [
				SELECT Transaction_Date__c
				FROM Application__c
				WHERE Id = :app.Id
			];
			Assert.areEqual(null, updatedApp.Transaction_Date__c, 'Transaction date should not be set for invalid date');
		}
	}

	@IsTest
	static void testContactQualificationWrapperFromObjectList() {
		// GIVEN a portal user and existing qualifications
		User portalUser = [SELECT Id FROM User WHERE email = 'testAgentLastName@TestEmail.com' LIMIT 1];

		System.runAs(portalUser) {
			// Get existing contact and qualifications from test setup
			Contact applicant = [SELECT Id FROM Contact WHERE LastName = 'Chen' LIMIT 1];
			List<Contact_Qualification__c> qualifications = [
				SELECT
					Id,
					IsDeleted,
					Name,
					CurrencyIsoCode,
					RecordTypeId,
					CreatedDate,
					CreatedById,
					LastModifiedDate,
					LastModifiedById,
					SystemModstamp,
					LastViewedDate,
					LastReferencedDate,
					Contact__c,
					Date_Achieved__c,
					Instruction_in_English__c,
					Qualification_Name__c,
					Qualification_Type__c,
					Qualification__c,
					Qualification__r.Name,
					Qualification__r.Qualification_Name__c,
					Qualification__r.Id,
					Score__c,
					isTestCompleted__c,
					Reference_Count__c,
					Listening__c,
					Reading__c,
					Speaking__c,
					Writing__c,
					Verification_Status__c,
					Honorary_Degree__c,
					Primary__c,
					deleted_on_source__c,
					Relevant_Qualification_Name__c,
					USA_Accredited__c,
					External_ID__c,
					CRM_Id__c,
					Tertiary_Qualification_Level__c,
					Qualification_Country__c,
					Other_Qualification__c,
					Other_Qualification_Comments__c,
					Institution_Name__c,
					Title__c,
					Test_of_Written_English__c,
					Year_of_Completion__c,
					Monash_Equivalent_GPA__c,
					Qualification_GPA_Scale__c,
					Qualification_GPA_Calc_Method__c,
					RecordType.Name,
					Institution_Code__c,
					Type__c,
					First_Year_Enrolled__c,
					Last_Year_Enrolled__c,
					Other_Institution__c,
					State__c,
					Status__c,
					Relevant_Institution_Name__c,
					State_Province__c,
					Expected_date_of_completion__c,
					English_Test_Expiry_Date__c,
					English_Test_Number__c,
					Source_Channel__c
				FROM Contact_Qualification__c
				WHERE Contact__c = :applicant.Id AND Qualification_Type__c = 'English Test'
				ORDER BY CreatedDate
				LIMIT 1
			];

			Assert.isTrue(!qualifications.isEmpty(), 'Should have qualifications from test setup');

			// WHEN converting to wrapper list
			Test.startTest();
			ApplicationWSWrapper.ContactQualificationWrapper wrapper = new ApplicationWSWrapper.ContactQualificationWrapper();
			List<ApplicationWSWrapper.ContactQualificationWrapper> wrappers = wrapper.fromObjectList(qualifications);
			Test.stopTest();

			// THEN verify wrapper contents
			Assert.areEqual(qualifications.size(), wrappers.size(), 'Should have same number of wrappers as qualifications');

			for (Integer i = 0; i < qualifications.size(); i++) {
				Contact_Qualification__c qual = qualifications[i];
				ApplicationWSWrapper.ContactQualificationWrapper wrap = wrappers[i];
				// Verify qualification relationship fields
				Assert.isTrue(
					qual.Qualification_Name__c.contains(wrap.qualificationName),
					'Qualification name should match for record ' + i
				);
				// Verify all other fields
				Assert.areEqual('English Test', wrap.qualificationType, 'Type should match for record ' + i);
				Assert.areEqual(qual.Score__c, wrap.score, 'Score should match for record ' + i);
				Assert.areEqual(qual.isTestCompleted__c, wrap.isTestCompleted, 'Test completed should match for record ' + i);
				Assert.areEqual(qual.Listening__c, wrap.listening, 'Listening score should match for record ' + i);
				Assert.areEqual(qual.Reading__c, wrap.reading, 'Reading score should match for record ' + i);
				Assert.areEqual(qual.Speaking__c, wrap.speaking, 'Speaking score should match for record ' + i);
				Assert.areEqual(qual.Writing__c, wrap.writing, 'Writing score should match for record ' + i);
			}
		}
	}

	@IsTest
	static void testWorkExperienceWrapperFromObjectList() {
		// GIVEN a portal user and existing work experiences
		User portalUser = [SELECT Id FROM User WHERE email = 'testAgentLastName@TestEmail.com' LIMIT 1];

		System.runAs(portalUser) {
			// Get existing work experiences from test setup
			Contact applicant = [SELECT Id FROM Contact WHERE LastName = 'Chen' LIMIT 1];
			List<Work_Experience__c> experiences = [
				SELECT
					Id,
					Position__c,
					Employer_Name__c,
					Start_Date__c,
					End_Date__c,
					Country__c,
					Country__r.uniqueCountryExternalId__c,
					Country__r.Name,
					Country__r.ISO_Alpha_2__c,
					Country__r.Id,
					Contact_Person_First_Name__c,
					Contact_Person_Last_Name__c,
					Contact_Person_Email__c,
					Contact_Person_Phone__c,
					External_ID__c
				FROM Work_Experience__c
				WHERE Contact__c = :applicant.Id
				ORDER BY Employer_Name__c
			];

			Assert.isTrue(!experiences.isEmpty(), 'Should have work experiences from test setup');

			// WHEN converting to wrapper list
			Test.startTest();
			ApplicationWSWrapper.WorkExperienceWrapper wrapper = new ApplicationWSWrapper.WorkExperienceWrapper();
			List<ApplicationWSWrapper.WorkExperienceWrapper> wrappers = wrapper.fromWorkExperienceList(experiences);
			Test.stopTest();

			// THEN verify wrapper contents
			Assert.areEqual(experiences.size(), wrappers.size(), 'Should have same number of wrappers as experiences');

			for (Integer i = 0; i < experiences.size(); i++) {
				Work_Experience__c exp = experiences[i];
				ApplicationWSWrapper.WorkExperienceWrapper wrap = wrappers[i];

				// Verify all fields
				Assert.areEqual(exp.Position__c, wrap.position, 'Position should match for ' + exp.Employer_Name__c);
				Assert.areEqual(
					exp.Employer_Name__c,
					wrap.employerName,
					'Employer name should match for ' + exp.Employer_Name__c
				);
				Assert.areEqual(exp.Start_Date__c, wrap.startDate, 'Start date should match for ' + exp.Employer_Name__c);
				Assert.areEqual(exp.End_Date__c, wrap.endDate, 'End date should match for ' + exp.Employer_Name__c);

				if (exp.Country__r != null) {
					Assert.areEqual(
						exp.Country__r.uniqueCountryExternalId__c,
						wrap.country?.uniqueCountryExternalId,
						'Country external ID should match for ' + exp.Employer_Name__c
					);
					Assert.areEqual(
						exp.Country__r.Name,
						wrap.country?.name,
						'Country name should match for ' + exp.Employer_Name__c
					);
					Assert.areEqual(
						exp.Country__r.ISO_Alpha_2__c,
						wrap.country?.isoAlpha2,
						'Country ISO Alpha 2 should match for ' + exp.Employer_Name__c
					);
					// Assert.areEqual(exp.Country__r.Id,
					//     wrap.country?.id,
					//     'Country ID should match for ' + exp.Employer_Name__c);
				}
			}
		}
	}
	@IsTest
	static void testApplicationCoursePreference() {
		// GIVEN a portal user and application
		User portalUser = [SELECT Id FROM User WHERE email = 'testAgentLastName@TestEmail.com' LIMIT 1];

		System.runAs(portalUser) {
			// Get existing application and ACP records
			Application__c app = [
				SELECT Id, Name, Applicant__c
				FROM Application__c
				WHERE Applicant__r.LastName = 'Chen'
				LIMIT 1
			];

			List<Application_Course_Preference__c> acpList = [
				SELECT
					Id,
					Course_Offering__r.Active__c,
					Course_Start_Year__c,
					Calendar_Start_Date__c,
					Application__c,
					Application__r.Name,
					Course__c,
					Course_Offering__r.Course__r.Id,
					Course_Code__c,
					Course_Version_Number__c,
					Course_Title__c,
					Unit_Set_Code__c,
					Location_Code__c,
					Documentation_Status_LOV__r.System_Code__c,
					Documentation_Status_LOV__r.Value__c,
					Entry_Qualification_Status_LOV__r.System_Code__c,
					Entry_Qualification_Status_LOV__r.Value__c,
					Outcome_Status_LOV__r.System_Code__c,
					Outcome_Status_LOV__r.Value__c,
					Offer_Response_Status_LOV__r.Value__c,
					Offer_Response_Status_LOV__r.System_Code__c,
					Offer_Condition__c,
					Offer_Date__c,
					Offer_Response_Date__c,
					Actual_Offer_Response_Date__c,
					Deferment_Status_LOV__r.System_Code__c,
					Admission_Calendar_Type__c,
					Commencement_Period__c,
					Managing_Faculty__c,
					Unit_Set_Description__c,
					Status__c,
					Preference_Number__c,
					LastModifiedDate,
					Conditional_Offer_Status_LOV__r.Value__c,
					Deferment_Status_LOV__r.Value__c,
					Conditional_Offer_Satisfied_Date__c,
					ACP_ID__c,
					External_Id__c
				FROM Application_Course_Preference__c
				WHERE Application__c = :app.Id
				ORDER BY CreatedDate
			];

			Assert.isTrue(!acpList.isEmpty(), 'Should have ACP records from test setup');

			// WHEN converting to wrapper
			Test.startTest();
			ApplicationWSWrapper.ApplicationCoursePreference wrapper = new ApplicationWSWrapper.ApplicationCoursePreference();
			List<ApplicationWSWrapper.ApplicationCoursePreference> wrappers = wrapper.fromObjectList(acpList);
			Test.stopTest();

			// THEN verify wrapper contents
			Assert.areEqual(acpList.size(), wrappers.size(), 'Should have same number of wrappers as ACP records');

			for (Integer i = 0; i < acpList.size(); i++) {
				Application_Course_Preference__c acp = acpList[i];
				ApplicationWSWrapper.ApplicationCoursePreference wrap = wrappers[i];

				// Verify all fields
				Assert.areEqual(acp.Id, wrap.id, 'Id should match for record ' + i);
				Assert.areEqual(
					acp.Course_Offering__r.Active__c,
					wrap.courseOfferingActive,
					'Course offering active should match for record ' + i
				);
				Assert.areEqual(
					Integer.valueOf(acp.Course_Start_Year__c),
					wrap.courseStartYear,
					'Course start year should match for record ' + i
				);
				// Assert.areEqual(acp.Calendar_Start_Date__c, wrap.calendarStartDate, 'Calendar start date should match for record ' + i);
				// Assert.areEqual(acp.Application__c, wrap.applicationId, 'Application Id should match for record ' + i);
				// Assert.areEqual(acp.Application__r.Name, wrap.applicationName, 'Application name should match for record ' + i);
				// Assert.areEqual(acp.Course__c, wrap.courseId, 'Course Id should match for record ' + i);
				// Assert.areEqual(acp.Course_Offering__r.Course__r.Id, wrap.courseOfferingCourseId, 'Course offering course Id should match for record ' + i);
				// Assert.areEqual(acp.Course_Code__c, wrap.courseCode, 'Course code should match for record ' + i);
				// Assert.areEqual(Integer.valueOf(acp.Course_Version_Number__c), wrap.courseVersionNumber, 'Course version number should match for record ' + i);
				// Assert.areEqual(acp.Course_Title__c, wrap.courseTitle, 'Course title should match for record ' + i);
				// Assert.areEqual(acp.Unit_Set_Code__c, wrap.unitSetCode, 'Unit set code should match for record ' + i);
				// Assert.areEqual(acp.Location_Code__c, wrap.locationCode, 'Location code should match for record ' + i);
				// Assert.areEqual(acp.Documentation_Status_LOV__r.System_Code__c, wrap.documentationStatusSystemCode, 'Documentation status system code should match for record ' + i);
				// Assert.areEqual(acp.Documentation_Status_LOV__r.Value__c, wrap.documentationStatusValue, 'Documentation status value should match for record ' + i);
				// Assert.areEqual(acp.Entry_Qualification_Status_LOV__r.System_Code__c, wrap.entryQualificationStatusSystemCode, 'Entry qualification status system code should match for record ' + i);
				// Assert.areEqual(acp.Entry_Qualification_Status_LOV__r.Value__c, wrap.entryQualificationStatusValue, 'Entry qualification status value should match for record ' + i);
				// Assert.areEqual(acp.Outcome_Status_LOV__r.System_Code__c, wrap.outcomeStatusSystemCode, 'Outcome status system code should match for record ' + i);
				// Assert.areEqual(acp.Outcome_Status_LOV__r.Value__c, wrap.outcomeStatusValue, 'Outcome status value should match for record ' + i);
				// Assert.areEqual(acp.Offer_Response_Status_LOV__r.Value__c, wrap.offerResponseStatusValue, 'Offer response status value should match for record ' + i);
				// Assert.areEqual(acp.Offer_Condition__c, wrap.offerCondition, 'Offer condition should match for record ' + i);
				// Assert.areEqual(acp.Offer_Date__c, wrap.offerDate, 'Offer date should match for record ' + i);
				// Assert.areEqual(acp.Offer_Response_Date__c, wrap.offerResponseDate, 'Offer response date should match for record ' + i);
				// Assert.areEqual(acp.Offer_Response_Status_LOV__r.System_Code__c, wrap.offerResponseStatusSystemCode, 'Offer response status system code should match for record ' + i);
				// Assert.areEqual(acp.Actual_Offer_Response_Date__c, wrap.actualOfferResponseDate, 'Actual offer response date should match for record ' + i);
				// Assert.areEqual(acp.Deferment_Status_LOV__r.System_Code__c, wrap.defermentStatusSystemCode, 'Deferment status system code should match for record ' + i);
				// Assert.areEqual(acp.Admission_Calendar_Type__c, wrap.admissionCalendarType, 'Admission calendar type should match for record ' + i);
				// Assert.areEqual(acp.Commencement_Period__c, wrap.commencementPeriod, 'Commencement period should match for record ' + i);
				// Assert.areEqual(acp.Managing_Faculty__c, wrap.managingFaculty, 'Managing faculty should match for record ' + i);
				// Assert.areEqual(acp.Unit_Set_Description__c, wrap.unitSetDescription, 'Unit set description should match for record ' + i);
				// Assert.areEqual(acp.Status__c, wrap.status, 'Status should match for record ' + i);
				// Assert.areEqual(acp.Preference_Number__c, wrap.preferenceNumber, 'Preference number should match for record ' + i);
				// Assert.areEqual(acp.LastModifiedDate?.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'), wrap.lastModifiedDate, 'Last modified date should match for record ' + i);
				// Assert.areEqual(acp.Conditional_Offer_Status_LOV__r.Value__c, wrap.conditionalOfferStatusValue, 'Conditional offer status value should match for record ' + i);
				// Assert.areEqual(acp.Deferment_Status_LOV__r.Value__c, wrap.defermentStatusValue, 'Deferment status value should match for record ' + i);
				// Assert.areEqual(acp.Conditional_Offer_Satisfied_Date__c, wrap.conditionalOfferSatisfiedDate, 'Conditional offer satisfied date should match for record ' + i);
				// Assert.areEqual(acp.ACP_ID__c, wrap.acpId, 'ACP ID should match for record ' + i);
				// Assert.areEqual(acp.External_Id__c, wrap.externalId, 'External ID should match for record ' + i);
			}
		}
	}
	@IsTest
	static void testCDMApplicationCoursePreference() {
		// GIVEN a portal user and application from makeData
		User portalUser = [SELECT Id FROM User WHERE email = 'testAgentLastName@TestEmail.com' LIMIT 1];

		System.runAs(portalUser) {
			// Get existing records from makeData
			Application__c app = [
				SELECT Id, Name, Applicant__c
				FROM Application__c
				WHERE Applicant__r.LastName = 'Chen'
				LIMIT 1
			];
			Course_Offering__c courseOffering = [
				SELECT Id, Course_Offering_UID__c, Active__c, Course__c
				FROM Course_Offering__c
				LIMIT 1
			];

			// Create test CDM_ApplicationCoursePreference
			ApplicationWSWrapper.CDM_ApplicationCoursePreference cdmAcp = new ApplicationWSWrapper.CDM_ApplicationCoursePreference();
			cdmAcp.applicationRecord = app;
			cdmAcp.crmRecordId = fflib_IDGenerator.generate(Application_Course_Preference__c.SObjectType);
			cdmAcp.preference = 1;

			// Set up course offering using existing record
			ApplicationWSWrapper.CDM_CourseOffering cdmCourseOffering = new ApplicationWSWrapper.CDM_CourseOffering();
			cdmCourseOffering.crmRecordId = courseOffering.Id;
			cdmCourseOffering.courseOfferingUid = courseOffering.Course_Offering_UID__c;

			cdmAcp.courseOffering = cdmCourseOffering;

			//TODO Ben fix this

			//     // WHEN converting to ACP record
			//     Test.startTest();
			//     //Application_Course_Preference__c acp = cdmAcp.asACPRecord();
			//     Test.stopTest();

			//     // THEN verify all fields are mapped correctly
			//     Assert.areEqual(app.Id, acp.Application__c, 'Application ID should match');
			//     Assert.areEqual(app.Applicant__c, acp.Applicant__c, 'Applicant ID should match');
			//     Assert.areEqual('1', acp.Preference_Number__c, 'Preference number should match');

			//     // Verify course offering mapping based on user context
			//     if (OESApplicationService.isOESUser) {
			//         Assert.areEqual(courseOffering.Course_Offering_UID__c,
			//             acp.Course_Offering__r.Course_Offering_UID__c,
			//             'Course Offering UID should match for OES user');
			//     } else {
			//         Assert.areEqual(courseOffering.Id, acp.Course_Offering__c,
			//             'Course Offering ID should match for non-OES user');
			//     }

			//     // Test error case - missing course offering
			//     ApplicationWSWrapper.CDM_ApplicationCoursePreference invalidCdmAcp =
			//         new ApplicationWSWrapper.CDM_ApplicationCoursePreference();
			//     invalidCdmAcp.applicationRecord = app;

			//     try {
			//         invalidCdmAcp.asACPRecord();
			//         Assert.fail('Should have thrown an exception for missing course offering');
			//     } catch (RESTlib_Ex.InvalidRequestException e) {
			//         Assert.areEqual('Course Offering cannot be empty.', e.getMessage(),
			//             'Should throw correct error message');
			//     }
		}
	}
}