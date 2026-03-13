/**
 * @description Test Class for ApplicantCaseServices
 * @author      Vinothraja
 * @date        27/09/2023       
 * @group       Admissions
 */
@isTest(isParallel=true)
private class ApplicantCaseServices_Test {
	@TestSetup
	static void makeData(){
        TriggerCommon.disableTrigger('Country_Attribute__c');
        TriggerCommon.disableTrigger('Account');
        TriggerCommon.disableTrigger('Contact');
        TriggerCommon.disableTrigger('User');
        // Custom Settings setup
        Account testaccount = new Account(name='Monash University Global',recordtypeid=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organization').getRecordTypeId());
        insert testaccount;

        Global_Monash_Account__c cusSet = new Global_Monash_Account__c();
        cusSet.id__c= string.valueOf(testaccount.Id);
        Insert cusSet;

        // STEP 1 - Create Agent Onboarding Settings
       	insert AgentPortalTestDataBuilder.factory.createAgentOnboardingSettings();

        // STEP 2 - Create a test Agent Portal User
        AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();

        // STEP 3 - Create a valid Applicant/Application
        AgentPortalTestDataBuilder.Application app = new AgentPortalTestDataBuilder.Application().withAgent(portalUser).build();

        TriggerCommon.enableTrigger('Country_Attribute__c');
        TriggerCommon.enableTrigger('Account');
        TriggerCommon.enableTrigger('Contact');
        TriggerCommon.enableTrigger('User');
	}
    /*
    * Tests whether the incoming enquiry records are associated with the linked ACP's Agency 
	*/
	@IsTest
	static void testPopulateExternalStakeholder() {
        // GIVEN
        Contact applicant = [SELECT id, name, Person_ID_unique__c FROM Contact WHERE Person_ID_unique__c ='12345678' LIMIT 1];
        Contact agent = [SELECT id FROM Contact WHERE Email = 'TestEmail@testemail.com' LIMIT 1];
		Application__c application = [SELECT id, Applicant__c, Agent__c, Agent_Org_Unit_Code__c FROM Application__c WHERE Applicant__r.Person_ID_unique__c ='12345678' LIMIT 1];
        Application_Course_Preference__c acp = [SELECT id, Application_Agent_Code__c  FROM Application_Course_Preference__c WHERE Application__c = :application.id LIMIT 1];
        
        // WHEN
        AgentPortalTestDataFactory apTDF = new AgentPortalTestDataFactory();
		Test.startTest();
			Case enquiry = apTDF.createAgentEnquiry(applicant, agent, acp);
			insert enquiry;
		Test.stopTest();

        // THEN
        // check whether the External Stakeholder field is populated with the ACP-Application's Agency (Account.Id)
		enquiry = [SELECT External_stakeholder__c FROM Case LIMIT 1];
		Assert.areEqual(application.Agent__c, enquiry.External_stakeholder__c, 'Populating External Stakeholder failed');
	}
    /*
    * Tests whether the incoming enquiry records are populated with Agent's email
	*/
	@IsTest
	static void shouldPopulateExternalStakeholderEmail() {
		// GIVEN
		// A valid Applicant
        Contact applicant = [SELECT id, name, Person_ID_unique__c FROM Contact WHERE Person_ID_unique__c ='12345678' LIMIT 1];
		// A valid Agent
		User agent = AgentPortalTestDataFactory.util.getAgentUser();
		// A valid Application
		Application__c application = [SELECT id, Applicant__c, Agent__c, Agent_Org_Unit_Code__c FROM Application__c WHERE Applicant__r.Person_ID_unique__c ='12345678' LIMIT 1];
        Application_Course_Preference__c acp = [SELECT id, Application_Agent_Code__c  FROM Application_Course_Preference__c WHERE Application__c = :application.id LIMIT 1];
        
        AgentPortalTestDataFactory apTDF = new AgentPortalTestDataFactory();
		System.runAs(agent){
			Test.startTest();
				// WHEN
				// An Enquiry is created
				Case enquiry = apTDF.createAgentEnquiry(applicant, new Contact(id = agent.ContactId), acp);
				insert enquiry;
			Test.stopTest();
		}

		// THEN
        // The External Stakeholder Email is populated with the Agent's email
		Case enquiry = [SELECT External_stakeholder_email__c FROM Case LIMIT 1];
		Assert.areEqual(agent.contact.Email, enquiry.External_stakeholder_email__c, 'External Stakeholder Email not populated');
	}

}