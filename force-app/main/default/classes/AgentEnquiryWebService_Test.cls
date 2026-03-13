/**
 * @description Test class for AgentEnquiryWebService
 * @date        18/09/2023  
 * @author      Nick Guia
 * @group       Admissions
 */
@isTest(isParallel=false) // cannot run in parallel due to APEX_DATA_ACCESS_RESTRICTION
private class AgentEnquiryWebService_Test {

    @TestSetup
    static void makeData() {

        // STEP 1 - create a test Agent Portal User
        TriggerCommon.disableTrigger('Country_Attribute__c');
        TriggerCommon.disableTrigger('Account');
        TriggerCommon.disableTrigger('Contact');
        TriggerCommon.disableTrigger('User');

        AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();

        TriggerCommon.enableTrigger('Country_Attribute__c');
        TriggerCommon.enableTrigger('Account');
        TriggerCommon.enableTrigger('Contact');
        TriggerCommon.enableTrigger('User');

        // STEP 2 - create a test Application as the portal user

        System.runAs(portalUser.testUser) {
            TriggerCommon.disableTrigger('Application__c');
            TriggerCommon.disableTrigger('Course__c');
            TriggerCommon.disableTrigger('Course_Offering__c');
            TriggerCommon.disableTrigger('Application_Course_Preference__c');

            Course__c course = AgentPortalTestDataFactory.createCourse();
            insert course;

            Course_Offering__c courseOffering = AgentPortalTestDataBuilder.factory.createCourseOffering(course);
            
            new AgentPortalTestDataBuilder.Application()
                                                                        .withAgent(portalUser)
                                                                        .withCourseOffering(courseOffering)
                                                                        .build();

            TriggerCommon.enableTrigger('Application__c');
            TriggerCommon.enableTrigger('Course__c');
            TriggerCommon.enableTrigger('Course_Offering__c');
            TriggerCommon.enableTrigger('Application_Course_Preference__c');
        }
    }

     /**
     * @description test an CreateEnquiry responds with the appropriate message when an attempt
     * is made to create an Enquiry on an ACP-> Application which is not in the submitted status
     */
    @isTest
    static void shouldHandleApplicationNotInSubmittedStatusResponse() {

        // GIVEN
        User agentUser = getAgentUser();

        System.runAs(agentUser) {
            // create a request payload
            AgentPortalPayload.CreateEnquiryRequest payload = createPostRequest();
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse(); 

            req.requestURI = '/v2/AgentEnquiryWebService';  
            req.httpMethod = 'POST';  
            req.requestBody = Blob.valueOf(JSON.serialize(payload));

            RestContext.request = req;
            RestContext.response = res;

            Test.startTest();
            TriggerCommon.disableTrigger('Case');
            
            // WHEN
            AgentEnquiryWebService.handleCreateEnquiry();
            TriggerCommon.enableTrigger('Case');
         

            Test.stopTest();
        }
           // THEN
           String responseBodyStr = RestContext.response.responseBody.toString();
        
           Assert.isTrue(responseBodyStr.containsIgnoreCase('"success" : false'), 'Unable to create an Enquiry from the HTTP Post request');
           Assert.isTrue(responseBodyStr.containsIgnoreCase('"description" : "Application status should be in Submitted status to create an Enquiry"'), 'Unable to create an Enquiry from the HTTP Post request');
    }

   
    /**
     * @description test an Enquiry is generated when invoking the POST method
     */
    @isTest
    static void shouldHandleCreateEnquiry() {

        // GIVEN
        User agentUser = getAgentUser();

        System.runAs(agentUser) {
            //Update the application status to Submitted
            updateTestSetupApplicationRecord();
            // create a request payload
            AgentPortalPayload.CreateEnquiryRequest payload = createPostRequest();
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse(); 

            req.requestURI = '/v2/AgentEnquiryWebService';  
            req.httpMethod = 'POST';  
            req.requestBody = Blob.valueOf(JSON.serialize(payload));

            RestContext.request = req;
            RestContext.response = res;

            Test.startTest();
            TriggerCommon.disableTrigger('Case');
            
            // WHEN
            AgentEnquiryWebService.handleCreateEnquiry();
            TriggerCommon.enableTrigger('Case');
         

            Test.stopTest();
        }

        // THEN
        String responseBodyStr = RestContext.response.responseBody.toString();
        // TODO: this does not work because the response is not deserializable back to it's concrete class.
        // AgentPortalResponse.toJSONString() errors out on responseBody (get) method because it reconverts the instance to Blob (cyclic reference resulting to null pointer : System.NullPointerException: null argument for JSONGenerator.writeStringField())
        // AgentPortalResponse has to be restructured!
        // AgentPortalPayload.CreateEnquiryResponse responseWrapper = (AgentPortalPayload.CreateEnquiryResponse) JSON.deserialize(responseBodyStr, AgentPortalPayload.CreateEnquiryResponse.class);
        // Assert.areEqual(expectedSuccessMessage, responseWrapper.successMessage, 'Unable to create an Enquiry from the HTTP Post request');

        // workaround Assert : this seems to have become the common assert approach in AgentPortalPayload_Test due to the issue, and must be fixed.
        Assert.isTrue(responseBodyStr.containsIgnoreCase('"success" : true'), 'Unable to create an Enquiry from the HTTP Post request');
        Assert.isTrue(responseBodyStr.containsIgnoreCase('"description" : "Enquiry is created"'), 'Unable to create an Enquiry from the HTTP Post request');
    }

