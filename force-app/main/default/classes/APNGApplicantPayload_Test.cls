/**
 * @description Test class for APNGApplicantPayload. This is Payload class, so no functional testing
 * @author      Nick Guia
 * @since       AUG.02.2024
 * @revison     Bgreenland 30 Aug 2024 - additional test
 * @revison     BGreenland 20 Nov 2024 - added test for country of birth
 */
@isTest(isParallel=true)
private class APNGApplicantPayload_Test {
  @TestSetup
  static void makeData() {
    //create APNG User
    TriggerCommon.disableTrigger('Country_Attribute__c');
    TriggerCommon.disableTrigger('Account');
    TriggerCommon.disableTrigger('Contact');
    TriggerCommon.disableTrigger('User');

    AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser()
      .build();

          // create a test Country
    AgentPortalTestDataFactory factory = new AgentPortalTestDataFactory();
    Country_Attribute__c country = factory.createCountryAttribute(
      BDPConstants.AUSTRALIA_CALLISTA_CODE,
      'AUSTRALIA'
    );
    insert country;
    TriggerCommon.enableTrigger('Country_Attribute__c');
    TriggerCommon.enableTrigger('Account');
    TriggerCommon.enableTrigger('Contact');
    TriggerCommon.enableTrigger('User');
  }

  /**
   * @description Test that the request payload can be properly
   * initialized and is an instance of RESTlib_Payload.Request
   */

  @isTest
  static void shouldCreateGetRequest() {
    // GIVEN : a req variable
    APNGApplicantPayload.GetRequest req;
    User testUser = getTestUser();
    System.runAs(testUser) {
      Test.startTest();

      // WHEN : I initialize
      req = new APNGApplicantPayload.GetRequest();
      req.crmContactId = 'MAPS_TO_CONTACT.CRM_ID__C';
      req.applicantName = 'Some Applicant Name';
      req.pageSize = 100;
      req.pageOffset = 100;

      Test.stopTest();
    }

    // THEN : initialization successful
    Assert.isNotNull(
      req,
      'Unable to initialize APNGApplicantPayload.GetRequest'
    );
    // should extend to the framework
    Assert.isInstanceOfType(
      req,
      RESTlib_Payload.Request.class,
      'Request Payload should be an instance of RESTlib_Payload.Request'
    );
  }

  /**
   * @description Test that the request payload can be properly
   * initialized and is an instance of RESTlib_Payload.Request
   */
  @isTest
  static void shouldCreateGetResponse() {
    // GIVEN : a response variable
    APNGApplicantPayload.GetResponse resp;
    APNGApplicantPayload.ApplicantDetails applicant = new APNGApplicantPayload.ApplicantDetails(
      new Contact(First_Name__c = 'Applicant FN', Last_Name__c = 'Applicant LN')
    );
    applicant.isEditable = false;

    Test.startTest();
    User testUser = getTestUser();
    System.runAs(testUser) {
      // WHEN : I initialize
      resp = new APNGApplicantPayload.GetResponse();
      resp.noOfRecords = 1;
      resp.pageSize = 100;
      resp.pageOffset = 100;
      resp.applicant = applicant;
      resp.message = 'TestMessage';
      resp.applicants = new List<APNGApplicantPayload.ApplicantDetails>();
    }

    Test.stopTest();

    // THEN : initialization successful
    Assert.isNotNull(
      resp,
      'Unable to initialize APNGApplicantPayload.GetResponse'
    );
    // should extend to the framework
    Assert.isInstanceOfType(
      resp,
      RESTlib_Payload.Response.class,
      'Request Payload should be an instance of RESTlib_Payload.Response'
    );
  }

  /**
   * @description Test that ApplicantDetails can be properly initialized
   */
  @isTest
  static void shouldCreateApplicantDetails() {
    // GIVEN : an applicant variable
    APNGApplicantPayload.ApplicantDetails applicant;

    User testUser = getTestUser();
    System.runAs(testUser) {
      Test.startTest();

      // WHEN : I initialize
      applicant = new APNGApplicantPayload.ApplicantDetails(
        new Contact(
          First_Name__c = 'Applicant FN',
          Last_Name__c = 'Applicant LN'
        )
      );
      applicant.isEditable = false;

      Test.stopTest();
    }
    // THEN : initialization successful
    Assert.isNotNull(
      applicant,
      'Unable to initialize APNGApplicantPayload.ApplicantDetails'
    );
  }

