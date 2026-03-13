/**
 * @description Test class for ApplicantWS
 * @author      Nick Guia
 * @since       AUG.05.2024
 */
@isTest(isParallel=true)
private class ApplicantWS_Test {
  @TestSetup
  static void makeData() {
    TriggerCommon.disableTrigger('Country_Attribute__c');
    TriggerCommon.disableTrigger('Account');
    TriggerCommon.disableTrigger('Contact');
    TriggerCommon.disableTrigger('User');
    TriggerCommon.disableTrigger('Application__c');
    TriggerCommon.disableTrigger('Application_Course_Preference__c');

    // STEP 1 - create a test Agent Portal User
    AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser()
      .build();

    // STEP 2 - create a test Application (data model) as the portal user
    Contact con = AgentPortalTestDataBuilder.factory.createApplicantContact();
    con.First_Name__c = 'John';
    con.Last_Name__c = 'Wick';
    con.Salutation = 'Mr';
    con.Pronouns_V2__c = 'He/Him/His';
    con.Suffix = 'Jr';
    con.Preferred_Name__c = 'J';
    con.Gender__c = 'M';
    con.OtherStreet = '123 Some other st';
    con.OtherCity = 'Clayton';
    con.OtherState = 'Victoria';
    con.OtherCountry = 'Australia';
    con.OtherPostalCode = '3168';
    con.HomePhone = '04444444444';
    con.Previous_Surname__c = 'Some Previous Surname';
    con.Previous_Monash_ID__c = 'PREVIOUS_ID';
    con.Previously_Studied_at_Monash__c = false;
    con.Aboriginal_or_Torres_Strait_Islander__c = 'NO';
    con.CountryOfBirth__c = portalUser.country.Id; // DEFAULTS TO AUSTRALIA
    AgentPortalTestDataBuilder.Application testApplication = new AgentPortalTestDataBuilder.Application()
      .withAgent(portalUser)
      .withApplicant(con)
      .build();

    TriggerCommon.enableTrigger('Application__c');
    TriggerCommon.enableTrigger('Application_Course_Preference__c');
    TriggerCommon.enableTrigger('Country_Attribute__c');
    TriggerCommon.enableTrigger('Account');
    TriggerCommon.enableTrigger('Contact');
    TriggerCommon.enableTrigger('User');

    /**
     * STEP 3 - build Person 360 for the Applicant
     * Affiliations and CPAs are important so the Agent gets access to the Contact.
     */
    Person360.Person360Builder p360Builder = new Person360.Person360Builder(
      con
    );
    // Affiliation
    p360Builder.withAffiliation(testApplication.applicantAffiliation);
    // Contact Points
    p360Builder.buildAddress()
      .withClassification('Private')
      .withStreetName(con.MailingStreet)
      .withCity(con.MailingCity)
      .withCountry(con.MailingCountry)
      .withState(con.MailingState)
      .withPostCode(con.MailingPostalCode);
    p360Builder.buildEmail()
      .withClassification('Private')
      .withEmailId(con.Email);
    p360Builder.buildPhone()
      .withClassification('Private')
      .withPhoneNumber(con.Phone);
    // finalise - build and commit
    Person360 p360 = p360Builder.build();
    BaseClass bc = new Person360BuilderDirector()
      .resolveDependencies(p360)
      .getBaseClass();
    Boolean isSuccess = bc.commitRecords();
    Assert.isTrue(
      isSuccess,
      'Unable to create Person 360 records for the Applicant'
    );

  }

  /**
   * @description APNG SCENARIO
   * As an APNG user, invoke the Get Applicant API.
   * It should return the response as per integration specs:
   * @see https://monash-esol.atlassian.net/wiki/spaces/EPOM/pages/785580211/Tech+Debt+Register+-+Admissions+API+refactoring#GET
   */
  @isTest
  static void apngHandleGetShouldReturnPositiveResponseWhenGetByCRMId() {
    // GIVEN : a Rest Request for Get Applicant API
    Contact con = [
      SELECT Id, Name, CRM_ID__c
      FROM Contact
      WHERE Previous_Monash_ID__c = 'PREVIOUS_ID'
      LIMIT 1
    ];
    // Set HTTP context
    RestRequest req = new RestRequest();
    req.params.put('crmContactId', con.CRM_ID__c);
    RestResponse res = new RestResponse();
    req.requestURI = '/v3/ApplicantWebService';
    req.httpMethod = 'GET';
    RestContext.request = req;
    RestContext.response = res;

    User agentUser = AgentPortalTestDataFactory.util.getAgentUser();
    APNGApplicantPayload.GetResponse respObj;

    Test.startTest();

    // WHEN : Get Applicant API is invoked by an APNG user
    System.runAs(agentUser) {
      ApplicantWS.handleGet();
      respObj = (APNGApplicantPayload.GetResponse) JSON.deserialize(
        RestContext.response.responseBody.toString(),
        APNGApplicantPayload.GetResponse.class
      );
    }

    Test.stopTest();

    // THEN : assert that the right contact was returned
    Assert.isTrue(respObj.success, 'Unexpected response');
    Assert.areEqual(
      con.CRM_ID__c,
      respObj.applicant.externalId,
      'Invalid return value'
    );
  }

