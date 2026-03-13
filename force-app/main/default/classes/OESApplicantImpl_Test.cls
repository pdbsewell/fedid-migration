/**
 * @description Test class for OESApplicantImpl.
 * @author      Nick Guia
 * @since       AUG.02.2024
 */
@isTest(isParallel=false) //false for user
private class OESApplicantImpl_Test {
  @TestSetup
  static void makeData() {
    AgentPortalTestDataFactory factory = new AgentPortalTestDataFactory();
    //create OES User
    TriggerCommon.disableTrigger('Country_Attribute__c');
    TriggerCommon.disableTrigger('Account');
    TriggerCommon.disableTrigger('Contact');
    TriggerCommon.disableTrigger('User');

    AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser()
      .build();
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
    // create a test Country
    Country_Attribute__c country = factory.createCountryAttribute(
      BDPConstants.AUSTRALIA_CALLISTA_CODE,
      'AUSTRALIA'
    );
    insert country;

    // create test Contact
    Contact applicant = factory.createApplicantContact();
    applicant.FirstName = '(FN) Editable';
    applicant.LastName = '(LN) Applicant';
    applicant.First_Name__c = applicant.FirstName;
    applicant.Last_Name__c = applicant.LastName;
    applicant.Salutation = 'Mr';
    applicant.Pronouns_V2__c = 'He/Him/His';
    applicant.Suffix = 'Jr';
    applicant.Preferred_Name__c = 'Nickname';
    applicant.Gender__c = 'Male';
    applicant.OtherStreet = 'Some other street';
    applicant.OtherCity = 'Clayton';
    applicant.OtherState = 'Victoria';
    applicant.OtherCountry = 'Australia';
    applicant.OtherPostalCode = '3168';
    applicant.HomePhone = '04444444444';
    applicant.Previous_Surname__c = 'Some Previous Surname';
    applicant.Previous_Monash_ID__c = 'PREVIOUS_ID';
    applicant.Previously_Studied_at_Monash__c = false;
    applicant.Aboriginal_or_Torres_Strait_Islander__c = 'NO';
    applicant.CountryOfBirth__r = country;
    System.runAs(portalUser.testUser) {
      insert applicant;
    }

    TriggerCommon.enableTrigger('Country_Attribute__c');
    TriggerCommon.enableTrigger('Account');
    TriggerCommon.enableTrigger('Contact');
    TriggerCommon.enableTrigger('User');
  }

  /**
   * @description test boiler plate code - getHandleGet()
   */
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  @isTest
  static void shouldReturnHandleGet() {
    // GIVEN : a HandleGet instance
    RESTlib_ClientImplHandler handler;
    System.runAs(getTestUser()) {
      Test.startTest();

      // WHEN : I invoke getHandleGet()
      OESApplicantImpl impl = new OESApplicantImpl();
      handler = impl.getHandleGet();

      Test.stopTest();
    }

    // THEN : Put is not expected to be implemented yet
    Assert.isTrue(handler == null, 'Unexpected Get implementation');
  }

  /**
   * @description test boiler plate code - getHandlePost()
   */

  @isTest
  static void shouldReturnHandlePost() {
    // GIVEN : a HandleGet instance
    OESApplicantImpl.HandlePost handler;
    //WHEN The method is executed as an OES user.
    User testUser = getTestUser();
    System.runAs(testUser) {
      Test.startTest();

      // WHEN : I invoke getHandlePost()
      OESApplicantImpl impl = new OESApplicantImpl();
      handler = (OESApplicantImpl.HandlePost) impl.getHandlePost();

      Test.stopTest();
    }

    // THEN : it should return the class instance which extends to RESTlib_ClientImplHandler
    Assert.isNotNull(handler, 'Unable to get HandlePost()');
    Assert.isInstanceOfType(
      handler,
      RESTlib_ClientImplHandler.class,
      'HandleGet be an instance of RESTlib_ClientImplHandler'
    );
  }