  /**
   * @description test APNGApplicantPayload.getEmail
   * @author Ben Greenland | 2024-08-26
   **/
  @isTest
  static void testGetEmail() {
    User testUser = getTestUser();
    System.runAs(testUser) {
      //GIVEN the payload contains Emails
      List<CommonWSPayload.Email> emails = new List<CommonWSPayload.Email>();
      CommonWSPayload.Email email1 = new CommonWSPayload.Email();
      email1.type = 'Primary';
      email1.email = 'bob@bob.com';
      emails.add(email1);
      CommonWSPayload.Email email2 = new CommonWSPayload.Email();
      email2.type = 'Secondary';
      email2.email = 'TEst@test.com';
      emails.add(email2);
      // WHEN the getEmail method is called
      Test.startTest();
      String primaryEmail = CommonWSPayload.getEmail(emails, 'Primary');
      String secondaryEmail = CommonWSPayload.getEmail(
        emails,
        'Secondary'
      );
      String missingTypeEmail = CommonWSPayload.getEmail(
        emails,
        'Missing'
      );
      Test.stopTest();

      //THEN the expected email is returned
      Assert.areEqual('bob@bob.com', primaryEmail);
      Assert.areEqual('TEst@test.com', secondaryEmail);
      //THEN no email is returned
      Assert.areEqual('', missingTypeEmail);
    }
  }

  /**
   * @description test APNGApplicantPayload.getPhoneNumber
   * @author Ben Greenland | 2024-08-26
   **/
  @isTest
  static void testGetPhoneNumber() {
    User testUser = getTestUser();
    System.runAs(testUser) {
      //GIVEN: multiple phine numbers
      List<CommonWSPayload.Phone> phones = new List<CommonWSPayload.Phone>();
      CommonWSPayload.Phone phone1 = new CommonWSPayload.Phone();
      phone1.type = 'MOBILE';
      phone1.phoneNumber = '0412123123';
      phones.add(phone1);

      CommonWSPayload.Phone phone2 = new CommonWSPayload.Phone();
      phone2.type = 'Work';
      phone2.phoneNumber = '+41 3123123123';
      phones.add(phone2);
      // WHEN the getPhoneNumber method is called
      Test.startTest();
      String phoneNumber = CommonWSPayload.getPhoneNumber(
        phones,
        'MOBILE'
      );
      String phoneNumber1 = CommonWSPayload.getPhoneNumber(
        phones,
        'Kittens'
      );
      Test.stopTest();
      //THEN the correct phone number is returned
      Assert.areEqual(
        '0412123123',
        phoneNumber,
        'MOBILE Phone number should match the provided type'
      );
      Assert.areEqual(
        '',
        phoneNumber1,
        'Phone number should match the provided type'
      );
    }
  }

  /**
   * @description test APNGApplicantPayload.parseApplicantToResponse
   * @author Ben Greenland | 2024-08-26
   **/
  @isTest
  public static void testparseApplicantToResponse() {
    User testUser = getTestUser();
    System.runAs(testUser) {
      //GIVEN a contact object record
      Contact con = getTestContact();
      triggerCommon.disableTrigger('Contact');
      insert con;
      triggerCommon.enableTrigger('Contact');

      con = [
        SELECT
          Id,
          FirstName,
          LastName,
          middleName,
          First_Name__c,
          Last_Name__c,
          Birthdate,
          Previous_Surname__c,
          Previous_Firstname__c,
          Previous_Monash_ID__c,
          Previously_Studied_at_Monash__c,
          MobilePhone,
          Personal_Email__c,
          Email,
          CRM_Id__c,
          AccountId,
          Preferred_Name__c,
          Gender__c
        FROM Contact
        WHERE Id = :con.Id
        LIMIT 1
      ];
      Test.startTest();
      // WHEN parseApplicantToResponse is called
      APNGApplicantPayload.ApplicantResponse response = APNGApplicantPayload.parseApplicantToResponse(
        con
      );
      //THEN record is mapped to wrapper class
      Assert.areEqual(
        'TestFirstName',
        response.firstName,
        'Incorrect first name'
      );
      Assert.areEqual('TestLastName', response.lastName, 'Incorrect last name');
      Assert.areEqual(
        '2009-12-31',
        response.dateOfBirth,
        'Incorrect date of birth'
      );
      Assert.areEqual(
        'PreviousSurname',
        response.previousName,
        'Incorrect previous surname'
      );
      Assert.areEqual(
        '123456',
        response.previousMonashId,
        'Incorrect previous Monash ID'
      );
      Assert.areEqual(
        true,
        response.isPreviousMonashStudent,
        'Incorrect previous Monash student status'
      );
      Assert.areEqual('0412345678', response.Phone, 'Incorrect phone number');
      Assert.areEqual(
        'test@email.com',
        response.Email,
        'Incorrect email address'
      );
      Assert.isNotNull(response.externalId, 'is null CRM ID');

      Test.stopTest();
    }
  }

