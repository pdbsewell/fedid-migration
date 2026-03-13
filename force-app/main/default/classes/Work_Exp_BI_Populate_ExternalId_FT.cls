/**
 * @Class              : Work_Exp_BI_Populate_ExternalId_FT.cls
 * @Description        : Test class for for Work Exp: BI : Populate ExternalId after record trigger flow 
 * @Author             : SMendu
 * @Group              : Admissions
 * @Revision           : 
 * 2024-06-18        Created 
 */
@isTest(isParallel=false)//PermissionSet Assingment and User create cannot happen with Parallel testing
    private  class Work_Exp_BI_Populate_ExternalId_FT {
        @TestSetup
        static void makeData(){
            AgentPortalTestDataFactory factory = new AgentPortalTestDataFactory();

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
    
    /*
    * @description: Tests whether WorkExperience ExternalId gets populated on WorkExperience insert
    */
    @isTest 
    private static void shouldPopulateWorkExperienceExternalIDForOES() {
    
        // GIVEN - A valid OES agent creates Application data
        // A valid Agent Portal Agent
        User agent = AgentPortalTestDataFactory.util.getAgentUser();

        User u = [SELECT id, Username, ContactId FROM User WHERE Username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1];
        User userx = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true  LIMIT 1];
        //Assign OES_Permission_Set as System Admin to avoid cannot perform DML on what salesforce
        //calls setup objects(User,Profile,Group,RecordType in this case) and non-setup object in the same context
        System.runAs(userx)
        {
            //Assign OES permission set to uplift AgentPortal user as OES user
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'OES_Permission_Set'];
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId=u.Id, PermissionSetId=ps.Id);
            insert psa;
        }

        //Run as OES Agent
        System.runAs(agent)
        {
            // A valid Applicant
            Contact applicant = AgentPortalTestDataBuilder.factory.createApplicantContact();
            applicant.LastName = 'Test Last';
            applicant.FirstName = 'Test First';
            applicant.Last_Name__c = applicant.LastName;
            insert applicant;

            // Construct a Work_Experience__c record
            Work_Experience__c wex1 = new Work_Experience__c(Contact__c = applicant.id, Position__c = 'CEO', Employer_Name__c = 'Papa Afghanistan');
            
            // WHEN- Work_Experience__c is inserted against the applicant
            Test.startTest();
                insert wex1;
            Test.stopTest();
            
            //THEN - External_ID__c must have been populated on the Work_Experience__c record 
            Assert.isTrue(([select External_ID__c from Work_Experience__c where id=:wex1.Id].External_ID__c!=null), 'External ID must be populated');

        }
    }

}