/**
 * @description Test class for APNGApplicantImpl.
 * @author      Nick Guia
 * @since       AUG.02.2024
 * @revision    BGreenland  30 Aug 2024 - added addtional test
 */
@isTest(isParallel=true)
private class APNGApplicantImpl_Test {
  @TestSetup
  static void makeData() {
    AgentPortalTestDataFactory factory = new AgentPortalTestDataFactory();

    TriggerCommon.disableTrigger('Country_Attribute__c');
    TriggerCommon.disableTrigger('Contact');
    TriggerCommon.disableTrigger('Account');
    TriggerCommon.disableTrigger('User');

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

    //create APNG User
    AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser()
      .build();

    System.runAs(portalUser.testUser) {
      insert applicant;
    }

    TriggerCommon.enableTrigger('Country_Attribute__c');
    TriggerCommon.enableTrigger('Contact');
    TriggerCommon.disableTrigger('Account');
    TriggerCommon.disableTrigger('User');
  }

  /**
   * @description test boiler plate code - getHandleGet()
   */
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  @isTest
  static void shouldReturnHandleGet() {
    // GIVEN : a HandleGet instance
    APNGApplicantImpl.HandleGet handler;

    Test.startTest();

    // WHEN : I invoke getHandleGet()
    APNGApplicantImpl impl = new APNGApplicantImpl();
    handler = (APNGApplicantImpl.HandleGet) impl.getHandleGet();

    Test.stopTest();

    // THEN : it should return the class instance which extends to RESTlib_ClientImplHandler
    Assert.isNotNull(handler, 'Unable to get HandleGet()');
    Assert.isInstanceOfType(
      handler,
      RESTlib_ClientImplHandler.class,
      'HandleGet must be an instance of RESTlib_ClientImplHandler'
    );
  }

  /**
   * @description test boiler plate code - HandleGet types
   */
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  @isTest
  static void shouldReturnHandleRequestResponseTypes() {
    // GIVEN : a HandleGet instance
    APNGApplicantImpl.HandleGet handler = new APNGApplicantImpl.HandleGet();

    Type expectedRequest = APNGApplicantPayload.GetRequest.class;
    Type expectedResponse = APNGApplicantPayload.GetResponse.class;
    Type returnRequest;
    Type returnResponse;

    Test.startTest();

    // WHEN : I invoke get types
    returnRequest = handler.getRequestType();
    returnResponse = handler.getResponseType();

    Test.stopTest();

    // THEN : I should receive the expected types
    Assert.areEqual(expectedRequest, returnRequest, 'Unexpected request Type');
    Assert.areEqual(
      expectedResponse,
      returnResponse,
      'Unexpected response Type'
    );
  }

  /**
   * @description test boiler plate code - getHandlePost()
   */
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  @isTest
  static void shouldReturnHandlePost() {
    // GIVEN : a HandlePost instance
    APNGApplicantImpl.HandlePost handler;

    Test.startTest();

    // WHEN : I invoke getHandlePost()
    APNGApplicantImpl impl = new APNGApplicantImpl();
    handler = (APNGApplicantImpl.HandlePost) impl.getHandlePost();

    Test.stopTest();

    // THEN : it should return the class instance which extends to RESTlib_ClientImplHandler
    Assert.isNotNull(handler, 'Unable to get HandlePost()');
    Assert.isInstanceOfType(
      handler,
      RESTlib_ClientImplHandler.class,
      'HandleGet be an instance of RESTlib_ClientImplHandler'
    );
  }

  /**
   * @description test boiler plate code - getHandlePut()
   * NO IMPLEMENTATION YET
   */
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  @isTest
  static void shouldReturnHandlePut() {
    // GIVEN : a Handler instance
    RESTlib_ClientImplHandler handler;

    Test.startTest();

    // WHEN : I invoke getHandlePut()
    APNGApplicantImpl impl = new APNGApplicantImpl();
    handler = impl.getHandlePut();

    Test.stopTest();

    // THEN : Put is not expected to be implemented yet
    Assert.isTrue(handler == null, 'Unexpected Put implementation');
  }

