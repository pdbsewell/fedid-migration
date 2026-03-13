/**
 * @Class              : Contact_Qual_BI_Populate_ExternalId_FT.cls
 * @Description        : Test class for for Contact Qual BI Populate ExternalId after record trigger flow 
 * @Author             : SMendu
 * @Group              : Admissions
 * @Revision           : 
 * 2024-06-18        Created 
 */
@isTest(isParallel=false)//PermissionSet Assingment and User create cannot happen with Parallel testing
private  class Contact_Qual_BI_Populate_ExternalId_FT {

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
        * @description: Tests whether UpdateApplication for OES updates Fee payment to false
        */
        @isTest 
        private static void shouldPopulateContactQualificationExternalIDForOES() {
        
            // data setup
            Country_Attribute__c austria = new Country_Attribute__c();
            austria.uniqueCountryExternalId__c  = 'ABCDEFGHI';
            austria.Country__c = 'Austria';
            insert austria;

            String admissionTestRecTypeId = [SELECT Id, Name, sObjectType FROM RecordType WHERE DeveloperName = 'Admission_Test'].Id;
            Qualification__c qualificationEnglishTest = new Qualification__c(
                    RecordTypeId = admissionTestRecTypeId,
                    Available_on_Portal__c = true,
                    Qualification_Name__c = 'SMCL English Test',
                    Callista_Code__c = '0909ds',
                    Qualification_UID__c = '0909ds'

            );
            insert qualificationEnglishTest; 
            
            Qualification__c retQual = [select Qualification_UID__c from Qualification__c where id=:qualificationEnglishTest.Id];

            // GIVEN - A valid OES agent creates Application data
            // A valid Agent Portal Agent
            User agent = AgentPortalTestDataFactory.util.getAgentUser();
            User userx = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true  LIMIT 1];
            
            //Assign OES_Permission_Set as System Admin to avoid cannot perform DML on what salesforce
            //calls setup objects(User,Profile,Group,RecordType in this case) and non-setup object in the same context
            System.runAs(userx)
            {
                //Assign OES permission set to uplift AgentPortal user as OES user
                PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'OES_Permission_Set'];
                PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId=agent.Id, PermissionSetId=ps.Id);
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

                // Construct a Contact Qualification record
                Contact_Qualification__c conQual = new Contact_Qualification__c();
                conQual.Qualification__c = qualificationEnglishTest.Id;
                conQual.Contact__c = applicant.Id;
                
                // WHEN- Contact_Qualification__c is inserted against the applicant
                Test.startTest();
                    insert conQual;
                Test.stopTest();

                //THEN - External_ID__c must have been populated on the Contact_Qualification__c record 
                Assert.isTrue(([select External_ID__c from contact_qualification__c where id=:conQual.Id].External_ID__c!=null), 'External ID must be populated');

            }
        }
    
}