/**
 * @author              Kristian Vegerano
 * @description         Utility class for enquiries
 * @History                     
 *      AUG.10.2018     Kristian Vegerano   -   Created
 */
@isTest(SeeAllData=false)
private class AgentEnquiryService_Test {
    
    @testSetup 
    static void setup(){
        //Create agency record
        Account testAgency = new Account(Name = 'TestAgency');
        insert testAgency;
        
        //Create application record
        Application__c testApplication = new Application__c();
        testApplication.Callista_Application_Id__c = '123456789';
        insert testApplication;
        
        //Create applicant record
        Contact testApplicant = new Contact(LastName = 'TestApplicantLastName', 
                                            Person_ID_unique__c = '12345678',
                                            RecordTypeId = Schema.SObjectType.Contact
                                                    .getRecordTypeInfosByName()
                                                    .get('Known to Monash systems')
                                                    .getRecordTypeId());
        insert testApplicant;
    }
	
	/**
     *  @author         Kristian Vegerano
     *  @description    Test method retrieving application record
     */
    static testMethod void testRetrieveApplicationDetails() {
        //Retrieve ApplicationId
        String testApplicationId = [SELECT Id, Callista_Application_Id__c FROM Application__c LIMIT 1].Callista_Application_Id__c;
        
        //Run test
        Test.startTest();
            Application__c testApplication = AgentEnquiryService.getApplicationDetails(testApplicationId);
        Test.stopTest();
        
        //Assert results
        System.assertNotEquals(null, testApplication);
    }
    
	/**
     *  @author         Kristian Vegerano
     *  @description    Test method for submitting agent enquiry
     */
    static testMethod void testSubmitNonExistingAgentEnquiry() {
        //Retrieve AgencyId
        Id testAgencyId = [SELECT Id FROM Account LIMIT 1].Id;
        
        //Retrieve ApplicationId
        String testApplicationId = [SELECT Id, Callista_Application_Id__c FROM Application__c LIMIT 1].Callista_Application_Id__c;
        
        //Retrieve ApplicantId
        Id testApplicantId = [SELECT Id FROM Contact LIMIT 1].Id;
        
        //Run test
        Test.startTest();
            Date todayDate = Date.TODAY();
            AgentEnquiryService.submitAgentEnquiry(testApplicationId, testAgencyId, 'Australia', testApplicantId, 
                                                   'TestAgentFirstName', 'TestAgentLastName', 'test.agent@email.test.agent.com.au', 
                                                   'TestEnquirySubject', 'TestEnquiryContent', 'Application Progress follow-up', 'TestCourse101',
                                                   (todayDate.year() + '-' + todayDate.month() + '-' + todayDate.day()));
        Test.stopTest();
        
        //Assert results
        Case agentEnquiry = [SELECT Id, Subject, Description, ContactId, Contact.FirstName, Contact.LastName, AccountId,
                                        Related_to_Contact__c, Related_to_Contact__r.FirstName, Related_to_Contact__r.LastName,
                                        Category_Level_1__c, Category_Level_2__c
                             FROM Case LIMIT 1];
                             
        System.assertNotEquals(null, agentEnquiry);
        System.assertEquals(agentEnquiry.Subject, 'TestEnquirySubject');
        System.assertEquals(agentEnquiry.Description, 'TestEnquiryContent');
        System.assertEquals(agentEnquiry.Contact.FirstName, 'TestAgentFirstName');
        System.assertEquals(agentEnquiry.Contact.LastName, 'TestAgentLastName');
        System.assertEquals(agentEnquiry.AccountId, testAgencyId);
        System.assertEquals(agentEnquiry.Related_to_Contact__r.LastName, 'TestApplicantLastName');
    }
    