    /**
     * @description test that the createEnquiry() method generates an Enquiry based on the
     * paylaod details. In this test, we limit the scope to only those fields not already covered
     * by the other tests
     */
    @isTest
    static void shouldCreateEnquiry() {
        // GIVEN

        Case actualEnquiry;
        AgentPortalPayload.CreateEnquiryRequest payload;
        User agentUser = getAgentUser();

        System.runAs(agentUser) {
            updateTestSetupApplicationRecord();
            payload = createPostRequest();
            AgentEnquiryWebService service = new AgentEnquiryWebService(new ACPSelector());

            Test.startTest();

            // WHEN
            actualEnquiry = service.createEnquiry(payload);

            Test.stopTest();
        }

        // THEN
        Assert.areEqual(payload.enquiry.subject, actualEnquiry.Subject, 'Invalid field outcome from creating an Enquiry');
        Assert.areEqual(payload.enquiry.origin, actualEnquiry.Origin, 'Invalid field outcome from creating an Enquiry');
        //Assert.areEqual(AgentPortalConstants.STUDENT_REC_POST_APP_QUEUE_ID, actualEnquiry.OwnerId, 'Invalid field outcome from creating an Enquiry');
        Assert.areEqual(payload.enquiry.categoryLevel2, actualEnquiry.Category_Level_2__c, 'Invalid field outcome from creating an Enquiry');
        //Assert.areEqual(agentUser.Contact.AccountId, actualEnquiry.External_Stakeholder__c, 'Invalid field outcome from creating an Enquiry');
        Assert.areEqual(AgentEnquiryWebService.DEFAULT_STUDENT_TYPE, actualEnquiry.Student_Type__c, 'Invalid field outcome from creating an Enquiry');
        Assert.areEqual(payload.enquiry.references[0]?.value[0].id, actualEnquiry.Application_Course_Preference__c, 'Invalid field outcome from creating an Enquiry');
		Assert.isTrue(actualEnquiry.Summary__c.containsIgnoreCase(payload.enquiry.subject) && actualEnquiry.Summary__c.containsIgnoreCase(payload.enquiry.content), 'Summary field is not populated with Subject and Content');
		Assert.isTrue(actualEnquiry.is_Visible_to_External_Stakeholder__c, 'Enquiry NOT visible to Agency');
    }

    

