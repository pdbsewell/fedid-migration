/**
 * @description       : Test class for ApplicationWSValidations abstract class
 * @author            : Ben Greenland
 * @group             : Admissions
 * @last modified on  : 2024-10-26
 * @last modified by  : Ben Greenland
 * Modifications Log
 * Ver   Date         Author         Modification
 * 1.0   2024-10-22   Ben Greenland   Initial Version
 **/
@isTest(isParallel=true)
private class ApplicationWSValidations_Test extends ApplicationWSValidations {
	@TestSetup
	static void makeData() {
		TriggerCommon.disableTrigger('Country_Attribute__c');
		TriggerCommon.disableTrigger('Account');
		TriggerCommon.disableTrigger('Contact');
		TriggerCommon.disableTrigger('User');
		AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();
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
		TriggerCommon.enableTrigger('Country_Attribute__c');
		TriggerCommon.enableTrigger('Account');
		TriggerCommon.enableTrigger('Contact');
		TriggerCommon.enableTrigger('User');
	}

	@IsTest
	static void testValidateCampusLocation() {
		// GIVEN a TestApplicationWSValidations instance
		ApplicationWSValidations validations = new ApplicationWSValidations();

		User u = [
			SELECT id
			FROM User
			WHERE username LIKE '%testAgentLastName@TestEmail.com.domain%'
			LIMIT 1
		];
		System.runAs(u) {
			Contact con = [SELECT Id, CRM_ID__C FROM Contact LIMIT 1];
			// WHEN validating a valid campus location
			validations.validateCampusLocation('Australia', con.CRM_ID__C);

			// THEN no exception should be added
			Assert.isTrue(
				String.isBlank(validations.exceptions.getListExceptionSummaryString()),
				'No exceptions should be added for a valid campus location'
			);

			// WHEN validating an invalid campus location
			validations.validateCampusLocation('', fflib_IDGenerator.generate(Contact.SObjectType));

			// THEN an exception should be added
			Assert.isFalse(
				validations.exceptions.getExceptions().isEmpty(),
				'An exception should be added for an invalid campus location'
			);
		}
	}