  /**
   * @description test boiler plate code - getHandlePatch()
   */
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  @isTest
  static void shouldReturnHandlePatch() {
    // GIVEN : a HandlePatch instance
    APNGApplicantImpl.HandlePatch handler;

    Test.startTest();

    // WHEN : I invoke getHandlePatch()
    APNGApplicantImpl impl = new APNGApplicantImpl();
    handler = (APNGApplicantImpl.HandlePatch) impl.getHandlePatch();

    Test.stopTest();

    // THEN : it should return the class instance which extends to RESTlib_ClientImplHandler
    Assert.isNotNull(handler, 'Unable to get HandlePatch()');
    Assert.isInstanceOfType(
      handler,
      RESTlib_ClientImplHandler.class,
      'HandleGet be an instance of RESTlib_ClientImplHandler'
    );
  }

  /**
   * @description when HandleGet is invoked with null request parameters, the system
   * should throw a RESTlib_Ex.InvalidRequestException
   */
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  @isTest
  static void handleGetShouldThrowExceptionWhenParametersAreNull() {
    // GIVEN : a HandleGet instance with a request with null parameters
    APNGApplicantImpl.HandleGet handler = new APNGApplicantImpl.HandleGet();
    APNGApplicantPayload.GetRequest req = new APNGApplicantPayload.GetRequest();

    Test.startTest();

    // WHEN : I validate the request
    try {
      handler.validate(req);
      Assert.fail('Should throw an exception with null request parameters');
    } catch (RESTlib_Ex.InvalidRequestException e) {
      // THEN : the right exception type should be thrown
      Assert.isTrue(true);
    } catch (Exception e) {
      Assert.fail('Expected to throw an RESTlib_Ex.InvalidRequestException');
    }
  }

  /**
   * @description when HandleGet is invoked with null request parameters, the system
   * should throw a RESTlib_Ex.InvalidRequestException
   */

  @isTest
  static void handleGetShouldThrowExceptionWhenApplicantNotFound() {
    // GIVEN : a HandleGet instance with a request with null parameters
    APNGApplicantImpl.HandleGet handler = new APNGApplicantImpl.HandleGet();
    APNGApplicantPayload.GetRequest req = new APNGApplicantPayload.GetRequest();
    req.crmContactId = 'NOT_EXISTING';
    APNGApplicantPayload.GetResponse resp = new APNGApplicantPayload.GetResponse();

    Test.startTest();

    // WHEN : I validate the request
    try {
      handler.process(req, resp);
      Assert.fail('Should throw an exception when applicant does not exist');
    } catch (RESTlib_Ex.NotFoundException e) {
      // THEN : the right exception type should be thrown
      Assert.isTrue(true);
    } catch (Exception e) {
      Assert.fail('Expected to throw an RESTlib_Ex.NotFoundException');
    }
  }

  /**
   * @description When an applicant dAPNGn't have an existing Submitted Application
   * and HTTP Get Applicant is invoked, it should return the instance of the contact, identified
   * by CRM_ID__c; with the isEditable flag set to TRUE
   */
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  @isTest
  static void handleGetShouldReturnPositiveResponseEditableContact() {
    // GIVEN : an Applicant with an existing draft Application
    Contact con = [SELECT Id, CRM_ID__c FROM Contact LIMIT 1];
    Application__c submittedApp = new AgentPortalTestDataFactory()
      .createApplication(con.Id);
    TriggerCommon.disableTrigger('Application__c');
    insert submittedApp;
    TriggerCommon.enableTrigger('Application__c');

    // test request
    APNGApplicantPayload.GetRequest req = new APNGApplicantPayload.GetRequest();
    req.crmContactId = con.CRM_ID__c;
    APNGApplicantPayload.GetResponse resp = new APNGApplicantPayload.GetResponse();

    Test.startTest();

    // WHEN : I invoke HandleGet
    resp = (APNGApplicantPayload.GetResponse) new APNGApplicantImpl.HandleGet()
      .process(req, resp);

    Test.stopTest();

    // THEN : validate response
    Assert.areEqual(1, resp.noOfRecords, 'Unexpected number of records');
    Assert.areEqual(
      true,
      resp.applicant.isEditable,
      'Unexpected value for is Editable'
    );
    Assert.areEqual(
      con.CRM_ID__c,
      resp.applicant.externalId,
      'Unexpected value for external ID'
    );
  }