    /**
     * @description test that we get the right Enquiry Type WHEN :
     *  - category level 1 = 'Enquiry'
     *  - category level 1 != 'Late Enrolment'
     */
    @isTest
    static void shouldGetEnquiryRecordType() {
        // GIVEN
        Id actualEnqRecTypeWhenEnquiry;
        Id actualEnqRecTypeWhenNOTEnquiry;

        AgentEnquiryWebService service = new AgentEnquiryWebService(new ACPSelector());

        Test.startTest();

        // WHEN
        actualEnqRecTypeWhenEnquiry = service.getEnquiryRecordType('Admissions');
        actualEnqRecTypeWhenNOTEnquiry = service.getEnquiryRecordType('MUM_Admissions');

        Test.stopTest();

        // THEN
        Assert.areEqual(AgentEnquiryWebService.CASE_RECTYPE_ADMISSIONS, actualEnqRecTypeWhenEnquiry, 'Unexpected Enquiry Record Type');
        Assert.areEqual(AgentEnquiryWebService.CASE_RECTYPE_MUM_ADMISSIONS, actualEnqRecTypeWhenNOTEnquiry, 'Unexpected Enquiry Record Type');
    }

 

    /**
     * @description should return the ACP record based on the reference of the payload
     */
    @isTest
    static void shouldGetACPRecordBasedOnPayloadReference() {

        // GIVEN
        String acpId = fflib_IDGenerator.generate(Application_Course_Preference__c.SObjectType);
        AgentPortalPayload.CDM_Value cdmVal = new AgentPortalPayload.CDM_Value();
        cdmVal.id = acpId;

        AgentPortalPayload.CDM_Reference cdmReference = new AgentPortalPayload.CDM_Reference();
        cdmReference.key = 'crmACP';
        cdmReference.value = new List<AgentPortalPayload.CDM_Value>{ cdmVal };

        // mock the selector class
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        ACPSelector mockACPSelector = (ACPSelector) mocks.mock(ACPSelector.class);

        // mock query return
        Application_Course_Preference__c mockACP = new Application_Course_Preference__c();
        mockACP = (Application_Course_Preference__c) fflib_ApexMocksUtils.setReadOnlyFields(
            mockACP,
            Application_Course_Preference__c.class,
            new Map<SObjectField, Object> {
                Application_Course_Preference__c.Id => acpId,
                Application_Course_Preference__c.Name => 'ACP-1',
                Application_Course_Preference__c.Application__c => fflib_IDGenerator.generate(Application__c.SObjectType)
            }
        );
        List<Application_Course_Preference__c> mockACPList = new List<Application_Course_Preference__c>{ mockACP };

        mocks.startStubbing(); // stubbing start

        mocks.when(
            mockACPSelector.selectFieldsById((List<String>) fflib_Match.anyList(), (Set<Id>) fflib_Match.anyObject())
        ).thenReturn(mockACPList);

        mocks.stopStubbing(); // stubbing end

        AgentEnquiryWebService service = new AgentEnquiryWebService(mockACPSelector);
        Application_Course_Preference__c actualACP;

        Test.startTest();

        // WHEN
        actualACP = service.getACPRecord(new List<AgentPortalPayload.CDM_Reference>{ cdmReference });

        Test.stopTest();

        // THEN
        Assert.areEqual(mockACP.Id, actualACP.Id, 'Unable to query the right ACP');
        Assert.areEqual(mockACP.Name, actualACP.Name, 'Unable to query the right ACP');
        Assert.areEqual(mockACP.Application__c, actualACP.Application__c, 'Unable to query the right ACP');
    }