  /**
   * @description This test method verifies the functionality of the handlePost method in the OESApplicantImpl class.
   * @author Ben Greenland | 2024-08-27
   **/
  @isTest
  static void handlePostCreateApplicant() {
    //GIVEN: An Applicant Create Request is prepared and serialized into a RestRequest.
    OESApplicantPayload.PostRequest postRequestPayload = createPostRequestPayload();
    RestRequest request = new RestRequest();
    request.httpMethod = 'POST';
    request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
    RestContext.request = request;

    //WHEN The method is executed as an OES user.
    User testUser = getTestUser();
    System.runAs(testUser) {
      RestResponse response = new RestResponse();
      RestContext.response = response;

      Test.startTest();
      RESTlib_ClientImplHandler clientImplHandler = new OESApplicantImpl()
        .getHandlePost();
      clientImplHandler.setPayloadType(
        OESApplicantPayload.PostRequest.class,
        OESApplicantPayload.PostResponse.class
      );
      clientImplHandler.execute();
      Test.stopTest();

      String responseBodyString = response.responseBody.toString();
      // Deserialize string to custom payload class
      OESApplicantPayload.PostResponse customResponse = (OESApplicantPayload.PostResponse) JSON.deserialize(
        responseBodyString,
        OESApplicantPayload.PostResponse.class
      );
      Assert.isTrue(customResponse.success, 'Expected success to be true');
    }
    //THEN A contact is expected to be successfully created in the system.
    List<Contact> result = [
      SELECT Id
      FROM Contact
      WHERE Previous_Monash_ID__c = '12345'
    ];
    Assert.isTrue(result.size() == 1, 'Expected a  Contact to be created');
  }

  @isTest
  static void handlePostCreateApplicantFailue() {
    //GIVEN: An Applicant Create Request is prepared and serialized into a RestRequest with bad data
    OESApplicantPayload.PostRequest postRequestPayload = createPostRequestPayload();
    postRequestPayload.applicant.dateOfBirth = 'xxxxxx'; // create a bad payload
    RestRequest request = new RestRequest();
    request.httpMethod = 'POST';
    request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
    RestContext.request = request;

    //WHEN The method is executed as an OES user.
    System.runAs(getTestUser()) {
      RestResponse response = new RestResponse();
      RestContext.response = response;

      Test.startTest();
      RESTlib_ClientImplHandler clientImplHandler = new OESApplicantImpl()
        .getHandlePost();
      clientImplHandler.setPayloadType(
        OESApplicantPayload.PostRequest.class,
        OESApplicantPayload.PostResponse.class
      );
      clientImplHandler.execute();
      Test.stopTest();

      String responseBodyString = response.responseBody.toString();
      // Deserialize string to custom payload class
      OESApplicantPayload.PostResponse customResponse = (OESApplicantPayload.PostResponse) JSON.deserialize(
        responseBodyString,
        OESApplicantPayload.PostResponse.class
      );
      //THEN An error response is returned.
      Assert.isFalse(customResponse.success, 'Expected success to be false');
      // Must create Nebula Log entry
      Assert.isTrue([SELECT Id, Nebula__OriginLocation__c FROM Nebula__LogEntry__c].size()>0);
    }
  }

  /**
   * @description test boiler plate code - getHandlePut()
   * NO IMPLEMENTATION YET
   */

  @isTest
  static void shouldReturnHandlePut() {
    // GIVEN : a Handler instance
    RESTlib_ClientImplHandler handler;
    System.runAs(getTestUser()) {
      Test.startTest();

      // WHEN : I invoke getHandleGet()
      OESApplicantImpl impl = new OESApplicantImpl();
      handler = impl.getHandlePut();

      Test.stopTest();
    }
    // THEN : Put is not expected to be implemented yet
    Assert.isTrue(handler == null, 'Unexpected Get implementation');
  }

  /**
   * @description test boiler plate code - getHandlePatch()
   */

  @isTest
  static void shouldReturnHandlePatch() {
    // GIVEN : a HandleGet instance
    OESApplicantImpl.HandlePatch handler;
    System.runAs(getTestUser()) {
      Test.startTest();

      // WHEN : I invoke getHandlePatch()
      OESApplicantImpl impl = new OESApplicantImpl();
      handler = (OESApplicantImpl.HandlePatch) impl.getHandlePatch();

      Test.stopTest();
    }

    // THEN : it should return the class instance which extends to RESTlib_ClientImplHandler
    Assert.isNotNull(handler, 'Unable to get HandlePatch()');
    Assert.isInstanceOfType(
      handler,
      RESTlib_ClientImplHandler.class,
      'HandleGet be an instance of RESTlib_ClientImplHandler'
    );
  }

