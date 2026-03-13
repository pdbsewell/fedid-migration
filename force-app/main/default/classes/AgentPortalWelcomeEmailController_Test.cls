/*
 * @author       SMendu
 * @date         26/06/2023
 * @description  test class for AgentPortalWelcomeEmailController class
 */
@isTest
public with sharing class AgentPortalWelcomeEmailController_Test {
    @testSetup static void setup() {
        // Enable the linking of applications and ACP to the branch manager of an Agency
        Feature_Switch__c fs = new Feature_Switch__c();
        fs.Align_Application_Owner__c = true;
        fs.Align_ACP_Owner__c = true;
        insert fs;
        
        Agent_Onboarding_Settings__c setting = new Agent_Onboarding_Settings__c(Role_RT_Developer_Name__c = 'Agency_Contact_Role');
        insert setting;
        Country_Attribute__c australia = new Country_Attribute__c(Name = 'AUSTRALIA',
                                                                  Callista_Code__c = BDPConstants.AUSTRALIA_CALLISTA_CODE,
                                                                  Country__c = 'Australia');
        insert australia;
        Account testAgency = new Account(Name = 'TestAgencyAccount', Callista_Org_Unit_Code__c = 'TSTAG', Monash_AM_Campus__c = 'Australia', Status__c = 'Appointed', City__c = 'Perth', Country_Lookup__c = australia.id, Post_Code__c = '2170', Email__c = 'Agent@TestAgencyAccount.com.domain', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Agency').getRecordTypeId());
        insert testAgency;
        Id agentRecType = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Agency_Contact').getRecordTypeId(); 

        Contact testAgentCon = new Contact(RecordTypeId=agentRecType, FirstName = 'TestFirstName', LastName = 'TestLastName', AccountId = testAgency.Id
                                        , Email = 'TestEmail@testemail.com', Agency_Contact_Roles__c = 'Branch Manager;Delegated Admin');
        insert new List<Contact> {testAgentCon};
        User runUsr = [SELECT id FROM User WHERE id = :UserInfo.getUserId()];
        System.runAs(runUsr){
            Id proId =[select id from profile where name = :AgentPortalConstants.AGENT_PROFILE].id;
            Integer rnd = Integer.valueOf(Math.random()*9999);
            User testAgentUser = new User();
            testAgentUser.Username = String.valueOf(rnd) + 'testAgentLastName@TestEmail.com.domain';
            testAgentUser.email = String.valueOf(rnd) + 'testAgentLastName@TestEmail.com';
            testAgentUser.ContactId = testAgentCon.id; 
            testAgentUser.LastName ='test';
            testAgentUser.Alias ='test';
            testAgentUser.isActive = true;
            testAgentUser.TimeZoneSidKey ='Australia/Sydney';
            testAgentUser.LocaleSidKey ='en_AU';
            testAgentUser.EmailEncodingKey ='ISO-8859-1';
            testAgentUser.ProfileId = proId;
            testAgentUser.LanguageLocaleKey ='en_US';
            insert testAgentUser;
            
            PermissionSetGroup agentPSG = [SELECT Id, Status FROM permissionSetGroup WHERE developername = :AgentPortalConstants.AGENT_PERMISSION_SET_GROUP]; 
            // force calculation of the PSG if it is not already Updated
            if (agentPSG.Status != 'Updated') {
                Test.calculatePermissionSetGroup(agentPSG.Id);
            }
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId=testAgentUser.Id,PermissionSetGroupId=agentPSG.Id);
            insert psa;
        }
    }

      /**
     * @author      Shalini Mendu
     * @description Tests retrieveing AgentPortal applicant contact details on welcome email
     * @revision    26/06/2023 - SMendu - Created
     */
    @isTest 
    static void test_RetrieveAgentDetails(){
        User u = [SELECT id, ContactId, Contact.AccountId FROM User WHERE username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1 ];
        AgentPortalWelcomeEmailController emailTemplateController = null;
            Test.startTest();
            System.runAs(u){
                emailTemplateController = new AgentPortalWelcomeEmailController();
                emailTemplateController.UserContactID = u.ContactId;
                emailTemplateController.contactEmail = 'testemail@getnada.com';
                emailTemplateController.networkUrlForUserEmails = 'testemail';
            }
            Test.stopTest();
            System.assertEquals('test', emailTemplateController.getUserFirstName(), 'It should retrieve test as the name');
            System.assertEquals('Branch Manager;Delegated Admin', emailTemplateController.getAgentContactRole(), 'It should retrieve Branch Manager;Delegated Admin as the name');
            System.assertEquals('TestAgencyAccount', emailTemplateController.getAgentAgencyName(), 'It should retrieve TestAgencyAccount as the name');
    }
}