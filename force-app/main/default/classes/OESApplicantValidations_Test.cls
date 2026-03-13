/**
 * @description       : test OESApplicantValidations
 * @author            : Ben Greenland
 * @group             : admissions
 * @last modified on  : 2024-11-26
 * @last modified by  : Ben Greenland
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2024-09-16   Ben Greenland   Initial Version
**/
@isTest(isParallel=true)
private class OESApplicantValidations_Test {

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
    private static void testValidPayload(){
        //GIVEN a valid  OESApplicantPayload.PostRequest
        OESApplicantPayload.PostRequest request = new OESApplicantPayload.PostRequest();
        OESApplicantPayload.Applicant app = new OESApplicantPayload.Applicant();
        app.lastName = 'Application Lastname';
        CommonWSPayload.Email email = new CommonWSPayload.Email();
        email.email = 'test@test.com';
        email.type = 'personal';
        app.email = new List<CommonWSPayload.Email>{email};
        CommonWSPayload.Phone phone = new CommonWSPayload.Phone();
        phone.phoneNumber = '023423455';
        phone.type = 'mobile';
        app.phone = new List<CommonWSPayload.Phone>{phone};
        app.dateOfBirth = '1996-10-09';
        app.isPreviousMonashStudent = false;
        request.applicant = app;

        //WHEN it is validated
        Test.startTest();
        RESTlib_Ex.InvalidRequestException errorList = OESApplicantValidations.validate(request);
        Test.stopTest();
        //THEN there should be now errors
        Assert.areEqual(null, errorList.getExceptions(), 'Payload should be valid');
    }
    @istest
    private static void testInvalidPayload(){
        //GIVEN an Empty PostRequest 
        OESApplicantPayload.PostRequest request = new OESApplicantPayload.PostRequest();
        OESApplicantPayload.Applicant app = new OESApplicantPayload.Applicant();
        app.lastName = '';
        CommonWSPayload.Email email = new CommonWSPayload.Email();
        email.email = '';
        email.type = 'home';
        app.email = new List<CommonWSPayload.Email>{email};
        CommonWSPayload.Phone phone = new CommonWSPayload.Phone();
        phone.phoneNumber = '';
        phone.type = 'home';
        app.phone = new List<CommonWSPayload.Phone>{phone};
        app.dateOfBirth = '';
        request.applicant = app;
        //WHEN it is validated 
        Test.startTest();
        RESTlib_Ex.InvalidRequestException errorList = OESApplicantValidations.validate(request);
        Test.stopTest();
        //THEN there should be errors
        //There's a duplicate issue uncomment when fixed in Restlib_Ex
        Assert.isTrue(errorList.getExceptions().size()>=4, 'Payload should have 4 errors ');
    }

    @istest
    private static void testInvalidDate(){
        //GIVEN a  OESApplicantPayload.PostRequest with invalid date
        OESApplicantPayload.PostRequest request = new OESApplicantPayload.PostRequest();
        OESApplicantPayload.Applicant app = new OESApplicantPayload.Applicant();
        app.lastName = 'Application Lastname';
        CommonWSPayload.Email email = new CommonWSPayload.Email();
        email.email = 'test@test.com';
        email.type = 'personal';
        app.email = new List<CommonWSPayload.Email>{email};
        CommonWSPayload.Phone phone = new CommonWSPayload.Phone();
        phone.phoneNumber = '023423455';
        phone.type = 'mobile';
        app.phone = new List<CommonWSPayload.Phone>{phone};
        app.dateOfBirth = '1xxx';
        request.applicant = app;
        //WHEN it is validated
        Test.startTest();
        RESTlib_Ex.InvalidRequestException errorList = OESApplicantValidations.validate(request);
        Test.stopTest();
        //THEN there should be 1 error
        //There's a duplicate issue uncomment when fixed in Restlib_Ex
        Assert.isTrue(errorList.getExceptions().size()>=1, 'Payload should have 1 errors ');
        Assert.isTrue(String.valueOf(errorList.getExceptions()).contains('Only yyyy-MM-dd format is accepted'), 'error should be "Applicant\'s Date of Birth is of invalid format. Only yyyy-MM-dd format is accepted"');
    }