  /**
   * @description
   */
  @isTest
  static void testRequestRespnseTypesForPost() {
    RESTlib_ClientImplHandler handler;
    System.runAs(getTestUser()) {
      Test.startTest();

      handler = new OESApplicantImpl().getHandlePost();
      handler.setPayloadType(
        OESApplicantPayload.PostRequest.class,
        OESApplicantPayload.PostResponse.class
      );
      Assert.areEqual(
        handler.getRequestType(),
        OESApplicantPayload.PostRequest.class,
        'Request type should match'
      );
      Assert.areEqual(
        handler.getResponseType(),
        OESApplicantPayload.PostResponse.class,
        'Response type should match'
      );

      Test.stopTest();
    }
  }

  /**
  * @description  null payload Exception test
  * @author Ben Greenland | 2024-10-20 
  **/
  @isTest
  static void nullPayloadShouldReturnException() {
    Test.startTest();
    try {
      APNGApplicantImpl.HandlePatch handler = new APNGApplicantImpl.HandlePatch();
      handler.getRequestType();
      handler.getResponseType();
      handler.process(null, null);
    } catch (Exception ex) {
      Assert.isTrue(
        ex.getMessage() == 'Error in patch payload',
        'Expected an Exception for a null payload'
      );
    }

    Test.stopTest();
  }

  /**
   * @description test patch request update an Applicant with an existing Submitted 
   * application
   * @author SMendu | 2025-06-03
   **/
  @IsTest
  static void handlePatchWithSubmittedApps() {
    //GIVEN: An Applicant Patch Request is prepared and serialized into a RestRequest.
    OESApplicantPayload.PatchRequest postRequestPayload = createPatchRequestPayload();
    RestRequest request = new RestRequest();
    request.httpMethod = 'PATCH';
    request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
    RestContext.request = request;
     Contact con = [
      SELECT Id, FirstName, LastName, CRM_ID__c, accountId, email, phone,Birthdate
      FROM Contact
      WHERE FirstName = '(FN) Editable'
      LIMIT 1
    ];
  

    //WHEN The method is executed as an OES user.
    User testUser = [
      SELECT ID
      FROM User
      WHERE Email = 'testAgentLastName@TestEmail.com'
      LIMIT 1
    ];
    System.runAs(testUser) {
    Application__c app = new Application__c( Applicant__c=con.Id, Status__c='Submitted');
    insert app;
      RestResponse response = new RestResponse();
      RestContext.response = response;

      Test.startTest();
      RESTlib_ClientImplHandler clientImplHandler = new OESApplicantImpl()
        .getHandlePatch();
      clientImplHandler.setPayloadType(
        OESApplicantPayload.PatchRequest.class,
        OESApplicantPayload.PatchResponse.class
      );
      clientImplHandler.execute();
      Test.stopTest();

      String responseBodyString = response.responseBody.toString();
      // Deserialize string to custom payload class
      OESApplicantPayload.PatchResponse customResponse = (OESApplicantPayload.PatchResponse) JSON.deserialize(
        responseBodyString,
        OESApplicantPayload.PatchResponse.class
      );
      Assert.isTrue(customResponse.success, 'Expected success to be true');
      Assert.areEqual(
        customResponse.message,
        'Applicant has Application(s) in Submitted status. Please contact Monash connect to update the applicant contact details',
        'Expected message'
      );
     // Must create Nebula Log entry
      Assert.isTrue([SELECT Id, Nebula__OriginLocation__c FROM Nebula__LogEntry__c].size()>0);
    }
  }