    /**
     * @description if the payload key is not equal to 'crmACP', do not query the ACP
     */
    @isTest
    static void shouldReturnNullWhenGettingACPWithInvalidKey() {

        // GIVEN
        String acpId = fflib_IDGenerator.generate(Application_Course_Preference__c.SObjectType);
        AgentPortalPayload.CDM_Value cdmVal = new AgentPortalPayload.CDM_Value();
        cdmVal.id = acpId;

        AgentPortalPayload.CDM_Reference cdmReference = new AgentPortalPayload.CDM_Reference();
        cdmReference.key = 'SOME INVALID KEY';
        cdmReference.value = new List<AgentPortalPayload.CDM_Value>{ cdmVal };

        // mock the selector class
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        ACPSelector mockACPSelector = (ACPSelector) mocks.mock(ACPSelector.class);

        // mock query return - only if the key is right
        Application_Course_Preference__c mockACP = new Application_Course_Preference__c();
        mockACP = (Application_Course_Preference__c) fflib_ApexMocksUtils.setReadOnlyFields(
            mockACP,
            Application_Course_Preference__c.class,
            new Map<SObjectField, Object> {
                Application_Course_Preference__c.Id => acpId,
                Application_Course_Preference__c.Name => 'ACP-1',
                Application_Course_Preference__c.Application__c => fflib_IDGenerator.generate(Application__c.SObjectType)
            }
        );
        List<Application_Course_Preference__c> mockACPList = new List<Application_Course_Preference__c>{ mockACP };

        mocks.startStubbing(); // stubbing start

        mocks.when(mockACPSelector.selectFieldsById((List<String>) fflib_Match.anyList(), (Set<Id>) fflib_Match.anyObject())).thenReturn(mockACPList);

        mocks.stopStubbing(); // stubbing end

        AgentEnquiryWebService service = new AgentEnquiryWebService(mockACPSelector);
        Application_Course_Preference__c actualACP;

        Test.startTest();

        // WHEN
        actualACP = service.getACPRecord(new List<AgentPortalPayload.CDM_Reference>{ cdmReference });

        Test.stopTest();

        // THEN
        Assert.isNull(actualACP, 'Invalid ACP query with non crmACP Key');
    }

    /**
     * @description generate a sample HTTPPost Request payload.
     * This method subsequently runs a SOQL on ACP, so this shouldn't be used in a loop
     * @return `AgentPortalPayload.CreateEnquiryRequest`
     */
    private static AgentPortalPayload.CreateEnquiryRequest createPostRequest() {
        AgentPortalPayload.CreateEnquiryRequest req = new AgentPortalPayload.CreateEnquiryRequest();
        req.enquiry = createCDMEnquiry();
        return req;
    }

    private static AgentPortalPayload.CDM_Enquiry createCDMEnquiry() {
        AgentPortalPayload.CDM_Enquiry enquiry = new AgentPortalPayload.CDM_Enquiry();
        enquiry.subject = 'Test Enquiry for test class';
        enquiry.categoryLevel1 = 'Enrolment';
        enquiry.categoryLevel2 = 'Other';
        enquiry.content = 'Test Enquiry body';
        enquiry.origin = 'Web - Agent Portal';
        enquiry.recordtypeDeveloperName = 'Admissions';
        enquiry.enquiryType = 'Post Application';
       
        enquiry.references = new List<AgentPortalPayload.CDM_Reference> { createCDMReference() };
        return enquiry;
    }

    private static AgentPortalPayload.CDM_Reference createCDMReference() {
        AgentPortalPayload.CDM_Reference ref = new AgentPortalPayload.CDM_Reference();
        ref.key = 'crmACP';
        ref.value = new List<AgentPortalPayload.CDM_Value> { createCDMValue() };
        return ref;
    }

    private static AgentPortalPayload.CDM_Value createCDMValue() {
        AgentPortalPayload.CDM_Value val = new AgentPortalPayload.CDM_Value();
        val.id = getTestSetupACPRecord().Id;
        val.description = 'test desc';
        return val;
    }

    private static Application_Course_Preference__c getTestSetupACPRecord() {
        return [SELECT Id, Name, Course_Title__c FROM Application_Course_Preference__c LIMIT 1];
    }

    private static void updateTestSetupApplicationRecord() {
        Application__c app =  [SELECT Id, Name, Status__c FROM Application__c  LIMIT 1];
        app.Status__c = 'Submitted';
        update app;
    }

    private static User getAgentUser() {
        return [SELECT Id, Contact.Id, Contact.AccountId FROM User WHERE username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1 ];
    }
}