  /**
   * @description APNG SCENARIO
   * As an APNG user, I should be able to get Applicant Details
   * by searching by their name
   * @see https://monash-esol.atlassian.net/wiki/spaces/EPOM/pages/785580211/Tech+Debt+Register+-+Admissions+API+refactoring#GET
   */
  @isTest
  static void apngHandleGetShouldReturnPositiveResponseWhenSearchByContactName() {
    // GIVEN : a Rest Request for Get Applicant API
    Contact con = [
      SELECT Id, Full_name__c, CRM_ID__c
      FROM Contact
      WHERE Previous_Monash_ID__c = 'PREVIOUS_ID'
      LIMIT 1
    ];
    // Set HTTP context
    RestRequest req = new RestRequest();
    req.params.put('applicantName', con.Full_name__c); // only FN + LN
    RestResponse res = new RestResponse();
    req.requestURI = '/v3/ApplicantWebService';
    req.httpMethod = 'GET';
    RestContext.request = req;
    RestContext.response = res;

    User agentUser = AgentPortalTestDataFactory.util.getAgentUser();
    APNGApplicantPayload.GetResponse respObj;

    Test.startTest();

    // WHEN : Get Applicant API is invoked by an APNG user
    System.runAs(agentUser) {
      ApplicantWS.handleGet();
      respObj = (APNGApplicantPayload.GetResponse) JSON.deserialize(
        RestContext.response.responseBody.toString(),
        APNGApplicantPayload.GetResponse.class
      );
    }

    Test.stopTest();

    // THEN : assert that the right contact was returned
    Assert.isTrue(respObj.success, 'Unexpected response');
    Assert.areEqual(1, respObj.applicants.size(), 'Invalid number of contacts');
    Assert.areEqual(
      con.CRM_ID__c,
      respObj.applicants[0].externalId,
      'Invalid return value'
    );
  }

  /**
   * @description APNG SCENARIO
   * When the provided CRM_ID__c is nto found, throw a WebServiceException
   */
  @isTest
  static void apngHandleGetShouldReturnExceptionWhenContactExternalIdNotFound() {
    // GIVEN : an external Id that doesn't exis
    // Set HTTP context
    RestRequest req = new RestRequest();
    req.params.put('crmContactId', 'SOMEID');
    RestResponse res = new RestResponse();
    req.requestURI = '/v3/ApplicantWebService';
    req.httpMethod = 'GET';
    RestContext.request = req;
    RestContext.response = res;

    User agentUser = AgentPortalTestDataFactory.util.getAgentUser();
    APNGApplicantPayload.GetResponse respObj;

    Test.startTest();

    // WHEN : Get Applicant API is invoked by an APNG user
    System.runAs(agentUser) {
      ApplicantWS.handleGet();
      respObj = (APNGApplicantPayload.GetResponse) JSON.deserialize(
        RestContext.response.responseBody.toString(),
        APNGApplicantPayload.GetResponse.class
      );
    }

    Test.stopTest();

    // THEN : response should be unsuccessful
    Assert.isFalse(respObj.success, 'Unexpected response');
    Assert.areEqual(
      'RESTlib_Ex.NotFoundException',
      respObj.error,
      'Unexpected response'
    );
  }