  /**
   * @description When an applicant has an existing Submitted Application
   * and HTTP Get Applicant is invoked, it should return the instance of the contact, identified
   * by CRM_ID__c; with the isEditable flag set to TRUE
   */
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  @isTest
  static void handleGetShouldReturnPositiveResponseUneditableContact() {
    // GIVEN : an Applicant with an existing submitted Application
    Contact con = [SELECT Id, CRM_ID__c FROM Contact LIMIT 1];
    Application__c submittedApp = new AgentPortalTestDataFactory()
      .createApplication(con.Id);
    submittedApp.Status__c = 'Submitted';

    TriggerCommon.disableTrigger('Application__c');
    insert submittedApp;
    TriggerCommon.enableTrigger('Application__c');

    // test request
    APNGApplicantPayload.GetRequest req = new APNGApplicantPayload.GetRequest();
    req.crmContactId = con.CRM_ID__c;
    APNGApplicantPayload.GetResponse resp = new APNGApplicantPayload.GetResponse();

    Test.startTest();

    // WHEN : I invoke HandleGet
    resp = (APNGApplicantPayload.GetResponse) new APNGApplicantImpl.HandleGet()
      .process(req, resp);

    Test.stopTest();

    // THEN : validate response
    Assert.areEqual(1, resp.noOfRecords, 'Unexpected number of records');
    Assert.areEqual(
      false,
      resp.applicant.isEditable,
      'Unexpected value for is Editable'
    );
    Assert.areEqual(
      con.CRM_ID__c,
      resp.applicant.externalId,
      'Unexpected value for external ID'
    );
  }

  /**
   * @description when get applicant is invoked by searching by name, it should
   * return the number of expected records that matches the name
   */

  @isTest
  static void handleGetShouldReturnPositiveResponseSearchContact() {
    // GIVEN : an Applicant record
    User testUser = [
      SELECT ID
      FROM User
      WHERE Email = 'testAgentLastName@TestEmail.com'
      LIMIT 1
    ];
    System.runAs(testUser) {
      Contact con = [
        SELECT Id, FirstName, LastName, CRM_ID__c
        FROM Contact 
        WHERE LastName = '(LN) Applicant'
        LIMIT 1
      ];
      String fullName = con.FirstName + ' ' + con.LastName;

      // test request
      APNGApplicantPayload.GetRequest req = new APNGApplicantPayload.GetRequest();
      req.applicantName = fullName;
      APNGApplicantPayload.GetResponse resp = new APNGApplicantPayload.GetResponse();

      Test.startTest();

      // WHEN : I invoke HandleGet
      resp = (APNGApplicantPayload.GetResponse) new APNGApplicantImpl.HandleGet()
        .process(req, resp);

      Test.stopTest();
    
    // THEN : validate response
        Assert.areEqual(1, resp.noOfRecords, 'Unexpected number of records');
        Assert.areEqual(1, resp.applicants.size(), 'Unexpected number of records');
    }
  }

  /**
   * @description when patch is invoked with a null payload
   */
  @isTest
  static void handlePatchShouldReturnPositiveResponse() {
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
   * @description test patch request update an Applicant
   * @author Ben Greenland | 2024-10-17
   **/
  @IsTest
  static void handlePatch() {
    //GIVEN: An Applicant Patch Request is prepared and serialized into a RestRequest.
    APNGApplicantPayload.PatchRequest postRequestPayload = createPatchRequestPayload();
    RestRequest request = new RestRequest();
    request.httpMethod = 'PATCH';
    request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
    RestContext.request = request;

    //WHEN The method is executed as an APNG user.
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
      RESTlib_ClientImplHandler clientImplHandler = new APNGApplicantImpl()
        .getHandlePatch();
      clientImplHandler.setPayloadType(
        APNGApplicantPayload.PatchRequest.class,
        APNGApplicantPayload.PatchResponse.class
      );
      clientImplHandler.execute();
      Test.stopTest();

      String responseBodyString = response.responseBody.toString();
      // Deserialize string to custom payload class
      APNGApplicantPayload.PatchResponse customResponse = (APNGApplicantPayload.PatchResponse) JSON.deserialize(
        responseBodyString,
        APNGApplicantPayload.PatchResponse.class
      );
      // THEN - There must be a positive response
      Assert.isTrue([SELECT Id, Nebula__OriginLocation__c FROM Nebula__LogEntry__c].size()>0);
      Assert.isTrue(customResponse.success, 'Expected success to be true' + JSON.serializePretty(customResponse));
      Assert.areEqual(
        customResponse.message,
        'Applicant updated successfully!',
        'Expected message'
      );
    }
  }