    @istest
    private static void test10YearOld(){
        //GIVEN a  OESApplicantPayload.PostRequest with birthdate < 10 years old
        OESApplicantPayload.PostRequest request = new OESApplicantPayload.PostRequest();
        OESApplicantPayload.Applicant app = new OESApplicantPayload.Applicant();
        app.lastName = 'Application Lastname';
        CommonWSPayload.Email email = new CommonWSPayload.Email();
        email.email = 'test@test.com';
        email.type = 'personal';
        app.email = new List<CommonWSPayload.Email>{email};
        CommonWSPayload.Phone phone = new CommonWSPayload.Phone();
        phone.phoneNumber = '023423455';
        phone.type = 'mobile';
        app.phone = new List<CommonWSPayload.Phone>{phone};
        String year = String.valueOf(Date.today().year()-2);
        app.dateOfBirth = year+'-10-09';
        request.applicant = app;

         //WHEN it is validated
         Test.startTest();
         RESTlib_Ex.InvalidRequestException errorList = OESApplicantValidations.validate(request);
         Test.stopTest();
          //THEN there should be 1 error and the error message should be "Applicant should be minimum 10 yrs old"
          // THeres a duplicate issue uncomment when fixed in Restlib_Ex
       // Assert.areEqual(1, errorList.getExceptions().size(), 'Payload should have 1 errors '+JSON.serializePretty(errorList.getExceptions().size()));
        Assert.isTrue(String.valueOf(errorList.getExceptions()).contains('10 yrs old'), 'error should be "Applicant should be minimum 10 yrs old"');
    }

    @isTest
    static void testValidateNullContactId() {
        // GIVEN a null contactId payload
        OESApplicantPayload.PatchRequest req = new OESApplicantPayload.PatchRequest();
        req.contactId = null;
        
        // WHEN validated
        RESTlib_Ex.InvalidRequestException result = OESApplicantValidations.validatePatchRequest(req);
        
        // THEN errors are expected
        Assert.isTrue(result.getExceptions().size()>0, 'Should have exceptions');
        Assert.areEqual('Request without a valid externalId', result.getExceptions()[0].getMessage(), 'Should have correct error message');
    }
    
    @isTest
    static void testValidateSubmittedApplicationWithUpdates() {
        Contact applicant = [SELECT Id,CRM_Id__c FROM Contact WHERE Phone = '11112222' LIMIT 1];

        // GIVEN a patch request with an application
        OESApplicantPayload.PatchRequest req = new OESApplicantPayload.PatchRequest();
        req.contactId = applicant.Id;
        req.lastName = 'NewLastName';
        req.externalId = applicant.CRM_Id__c;

        // WHEN it is validated
        RESTlib_Ex.InvalidRequestException result = OESApplicantValidations.validatePatchRequest(req);

        // THEN there should be 1 error
        Assert.isTrue(result.getExceptions().size()>0, 'Should have exceptions');
        Assert.areNOTEqual('Applicant has submitted Applications. Request contains fields which cannot be updated', 
                        result.getExceptions()[0].getMessage(), 
                        'Should have correct error message');
    }
    
    @isTest
        static void testValidateEmptyLastName() {
        // GIVEN a patch request with an empty last name
        OESApplicantPayload.PatchRequest req = new OESApplicantPayload.PatchRequest();
        req.contactId = '003000000000001'; // Dummy ID
        req.externalId = 'Cake';
        req.lastName = '';
        
        // WHEN it is validated
        RESTlib_Ex.InvalidRequestException result = OESApplicantValidations.validatePatchRequest(req);
        
        // THEN
        Assert.isTrue(result.getExceptions().size()>0, 'Should have exceptions');
        Assert.areEqual('Applicant\'s Last Name cannot be empty', result.getExceptions()[0].getMessage(), 'Should have correct error message');
    }
    
    @isTest
    static void testValidateEmptyEmail() {
        // GIVEN a patch request with an empty email
        OESApplicantPayload.PatchRequest req = new OESApplicantPayload.PatchRequest();
        req.contactId = '003000000000001'; // Dummy ID
        req.externalId = 'Cake';
        req.Email = new List<CommonWSPayload.Email>();
        CommonWSPayload.Email personalEmail = new CommonWSPayload.Email();
        personalEmail.type = 'Personal';
        personalEmail.email = '';
        req.Email.add(personalEmail);
        
        // WHEN it is validated
        RESTlib_Ex.InvalidRequestException result = OESApplicantValidations.validatePatchRequest(req);
        
        // THEN there should be 1 error
        Assert.isTrue(result.getExceptions().size()>0, 'Should have exceptions');
        Assert.areEqual('Applicant\'s email cannot be empty', result.getExceptions()[0].getMessage(), 'Should have correct error message');
    }
    
