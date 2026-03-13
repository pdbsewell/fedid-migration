/**
 * @description       : test APNGApplicantValidations
 * @author            : Ben Greenland
 * @group             : admissions
 * @last modified on  : 2024-12-13
 * @last modified by  : Ben Greenland
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2024-09-16   Ben Greenland   Initial Version
 **/
@isTest(isParallel=true)
private class APNGApplicantValidations_Test {
	@TestSetup
	static void makeData() {
		// Create test data
		AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();

		// Create an applicant
		Contact applicant = new AgentPortalTestDataFactory().createApplicantContact();
		insert applicant;

		// Create an application in submitted status
		Application__c submittedApp = new AgentPortalTestDataFactory().createApplication(applicant.Id);
		submittedApp.Status__c = 'Submitted';
		submittedApp.Agent__c = portalUser.acc.Id;
		insert submittedApp;
	}

	@isTest
	private static void testValidPayload() {
		//GIVEN a valid  APNGApplicantPayload.PostRequest
		APNGApplicantPayload.PostRequest request = new APNGApplicantPayload.PostRequest();
		APNGApplicantPayload.Applicant app = new APNGApplicantPayload.Applicant();
		app.lastName = 'Application Lastname';
		CommonWSPayload.Email email = new CommonWSPayload.Email();
		email.email = 'test@test.com';
		email.type = 'home';
		app.email = new List<CommonWSPayload.Email>{ email };
		CommonWSPayload.Phone phone = new CommonWSPayload.Phone();
		phone.phoneNumber = '023423455';
		phone.type = 'home';
		app.phone = new List<CommonWSPayload.Phone>{ phone };
		app.dateOfBirth = '1996-10-09';
		request.applicant = app;
		//WHEN it is validated
		Test.startTest();
		RESTlib_Ex.InvalidRequestException errorList = APNGApplicantValidations.validate(request);
		Test.stopTest();
		//THEN there should be now errors
		Assert.areEqual(null, errorList.getExceptions(), 'Payload should be valid');
	}
	@istest
	private static void testInvalidPayload() {
		//GIVEN an Empty PostRequest
		APNGApplicantPayload.PostRequest request = new APNGApplicantPayload.PostRequest();
		APNGApplicantPayload.Applicant app = new APNGApplicantPayload.Applicant();
		app.lastName = '';
		CommonWSPayload.Email email = new CommonWSPayload.Email();
		email.email = '';
		email.type = 'home';
		app.email = new List<CommonWSPayload.Email>{ email };
		CommonWSPayload.Phone phone = new CommonWSPayload.Phone();
		phone.phoneNumber = '';
		phone.type = 'home';
		app.phone = new List<CommonWSPayload.Phone>{ phone };
		app.dateOfBirth = '';
		request.applicant = app;
		//WHEN it is validated
		Test.startTest();
		RESTlib_Ex.InvalidRequestException errorList = APNGApplicantValidations.validate(request);
		Test.stopTest();
		//THEN there should be errors
		Assert.areEqual(3, errorList.getExceptions().size(), 'Payload should have 3 errors ');
	}

	@istest
	private static void testInvalidDate() {
		//GIVEN a  APNGApplicantPayload.PostRequest with invalid date
		APNGApplicantPayload.PostRequest request = new APNGApplicantPayload.PostRequest();
		APNGApplicantPayload.Applicant app = new APNGApplicantPayload.Applicant();
		app.lastName = 'Application Lastname';
		CommonWSPayload.Email email = new CommonWSPayload.Email();
		email.email = 'test@test.com';
		email.type = 'home';
		app.email = new List<CommonWSPayload.Email>{ email };
		CommonWSPayload.Phone phone = new CommonWSPayload.Phone();
		phone.phoneNumber = '023423455';
		phone.type = 'home';
		app.phone = new List<CommonWSPayload.Phone>{ phone };
		app.dateOfBirth = '1xxx';
		request.applicant = app;
		//WHEN it is validated
		Test.startTest();
		RESTlib_Ex.InvalidRequestException errorList = APNGApplicantValidations.validate(request);
		Test.stopTest();
		//THEN there should be 1 error
		Assert.areEqual(1, errorList.getExceptions().size(), 'Payload should have 1 errors ');
		Assert.isTrue(
			String.valueOf(errorList.getExceptions()).contains('Only yyyy-MM-dd format is accepted'),
			'error should be "Applicant\'s Date of Birth is of invalid format. Only yyyy-MM-dd format is accepted"'
		);
	}

