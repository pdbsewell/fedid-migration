/**
 * @description       : Test coverage for ApplicationWSValidations
 * @author            : Ben Greenland
 * @group             : admissions
 * @last modified on  : 2024-11-26
 * @last modified by  : Ben Greenland
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2024-10-21   Ben Greenland   Initial Version
 **/

@IsTest(isParallel=true)
private class ApplicantWSValidations_Test {
  /**
   * @description Tests the validate method with a valid OES post request
   */
  @IsTest
  static void testValidate_OESPostRequest() {
    // GIVEN an OES post request
    OESApplicantPayload.PostRequest request = new OESApplicantPayload.PostRequest();
    request.applicant = new OESApplicantPayload.Applicant();
    request.applicant.lastName = 'Doe';
    request.applicant.dateOfBirth = '1990-01-01';
    request.applicant.isPreviousMonashStudent = false; 
    CommonWSPayload.Email email = new CommonWSPayload.Email();
    email.email = 'test@example.com';
    email.type = 'Personal';
    request.applicant.email = new List<CommonWSPayload.Email>{ email };
    CommonWSPayload.Phone phone = new CommonWSPayload.Phone();
    phone.phoneNumber = '023423455';
    phone.type = 'mobile';
    request.applicant.phone = new List<CommonWSPayload.Phone>{ phone };


    // WHEN the validate method is called
    Test.startTest();
    RESTlib_Ex.InvalidRequestException result = ApplicantWSValidations.validate(
      request
    );
    Test.stopTest();
    // THEN no exceptions should be thrown
    Assert.areEqual(
      '',
      result.message,
      'No exceptions should be thrown for a valid OES request'
    );
  }

  /**
   * @description Tests the validate method with a valid APNG post request
   */
  @IsTest
  static void testValidate_APNGPostRequest() {
    // GIVEN an APNG post request
    APNGApplicantPayload.PostRequest request = new APNGApplicantPayload.PostRequest();
    request.applicant = new APNGApplicantPayload.Applicant();
    request.applicant.lastName = 'Smith';
    request.applicant.dateOfBirth = '1985-05-05';
    CommonWSPayload.Email email = new CommonWSPayload.Email();
    email.email = 'test@example.com';
    email.type = 'Personal';
    request.applicant.email = new List<CommonWSPayload.Email>{ email };

    // WHEN the validate method is called
    RESTlib_Ex.InvalidRequestException result = ApplicantWSValidations.validate(
      request
    );

    // THEN no exceptions should be thrown
    Assert.areEqual(
      '',
      result.message,
      'No exceptions should be thrown for a valid request'
    );
  }

  /**
   * @description Tests the validatePatchRequest method with a valid OES patch request
   */
  @IsTest
  static void testValidatePatchRequest_OESPatchRequest() {
    // GIVEN a valid OES patch request with all required fields
    OESApplicantPayload.PatchRequest req = new OESApplicantPayload.PatchRequest();
    req.contactId = fflib_IDGenerator.generate(Schema.Contact.SObjectType);
    req.externalId = 'TEST123';
    req.lastName = 'Test LastName';
    req.gender = 'M';
    req.dateOfBirth = String.valueOf(Date.today().addYears(-20));
    
    // Add required email
    CommonWSPayload.Email email = new CommonWSPayload.Email();
    email.email = 'test@example.com';
    email.type = 'Personal';
    req.email = new List<CommonWSPayload.Email>{ email };
    
    // Add required phone
    CommonWSPayload.Phone phone = new CommonWSPayload.Phone();
    phone.phoneNumber = '0412345678';
    phone.type = 'Mobile';
    req.phone = new List<CommonWSPayload.Phone>{ phone };
    
    // Add required address
    CommonWSPayload.Address address = new CommonWSPayload.Address();
    address.type = 'Postal';
    address.street = '123 Test St';
    address.city = 'Test City';
    address.state = 'Test State';
    address.postalCode = '1234';
    address.country = 'Test Country';
    req.address = new List<CommonWSPayload.Address>{ address };
    
    // Add required country of birth
    CommonWSPayload.Country countryOfBirth = new CommonWSPayload.Country();
    countryOfBirth.uniqueCountryExternalId = 'TEST123';
    req.countryOfBirth = countryOfBirth;
    
    // Add required isPreviousMonashStudent field
    req.isPreviousMonashStudent = false;
    
    // Create test country record
    Country_Attribute__c testCountry = new Country_Attribute__c(
        Name = 'Test Country',
        uniqueCountryExternalId__c = 'TEST123'
    );
    insert testCountry;
    
    // WHEN validating the request
    Test.startTest();
    RESTlib_Ex.InvalidRequestException result = ApplicantWSValidations.validatePatchRequest(req);
    Test.stopTest();
    
    // THEN no exceptions should be thrown
    Assert.isTrue(result.getExceptions() == null || result.getExceptions().isEmpty(), 
        'No exceptions should be thrown for valid patch request. Got: ' + 
        (result.getExceptions() != null ? JSON.serializePretty(result.getExceptions()) : 'null'));
  }

