/**
 * @description       : Test class for OESApplicationValidations class
 * @author            : Ben Greenland
 * @group             : Admissions Web Services
 * @last modified on  : 2024-11-01
 * @last modified by  : Ben Greenland
 **/
// TEMP to fix PMD picking them after multiple runs
// PMD complains errors for private methods being used in test classes. MOst varibales are private in the class
// https://github.com/forcedotcom/salesforcedx-vscode/issues/2046
@isTest(isParallel=true)
private class OESApplicationValidations_Test {
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
		);

		// avoid MIXED_DML_OPERATION
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
		TriggerCommon.enableTrigger('Country_Attribute__c');
		TriggerCommon.enableTrigger('Account');
		TriggerCommon.enableTrigger('Contact');
		TriggerCommon.enableTrigger('User');
	}
	@IsTest
	static void testValidateRequestValid() {
		User u = [
			SELECT id
			FROM User
			WHERE username LIKE '%testAgentLastName@TestEmail.com.domain%'
			LIMIT 1
		];
		System.runAs(u) {
			Contact con = [SELECT Id, CRM_ID__C FROM Contact LIMIT 1];
			// GIVEN a valid request
			OESApplicationPayload.PostRequest validRequest = new OESApplicationPayload.PostRequest();
			validRequest.contactId = con.CRM_ID__C;
			validRequest.campusLocation = 'Australia';
			validRequest.residencyStatus = 'Domestic';
			CommonWSPayload.Email email = new CommonWSPayload.Email();
			email.email = 'test@example.com';
			email.type = 'Personal';
			validRequest.email = new List<CommonWSPayload.Email>{ email };
			CommonWSPayload.Phone phone = new CommonWSPayload.Phone();
			phone.phoneNumber = '1234567890';
			phone.type = 'Mobile';
			validRequest.phone = new List<CommonWSPayload.Phone>{ phone };

			// WHEN validating the request
			Test.startTest();
			OESApplicationValidations validator = new OESApplicationValidations();
			RESTlib_Ex.ListException result = validator.validate(validRequest);

			Test.stopTest();

			// THEN no exceptions should be returned
			Assert.isNull(result, 'No exceptions should be returned for a valid request');
		}
	}

	@IsTest
	static void testValidateRequestInvalid() {
		// GIVEN an invalid request
		OESApplicationPayload.PatchRequest invalidRequest = new OESApplicationPayload.PatchRequest();
		// Leave all fields null to trigger validation errors

		// WHEN validating the request
		Test.startTest();
		OESApplicationValidations validator = new OESApplicationValidations();
		RESTlib_Ex.ListException result = validator.validate(invalidRequest);
		Test.stopTest();
		// THEN exceptions should be returned
		Assert.isNotNull(result, 'Exceptions should be returned for an invalid request');
	}

	@IsTest
	static void testValidateContactId() {
		// GIVEN an OESApplicationValidations instance
		OESApplicationValidations validations = new OESApplicationValidations();

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
			validations.validateContactId([SELECT id, CRM_ID__c FROM Contact WHERE id = :con.id].CRM_ID__C);

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
	static void testValidateCampusLocation() {
		// GIVEN an OESApplicationValidations instance
		OESApplicationValidations validations = new OESApplicationValidations();
		RESTlib_Ex.ListException exceptions = new RESTlib_Ex.ListException();

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
			Assert.isTrue(
				String.isNotBlank(validations.exceptions.getListExceptionSummaryString()),
				'An exception should be added for an invalid campus location'
			);
		}
	}

	@IsTest
	static void testValidateResidencyStatus() {
		// GIVEN an OESApplicationValidations instance
		OESApplicationValidations validations = new OESApplicationValidations();
		RESTlib_Ex.ListException exceptions = new RESTlib_Ex.ListException();

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
	static void testValidateEmails() {
		// GIVEN an OESApplicationValidations instance
		OESApplicationValidations validations = new OESApplicationValidations();

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
		// WHEN validating invalid emails
		List<CommonWSPayload.Email> invalidEmails = new List<CommonWSPayload.Email>();
		CommonWSPayload.Email emailInvalid = new CommonWSPayload.Email();
		emailInvalid.email = '';
		emailInvalid.type = 'Personal';
		invalidEmails.add(emailInvalid);
		validations.validateEmails(invalidEmails);

		// THEN an exception should be added
		Assert.isFalse(validations.exceptions.getExceptions().isEmpty(), 'An exception should be added for invalid emails');
		validations.exceptions = new RESTlib_Ex.InvalidRequestException();
		//GIVEN AN invalid email
		List<CommonWSPayload.Email> invalidEmails1 = new List<CommonWSPayload.Email>();
		CommonWSPayload.Email emailInvalid1 = new CommonWSPayload.Email();
		emailInvalid1.email = 'bob@cheese.com';
		emailInvalid1.type = '';
		invalidEmails1.add(emailInvalid1);
		//WHEN Validated
		validations.validateEmails(invalidEmails1);

		// THEN an exception should be added
		Assert.isFalse(
			validations.exceptions.getExceptions().isEmpty(),
			'An exception should be added for invalid email type'
		);
		validations.exceptions = new RESTlib_Ex.InvalidRequestException();

		//GIVEN AN invalid email
		List<CommonWSPayload.Email> invalidEmails2 = new List<CommonWSPayload.Email>();
		CommonWSPayload.Email emailInvalid2 = new CommonWSPayload.Email();
		emailInvalid2.email = 'bob@cheese.com';
		emailInvalid2.type = 'Work';
		invalidEmails2.add(emailInvalid2);
		//WHEN Validated
		validations.validateEmails(invalidEmails2);

		// THEN an exception should be added
		// FIXME: Girish This is failing. Need to fix this.
		Assert.isFalse(
			validations.exceptions.getExceptions().isEmpty(),
			'An exception should be added for invalid email type'
		);
		validations.exceptions = new RESTlib_Ex.InvalidRequestException();
		//GIVEN AN invalid email
		List<CommonWSPayload.Email> invalidEmails3 = new List<CommonWSPayload.Email>();
		CommonWSPayload.Email emailInvalid3 = new CommonWSPayload.Email();
		emailInvalid3.email = 'bob@&&&&SDF.&&';
		emailInvalid3.type = 'Personal';
		invalidEmails3.add(emailInvalid3);
		//WHEN Validated
		validations.validateEmails(invalidEmails3);

		// THEN an exception should be added
		Assert.isFalse(
			validations.exceptions.getExceptions().isEmpty(),
			'An exception should be added for invalid email type'
		);
		validations.exceptions = new RESTlib_Ex.InvalidRequestException();

		//GIVEN a monash email
		List<CommonWSPayload.Email> invalidEmails4 = new List<CommonWSPayload.Email>();
		CommonWSPayload.Email emailInvalid4 = new CommonWSPayload.Email();
		emailInvalid4.email = 'bob@monash.edu';
		emailInvalid4.type = 'Personal';
		invalidEmails.add(emailInvalid4);
		//WHEN Validated
		validations.validateEmails(invalidEmails4);

		// THEN an exception should be added
		Assert.isFalse(
			validations.exceptions.getExceptions().isEmpty(),
			'An exception should be added for invalid email type'
		);
	}

	@IsTest
	static void testValidatePhone() {
		// GIVEN an OESApplicationValidations instance
		OESApplicationValidations validations = new OESApplicationValidations();
		RESTlib_Ex.ListException exceptions = new RESTlib_Ex.ListException();

		// WHEN validating a valid phone
		List<CommonWSPayload.Phone> validPhones = new List<CommonWSPayload.Phone>();
		CommonWSPayload.Phone phone = new CommonWSPayload.Phone();
		phone.phoneNumber = '1234567890';
		phone.type = 'Mobile';
		validPhones.add(phone);
		validations.validatePhone(validPhones);

		// THEN no exception should be added
		Assert.isTrue(String.isBlank(validations.exceptions.message), 'No exceptions should be added for valid phones');

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
	@IsTest
	static void testValidatePhoneNotMobile() {
		// GIVEN an OESApplicationValidations instance
		OESApplicationValidations validations = new OESApplicationValidations();

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
		phoneInvalid.type = 'santabanta';
		invalidPhones.add(phoneInvalid);
		validations.validatePhone(invalidPhones);

		// THEN an exception should be added
		Assert.isTrue(
			String.isNotBlank(validations.exceptions.getListExceptionSummaryString()),
			'An exception should be added for invalid phones'
		);
	}
	@isTest
	static void testValidateInvalidPatchApplications() {
		String errorSummary;
		// Retrieve test data
		User u = [SELECT id FROM user WHERE email = 'testAgentLastName@TestEmail.com'];
		Application__c application = [SELECT Id, Name, Applicant__c FROM Application__c LIMIT 1];
		// Create a PatchRequest object
		OESApplicationPayload.PatchRequest patchRequest = new OESApplicationPayload.PatchRequest();
		patchRequest.application = new OESApplicationPayload.CDM_Application();
		// invalid application
		patchRequest.application.applicationId = 'application.Name';
		patchRequest.application.crmContactId = 'application.Applicant__c';
		patchRequest.application.applicationStatus = 'Submitted';
		Test.startTest();
		System.runAs(u) {
			// Create an instance of OESApplicationValidations
			OESApplicationValidations validations = new OESApplicationValidations(patchRequest);
			try {
				// Call the validatePatchApplications method

				validations.validatePatch(patchRequest);
			} catch (RESTlib_Ex.InvalidRequestException e) {
				for (RESTlib_Ex.ListException ex : e.getExceptions()) {
					Assert.areEqual(
						'Invalid Applicant ID or Applicant doesn’t exist!',
						ex.getMessage(),
						'Should throw an exception when the Application Id or applicant ID is empty'
					);
				}
			}
			Test.stopTest();
		}
	}
	@isTest
	static void testValidatePatchApplications() {
		String errorSummary;
		// Retrieve test data
		User u = [SELECT id FROM user WHERE email = 'testAgentLastName@TestEmail.com'];
		Application__c application = [SELECT Id, Name, Applicant__c, Applicant__r.CRM_ID__c FROM Application__c LIMIT 1];
		// Create a PatchRequest object
		OESApplicationPayload.PatchRequest patchRequest = new OESApplicationPayload.PatchRequest();
		patchRequest.application = new OESApplicationPayload.CDM_Application();
		Test.startTest();
		System.runAs(u) {
			// Create an instance of OESApplicationValidations
			OESApplicationValidations validations = new OESApplicationValidations(patchRequest);
			patchRequest.application.applicationId = application.Name;
			patchRequest.application.crmContactId = application.Applicant__r.CRM_ID__c;
			patchRequest.application.applicationStatus = 'Draft';
			patchRequest.application.visa = new ApplicationWSWrapper.CDM_Visa();
			// patchRequest.application.visa.startDate = '13-06-2019';
			validations = new OESApplicationValidations(patchRequest);
			try {
				validations.validatePatchApplications();
				errorSummary = validations.exceptions.getListExceptionSummaryString();
			} catch (RESTlib_Ex.InvalidRequestException e) {
				errorSummary = validations.exceptions.getListExceptionSummaryString();
			}
		}
		Test.stopTest();
		Assert.isTrue(patchRequest.application.applicationId != null, 'Application Id should not be null');
	}
	@isTest
	static void testValidateCDMACPs() {
		String errorSummary;
		// Retrieve test data
		User u = [SELECT id FROM user WHERE email = 'testAgentLastName@TestEmail.com'];
		Application__c application = [SELECT Id, Name, Applicant__c, Applicant__r.CRM_ID__c FROM Application__c LIMIT 1];
		// Create a PatchRequest object
		OESApplicationPayload.PatchRequest patchRequest = new OESApplicationPayload.PatchRequest();
		patchRequest.application = new OESApplicationPayload.CDM_Application();
		// create a CDM for ACP
		OESApplicationPayload.CDM_ApplicationCoursePreference acpCDM = new OESApplicationPayload.CDM_ApplicationCoursePreference();
		acpCDM.basisForAdmissionType = '311: sHIGHER EDUCATION COURSE (COMPLETE/INCOMPLETE, AUST/OS)';
		acpCDM.documentationStatus = 'Satsisfied';
		acpCDM.outcomeStatus = 'Ofsfer';
		acpCDM.entryQualificationStatus = 'Qsualified';
		acpCDM.offerResponseStatus = 'Pensding';
		acpCDM.offerDate = Date.today().addDays(-5);
		acpCDM.actualOfferResponseDate = Date.today();
		acpCDM.courseOffering = new ApplicationWSWrapper.CDM_CourseOffering();

		patchRequest.application.coursePreferences = new List<OESApplicationPayload.CDM_ApplicationCoursePreference>{
			acpCDM
		};
		Test.startTest();
		System.runAs(u) {
			// Create an instance of OESApplicationValidations
			OESApplicationValidations validations = new OESApplicationValidations(patchRequest);
			patchRequest.application.applicationId = application.Name;
			patchRequest.application.crmContactId = application.Applicant__r.CRM_ID__c;
			patchRequest.application.applicationStatus = 'Draft';
			patchRequest.application.visa = new ApplicationWSWrapper.CDM_Visa();
			patchRequest.application.visa.startDate = '13-06-2019';
			validations = new OESApplicationValidations(patchRequest);
			try {
				validations.validatePatch(patchRequest);
				// validations.validateCdmAcp(patchRequest);
				errorSummary = validations.exceptions.getListExceptionSummaryString();
			} catch (RESTlib_Ex.InvalidRequestException e) {
				errorSummary = validations.exceptions.getListExceptionSummaryString();
			}
			System.debug('errorSummary: ' + errorSummary);
		}
		// Validate ACPs
		Assert.isTrue(
			errorSummary.contains('Invalid Documentation Status: Satsisfied'),
			'Error message should indicate Invalid Documentation Status'
		);
		Assert.isTrue(
			errorSummary.contains('Invalid Outcome Status: Ofsfer'),
			'Error message should indicate Invalid Outcome Status'
		);
		Assert.isTrue(
			errorSummary.contains('Invalid Entry Qualification Status: Qsualified'),
			'Error message should indicate Invalid Entry Qualification Status'
		);
		Assert.isTrue(
			errorSummary.contains('Invalid Offer Response Status: Pensding'),
			'Error message should indicate Invalid Offer Response Status'
		);
		Test.stopTest();
	}
	@isTest
	static void testInvalidStatusTransition() {
		String errorSummary = '';
		TriggerCommon.disableTrigger('Application__c');

		// Retrieve test data
		User u = [SELECT id FROM user WHERE email = 'testAgentLastName@TestEmail.com'];
		Application__c application = [SELECT Id, Name, Applicant__c, Applicant__r.CRM_ID__c FROM Application__c LIMIT 1];
		application.Status__c = 'Draft';
		update application;
		// Create a PatchRequest object
		OESApplicationPayload.PatchRequest patchRequest = new OESApplicationPayload.PatchRequest();
		patchRequest.application = new OESApplicationPayload.CDM_Application();
		// create a CDM for ACP
		Test.startTest();
		System.runAs(u) {
			// Create an instance of OESApplicationValidations
			OESApplicationValidations validations = new OESApplicationValidations(patchRequest);
			patchRequest.application.applicationId = application.Name;
			patchRequest.application.crmContactId = application.Applicant__r.CRM_ID__c;
			// invalid transition status
			patchRequest.application.applicationStatus = 'AgentPortalConstants.DATA_VALIDATION_READY';
			patchRequest.application.visa = new ApplicationWSWrapper.CDM_Visa();
			// patchRequest.application.visa.startDate = '13-06-2019';
			validations = new OESApplicationValidations(patchRequest);
			try {
				validations.validateApplicationStatus();
			} catch (RESTlib_Ex.InvalidRequestException e) {
				errorSummary += validations.exceptions.getListExceptionSummaryString();
			}
			// update application status to Failed Data Validation
			application.Status__c = 'Failed Data validation';
			update application;
			try {
				validations.validateApplicationStatus();
			} catch (RESTlib_Ex.InvalidRequestException e) {
				errorSummary += validations.exceptions.getListExceptionSummaryString();
			} // update application status to Failed Data Validation
			application.Status__c = 'Submitted';
			update application;
			try {
				validations.validateApplicationStatus();
			} catch (RESTlib_Ex.InvalidRequestException e) {
				errorSummary += validations.exceptions.getListExceptionSummaryString();
			}
		}
		Test.stopTest();
	}
	@isTest
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
		qualification.type.qualificationUid = '122';
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
		score2.name = 'readsing';
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
		// qualification.expectedDateOfCompletion = '202-09-09';
		qualifications.add(qualification);
		patchRequest.application.qualifications = qualifications;
		OESApplicationValidations validations = new OESApplicationValidations(patchRequest);
		u = [SELECT id FROM user WHERE email = 'testAgentLastName@TestEmail.com'];
		System.runAs(u) {
			Test.startTest();
			validations.validateQualification();
			Test.stopTest();
		}
		// Add assertions to verify the error messages
		String errorSummary = validations.exceptions.getListExceptionSummaryString();
		Assert.isTrue(
			errorSummary.contains(validations.getAPIResponseErrorMessages('VERIFICATION_STATUS_INVALID', '')),
			'Error message should indicate VERIFICATION_STATUS_INVALID'
		);
		Assert.isTrue(
			errorSummary.contains(validations.getAPIResponseErrorMessages('DATE_OBTAINED_OR_COMPLETION_MANDATORY', '')),
			'Error message should indicate DATE_OBTAINED_OR_COMPLETION_MANDATORY'
		);
		// Assert.isTrue(
		// 	errorSummary.contains(validations.getAPIResponseErrorMessages('START_DATE_EMPTY', '')),
		// 	'Error message should indicate Start date cannot be empty'
		// );
		Assert.isTrue(
			errorSummary.contains(validations.getAPIResponseErrorMessages('RESULT_TYPE_INVALID', '')),
			'Error message should indicate RESULT_TYPE_INVALID'
		);
	}

	@isTest
	static void testValidateVisa() {
		Application__c app;
		User u = [SELECT id FROM user WHERE email = 'testAgentLastName@TestEmail.com'];
		System.runAs(u) {
			app = [SELECT Id, Name, Applicant__c FROM Application__c LIMIT 1];
		}
		// Create a CDM_Application object with visa details
		OESApplicationPayload.CDM_Application application = new OESApplicationPayload.CDM_Application();
		// Create a CDM_Application object with visa details
		application.visa = new ApplicationWSWrapper.CDM_Visa();
		application.visa.startDate = '13-0a6-219';
		application.visa.endDate = '13-0a6-209';
		application.visa.citizenship = new ApplicationWSWrapper.CDM_Country();
		application.visa.citizenship.uniqueCountryExternalId = '';
		application.visa.citizenship.code = 'GG';
		application.visa.citizenship.value = 'Guernsey';
		application.visa.type = new ApplicationWSWrapper.CDM_VisaType();
		application.visa.visaNumber = '';
		application.residencyStatus = 'INT-TEP';

		application.visa.singleEntryVisaCountry = new ApplicationWSWrapper.CDM_Country();
		application.visa.singleEntryVisaCountry.uniqueCountryExternalId = '';
		// Create an instance of OESApplicationValidations
		OESApplicationPayload.PatchRequest applicationPatchRequest = new OESApplicationPayload.PatchRequest();
		applicationPatchRequest.application = application;
		// Create an instance of OESApplicationValidations
		OESApplicationValidations validations = new OESApplicationValidations(applicationPatchRequest);
		// Call the validateVisa method
		// try {
		Test.startTest();
		validations.validateVisa();
		Test.stopTest();
		String errorSummary = validations.exceptions.getListExceptionSummaryString();
		Assert.isTrue(
			errorSummary.contains(validations.getAPIResponseErrorMessages('VISA_START_DATE_INVALID', '')),
			'Error message should indicate invalid Visa start date'
		);
		Assert.isTrue(
			errorSummary.contains(
				validations.getAPIResponseErrorMessages('VISA_APPLICANT_CITIZENSHIP_UNIQUE_EXTID_MISSING', '')
			),
			'Error message should indicate missing visa citizenship unique country external ID'
		);
	}
	@isTest
	static void testValidateVisaEmptyFields() {
		Application__c app;
		User u = [SELECT id FROM user WHERE email = 'testAgentLastName@TestEmail.com'];
		System.runAs(u) {
			app = [SELECT Id, Name, Applicant__c FROM Application__c LIMIT 1];
		}
		// Create a CDM_Application object with visa details
		OESApplicationPayload.CDM_Application application = new OESApplicationPayload.CDM_Application();
		application.residencyStatus = 'INT-TEP';
		// Create a CDM_Application object with visa details
		application.visa = new ApplicationWSWrapper.CDM_Visa();
		// check for empty fields
		application.visa.startDate = '';
		application.visa.endDate = '';
		application.visa.citizenship = new ApplicationWSWrapper.CDM_Country();
		application.visa.citizenship.code = '';
		application.visa.citizenship.value = '';
		application.visa.visaNumber = '';
		application.visa.singleEntryVisaCountry = new ApplicationWSWrapper.CDM_Country();
		application.visa.immigrationOfficeIssued = '';
		application.visa.type = new ApplicationWSWrapper.CDM_VisaType();

		// Create an instance of OESApplicationValidations
		OESApplicationPayload.PatchRequest applicationPatchRequest = new OESApplicationPayload.PatchRequest();
		applicationPatchRequest.application = application;
		// Create an instance of OESApplicationValidations
		OESApplicationValidations validations = new OESApplicationValidations(applicationPatchRequest);
		Test.startTest();
		validations.validateVisa();
		validations.validateApplicant();
		Test.stopTest();
		String errorSummary = validations.exceptions.getListExceptionSummaryString();
		Assert.isTrue(
			errorSummary.contains(validations.getAPIResponseErrorMessages('VISA_CITIZENSHIP_CODE_EMPTY', '')),
			'Error message should indicate missing visa citizenship unique country external ID'
		);
		Assert.isTrue(
			errorSummary.contains(
				validations.getAPIResponseErrorMessages('VISA_APPLICANT_CITIZENSHIP_UNIQUE_EXTID_MISSING', '')
			),
			'Error message should indicate missing visa citizenship unique country external ID'
		);
		// OES Specific validations
		// for INT-TEP residency status
		Assert.isTrue(
			errorSummary.contains(validations.getAPIResponseErrorMessages('VISA_START_DATE_EMPTY', '')),
			'Error message should indicate missing visa start date'
		);
		Assert.isTrue(
			errorSummary.contains(validations.getAPIResponseErrorMessages('VISA_END_DATE_EMPTY', '')),
			'Error message should indicate missing visa end date'
		);
		Assert.isTrue(
			errorSummary.contains(validations.getAPIResponseErrorMessages('VISA_NUMBER_EMPTY', '')),
			'Error message should indicate missing visa number'
		);
		Assert.isTrue(
			errorSummary.contains(validations.getAPIResponseErrorMessages('SINGLE_ENTRY_VISA_COUNTRY_EMPTY', '')),
			'Error message should indicate missing single entry visa country'
		);
		Assert.isTrue(
			errorSummary.contains(validations.getAPIResponseErrorMessages('PASSPORT_NUMBER_EMPTY', '')),
			'Error message should indicate missing PASSPORT_NUMBER_EMPTY when residency status is INT-TEP'
		);
	}

	@isTest
	static void testSecondaryEducationData() {
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

		// Valid Secondary Education Qualification
		ApplicationWSWrapper.CDM_Qualification validQualification = new ApplicationWSWrapper.CDM_Qualification();
		validQualification.type = new ApplicationWSWrapper.CDM_QualificationType();
		validQualification.type.name = 'Secondary Education';
		validQualification.countryObtained = new ApplicationWSWrapper.CDM_Country();
		validQualification.countryObtained.crmRecordId = fflib_IDGenerator.generate(Country_Attribute__c.SObjectType);
		validQualification.countryObtained.value = 'Argentina';
		validQualification.institution = new ApplicationWSWrapper.CDM_Institution();
		validQualification.institution.value = 'Argentina college';
		validQualification.institution.institutionCode = '';
		validQualification.expectedDateOfCompletion = '2024-09-07';
		validQualification.expectedDateOfCompletion = '2024-09-07';
		qualifications.add(validQualification);

		// Invalid Secondary Education Qualification
		ApplicationWSWrapper.CDM_Qualification invalidQualification = new ApplicationWSWrapper.CDM_Qualification();
		invalidQualification.type = new ApplicationWSWrapper.CDM_QualificationType();
		invalidQualification.type.name = 'Secondary Education';
		invalidQualification.countryObtained = new ApplicationWSWrapper.CDM_Country();
		invalidQualification.countryObtained.crmRecordId = '';
		invalidQualification.countryObtained.value = '';
		// invalidQualification.institution = new ApplicationWSWrapper.CDM_Institution();
		// invalidQualification.institution.value = '';
		invalidQualification.expectedDateOfCompletion = '';
		qualifications.add(invalidQualification);

		patchRequest.application.qualifications = qualifications;

		OESApplicationValidations validations = new OESApplicationValidations(patchRequest);

		u = [SELECT id FROM user WHERE email = 'testAgentLastName@TestEmail.com'];
		System.runAs(u) {
			Test.startTest();
			validations.validateQualification();
			Test.stopTest();
		}
		// Add assertions to verify the error messages
		String errorSummary = validations.exceptions.getListExceptionSummaryString();
		Assert.isTrue(
			errorSummary.contains(validations.getAPIResponseErrorMessages('QUALIFICATION_UID_EMPTY', '')),
			'Error message should indicate Secondary Education Qualification UID cannot be empty.'
		);
		Assert.isTrue(
			errorSummary.contains('English language of instruction is empty'),
			'Error message should indicate English language of instruction is empty'
		);

		Assert.isTrue(errorSummary.contains('Secondary Education'), 'Error message should indicate Secondary Education');
	}
	@isTest
	static void testTertiearyEducationData() {
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

		// Invalid Tertiary Education Qualification
		ApplicationWSWrapper.CDM_Qualification invalidQualification = new ApplicationWSWrapper.CDM_Qualification();
		invalidQualification.type = new ApplicationWSWrapper.CDM_QualificationType();
		invalidQualification.type.name = 'Tertiary Education';
		invalidQualification.countryObtained = new ApplicationWSWrapper.CDM_Country();
		invalidQualification.countryObtained.crmRecordId = '';
		invalidQualification.countryObtained.value = '';
		invalidQualification.expectedDateOfCompletion = '122/321';
		qualifications.add(invalidQualification);

		// invalid other Education Qualification
		ApplicationWSWrapper.CDM_Qualification invalidQualification2 = new ApplicationWSWrapper.CDM_Qualification();
		invalidQualification2.type = new ApplicationWSWrapper.CDM_QualificationType();
		invalidQualification2.type.name = 'Other Education';
		invalidQualification2.countryObtained = new ApplicationWSWrapper.CDM_Country();
		invalidQualification2.countryObtained.crmRecordId = '';
		invalidQualification2.countryObtained.value = '';
		invalidQualification2.expectedDateOfCompletion = '122/321';
		qualifications.add(invalidQualification2);
		patchRequest.application.qualifications = qualifications;

		OESApplicationValidations validations = new OESApplicationValidations(patchRequest);
		u = [SELECT id FROM user WHERE email = 'testAgentLastName@TestEmail.com'];
		System.runAs(u) {
			Test.startTest();
			validations.validateQualification();
			Test.stopTest();
		}

		// Add assertions to verify the error messages
		String errorSummary = validations.exceptions.getListExceptionSummaryString();
		Assert.isTrue(
			errorSummary.contains(ApplicationWSValidations.API_VALIDATION_RESPONSE_MESSAGES.get('INSTITUTION_EMPTY')),
			'Error message should indicate missing Institution'
		);
		Assert.isTrue(
			errorSummary.contains(ApplicationWSValidations.API_VALIDATION_RESPONSE_MESSAGES.get('LEVEL_OF_COMPLETION_EMPTY')),
			'Error message should indicate missing LEVEL_OF_COMPLETION_EMPTY external ID'
		);
	}

	// add workExperience validations
	@isTest
	static void testValidateWorkExperience() {
		OESApplicationPayload.PatchRequest patchRequest = new OESApplicationPayload.PatchRequest();
		patchRequest.application = new OESApplicationPayload.CDM_Application();

		// Create a list of work experiences
		List<ApplicationWSWrapper.CDM_WorkExperience> workExperiences = new List<ApplicationWSWrapper.CDM_WorkExperience>();

		// Valid Work Experience
		ApplicationWSWrapper.CDM_WorkExperience validWorkExperience = new ApplicationWSWrapper.CDM_WorkExperience();
		validWorkExperience.position = 'test';
		validWorkExperience.employer = 'employer';
		validWorkExperience.startDate = '2020-05-05';
		validWorkExperience.countryObtained = new ApplicationWSWrapper.CDM_Country();
		validWorkExperience.countryObtained.crmRecordId = 'crmRecordId';
		validWorkExperience.countryObtained.code = 'IO';
		validWorkExperience.countryObtained.uniqueCountryExternalId = 'null-IOT-86-2';
		validWorkExperience.countryObtained.value = 'British Indian Ocean Territory (the)';
		validWorkExperience.contactPerson = new ApplicationWSWrapper.CDM_Referee();
		validWorkExperience.contactPerson.firstName = 'test';
		validWorkExperience.contactPerson.lastName = 'teset';
		validWorkExperience.contactAddress = 'testsdf@test.com';
		validWorkExperience.contactPhone = '0412341234';
		workExperiences.add(validWorkExperience);

		// Invalid Work Experience
		ApplicationWSWrapper.CDM_WorkExperience invalidWorkExperience = new ApplicationWSWrapper.CDM_WorkExperience();
		invalidWorkExperience.position = '';
		invalidWorkExperience.employer = '';
		invalidWorkExperience.startDate = '';
		invalidWorkExperience.countryObtained = new ApplicationWSWrapper.CDM_Country();
		workExperiences.add(invalidWorkExperience);

		patchRequest.application.workExperiences = workExperiences;
		OESApplicationValidations validations = new OESApplicationValidations(patchRequest);

		User u = [SELECT id FROM user WHERE email = 'testAgentLastName@TestEmail.com'];
		System.runAs(u) {
			Test.startTest();
			validations.validateWorkExperience();
			Test.stopTest();
		}
		// Add assertions to verify the error messages
		String errorSummary = validations.exceptions.getListExceptionSummaryString();
		Assert.isTrue(
			errorSummary.contains(ApplicationWSValidations.API_VALIDATION_RESPONSE_MESSAGES.get('POSITION_EMPTY')),
			'Error message should indicate missing position'
		);
		Assert.isTrue(
			errorSummary.contains(ApplicationWSValidations.API_VALIDATION_RESPONSE_MESSAGES.get('EMPLOYER_EMPTY')),
			'Error message should indicate missing employer'
		);
		Assert.isTrue(
			errorSummary.contains(ApplicationWSValidations.API_VALIDATION_RESPONSE_MESSAGES.get('START_DATE_EMPTY')),
			'Error message should indicate missing start date'
		);
		Assert.isTrue(
			errorSummary.contains(validations.getAPIResponseErrorMessages('COUNTRY_EXTERNAL_ID_EMPTY', '')),
			'Error message should indicate missing country obtained'
		);
	}

	@isTest
	static void testValidateBasisForAdmissionType() {
		// Create an instance of OESApplicationValidations
		OESApplicationValidations validations = new OESApplicationValidations();
		// Call the validateBasisForAdmissionType method with a valid type
		validations.validateBasisForAdmissionType('311: HIGHER EDUCATION COURSE (COMPLETE/INCOMPLETE, AUST/OS)');
		// Call the validateBasisForAdmissionType method with an invalid type
		try {
			validations.validateBasisForAdmissionType('Invalid Type');
		} catch (RestLib_Ex.InvalidRequestException e) {
			// THEN an exception should be thrown
			Assert.isTrue(
				e.getMessage().contains('Invalid Basis for Admission Type: Invalid Type'),
				'Invalid Basis for Admission Type'
			);
		}
		try {
			validations.validateOfferAndResponseDate(Date.valueOf('2020-05-05'), Date.valueOf('2019-05-05'));
		} catch (RestLib_Ex.InvalidRequestException e) {
			// THEN an exception should be thrown
			Assert.isTrue(
				e.getMessage().contains('Actual Offer Response Date must be greater '),
				'Actual Offer Response Date must be greater'
			);
		}
		try {
			validations.validateEntryQualificationStatus('Invalid QualificationStatus');
		} catch (RestLib_Ex.InvalidRequestException e) {
			// THEN an exception should be thrown
			Assert.isTrue(
				e.getMessage().contains('Invalid Entry Qualification Status'),
				'Invalid Entry Qualification Status'
			);
		}
	}
}