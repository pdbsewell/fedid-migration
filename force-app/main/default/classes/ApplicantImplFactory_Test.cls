/**
 * @description Test class for ApplicantImplFactory.
 * @author      Nick Guia
 * @since       AUG.02.2024
 */
@isTest(isParallel=false) // APEX_DATA_ACCESS_RESTRICTION
private class ApplicantImplFactory_Test {
    
    /**
     * @description When an OES user invokes the factory class, it should return
     * the OES implementation of the API
     */
    @isTest
    static void shouldReturnOESImplementationWhenRunningUserIsOES() {

        // GIVEN : An OES User
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

        // avoid MIXED_DML_OPERATION
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert psa;
        }
        
        TriggerCommon.enableTrigger('Country_Attribute__c');
        TriggerCommon.enableTrigger('Account');
        TriggerCommon.enableTrigger('Contact');
        TriggerCommon.enableTrigger('User');

        RestRequest req = new RestRequest();
        req.requestURI = 'TEST/ONLY';
        RestContext.request = req;
        RESTlib_IClientImpl actual;

        Test.startTest();

        // WHEN : The factory class is invoked
        System.runAs(portalUser.testUser) {
            actual = new ApplicantImplFactory().getImplementation();
        }

        Test.stopTest();

        // THEN : It should return the OES specific implementation
        Assert.isInstanceOfType(actual, OESApplicantImpl.class, 'Unexpected return type from the implementation factory');
    }

    /**
     * @description When an APNG user invokes the factory class, it should return
     * the APNG implementation of the API
     */
    @isTest
    static void shouldReturnAPNGImplementationWhenRunningUserIsAgent() {
        // GIVEN : An APNG User
        TriggerCommon.disableTrigger('Country_Attribute__c');
        TriggerCommon.disableTrigger('Account');
        TriggerCommon.disableTrigger('Contact');
        TriggerCommon.disableTrigger('User');

        AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();

        TriggerCommon.enableTrigger('Country_Attribute__c');
        TriggerCommon.enableTrigger('Account');
        TriggerCommon.enableTrigger('Contact');
        TriggerCommon.enableTrigger('User');

        RestRequest req = new RestRequest();
        req.requestURI = 'TEST/ONLY';
        RestContext.request = req;
        RESTlib_IClientImpl actual;

        Test.startTest();

        // WHEN : The factory class is invoked
        System.runAs(portalUser.testUser) {
            actual = new ApplicantImplFactory().getImplementation();
        }

        Test.stopTest();

        // THEN : It should return the OES specific implementation
        Assert.isInstanceOfType(actual, APNGApplicantImpl.class, 'Unexpected return type from the implementation factory');
    }
}