  /**
   * @description test parseApplicantToContact()
   * @description tests parsing of a valid APNGApplicantPayload.Applicant record to a contact record
   * @author Ben Greenland | 2024-09-03
   **/
  @isTest
  static void testParseApplicantToContact() {
    User testUser = getTestUser();
    System.runAs(testUser) {
      //GIVEN APNGApplicantPayload with applicant data
      APNGApplicantPayload.Applicant app = getApplicant();
      Contact con = new Contact();
      Test.startTest();
      //WHEN parseApplicantToContact is called
      con = APNGApplicantPayload.parseApplicantToContact(app);
      Test.stopTest();
      //THEN record is mapped to contact object record
      Assert.areEqual('John', con.FirstName, 'Incorrect first name');
      Assert.areEqual('Doe', con.LastName, 'Incorrect last name');
      Assert.areEqual('John', con.First_Name__c, 'First name should match');
      Assert.areEqual('Doe', con.Last_Name__c, 'Last name should match');
      Assert.areEqual(
        'Jane',
        con.Previous_Surname__c,
        'Previous surname should match'
      );
      Assert.areEqual(
        '12345',
        con.Previous_Monash_ID__c,
        'Previous Monash ID should match'
      );
      Assert.areEqual(
        true,
        con.Previously_Studied_at_Monash__c,
        'Previously studied at Monash should be true'
      );
      Assert.areEqual(
        '0412345678',
        con.MobilePhone,
        'Mobile phone number should match'
      );
      Assert.areEqual(
        'johndoe@example.com',
        con.Personal_Email__c,
        'Email address should match'
      );
    }
  }

    /**
    * @description test PatchResponse
    * @author Ben Greenland | 2024-10-16 
    **/
  @IsTest
    static void testPatchResponse() {
        // GIVEN a new PatchResponse object
        APNGApplicantPayload.PatchResponse response = new APNGApplicantPayload.PatchResponse();
        
        // WHEN setting the applicant and message
        APNGApplicantPayload.ApplicantPatchResponse applicantResponse = new APNGApplicantPayload.ApplicantPatchResponse();
        applicantResponse.firstName = 'John';
        applicantResponse.lastName = 'Doe';
        applicantResponse.dateOfBirth = '1990-01-01';
        applicantResponse.externalId = 'EXT123';
        applicantResponse.aboriginalOrTorresStraitIslander = 'Yes';
        response.applicant = applicantResponse;
        response.message = 'Update successful';

        // THEN the response should contain the correct information
        Assert.isNotNull(response.applicant, 'Applicant should not be null');
        Assert.areEqual('John', response.applicant.firstName, 'First name should match');
        Assert.areEqual('Doe', response.applicant.lastName, 'Last name should match');
        Assert.areEqual('1990-01-01', response.applicant.dateOfBirth, 'Date of birth should match');
        Assert.areEqual('EXT123', response.applicant.externalId, 'External ID should match');
        Assert.areEqual('Yes', response.applicant.aboriginalOrTorresStraitIslander, 'Aboriginal or Torres Strait Islander should match');
        Assert.areEqual('Update successful', response.message, 'Message should match');

        // WHEN serializing the response
        String jsonResponse = JSON.serialize(response);

        // THEN the JSON should contain the expected fields
        Assert.isTrue(jsonResponse.contains('"firstName":"John"'), 'JSON should contain firstName');
        Assert.isTrue(jsonResponse.contains('"lastName":"Doe"'), 'JSON should contain lastName');
        Assert.isTrue(jsonResponse.contains('"dateOfBirth":"1990-01-01"'), 'JSON should contain dateOfBirth');
        Assert.isTrue(jsonResponse.contains('"externalId":"EXT123"'), 'JSON should contain externalId');
        Assert.isTrue(jsonResponse.contains('"message":"Update successful"'), 'JSON should contain message');
        
    }