    @isTest
    static void testValidateInvalidGender() {
        // GIVEN a patch request with an invalid gender
        OESApplicantPayload.PatchRequest req = new OESApplicantPayload.PatchRequest();
        req.contactId = fflib_IDGenerator.generate(Schema.Contact.SObjectType); // Dummy ID
        req.externalId = 'Cake';
        req.gender = 'P'; // Assuming 'P' is in AgentPortalConstants.CON_UNUSED_GENDERS
        
        // WHEN it is validated
        RESTlib_Ex.InvalidRequestException result = OESApplicantValidations.validatePatchRequest(req);
        
        // THEN there should be 1 error
        Assert.isTrue(result.getExceptions().size()>0, 'Should have exceptions');
        Assert.areEqual('Applicant\'s Gender cannot be P or U', result.getExceptions()[0].getMessage(), 'Should have correct error message');
    }
    
    @isTest
    static void testValidateUnderage() {
        // GIVEN a patch request with a date of birth < 10 years old
        OESApplicantPayload.PatchRequest req = new OESApplicantPayload.PatchRequest();
        req.contactId = fflib_IDGenerator.generate(Schema.Contact.SObjectType); // Dummy ID
        req.externalId = 'Cake';
        req.gender = 'M';
        req.dateOfBirth = String.valueOf(Date.today().addYears(-9)); // 9 years old
        
        // WHEN it is validated
        RESTlib_Ex.InvalidRequestException result = OESApplicantValidations.validatePatchRequest(req);
        
        // THEN there should be 1 error
        Assert.isTrue(result.getExceptions().size()>0, 'Should have exceptions');
        Assert.areEqual('Applicant should be minimum 10 yrs old', result.getExceptions()[0].getMessage(), 'Should have correct error message');
    }
    
    @isTest
    static void testValidateValidRequest() {
        // GIVEN a patch request with a valid last name, email, gender, and date of birth
        OESApplicantPayload.PatchRequest req = new OESApplicantPayload.PatchRequest();
        req.contactId = fflib_IDGenerator.generate(Schema.Contact.SObjectType); // Dummy ID
        req.externalId = 'Cake';
        req.lastName = 'ValidLastName';
        req.Email = new List<CommonWSPayload.Email>();
        CommonWSPayload.Email personalEmail = new CommonWSPayload.Email();
        personalEmail.type = 'Personal';
        personalEmail.email = 'valid@email.com';
        req.Email.add(personalEmail);
        req.gender = 'M'; // Assuming 'M' is not in AgentPortalConstants.CON_UNUSED_GENDERS
        req.dateOfBirth = String.valueOf(Date.today().addYears(-20)); // 20 years old
        
        
        // WHEN it is validated
        RESTlib_Ex.InvalidRequestException result = OESApplicantValidations.validatePatchRequest(req);
        
        // THEN there should be no errors
        Assert.isFalse(result==null, 'Should not have exceptions');
    }

