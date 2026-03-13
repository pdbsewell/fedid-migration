/**
* @author Shalini Mendu
* @date 30.03.2023
* @Revised 09.02.2024 - Revised from scratch to match the revised main class
* @group Test Class
* @description Test Class of AdAffiliationmanageService
*/
@isTest(isParallel=true)
public class AffiliationManageService_Test {
     /**
     * @description Set up data
     */
    @testSetup
    static void setup() {
         // STEP 1 - Disable relevant triggers
        TriggerCommon.disableTrigger('Country_Attribute__c');
        TriggerCommon.disableTrigger('Account');
        TriggerCommon.disableTrigger('Contact');
        TriggerCommon.disableTrigger('User');
        TriggerCommon.disableTrigger('Application__c');
        TriggerCommon.disableTrigger('Application_Course_Preference__c');
       
        // STEP 2 - Create a test Agent Portal User
        AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();
     
        // STEP 3 - create a test Application as the portal user
        AgentPortalTestDataBuilder.Application testApplication = new AgentPortalTestDataBuilder.Application()
                                                                    .withAgent(portalUser)
                                                                    .build();
      

        Account acc = [select id from Account where name like 'TestAgencyAccount%'];
         // STEP 4 - Enable all the disabled triggers back
        TriggerCommon.enableTrigger('Application__c');
        TriggerCommon.enableTrigger('Application_Course_Preference__c');
        TriggerCommon.enableTrigger('Country_Attribute__c');
        TriggerCommon.enableTrigger('Account');
        TriggerCommon.enableTrigger('Contact');
        TriggerCommon.enableTrigger('User');
 
    }

    /**
     * @description Test to verify Affiliation created has Edit role
     */
    @isTest
    static void shouldCreateCreateEditAffiliationSharing(){
         // GIVEN
        AffiliationManageService service =  new AffiliationManageService();
        //Query Application
        Application__C app = [select id, Source_System__c, Callista_Application_Id__c, Applicant__c, Agent__c from Application__c];
        Test.startTest();
            // WHEN
            service.upserAffiliationsFromApplication(new List<Application__c>{app});
        Test.stopTest();
        // THEN
        Assert.areEqual('Edit', [select Share_Contact_to_Account_Role__c from Affiliation__c].Share_Contact_to_Account_Role__c, 'The affiliation must have Edit sharing role');
    }

    /**
     * @description Test to verify Affiliation created has Read role
     */
    @isTest
    static void shouldCreateCreateReadAffiliationSharing(){
        // GIVEN
        AffiliationManageService service =  new AffiliationManageService();
        //Query Application
        Application__C app = [select id, Source_System__c, Callista_Application_Id__c, Applicant__c, Agent__c from Application__c];
        Affiliation__c newAff  = null;
        Test.startTest();
            // WHEN
            newAff = service.createAgencyAccessFromApplication(app);
        Test.stopTest();    
         // THEN
         Assert.areEqual('Read', newAff.Share_Contact_to_Account_Role__c, 'The affiliation must have Read access');
    
    }

    /**
     * @description Test to verify Affiliation created has No Sharing role
     */
    @isTest
    static void shouldUpdateToNoSharingAffiliationSharing(){
         // GIVEN
        AffiliationManageService service =  new AffiliationManageService();
        //Query Application
        Application__C app = [select id, Source_System__c, Callista_Application_Id__c, Applicant__c, Agent__c from Application__c];
        Affiliation__c oldAff = null;
        Test.startTest();
            // WHEN
            oldAff =  service.removeAgencyAccessFromApplication(app);
        Test.stopTest();    
        // THEN 
        Assert.areEqual('No Sharing', oldAff.Share_Contact_to_Account_Role__c, 'The affiliation must have No Sharing access');
     
    }

}