  /**
   * @description test post request is created as an APNG user
   * @author Ben Greenland | 2024-09-03
   **/
  @istest
  static void testPostRequest() {
    User testUser = getTestUser();
    System.runAs(testUser) {
      //GIVEN APNGApplicantPayload with applicant data
      APNGApplicantPayload.PostRequest req;
      APNGApplicantPayload.Applicant applicant = getApplicant();
      //WHEN request is made
      req = new APNGApplicantPayload.PostRequest();
      req.applicant = applicant;
      //THEN request is successful
      Assert.isNotNull(req, 'Request should be successful');
    }
  }

  /**
   * @description Test Post response
   * @author Ben Greenland | 2024-09-03
   **/
  @istest
  static void testPostRestponse() {
    User testUser = getTestUser();
    System.runAs(testUser) {
      //GIVEN APNGApplicantPayload with applicant data
      APNGApplicantPayload.PostResponse resp;
      APNGApplicantPayload.ApplicantResponse applicantResponse = APNGApplicantPayload.parseApplicantToResponse(
        getTestContact()
      );
      //WHEN request is made
      resp = new APNGApplicantPayload.PostResponse();
      resp.applicant = applicantResponse;
      resp.message = 'helo';
      //THEN request is successful
      Assert.isNotNull(resp, 'Response should be successful');
    }
  }
  /**
   * @description Test creating a Contact from a PatchRequest
   * @author Ben G
   * @date 2024-09-05
   */
  @isTest
 static void testCreateContactFromPatchRequest() {
        // GIVEN a PatchRequest with sample data
        Country_Attribute__c country = [SELECT Id FROM Country_Attribute__c WHERE Country__c = 'AUSTRALIA' LIMIT 1];
        APNGApplicantPayload.PatchRequest req = new APNGApplicantPayload.PatchRequest();
        req.contactId = fflib_IDGenerator.generate(Contact.SObjectType); // Sample Contact Id
        req.lastName = 'Doe';
        req.firstName = 'John';
        req.title = 'Mr.';
        req.dateOfBirth = '1990-01-01';
        req.isPreviousMonashStudent = true;
        req.preferredName = 'Johnny';
        req.aboriginalOrTorresStraitIslander = 'Yes';
        req.previousName = 'Smith';
        req.previousMonashId = 'M12345';
        req.pronoun = 'He/Him';
        req.gender = 'Male';
        // Create test data for phone
        CommonWSPayload.Phone phone1 = new CommonWSPayload.Phone();
        phone1.type = 'Mobile';
        phone1.phoneNumber = '1234567890';
        CommonWSPayload.Phone phone2 = new CommonWSPayload.Phone();
        phone2.type = 'Home';
        phone2.phoneNumber = '0987654321';
        req.phone = new List<CommonWSPayload.Phone>{ phone1, phone2 };
        // Create test data for email
        CommonWSPayload.Email email1 = new CommonWSPayload.Email();
        email1.type = 'Personal';
        email1.email = 'john.doe@example.com';
        req.email = new List<CommonWSPayload.Email>{ email1 };

        CommonWSPayload.Address postalAddress = new CommonWSPayload.Address();
        postalAddress.type = 'Postal';
        postalAddress.street = '123 Main St';
        postalAddress.city = 'City';
        postalAddress.state = 'State';
        postalAddress.country = 'Country';
        postalAddress.postalCode = '12345';

        CommonWSPayload.Address otherAddress = new CommonWSPayload.Address();
        otherAddress.type = 'Other';
        otherAddress.street = '456 Elm St';
        otherAddress.city = 'OtherCity';
        otherAddress.state = 'OtherState';
        otherAddress.country = 'OtherCountry';
        otherAddress.postalCode = '67890';

        req.address = new List<CommonWSPayload.Address>{ postalAddress, otherAddress };

        CommonWSPayload.Country countryPayload = new CommonWSPayload.Country();
        countryPayload.crmRecordId = country.Id;
        req.countryOfBirth = countryPayload;

        // WHEN createContactFromPatchRequest is called
        Contact result = req.createContactFromPatchRequest();

        // THEN the resulting Contact should have the correct field values
        Assert.areEqual(req.contactId, result.Id, 'Contact Id should match the request');
        Assert.areEqual(req.lastName, result.LastName, 'Last Name should match the request');
        Assert.areEqual(req.firstName, result.FirstName, 'First Name should match the request');
        Assert.areEqual(req.title, result.Salutation, 'Title should match the request');
        Assert.areEqual(req.dateOfBirth, String.valueOf(result.Birthdate), 'Date of Birth should match the request');
        Assert.areEqual(req.isPreviousMonashStudent, result.Previously_Studied_at_Monash__c, 'Previous Monash Student status should match the request');
        Assert.areEqual(req.preferredName, result.Preferred_Name__c, 'Preferred Name should match the request');
        Assert.areEqual(req.aboriginalOrTorresStraitIslander, result.Aboriginal_or_Torres_Strait_Islander__c, 'Aboriginal or Torres Strait Islander status should match the request');
        Assert.areEqual(req.previousName, result.Previous_Surname__c, 'Previous Name should match the request');
        Assert.areEqual(req.previousMonashId, result.Previous_Monash_ID__c, 'Previous Monash ID should match the request');
        Assert.areEqual(req.pronoun, result.Pronouns_V2__c, 'Pronoun should match the request');
        Assert.areEqual(req.gender, result.Gender__c, 'Gender should match the request');
        Assert.areEqual('1234567890', result.MobilePhone, 'Mobile Phone should match the request');
        Assert.areEqual('0987654321', result.HomePhone, 'Home Phone should match the request');
        Assert.areEqual('john.doe@example.com', result.Personal_Email__c, 'Personal Email should match the request');
        Assert.areEqual('123 Main St', result.MailingStreet, 'Mailing Street should match the request');
        Assert.areEqual('City', result.MailingCity, 'Mailing City should match the request');
        Assert.areEqual('State', result.MailingState, 'Mailing State should match the request');
        Assert.areEqual('Country', result.MailingCountry, 'Mailing Country should match the request');
        Assert.areEqual('12345', result.MailingPostalCode, 'Mailing Postal Code should match the request');
        Assert.areEqual('456 Elm St', result.OtherStreet, 'Other Street should match the request');
        Assert.areEqual('OtherCity', result.OtherCity, 'Other City should match the request');
        Assert.areEqual('OtherState', result.OtherState, 'Other State should match the request');
        Assert.areEqual('OtherCountry', result.OtherCountry, 'Other Country should match the request');
        Assert.areEqual('67890', result.OtherPostalCode, 'Other Postal Code should match the request');

        Assert.areEqual(req.firstName, result.First_name__c, 'First Name should match the request');
        Assert.areEqual(req.lastName, result.Last_name__c, 'Last Name should match the request');
        Assert.areEqual(req.firstName, result.firstname, 'First Name should match the request');
        Assert.areEqual(req.lastName, result.lastname, 'Last Name should match the request');
        Assert.areEqual(req.countryOfBirth.crmRecordId, result.CountryOfBirth__c, 'Country of Birth should match the request');
    }

