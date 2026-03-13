/**
 * @description Test class for AgentManagementWebServiceHelper
 * @author      Nick Guia
 * @date        APR.09.2024
 * @group       Admissions
 */
@isTest(isParallel=true)
private class AgentManagementWebServiceHelper_Test {

    @TestSetup
    static void makeData() {

        AgentPortalTestDataFactory factory = new AgentPortalTestDataFactory();

        TriggerCommon.disableTrigger('Country_Attribute__c');
        TriggerCommon.disableTrigger('Account');
        TriggerCommon.disableTrigger('Contact');
        TriggerCommon.disableTrigger('User');


        // create a test Agent Portal User
        AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();

        // create Delegator Agencies
        List<Account> delegatorAgencies = new List<Account>();

        // create an active delegator Agency
        Account delegatorAgency = factory.createAgencyAccount(portalUser.country); // reuse the same country as the portal user, so we don't have to recreate
        delegatorAgency.Name = 'Delegator Agency';
        delegatorAgencies.add(delegatorAgency);

        // create an inactive delegator Agency
        Account inactiveDelegatorAgency = factory.createAgencyAccount(portalUser.country); // reuse the same country as the portal user, so we don't have to recreate
        inactiveDelegatorAgency.Name = 'Delegator Agency Inactive';
        delegatorAgencies.add(inactiveDelegatorAgency);

        insert delegatorAgencies;

        // create an account partner
        List<AccountPartner>  apList = new List<AccountPartner>();
        AccountPartner ap = new AccountPartner(
            AccountFromId = portalUser.acc.Id,
            AccountToId = delegatorAgency.Id,
            Role = 'Delegator'
        );
        apList.add(ap);
        insert ap; // this auto creates the inverse relationship

        TriggerCommon.enableTrigger('Country_Attribute__c');
        TriggerCommon.enableTrigger('Account');
        TriggerCommon.enableTrigger('Contact');
        TriggerCommon.enableTrigger('User');
    }

    /**
     * @description test that the elevated access selector would
     * return AccountPartner object even when running as an Experience User
     * given that their license do not provide access to the object
     */
    @isTest
    static void shouldReturnDelegatorAccountAsExperienceUser() {

        // GIVEN : a user,contact, and account detail
        User agentUser = AgentPortalTestDataFactory.util.getAgentUser();
        List<AccountPartner> apList;
        AgentManagementWebServiceHelper.ElevatedAccountPartnerSelector apSelector;

        Test.startTest();

        // WHEN : we select AccountPartner based on FromId
        System.runAs(agentUser) {
            apSelector = new AgentManagementWebServiceHelper.ElevatedAccountPartnerSelector();
            apList = apSelector.selectDelegatorByFromId(new Set<Id> { agentUser.Contact.AccountId });
        }
        
        Test.stopTest();

        // THEN : check query result
        Assert.isNotNull(apList, 'Unable query Account Partner records');
        Assert.areEqual(1, apList.size(), 'Unexpected number of Account Partner records found');
    }

    /**
     * @description test that the method would return a generic response type
     * when provided an Exception in order to hide (potentially) sensitive information
     * from the organic exception message
     */
    @isTest
    static void shouldReturnGenericErrorResponse() {

        // GIVEN : initialise services
        AgentManagementWebServiceHelper helper;
        APNG_WebServicePayload.APNG_BaseResponse response;

        Test.startTest();

        // WHEN : throw a test DMLException
        helper = new AgentManagementWebServiceHelper();
        response = helper.getErrorResponse(new DMLException('Test DML Exception'));

        Test.stopTest();

        // THEN : we get a generic response
        Assert.isNotNull(response, 'Unexpected null response');
        Assert.areEqual(false, response.success, 'Unexpected response value');
        Assert.areEqual(new DmlException().getTypeName(), response.error, 'Unexpected response value');
        Assert.areEqual(AgentManagementWebServiceHelper.RESPONSE_MSG_ERROR_GENERIC, response.description, 'Unexpected response value');
    }

    /**
     * @description test that the helper method would throw an exception
     * when the user query does not find the provided username
     */
    @isTest
    static void shouldThrowExceptionWhenUserNotFoundOnHandleGet() {

        // GIVEN : a non-existing username
        String nonExistingUserName = 'NOT_AN_EXISTING_USER010101';
        AgentManagementWebServiceHelper helper;

        Test.startTest();

        // WHEN : run handleGet
        helper = new AgentManagementWebServiceHelper();
        try {
            helper.handleGetResponse(nonExistingUserName);
            Assert.fail('Previous line is supposed to throw an exception');
        } catch(AgentManagementWebService.AgentManagementWebServiceException e) {
            // THEN : an exception should be thrown
            Assert.isTrue(true, 'Expected outcome');
        } catch(Exception e) {
            Assert.fail('Unexpected exception type');
        }

        Test.stopTest();
    }

    /**
     * @description test that the helper method would return a positive response
     */
    @isTest
    static void shouldReturnResponseOnHandleGet() {

        // GIVEN: a user,contact, and account detail
        User agentUser = AgentPortalTestDataFactory.util.getAgentUser();
        AgentManagementWebServiceHelper helper;
        APNG_WebServicePayload.APNG_AgentManagementWebService_GetResponse response;

        Test.startTest();

        // WHEN : handle get response
        helper = new AgentManagementWebServiceHelper();
        System.runAs(agentUser) {
            response = helper.handleGetResponse(agentUser.Username);
        }

        Test.stopTest();

        // THEN : we receive a positive response
        Assert.isNotNull(response, 'Unexpected null response');
        Assert.areEqual(agentUser.Id, response.userRecord?.Id, 'Unexpected user detail');
        Assert.isTrue(response.userLoginList.isEmpty(), 'Unexpected frozen user');
        Assert.areEqual(agentUser.Contact.Id, response.contactRecord.Id, 'Unexpected contact Id');
        Assert.areEqual(agentUser.Contact.AccountId, response.accountRecord.Id, 'Unexpected account Id');
        Assert.areEqual(agentUser.Contact.First_Name__c, response.contactRecord.First_Name__c, 'Unexpected contact First_Name__c');
        Assert.areEqual(agentUser.Contact.Last_Name__c, response.contactRecord.Last_Name__c, 'Unexpected account Last_Name__cs');
        // there should only be 1 based on test setup
        Assert.areEqual(1, response.accountPartnerList.size(), 'Unexpected number of account partners'); 
    }
}