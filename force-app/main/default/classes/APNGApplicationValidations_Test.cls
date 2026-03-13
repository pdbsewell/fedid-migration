/**
 * @description       : Test class for APNGApplicationValidations class
 * @author            : Ben Greenland
 * @group             : Admissions
 * @last modified on  : 2024-10-26
 * @last modified by  : Ben Greenland
 **/
@isTest(isParallel=true)
private class APNGApplicationValidations_Test {
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
			APNGApplicationPayload.PostRequest validRequest = new APNGApplicationPayload.PostRequest();
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
			APNGApplicationValidations validations = new APNGApplicationValidations();
			RESTlib_Ex.ListException result = validations.validate(validRequest);

			Test.stopTest();

			// THEN no exceptions should be returned
			Assert.isNull(result, 'No exceptions should be returned for a valid request');
		}
	}
	@IsTest
	static void testValidateRequestInvalid() {
		// GIVEN an invalid request
		APNGApplicationPayload.PostRequest invalidRequest = new APNGApplicationPayload.PostRequest();
		// Leave all fields null to trigger validation errors

		// WHEN validating the request
		Test.startTest();
		APNGApplicationValidations validations = new APNGApplicationValidations();
		User u = new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser();
		RESTlib_Ex.ListException result;
		// Create a test Applicant record
		System.runAs(u) {
			result = validations.validate(invalidRequest);
		}

		Test.stopTest();

		// THEN exceptions should be returned
		Assert.isNotNull(result, 'Exceptions should be returned for an invalid request');
		Assert.isTrue(result.getExceptions().size() > 0, 'Multiple exceptions should be returned');
	}

	@IsTest
	static void testValidateContactId() {
		// GIVEN an APNGApplicationValidations instance
		APNGApplicationValidations validations = new APNGApplicationValidations();

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
	static void testValidateCampusLocation() {
		// GIVEN an APNGApplicationValidations instance
		APNGApplicationValidations validations = new APNGApplicationValidations();

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
	static void testValidateResidencyStatus() {
		// GIVEN an APNGApplicationValidations instance
		APNGApplicationValidations validations = new APNGApplicationValidations();

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
		// GIVEN an APNGApplicationValidations instance
		APNGApplicationValidations validations = new APNGApplicationValidations();

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
		APNGApplicationValidations validations = new APNGApplicationValidations();

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
	@isTest
	static void testValidateInvalidPatchApplications() {
		// Retrieve test data
		User u = [SELECT id FROM user WHERE email = 'testAgentLastName@TestEmail.com'];
		System.runAs(u) {
			Application__c application = [SELECT Id, Name, Applicant__c FROM Application__c LIMIT 1];
			// Create a PatchRequest object
			APNGApplicationPayload.PatchRequest patchRequest = new APNGApplicationPayload.PatchRequest();
			patchRequest.application = new APNGApplicationPayload.CDM_Application();
			// invalid application
			patchRequest.application.applicationId = 'application.Name';
			patchRequest.application.crmContactId = 'application.Applicant__c';
			patchRequest.application.applicationStatus = 'Submitted';

			// Create an instance of APNGApplicationValidations
			APNGApplicationValidations validations = new APNGApplicationValidations();

			// Create an exception object
			Test.startTest();
			// Call the validatePatchApplications method

			try {
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
		// Retrieve test data
		User u = [SELECT id FROM user WHERE email = 'testAgentLastName@TestEmail.com'];
		System.runAs(u) {
			Application__c application = [SELECT Id, Name, Applicant__c FROM Application__c LIMIT 1];
			// Create a PatchRequest object
			APNGApplicationPayload.PatchRequest patchRequest = new APNGApplicationPayload.PatchRequest();
			patchRequest.application = new APNGApplicationPayload.CDM_Application();
			patchRequest.application.applicationId = application.Name;
			patchRequest.application.crmContactId = application.Applicant__c;
			patchRequest.application.applicationStatus = 'Draft';
			// English Test Qualification
			ApplicationWSWrapper.CDM_Qualification qualification = new ApplicationWSWrapper.CDM_Qualification();
			qualification.type = new ApplicationWSWrapper.CDM_QualificationType();
			qualification.type.name = 'Tertiary Education';
			// Name and CRM Record ID are required, should throw error
			qualification.type.code = '';
			qualification.scores = new List<ApplicationWSWrapper.CDM_QualificationScore>();
			// Secondary Education Qualification
			ApplicationWSWrapper.CDM_Qualification qualification2 = new ApplicationWSWrapper.CDM_Qualification();
			qualification2.type = new ApplicationWSWrapper.CDM_QualificationType();
			qualification2.type.name = 'Secondary Education';
			// Name and CRM Record ID are required, should throw error
			qualification2.type.code = '';
			qualification2.countryObtained = new ApplicationWSWrapper.CDM_Country();
			qualification2.countryObtained.crmRecordId = '';
			qualification2.countryObtained.code = 'AU';
			qualification2.countryObtained.value = 'Australia';

			patchRequest.application.qualifications = new List<ApplicationWSWrapper.CDM_Qualification>{
				qualification,
				qualification2
			};
			// Valid Work Experience
			ApplicationWSWrapper.CDM_WorkExperience validWorkExperience = new ApplicationWSWrapper.CDM_WorkExperience();
			validWorkExperience.position = 'test';
			validWorkExperience.employer = 'employer';
			validWorkExperience.startDate = '2020-05-05';
			validWorkExperience.countryObtained = new ApplicationWSWrapper.CDM_Country();
			validWorkExperience.countryObtained.crmRecordId = 'crmRecordId';
			validWorkExperience.countryObtained.code = 'IO';
			patchRequest.application.workExperiences = new List<ApplicationWSWrapper.CDM_WorkExperience>{
				validWorkExperience
			};
			// Add scores
			Test.startTest();
			String errorSummary = '';
			APNGApplicationValidations validations = new APNGApplicationValidations();

			validations = new APNGApplicationValidations(patchRequest);
			try {
				validations.validatePatchApplications();
				errorSummary = validations.exceptions.getListExceptionSummaryString();
			} catch (Exception e) {
				errorSummary = e.getMessage();
			}
			Test.stopTest();
			System.debug('errorSummary Ter: ' + errorSummary);
			// for tertiary education
			Assert.isTrue(
				errorSummary.contains(validations.getAPIResponseMessages('QUALIFICATION_COUNTRY_EMPTY', '')),
				'Error message should indicate QUALIFICATION_COUNTRY_EMPTY'
			);
			Assert.isTrue(
				errorSummary.contains(validations.getAPIResponseMessages('QUALIFICATION_NAME_EMPTY', '')),
				'Error message should indicate QUALIFICATION_NAME_EMPTY'
			);
			// for secondary education
			Assert.isTrue(
				errorSummary.contains(validations.getAPIResponseMessages('STATE_EMPTY', '')),
				'Error message should indicate STATE_EMPTY'
			);
		}
	}
	@isTest
	static void testValidatePatchApplicationsException() {
		// Retrieve test data
		User u = [SELECT id FROM user WHERE email = 'testAgentLastName@TestEmail.com'];
		System.runAs(u) {
			Application__c application = [SELECT Id, Name, Applicant__c FROM Application__c LIMIT 1];
			// Create a PatchRequest object
			APNGApplicationPayload.PatchRequest patchRequest = new APNGApplicationPayload.PatchRequest();
			patchRequest.application = new APNGApplicationPayload.CDM_Application();
			patchRequest.application.applicationId = application.Name;
			patchRequest.application.crmContactId = application.Applicant__c;
			patchRequest.application.applicationStatus = 'Draft';
			ApplicationWSWrapper.CDM_Visa visa = new ApplicationWSWrapper.CDM_Visa();
			visa.endDate = 'Student';
			patchRequest.application.visa = visa;
			// English Test Qualification
			ApplicationWSWrapper.CDM_Qualification qualification = new ApplicationWSWrapper.CDM_Qualification();
			qualification.type = new ApplicationWSWrapper.CDM_QualificationType();
			qualification.type.crmRecordId = fflib_IDGenerator.generate(Contact_Qualification__c.getSObjectType());
			qualification.type.name = 'English Test';
			qualification.type.code = '';
			qualification.type.qualificationName = 'Cambridge Linguaskill';
			qualification.type.qualificationUid = '122';
			qualification.scores = new List<ApplicationWSWrapper.CDM_QualificationScore>();
			patchRequest.application.qualifications = new List<ApplicationWSWrapper.CDM_Qualification>{ qualification };
			// Valid Work Experience
			ApplicationWSWrapper.CDM_WorkExperience validWorkExperience = new ApplicationWSWrapper.CDM_WorkExperience();
			validWorkExperience.position = 'test';
			validWorkExperience.employer = 'employer';
			validWorkExperience.startDate = '2020-05-05';
			validWorkExperience.countryObtained = new ApplicationWSWrapper.CDM_Country();
			validWorkExperience.countryObtained.crmRecordId = 'crmRecordId';
			validWorkExperience.countryObtained.code = 'IO';
			validWorkExperience.countryObtained.uniqueCountryExternalId = 'null-IOT-86';
			patchRequest.application.workExperiences = new List<ApplicationWSWrapper.CDM_WorkExperience>{
				validWorkExperience
			};
			// Add scores
			// Create an exception object
			Test.startTest();
			APNGApplicationValidations validations = new APNGApplicationValidations(patchRequest);
			String errorSummary = '';

			// Call the validatePatchApplications method
			try {
				validations.validatePatchApplications();
				errorSummary = validations.exceptions.getListExceptionSummaryString();
			} catch (Exception e) {
				Assert.isTrue(e.getMessage() != null, 'Should throw an exception when the request is invalid');
				errorSummary += e.getMessage();
			}
			// Assert.isTrue(
			// 	errorSummary.contains(validations.getAPIResponseMessages('SCORE_EMPTY', '')),
			// 	'Error message should indicate Score is empty'
			// );
			Assert.isTrue(
				errorSummary.contains(validations.getAPIResponseMessages('DATE_OBTAINED_OR_COMPLETION_MANDATORY', '')),
				'Error message should indicate Either Date obtained/Expected completion date to be filled'
			);
			Test.stopTest();
		}
	}
}