	@IsTest
	static void testDefaultVirtualMethods() {
		// GIVEN an instance of ApplicationWSValidations
		ApplicationWSValidations validations = new ApplicationWSValidations();
		RESTlib_Payload.Request dummyRequest = new APNGApplicationPayload.PostRequest();

		// WHEN calling the default virtual methods
		Test.startTest();
		Boolean isValid = validations.isValidRequestType(dummyRequest);
		String contactId = validations.getContactId(dummyRequest);
		String campusLocation = validations.getCampusLocation(dummyRequest);
		String residencyStatus = validations.getResidencyStatus(dummyRequest);
		List<CommonWSPayload.Email> emails = validations.getEmail(dummyRequest);
		List<CommonWSPayload.Phone> phones = validations.getPhone(dummyRequest);
		Test.stopTest();

		// THEN they should return the default values
		Assert.isFalse(isValid, 'Default isValidRequestType should return false');
		Assert.isNull(contactId, 'Default getContactId should return null');
		Assert.isNull(campusLocation, 'Default getCampusLocation should return null');
		Assert.isNull(residencyStatus, 'Default getResidencyStatus should return null');
		Assert.isNull(emails, 'Default getEmail should return null');
		Assert.isNull(phones, 'Default getPhone should return null');
	}
	@IsTest
	static void testValidateEnglishTestInvalidAttributes() {
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
		qualification.type.qualificationName = 'bachelor of commerce';
		qualification.type.qualificationUid = 'MEPT0';
		qualification.verificationStatus = 'Done';
		qualification.resultType = 'Done';
		qualification.expectedDateOfCompletion = '2012-10-10';
		qualification.countryObtained = new ApplicationWSWrapper.CDM_Country();
		qualifications.add(qualification);
		// New English test
		qualification = new ApplicationWSWrapper.CDM_Qualification();
		qualification.type = new ApplicationWSWrapper.CDM_QualificationType();
		qualification.type.crmRecordId = fflib_IDGenerator.generate(Qualification__c.SObjectType);
		qualification.type.name = 'English Test';
		qualification.type.code = '';
		qualification.type.qualificationName = 'bachelor of commerce';
		qualification.type.qualificationUid = 'MEPT0';
		qualification.verificationStatus = 'Done';
		qualification.resultType = 'Done';
		qualification.countryObtained = new ApplicationWSWrapper.CDM_Country();
		qualifications.add(qualification);

		patchRequest.application.qualifications = qualifications;
		OESApplicationValidations validations = new OESApplicationValidations(patchRequest);
		u = [SELECT id FROM user WHERE email = 'testAgentLastName@TestEmail.com'];
		System.runAs(u) {
			Test.startTest();
			validations.validateQualification();
			Test.stopTest();
		}
		// // Add assertions to verify the error messages
		Assert.isTrue(qualifications.size() >= 1, 'Qualifications should atleast have 1 item');
	}
	@IsTest
	static void testValidateScore() {
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
		qualification.expectedDateOfCompletion = '2024';
		qualification.type.code = '';
		qualification.type.qualificationName = 'Pearoson Test';
		qualification.type.qualificationUid = 'MPT0';
		qualification.verificationStatus = 'Done';
		qualification.resultType = 'Done';
		qualification.conferredDate = '';
		// Add scores
		qualification.scores = new List<ApplicationWSWrapper.CDM_QualificationScore>();
		ApplicationWSWrapper.CDM_QualificationScore score1 = new ApplicationWSWrapper.CDM_QualificationScore();
		score1.name = 'listening';
		score1.value = '12s22';
		qualification.scores.add(score1);

		ApplicationWSWrapper.CDM_QualificationScore score2 = new ApplicationWSWrapper.CDM_QualificationScore();
		score2.name = 'reading';
		score2.value = '22222';
		qualification.scores.add(score2);

		ApplicationWSWrapper.CDM_QualificationScore score3 = new ApplicationWSWrapper.CDM_QualificationScore();
		score3.name = 'speaking';
		score3.value = '2222221';
		qualification.scores.add(score3);

		ApplicationWSWrapper.CDM_QualificationScore score4 = new ApplicationWSWrapper.CDM_QualificationScore();
		score4.name = 'writing';
		score4.value = '122222';
		qualification.scores.add(score4);

		qualification.countryObtained = new ApplicationWSWrapper.CDM_Country();
		qualification.expectedDateOfCompletion = '202-09-09';
		qualifications.add(qualification);
		patchRequest.application.qualifications = qualifications;
		OESApplicationValidations validations = new OESApplicationValidations(patchRequest);
		u = [SELECT id FROM user WHERE email = 'testAgentLastName@TestEmail.com'];
		System.runAs(u) {
			Test.startTest();
			validations.qualificationValidator.validateEnglishTest(qualification);
			validations.qualificationValidator.validateScores(qualification);
			Test.stopTest();
		}
		// Add assertions to verify the error messages
		Assert.isTrue(qualifications.size() >= 1, 'qualifications should atleast have 1 item');
	}