  /**
   * @description test patch request update an Applicant
   * @author Ben Greenland | 2024-10-17
   **/
  @IsTest
  static void handlePatch() {
    //GIVEN: An Applicant Patch Request is prepared and serialized into a RestRequest.
    OESApplicantPayload.PatchRequest postRequestPayload = createPatchRequestPayload();
    RestRequest request = new RestRequest();
    request.httpMethod = 'PATCH';
    request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
    RestContext.request = request;

    //WHEN The method is executed as an OES user.
    User testUser = [
      SELECT ID
      FROM User
      WHERE Email = 'testAgentLastName@TestEmail.com'
      LIMIT 1
    ];
    System.runAs(testUser) {
      RestResponse response = new RestResponse();
      RestContext.response = response;

      Test.startTest();
      RESTlib_ClientImplHandler clientImplHandler = new OESApplicantImpl()
        .getHandlePatch();
      clientImplHandler.setPayloadType(
        OESApplicantPayload.PatchRequest.class,
        OESApplicantPayload.PatchResponse.class
      );
      clientImplHandler.execute();
      Test.stopTest();

      String responseBodyString = response.responseBody.toString();
      // Deserialize string to custom payload class
      OESApplicantPayload.PatchResponse customResponse = (OESApplicantPayload.PatchResponse) JSON.deserialize(
        responseBodyString,
        OESApplicantPayload.PatchResponse.class
      );

      Assert.isTrue(customResponse.success, 'Expected success to be true');
      Assert.areEqual(
        customResponse.message,
        'Applicant updated successfully!',
        'Expected message'
      );
      // Must create Nebula Log entry
      Assert.isTrue([SELECT Id, Nebula__OriginLocation__c FROM Nebula__LogEntry__c].size()>0);
    }
  }

  /**
   * @description return OESApplicantPayload.PostRequest
   * @author Ben Greenland | 2024-09-03
   * @return OESApplicantPayload.PostRequest
   **/
  private static OESApplicantPayload.PostRequest createPostRequestPayload() {
    OESApplicantPayload.PostRequest postRequestPayload = new OESApplicantPayload.PostRequest();
    postRequestPayload.applicant = getApplicant();
    return postRequestPayload;
  }