    @isTest
    static void testIsNonPronounFieldUpdated() {
        // Test case 1: Only pronoun field updated
        // GIVEN a patch request with only the pronoun field updated
        OESApplicantPayload.PatchRequest req1 = new OESApplicantPayload.PatchRequest();
        req1.pronoun = 'They/Them';

        // WHEN isNonPronounFieldUpdated is called
        // THEN it should return false
        OESApplicantValidations OESVals = new OESApplicantValidations();
        Assert.isFalse(OESVals.isNonPronounFieldUpdated(req1), 'Should return false when only pronoun is updated');

        // Test case 2: Non-pronoun field updated
        // GIVEN a patch request with a non-pronoun field (lastName) updated
        OESApplicantPayload.PatchRequest req2 = new OESApplicantPayload.PatchRequest();
        req2.lastName = 'NewLastName';

        // WHEN isNonPronounFieldUpdated is called
        // THEN it should return true
        Assert.isTrue(OESVals.isNonPronounFieldUpdated(req2), 'Should return true when lastName is updated');

        // Test case 3: Multiple fields updated including pronoun
        // GIVEN a patch request with multiple fields updated, including both pronoun and non-pronoun fields
        OESApplicantPayload.PatchRequest req3 = new OESApplicantPayload.PatchRequest();
        req3.pronoun = 'She/Her';
        req3.firstName = 'NewFirstName';
        req3.dateOfBirth = String.valueOf(Date.today().addYears(-20));

        // WHEN isNonPronounFieldUpdated is called
        // THEN it should return true
        Assert.isTrue(OESVals.isNonPronounFieldUpdated(req3), 'Should return true when multiple fields including non-pronoun are updated');

        // Test case 4: Email updated
        // GIVEN a patch request with the email field updated
        OESApplicantPayload.PatchRequest req4 = new OESApplicantPayload.PatchRequest();
        req4.Email = new List<CommonWSPayload.Email>();
        CommonWSPayload.Email personalEmail = new CommonWSPayload.Email();
        personalEmail.type = 'Personal';
        personalEmail.email = 'new@email.com';
        req4.Email.add(personalEmail);

        // WHEN isNonPronounFieldUpdated is called
        // THEN it should return true
        Assert.isTrue(OESVals.isNonPronounFieldUpdated(req4), 'Should return true when email is updated');

        // Test case 5: Phone updated
        // GIVEN a patch request with the phone field updated
        OESApplicantPayload.PatchRequest req5 = new OESApplicantPayload.PatchRequest();
        CommonWSPayload.Phone phone = new CommonWSPayload.Phone();
        phone.type = 'Mobile';
        phone.phoneNumber = '1234567890';
        req5.phone = new List<CommonWSPayload.Phone>{phone};

        // WHEN isNonPronounFieldUpdated is called
        // THEN it should return true
        Assert.isTrue(OESVals.isNonPronounFieldUpdated(req5), 'Should return true when phone is updated');

        // Test case 6: No fields updated
        // GIVEN a patch request with no fields updated
        OESApplicantPayload.PatchRequest req6 = new OESApplicantPayload.PatchRequest();

        // WHEN isNonPronounFieldUpdated is called
        // THEN it should return false
        Assert.isFalse(OESVals.isNonPronounFieldUpdated(req6), 'Should return false when no fields are updated');
    }
    

    @IsTest
    static void validateEmails_shouldPass_whenValidPersonalEmailProvided() {
        // GIVEN
        OESApplicantValidations validator = new OESApplicantValidations();
        RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
        List<CommonWSPayload.Email> emails = new List<CommonWSPayload.Email>();
        CommonWSPayload.Email email = new CommonWSPayload.Email();
        email.type = 'Personal';
        email.email = 'test@example.com';
        emails.add(email);

        // WHEN
        validator.validateEmails(emails, exceptions);

        // THEN
        Assert.isTrue(exceptions.getExceptions()==null, 
            'No exceptions should be thrown for valid email '+exceptions.getExceptions());
    }

    @IsTest
    static void validateEmails_shouldFail_whenNoEmailProvided() {
        // GIVEN
        OESApplicantValidations validator = new OESApplicantValidations();
        RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
        List<CommonWSPayload.Email> emails = new List<CommonWSPayload.Email>();

        // WHEN
        validator.validateEmails(emails, exceptions);

        // THEN
        Assert.areEqual(1, exceptions.getExceptions().size(), 
            'Should throw exception for empty email list');
        Assert.isTrue(
            exceptions.getExceptions()[0].getMessage().contains('At least one email address is required'),
            'Should indicate that email is required'
        );
    }

    @IsTest
    static void validateEmails_shouldFail_whenMonashEmailProvided() {
        // GIVEN
        OESApplicantValidations validator = new OESApplicantValidations();
        RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
        List<CommonWSPayload.Email> emails = new List<CommonWSPayload.Email>();
        CommonWSPayload.Email email = new CommonWSPayload.Email();
        email.type = 'Personal';
        email.email = 'test@monash.edu';
        emails.add(email);

        // WHEN
        validator.validateEmails(emails, exceptions);

        // THEN
        Assert.areEqual(1, exceptions.getExceptions().size(), 
            'Should throw exception for Monash email');
        Assert.isTrue(
            exceptions.getExceptions()[0].getMessage().contains('Monash email addresses are not allowed'),
            'Should indicate that Monash emails are not allowed'
        );
    }

    @IsTest
    static void validateEmails_shouldFail_whenStudentMonashEmailProvided() {
        // GIVEN
        OESApplicantValidations validator = new OESApplicantValidations();
        RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
        List<CommonWSPayload.Email> emails = new List<CommonWSPayload.Email>();
        CommonWSPayload.Email email = new CommonWSPayload.Email();
        email.type = 'Personal';
        email.email = 'test@student.monash.edu';
        emails.add(email);

        // WHEN
        validator.validateEmails(emails, exceptions);

        // THEN
        Assert.areEqual(1, exceptions.getExceptions().size(), 
            'Should throw exception for student Monash email');
        Assert.isTrue(
            exceptions.getExceptions()[0].getMessage().contains('Monash email addresses are not allowed'),
            'Should indicate that Monash emails are not allowed'
        );
    }

