/**
 * @description       : Test class for OESApplicantPayload really only needs coverage as little logic in wrapper
 * @author            : Ben Greenland
 * @group             : Admissions
 * @last modified on  : 2024-11-25
 * @last modified by  : Ben Greenland
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2024-08-26   Ben Greenland   Initial Version
**/

@isTest(isParallel=false)//false due to PermissionSetAssignment
private class OESApplicantPayload_Test {

    @TestSetup
    static void makeData() {
        //create OES User
        TriggerCommon.disableTrigger('Country_Attribute__c');
        TriggerCommon.disableTrigger('Account');
        TriggerCommon.disableTrigger('Contact');
        TriggerCommon.disableTrigger('User');

        AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();
        PermissionSet oesPs = [SELECT Id 
                            FROM PermissionSet 
                            WHERE Name = 'OES_Permission_Set'];
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = portalUser.testUser.Id,
            PermissionSetId = oesPs.Id
        );

                  // create a test Country
        AgentPortalTestDataFactory factory = new AgentPortalTestDataFactory();
        Country_Attribute__c country = factory.createCountryAttribute(
        BDPConstants.AUSTRALIA_CALLISTA_CODE,
        'AUSTRALIA'
        );
        insert country;

        // avoid MIXED_DML_OPERATION
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert psa;
        }
        
        TriggerCommon.enableTrigger('Country_Attribute__c');
        TriggerCommon.enableTrigger('Account');
        TriggerCommon.enableTrigger('Contact');
        TriggerCommon.enableTrigger('User');
    }
    
    /**
    * @description test CommonWSPayload.getEmail
    * @author Ben Greenland | 2024-08-26 
    **/
