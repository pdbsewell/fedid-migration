/**
 * @description Test class for AgentPortalApplicationService
 * @author      Nick Guia
 * @date        FEB.23.2024
 */
@isTest(isParallel=true)
private class AgentPortalApplicationService_Test {

    private static String AGENCY_ORG_UNIT_CODE = 'APP_TEST';

    @TestSetup
    static void makeData() {

        AgentPortalTestDataFactory factory = new AgentPortalTestDataFactory();

        TriggerCommon.disableTrigger('Country_Attribute__c');
        TriggerCommon.disableTrigger('Account');

        Country_Attribute__c auCountry = factory.createCountryAttribute(BDPConstants.AUSTRALIA_CALLISTA_CODE, 'AUSTRALIA');
        insert auCountry;

        Account agency = factory.createAgencyAccount(auCountry);
        agency.Callista_Org_Unit_Code__c = AGENCY_ORG_UNIT_CODE;
        insert agency;

        Contact branchMgr = factory.createAgentContact(agency);
        branchMgr.Agency_Contact_Roles__c = 'Branch Manager';
        insert branchMgr;

        // use runAs to avoid DML exception
        System.runAs(new User(Id = UserInfo.getUserId())) {
            User bmUser = factory.createAgentUser(branchMgr);
            insert bmUser;

            PermissionSetAssignment psa = factory.createAgentPermissionSetAssignment(bmUser);
            insert psa;
        }
        
        TriggerCommon.enableTrigger('Country_Attribute__c');
        TriggerCommon.enableTrigger('Account');
    }

    /**
     * @description should populate fields to track the first time
     * that an Agent sends the application to the applicant for review
     */
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
    @isTest
    static void shouldPopulateRevisionFieldsOfApplication() {

        // GIVEN
        Application__c testApp = new Application__c();
        testApp.Sent_to_student_for_review_Timestamp__c = Datetime.now();
        AgentPortalApplicationService service;

        Test.startTest();

        // WHEN
        service = new AgentPortalApplicationService();
        testApp = service.populateRevisionFields(testApp);

        Test.stopTest();

        // THEN
        Assert.isTrue(testApp.Agent_Edits_After_Applicant_Acceptance__c, 'Did not track Agent edits after an Applicant acceptance');
        Assert.isNotNull(testApp.Sent_to_student_for_review_Timestamp__c, 'Unable to capture timestamp of sending application to applicant');
    }
    
    /**
     * @description when delegating an application, the Agency must be reassigned to the
     * Account record indicated by the Delegator_Org_Unit_Code__c
     */
    @isTest
    static void shouldDelegateApplication() {

        // GIVEN : setup data

        // create a mock application
        Application__c mockApp = new Application__c(
            Id = fflib_IDGenerator.generate(Application__c.SObjectType),
            Agent__c = fflib_IDGenerator.generate(Account.SObjectType),
            Status__c = 'Submitted',
            Agent_Org_Unit_Code__c = 'MOCK_UNIT_CODE',
            Delegator_Org_Unit_Code__c = AGENCY_ORG_UNIT_CODE
        );

        // get account from test setup
        Id agencyRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                                    .get('Agency')
                                    .getRecordTypeId();
        
        Account expectedDelegator = [SELECT Id, Callista_Org_Unit_Code__c,
                                        (SELECT Id FROM Contacts WHERE Agency_Contact_Roles__c INCLUDES ('Branch Manager'))
                                    FROM Account
                                    WHERE RecordTypeId = :agencyRecTypeId
                                    AND Callista_Org_Unit_Code__c = :AGENCY_ORG_UNIT_CODE
                                    LIMIT 1];
        Assert.isTrue(!expectedDelegator.Contacts.isEmpty(), 'Delegator Agency does not have a Branch Manager');
        Contact bm = expectedDelegator.Contacts[0];
        User bmUser = [SELECT Id FROM User WHERE ContactId = :bm.Id LIMIT 1];

        List<Application__c> appResult;

        AgentPortalApplicationService service;

        Test.startTest();

        // WHEN: delegateApplication process runs
        service = new AgentPortalApplicationService();
        appResult = service.delegateApplication(new List<Application__c>{ mockApp });

        Test.stopTest();

        // THEN : Agency should change, and owner should be the new Agency's BM
        Assert.areEqual(1, appResult.size(), 'Unexpected number of Applications');
        Assert.areEqual(expectedDelegator.Id, appResult[0].Agent__c, 'Unable to delegate Application Agency');
        Assert.areEqual(expectedDelegator.Callista_Org_Unit_Code__c, appResult[0].Agent_Org_Unit_Code__c, 'Unable to delegate Application Agency');
        Assert.areEqual(bmUser.Id, mockApp.OwnerId, 'Unable to transfer ownership to new Agency BM');
    }

    /**
     * @description when delegating an application, the Agency must be reassigned to the
     * Account record indicated by the Delegator_Org_Unit_Code__c. If no Account exists with such
     * code, the method should log an exception
     */
    @isTest
    static void shouldThrowAnExceptionWhenDelegatingApplicationAndOrgUnitCodeDoesNotExist() {

        // GIVEN

        // create a mock application with a random Delegator_Org_Unit_Code__c
        Application__c mockApp = new Application__c(
            Id = fflib_IDGenerator.generate(Application__c.SObjectType),
            Agent__c = fflib_IDGenerator.generate(Account.SObjectType),
            Status__c = 'Submitted',
            Agent_Org_Unit_Code__c = 'MOCK_UNIT_CODE',
            Delegator_Org_Unit_Code__c = 'DNE' // does not exist
        );

        AgentPortalApplicationService service;

        Test.startTest();

        // WHEN
        service = new AgentPortalApplicationService();
        List<Application__c> appResult = service.delegateApplication(new List<Application__c>{ mockApp });

        // explicitly save logs
        Nebula.Logger.saveLog();

        Test.stopTest();

        // THEN
        List<Nebula__LogEntry__c> logs =  [SELECT Id, Nebula__OriginLocation__c
                                            FROM Nebula__LogEntry__c
                                            WHERE Nebula__OriginLocation__c = 'AgentPortalApplicationService.delegateApplication'];
        Assert.isTrue(!logs.isEmpty(), 'Unable to generate Exception Logs');
    }
}