	@istest
	private static void test10YearOld() {
		//GIVEN a  APNGApplicantPayload.PostRequest with birthdate < 10 years old
		APNGApplicantPayload.PostRequest request = new APNGApplicantPayload.PostRequest();
		APNGApplicantPayload.Applicant app = new APNGApplicantPayload.Applicant();
		app.lastName = 'Application Lastname';
		CommonWSPayload.Email email = new CommonWSPayload.Email();
		email.email = 'test@test.com';
		email.type = 'home';
		app.email = new List<CommonWSPayload.Email>{ email };
		CommonWSPayload.Phone phone = new CommonWSPayload.Phone();
		phone.phoneNumber = '023423455';
		phone.type = 'home';
		app.phone = new List<CommonWSPayload.Phone>{ phone };
		String year = String.valueOf(Date.today().year() - 2);
		app.dateOfBirth = year + '-10-09';
		request.applicant = app;
		//WHEN it is validated
		Test.startTest();
		RESTlib_Ex.InvalidRequestException errorList = APNGApplicantValidations.validate(request);
		Test.stopTest();
		//THEN there should be 1 error and the error message should be "Applicant should be minimum 10 yrs old"
		Assert.areEqual(
			1,
			errorList.getExceptions().size(),
			'Payload should have 1 errors ' + JSON.serializePretty(errorList.getExceptions().size())
		);
		Assert.isTrue(
			String.valueOf(errorList.getExceptions()).contains('10 yrs old'),
			'error should be "Applicant should be minimum 10 yrs old"'
		);
	}

	@isTest
	static void testValidateNullContactId() {
		// Arrange
		APNGApplicantPayload.PatchRequest req = new APNGApplicantPayload.PatchRequest();
		req.contactId = null;

		// Act
		RESTlib_Ex.InvalidRequestException result = APNGApplicantValidations.validatePatchRequest(req);

		// Assert
		Assert.isTrue(result.getExceptions().size() > 0, 'Should have exceptions');
		Assert.areEqual(
			'Request without a valid Id',
			result.getExceptions()[0].getMessage(),
			'Should have correct error message'
		);
	}

	@isTest
	static void testValidateSubmittedApplicationWithUpdates() {
		Contact applicant = [SELECT Id FROM Contact WHERE Phone = '11112222' LIMIT 1];

		// Create a patch request
		APNGApplicantPayload.PatchRequest req = new APNGApplicantPayload.PatchRequest();
		req.contactId = applicant.Id;
		req.lastName = 'NewLastName';

		// Create a mock AgentPortalServices

		// Act
		RESTlib_Ex.InvalidRequestException result = APNGApplicantValidations.validatePatchRequest(req);

		// Assert
		Assert.isTrue(result.getExceptions().size() > 0, 'Should have exceptions');
		Assert.areEqual(
			'Applicant has submitted Applications. Request contains fields which cannot be updated',
			result.getExceptions()[0].getMessage(),
			'Should have correct error message'
		);
	}

	@isTest
	static void testValidateEmptyLastName() {
		// Arrange
		APNGApplicantPayload.PatchRequest req = new APNGApplicantPayload.PatchRequest();
		req.contactId = fflib_IDGenerator.generate(Schema.Contact.SObjectType); // Dummy ID
		req.lastName = '';

		// Act
		RESTlib_Ex.InvalidRequestException result = APNGApplicantValidations.validatePatchRequest(req);

		// Assert
		Assert.isTrue(result.getExceptions().size() > 0, 'Should have exceptions');
		Assert.areEqual(
			'Applicant\'s Last Name cannot be empty',
			result.getExceptions()[0].getMessage(),
			'Should have correct error message'
		);
	}