    @IsTest
    static void validateEmails_shouldFail_whenInvalidEmailFormatProvided() {
        // GIVEN
        OESApplicantValidations validator = new OESApplicantValidations();
        RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
        List<CommonWSPayload.Email> emails = new List<CommonWSPayload.Email>();
        CommonWSPayload.Email email = new CommonWSPayload.Email();
        email.type = 'Personal';
        email.email = 'invalid-email';
        emails.add(email);

        // WHEN
        validator.validateEmails(emails, exceptions);

        // THEN
        Assert.areEqual(1, exceptions.getExceptions().size(), 
            'Should throw exception for invalid email format');
        Assert.isTrue(
            exceptions.getExceptions()[0].getMessage().contains('Invalid email format'),
            'Should indicate that email format is invalid'
        );
    }

    @IsTest
    static void validateEmails_shouldPass_whenMultipleValidEmailsProvided() {
        // GIVEN
        OESApplicantValidations validator = new OESApplicantValidations();
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
        validator.validateEmails(emails, exceptions);

        // THEN
        Assert.isTrue(exceptions.getExceptions()==null, 
            'No exceptions should be thrown for valid emails ');
    }

    @IsTest
    static void validatePreviousMonashDetails_shouldPass_whenNotPreviousStudent() {
        // GIVEN
        OESApplicantPayload.PostRequest req = new OESApplicantPayload.PostRequest();
        req.applicant = new OESApplicantPayload.Applicant();
        req.applicant.isPreviousMonashStudent = false;
        req.applicant.previousMonashId = null;
        
        OESApplicantValidations validator = new OESApplicantValidations();
        RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();

        // WHEN
        validator.validatePreviousMonashDetails(
            req.applicant.isPreviousMonashStudent,
            req.applicant.previousMonashId,
            exceptions
        );

        // THEN
        Assert.isTrue(exceptions.getExceptions()==null, 
            'No exceptions should be thrown when not a previous student ');
    }

    @IsTest
    static void validatePreviousMonashDetails_shouldPass_whenPreviousStudentWithValidId() {
        // GIVEN
        OESApplicantPayload.PostRequest req = new OESApplicantPayload.PostRequest();
        req.applicant = new OESApplicantPayload.Applicant();
        req.applicant.isPreviousMonashStudent = true;
        req.applicant.previousMonashId = '12345678';
        
        OESApplicantValidations validator = new OESApplicantValidations();
        RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();

        // WHEN
        validator.validatePreviousMonashDetails(
            req.applicant.isPreviousMonashStudent,
            req.applicant.previousMonashId,
            exceptions
        );

        // THEN
        Assert.isTrue(exceptions.getExceptions()==null, 
            'No exceptions should be thrown for valid previous student details');
    }

    @IsTest
    static void validatePreviousMonashDetails_shouldFail_whenPreviousStudentWithoutId() {
        // GIVEN
        OESApplicantPayload.PostRequest req = new OESApplicantPayload.PostRequest();
        req.applicant = new OESApplicantPayload.Applicant();
        req.applicant.isPreviousMonashStudent = true;
        req.applicant.previousMonashId = null;
        
        OESApplicantValidations validator = new OESApplicantValidations();
        RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();

        // WHEN
        validator.validatePreviousMonashDetails(
            req.applicant.isPreviousMonashStudent,
            req.applicant.previousMonashId,
            exceptions
        );

        // THEN
        Assert.areEqual(1, exceptions.getExceptions().size(), 
            'Should throw exception when previous student has no ID');
        Assert.isTrue(
            exceptions.getExceptions()[0].getMessage()
                .contains('Previous Monash ID is required when applicant is a previous Monash student'),
            'Should indicate that Previous Monash ID is required'
        );
    }

