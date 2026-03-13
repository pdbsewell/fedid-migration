@isTest(isParallel=true)
public with sharing class AffiliationCheckWebService_Test {
    @TestSetup
    static void makeData() {
        Account testAccount = new Account(Name = 'TestAgencyAccount', Monash_AM_Campus__c = 'Australia');
        insert testAccount;
        Contact testContact = new Contact(FirstName = 'TestFirstName', LastName = 'TestLastName', AccountId = testAccount.Id, Email = 'TestEmail@testemail.com');
        insert testContact;
        User runUsr = [SELECT id FROM User WHERE id = :UserInfo.getUserId()];
        System.runAs(runUsr){
            Id proId =[select id from profile where name = :AgentPortalConstants.AGENT_PROFILE].id;
            Integer rnd = Integer.valueOf(Math.random()*9999);
            User u= new User();
            u.Username = String.valueOf(rnd) + 'testAgentLastName@TestEmail.com.domain';
            u.email = String.valueOf(rnd) + 'testAgentLastName@TestEmail.com';
            u.ContactId = testContact.id; 
            u.LastName ='test';
            u.Alias ='test';
            u.isActive = true;
            u.TimeZoneSidKey ='Australia/Sydney';
            u.LocaleSidKey ='en_AU';
            u.EmailEncodingKey ='ISO-8859-1';
            u.ProfileId = proId;
            u.LanguageLocaleKey ='en_US';
            insert u;
            PermissionSetGroup AgentPSG = [SELECT Id, Status FROM permissionSetGroup WHERE developername = :AgentPortalConstants.AGENT_PERMISSION_SET_GROUP]; 
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId=u.Id,PermissionSetGroupId=AgentPSG.Id);
            // force calculation of the PSG if it is not already Updated
            if (AgentPSG.Status != 'Updated') {
                Test.calculatePermissionSetGroup(AgentPSG.Id);
            }            
            insert psa;
        }
        Contact applicant = new Contact(FirstName = 'TestApplicant', LastName = 'ApplicantLastName', Email = 'applicant941811@testemail.com');
        insert applicant;
    }
    @isTest
    private static void testcheckAffiliation_Positive() {
        Contact con = [SELECT CRM_ID__c FROM Contact WHERE Email ='TestEmail@testemail.com' LIMIT 1];
        User u = [SELECT id FROM User WHERE username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1 ];

        RestRequest req = new RestRequest();
        req.httpMethod = 'GET';
        req.params.put('contactId',con.CRM_ID__c);
        req.params.put('campusLocation','Australia');
        RestContext.request = req;        
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        System.runAs(u){
            AffiliationCheckWebService.checkAffiliation();
        }
        System.assert(res.responseBody.toString().containsIgnoreCase('canCreateApplications'), 'AffiliationCheckWebService failed' );
    }
    @isTest
    private static void testcheckAffiliation_Negative() {
        Contact con = [SELECT CRM_ID__c FROM Contact WHERE Email ='TestEmail@testemail.com' LIMIT 1];
        User u = [SELECT id FROM User WHERE username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1 ];

        RestRequest req = new RestRequest();
        req.httpMethod = 'GET';
        req.params.put('contactId',con.CRM_ID__c);
        RestContext.request = req;        
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        System.runAs(u){
            AffiliationCheckWebService.checkAffiliation();
        }
        System.assert(res.responseBody.toString().containsIgnoreCase('Campus Location cannot be empty'), 'AffiliationCheckWebService failed' );
    }
}