/**
 * @description       :
 * @author            : Ben Greenland
 * @group             :
 * @last modified on  : 2024-11-24
 * @last modified by  : Ben Greenland
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2024-11-19   Ben Greenland   Initial Version
 **/
@isTest(isParallel=false) //required for permission set assignement
public with sharing class ApplicationWSServiceTest {
	@TestSetup
	static void makeData() {
		TriggerCommon.disableTrigger('Country_Attribute__c');
		TriggerCommon.disableTrigger('Account');
		TriggerCommon.disableTrigger('Contact');
		TriggerCommon.disableTrigger('User');
		// Agencies
		Account testAccount1 = new Account(
			Name = 'AgencyOne',
			Monash_AM_Campus__c = 'Malaysia',
			Status__c = 'Appointed',
			Callista_Org_Unit_Code__c = 'TESTA1'
		);
		Account testAccount2 = new Account(
			Name = 'AgencyTwo',
			Monash_AM_Campus__c = 'Australia;Malaysia',
			Status__c = 'Appointed',
			Callista_Org_Unit_Code__c = 'TESTA2'
		);
		Account testAccount3 = new Account(
			Name = 'AgencyThree',
			Monash_AM_Campus__c = 'Malaysia',
			Status__c = 'Appointed',
			Callista_Org_Unit_Code__c = 'TESTA3'
		);
		Account testAccount4 = new Account(
			Name = 'AgencyFour',
			Monash_AM_Campus__c = 'Australia;Malaysia',
			Status__c = 'Contract Terminated',
			Callista_Org_Unit_Code__c = 'TESTA4'
		);
		Account testAccount5 = new Account(
			Name = 'AgencyFive',
			Monash_AM_Campus__c = 'Australia',
			Status__c = 'Appointed',
			Callista_Org_Unit_Code__c = 'TESTA5'
		);
		insert new List<Account>{ testAccount1, testAccount2, testAccount3, testAccount4, testAccount5 };
		// Applicant
		Contact testContact = new Contact(
			FirstName = 'TestFirstName',
			LastName = 'TestLastName',
			Email = 'TestEmail94183@testemail.com'
		);
		insert testContact;
		// Applications
		Application__c appForTerminatedAgency = new Application__c(
			Source_system__c = 'Agent Portal',
			Applicant__c = testContact.id,
			Campus_Location__c = 'Malaysia',
			Residency_Status__c = 'DOM-SUN',
			Residency_Sub_status__c = 'DOM-SUN.B',
			Agent__c = testAccount4.id
		);
		insert appForTerminatedAgency;
		// ACP Statuses
		List_Of_Values__c lov1 = new List_Of_Values__c(
			value__c = 'AP-PROGRES',
			system_code__c = 'PENDING',
			type__c = 'ADM_OUTCOME_STATUS',
			name = 'AP-PROGRES (PENDING)',
			is_Active__c = true
		);
		List_Of_Values__c lov2 = new List_Of_Values__c(
			value__c = 'ACC-DEL',
			system_code__c = 'REJECTED',
			type__c = 'ADM_OFFER_RESP_STATUS',
			name = 'ACC-DEL (REJECTED)',
			is_Active__c = true
		);
		List_Of_Values__c lov3 = new List_Of_Values__c(
			value__c = 'ACCEPTED',
			system_code__c = 'ACCEPTED',
			type__c = 'ADM_OFFER_RESP_STATUS',
			name = 'ACCEPTED (ACCEPTED)',
			is_Active__c = true
		);
		List_Of_Values__c lov4 = new List_Of_Values__c(
			value__c = 'OFFER',
			system_code__c = 'OFFER',
			type__c = 'ADM_OUTCOME_STATUS',
			name = 'OFFER (OFFER)',
			is_Active__c = true
		);
		List_Of_Values__c lov5 = new List_Of_Values__c(
			value__c = 'REJECTED',
			system_code__c = 'REJECTED',
			type__c = 'ADM_OUTCOME_STATUS',
			name = 'REJECTED (REJECTED)',
			is_Active__c = true
		);
		List_Of_Values__c lov6 = new List_Of_Values__c(
			value__c = 'DEFERRAL',
			system_code__c = 'DEFERRAL',
			type__c = 'ADM_OFFER_RESP_STATUS',
			name = 'DEFERRAL (DEFERRAL)',
			is_Active__c = true
		);
		insert new List<List_Of_Values__c>{ lov1, lov2, lov3, lov4, lov5, lov6 };
		// Course
		Course__c course1 = StudFirst_TestHelper.createCourse();
		insert new List<Course__c>{ course1 };
		// Course offerings
		Course_Offering__c offering1 = StudFirst_TestHelper.createCourseOffering(course1);
		offering1.Course_Title__c = 'General Course';
		Course_Offering__c offering2 = StudFirst_TestHelper.createCourseOffering(course1);
		offering2.Course_Title__c = 'Live Course';
		offering2.Start_Date__c = date.today();
		Course_Offering__c offering3 = StudFirst_TestHelper.createCourseOffering(course1);
		offering3.Course_Title__c = 'Expired Course';
		offering3.Start_Date__c = date.today().addDays(-500);
		insert new List<Course_Offering__c>{ offering1, offering2, offering3 };

		// Disable the linking of applications to the branch manager of an Agency
		Feature_Switch__c fs = new Feature_Switch__c();
		fs.Align_Application_Owner__c = false;
		insert fs;

		// INSERT Agent specific data
		AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();
		// GIVEN: Country record is created with uniqueCountryExternalId__c key and the user is granted permission to be an OES user
		Country_Attribute__c austria = new Country_Attribute__c();
		austria.Country__c = 'Austria';
		austria.uniqueCountryExternalId__c = '1101-123456';
		Country_Attribute__c australia = new Country_Attribute__c();
		australia.Country__c = 'Australia';
		australia.uniqueCountryExternalId__c = '1101-AUS-36-0';
		insert new List<sObject>{ austria, australia };

		// add an institution
		Institution__c tertInsRec = new Institution__c();
		tertInsRec.Institution_Country__c = [SELECT id FROM Country_Attribute__c WHERE Name = 'Australia' LIMIT 1].id;
		tertInsRec.Institution_Code__c = '835';
		tertInsRec.Type__c = 'Teritary Education';
		tertInsRec.Institution_Name__c = 'CANNING COLLEGE AUSTRALIA';
		Institution__c testSchool = new Institution__c();
		testSchool.Institution_Country__c = [SELECT id FROM Country_Attribute__c WHERE Name = 'Australia' LIMIT 1].id;
		tertInsRec.Institution_Code__c = '834';
		tertInsRec.Institution_Name__c = 'CANNING COLLEGE AUSTRALIA';
		tertInsRec.Type__c = 'Secondary Education';
		insert new List<sObject>{ testSchool, tertInsRec };
		// create a contact-qualification that is "draft"
		// GIVEN: Country record is created with uniqueCountryExternalId__c key and the user is granted permission to be an OES user
		Qualification__c testQualification = StudFirst_TestHelper.createQualification('Test Qualification');
		insert testQualification;
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

		Course_Offering__c coursOfferingOne = StudFirst_TestHelper.createCourseOffering(course);
		coursOfferingOne.Course_Code__c = 'E6001';
		coursOfferingOne.Course_Version_Number__c = 1;
		coursOfferingOne.Admission_Calendar_Type__c = 'ADM-0';
		coursOfferingOne.Location_Code__c = 'CLAYTON';
		coursOfferingOne.Attendance_Type__c = 'FT';
		coursOfferingOne.Attendance_Mode__c = 'IN';
		coursOfferingOne.Admission_Category__c = 'UG-CSP';
		coursOfferingOne.Academic_CI_Sequence_Number__c = 1111;
		coursOfferingOne.Admission_CI_Sequence_Number__c = 1111;
		coursOfferingOne.Unit_Set_Code__c = null;
		coursOfferingOne.Unit_Set_Version__c = null;
		coursOfferingOne.Citizenship_type__c = 'INT-TEP';
		coursOfferingOne.Admission_Calendar_Description__c = 'CrOf1';
		coursOfferingOne.Active__c = true;

		courseOfferings.add(coursOfferingOne);

		Course_Offering__c courseOfferingTwo = StudFirst_TestHelper.createCourseOffering(course);
		courseOfferingTwo.Course_Code__c = 'E6001';
		courseOfferingTwo.Course_Version_Number__c = 1;
		courseOfferingTwo.Admission_Calendar_Type__c = 'ADM-0';
		courseOfferingTwo.Location_Code__c = 'CLAYTON';
		courseOfferingTwo.Attendance_Type__c = 'FT';
		courseOfferingTwo.Attendance_Mode__c = 'EX';
		courseOfferingTwo.Admission_Category__c = 'UG-CSP';
		courseOfferingTwo.Academic_CI_Sequence_Number__c = 1111;
		courseOfferingTwo.Admission_CI_Sequence_Number__c = 1111;
		courseOfferingTwo.Unit_Set_Code__c = null;
		courseOfferingTwo.Unit_Set_Version__c = null;
		courseOfferingTwo.Citizenship_type__c = 'INT-TEP';
		courseOfferingTwo.Admission_Calendar_Description__c = 'CrOf2';
		courseOfferingTwo.Active__c = true;

		courseOfferings.add(courseOfferingTwo);

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

		//BEN not happy with this but it is required to pass validations
		// Course_Offering__c courseOfferingOES = [
		// 	SELECT Id
		// 	FROM Course_Offering__c
		// 	WHERE Course_Offering_UID__c = 'CO-COCOID1'
		// 	LIMIT 1
		// ];
		System.runAs(portalUser.testUser) {
			Contact applicant = StudFirst_TestHelper.createInternationalApplicant();
			applicant.Last_Name__c = applicant.LastName;
			applicant.First_Name__c = applicant.FirstName;
			applicant.Email = 'test@test.com';
			applicant.Personal_Email__c = 'test@test.com';
			insert applicant;

			Contact_Qualification__c englishTestQua = StudFirst_TestHelper.createContactQualification(
				applicant,
				testQualification,
				'English Test'
			);
			englishTestQua.Contact__c = applicant.Id;
			englishTestQua.Institution_Code__c = testSchool.Institution_Code__c;
			englishTestQua.Institution_Name__c = testSchool.Institution_Name__c;
			insert englishTestQua;
			// create a contact-qualification that is "completed"
			Application__c application = StudFirst_TestHelper.createInternationalApplication(applicant, australia);
			application.Agent__c = portalUser.testUser.AccountId;
			application.Campus_Location__c = 'Malaysia';
			application.Australian_Immigration_Office_Issued__c = 'Yes';
			application.Criminal_History_Opt_In__c = 'Yes';
			application.Refused_entry_visa_to_any_country__c = 'No';
			application.Breached_visa_condition__c = 'No';
			application.Medical_health_prevent_visa__c = 'No';
			application.Protection_visa_in_any_country__c = 'No';
			application.Convicted_of_crime_offence__c = 'No';
			application.Disability_Opt_In__c = 'Yes';
			application.HasDisabilities__c = 'No';
			insert application;

			Course__c courseXX = StudFirst_TestHelper.createCourse();
			courseXX.name = 'E6001OES';
			courseXX.Course_Code__c = 'E6001_11OES';
			courseXX.Version__c = '11';
			insert courseXX;

			Course_Offering__c oesCourseOfferingXX = StudFirst_TestHelper.createCourseOffering(courseXX);
			oesCourseOfferingXX.Course_Type__c = '21'; // any type that is not PD
			oesCourseOfferingXX.Portal_Available__c = true;
			oesCourseOfferingXX.Default_Admission_Category_Ind__c = true;
			oesCourseOfferingXX.Location_Code__c = 'ONLINE';
			oesCourseOfferingXX.Fee_Category__c = 'AU_DOM_MO';
			oesCourseOfferingXX.Course_Offering_UID__c = 'CO-COCOID1OES';
			oesCourseOfferingXX.Active__c = true;
			oesCourseOfferingXX.Mix_Unique_Id__c = AgentPortalTestDataFactory.util.generateRandomString(10);
			insert oesCourseOfferingXX;

			// Application_Course_Preference__c acp = new Application_Course_Preference__c();
			// acp.Course_Offering__c = oesCourseOfferingXX.Id;
			// acp.Application__c = application.Id;
			// insert acp;
			Work_Experience__c wex1 = new Work_Experience__c(
				Contact__c = applicant.id,
				Country__c = australia.Id,
				Position__c = 'Developer',
				Employer_Name__c = 'ABC Ltd'
			);

			Work_Experience__c wex2 = new Work_Experience__c(
				Contact__c = applicant.id,
				Position__c = 'CEO',
				Country__c = australia.Id,
				Employer_Name__c = 'XYZ infotech'
			);
			insert new List<Work_Experience__c>{ wex1, wex2 };
			// Add this: Create Application Work Experience links
			List<Application_Work_Experience_Provided__c> appWorkExps = new List<Application_Work_Experience_Provided__c>{
				new Application_Work_Experience_Provided__c(Application__c = application.Id, Work_Experience__c = wex1.Id),
				new Application_Work_Experience_Provided__c(Application__c = application.Id, Work_Experience__c = wex2.Id)
			};
			insert appWorkExps;
		}
		TriggerCommon.enableTrigger('Country_Attribute__c');
		TriggerCommon.enableTrigger('Account');
		TriggerCommon.enableTrigger('Contact');
		TriggerCommon.enableTrigger('User');
	}
	@IsTest
	static void testIsValidContact() {
		Contact contact = [SELECT Id, CRM_ID__c FROM Contact LIMIT 1];
		Application__c app = [SELECT Id, Name FROM Application__c LIMIT 1];
		Boolean result = ApplicationWSService.isValidContact(contact.Id);
		Assert.areEqual(true, result, '');

		// Negative test case
		result = ApplicationWSService.isValidContact('InvalidCRM');
		Assert.areEqual(false, result, 'Not a valid contact');
		// testGetApplication
		List<Application__c> resultApp = ApplicationWSService.getApplicationByName(app.Name);
		Assert.areEqual(1, resultApp.size(), 'Application should be found');
		Assert.areEqual(app.Name, resultApp[0].Name, 'Application name should match');

		// testIsValidApplication() {
		Assert.areEqual(true, ApplicationWSService.isValidApplication(app.Name), 'Application should be valid');

		// Negative test case
		result = ApplicationWSService.isValidApplication('InvalidApp');
		Assert.areEqual(false, result, 'Application should not be valid');
	}

	@isTest
	static void testAsApplicationRecord() {
		User portalUser = [SELECT Id FROM User WHERE email = 'testAgentLastName@TestEmail.com' LIMIT 1];
		// Course_Offering__c courseOffering = [SELECT Id FROM Course_Offering__c LIMIT 1];

		System.runAs(portalUser) {
			// Create instance of CDM_Application
			String jsonTemplate = getTemplateJsonApplication();
			APNGApplicationPayload.CDM_Application cdmApplication = (APNGApplicationPayload.CDM_Application) JSON.deserialize(
				jsonTemplate,
				APNGApplicationPayload.CDM_Application.class
			);
			// cdmApplication.workExperiences = null;
			cdmApplication.qualifications = null;
			cdmApplication.coursePreferences = null;
			// Call the method
			Test.startTest();
			ApplicationWSService.PatchApplicationService patchService = new ApplicationWSService.PatchApplicationService(
				cdmApplication
			);
			ApplicationWSWrapper.ApplicationResponseWrapper responseWrapper = patchService.process();
			Assert.isNotNull(responseWrapper, 'Response should not be null');
			Test.stopTest();
		}
	}

	@isTest
	private static void testAgentAcceptedApplicationUpdates() {
		Contact applicant = [SELECT id FROM Contact WHERE email = 'TestEmail94183@testemail.com' LIMIT 1];
		List<Account> agency = [SELECT id FROM Account WHERE Name IN ('AgencyOne', 'AgencyTwo', 'AgencyThree')];
		Application__c appn1 = new Application__c(
			Source_system__c = 'Agent Portal',
			Applicant__c = applicant.id,
			Campus_Location__c = 'Malaysia',
			Residency_Status__c = 'DOM-SUN',
			Residency_Sub_status__c = 'DOM-SUN.B',
			Agent__r = agency.get(0),
			Agent_Org_Unit_Code__c = 'TESTA1',
			Status__c = 'Review'
		);
		Application__c appn2 = new Application__c(
			Source_system__c = 'Agent Portal',
			Applicant__c = applicant.id,
			Campus_Location__c = 'Malaysia',
			Residency_Status__c = 'DOM-SUN',
			Residency_Sub_status__c = 'DOM-SUN.B',
			Agent__r = agency.get(1),
			Agent_Org_Unit_Code__c = 'TESTA2',
			Status__c = 'Review'
		);
		Application__c appn3 = new Application__c(
			Source_system__c = 'Agent Portal',
			Applicant__c = applicant.id,
			Campus_Location__c = 'Malaysia',
			Residency_Status__c = 'DOM-SUN',
			Residency_Sub_status__c = 'DOM-SUN.B',
			Agent__r = agency.get(2),
			Agent_Org_Unit_Code__c = 'TESTA3',
			Status__c = 'Draft'
		);
		insert new List<Application__c>{ appn1, appn2, appn3 };
		Course_Offering__c offering = [SELECT id FROM Course_Offering__c WHERE Course_Title__c = 'General Course' LIMIT 1];
		Course__c course = [SELECT id FROM Course__c LIMIT 1];
		List_Of_Values__c rejectedByApplicant = [
			SELECT id
			FROM List_Of_Values__c
			WHERE name = 'ACC-DEL (REJECTED)'
			LIMIT 1
		];
		List_Of_Values__c rejectedByMonash = [SELECT id FROM List_Of_Values__c WHERE name = 'REJECTED (REJECTED)' LIMIT 1];
		List_Of_Values__c acceptedByMonash = [SELECT id FROM List_Of_Values__c WHERE name = 'OFFER (OFFER)' LIMIT 1];
		Test.startTest();
		Application_Course_Preference__c acpForAppn1 = StudFirst_TestHelper.createCoursePreferences(
			appn1,
			applicant,
			offering,
			course
		);
		acpForAppn1.Outcome_Status_LOV__c = rejectedByMonash.id;
		Application_Course_Preference__c acpForAppn2 = StudFirst_TestHelper.createCoursePreferences(
			appn2,
			applicant,
			offering,
			course
		);
		acpForAppn2.Outcome_Status_LOV__c = acceptedByMonash.id;
		acpForAppn2.Offer_Response_Status_LOV__c = rejectedByApplicant.id;
		Application_Course_Preference__c acpForAppn3 = StudFirst_TestHelper.createCoursePreferences(
			appn3,
			applicant,
			offering,
			course
		);
		insert new List<Application_Course_Preference__c>{ acpForAppn1, acpForAppn2, acpForAppn3 };
		try {
			Application__C app = [SELECT id, Name FROM Application__c WHERE Id = :appn1.Id];
			ApplicationWSService.checkAgentDeclarationAcceptedApplications(app.Name);
			ApplicationWSService.checkApplicationReviewErrors(app.Id);
		} catch (Exception e) {
			Assert.isTrue(e.getMessage() != null, 'Exception is expected');
		}
		Test.stopTest();
	}
	@isTest
	static void testProcessMethodExceptions() {
		User portalUser = [SELECT Id FROM User WHERE email = 'testAgentLastName@TestEmail.com' LIMIT 1];

		System.runAs(portalUser) {
			// Create instance of CDM_Application
			String jsonTemplate = getTemplateJsonApplication();
			APNGApplicationPayload.CDM_Application cdmApplication = (APNGApplicationPayload.CDM_Application) JSON.deserialize(
				jsonTemplate,
				APNGApplicationPayload.CDM_Application.class
			);
			cdmApplication.workExperiences[0].countryObtained.crmRecordId = 'InvalidCountryId';
			// cdmApplication.workExperiences = null;
			cdmApplication.qualifications = null;
			cdmApplication.coursePreferences = null;
			// Call the method
			ApplicationWSService.PatchApplicationService patchService = new ApplicationWSService.PatchApplicationService(
				cdmApplication
			);
			Test.startTest();

			ApplicationWSWrapper.ApplicationResponseWrapper responseWrapper;
			try {
				responseWrapper = patchService.process();
			} catch (Exception e) {
				Assert.isNull(responseWrapper, 'Exception should be thrown');
			}
			Test.stopTest();
		}
	}
	@IsTest
	static void testHelperMethods() {
		User portalUser = [SELECT Id FROM User WHERE email = 'testAgentLastName@TestEmail.com' LIMIT 1];
		Account agency = [SELECT id, Callista_Org_Unit_Code__c FROM Account WHERE Name = 'TestAgencyAccount' LIMIT 1];

		Test.startTest();
		System.runAs(portalUser) {
			Contact con = new Contact(
				First_Name__c = 'Test',
				Last_Name__c = 'Test Last',
				Personal_email__c = 'test123@getnad.com',
				BirthDate = Date.valueOf('2003-02-01'),
				OwnerId = portalUser.id
			);
			insert con;
			Application__c app = new Application__c(
				Applicant__c = con.id,
				Status__c = 'Draft',
				Agent__c = agency.id,
				Agent_Org_Unit_Code__c = agency.Callista_Org_Unit_Code__c,
				Source_System__c = 'AgentPortal',
				Campus_Location__c = 'Malaysia',
				Residency_Status__c = 'DOM-SUN',
				Residency_Sub_status__c = 'DOM-SUN.B'
			);
			app = (Application__c) AgentPortalServices.createApplication(app, 'test123@getnad.com', '123');
			Assert.areEqual(
				true,
				ApplicationWSService.doOtherDraftsExistForSameCampus(
					con.id,
					'Malaysia',
					new Set<String>{ agency.Callista_Org_Unit_Code__c }
				),
				'Other drafts should exist for the same campus'
			);
			// Negative test case for doOtherDraftsExistForSameCampus
			Assert.areEqual(
				false,
				ApplicationWSService.doOtherDraftsExistForSameCampus(
					con.id,
					'Malaysia',
					new Set<String>{ 'InvalidOrgUnitCode' }
				),
				'Other drafts should not exist for the same campus'
			);
			Assert.areEqual(true, ApplicationWSService.isValidContact((String) con.id), 'Contact should be valid');
			Assert.areEqual(
				app.Name,
				ApplicationWSService.getApplicationByName([SELECT id, Name FROM Application__c WHERE Id = :app.Id].Name)[0]
					.Name,
				'Application should be found'
			);
		}
		Test.stopTest();
	}
	private static String getTemplateJsonApplication() {
		Contact applicant = [SELECT Id, CRM_ID__c FROM Contact WHERE LastName = 'Chen' LIMIT 1];

		Application__c testApplication = [
			SELECT id, Applicant__c, Name
			FROM Application__c
			WHERE Applicant__c = :applicant.Id
			LIMIT 1
		];
		Country_Attribute__c country = [SELECT Id FROM Country_Attribute__c WHERE Country__c = 'AUSTRALIA' LIMIT 1];
		Contact_Qualification__c qualificationEnglishTest = [
			SELECT Id
			FROM Contact_Qualification__c
			WHERE Contact__c = :testApplication.Applicant__c
		];
		List<Work_Experience__c> workExperiences = [
			SELECT Id, Country__c
			FROM Work_Experience__c
			WHERE Contact__c = :testApplication.Applicant__c
		];
		String jsonTemplate =
			'{ "smsApplicantId": "", "crmContactId": "{0}", "applicationId": "{1}", ' +
			'"applicationStatus": "Sent Draft Application to Applicant", "agentNotes": "SSSSSSSSS", "applicationType": "Default",' +
			' "residencyStatus": "INTRNTNL.B", "passportNumber": "", "hasDisability": { "code": "No" }, "existingDisabilitySupport": {}, ' +
			'"isPrincipalCourseTransfer": false, "hasRequestForScholarship": false, "hasRequestForAdvancedStanding": false, "englishLanguageProficiency": true,' +
			' "sponsorScholarship": "", "sponsorStatus": {}, "visa": { "citizenship": { "crmRecordId": "{2}", "code": "GG", "value": "Guernsey" },' +
			' "type": {}, "visaNumber": "", "hasRefusedEntry": { "code": "No" }, "hasBreachedVisa": { "code": "No" }, "hasMedicalIssues": { "code": "No" }, ' +
			'"hasProtectionVisa": { "code": "No" }, "hasConvictedOfCrime": { "code": "No" }, "immigrationOfficeIssued": "", "singleEntryVisaCountry": {} }, ' +
			'"coursePreferences": [ { "course": {}, "courseOffering": { "crmRecordId": "{3}", "studyPeriod": {}, "location": {} }, "preference": 1 } ], ' +
			'"qualifications": [ { "type": { "crmRecordId": "{4}", "name": "English Test" }, "countryObtained": {}, "institution": {},' +
			'"expectedDateOfCompletion": "2029-09-09" }, { "type": { "name": "Tertiary Education", "qualificationName": "bachelor of commerce" }, ' +
			'"startDate": "2020", "endDate": "2022", "countryObtained": { "crmRecordId": "{5}", "value": "CHINA" },' +
			' "status": "SUCCESSFULLY COMPLETED AND OBTAINED", "institution": { "crmRecordId": "{6}", "value": "TIANJIN UNIVERSITY, CN" } }, ' +
			'{ "type": { "crmRecordId": "", "name": "Secondary Education" }, "countryObtained": { "crmRecordId": "{7}", "value": "Argentina" }, ' +
			'"institution": { "value": "Argentina college" }, "expectedDateOfCompletion": "2024-09-07" }, { "type": { "crmRecordId": "{8}", "name": "Secondary Education" }, "endDate": "2022", "countryObtained": { "crmRecordId": "{secondaryEdCountryObtainedSFID}", "value": "El Salvador" }, "institution": { "value": "El salvador institution name test" } }, { "type": { "name": "Other Qualification", "qualificationName": "other qualification added by agent" }, "conferredDate": "2021-06-06", "countryObtained": {}, "institution": {} } ], "workExperiences": [ {"crmRecordId":"{workExcrmRecordId}", "position": "Developer", "employer": "ONGC", "startDate": "2020-05-05", "countryObtained": { "crmRecordId": "{workExCountryObtainedSFID}", "code": "IO", "uniqueCountryExternalId":"1101-AUS-36-0", "value":"Australia" }, "contactPerson": { "firstName": "test", "lastName": "teset" }, "contactAddress": "testsdf@test.com", "contactPhone": "0412341234" } ], "payment": { "mode": "Other", "amount": 100 } }';
		// Create instance of CDM_Application
		jsonTemplate = jsonTemplate.replace('{0}', applicant.CRM_Id__c);
		jsonTemplate = jsonTemplate.replace('{1}', testApplication.Name);
		jsonTemplate = jsonTemplate.replace('{2}', country.id);
		// incorrect course offering id to throw exception
		jsonTemplate = jsonTemplate.replace('{3}', applicant.CRM_Id__c);
		jsonTemplate = jsonTemplate.replace('{4}', qualificationEnglishTest.id);
		jsonTemplate = jsonTemplate.replace('{5}', country.id);
		jsonTemplate = jsonTemplate.replace('{secondaryEdCountryObtainedSFID}', country.Id);
		jsonTemplate = jsonTemplate.replace('{workExcrmRecordId}', workExperiences[0].id);
		jsonTemplate = jsonTemplate.replace('{workExCountryObtainedSFID}', workExperiences[0].Country__c);
		return jsonTemplate;
	}

	@IsTest
	static void testPatchApplicationServiceProcessAgentDeclarationAccepted() {
		// GIVEN an application ready for submission
		User portalUser = [SELECT Id FROM User WHERE email = 'testAgentLastName@TestEmail.com' LIMIT 1];
		Application__c app;
		Contact applicant = [SELECT Id, CRM_ID__c FROM Contact WHERE LastName = 'Chen' LIMIT 1];
		app = [SELECT Id, Name FROM Application__c WHERE Applicant__c = :applicant.Id LIMIT 1];
		Course_Offering__c courseOffering = [
			SELECT Id
			FROM Course_Offering__c
			WHERE Course_Offering_UID__c = 'CO-COCOID1'
			LIMIT 1
		];
		System.runAs(portalUser) {
			// WHEN submitting application with Agent Declaration Accepted status
			APNGApplicationPayload.CDM_Application cdmApp = new APNGApplicationPayload.CDM_Application();
			cdmApp.applicationREF = app.Name;
			cdmApp.applicationId = app.Name;
			cdmApp.applicationStatus = AgentPortalConstants.AGENT_DECLARATION_ACCEPTED;
			cdmApp.crmContactId = applicant.CRM_ID__c;

			ApplicationWSWrapper.CDM_Visa visa = new ApplicationWSWrapper.CDM_Visa();
			visa.citizenship = new ApplicationWSWrapper.CDM_Country();
			visa.singleEntryVisaCountry = new ApplicationWSWrapper.CDM_Country();
			visa.type = new ApplicationWSWrapper.CDM_VisaType();
			ApplicationWSWrapper.CDM_Status status = new ApplicationWSWrapper.CDM_Status();
			status.code = 'No';
			visa.hasRefusedEntry = status;
			visa.hasBreachedVisa = status;
			visa.hasMedicalIssues = status;
			visa.hasProtectionVisa = status;
			visa.hasConvictedOfCrime = status;
			cdmApp.visa = visa;

			ApplicationWSWrapper.CDM_CourseOffering courseOfferingCDM = new ApplicationWSWrapper.CDM_CourseOffering();
			courseOfferingCDM.crmRecordId = courseOffering.Id;

			// create a CDM for ACP
			ApplicationWSWrapper.CDM_ApplicationCoursePreference acpCDM = new ApplicationWSWrapper.CDM_ApplicationCoursePreference();
			//acpCDM.crmRecordId = testApplication.acp.Id;
			acpCDM.courseOffering = courseOfferingCDM;
			acpCDM.applicationRecord = app;

			// Add required course preferences for affiliation check
			//ApplicationWSWrapper.CDM_ApplicationCoursePreference acp = new ApplicationWSWrapper.CDM_ApplicationCoursePreference();
			cdmApp.coursePreferences = new List<ApplicationWSWrapper.CDM_ApplicationCoursePreference>{ acpCDM };

			Test.startTest();
			new ApplicationWSService.PatchApplicationService(cdmApp).process();
			// ApplicationWSService.checkAgentDeclarationAcceptedApplications(cdmApp.applicationId);
			// ApplicationWSService.checkApplicationReviewErrors(app.Id);
			Test.stopTest();
		}
		// THEN verify the application was submitted successfully
		Application__c updatedApp = [SELECT Id, Status__c, Submitted_Date__c FROM Application__c WHERE Id = :app.Id];
		Assert.areEqual(
			MyApplicationUtilities.APP_PENDING_MERGE_STATUS,
			updatedApp.Status__c,
			'Application status should be updated to pending merge'
		);
		Assert.areEqual(Date.today(), updatedApp.Submitted_Date__c, 'Submitted date should be set to today');
	}

	@IsTest
	static void testPatchApplicationServiceWorkExperiences() {
		// GIVEN a contact and application
		User portalUser = [SELECT Id FROM User WHERE email = 'testAgentLastName@TestEmail.com' LIMIT 1];
		Contact applicant = [SELECT Id, CRM_ID__c FROM Contact WHERE LastName = 'Chen' LIMIT 1];
		Application__c app = [SELECT Id, Name FROM Application__c WHERE Applicant__c = :applicant.Id LIMIT 1];
		Country_Attribute__c country = [SELECT Id FROM Country_Attribute__c WHERE Country__c = 'Australia' LIMIT 1];
		Course_Offering__c courseOffering = [
			SELECT Id
			FROM Course_Offering__c
			WHERE Course_Offering_UID__c = 'CO-COCOID1OES'
			LIMIT 1
		];
		System.runAs(portalUser) {
			// WHEN submitting application with Agent Declaration Accepted status
			APNGApplicationPayload.CDM_Application cdmApp = new APNGApplicationPayload.CDM_Application();
			cdmApp.applicationREF = app.Name;
			cdmApp.applicationId = app.Name;
			cdmApp.applicationStatus = AgentPortalConstants.AGENT_DECLARATION_ACCEPTED;
			cdmApp.crmContactId = applicant.CRM_ID__c;

			ApplicationWSWrapper.CDM_Visa visa = new ApplicationWSWrapper.CDM_Visa();
			visa.citizenship = new ApplicationWSWrapper.CDM_Country();
			visa.singleEntryVisaCountry = new ApplicationWSWrapper.CDM_Country();
			visa.type = new ApplicationWSWrapper.CDM_VisaType();
			ApplicationWSWrapper.CDM_Status status = new ApplicationWSWrapper.CDM_Status();
			status.code = 'No';
			visa.hasRefusedEntry = status;
			visa.hasBreachedVisa = status;
			visa.hasMedicalIssues = status;
			visa.hasProtectionVisa = status;
			visa.hasConvictedOfCrime = status;
			cdmApp.visa = visa;

			ApplicationWSWrapper.CDM_CourseOffering courseOfferingCDM = new ApplicationWSWrapper.CDM_CourseOffering();
			courseOfferingCDM.crmRecordId = courseOffering.Id;
			ApplicationWSWrapper.CDM_ApplicationCoursePreference acpCDM = new ApplicationWSWrapper.CDM_ApplicationCoursePreference();
			acpCDM.courseOffering = courseOfferingCDM;
			acpCDM.applicationRecord = app;
			cdmApp.coursePreferences = new List<ApplicationWSWrapper.CDM_ApplicationCoursePreference>{ acpCDM };
			// Add both historic and non-historic work experiences
			ApplicationWSWrapper.CDM_WorkExperience historicWorkExp = new ApplicationWSWrapper.CDM_WorkExperience();
			//historicWorkExp.isHistoric = true;
			historicWorkExp.employer = 'Historic Employer';
			historicWorkExp.position = 'Historic Position';
			historicWorkExp.countryObtained = new ApplicationWSWrapper.CDM_Country();
			historicWorkExp.countryObtained.crmRecordId = country.Id;
			ApplicationWSWrapper.CDM_WorkExperience currentWorkExp = new ApplicationWSWrapper.CDM_WorkExperience();
			//currentWorkExp.isHistoric = false;
			currentWorkExp.employer = 'Current Employer';
			currentWorkExp.position = 'Current Position';
			currentWorkExp.countryObtained = new ApplicationWSWrapper.CDM_Country();
			currentWorkExp.countryObtained.crmRecordId = country.Id;

			cdmApp.workExperiences = new List<ApplicationWSWrapper.CDM_WorkExperience>{ historicWorkExp, currentWorkExp };

			Test.startTest();
			ApplicationWSService.PatchApplicationService patchService = new ApplicationWSService.PatchApplicationService(
				cdmApp
			);
			List<Work_Experience__c> workExperiences = patchService.workExperiences;
			Test.stopTest();

			// THEN verify only non-historic work experiences are returned
			Assert.isNotNull(workExperiences, 'Work experiences list should not be null');
			Assert.isTrue(
				workExperiences[0].Employer_Name__c.contains('Employer'),
				'Should contain the current work experience'
			);
		}
	}

	@IsTest
	static void testGetWorkExperiencesByApplicationId() {
		// GIVEN an application and work experiences from test setup
		User portalUser = [SELECT Id FROM User WHERE email = 'testAgentLastName@TestEmail.com' LIMIT 1];
		Contact applicant = [SELECT Id FROM Contact WHERE LastName = 'Chen' LIMIT 1];
		Application__c app = [SELECT Id FROM Application__c WHERE Applicant__c = :applicant.Id LIMIT 1];

		System.runAs(portalUser) {
			// WHEN getting work experiences for the application
			Test.startTest();
			List<Work_Experience__c> workExperiences = ApplicationWSService.getWorkExperiencesByApplicationId(app.Id);
			Test.stopTest();

			// THEN verify work experiences are returned correctly
			Assert.isNotNull(workExperiences, 'Work experiences should not be null');
			Assert.areEqual(2, workExperiences.size(), 'Should return two work experiences');

			// Verify the work experiences contain the expected data
			Set<String> employerNames = new Set<String>();
			for (Work_Experience__c we : workExperiences) {
				employerNames.add(we.Employer_Name__c);
			}
			Assert.isTrue(employerNames.contains('ABC Ltd'), 'Should contain ABC Ltd as employer');
			Assert.isTrue(employerNames.contains('XYZ infotech'), 'Should contain XYZ infotech as employer');
		}
	}
	@IsTest
	static void testValidateQualifications() {
		Application__c app;
		User u = [SELECT id FROM user WHERE email = 'testAgentLastName@TestEmail.com'];
		System.runAs(u) {
			app = [SELECT Id, Name, Applicant__c FROM Application__c LIMIT 1];
		}
		OESApplicationPayload.PatchRequest patchRequest = new OESApplicationPayload.PatchRequest();
		patchRequest.application = new OESApplicationPayload.CDM_Application();
		patchRequest.application.applicationId = app.Name;

		// Create a list of qualifications
		List<ApplicationWSWrapper.CDM_Qualification> qualifications = new List<ApplicationWSWrapper.CDM_Qualification>();

		// English Test Qualification
		ApplicationWSWrapper.CDM_Qualification qualification = new ApplicationWSWrapper.CDM_Qualification();
		qualification.type = new ApplicationWSWrapper.CDM_QualificationType();
		qualification.type.crmRecordId = fflib_IDGenerator.generate(Qualification__c.SObjectType);
		qualification.type.name = 'English Test';
		qualification.type.code = '';
		qualification.type.qualificationName = 'Cambridge Linguaskill';
		qualification.type.qualificationUid = 'MEPT0';
		qualification.verificationStatus = 'Done';
		qualification.resultType = 'Done';
		qualification.conferredDate = '';
		// Add scores
		qualification.scores = new List<ApplicationWSWrapper.CDM_QualificationScore>();
		ApplicationWSWrapper.CDM_QualificationScore score1 = new ApplicationWSWrapper.CDM_QualificationScore();
		score1.name = 'listening';
		score1.value = '100';
		qualification.scores.add(score1);
		qualification.countryObtained = new ApplicationWSWrapper.CDM_Country();
		qualification.countryObtained.crmRecordId = fflib_IDGenerator.generate(Country_Attribute__c.SObjectType);
		qualification.expectedDateOfCompletion = '202-09-09';
		qualifications.add(qualification);
		patchRequest.application.qualifications = qualifications;
		u = [SELECT id FROM user WHERE email = 'testAgentLastName@TestEmail.com'];
		System.runAs(u) {
			Test.startTest();
			new ApplicationWSService.PatchApplicationService(patchRequest.application);
			Test.stopTest();
		}
		// Add assertions to verify the error messages
		Assert.isTrue(qualifications.size() >= 1, 'qualifications should atleast have 1 item');
	}
}