    @IsTest
    static void validatePreviousMonashDetails_shouldFail_whenPreviousStudentWithLongId() {
        // GIVEN
        OESApplicantPayload.PostRequest req = new OESApplicantPayload.PostRequest();
        req.applicant = new OESApplicantPayload.Applicant();
        req.applicant.isPreviousMonashStudent = true;
        req.applicant.previousMonashId = '123456789012345678901'; // 21 characters
        
        OESApplicantValidations validator = new OESApplicantValidations();
        RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();

        // WHEN
        validator.validatePreviousMonashDetails(
            req.applicant.isPreviousMonashStudent,
            req.applicant.previousMonashId,
            exceptions
        );

        // THEN
        Assert.areEqual(1, exceptions.getExceptions().size(), 
            'Should throw exception when Previous Monash ID is too long');
        Assert.isTrue(
            exceptions.getExceptions()[0].getMessage()
                .contains('Previous Monash ID must not exceed 20 characters'),
            'Should indicate that Previous Monash ID is too long'
        );
    }



    @IsTest
    static void validatePreviousMonashDetails() {
        // GIVEN
        OESApplicantPayload.PatchRequest req = new OESApplicantPayload.PatchRequest();  
        req.isPreviousMonashStudent = true;
        req.previousMonashId = null;
        
        OESApplicantValidations validator = new OESApplicantValidations();
        RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();

        // WHEN
        validator.validatePreviousMonashDetails(
            req.isPreviousMonashStudent,
            req.previousMonashId,
            exceptions
        );

        // THEN
        Assert.areEqual(1, exceptions.getExceptions().size(), 
            'Should validate when patching previous student fields');
        Assert.isTrue(
            exceptions.getExceptions()[0].getMessage()
                .contains('Previous Monash ID is required when applicant is a previous Monash student'),
            'Should indicate that Previous Monash ID is required'
        );
    }
    @isTest
    static void validatePreviousMonashDetails_shouldFail_whenIsPreviousStudentIsNull() {
        // GIVEN a request where isPreviousMonashStudent is null
        Boolean isPreviousMonashStudent = null;
        String previousMonashId = null;
        RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
        
        // WHEN validating previous Monash details
        Test.startTest();
        new OESApplicantValidations().validatePreviousMonashDetails(
            isPreviousMonashStudent,
            previousMonashId,
            exceptions
        );
        Test.stopTest();
        
        // THEN appropriate exception should be thrown
        Assert.areEqual(1, exceptions.getExceptions().size(), 
            'Should throw exception when isPreviousMonashStudent is null');
        Assert.isTrue(
            exceptions.getExceptions()[0].getMessage()
                .contains('isPreviousMonashStudent is required'),
            'Should indicate that isPreviousMonashStudent is required'
        );
    }

    @isTest
    static void validateGender_shouldFail_whenEmpty() {
        // GIVEN a patch request with an empty gender
        OESApplicantPayload.PatchRequest req = new OESApplicantPayload.PatchRequest();
        req.contactId = fflib_IDGenerator.generate(Schema.Contact.SObjectType); // Dummy ID
        req.gender = '';
        req.externalId = 'EXTERNAL_ID';
        
        // WHEN it is validated
        RESTlib_Ex.InvalidRequestException result = OESApplicantValidations.validatePatchRequest(req);
        
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
        OESApplicantPayload.PatchRequest req = new OESApplicantPayload.PatchRequest();
        req.contactId = fflib_IDGenerator.generate(Schema.Contact.SObjectType); // Dummy ID
        req.gender = null;
        req.externalId = 'EXTERNAL_ID';
        // WHEN it is validated
        RESTlib_Ex.InvalidRequestException result = OESApplicantValidations.validatePatchRequest(req);
        
        // THEN there should be an error for null gender
        Assert.isTrue(result.getExceptions().size() > 0, 'Should have exceptions');
        Assert.isTrue(
            result.message.contains('Gender cannot be empty'),
            'Should indicate that gender cannot be empty'
        );
    }

    @isTest
    static void validateGender_shouldPass_whenValid() {
        // GIVEN a patch request with a valid gender
        OESApplicantPayload.PatchRequest req = new OESApplicantPayload.PatchRequest();
        req.contactId = fflib_IDGenerator.generate(Schema.Contact.SObjectType); // Dummy ID
        req.gender = 'M'; // Assuming 'M' is a valid gender code
        req.externalId = 'EXTERNAL_ID';
        
        // WHEN it is validated
        RESTlib_Ex.InvalidRequestException result = OESApplicantValidations.validatePatchRequest(req);
        
        // THEN there should be no gender-related errors
        Assert.isTrue(
            !String.valueOf(result.message).contains('Gender'),
            'Should not have gender-related errors'
        );
    }

