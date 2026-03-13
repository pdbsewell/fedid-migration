/**
 * @description Test class for APNG_WebServiceSelector
 * @author      Nick Guia
 * @since       27/09/2023
 * @group       Admissions
 * @see         https://monash-esol.atlassian.net/wiki/spaces/EPOM/pages/328925218/APNG+-+Enquiry+Management+LLD
 */
@isTest(isParallel=false)
private class APNG_WebServiceSelector_Test {

    @TestSetup
    static void makeData(){
        TriggerCommon.disableTrigger('Country_Attribute__c');
        TriggerCommon.disableTrigger('Account');
        TriggerCommon.disableTrigger('Contact');
        TriggerCommon.disableTrigger('User');
        TriggerCommon.disableTrigger('Case');
        TriggerCommon.disableTrigger('CaseFeed');

        List<User> admins = [select id, username, Profile.name FROM User WHERE Profile.Name LIKE '%Admin%' LIMIT 100];
        // STEP 1 - create a test Agent Portal User
        AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();

        // STEP 2 - create an Enquiry as the Agent user
        AgentPortalTestDataBuilder.AgentEnquiry agentEnquiry = new AgentPortalTestDataBuilder.AgentEnquiry().withAgent(portalUser);
        // STEP 2 - create 5 CaseFeeds as the Agent user
        agentEnquiry.caseFeedNumber = 5;
        agentEnquiry.build();

        TriggerCommon.enableTrigger('Country_Attribute__c');
        TriggerCommon.enableTrigger('Account');
        TriggerCommon.enableTrigger('Contact');
        TriggerCommon.enableTrigger('User');
        TriggerCommon.enableTrigger('Case');
        TriggerCommon.enableTrigger('CaseFeed');
    }

    /**
     * @description test if Agent is able to query the case record
     */
    @isTest
    static void shouldReturnCaseByCaseNumber() {

        // GIVEN

        // get the setup Case
        Case caseRec = [SELECT Id, CaseNumber FROM Case LIMIT 1];
        User agentUser = AgentPortalTestDataFactory.util.getAgentUser();

        Case queryResult;

        Test.startTest();

        // WHEN
        APNG_WebServiceSelector selector = new APNG_WebServiceSelector();
        System.runAs(agentUser) {
            // query the case as the Agent to test permissions
            queryResult = selector.selectCaseDetailsByCaseNumber(caseRec.CaseNumber);
        }

        Test.stopTest();

        // THEN
        Assert.isNotNull(queryResult, 'Unable to query Case');
    }

    /**
     * @description test if Agent is able to query the case record when it is hidden 
     */
    @isTest
    static void shouldNotReturnHiddenCases() {

        // GIVEN

        // get the setup Case
        Case caseRec = [SELECT Id, CaseNumber FROM Case LIMIT 1];
        // hide the enquiry to Agencies
        caseRec.is_Visible_to_External_Stakeholder__c = false; 
        TriggerCommon.disableTrigger('Case');
			update caseRec;        
        TriggerCommon.enableTrigger('Case');
        
        User agentUser = AgentPortalTestDataFactory.util.getAgentUser();

        Case queryResult;

        Test.startTest();

        // WHEN
        APNG_WebServiceSelector selector = new APNG_WebServiceSelector();
        System.runAs(agentUser) {
            // query the case as the Agent 
            try {
                queryResult = selector.selectCaseDetailsByCaseNumber(caseRec.CaseNumber);
            } catch(QueryException qe) {
                // THEN 
                // Case is not returned
                Assert.isTrue(true);
            } catch(Exception ex) {
                Assert.isTrue(false, ex.getMessage());
            }
        }

        Test.stopTest();

        // THEN
        // Case is not returned
        Assert.isNull(queryResult, 'Hidden enquiries are sent to Agency');
    }
    
    /**
     * @description test if Agent is able to query the caseFeed records
     */
    @isTest
    static void shouldReturnCaseFeedByCaseNumber() {

        // GIVEN

        // get the setup Case
        Case caseRec = [SELECT Id, CaseNumber FROM Case LIMIT 1];
        User agentUser = AgentPortalTestDataFactory.util.getAgentUser();

        List<CaseFeed> queryResult;

        Test.startTest();

        // WHEN
        APNG_WebServiceSelector selector = new APNG_WebServiceSelector();
        System.runAs(agentUser) {
            // query the case as the Agent to test permissions
            queryResult = selector.selectCaseFeedByCaseNumber(caseRec.CaseNumber);
        }

        Test.stopTest();

        // THEN
        Assert.isNotNull(queryResult, 'Unable to query Case');
        Assert.areEqual(5, queryResult.size(), 'Unexpected number of CaseFeeds returned by the query');
    }
}