@isTest
    static void testGetEmail() {
        System.runAs(getTestUser()){
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
            String secondaryEmail = CommonWSPayload.getEmail(emails, 'Secondary');
            String missingTypeEmail = CommonWSPayload.getEmail(emails, 'Missing');
            Test.stopTest();

            //THEN the expected email is returned
            Assert.areEqual('bob@bob.com', primaryEmail);
            Assert.areEqual('TEst@test.com', secondaryEmail);
            //THEN no email is returned
            Assert.areEqual('', missingTypeEmail);
        }
    }
    /**
    * @description test CommonWSPayload.getPhoneNumber
    * @author Ben Greenland | 2024-08-26 
    **/
  
    @isTest
    static void testGetPhoneNumber() {
        System.runAs(getTestUser()){
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
            String phoneNumber = CommonWSPayload.getPhoneNumber(phones, 'MOBILE');
            String phoneNumber1 = CommonWSPayload.getPhoneNumber(phones, 'Kittens');
            Test.stopTest();
            //THEN the correct phone number is returned
            Assert.areEqual('0412123123', phoneNumber, 'MOBILE Phone number should match the provided type');
            Assert.areEqual('', phoneNumber1, 'Phone number should match the provided type');
        }
    }
    /**
    * @description test OESApplicantPayload.parseApplicantToResponse
    * @author Ben Greenland | 2024-08-26 
    **/
    @isTest
    public static void testparseApplicantToResponse() {
        System.runAs(getTestUser()){
        //GIVEN a contact object record
        Contact con = getTestContact();
        triggerCommon.disableTrigger('Contact');
        insert con;
        triggerCommon.enableTrigger('Contact');
        
        con = [SELECT Id, FirstName, LastName,First_Name__c, Last_Name__c, Birthdate, Previous_Surname__c, 
                Previous_Monash_ID__c, Previously_Studied_at_Monash__c, MobilePhone, Personal_Email__c,
                Email, CRM_Id__c,Is_Mononymous_Name__c FROM Contact WHERE Id = :con.Id LIMIT 1];
        Test.startTest();
        // WHEN parseApplicantToResponse is called
            OESApplicantPayload.ApplicantResponse response = OESApplicantPayload.parseApplicantToResponse(con);
        //THEN record is mapped to wrapper class
            Assert.areEqual('TestFirstName', response.firstName, 'Incorrect first name');
            Assert.areEqual('TestLastName', response.lastName, 'Incorrect last name');
            Assert.areEqual('2009-12-31', response.dateOfBirth, 'Incorrect date of birth');
            Assert.areEqual('PreviousSurname', response.previousName, 'Incorrect previous surname');
            Assert.areEqual('123456', response.previousMonashId, 'Incorrect previous Monash ID');
            Assert.areEqual(true, response.isPreviousMonashStudent, 'Incorrect previous Monash student status');
            Assert.areEqual('0412345678', response.Phone, 'Incorrect phone number');
            Assert.areEqual('test@email.com', response.Email, 'Incorrect email address');
            Assert.isNotNull ( response.externalId, 'is null CRM ID');

        Test.stopTest();
        }
    }

    @isTest
    static void testParseApplicantToContact() {
        System.runAs(getTestUser()){
            //GIVEN OESApplicantPayload with applicant data 
            OESApplicantPayload.Applicant app = getApplicant();
            Contact con = new Contact();
            Test.startTest();
            //WHEN parseApplicantToContact is called
            con = OESApplicantPayload.parseApplicantToContact(app);
            Test.stopTest();
            //THEN record is mapped to contact object record
            Assert.areEqual('John', con.FirstName, 'Incorrect first name');
            Assert.areEqual('Doe', con.LastName, 'Incorrect last name');
            Assert.areEqual('John', con.First_name__c, 'First name should match');
            Assert.areEqual('Doe', con.Last_name__c, 'Last name should match');
            Assert.areEqual('Jane', con.Previous_Surname__c, 'Previous surname should match');
            Assert.areEqual('12345', con.Previous_Monash_ID__c, 'Previous Monash ID should match');
            Assert.areEqual(true, con.Previously_Studied_at_Monash__c, 'Previously studied at Monash should be true');
            Assert.areEqual('0412345678', con.MobilePhone, 'Mobile phone number should match');
            Assert.areEqual('johndoe@example.com', con.Personal_Email__c, 'Email address should match');
        }
    }

    @istest
     static void testPostRequest() {
        System.runAs(getTestUser()){
            //GIVEN OESApplicantPayload with applicant data 
            OESApplicantPayload.PostRequest req;
            OESApplicantPayload.Applicant applicant = getApplicant();
            //WHEN request is made
            req = new OESApplicantPayload.PostRequest();
            req.applicant = applicant;
            //THEN request is successful
            Assert.isNotNull(req, 'Request should be successful');
        }
    }

    @istest
     static void testPostRestponse() {
        System.runAs(getTestUser()){
            //GIVEN OESApplicantPayload with applicant data 
            OESApplicantPayload.PostResponse resp;
            OESApplicantPayload.ApplicantResponse applicantResponse = OESApplicantPayload.parseApplicantToResponse(getTestContact());
            //WHEN request is made
            resp = new OESApplicantPayload.PostResponse();
            resp.applicant = applicantResponse;
            resp.message = 'helo';
            //THEN request is successful
            Assert.isNotNull(resp, 'Response should be successful');
        }
    }

   

  /**
   * @description Test that ApplicantDetails can be properly initialized
   */
  @isTest
  static void shouldCreateApplicantDetails() {
    // GIVEN : an applicant variable
    OESApplicantPayload.ApplicantDetails applicant;
    System.runAs(getTestUser()){
        Test.startTest();

        // WHEN : I initialize
        applicant = new OESApplicantPayload.ApplicantDetails(
        new Contact(First_Name__c = 'Applicant FN', Last_Name__c = 'Applicant LN')
        );
        applicant.isEditable = false;

        Test.stopTest();
    }
    // THEN : initialization successful
    Assert.isNotNull(
      applicant,
      'Unable to initialize OESApplicantPayload.ApplicantDetails'
    );
  }

  @isTest
   static void testCreateContactFromPatchRequest() {
        // GIVEN a PatchRequest with sample data
        Country_Attribute__c country = [SELECT uniqueCountryExternalId__c,Name FROM Country_Attribute__c WHERE Country__c = 'AUSTRALIA' LIMIT 1];
        OESApplicantPayload.PatchRequest req = new OESApplicantPayload.PatchRequest();
        req.contactId = '003000000000001AAA'; // Sample Contact Id
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

           // New fields
        req.crmContactId = 'CRM123';
        req.smsContactId = 'SMS456';
        req.countryOfResidence = 'Australia';
        req.isDeceased = false;
        req.broadAreaOfInterest = 'Science';
        req.highestEducationLevel = 'Bachelor Degree';
        req.leadSource = 'Web';
        req.sourceSystem = 'OES';
        req.specificAreaOfInterest = 'Physics';
        req.disallowedFieldUpdated = false;
        req.hasMononymousName = false;
        req.broadAreaOfInterest = 'Bunyips';

        // Create Phone objects without constructor
        CommonWSPayload.Phone mobilePhone = new CommonWSPayload.Phone();
        mobilePhone.type = 'Mobile';
        mobilePhone.phoneNumber = '1234567890';
        CommonWSPayload.Phone homePhone = new CommonWSPayload.Phone();
        homePhone.type = 'Home';
        homePhone.phoneNumber = '0987654321';
        req.phone = new List<CommonWSPayload.Phone>{ mobilePhone, homePhone };

        // Create Email object without constructor
        CommonWSPayload.Email personalEmail = new CommonWSPayload.Email();
        personalEmail.type = 'Personal';
        personalEmail.email = 'john.doe@example.com';
        req.email = new List<CommonWSPayload.Email>{ personalEmail };

        // Create Address objects without constructor
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
        countryPayload.uniqueCountryExternalId = country.uniqueCountryExternalId__c;
        req.countryOfBirth = countryPayload;

        // WHEN createContactFromPatchRequest is called
        Contact result = req.createContactFromPatchRequest();

        // THEN the resulting Contact should have the correct field values
        Assert.areEqual(req.contactId, result.Id, 'Contact Id should match the request');
        Assert.areEqual(req.lastName, result.LastName, 'Last Name should match the request');
        Assert.areEqual(req.firstName, result.FirstName, 'First Name should match the request');
        Assert.areEqual(req.lastName, result.Last_Name__c, 'Last Name should match the request');
        Assert.areEqual(req.firstName, result.First_Name__c, 'First Name should match the request');
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
        Assert.areEqual(country.uniqueCountryExternalId__c, result.CountryOfBirth__r.uniqueCountryExternalId__c, 'Country of Birth should match the request');

         //  field assertions for additional fields
    Assert.areEqual(req.countryOfResidence, result.Country_of_Residence__c, 'Country of Residence should match');
    Assert.areEqual(req.isDeceased, result.Deceased__c, 'Deceased status should match');
    Assert.areEqual(req.broadAreaOfInterest, result.Broad_area_s_of_interest__c, 'Broad Area of Interest should match');
    Assert.areEqual(req.highestEducationLevel, result.Highest_level_of_education_to_date__c, 'Highest Education Level should match');
    Assert.areEqual(req.specificAreaOfInterest, result.Specific_area_s_of_interest__c, 'Specific Area of Interest should match');
    }

     @isTest
    static void testParseApplicantToPatchResponse() {
        // GIVEN a Contact with sample data
        Contact con = new Contact(
            Id = '003000000000001AAA',
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Birthdate = Date.newInstance(1990, 1, 1),
            Previously_Studied_at_Monash__c = true,
            Preferred_Name__c = 'Johnny',
            Previous_Surname__c = 'Smith',
            Previous_Monash_ID__c = 'M12345',
            Gender__c = 'Male',
            MobilePhone = '1234567890',
            Personal_Email__c = 'john.doe@example.com',
            MiddleName = 'Middle',
            AccountId = '001000000000001AAA'
        );

        // WHEN parseApplicantToPatchResponse is called
        OESApplicantPayload.ApplicantPatchResponse result = OESApplicantPayload.parseApplicantToPatchResponse(con);

        // THEN the resulting ApplicantPatchResponse should have the correct field values
        Assert.areEqual('John', result.firstName, 'First Name should match the Contact');
        Assert.areEqual('Doe', result.lastName, 'Last Name should match the Contact');
        Assert.areEqual('1990-01-01', result.dateOfBirth, 'Date of Birth should match the Contact');
        Assert.areEqual(true, result.isPreviousMonashStudent, 'Previous Monash Student status should match the Contact');
        Assert.areEqual('Johnny', result.preferredName, 'Preferred Name should match the Contact');
        Assert.areEqual('Smith', result.previousName, 'Previous Name should match the Contact');
        Assert.areEqual('M12345', result.previousMonashId, 'Previous Monash ID should match the Contact');
        Assert.areEqual('Male', result.gender, 'Gender should match the Contact');
        Assert.areEqual('1234567890', result.Phone, 'Phone should match the Contact');
        Assert.areEqual('john.doe@example.com', result.Email, 'Email should match the Contact');
        Assert.areEqual('Middle', result.middleName, 'Middle Name should match the Contact');
        Assert.areEqual('001000000000001AAA', result.accountId, 'Account ID should match the Contact');
    }

    @isTest
    static void testPatchResponse() {
        // GIVEN a PatchResponse with sample data
        OESApplicantPayload.PatchResponse response = new OESApplicantPayload.PatchResponse();
        OESApplicantPayload.ApplicantPatchResponse applicantResponse = new OESApplicantPayload.ApplicantPatchResponse();
        applicantResponse.firstName = 'John';
        applicantResponse.lastName = 'Doe';
        applicantResponse.dateOfBirth = '1990-01-01';
        applicantResponse.externalId = 'EXT123';
        response.applicant = applicantResponse;
        response.message = 'Update successful';

        // WHEN accessing the PatchResponse fields
        // THEN the fields should have the correct values
        Assert.areNotEqual(null, response.applicant, 'Applicant should not be null');
        Assert.areEqual('John', response.applicant.firstName, 'First name should match');
        Assert.areEqual('Doe', response.applicant.lastName, 'Last name should match');
        Assert.areEqual('1990-01-01', response.applicant.dateOfBirth, 'Date of birth should match');
        Assert.areEqual('EXT123', response.applicant.externalId, 'External ID should match');
        Assert.areEqual('Update successful', response.message, 'Message should match');
    }

     
     

     /**
     * @description helper to create a test applicant
     * @author Ben Greenland | 2024-09-03 
     * @return OESApplicantPayload.Applicant 
     **/
     private static OESApplicantPayload.Applicant getApplicant(){
        OESApplicantPayload.Applicant app = new OESApplicantPayload.Applicant();
        app.firstName = 'John';
        app.lastName = 'Doe';
        app.dateOfBirth ='2009-12-31';
        app.previousName = 'Jane';
        app.previousMonashId = '12345';
        app.isPreviousMonashStudent = true;
        CommonWSPayload.Phone phone = new CommonWSPayload.Phone();
        phone.phoneNumber =  '0412345678';
        phone.type ='Mobile';
        app.phone = new List<CommonWSPayload.Phone>{
            phone
        };
        CommonWSPayload.Email email = new CommonWSPayload.Email();
        email.email = 'johndoe@example.com';
        email.type = 'Personal';
        app.email = new List<CommonWSPayload.Email>{
            email
        };
        return app;
     }

     /**
     * @description helper to create a test contact
     * @author Ben Greenland | 2024-09-03 
     * @return Contact 
     **/
     private static Contact getTestContact(){
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
  private static User getTestUser(){
    User testUser = [
      SELECT Id
      FROM User
      WHERE Email = 'testAgentLastName@TestEmail.com'
      LIMIT 1
    ][0];
    return testUser;
  }
}