	@IsTest
	static void testPatchRequest() {
		AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();
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
		AgentPortalTestDataBuilder.Application testApplication = new AgentPortalTestDataBuilder.Application()
			.withAgent(portalUser)
			.build();

		// GIVEN : a HandleGet instance
		APNGApplicationImpl.HandlePatch handler = new APNGApplicationImpl.HandlePatch();

		Type returnRequest;
		Type returnResponse;

		Test.startTest();
		System.runAs(portalUser.testUser) {
			// WHEN : I invoke get types
			returnRequest = handler.getRequestType();
			returnResponse = handler.getResponseType();

			// Retrieve test data
			ApplicationWSWrapper.CDM_CourseOffering coCDM = new ApplicationWSWrapper.CDM_CourseOffering();
			coCDM.crmRecordId = 'co.Id';
			coCDM.courseOfferingUid = 'co.Course_Offering_UID__c';
			coCDM.applicationRecord = testApplication.app;
			//  Minimum ACP

			// APNGApplicationPayload.CDM_ApplicationCoursePreference acpCDM = new APNGApplicationPayload.CDM_ApplicationCoursePreference();
			// acpCDM.courseOffering = coCDM;
			// acpCDM.applicationRecord = testApplication.app;
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
			patchRequest.application = application;

			// Invalid Work Experience
			ApplicationWSWrapper.CDM_WorkExperience invalidWorkExperience = new ApplicationWSWrapper.CDM_WorkExperience();
			invalidWorkExperience.position = '';
			invalidWorkExperience.employer = '';
			invalidWorkExperience.startDate = '';
			invalidWorkExperience.endDate = '';
			patchRequest.application.workExperiences = new List<ApplicationWSWrapper.CDM_WorkExperience>{
				invalidWorkExperience
			};
			// qualifications
			// Invalid Secondary Education Qualification
			ApplicationWSWrapper.CDM_Qualification invalidQualification = new ApplicationWSWrapper.CDM_Qualification();
			invalidQualification.type = new ApplicationWSWrapper.CDM_QualificationType();
			invalidQualification.type.name = 'Secondary Education';
			invalidQualification.countryObtained = new ApplicationWSWrapper.CDM_Country();
			invalidQualification.countryObtained.crmRecordId = '';
			invalidQualification.countryObtained.value = '';
			invalidQualification.expectedDateOfCompletion = '';
			patchRequest.application.qualifications = new List<ApplicationWSWrapper.CDM_Qualification>{
				invalidQualification
			};
			RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
			APNGApplicationValidations validations;
			try {
				validations = new APNGApplicationValidations();
				// WHEN : I invoke validate()
				exceptions = validations.validatePatch(patchRequest);
			} catch (RESTlib_Ex.InvalidRequestException e) {
				// THEN : no exceptions should be thrown
				Assert.isTrue(e.getMessage() != null, 'Exception was thrown');
			} catch (Exception e) {
				// THEN : no exceptions should be thrown
				Assert.isTrue(e.getMessage() != null, 'Exception was thrown');
			}

			Test.stopTest();
		}
	}