  /**
   * @description Tests the validatePatchRequest method with a valid APNG patch request
   */
  @IsTest
  static void testValidatePatchRequest_APNGPatchRequest() {
    // GIVEN an APNG patch request
    APNGApplicantPayload.PatchRequest request = new APNGApplicantPayload.PatchRequest();
    request.contactId = fflib_IDGenerator.generate(Contact.SObjectType);
    request.lastName = 'NewLastName';
    request.gender = 'F';

    // WHEN the validatePatchRequest method is called
    RESTlib_Ex.InvalidRequestException result = ApplicantWSValidations.validatePatchRequest(
      request
    );

    // THEN
    Assert.areEqual(
      '',
      result.message,
      'No exceptions should be thrown for a valid patch request'
    );
  }

  /**
   * @description Tests the validateLastName method with a valid last name
   */
  @IsTest
  static void testValidateLastName_Valid() {
    // GIVEN a valid last name
    String lastName = 'ValidName';
    RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
    TestApplicantWSValidations validator = new TestApplicantWSValidations();

    // WHEN the validateLastName method is called
    validator.testValidateLastName(lastName, exceptions);

    // THEN
    Assert.areEqual(
      '',
      exceptions.message,
      'No exceptions should be thrown for a valid last name'
    );
  }

  /**
   * @description Tests the validateLastName method with an invalid (empty) last name
   */
  @IsTest
  static void testValidateLastName_Invalid() {
    // GIVEN an empty last name
    String lastName = '';
    RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
    TestApplicantWSValidations validator = new TestApplicantWSValidations();

    // WHEN the validateLastName method is called
    validator.testValidateLastName(lastName, exceptions);

    // THEN an exception should be thrown
    Assert.areEqual(
      1,
      exceptions.getExceptions().size(),
      'An exception should be thrown for an empty last name'
    );
    Assert.isTrue(
      exceptions.getExceptions()[0]
        .getMessage()
        .contains('Last Name cannot be empty'),
      'Exception message should mention empty last name'
    );
  }

  /**
   * @description Tests the validateDateOfBirth method with a valid date of birth
   */
  @IsTest
  static void testValidateDateOfBirth_Valid() {
    // GIVEN a valid date of birth
    String dateOfBirth = '1990-01-01';
    RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
    TestApplicantWSValidations validator = new TestApplicantWSValidations();

    // WHEN the validateDateOfBirth method is called
    validator.testValidateDateOfBirth(dateOfBirth, exceptions);

    // THEN
    Assert.areEqual(
      '',
      exceptions.message,
      'No exceptions should be thrown for a valid date of birth'
    );
  }

  /**
   * @description Tests the validateDateOfBirth method with an invalid date of birth (age less than minimum required)
   */
  @IsTest
  static void testValidateDateOfBirth_Invalid() {
    // GIVEN a date of birth that is less than the minimum required age
    String dateOfBirth = String.valueOf(
      Date.valueOf(Date.today().addYears(-5))
    );
    RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
    TestApplicantWSValidations validator = new TestApplicantWSValidations();

    // WHEN the validateDateOfBirth method is called
    validator.testValidateDateOfBirth(dateOfBirth, exceptions);

    // THEN an exception should be thrown
    Assert.areEqual(
      1,
      exceptions.getExceptions().size(),
      'An exception should be thrown for an invalid date of birth'
    );

    Assert.isTrue(
      exceptions.getExceptions()[0].getMessage().contains('minimum 10 yrs old'),
      'Exception message should mention minimum age'
    );
  }