  /**
   * @description get a Test Applicant Wrapper object
   * @author Ben Greenland | 2024-09-03
   * @return APNGApplicantPayload.Applicant
   **/
  private static APNGApplicantPayload.Applicant getApplicant() {
    APNGApplicantPayload.Applicant app = new APNGApplicantPayload.Applicant();
    app.firstName = 'John';
    app.lastName = 'Doe';
    app.dateOfBirth = '2009-12-31';
    app.previousName = 'Jane';
    app.previousFirstName = 'Jane';
    app.previousMonashId = '12345';
    app.isPreviousMonashStudent = true;
    CommonWSPayload.Phone phone = new CommonWSPayload.Phone();
    phone.phoneNumber = '0412345678';
    phone.type = 'Mobile';
    app.phone = new List<CommonWSPayload.Phone>{ phone };
    CommonWSPayload.Email email = new CommonWSPayload.Email();
    email.email = 'johndoe@example.com';
    email.type = 'Personal';
    app.email = new List<CommonWSPayload.Email>{ email };
    return app;
  }

  /**
   * @description get a test Contact
   * @author Ben Greenland | 2024-09-03
   * @return Contact
   **/
  private static Contact getTestContact() {
    //GIVEN a contact object record
    return new Contact(
      FirstName = 'TestFirstName',
      First_Name__c = 'TestFirstName',
      LastName = 'TestLastName',
      Last_Name__c = 'TestLastName',
      Birthdate = Date.parse('31/12/2009'),
      Previous_Surname__c = 'PreviousSurname',
      Previous_Monash_ID__c = '123456',
      Previously_Studied_at_Monash__c = true,
      MobilePhone = '0412345678',
      Personal_Email__c = 'test@email.com'
    );
  }

  /**
   * @description gets the test user
   * @author Ben Greenland | 2024-09-03
   * @return User
   **/
  private static User getTestUser() {
    User testUser = [
      SELECT Id
      FROM User
      WHERE Email = 'testAgentLastName@TestEmail.com'
      LIMIT 1
    ][0];
    return testUser;
  }
}