	@isTest
	static void testValidateEmptyEmail() {
		// Arrange
		APNGApplicantPayload.PatchRequest req = new APNGApplicantPayload.PatchRequest();
		req.contactId = fflib_IDGenerator.generate(Schema.Contact.SObjectType); // Dummy ID
		req.Email = new List<CommonWSPayload.Email>();
		CommonWSPayload.Email personalEmail = new CommonWSPayload.Email();
		personalEmail.type = 'Personal';
		personalEmail.email = '';
		req.Email.add(personalEmail);

		// Act
		RESTlib_Ex.InvalidRequestException result = APNGApplicantValidations.validatePatchRequest(req);

		// Assert
		Assert.isTrue(result.getExceptions().size() > 0, 'Should have exceptions');
		Assert.areEqual(
			'Applicant\'s email cannot be empty',
			result.getExceptions()[0].getMessage(),
			'Should have correct error message'
		);
	}

	@isTest
	static void testValidateInvalidGender() {
		// Arrange
		APNGApplicantPayload.PatchRequest req = new APNGApplicantPayload.PatchRequest();
		req.contactId = fflib_IDGenerator.generate(Schema.Contact.SObjectType); // Dummy ID
		req.gender = 'P'; // Assuming 'P' is in AgentPortalConstants.CON_UNUSED_GENDERS

		// Act
		RESTlib_Ex.InvalidRequestException result = APNGApplicantValidations.validatePatchRequest(req);

		// Assert
		Assert.isTrue(result.getExceptions().size() > 0, 'Should have exceptions');
		Assert.areEqual(
			'Applicant\'s Gender cannot be P or U',
			result.getExceptions()[0].getMessage(),
			'Should have correct error message'
		);
	}

	@isTest
	static void testValidateUnderage() {
		// Arrange
		APNGApplicantPayload.PatchRequest req = new APNGApplicantPayload.PatchRequest();
		req.contactId = fflib_IDGenerator.generate(Schema.Contact.SObjectType); // Dummy ID
		req.dateOfBirth = String.valueOf(Date.today().addYears(-9)); // 9 years old
		req.gender = 'M';
		// Add required email
		CommonWSPayload.Email email = new CommonWSPayload.Email();
		email.email = 'test@example.com';
		email.type = 'Personal';
		req.email = new List<CommonWSPayload.Email>{ email };

		// Act
		Test.startTest();
		RESTlib_Ex.InvalidRequestException result = APNGApplicantValidations.validatePatchRequest(req);
		Test.stopTest();

		// Assert
		Assert.isTrue(result.getExceptions().size() > 0, 'Should have exceptions');
		Assert.areEqual(
			'Applicant should be minimum 10 yrs old',
			result.getExceptions()[0].getMessage(),
			'Should have correct error message'
		);
	}

	@isTest
	static void testValidateValidRequest() {
		// Arrange
		APNGApplicantPayload.PatchRequest req = new APNGApplicantPayload.PatchRequest();
		req.contactId = fflib_IDGenerator.generate(Schema.Contact.SObjectType); // Dummy ID
		req.lastName = 'ValidLastName';
		req.Email = new List<CommonWSPayload.Email>();
		CommonWSPayload.Email personalEmail = new CommonWSPayload.Email();
		personalEmail.type = 'Personal';
		personalEmail.email = 'valid@email.com';
		req.Email.add(personalEmail);
		req.gender = 'M'; // Assuming 'M' is not in AgentPortalConstants.CON_UNUSED_GENDERS
		req.dateOfBirth = String.valueOf(Date.today().addYears(-20)); // 20 years old

		// Act
		RESTlib_Ex.InvalidRequestException result = APNGApplicantValidations.validatePatchRequest(req);

		// Assert
		Assert.isFalse(result == null, 'Should not have exceptions');
	}