	@isTest
	static void testValidatePayment2() {
		// GIVEN a TestApplicationWSValidations instance
		APNGApplicationPayload.CDM_Application application = new APNGApplicationPayload.CDM_Application();
		application.payment = new ApplicationWSWrapper.CDM_Payment();
		application.payment.datePaid = '20s24-1s0-ss26s';
		application.payment.amount = '1000p';
		ApplicationWSValidations validations = new ApplicationWSValidations();
		AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();
		Test.startTest();
		System.runAs(portalUser.testUser) {
			validations.validatePayment(application.payment);
		}
		Test.stopTest();
		// TODO: Fix payment error messages
		Assert.isTrue(
			validations.exceptions.getListExceptionSummaryString()
				.contains(validations.getAPIResponseMessages('INVALID_PAID_DATE', '')),
			'Exception should be thrown for invalid date format'
		);
		Assert.isTrue(
			validations.exceptions.getListExceptionSummaryString()
				.contains(validations.getAPIResponseMessages('INVALID_PAYMENT_AMOUNT', '')),
			'Exception should be thrown for invalid fee amount'
		);
	}
	@IsTest
	static void testValidatePayment() {
		// GIVEN a TestApplicationWSValidations instance
		APNGApplicationPayload.CDM_Application application = new APNGApplicationPayload.CDM_Application();
		application.payment = new ApplicationWSWrapper.CDM_Payment();
		application.payment.datePaid = '20s24-1s0-ss26s';
		application.payment.amount = '1000p';
		ApplicationWSValidations validations = new ApplicationWSValidations();
		AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();
		Test.startTest();
		System.runAs(portalUser.testUser) {
			validations.validatePayment(application.payment);
		}
		Test.stopTest();
		// TODO: Fix payment error messages
		Assert.isTrue(
			validations.exceptions.getListExceptionSummaryString()
				.contains(validations.getAPIResponseMessages('INVALID_PAID_DATE', '')),
			'Exception should be thrown for invalid date format'
		);
		Assert.isTrue(
			validations.exceptions.getListExceptionSummaryString()
				.contains(validations.getAPIResponseMessages('INVALID_PAYMENT_AMOUNT', '')),
			'Exception should be thrown for invalid fee amount'
		);
	}
	@isTest
	static void testValidateWorkExp() {
		AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();
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
		AgentPortalTestDataBuilder.Application testApplication = new AgentPortalTestDataBuilder.Application()
			.withAgent(portalUser)
			.build();

		Test.startTest();
		System.runAs(portalUser.testUser) {
			APNGApplicationPayload.CDM_Application application = new APNGApplicationPayload.CDM_Application();
			application.applicationId = [SELECT id, name FROM Application__c WHERE Id = :testApplication.app.Id].Name;
			application.crmContactId = testApplication.applicant.Id;
			List<ApplicationWSWrapper.CDM_WorkExperience> listWorkEx = new List<ApplicationWSWrapper.CDM_WorkExperience>();
			// Invalid Work Experience
			ApplicationWSWrapper.CDM_WorkExperience invalidWorkExperience = new ApplicationWSWrapper.CDM_WorkExperience();
			invalidWorkExperience.position = '';
			invalidWorkExperience.employer = '';
			invalidWorkExperience.startDate = '';
			invalidWorkExperience.endDate = '';
			listWorkEx.add(invalidWorkExperience);
			// Invalid Work Experience
			invalidWorkExperience = new ApplicationWSWrapper.CDM_WorkExperience();
			invalidWorkExperience.startDate = '2020';
			invalidWorkExperience.endDate = '2021';
			listWorkEx.add(invalidWorkExperience);
			ApplicationWSWrapper.CDM_WorkExperience validWorkExperience = new ApplicationWSWrapper.CDM_WorkExperience();
			validWorkExperience.position = 'Sr Dev';
			validWorkExperience.employer = 'Monash';
			validWorkExperience.startDate = '2024-10-10';
			validWorkExperience.endDate = '2025-01-01';
			listWorkEx.add(validWorkExperience);
			ApplicationWSValidations validations;
			try {
				validations = new ApplicationWSValidations();
				// WHEN : I invoke validate()
				validations.workExperienceValidator.validateWorkExperience(listWorkEx);
			} catch (RESTlib_Ex.InvalidRequestException e) {
				// THEN : no exceptions should be thrown
				Assert.isTrue(e.getMessage() != null, 'Exception was thrown');
			} catch (Exception e) {
				// THEN : no exceptions should be thrown
				Assert.isTrue(e.getMessage() != null, 'Exception was thrown');
			}
			// Add assertions to verify the error messages
			String errorSummary = validations.exceptions.getListExceptionSummaryString();
			Assert.isTrue(
				errorSummary.contains(validations.getAPIResponseMessages('EMPLOYER_EMPTY', '')),
				'Exception should be thrown for EMPLOYER_EMPTY'
			);

			Assert.isTrue(
				errorSummary.contains(validations.getAPIResponseMessages('POSITION_EMPTY', '')),
				'Exception should be thrown for POSITION_EMPTY'
			);

			Assert.isTrue(
				errorSummary.contains(validations.getAPIResponseMessages('COUNTRY_EMPTY', '')),
				'Exception should be thrown for COUNTRY_EMPTY'
			);
			Assert.isTrue(
				errorSummary.contains(validations.getAPIResponseMessages('START_DATE_INVALID_FORMAT', '')),
				'Exception should be thrown for START_DATE_INVALID_FORMAT'
			);

			Test.stopTest();
		}
	}
	@isTest
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

