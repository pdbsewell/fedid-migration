/**
 * @description Test class for APNG_EnquiryWebService
 * @date        27/09/2023  
 * @author      Nick Guia
 * @group       Admissions
 */
@isTest(isParallel=false)
public with sharing class APNG_EnquiryWebService_Test {

    @TestSetup
    static void makeData() {
        TriggerCommon.disableTrigger('Country_Attribute__c');
        TriggerCommon.disableTrigger('Account');
        TriggerCommon.disableTrigger('Contact');
        TriggerCommon.disableTrigger('User');
        TriggerCommon.disableTrigger('Case');
        TriggerCommon.disableTrigger('CaseFeed');

        // STEP 1 - create a test Agent Portal User
        AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();

        // STEP 2 - create an Enquiry and CaseFeeds as the Agent user
        AgentPortalTestDataBuilder.AgentEnquiry agentEnquiry = new AgentPortalTestDataBuilder.AgentEnquiry()
                                                                .withAgent(portalUser)
                                                                .withCaseFeed(5)
                                                                .build();
        TriggerCommon.enableTrigger('Country_Attribute__c');
        TriggerCommon.enableTrigger('Account');
        TriggerCommon.enableTrigger('Contact');
        TriggerCommon.enableTrigger('User');
        TriggerCommon.enableTrigger('Case');
        TriggerCommon.enableTrigger('CaseFeed');
    }

    /**
     * @description test invoking the HTTP GET method with access
     * emulating an Agent's privileges
     */
    @isTest
    static void shouldDoGet(){

        // GIVEN
        User agentUser = AgentPortalTestDataFactory.util.getAgentUser();
        Case caseRec = [SELECT Id, CaseNumber FROM Case LIMIT 1];

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/v2/AgentManagementWebService/details/'+caseRec.CaseNumber;  
        req.httpMethod = 'GET';  
        RestContext.request = req;
        RestContext.response = res;

        APNG_WebServicePayload.APNG_EnquiryWebService_GetResponse resp;

        Test.startTest();

        // WHEN
        System.runAs(agentUser) {
            APNG_EnquiryWebService.doGet();
            String respJSONStr = RestContext.response.responseBody.toString();
            resp = (APNG_WebServicePayload.APNG_EnquiryWebService_GetResponse) JSON.deserialize(respJSONStr, APNG_WebServicePayload.APNG_EnquiryWebService_GetResponse.class);
        }

        Test.stopTest();

        // THEN
        Assert.isNotNull(resp, 'Invalid null response');
        Assert.isTrue(resp.success, 'Unexpected unsuccessful response');
        Assert.isNotNull(resp.enquiryDetails, 'Unable to query case details');
        Assert.areEqual(5, resp.caseFeedList.size(), 'Unexpected number of case feed items returned');
    }

    /**
     * @description test invoking the HTTP GET method with access
     * emulating an Agent's privileges
     */
    @isTest
    static void shouldThrowExceptionOnDoGetWhenCaseNumberInvalid(){

        // GIVEN
        User agentUser = AgentPortalTestDataFactory.util.getAgentUser();

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse(); 
        req.requestURI = '/v2/AgentManagementWebService/details/000001';
        req.httpMethod = 'GET';  
        RestContext.request = req;
        RestContext.response = res;

        APNG_WebServicePayload.APNG_EnquiryWebService_GetResponse resp;

        Test.startTest();

        // WHEN
        System.runAs(agentUser) {
            APNG_EnquiryWebService.doGet();
            String respJSONStr = RestContext.response.responseBody.toString();
            resp = (APNG_WebServicePayload.APNG_EnquiryWebService_GetResponse) JSON.deserialize(respJSONStr, APNG_WebServicePayload.APNG_EnquiryWebService_GetResponse.class);
        }

        Test.stopTest();

        // THEN
        Assert.isFalse(resp.success, 'Unexpected unsuccessful response');
    }
    
    /**
     * @description test invoking the HTTP GET method on Hidden Enquiries
     */
    @isTest
    static void shouldThrowExceptionOnDoGetWhenCaseIsHidden(){

        // GIVEN
        User agentUser = AgentPortalTestDataFactory.util.getAgentUser();
        Case caseRec = [SELECT Id, CaseNumber FROM Case LIMIT 1];
        // hide the enquiry to Agencies
        caseRec.is_Visible_to_External_Stakeholder__c = false; 
        TriggerCommon.disableTrigger('Case');
        System.runAs(new User(Id = UserInfo.getUserId())) { // to avoid mixed DML
			update caseRec;        
        }
        TriggerCommon.enableTrigger('Case');

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/v2/AgentManagementWebService/details/'+caseRec.CaseNumber;  
        req.httpMethod = 'GET';  
        RestContext.request = req;
        RestContext.response = res;

        APNG_WebServicePayload.APNG_EnquiryWebService_GetResponse resp;

        Test.startTest();

        // WHEN
        System.runAs(agentUser) {
            APNG_EnquiryWebService.doGet();
            String respJSONStr = RestContext.response.responseBody.toString();
            resp = (APNG_WebServicePayload.APNG_EnquiryWebService_GetResponse) JSON.deserialize(respJSONStr, APNG_WebServicePayload.APNG_EnquiryWebService_GetResponse.class);
        }

        Test.stopTest();

        // THEN
        Assert.isNotNull(resp, 'Invalid null response');
        Assert.isFalse(resp.success, 'Unexpected successful response');
        Assert.isNull(resp.enquiryDetails, 'Hidden enquiries are sent to Agency');
        Assert.areEqual(0, resp.caseFeedList.size(), 'Unexpected number of case feed items returned');
    }
}