  @IsTest
  static void validateEmails_shouldPass_whenValidEmailsProvided() {
    // GIVEN
    TestApplicantWSValidations validator = new TestApplicantWSValidations();
    RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
    List<CommonWSPayload.Email> emails = new List<CommonWSPayload.Email>();
    CommonWSPayload.Email email = new CommonWSPayload.Email();
    email.type = 'Personal';
    email.email = 'test@example.com';
    emails.add(email);
    email = new CommonWSPayload.Email();
    email.type = 'Work';
    email.email = 'test@work.com';
    emails.add(email);

    // WHEN
    validator.testValidateEmails(emails, exceptions);

    // THEN
    Assert.isNull(
      exceptions.getExceptions(),
      'No exceptions should be thrown for valid emails'
    );
  }

  @IsTest
  static void validateEmails_shouldFail_whenEmptyEmailProvided() {
    // GIVEN
    TestApplicantWSValidations validator = new TestApplicantWSValidations();
    RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
    List<CommonWSPayload.Email> emails = new List<CommonWSPayload.Email>();
    CommonWSPayload.Email email = new CommonWSPayload.Email();
    email.type = 'Personal';
    email.email = '';
    emails.add(email);

    // WHEN
    validator.testValidateEmails(emails, exceptions);

    // THEN
    Assert.isTrue(
      exceptions.getExceptions() != null,
      'Should throw exception for empty email'
    );
    Assert.isTrue(
      exceptions.getExceptions()[0]
        .getMessage()
        .contains('Applicant\'s Email cannot be empty'),
      'Should indicate that email cannot be empty'
    );
  }
  @IsTest
  static void validateGender_shouldFail_whenUnusedGenderProvided() {
    // GIVEN
    TestApplicantWSValidations validator = new TestApplicantWSValidations();
    RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
    String unusedGender = 'P'; // P is in CON_UNUSED_GENDERS

      // WHEN
      validator.testValidateGender(unusedGender, exceptions);

      // THEN
      Assert.areEqual(1, exceptions.getExceptions().size(), 
          'Should throw exception for unused gender');
      Assert.isTrue(
          exceptions.getExceptions()[0].getMessage()
              .contains('Applicant\'s Gender cannot be P or U'),
          'Should indicate that gender P or U is not allowed'
    );
  }

  /**
   * @description Test implementation of ApplicantWSValidations to access protected methods
   */
  private class TestApplicantWSValidations extends ApplicantWSValidations {
    protected override void validateRequest(
      RESTlib_Payload.Request requestObj,
      RESTlib_Ex.InvalidRequestException exceptions
    ) {
    }
    protected override void validatePatchRequest(
      RESTlib_Payload.Request requestObj,
      RESTlib_Ex.InvalidRequestException exceptions
    ) {
    }
    protected override Boolean isNonPronounFieldUpdated(Object req) {
      return false;
    }

    public void testValidateLastName(
      String lastName,
      RESTlib_Ex.InvalidRequestException exceptions
    ) {
      validateLastName(lastName, exceptions);
    }

    public void testValidateDateOfBirth(
      String dateOfBirth,
      RESTlib_Ex.InvalidRequestException exceptions
    ) {
      validateDateOfBirth(dateOfBirth, exceptions);
    }
    public void testValidateEmails(
      List<CommonWSPayload.Email> emails,
      RESTlib_Ex.InvalidRequestException exceptions
    ) {
      validateEmails(emails, exceptions);
    }

    public void testValidateGender(
      String gender,
      RESTlib_Ex.InvalidRequestException exceptions
    ) {
      validateGender(gender, exceptions);
    }

    public void testValidateAddresses(
          List<CommonWSPayload.Address> addresses,
          RESTlib_Ex.InvalidRequestException exceptions
      ) {
      validateAddresses(addresses, exceptions);
    }
  }


  @IsTest
  static void validateAddresses_shouldPass_whenValidAddressesProvided() {
      // GIVEN
      TestApplicantWSValidations validator = new TestApplicantWSValidations();
      RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
      List<CommonWSPayload.Address> addresses = new List<CommonWSPayload.Address>();
      CommonWSPayload.Address address = new CommonWSPayload.Address();
      address.type = 'Postal';
      address.street = '123 Main St';
      address.city = 'Melbourne';
      address.state = 'VIC';
      address.country = 'Australia';
      address.postalCode = '3000';
      addresses.add(address);

      // WHEN
      validator.testValidateAddresses(addresses, exceptions);

      // THEN
      Assert.isNull(exceptions.getExceptions(), 
          'No exceptions should be thrown for valid addresses');
  }