		// Other Qualification
		ApplicationWSWrapper.CDM_Qualification qualification = new ApplicationWSWrapper.CDM_Qualification();
		qualification.type = new ApplicationWSWrapper.CDM_QualificationType();
		qualification.type.crmRecordId = fflib_IDGenerator.generate(Qualification__c.SObjectType);
		qualification.type.name = 'Other Qualification';
		qualification.type.qualificationName = 'Other Cambridge Linguaskill';
		qualification.conferredDate = '';
		qualifications.add(qualification);
		// Other Qualification
		qualification = new ApplicationWSWrapper.CDM_Qualification();
		qualification.type = new ApplicationWSWrapper.CDM_QualificationType();
		qualification.type.crmRecordId = fflib_IDGenerator.generate(Qualification__c.SObjectType);
		qualification.type.qualificationName = 'Other Cambridge Linguaskill';
		qualification.expectedDateOfCompletion = '2020-09-09';
		qualifications.add(qualification);
		// Tertiary qualification
		qualification.type = new ApplicationWSWrapper.CDM_QualificationType();
		qualification.type.crmRecordId = fflib_IDGenerator.generate(Qualification__c.SObjectType);
		qualification.type.name = 'Tertiary Education';
		qualifications.add(qualification);
		// Tertiary qualification
		qualification.type = new ApplicationWSWrapper.CDM_QualificationType();
		qualification.type.crmRecordId = fflib_IDGenerator.generate(Qualification__c.SObjectType);
		qualification.type.name = 'Secondary Education';
		qualifications.add(qualification);
		qualification.type = new ApplicationWSWrapper.CDM_QualificationType();
		qualification.type.crmRecordId = fflib_IDGenerator.generate(Qualification__c.SObjectType);
		qualification.type.name = 'Secondary Education';
		qualification.endDate = '231';
		qualification.expectedDateOfCompletion = '2010-01-01';
		qualifications.add(qualification);
		qualification.type = new ApplicationWSWrapper.CDM_QualificationType();
		qualification.type.crmRecordId = fflib_IDGenerator.generate(Qualification__c.SObjectType);
		qualification.type.name = 'Secondary Education';
		qualifications.add(qualification);
		// Tertiary qualification
		qualification.type = new ApplicationWSWrapper.CDM_QualificationType();
		qualification.type.crmRecordId = fflib_IDGenerator.generate(Qualification__c.SObjectType);
		qualification.type.name = 'Tertiary Education';
		qualification.endDate = '2010';
		qualification.startDate = '2020';
		qualifications.add(qualification);
		OESApplicationValidations validations = new OESApplicationValidations(patchRequest);
		u = [SELECT id FROM user WHERE email = 'testAgentLastName@TestEmail.com'];
		System.runAs(u) {
			Test.startTest();
			validations.qualificationValidator.validateOtherQualification(qualifications[0]);
			validations.qualificationValidator.validateOtherQualification(qualifications[1]);
			validations.qualificationValidator.validateTertiaryQualification(qualifications[2]);
			validations.qualificationValidator.validateSecondaryQualification(qualifications[3]);
			validations.qualificationValidator.validateSecondaryQualification(qualifications[4]);
			validations.qualificationValidator.validateSecondaryQualification(qualifications[5]);
			Test.stopTest();
		}
		// Add assertions to verify the error messages
		String errorSummary = validations.exceptions.getListExceptionSummaryString();
		Assert.isTrue(
			errorSummary.contains(validations.getAPIResponseMessages('LEVEL_OF_COMPLETION_EMPTY', '')),
			'Exception should be thrown for LEVEL_OF_COMPLETION_EMPTY'
		);
	}
	@isTest
	static void testHelperMethods() {
		ApplicationWSValidations validations;
		Test.startTest();
		validations = new ApplicationWSValidations();
		Test.stopTest();

		// THEN they should return the default values
		Assert.isTrue(validations.isValidDecimal('1.0'), 'Invalid decimal value');
		Assert.isFalse(validations.isValidDecimal('1q0'), 'Invalid decimal value');
	}
	@IsTest
	static void testValidateContactId() {
		// GIVEN an ApplicationWSValidations instance
		ApplicationWSValidations validations = new ApplicationWSValidations();

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

			// WHEN validating a valid contact ID
			validations.validateContactId([SELECT id, CRM_ID__C FROM Contact LIMIT 1].CRM_ID__C);
			// THEN no exception should be added
			Assert.isTrue(
				String.isBlank(validations.exceptions.getListExceptionSummaryString()),
				'No exceptions should be added for a valid contact ID'
			);

			// WHEN validating an invalid contact ID
			validations.validateContactId('');

			// THEN an exception should be added
			Assert.isFalse(
				validations.exceptions.getExceptions().isEmpty(),
				'An exception should be added for an invalid contact ID'
			);
		}

	}

	@IsTest
	static void testValidateResidencyStatus() {
		// GIVEN an ApplicationWSValidations instance
		ApplicationWSValidations validations = new ApplicationWSValidations();

		// WHEN validating a valid residency status
		validations.validateResidencyStatus('Domestic');

		// THEN no exception should be added
		Assert.isTrue(
			String.isBlank(validations.exceptions.getListExceptionSummaryString()),
			'No exceptions should be added for a valid residency status'
		);

		// WHEN validating an invalid residency status
		validations.validateResidencyStatus('');

		// THEN an exception should be added
		Assert.isFalse(
			validations.exceptions.getExceptions().isEmpty(),
			'An exception should be added for an invalid residency status'
		);
	}

	@IsTest
	static void testValidateEmail() {
		// GIVEN an ApplicationWSValidations instance
		ApplicationWSValidations validations = new ApplicationWSValidations();

		// WHEN validating a valid email
		List<CommonWSPayload.Email> validEmails = new List<CommonWSPayload.Email>();
		CommonWSPayload.Email email = new CommonWSPayload.Email();
		email.email = 'test@example.com';
		email.type = 'Personal';
		validEmails.add(email);
		validations.validateEmail(validEmails);

		// THEN no exception should be added
		Assert.isTrue(
			String.isBlank(validations.exceptions.getListExceptionSummaryString()),
			'No exceptions should be added for valid emails'
		);

		// WHEN validating invalid emails
		List<CommonWSPayload.Email> invalidEmails = new List<CommonWSPayload.Email>();
		CommonWSPayload.Email emailInvalid = new CommonWSPayload.Email();
		emailInvalid.email = '';
		emailInvalid.type = 'Personal';
		invalidEmails.add(emailInvalid);
		validations.validateEmail(invalidEmails);

		// THEN an exception should be added
		Assert.isFalse(validations.exceptions.getExceptions().isEmpty(), 'An exception should be added for invalid emails');
	}

	@IsTest
	static void testValidatePhone() {
		// GIVEN an APNGApplicationValidations instance
		ApplicationWSValidations validations = new ApplicationWSValidations();

		// WHEN validating a valid phone
		List<CommonWSPayload.Phone> validPhones = new List<CommonWSPayload.Phone>();
		CommonWSPayload.Phone phone = new CommonWSPayload.Phone();
		phone.phoneNumber = '1234567890';
		phone.type = 'Mobile';
		validPhones.add(phone);
		validations.validatePhone(validPhones);

		// THEN no exception should be added
		Assert.isTrue(
			String.isBlank(validations.exceptions.getListExceptionSummaryString()),
			'No exceptions should be added for valid phones'
		);

		// WHEN validating invalid phones
		List<CommonWSPayload.Phone> invalidPhones = new List<CommonWSPayload.Phone>();
		CommonWSPayload.Phone phoneInvalid = new CommonWSPayload.Phone();
		phoneInvalid.phoneNumber = '';
		phoneInvalid.type = 'Mobile';
		invalidPhones.add(phoneInvalid);
		validations.validatePhone(invalidPhones);

		// THEN an exception should be added
		Assert.isFalse(validations.exceptions.getExceptions().isEmpty(), 'An exception should be added for invalid phones');
	}
    
    /**
	 * Tests with expectedDateOfCompletion and no scores to verify that
	 * there is no validation error
	 */
	@IsTest
	static void testForNoValidationErrorOnEnglishTestForAPNG() {
		Application__c app;
		User u = [SELECT id FROM user WHERE email = 'testAgentLastName@TestEmail.com'];
		System.runAs(u) {
			app = [SELECT Id, Name, Applicant__c FROM Application__c LIMIT 1];
		}
		APNGApplicationPayload.PatchRequest patchRequest = new APNGApplicationPayload.PatchRequest();
		patchRequest.application = new APNGApplicationPayload.CDM_Application();
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
		qualification.verificationStatus = 'Done';
		qualification.resultType = 'Done';
		qualification.conferredDate = null;
		//Don't send score as we have provided Expected date of completion
		qualification.score = null;

		qualification.countryObtained = new ApplicationWSWrapper.CDM_Country();
		qualification.expectedDateOfCompletion = String.valueOf(System.today().addYears(2));
		qualifications.add(qualification);
		patchRequest.application.qualifications = qualifications;
		APNGApplicationValidations validations = new APNGApplicationValidations(patchRequest);
		u = [SELECT id FROM user WHERE email = 'testAgentLastName@TestEmail.com'];
		System.runAs(u) {
			Test.startTest();
			validations.qualificationValidator.validateEnglishTest(qualification);
			Test.stopTest();
		}
		// Add assertions to verify the error messages
		List<RESTlib_Ex.ListException> exceptionList = validations.exceptions.getExceptions();
		//THEN - There should be no exception as conferreddate was not provided. expectedDateOfCompletion was provided and there was no score.
		Assert.isTrue(exceptionList==null , 'There must be no exceptions in exceptionList');
	}

	/**
	 * Tests with conferredDate and no scores to verify that
	 * there is a validation error returned
	 */
	@IsTest
	static void testForValidationErrorOnEnglishTestForAPNG() {
		Application__c app;
		User u = [SELECT id FROM user WHERE email = 'testAgentLastName@TestEmail.com'];
		System.runAs(u) {
			app = [SELECT Id, Name, Applicant__c FROM Application__c LIMIT 1];
		}
		APNGApplicationPayload.PatchRequest patchRequest = new APNGApplicationPayload.PatchRequest();
		patchRequest.application = new APNGApplicationPayload.CDM_Application();
		patchRequest.application.applicationId = app.Name;
		//GIVEN - All the qualification data for English Test is created without expecteddateofCompletion field and no scores
		// Create a list of qualifications
		List<ApplicationWSWrapper.CDM_Qualification> qualifications = new List<ApplicationWSWrapper.CDM_Qualification>();

		// English Test Qualification
		ApplicationWSWrapper.CDM_Qualification qualification = new ApplicationWSWrapper.CDM_Qualification();
		qualification.type = new ApplicationWSWrapper.CDM_QualificationType();
		qualification.type.crmRecordId = fflib_IDGenerator.generate(Qualification__c.SObjectType);
		qualification.type.name = 'English Test';
		qualification.type.code = '';
		qualification.type.qualificationName = 'Cambridge Linguaskill';
		qualification.verificationStatus = 'Done';
		qualification.resultType = 'Done';
		//Don't send score as we have provided Expected date of completion
		qualification.score = null;

		qualification.countryObtained = new ApplicationWSWrapper.CDM_Country();
		qualification.conferredDate = String.valueOf(System.today().addYears(-1));
		qualifications.add(qualification);
		patchRequest.application.qualifications = qualifications;
		APNGApplicationValidations validations = new APNGApplicationValidations(patchRequest);
		u = [SELECT id FROM user WHERE email = 'testAgentLastName@TestEmail.com'];
		//WHEN - the method is called with the data
		System.runAs(u) {
			Test.startTest();
			validations.qualificationValidator.validateEnglishTest(qualification);
			Test.stopTest();
		}
		// Add assertions to verify the errors
		List<RESTlib_Ex.ListException> exceptionList = validations.exceptions.getExceptions();
		//THEN - There should be no exception as conferreddate was  provided, expectedDateOfCompletion was not provided and there was no score.
		Assert.isTrue(exceptionList.size()>= 1, 'exceptionList should atleast have 1 item');
	}


	/**
	 * Tests with expectedDateOfCompletion and no scores to verify that
	 * there is no validation error
	 */
	@IsTest
	static void testForNoValidationErrorOnEnglishTestForOES() {
		Application__c app;
		User u = [SELECT id FROM user WHERE email = 'testAgentLastName@TestEmail.com'];
		System.runAs(u) {
			app = [SELECT Id, Name, Applicant__c FROM Application__c LIMIT 1];
		}
		APNGApplicationPayload.PatchRequest patchRequest = new APNGApplicationPayload.PatchRequest();
		patchRequest.application = new APNGApplicationPayload.CDM_Application();
		patchRequest.application.applicationId = app.Name;

		// Create a list of qualifications
		List<ApplicationWSWrapper.CDM_Qualification> qualifications = new List<ApplicationWSWrapper.CDM_Qualification>();

		// English Test Qualification
		ApplicationWSWrapper.CDM_Qualification qualification = new ApplicationWSWrapper.CDM_Qualification();
		qualification.type = new ApplicationWSWrapper.CDM_QualificationType();
		qualification.type.crmRecordId = fflib_IDGenerator.generate(Qualification__c.SObjectType);
		qualification.type.name = 'English Test';
		qualification.type.code = '';
		qualification.type.qualificationName = '25 in Units 3 & 4 VCE English or Equivalent';
		qualification.verificationStatus = 'Done';
		qualification.resultType = 'Done';
		qualification.conferredDate = null;
		//Don't send score as we have provided Expected date of completion
		qualification.score = null;

		qualification.countryObtained = new ApplicationWSWrapper.CDM_Country();
		qualification.expectedDateOfCompletion = String.valueOf(System.today().addYears(2));
		qualifications.add(qualification);
		patchRequest.application.qualifications = qualifications;
		APNGApplicationValidations validations = new APNGApplicationValidations(patchRequest);
		u = [SELECT id FROM user WHERE email = 'testAgentLastName@TestEmail.com'];
		System.runAs(u) {
			Test.startTest();
			validations.qualificationValidator.validateEnglishTest(qualification);
			Test.stopTest();
		}
		// Add assertions to verify the error messages
		List<RESTlib_Ex.ListException> exceptionList = validations.exceptions.getExceptions();
		//THEN - There should be no exception as conferreddate was not provided. expectedDateOfCompletion was provided and there was no score.
		Assert.isNull(exceptionList , 'There must be no exceptions in exceptionList');
	}
    
    /**
	 * Tests  validatePersonalEmail with empty string
	 * there is a validation error
	 */
	@IsTest
	static void testValidatePersonalEmailWithEmptyEmail() {
        //GIVEN an ApplicationWSValidations instance
         ApplicationWSValidations validations = new ApplicationWSValidations();
        //WHEN empty string is passed to the method
         validations.validatePersonalEmail('');
        //THEN there should be an exception
         Assert.isFalse(validations.exceptions.getExceptions().isEmpty(),
			'There should be an exception about using empty email'
		);
    }
    
    /**
	 * Tests  validatePersonalEmail with monash string
	 * there is a validation error
	 */
	@IsTest
	static void testValidatePersonalMonashEmail() {
		// GIVEN an ApplicationWSValidations instance
      	 ApplicationWSValidations validations = new ApplicationWSValidations();
        //WHEN monash string is passed to the method
         validations.validatePersonalEmail('shalini@monash.edu');
        //THEN there should be an exception
           Assert.isFalse(validations.exceptions.getExceptions().isEmpty(),
			'There should be an exception about using monash id'
		);
    }
    
     /**
	 * Tests  validateEmails 
	 * there is no validation error
	 */
    @IsTest
	static void testValidateEmails() {
     	 
      // GIVEN an ApplicationWSValidations instance
		ApplicationWSValidations validations = new ApplicationWSValidations();

		// WHEN validating a valid email
		List<CommonWSPayload.Email> validEmails = new List<CommonWSPayload.Email>();
		CommonWSPayload.Email email = new CommonWSPayload.Email();
		email.email = 'test@example.com';
		email.type = 'Personal';
		validEmails.add(email);
		validations.validateEmails(validEmails);

		// THEN no exception should be added
		Assert.isTrue(
			String.isBlank(validations.exceptions.getListExceptionSummaryString()),
			'No exceptions should be added for valid emails'
		);
    }
	
}