	@isTest
	static void testIsNonPronounFieldUpdated() {
		// Test case 1: Only pronoun field updated
		// GIVEN a patch request with only the pronoun field updated
		APNGApplicantPayload.PatchRequest req1 = new APNGApplicantPayload.PatchRequest();
		req1.pronoun = 'They/Them';

		// WHEN isNonPronounFieldUpdated is called
		// THEN it should return false
		APNGApplicantValidations vals = new APNGApplicantValidations();
		Assert.isFalse(vals.isNonPronounFieldUpdated(req1), 'Should return false when only pronoun is updated');

		// Test case 2: Non-pronoun field updated
		// GIVEN a patch request with a non-pronoun field (lastName) updated
		APNGApplicantPayload.PatchRequest req2 = new APNGApplicantPayload.PatchRequest();
		req2.lastName = 'NewLastName';

		// WHEN isNonPronounFieldUpdated is called
		// THEN it should return true
		Assert.isTrue(vals.isNonPronounFieldUpdated(req2), 'Should return true when lastName is updated');

		// Test case 3: Multiple fields updated including pronoun
		// GIVEN a patch request with multiple fields updated, including both pronoun and non-pronoun fields
		APNGApplicantPayload.PatchRequest req3 = new APNGApplicantPayload.PatchRequest();
		req3.pronoun = 'She/Her';
		req3.firstName = 'NewFirstName';
		req3.dateOfBirth = String.valueOf(Date.today().addYears(-20));

		// WHEN isNonPronounFieldUpdated is called
		// THEN it should return true
		Assert.isTrue(
			vals.isNonPronounFieldUpdated(req3),
			'Should return true when multiple fields including non-pronoun are updated'
		);

		// Test case 4: Email updated
		// GIVEN a patch request with the email field updated
		APNGApplicantPayload.PatchRequest req4 = new APNGApplicantPayload.PatchRequest();
		req4.Email = new List<CommonWSPayload.Email>();
		CommonWSPayload.Email personalEmail = new CommonWSPayload.Email();
		personalEmail.type = 'Personal';
		personalEmail.email = 'new@email.com';
		req4.Email.add(personalEmail);

		// WHEN isNonPronounFieldUpdated is called
		// THEN it should return true
		Assert.isTrue(vals.isNonPronounFieldUpdated(req4), 'Should return true when email is updated');

		// Test case 5: Phone updated
		// GIVEN a patch request with the phone field updated
		APNGApplicantPayload.PatchRequest req5 = new APNGApplicantPayload.PatchRequest();
		CommonWSPayload.Phone phone = new CommonWSPayload.Phone();
		phone.type = 'Mobile';
		phone.phoneNumber = '1234567890';
		req5.phone = new List<CommonWSPayload.Phone>{ phone };

		// WHEN isNonPronounFieldUpdated is called
		// THEN it should return true
		Assert.isTrue(vals.isNonPronounFieldUpdated(req5), 'Should return true when phone is updated');

		// Test case 6: No fields updated
		// GIVEN a patch request with no fields updated
		APNGApplicantPayload.PatchRequest req6 = new APNGApplicantPayload.PatchRequest();

		// WHEN isNonPronounFieldUpdated is called
		// THEN it should return false
		Assert.isFalse(vals.isNonPronounFieldUpdated(req6), 'Should return false when no fields are updated');
	}
	@isTest
	static void validateGender_shouldFail_whenEmpty() {
		// GIVEN a patch request with an empty gender
		APNGApplicantPayload.PatchRequest req = new APNGApplicantPayload.PatchRequest();
		req.contactId = fflib_IDGenerator.generate(Schema.Contact.SObjectType); // Dummy ID
		req.gender = '';

		// WHEN it is validated
		RESTlib_Ex.InvalidRequestException result = APNGApplicantValidations.validatePatchRequest(req);

		// THEN there should be an error for empty gender
		Assert.isTrue(result.getExceptions().size() > 0, 'Should have exceptions');
		Assert.isTrue(
			result.getExceptions()[0].getMessage().contains('Gender cannot be empty'),
			'Should indicate that gender cannot be empty'
		);
	}

	@isTest
	static void validateGender_shouldFail_whenNull() {
		// GIVEN a patch request with a null gender
		APNGApplicantPayload.PatchRequest req = new APNGApplicantPayload.PatchRequest();
		req.contactId = fflib_IDGenerator.generate(Schema.Contact.SObjectType); // Dummy ID
		req.gender = null;

		// WHEN it is validated
		RESTlib_Ex.InvalidRequestException result = APNGApplicantValidations.validatePatchRequest(req);

		// THEN there should be an error for null gender
		Assert.isTrue(result.getExceptions().size() > 0, 'Should have exceptions');
		Assert.isTrue(
			result.getExceptions()[0].getMessage().contains('Gender cannot be empty'),
			'Should indicate that gender cannot be empty'
		);
	}