  /**
   * @description This test method verifies the functionality of the handlePost method in the APNGApplicantImpl class.
   * @author Ben Greenland | 2024-08-27
   **/
  @isTest
  static void handlePostCreateApplicant() {
    //GIVEN: An Applicant Create Request is prepared and serialized into a RestRequest.
    APNGApplicantPayload.PostRequest postRequestPayload = createPostRequestPayload();
    RestRequest request = new RestRequest();
    request.httpMethod = 'POST';
    request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
    RestContext.request = request;

    //WHEN The method is executed as an APNG user.
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
      RESTlib_ClientImplHandler clientImplHandler = new APNGApplicantImpl()
        .getHandlePost();
      clientImplHandler.setPayloadType(
        APNGApplicantPayload.PostRequest.class,
        APNGApplicantPayload.PostResponse.class
      );
      clientImplHandler.execute();
      Test.stopTest();

      String responseBodyString = response.responseBody.toString();
      // Deserialize string to custom payload class
      APNGApplicantPayload.PostResponse customResponse = (APNGApplicantPayload.PostResponse) JSON.deserialize(
        responseBodyString,
        APNGApplicantPayload.PostResponse.class
      );
      Assert.isTrue(customResponse.success, 'Expected success to be true');
      Assert.areEqual(
        customResponse.message,
        'Applicant created successfully!',
        'Expected message'
      );
    }
    //THEN A contact is expected to be successfully created in the system.
    List<Contact> result = [
      SELECT Id
      FROM Contact
      WHERE Previous_Monash_ID__c = '12345'
    ];
    Assert.isTrue(result.size() == 1, 'Expected a  Contact to be created');
  }

  /**
   * @description   This test method verifies the functionality of the handlePost method in the APNGApplicantImpl class.
   * @author Ben Greenland | 2024-09-03
   **/
  @isTest
  static void handlePostCreateApplicantFailue() {
    //GIVEN: An Applicant Create Request is prepared and serialized into a RestRequest with bad data
    APNGApplicantPayload.PostRequest postRequestPayload = createPostRequestPayload();
    postRequestPayload.applicant.dateOfBirth = 'xxxxxx'; // create a bad payload
    RestRequest request = new RestRequest();
    request.httpMethod = 'POST';
    request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
    RestContext.request = request;

    //WHEN The method is executed as an APNG user.
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
      RESTlib_ClientImplHandler clientImplHandler = new APNGApplicantImpl()
        .getHandlePost();
      clientImplHandler.setPayloadType(
        APNGApplicantPayload.PostRequest.class,
        APNGApplicantPayload.PostResponse.class
      );
      clientImplHandler.execute();
      Test.stopTest();

      String responseBodyString = response.responseBody.toString();
      // Deserialize string to custom payload class
      APNGApplicantPayload.PostResponse customResponse = (APNGApplicantPayload.PostResponse) JSON.deserialize(
        responseBodyString,
        APNGApplicantPayload.PostResponse.class
      );
      //THEN An error response is returned.
      Assert.isFalse(customResponse.success, 'Expected success to be false');
			Assert.isTrue([SELECT Id, Nebula__OriginLocation__c FROM Nebula__LogEntry__c].size()>0);

    }
  }
  private static APNGApplicantPayload.PostRequest createPostRequestPayload() {
    APNGApplicantPayload.PostRequest postRequestPayload = new APNGApplicantPayload.PostRequest();
    postRequestPayload.applicant = getApplicant();
    return postRequestPayload;
  }

  /**
   * @description test helper to create a test applicant
   * @author Ben Greenland | 2024-09-03
   * @return APNGApplicantPayload.Applicant
   **/
  private static APNGApplicantPayload.Applicant getApplicant() {
    APNGApplicantPayload.Applicant app = new APNGApplicantPayload.Applicant();
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
   * @description  createPatchRequestPayload
   * @author Ben Greenland | 2024-10-17
   * @return APNGApplicantPayload.PatchRequest
   **/
  private static APNGApplicantPayload.PatchRequest createPatchRequestPayload() {
    APNGApplicantPayload.PatchRequest patchRequestPayload = new APNGApplicantPayload.PatchRequest();
    Contact con = [
      SELECT Id, FirstName, LastName, CRM_ID__c, accountId
      FROM Contact
      WHERE FirstName = '(FN) Editable'
      LIMIT 1
    ];
    patchRequestPayload.contactId = con.Id;
    patchRequestPayload.lastname = 'Nasa';
    patchRequestPayload.gender = 'M';
    patchRequestPayload.isPreviousMonashStudent = false;

    return patchRequestPayload;
  }
}