  /**
   * @description test setup helper
   * @author Ben Greenland | 2024-09-03
   * @return OESApplicantPayload.Applicant
   **/
  private static OESApplicantPayload.Applicant getApplicant() {
    OESApplicantPayload.Applicant app = new OESApplicantPayload.Applicant();
    app.firstName = 'John';
    app.lastName = 'Doe';
    app.dateOfBirth = '2009-12-31';
    app.previousName = 'Jane';
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

  /**
   * @description  createPatchRequestPayload
   * @author Ben Greenland | 2024-10-17
   * @return OESApplicantPayload.PatchRequest
   **/
  private static OESApplicantPayload.PatchRequest createPatchRequestPayload() {
    OESApplicantPayload.PatchRequest patchRequestPayload = new OESApplicantPayload.PatchRequest();
    Contact con = [
      SELECT Id, FirstName, LastName, CRM_ID__c, accountId, email, phone,Birthdate
      FROM Contact
      WHERE FirstName = '(FN) Editable'
      LIMIT 1
    ];
    Country_Attribute__c country = [
      SELECT Id, uniqueCountryExternalId__c
      FROM Country_Attribute__c
      WHERE Name = 'Australia'
      LIMIT 1
    ];
    
    patchRequestPayload.contactId = con.Id;
    patchRequestPayload.lastname = 'Nasa';
    patchRequestPayload.isPreviousMonashStudent = false;
    patchRequestPayload.gender = 'M';
    patchRequestPayload.externalId = con.CRM_ID__c;
    patchRequestPayload.dateOfBirth = String.valueOf(con.Birthdate);
    patchRequestPayload.email = new List<CommonWSPayload.Email>();
    CommonWSPayload.Email email = new CommonWSPayload.Email();
    email.email = con.email;
    email.type = 'Personal';
    patchRequestPayload.email.add(email);
    patchRequestPayload.phone = new List<CommonWSPayload.Phone>();
    CommonWSPayload.Phone phone = new CommonWSPayload.Phone();
    phone.phoneNumber = con.phone;
    phone.type = 'Mobile';
    patchRequestPayload.phone.add(phone);
    CommonWSPayload.Address address = new CommonWSPayload.Address();
    address.type = 'POSTAL';
    address.street = '123 Test St';
    address.city = 'Clayton';
    address.state = 'Victoria';
    address.postalCode = '3168';
    address.country = 'Mordor';
    patchRequestPayload.address = new List<CommonWSPayload.Address>{ address };
    patchRequestPayload.countryOfBirth = new CommonWSPayload.Country();
    patchRequestPayload.countryOfBirth.crmRecordId = country.Id;
    patchRequestPayload.countryOfBirth.uniqueCountryExternalId = country.uniqueCountryExternalId__c;


    return patchRequestPayload;
  }
    
    
 /**
   * @description test patch request update an Applicant for an existing Applicant
   * @author smen | 2025-06-16
   **/
  @isTest
  static void handlePatchForExistingApplicants() {

     // create test Contact
    Contact applicant = new Contact();
    applicant.FirstName = 'Testing FirstName';
    applicant.LastName = 'Testing FirstName';
    applicant.First_Name__c = applicant.FirstName;
    applicant.Last_Name__c = applicant.LastName;
    applicant.Salutation = 'Mr';
    applicant.Pronouns_V2__c = 'He/Him/His';
    applicant.Suffix = 'Jr';
    applicant.Birthdate = Date.today().addYears(-21);
    applicant.Preferred_Name__c = 'Nickname';
    applicant.Gender__c = 'Male';
    applicant.email = 'testing@existing.com';
    applicant.MobilePhone = '0444444444';
    applicant.OtherStreet = 'Some other street';
    applicant.OtherCity = 'Clayton';
    applicant.OtherState = 'Victoria';
    applicant.OtherCountry = 'Australia';
    applicant.OtherPostalCode = '3168';
    applicant.HomePhone = '04444444444';
    applicant.Previous_Surname__c = 'Some Previous Surname';
    applicant.Previous_Monash_ID__c = 'PREVIOUS_ID';
    applicant.Previously_Studied_at_Monash__c = false;
    applicant.Aboriginal_or_Torres_Strait_Islander__c = 'NO';
    //insert as the running user
    insert applicant;
                             
    //GIVEN: An Applicant Patch Request is prepared and serialized into a RestRequest.
    OESApplicantPayload.PatchRequest postRequestPayload = createPatchRequestPayload();
    RestRequest request = new RestRequest();
    request.httpMethod = 'PATCH';
    request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
    RestContext.request = request;

    //WHEN The method is executed as an OES user.
    User testUser = [
      SELECT ID,profile.name
      FROM User
      WHERE Email = 'testAgentLastName@TestEmail.com'
      LIMIT 1
    ];
    
    System.runAs(testUser) {

      RestResponse response = new RestResponse();
      RestContext.response = response;

      Test.startTest();
      RESTlib_ClientImplHandler clientImplHandler = new OESApplicantImpl()
        .getHandlePatch();
      clientImplHandler.setPayloadType(
        OESApplicantPayload.PatchRequest.class,
        OESApplicantPayload.PatchResponse.class
      );
      clientImplHandler.execute();
      Test.stopTest();

      String responseBodyString = response.responseBody.toString();
      // Deserialize string to custom payload class
      OESApplicantPayload.PatchResponse customResponse = (OESApplicantPayload.PatchResponse) JSON.deserialize(
        responseBodyString,
        OESApplicantPayload.PatchResponse.class
      );
       
       //THEN The response has the expected success 
       Assert.isTrue(customResponse.success, 'Expected success to be true');
      Assert.areEqual(
        customResponse.message,
        'Applicant updated successfully!',
        'Expected message'
      );
   }
  }
  
    /**
   * @description test Affiliation creation
   * @author smen | 2025-06-19
   **/
    @isTest
    static void testAffiliationCreate()
    {
       Contact applicant = [
            SELECT Id, FirstName, LastName, CRM_ID__c, accountId, email, phone,Birthdate
            FROM Contact
            WHERE FirstName = '(FN) Editable'
            LIMIT 1];
          
    //GIVEN: An Applicant Patch Request is prepared and serialized into a RestRequest.
    OESApplicantPayload.PatchRequest postRequestPayload = createPatchRequestPayload();
    RestRequest request = new RestRequest();
    request.httpMethod = 'PATCH';
    request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
    RestContext.request = request;

    //WHEN: The method is executed as an OES user.
    User testUser = [
      SELECT ID,profile.name
      FROM User
      WHERE Email = 'testAgentLastName@TestEmail.com'
      LIMIT 1];
    
     TriggerCommon.disableTrigger('Affiliation__c');
     System.runAs(testUser) {
       new OESApplicantImpl.RunSystemContext().createAffiliation([select CRM_ID__c from Contact where Id=:applicant.Id][0].CRM_ID__c);
        //THEN: Affiliation must be created
       Assert.isTrue([Select id from Affiliation__c where Contact__c=:applicant.Id].size()>0); 
     }
     TriggerCommon.enableTrigger('Affiliation__c');
    }
}