	@isTest
	static void validateGender_shouldPass_whenValid() {
		// GIVEN a patch request with a valid gender
		APNGApplicantPayload.PatchRequest req = new APNGApplicantPayload.PatchRequest();
		req.contactId = fflib_IDGenerator.generate(Schema.Contact.SObjectType); // Dummy ID
		req.gender = 'M'; // Assuming 'M' is a valid gender code

		// WHEN it is validated
		Test.startTest();
		RESTlib_Ex.InvalidRequestException result = APNGApplicantValidations.validatePatchRequest(req);
		Test.stopTest();

		// THEN there should be no gender-related errors

		Assert.isTrue(!String.valueOf(result.getMessage()).contains('Gender'), 'Should not have gender-related errors');
	}

	@isTest
	static void validateGender_shouldFail_whenUnusedGender() {
		// GIVEN a patch request with an unused gender code
		APNGApplicantPayload.PatchRequest req = new APNGApplicantPayload.PatchRequest();
		req.contactId = fflib_IDGenerator.generate(Schema.Contact.SObjectType); // Dummy ID
		req.gender = 'P'; // P is in CON_UNUSED_GENDERS

		// WHEN it is validated
		Test.startTest();
		RESTlib_Ex.InvalidRequestException result = APNGApplicantValidations.validatePatchRequest(req);
		Test.stopTest();

		// THEN there should be an error for unused gender
		Assert.isTrue(result.getExceptions().size() > 0, 'Should have exceptions');
		Assert.isTrue(
			result.getExceptions()[0].getMessage().contains('Gender cannot be P or U'),
			'Should indicate that gender P or U is not allowed'
		);
	}
	@isTest
	private static void validateSubmittedApplications_shouldPass_whenOnlyPronounUpdated() {
		// GIVEN an applicant with a submitted application
		Contact applicant = [SELECT Id FROM Contact WHERE Phone = '11112222' LIMIT 1];
		Application__c submittedApp = [SELECT Id FROM Application__c WHERE Status__c = 'Submitted' LIMIT 1];

		// Create a patch request with only pronoun update
		APNGApplicantPayload.PatchRequest req = new APNGApplicantPayload.PatchRequest();
		req.contactId = applicant.Id;
		req.pronoun = 'They/Them';

		// WHEN validateSubmittedApplications is called
		Test.startTest();
		RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
		new APNGApplicantValidations().validateSubmittedApplications(applicant.Id, req, exceptions);
		Test.stopTest();

		// THEN no exceptions should be thrown
		Assert.areEqual(
			null,
			exceptions.getExceptions(),
			'No exceptions should be thrown for pronoun-only updates on submitted applications '
		);
	}

	@isTest
	private static void validateSubmittedApplications_shouldFail_whenNonPronounFieldsUpdated() {
		// GIVEN an applicant with a submitted application
		Contact applicant = [SELECT Id FROM Contact WHERE Phone = '11112222' LIMIT 1];
		Application__c submittedApp = [SELECT Id FROM Application__c WHERE Status__c = 'Submitted' LIMIT 1];

		// Create a patch request with pronoun and non-pronoun updates
		APNGApplicantPayload.PatchRequest req = new APNGApplicantPayload.PatchRequest();
		req.contactId = applicant.Id;
		req.pronoun = 'They/Them';
		req.lastName = 'NewLastName'; // Non-pronoun field

		// WHEN validateSubmittedApplications is called
		Test.startTest();
		RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
		new APNGApplicantValidations().validateSubmittedApplications(applicant.Id, req, exceptions);
		Test.stopTest();

		// THEN an exception should be thrown
		Assert.areEqual(
			1,
			exceptions.getExceptions().size(),
			'Should throw exception when non-pronoun fields are updated on submitted applications'
		);
		Assert.isTrue(
			exceptions.getExceptions()[0].getMessage().contains('Applicant has submitted Applications'),
			'Should indicate that applicant has submitted applications'
		);
	}