  /**
   * @description APNG SCENARIO
   * When the provided Name is not found, throw a WebServiceException
   */
  @isTest
  static void apngHandleGetShouldReturnExceptionWhenContactNameNotFound() {
    // GIVEN : a contact name that doesn't exist
    // Set HTTP context
    RestRequest req = new RestRequest();
    req.params.put('applicantName', 'SOME RANDOM NAME');
    RestResponse res = new RestResponse();
    req.requestURI = '/v3/ApplicantWebService';
    req.httpMethod = 'GET';
    RestContext.request = req;
    RestContext.response = res;

    User agentUser = AgentPortalTestDataFactory.util.getAgentUser();
    APNGApplicantPayload.GetResponse respObj;

    Test.startTest();

    // WHEN : Get Applicant API is invoked by an APNG user
    System.runAs(agentUser) {
      ApplicantWS.handleGet();
      respObj = (APNGApplicantPayload.GetResponse) JSON.deserialize(
        RestContext.response.responseBody.toString(),
        APNGApplicantPayload.GetResponse.class
      );
    }

    Test.stopTest();

    // THEN : response should be successful but empty search result
    Assert.isTrue(respObj.success, 'Unexpected response');
    Assert.areEqual(0, respObj.noOfRecords, 'Unexpected response');
    Assert.isTrue(respObj.applicants.isEmpty(), 'Unexpected response');
  }

  /**
   * @description Test APNG POST 
   * @author Ben Greenland | 2024-09-04
   **/
  @IsTest
  private static void testHandlePost() {
    //GIVEN AN agent user
    User agentUser = AgentPortalTestDataFactory.util.getAgentUser();
    System.runAs(agentUser) {
      Test.startTest();
      RestRequest req = new RestRequest();
      RestResponse res = new RestResponse();
      req.requestURI = '/v3/ApplicantWebService';
      req.httpMethod = 'POST';
      req.requestBody = Blob.valueOf('{"test":"test"}');

      RestContext.request = req;
      RestContext.response = res;
      //WHEN i create a post request
      ApplicantWS.handlePost();
      //THEN resosnse not null
      Assert.isNotNull(RestContext.response, 'response null');
      Test.stopTest();
    }
  }

    /**
   * @description APNG PATCH
   * Ensure fields are updated
   */
  @isTest
  static void apngTestHandlePatch() {
    // GIVEN
    // Set up test data
    Contact testContact = [
      SELECT Id, Previously_Studied_at_Monash__c
      FROM Contact
      WHERE Last_Name__c = 'Wick'
    ];

    System.runAs(AgentPortalTestDataFactory.util.getAgentUser()) {
      // Prepare the request body
      APNGApplicantPayload.PatchRequest patchRequest = new APNGApplicantPayload.PatchRequest();
      patchRequest.contactId = testContact.Id;
      patchRequest.lastName = 'UpdatedLastName';
      patchRequest.Email = new List<CommonWSPayload.Email>();
      CommonWSPayload.Email personalEmail = new CommonWSPayload.Email();
      personalEmail.type = 'Personal';
      personalEmail.email = 'updated@test.com';
      patchRequest.Email.add(personalEmail);
      patchRequest.isPreviousMonashStudent = testContact.Previously_Studied_at_Monash__c;
      patchRequest.gender = 'M';

      List<CommonWSPayload.Address> addressList = new List<CommonWSPayload.Address>();
      CommonWSPayload.Address address = new CommonWSPayload.Address();
      address.type = 'Postal';
      address.street = '3571 Johnpaul Crescent';
      address.state = 'Jeremieport';
      address.postalCode = '34468 Chance Throughway';
      address.country = 'Montserrat';
      address.city = 'East Immanuelport';
      addressList.add(address);
      patchRequest.address = addressList;

      // Set up the REST context
      RestRequest req = new RestRequest();
      RestResponse res = new RestResponse();

      req.requestURI = '/v3/ApplicantWebService';
      req.httpMethod = 'PATCH';
      req.requestBody = Blob.valueOf(JSON.serialize(patchRequest));
      RestContext.request = req;
      RestContext.response = res;

      //TriggerCommon.disableTrigger('Contact');
      // WHEN

      Test.startTest();
      ApplicantWS.handlePatch();
      Test.stopTest();
      // THEN
      // Verify the response
      System.assertEquals(
        200,
        res.statusCode,
        'The response should indicate success'
      );
    }

    // THEN

    // Verify that the contact was updated
    Contact updatedContact = [
      SELECT LastName, Email, Personal_Email__c
      FROM Contact
      WHERE Id = :testContact.Id
    ];

    System.assertEquals(
      'UpdatedLastName',
      updatedContact.LastName,
      'The last name should be updated'
    );
    System.assertEquals(
      'updated@test.com',
      updatedContact.Personal_Email__c,
      'The email should be updated'
    );
  }
}