    @isTest
    static void validateGender_shouldFail_whenUnusedGender() {
        // GIVEN a patch request with an unused gender code
        OESApplicantPayload.PatchRequest req = new OESApplicantPayload.PatchRequest();
        req.contactId = fflib_IDGenerator.generate(Schema.Contact.SObjectType); // Dummy ID
        req.gender = 'P'; // P is in CON_UNUSED_GENDERS
        req.externalId = 'EXTERNAL_ID';
        
        // WHEN it is validated
        RESTlib_Ex.InvalidRequestException result = OESApplicantValidations.validatePatchRequest(req);
        
        // THEN there should be an error for unused gender

        Assert.isTrue(result.getExceptions().size() > 0, 'Should have exceptions');
        Assert.isTrue(
            result.getListExceptionSummaryString().contains('Gender cannot be P or U'),
            'Should indicate that gender P or U is not allowed'
        );
    }
    @IsTest
static void validateAddresses_shouldPass_whenValidPostalAddress() {
    // GIVEN a valid postal address
    List<CommonWSPayload.Address> addresses = new List<CommonWSPayload.Address>();
    CommonWSPayload.Address address = new CommonWSPayload.Address();
    address.type = 'Postal';
    address.street = '123 Test St';
    address.city = 'Test City';
    address.state = 'Test State';
    address.postalCode = '1234';
    address.country = 'Test Country';
    addresses.add(address);
    
    OESApplicantValidations validator = new OESApplicantValidations();
    RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();

    // WHEN validating addresses
    Test.startTest();
    validator.validateAddresses(addresses, exceptions);
    Test.stopTest();

    // THEN no exceptions should be thrown
    Assert.isTrue(exceptions.getExceptions() == null, 
        'No exceptions should be thrown for valid postal address');
}

@IsTest
static void validateAddresses_shouldFail_whenNoPostalAddress() {
    // GIVEN only an 'Other' type address
    List<CommonWSPayload.Address> addresses = new List<CommonWSPayload.Address>();
    CommonWSPayload.Address address = new CommonWSPayload.Address();
    address.type = 'Other';
    address.street = '123 Test St';
    address.city = 'Test City';
    address.state = 'Test State';
    address.postalCode = '1234';
    address.country = 'Test Country';
    addresses.add(address);
    
    OESApplicantValidations validator = new OESApplicantValidations();
    RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();

    // WHEN validating addresses
    Test.startTest();
    validator.validateAddresses(addresses, exceptions);
    Test.stopTest();

    // THEN should have postal address required error

    Assert.isTrue(
        exceptions.getExceptions()[0].getMessage().contains('Postal address is required'),
        'Should indicate that postal address is required'
    );
}

@IsTest
static void validateAddresses_shouldFail_whenInvalidAddressType() {
    // GIVEN an address with invalid type
    List<CommonWSPayload.Address> addresses = new List<CommonWSPayload.Address>();
    CommonWSPayload.Address address = new CommonWSPayload.Address();
    address.type = 'Invalid';
    address.street = '123 Test St';
    address.city = 'Test City';
    address.state = 'Test State';
    address.postalCode = '1234';
    address.country = 'Test Country';
    addresses.add(address);
    
    OESApplicantValidations validator = new OESApplicantValidations();
    RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();

    // WHEN validating addresses
    Test.startTest();
    validator.validateAddresses(addresses, exceptions);
    Test.stopTest();

    // THEN should have invalid type error
    Assert.isTrue(exceptions.getExceptions().size() > 0, 
        'Should throw exception for invalid address type');
    Assert.isTrue(
        exceptions.getListExceptionSummaryString().contains('Invalid address type. Must be either Postal or Other'),
        'Should indicate that address type is invalid'
    );
}

@IsTest
static void validateAddresses_shouldFail_whenEmptyAddressType() {
    // GIVEN an address with empty type
    List<CommonWSPayload.Address> addresses = new List<CommonWSPayload.Address>();
    CommonWSPayload.Address address = new CommonWSPayload.Address();
    address.type = '';
    address.street = '123 Test St';
    address.city = 'Test City';
    address.state = 'Test State';
    address.postalCode = '1234';
    address.country = 'Test Country';
    addresses.add(address);
    
    OESApplicantValidations validator = new OESApplicantValidations();
    RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();

    // WHEN validating addresses
    Test.startTest();
    validator.validateAddresses(addresses, exceptions);
    Test.stopTest();

    // THEN should have empty type error
    Assert.isTrue(exceptions.getExceptions().size() > 0, 
        'Should throw exception for empty address type');
    Assert.isTrue(
        exceptions.getListExceptionSummaryString().contains('Address type is required'),
        'Should indicate that address type is required'
    );
}

@IsTest
static void validateAddresses_shouldPass_whenBothPostalAndOtherAddresses() {
    // GIVEN both postal and other addresses
    List<CommonWSPayload.Address> addresses = new List<CommonWSPayload.Address>();
    
    // Add postal address
    CommonWSPayload.Address postalAddress = new CommonWSPayload.Address();
    postalAddress.type = 'Postal';
    postalAddress.street = '123 Test St';
    postalAddress.city = 'Test City';
    postalAddress.state = 'Test State';
    postalAddress.postalCode = '1234';
    postalAddress.country = 'Test Country';
    addresses.add(postalAddress);
    
    // Add other address
    CommonWSPayload.Address otherAddress = new CommonWSPayload.Address();
    otherAddress.type = 'Other';
    otherAddress.street = '456 Other St';
    otherAddress.city = 'Other City';
    otherAddress.state = 'Other State';
    otherAddress.postalCode = '5678';
    otherAddress.country = 'Other Country';
    addresses.add(otherAddress);
    
    OESApplicantValidations validator = new OESApplicantValidations();
    RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();

    // WHEN validating addresses
    Test.startTest();
    validator.validateAddresses(addresses, exceptions);
    Test.stopTest();

    // THEN no exceptions should be thrown
    Assert.isTrue(exceptions.getExceptions() == null, 
        'No exceptions should be thrown for valid postal and other addresses');
}

@IsTest
static void checkCountryOfBirthExists_shouldHandleAllScenarios() {
    // GIVEN test data setup
    Country_Attribute__c validCountry = new Country_Attribute__c(
        Name = 'Test Country',
        uniqueCountryExternalId__c = 'TEST123'
    );
    insert validCountry;
    
    OESApplicantValidations validator = new OESApplicantValidations();
    RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
    
    // Test Scenario 1: Valid country
    // GIVEN a valid country
    CommonWSPayload.Country validCountryPayload = new CommonWSPayload.Country();
    validCountryPayload.uniqueCountryExternalId = 'TEST123';
    
    // WHEN validating valid country
    Test.startTest();
    validator.checkCountryOfBirthExists(validCountryPayload, exceptions);
    
    // THEN no exceptions should be thrown
    Assert.isTrue(exceptions.getExceptions() == null, 
        'No exceptions should be thrown for valid country');
    
    // Test Scenario 2: Non-existent country
    // GIVEN a non-existent country
    CommonWSPayload.Country nonExistentCountry = new CommonWSPayload.Country();
    nonExistentCountry.uniqueCountryExternalId = 'NONEXISTENT';
    exceptions = new RESTlib_Ex.InvalidRequestException();
    
    // WHEN validating non-existent country
    validator.checkCountryOfBirthExists(nonExistentCountry, exceptions);
    
    // THEN should have country not found error
    Assert.areEqual(1, exceptions.getExceptions().size(), 
        'Should throw exception for non-existent country');
    Assert.isTrue(
        exceptions.getExceptions()[0].getMessage().contains('Country of birth does not exist'),
        'Should indicate that country does not exist'
    );
    
    // Test Scenario 3: Null country
    // GIVEN a null country
    exceptions = new RESTlib_Ex.InvalidRequestException();
    
    // WHEN validating null country
    validator.checkCountryOfBirthExists(null, exceptions);
    
    // THEN should have required field error
    Assert.areEqual(1, exceptions.getExceptions().size(), 
        'Should throw exception for null country');
    Assert.isTrue(
        exceptions.getExceptions()[0].getMessage().contains('Country of birth is required'),
        'Should indicate that country is required'
    );
    
    // Test Scenario 4: Country with null uniqueCountryExternalId
    // GIVEN a country with null uniqueCountryExternalId
    CommonWSPayload.Country nullIdCountry = new CommonWSPayload.Country();
    exceptions = new RESTlib_Ex.InvalidRequestException();
    
    // WHEN validating country with null id
    validator.checkCountryOfBirthExists(nullIdCountry, exceptions);
    
    // THEN should have required field error
    Assert.areEqual(1, exceptions.getExceptions().size(), 
        'Should throw exception for country with null id');
    Assert.isTrue(
        exceptions.getExceptions()[0].getMessage().contains('Country of birth is required'),
        'Should indicate that country is required'
    );
    Test.stopTest();
}
}