	@isTest
	private static void validateSubmittedApplications_shouldValidateFields_whenNoSubmittedApplications() {
		// GIVEN an applicant with no submitted applications
		Contact applicant = [SELECT Id FROM Contact WHERE Phone = '11112222' LIMIT 1];

		// Delete the submitted application created in makeData
		delete [SELECT Id FROM Application__c WHERE Status__c = 'Submitted'];

		// Create a patch request with invalid data
		APNGApplicantPayload.PatchRequest req = new APNGApplicantPayload.PatchRequest();
		req.contactId = applicant.Id;
		req.lastName = ''; // Invalid empty last name
		req.gender = ''; // Invalid empty gender

		// WHEN validateSubmittedApplications is called
		Test.startTest();
		RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
		new APNGApplicantValidations().validateSubmittedApplications(applicant.Id, req, exceptions);
		Test.stopTest();

		// THEN field validation exceptions should be thrown
		Assert.isTrue(exceptions.getExceptions().size() > 0, 'Should validate fields when no submitted applications exist');
		Assert.isTrue(
			exceptions.getExceptions()[0].getMessage().contains('Last Name cannot be empty'),
			'Should validate lastName when no submitted applications exist'
		);
	}

	@isTest
	static void checkCountryOfBirth_shouldFail_whenCountryEmpty() {
		// GIVEN a country with blank crmRecordId
		CommonWSPayload.Country country = new CommonWSPayload.Country();
		country.crmRecordId = '';

		// WHEN checkCountryOfBirthExists is called
		Test.startTest();
		RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
		new APNGApplicantValidations().checkCountryOfBirthExists(country, exceptions);
		Test.stopTest();

		// THEN it should throw an exception
		Assert.areEqual(1, exceptions.getExceptions().size(), 'Should have one exception');
		Assert.areEqual(
			'Country of birth is required',
			exceptions.getExceptions()[0].getMessage(),
			'Should indicate country of birth is required'
		);
	}

	@isTest
	static void checkCountryOfBirth_shouldFail_whenCountryNotFound() {
		// GIVEN a country with invalid crmRecordId
		CommonWSPayload.Country country = new CommonWSPayload.Country();
		country.crmRecordId = fflib_IDGenerator.generate(Country_Attribute__c.SObjectType);

		// WHEN checkCountryOfBirthExists is called
		Test.startTest();
		RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
		new APNGApplicantValidations().checkCountryOfBirthExists(country, exceptions);
		Test.stopTest();

		// THEN it should throw an exception
		Assert.areEqual(1, exceptions.getExceptions().size(), 'Should have one exception');
		Assert.areEqual(
			'Country of birth does not exist',
			exceptions.getExceptions()[0].getMessage(),
			'Should indicate country of birth does not exist'
		);
	}

	@isTest
	static void checkCountryOfBirth_shouldPass_whenCountryValid() {
		// GIVEN a valid country record
		Country_Attribute__c countryAttr = new Country_Attribute__c(Name = 'Test Country');
		insert countryAttr;

		CommonWSPayload.Country country = new CommonWSPayload.Country();
		country.crmRecordId = countryAttr.Id;

		// WHEN checkCountryOfBirthExists is called
		Test.startTest();
		RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
		new APNGApplicantValidations().checkCountryOfBirthExists(country, exceptions);
		Test.stopTest();

		// THEN no exceptions should be thrown
		Assert.areEqual(0, exceptions.getExceptions()?.size() ?? 0, 'Should not have any exceptions');
	}

	@isTest
	static void checkCountryOfBirth_shouldPass_whenCountryNull() {
		// GIVEN a null country
		CommonWSPayload.Country country = null;

		// WHEN checkCountryOfBirthExists is called
		Test.startTest();
		RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
		new APNGApplicantValidations().checkCountryOfBirthExists(country, exceptions);
		Test.stopTest();

		// THEN no exceptions should be thrown
		Assert.areEqual(0, exceptions.getExceptions()?.size() ?? 0, 'Should not have any exceptions when country is null');
	}
}