    /**
     *  @author         Kristian Vegerano
     *  @description    Test method for submitting agent enquiry
     */
    static testMethod void testSubmitExistingAgentWithoutRoleEnquiry() {
        //Retrieve AgencyId
        Id testAgencyId = [SELECT Id FROM Account LIMIT 1].Id;
        
        //Retrieve ApplicationId
        String testApplicationId = [SELECT Id, Callista_Application_Id__c FROM Application__c LIMIT 1].Callista_Application_Id__c;
        
        //Retrieve ApplicantId
        Id testApplicantId = [SELECT Id FROM Contact LIMIT 1].Id;
        
        //Create Agent contact record
        Contact testAgent = new Contact(FirstName = 'TestAgentFirstName',
                                        LastName = 'TestAgentLastName',
                                        Email = 'test.agent@email.test.agent.com.au',
                                        RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Agency Contact').getRecordTypeId());
        insert testAgent;
        
        //Run test
        Test.startTest();
            Date todayDate = Date.TODAY();
            AgentEnquiryService.submitAgentEnquiry(testApplicationId, testAgencyId, 'Australia', testApplicantId, 
                                                   'TestAgentFirstName', 'TestAgentLastName', 'test.agent@email.test.agent.com.au', 
                                                   'TestEnquirySubject', 'TestEnquiryContent', 'Application Progress follow-up', 'TestCourse101',
                                                   (todayDate.year() + '-' + todayDate.month() + '-' + todayDate.day()));
        Test.stopTest();
        
        //Assert results
        Case agentEnquiry = [SELECT Id, Subject, Description, ContactId, Contact.FirstName, Contact.LastName, AccountId,
                                        Related_to_Contact__c, Related_to_Contact__r.FirstName, Related_to_Contact__r.LastName,
                                        Category_Level_1__c, Category_Level_2__c
                             FROM Case LIMIT 1];
                             
        System.assertNotEquals(null, agentEnquiry);
        System.assertEquals(agentEnquiry.Subject, 'TestEnquirySubject');
        System.assertEquals(agentEnquiry.Description, 'TestEnquiryContent');
        System.assertEquals(agentEnquiry.Contact.FirstName, 'TestAgentFirstName');
        System.assertEquals(agentEnquiry.Contact.LastName, 'TestAgentLastName');
        System.assertEquals(agentEnquiry.AccountId, testAgencyId);
        System.assertEquals(agentEnquiry.Related_to_Contact__r.LastName, 'TestApplicantLastName');
    }
    
    /**
     *  @author         Kristian Vegerano
     *  @description    Test method for submitting agent enquiry
     */
    static testMethod void testSubmitExistingAgentWithRoleEnquiry() {
        //Retrieve AgencyId
        Id testAgencyId = [SELECT Id FROM Account LIMIT 1].Id;
        
        //Retrieve ApplicationId
        String testApplicationId = [SELECT Id, Callista_Application_Id__c FROM Application__c LIMIT 1].Callista_Application_Id__c;
        
        //Retrieve ApplicantId
        Id testApplicantId = [SELECT Id FROM Contact LIMIT 1].Id;
        
        //Create Agent contact record
        Contact testAgent = new Contact(FirstName = 'TestAgentFirstName',
                                        LastName = 'TestAgentLastName',
                                        Email = 'test.agent@email.test.agent.com.au',
                                        RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Agency Contact').getRecordTypeId());
        insert testAgent;
        
        //Run test
        Test.startTest();
            Date todayDate = Date.TODAY();
            AgentEnquiryService.submitAgentEnquiry(testApplicationId, testAgencyId, 'Australia', testApplicantId, 
                                                   'TestAgentFirstName', 'TestAgentLastName', 'test.agent@email.test.agent.com.au', 
                                                   'TestEnquirySubject', 'TestEnquiryContent', 'Application Progress follow-up', 'TestCourse101',
                                                   (todayDate.year() + '-' + todayDate.month() + '-' + todayDate.day()));
        Test.stopTest();
        
        //Assert results
        Case agentEnquiry = [SELECT Id, Subject, Description, ContactId, Contact.FirstName, Contact.LastName, AccountId,
                                        Related_to_Contact__c, Related_to_Contact__r.FirstName, Related_to_Contact__r.LastName,
                                        Category_Level_1__c, Category_Level_2__c
                             FROM Case LIMIT 1];
                             
        System.assertNotEquals(null, agentEnquiry);
        System.assertEquals(agentEnquiry.Subject, 'TestEnquirySubject');
        System.assertEquals(agentEnquiry.Description, 'TestEnquiryContent');
        System.assertEquals(agentEnquiry.Contact.FirstName, 'TestAgentFirstName');
        System.assertEquals(agentEnquiry.Contact.LastName, 'TestAgentLastName');
        System.assertEquals(agentEnquiry.AccountId, testAgencyId);
        System.assertEquals(agentEnquiry.Related_to_Contact__r.LastName, 'TestApplicantLastName');
    }
    
    /**
     *  @author         Kristian Vegerano
     *  @description    Test method retrieving if the agent is verified or not
     */
    static testMethod void testGetIsAgentVerified() {
    	Account testAccount = new Account(Name = 'TestAccount');
    	insert testAccount;
    	
    	Contact testContact = new Contact(LastName = 'TestContact');
    	insert testContact;
    	
    	Roles__c testRole = new Roles__c(Account__c = testAccount.Id,
    								   Contact__c = testContact.Id,
    								   Role__c = 'Counsellor');
    	insert testRole;
    	
        Case testCase = new Case(AccountId = testAccount.Id,
        						 ContactId = testContact.Id);
        insert testCase;
        
        //Run test
        Test.startTest();
            AgentEnquiryService.getIsAgentVerified(testCase.Id);
            AgentEnquiryService.verifyAgent(testCase.Id);
        Test.stopTest();
    }
}