  @IsTest
  static void validateAddresses_shouldFail_whenMissingRequiredFields() {
      // GIVEN
      TestApplicantWSValidations validator = new TestApplicantWSValidations();
      RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
      List<CommonWSPayload.Address> addresses = new List<CommonWSPayload.Address>();
      CommonWSPayload.Address address = new CommonWSPayload.Address();
      address.type = 'Postal';
      address.street = '';
      address.city = '';
      address.country = '';
      address.postalCode = '';
      addresses.add(address);

      // WHEN
      validator.testValidateAddresses(addresses, exceptions);

      // THEN
      Assert.isTrue(exceptions.getExceptions().size() > 0, 
          'Should throw exception for each missing required field');
      Assert.isTrue(
          exceptions.getListExceptionSummaryString().contains('required for postal address'),
          'Should indicate missing required fields'
      );
  }

  @IsTest
  static void validateAddresses_shouldFail_whenInvalidAddressType() {
      // GIVEN
      TestApplicantWSValidations validator = new TestApplicantWSValidations();
      RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
      List<CommonWSPayload.Address> addresses = new List<CommonWSPayload.Address>();
      CommonWSPayload.Address address = new CommonWSPayload.Address();
      address.type = 'Invalid';
      address.street = '123 Main St';
      address.city = 'Melbourne';
      address.state = 'VIC';
      address.country = 'Australia';
      address.postalCode = '3000';
      addresses.add(address);

      // WHEN
      validator.testValidateAddresses(addresses, exceptions);

      // THEN
      Assert.areEqual(2, exceptions.getExceptions().size(), 
          'Should throw 1 exception for invalid address type');
      Assert.isTrue(
          exceptions.getListExceptionSummaryString().contains('Invalid address type. Must be either Postal or Other'),
          'Should indicate invalid address type'
      );
  }


  @IsTest
  static void validateAddresses_shouldValidateMultipleAddresses() {
      // GIVEN
      TestApplicantWSValidations validator = new TestApplicantWSValidations();
      RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
      List<CommonWSPayload.Address> addresses = new List<CommonWSPayload.Address>();
      CommonWSPayload.Address address = new CommonWSPayload.Address();
      address.type = 'Postal';
      address.street = '123 Main St';
      address.city = 'Melbourne';
      address.state = 'VIC';
      address.country = 'Australia';
      address.postalCode = '3000';
      addresses.add(address);
      address = new CommonWSPayload.Address();
      address.type = 'Other';
      address.street = '456 Second St';
      address.city = 'Sydney';
      address.state = 'NSW';
      address.country = 'Australia';
      address.postalCode = '2000';
      addresses.add(address);

      // WHEN
      validator.testValidateAddresses(addresses, exceptions);

      // THEN
      Assert.isNull(exceptions.getExceptions(), 
          'No exceptions should be thrown for valid multiple addresses');
  }

  @IsTest
  static void validateGender_shouldFail_whenEmpty() {
    // GIVEN
    TestApplicantWSValidations validator = new TestApplicantWSValidations();
    RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
    String emptyGender = '';

    // WHEN
    validator.testValidateGender(emptyGender, exceptions);

    // THEN
    Assert.areEqual(1, exceptions.getExceptions().size(), 
        'Should throw exception for empty gender');
    Assert.isTrue(
        exceptions.getExceptions()[0].getMessage()
            .contains('Applicant\'s Gender cannot be empty'),
        'Should indicate that gender cannot be empty'
    );
  }

  @IsTest
  static void validateGender_shouldFail_whenNull() {
    // GIVEN
    TestApplicantWSValidations validator = new TestApplicantWSValidations();
    RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
    String nullGender = null;

    // WHEN
    validator.testValidateGender(nullGender, exceptions);

    // THEN
    Assert.areEqual(1, exceptions.getExceptions().size(), 
        'Should throw exception for null gender');
    Assert.isTrue(
        exceptions.getExceptions()[0].getMessage()
            .contains('Applicant\'s Gender cannot be empty'),
        'Should indicate that gender cannot be empty'
    );
  }

  @IsTest
  static void validateGender_shouldPass_whenValid() {
    // GIVEN
    TestApplicantWSValidations validator = new TestApplicantWSValidations();
    RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
    String validGender = 'M'; // Assuming 'M' is a valid gender code

    // WHEN
    validator.testValidateGender(validGender, exceptions);

    // THEN
    Assert.isNull(exceptions.getExceptions(), 
        'No exceptions should be thrown for valid gender');
  }
}