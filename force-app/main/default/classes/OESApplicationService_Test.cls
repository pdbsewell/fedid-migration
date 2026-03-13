/**
 * @description Test class for OESApplicationService
 * @date        06/05/2024  
 * @author      SMendu
 * @group       Admissions
 * @revision
 */
@isTest(isParallel=false)//DML operations aren't permitted on this type of object: PermissionSetAssignment
public with sharing class OESApplicationService_Test {
    @TestSetup
    static void makeData(){
        //Create Agent User make data
        TriggerCommon.disableTrigger('Country_Attribute__c');
        TriggerCommon.disableTrigger('Account');
        TriggerCommon.disableTrigger('Contact');
        TriggerCommon.disableTrigger('User');

        // STEP 1 - Create Agent Onboarding Settings
       	insert AgentPortalTestDataBuilder.factory.createAgentOnboardingSettings();

        // STEP 2 - Create a test Agent Portal User
        AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();

        TriggerCommon.enableTrigger('Country_Attribute__c');
        TriggerCommon.enableTrigger('Account');
        TriggerCommon.enableTrigger('Contact');
        TriggerCommon.enableTrigger('User');
    }


    /**
     *@description Verify running user is OES user 
     */
    @isTest
    static void shouldBeOESUser() {
        //GIVEN : Assign OES_Permission_Set(custom permission in the ps) to the User uplifting the user as OES User
        User agent = AgentPortalTestDataFactory.util.getAgentUser();
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'OES_Permission_Set'];
        PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId=agent.Id,PermissionSetId=ps.Id);
        insert psa;
        Boolean oesUser;
        //WHEN : Utility method to identify OES user is called
        System.runAs(agent){
            Test.startTest();
                oesUser = OESApplicationService.isOESUser;
            Test.stopTest();
        }
        //THEN : It must return false representing that the running user is  OES
        Assert.areEqual(true, OESApplicationService.isOESUser, 'It must be an OES user');
    }

    /*@description Verify that running user is NOT OES user 
    */
   @isTest
   static void shouldBeNotOESUser() {
       //GIVEN : A plain APNG user
       User agent = AgentPortalTestDataFactory.util.getAgentUser();
       Boolean oesUser;
        //WHEN : Utility method to identify OES user is called
        System.runAs(agent){
           Test.startTest();
              oesUser = OESApplicationService.isOESUser;
            Test.stopTest();
       }
        //THEN : It must return false representing that the running user is NOT OES
        Assert.areEqual(false, oesUser, 'It must NOT be an OES user');
   }
}