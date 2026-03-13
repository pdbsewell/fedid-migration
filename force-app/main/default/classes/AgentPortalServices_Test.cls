/**
 * @description       : 
 * @author            : Ben Greenland
 * @group             : 
 * @last modified on  : 2024-07-03
 * @last modified by  : Ben Greenland
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.1  2024-05-06   Ben Greenland   Update test classes 
**/
@isTest(isParallel=false)// In parallel Apex tests, DML operations aren't permitted on this type of object: UserLogin: []
public with sharing class AgentPortalServices_Test {
    
    @TestSetup
    public static void makeData(){
        // Enable the linking of applications and ACP to the branch manager of an Agency
		Feature_Switch__c fs = new Feature_Switch__c();
        fs.Align_Application_Owner__c = true;
        fs.Align_ACP_Owner__c = true;
        insert fs;

        Environment_Settings__c es = new Environment_Settings__c();
        es.AgentPortal_Affiliation__c = true;
        es.CampusLocation_Australia__c = true;
        es.CampusLocation_Malaysia__c = true;
        es.CampusLocation_Indonesia__c = true;
        es.StudyType_Australia__c = 'Coursework, Exchange';
        es.StudyType_Malaysia__c = 'Coursework';
        es.StudyType_Indonesia__c = 'Coursework'; 
        es.ResidencyStatus_DOMAUS__c =true;
        insert es;

        List<SystemDataOwnersSetting__c> DataOwnerList = new List<SystemDataOwnersSetting__c>();
        SystemDataOwnersSetting__c accountDataOwner = new SystemDataOwnersSetting__c();
        accountDataOwner.Name = 'Account System Data Owner';
        accountDataOwner.FederationId__c = 'randomacc123';
        accountDataOwner.object__c = 'Account'; 
        DataOwnerList.add(accountDataOwner);
        SystemDataOwnersSetting__c contactDataOwner = new SystemDataOwnersSetting__c();
        contactDataOwner.Name = 'Contact System Data Owner';
        contactDataOwner.FederationId__c = 'randomacc345';
        contactDataOwner.object__c = 'Contact';
        DataOwnerList.add(contactDataOwner);
        SystemDataOwnersSetting__c systemownerDetail = new SystemDataOwnersSetting__c();
        systemownerDetail.Name = 'SystemOwnerDetail';
        systemownerDetail.ValidRecordTypes__c = 'applicant';
        systemownerDetail.ByPassUser__c = '0012A00000abcde';
        DataOwnerList.add(systemownerDetail);
        insert DataOwnerList;
        
        Agent_Onboarding_Settings__c setting = new Agent_Onboarding_Settings__c(Role_RT_Developer_Name__c = 'Agency_Contact_Role');
        insert setting;
        Country_Attribute__c australia = new Country_Attribute__c(Name = 'AUSTRALIA',
                                                                  Callista_Code__c = BDPConstants.AUSTRALIA_CALLISTA_CODE,
                                                                  Country__c = 'Australia');
        insert australia;
        Account testAgency = new Account(Name = 'TestAgencyAccount', Callista_Org_Unit_Code__c = 'TSTAG', Monash_AM_Campus__c = 'Australia', Status__c = 'Appointed', City__c = 'Perth', Country_Lookup__c = australia.id, Post_Code__c = '2170', Email__c = 'Agent@TestAgencyAccount.com.domain', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Agency').getRecordTypeId());
        insert testAgency;

        Id agentRecType = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Agency_Contact').getRecordTypeId(); 

        Contact testAgentCon = new Contact(RecordTypeId = agentRecType, FirstName = 'TestFirstName', LastName = 'TestLastName', AccountId = testAgency.Id
                                        , Email = 'TestEmail@testemail.com', Agency_Contact_Roles__c = 'Branch Manager; Delegated Admin');
        Contact secondAgentContact = new Contact(RecordTypeId = agentRecType, FirstName = 'Carborundum', LastName = 'TestLastName', AccountId = testAgency.Id, Email = 'TestEmail1996@testemail.com', Agency_Contact_Roles__c = 'Counsellor');
        insert new List<Contact> {testAgentCon, secondAgentContact};
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
            
            PermissionSetGroup AgentPSG = [SELECT Id, Status FROM permissionSetGroup WHERE developername = :AgentPortalConstants.AGENT_PERMISSION_SET_GROUP]; 
            // force calculation of the PSG if it is not already Updated
            if (AgentPSG.Status != 'Updated') {
                Test.calculatePermissionSetGroup(AgentPSG.Id);
            }
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId=testAgentUser.Id,PermissionSetGroupId=AgentPSG.Id);
            insert psa;

        }
    }
    
    @isTest
    private static void testCreateApplicant() {
        User u = [SELECT id FROM User WHERE username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1 ];
        Contact con = new Contact(First_Name__c = 'Test', Last_Name__c = 'Test Last', Personal_email__c = 'test123@getnad.com', BirthDate = Date.valueOf('2003-02-01'));
        Test.startTest();
        System.runAs(u){
            con = AgentPortalServices.createApplicant(con, u.id);
        }
        Test.stopTest();
        Assert.isTrue(String.isNotBlank(con.id) && String.isNotBlank(con.CRM_id__c), 'Applicant creation failed');
        Assert.areEqual(1, [SELECT id FROM Email__c WHERE Contact__c = :con.id]?.size(), 'Create Applicant - CPA - failed');
    }
    
    @isTest
    private static void testGetResidencyStatus() {
        User u = [SELECT id FROM User WHERE username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1 ];
        Object o;
        // Positive scenario
        System.runAs(u){
            o = AgentPortalServices.getResidencyStatus(u.id);
        }
        System.assert(o != null && JSON.serialize(o).containsIgnoreCase('DOM-AUS'), 'Fetching Residency Statuses failed');
        // Negative scenario
        String userId = UserInfo.getUserId();
        String errorMessage = '';
        try{
            o = AgentPortalServices.getResidencyStatus(userId);
        } catch(Exception e) {
            errorMessage = e.getMessage();
        }
        //System.assert(errorMessage.containsIgnoreCase('Insufficient permissions: secure query included inaccessible field'), 'Fetching Residency Statuses failed');
    }
    
    @isTest
    private static void testGetPhoneNumber() {
        List<AgentPortalPayload.Phone> phoneNos = new List<AgentPortalPayload.Phone> ();
        AgentPortalPayload.Phone ph = new AgentPortalPayload.Phone();
        ph.phoneNumber = '123';
        ph.type = 'HomePhone';
        phoneNos.add(ph);
        ph = new AgentPortalPayload.Phone();
        ph.phoneNumber = '456';
        ph.type = 'MobilePhone';
        phoneNos.add(ph);
        // Positive scenario
        String mob = AgentPortalServices.getPhoneNumber(phoneNos, 'MobilePhone');
        System.assert(mob.equals('456'), 'getPhoneNumber positive scenario failed');
        // negative scenario
        mob = AgentPortalServices.getPhoneNumber(phoneNos, 'Fax');
        System.assert(mob.equals(''), 'getPhoneNumber negative scenario failed');
    }
    
    @isTest
    private static void testGetEmail() {
        List<AgentPortalPayload.Email> emails = new List<AgentPortalPayload.Email> ();
        AgentPortalPayload.Email em = new AgentPortalPayload.Email();
        em.email = '1@2.com';
        em.type = 'Personal Email';
        emails.add(em);
        em = new AgentPortalPayload.Email();
        em.email = '3@4.com';
        em.type = 'Business Email';
        emails.add(em);
        // Positive scenario
        String eml = AgentPortalServices.getEmail(emails, 'Personal Email');
        System.assert(eml.equals('1@2.com'), 'getEmail positive scenario failed');
        // negative scenario
        eml = AgentPortalServices.getEmail(emails, 'Official Email');
        System.assert(eml.equals(''), 'getEmail negative scenario failed');
    }
    
    @isTest
    private static void testCreateApplication() {
        User u = [SELECT id, Contact.AccountId, contact.Account.Callista_Org_Unit_Code__c FROM User WHERE username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1 ];
        Contact con = new Contact(First_Name__c = 'Test', Last_Name__c = 'Test Last', Personal_email__c = 'test123@getnad.com', BirthDate = Date.valueOf('2003-02-01'), OwnerId = u.id);
        insert con;
        
        // TODO :: Affiliation based check has to be inserted here
        Application__c appPositive = new Application__c (Applicant__c = con.id, Agent__c = u.Contact.AccountId, Status__c =  'Draft', Source_System__c = 'AgentPortal', Residency_Status__c = 'INTRNTNL');
        Application__c appNegative = new Application__c (Applicant__c = con.id, Status__c =  'Draft', Source_System__c = 'AgentPortal', Residency_Status__c = 'ABC');
        String errorMessage = '';
        Test.startTest();
            System.runAs(u){
                // Negative scenario - failed insert 
                try{
                    appNegative = (Application__c) AgentPortalServices.createApplication(appNegative, '123@abc.com', '345');
                } catch (Exception e) {
                    errorMessage = e.getMessage();
                }
                // Positive scenario
                appPositive = (Application__c) AgentPortalServices.createApplication(appPositive, '123@abc.com', '345');
                // Helper - Check if there are existing drafts for the Applicant
                Assert.isFalse(AgentPortalServices.doOtherDraftsExistForSameCampus(con.id, 'Australia', new Set<String> {u.contact.Account.Callista_Org_Unit_Code__c}), 'Create Application - Helper validation - Preexisting drafts check - failed');
            }
        Test.stopTest();
        System.assert(String.isNotBlank(appPositive.Name), 'Create Application Positive scenario failed');
        System.assert(errorMessage.contains('Insert failed'), 'Create Application Negative scenario - Insert Error Check - failed');
        System.assertEquals(1, [select id from Email__c].size(), 'It should have created 1 Email Contact point record' );    
        System.assertEquals(1, [select id from Phone__c].size(), 'It should have created 1 Phone Contact point record' );    
        System.assertEquals(2, [select id from Contact_point_Affiliation__c].size(), 'It should have created 2 CPA records' );    
    }
    
    // Applications, and their ACPS, that are linked to AP Agencies but are created in Callista require their ownership to be aligned to that Agency. 
    // A active branch manager is required for this to occur.
    //
    @isTest
    private static void testAgencyOwner() {
		// Get the branch manager
        User BM = [SELECT id FROM User WHERE username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1 ];
        
        // Create an application and set the org unit. Processing takes place to update a lookup the Agency.
        test.startTest();
        Application__c minApp = new Application__c (source_system__c = 'Callista', status__c = 'Draft', Agent_Org_Unit_Code__c = 'TSTAG');
        insert minApp;
        
        minApp = [select id, Agent__c, ownerid, owner.name from application__c where id = :minApp.id];
        system.assertEquals(BM.id, minApp.OwnerId, 'Application owner should be ' + minApp.owner.name);
    
        Application_Course_Preference__c minACP = new Application_Course_Preference__c (Name = 'ACP-1', application__c = minApp.id);
        insert minACP;
        test.stopTest();

		minACP = [select id, ownerid, owner.name from Application_Course_Preference__c where id = :minACP.id];
        system.assertEquals(BM.id, minACP.OwnerId, 'ACP owner should be ' + minACP.owner.name);
    }
    
    // Exception Scenario - ACP owner should not be aligned if Application has been submitted
    @isTest
    private static void testAgencyOwnerWithAppStatus() {
                // Get the branch manager
        User BM = [SELECT id FROM User WHERE username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1 ];
        
        // Create an application and set the org unit. Processing takes place to update a lookup the Agency.
        test.startTest();
        Application__c minApp = new Application__c (source_system__c = 'Callista', Status__c = 'Submitted', Agent_Org_Unit_Code__c = 'TSTAG');
        insert minApp;
        
        minApp = [select id, Agent__c, ownerid, owner.name from application__c where id = :minApp.id];
        system.assertEquals(BM.id, minApp.OwnerId, 'Application owner should be ' + minApp.owner.name);
    
        Application_Course_Preference__c minACP = new Application_Course_Preference__c (Name = 'ACP-1', application__c = minApp.id);
        insert minACP;
        test.stopTest();
                minACP = [select id, ownerid, owner.name from Application_Course_Preference__c where id = :minACP.id];
        Assert.areNotEqual(BM.id, minACP.OwnerId, 'ACP owner should be ' + minACP.owner.name);
    }
    
    @isTest
    private static void testCreateAgentUser() {
        Contact testAgentContact = [SELECT id, Agency_Contact_Roles__c, AccountId FROM Contact WHERE email = 'TestEmail1996@testemail.com' LIMIT 1];
        Integer rnd = Integer.valueOf(Math.random()*9999);
        User agentUser = new User(FirstName = 'Test', LastName = 'temple', username = String.valueOf(rnd) + 'test.carborundum@getnada.com.apng', email = 'tess.temple@getnada.com', contactId = testAgentContact.id, CommunityNickname = 'T9100', ProfileId = AgentPortalConstants.AGENT_PROFILE_ID);
        User u = [SELECT id, Contact.AccountId FROM User WHERE username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1 ];
        Test.startTest();
            System.runAs(u){
                AgentPortalServices.createAgentUser(agentUser, testAgentContact);
            }
        Test.stopTest();
        System.assert([SELECT id FROM User WHERE Username LIKE '%test.carborundum@getnada.com.apng%' LIMIT 1]?.id != null, 'CreateAgentUser Positive scenario failed');
    }
    @isTest
    private static void testGetContact() {
        Account testAgency = new Account(Name = 'TestAgencyAccountTwo', Monash_AM_Campus__c = 'Australia', Callista_Org_Unit_Code__c = 'TSTA2');
        insert testAgency;
        
        Contact testAgentCon = new Contact(RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Agency_Contact').getRecordTypeId(), FirstName = 'TestFirstNameTwo', LastName = 'TestLastNameTwo', AccountId = testAgency.Id
                                        , Email = 'TestEmailTwo@testemailTwo.com', Agency_Contact_Roles__c = 'Branch Manager');
        insert testAgentCon;
        
        User runUsr = [SELECT id FROM User WHERE id = :UserInfo.getUserId()];
        User secondAgent = new User();
        Test.startTest();
        System.runAs(runUsr){
            Id proId =[select id from profile where name = :AgentPortalConstants.AGENT_PROFILE].id;
            Integer rnd = Integer.valueOf(Math.random()*9999);
            secondAgent.Username = String.valueOf(rnd) + 'testAgentLastNameTwo@TestEmailTwo.com.domain';
            secondAgent.email = String.valueOf(rnd) + 'testAgentLastNameTwo@TestEmailTwo.com';
            secondAgent.ContactId = testAgentCon.id; 
            secondAgent.LastName ='test';
            secondAgent.Alias ='test';
            secondAgent.isActive = true;
            secondAgent.TimeZoneSidKey ='Australia/Sydney';
            secondAgent.LocaleSidKey ='en_AU';
            secondAgent.EmailEncodingKey ='ISO-8859-1';
            secondAgent.ProfileId = proId;
            secondAgent.LanguageLocaleKey ='en_US';
            insert secondAgent;
            
            PermissionSetGroup AgentPSG = [SELECT Id, Status FROM permissionSetGroup WHERE developername = :AgentPortalConstants.AGENT_PERMISSION_SET_GROUP]; 
            // force calculation of the PSG if it is not already Updated
            if (AgentPSG.Status != 'Updated') {
                Test.calculatePermissionSetGroup(AgentPSG.Id);
            }
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId=secondAgent.Id,PermissionSetGroupId=AgentPSG.Id);
            insert psa;
        }
        User firstAgent = [SELECT id FROM User WHERE username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1 ];
        String crmID;
        System.runAs(firstAgent) {
        	Contact con = new Contact(First_Name__c = 'Test', Last_Name__c = 'Test Last', Personal_email__c = 'test123@getnad.com', BirthDate = Date.valueOf('2003-02-01'), OwnerId = UserInfo.getUserId());
        	insert con;
	        crmID = [SELECT id, CRM_ID__c FROM Contact WHERE id = :con.id LIMIT 1]?.CRM_ID__c;
        }
     
        System.runAs(secondAgent) {
            Contact retreivedContact = AgentPortalServices.getContact(crmID, AgentPortalConstants.APPLICANT_PERSONA, AgentPortalConstants.USER_CONTEXT);
            Assert.isNull(retreivedContact, 'GetContact - USER Context failed');
            retreivedContact = AgentPortalServices.getContact(crmID, AgentPortalConstants.APPLICANT_PERSONA, AgentPortalConstants.SYSTEM_CONTEXT);
            Assert.isNotNull(retreivedContact, 'GetContact - SYSTEM Context failed');
        }
        Test.stopTest();
    }
    @isTest
    private static void testUpdateApplicant(){
        Contact con = new Contact(First_Name__c = 'Test', Last_Name__c = 'Test Last', Personal_email__c = 'test123@getnad.com', MobilePhone = '123456789', BirthDate = Date.valueOf('2003-02-01'), OwnerId = UserInfo.getUserId()); // CPA will not be created
        insert con;
        User u = [SELECT id, Username, ContactId, contact.AccountId FROM User WHERE Username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1];
        
        System.runAs(u) {
            Test.startTest();
            // TODO :: Affiliation based check has to be inserted here
            Application__c appPositive = new Application__c (Applicant__c = con.id, Agent__c = u.Contact.AccountId, Status__c =  'Draft', Source_System__c = 'AgentPortal', Residency_Status__c = 'INTRNTNL');
      
            // Positive scenario
            appPositive = (Application__c) AgentPortalServices.createApplication(appPositive, '123@abc.com', '345');
           
            con = new Contact(id = con.id);
            con.Personal_email__c = 'test456@getnad.com.au'; // CPA will be Created
            con.HomePhone = '44444444'; // CPA will be created
            con.MobilePhone = 'abc@gef.com'; // CPA will be created
            con.MailingStreet = '350 Bourke Street';
            con.MailingCity = 'Melbourne';
            con.MailingState = 'Victoria';
            con.MailingPostalCode = '3000';
            con.MailingCountry = 'Australia';
            con.OtherStreet = '111 Bourke Street';
            con.OtherCity = 'Melbourne';
            con.OtherState = 'Victoria';
            con.OtherPostalCode = '3000';
            con.OtherCountry = 'Australia';
            AgentPortalServices.updateApplicant(con);
        }
            Test.stopTest();
        
       //2 CPA's on Application creation and 5 on update Applicant
        List<Contact_Point_Affiliation__c> cpa = [SELECT id, Phone__r.name, email__r.name, address__r.address__c FROM Contact_Point_Affiliation__c WHERE Contact__c = :con.id];
        Assert.areEqual(7, cpa?.size(), 'Update Applicant -should create 5 CPA records');
    }
    @isTest
    private static void testSearchApplicants(){
        Contact applicantOne = new Contact(First_Name__c = 'NonSearchable', Last_Name__c = 'Test Last',FirstName = 'NonSearchable', LastName = 'Test Last', Personal_email__c = 'test456@getnad.com', MobilePhone = '987654312', BirthDate = Date.valueOf('2003-02-05'), OwnerId = UserInfo.getUserId());
        insert applicantOne;
        Contact applicantTwo = new Contact(First_Name__c = 'Searchable', Last_Name__c = 'Test Last',FirstName = 'Searchable', LastName = 'Test Last', Personal_email__c = 'test123@getnad.com', MobilePhone = '123456789', BirthDate = Date.valueOf('2003-02-01'), OwnerId = UserInfo.getUserId());

        User u = [SELECT id, Username, ContactId, Contact.AccountId FROM User WHERE Username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1];
        List<Contact> searchResults;
        System.runAs(u) {
            Test.startTest();
            applicantTwo = AgentPortalServices.createApplicant(applicantTwo, UserInfo.getUserId());
            searchResults = AgentPortalServices.searchApplicants('Searchable', 10, 0);
            Test.stopTest();
        }
        Assert.areEqual(1, searchResults?.size(), 'Search Applicants - failed');
    }
    @isTest
    private static void testCreateAgencyContact(){
        Contact con = new Contact(First_Name__c = 'Test', Last_Name__c = 'Test Last', Personal_email__c = 'test123@getnad.com', BirthDate = Date.valueOf('2003-02-01'), OwnerId = UserInfo.getUserId());
        AgentPortalServices.createAgencyContact(con);
        String personalEmail = [SELECT id, Personal_email__c FROM Contact WHERE id = :con.id LIMIT 1]?.Personal_email__c;
        Assert.areEqual(personalEmail, 'test123@getnad.com', 'Create Agency Contact - failed');
    }
    @isTest
    private static void testUpdateApplication(){
        Contact con = new Contact(First_Name__c = 'Test', Last_Name__c = 'Test Last', Personal_email__c = 'test123@getnad.com', BirthDate = Date.valueOf('2003-02-01'), OwnerId = UserInfo.getUserId());
        insert con;
        Application__c app = new Application__c(Applicant__c = con.id, Status__c = 'Draft');
        insert app;
        app.Status__c = 'Submitted';
        AgentPortalServices.updateApplication(app);
        String status = [SELECT id, Status__c FROM Application__c WHERE id = :app.id LIMIT 1]?.Status__c;
        Assert.areEqual(status, 'Submitted', 'Update Application - failed');
    }
    @isTest
    private static void testGetAndUpdateApplicationWorkExperiences() {
        Contact con = new Contact(First_Name__c = 'Test', Last_Name__c = 'Test Last', Personal_email__c = 'test123@getnad.com', BirthDate = Date.valueOf('2003-02-01'), OwnerId = UserInfo.getUserId());
        insert con;
        Application__c app = new Application__c(Applicant__c = con.id, Status__c = 'Draft');
        insert app;


        Test.startTest();
            Work_Experience__c wex1 = new Work_Experience__c(Contact__c = con.id, Position__c = 'CEO', Employer_Name__c = 'Papa Afghanistan');
            Work_Experience__c wex2 = new Work_Experience__c(Contact__c = con.id, Position__c = 'CEO', Employer_Name__c = 'Papa Arabia');
            List<Work_Experience__c> lstWEX = AgentPortalServices.updateApplicationWorkExperiences(app.id, new List<Work_Experience__c> {wex1, wex2});
            Assert.areEqual(2, lstWEX.size(), 'updateApplicationWorkExperiences -- insert failed');
            Application__c appn = [SELECT id, name FROM Application__c WHERE id = :app.id LIMIT 1];
            AgentPortalPayload.WorkExperiences apWEXs = AgentPortalServices.getWorkExperiencesByApplicationId(appn.Name);
            Assert.isNotNull(apWEXs, 'getWorkExperiencesByApplicationId -- failed ');
            Work_Experience__c wex3 = new Work_Experience__c(Contact__c = con.id, Position__c = 'CEO', Employer_Name__c = 'Papa Albania');
            lstWEX = AgentPortalServices.updateApplicationWorkExperiences(app.id, new List<Work_Experience__c> {wex2, wex3});
            Assert.areEqual(2, lstWEX.size(), 'updateApplicationWorkExperiences -- sync failed');
        Test.stopTest();
        Work_Experience__c weExternalIdCheck = [SELECT Name, External_ID__c FROM Work_Experience__c LIMIT 1];
        Assert.areEqual(weExternalIdCheck.Name, weExternalIdCheck.External_ID__c, 'Name not equal to External_ID__c check flow on Work_Experience__c');
    }


    /**
    * @description test that work experience updates via externalId
    * @author Ben Greenland | 2024-06-17 
    **/
    @isTest
    private static void testGetAndUpdateApplicationWorkExperiencesExternalId() {
       
        //GIVEN 
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
        Integer lstWEXOrigCount = 0;
        Contact con;
        String wexTestName1;
        String wexTestName2;
        //GIVEN an OES user
        System.runAs(agent){
            con = new Contact(First_Name__c = 'Test', Last_Name__c = 'Test Last', Personal_email__c = 'test123@getnad.com', BirthDate = Date.valueOf('2003-02-01'), OwnerId = UserInfo.getUserId());
            insert con;
            Application__c app = new Application__c(Applicant__c = con.id, Status__c = 'Draft');
            insert app;
            Work_Experience__c wex1 = new Work_Experience__c(Contact__c = con.id, Position__c = 'CEO', Employer_Name__c = 'Papa Afghanistan');
            Work_Experience__c wex2 = new Work_Experience__c(Contact__c = con.id, Position__c = 'CEO', Employer_Name__c = 'Papa Arabia');
            List<Work_Experience__c> lstWEX = AgentPortalServices.updateApplicationWorkExperiences(app.id, new List<Work_Experience__c> {wex1, wex2});
            Application__c appn = [SELECT id, name FROM Application__c WHERE id = :app.id LIMIT 1];
            AgentPortalPayload.WorkExperiences apWEXs = AgentPortalServices.getWorkExperiencesByApplicationId(appn.Name);
            wexTestName1=apWEXs.applicationExperiences[0].External_ID__c;
            wexTestName2=apWEXs.applicationExperiences[1].External_ID__c;
            lstWEXOrigCount = lstWEX.size();


            Test.startTest();

            List<Work_Experience__c> wexTests = [SELECT External_ID__c,Contact__c,Position__c , Employer_Name__c 
                                       FROM Work_Experience__c 
                                       WHERE External_ID__c IN:new Set<String>{wexTestName1,wexTestName2}];
             //WHEN: the work experience is updated with the specified External_ID__c
            Work_Experience__c wex3 = new Work_Experience__c(External_ID__c=wexTests[0].External_ID__c, Contact__c = con.id, Position__c = 'Boss', Employer_Name__c = 'McDonalds');
            wex3.Id = null;
            Work_Experience__c wex4 = new Work_Experience__c(External_ID__c=wexTests[1].External_ID__c, Contact__c = con.id, Position__c = wexTests[1].Position__c, Employer_Name__c = wexTests[1].Employer_Name__c);
            wex4.Id = null;
            lstWEX = AgentPortalServices.updateApplicationWorkExperiences(app.id, new List<Work_Experience__c> {wex3,wex4});
            
            Test.stopTest();
            //THEN the record with the specied id are updated
            Assert.areEqual(lstWEX[0].External_ID__c,wexTestName1,'New Work experience record has been updated instead of upserted');
            Assert.areEqual(lstWEX[1].External_ID__c,wexTestName2,'New Work experience record has been updated instead of upserted');
            Assert.areEqual(lstWEX[0].Employer_Name__c, 'McDonalds', 'THe Employer_Name__c field has not been updated ');
        }
        
        Assert.areEqual(lstWEXOrigCount, [SELECT Id FROM Work_Experience__c WHERE  Contact__c =:con.id].size(), 'Expected 2 work experience records check upsert');
    }
    @isTest
    private static void testGetAndUpdateApplicationContactQualifications() {
        Contact con = new Contact(First_Name__c = 'Test', Last_Name__c = 'Test Last', Personal_email__c = 'test123@getnad.com', BirthDate = Date.valueOf('2003-02-01'), OwnerId = UserInfo.getUserId());
        insert con;
        Application__c app = new Application__c(Applicant__c = con.id, Status__c = 'Draft');
        insert app;
        Contact_Qualification__c qual1 = new Contact_Qualification__c(Contact__c = con.id, Other_Institution__c = 'ABC Institution', Other_Qualification__c = 'Test of English', RecordTypeId = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByName().get('English Test').getRecordTypeId());
        Contact_Qualification__c qual2 = new Contact_Qualification__c(Contact__c = con.id, Other_Institution__c = 'ABC Institution', Other_Qualification__c = 'Test of English', RecordTypeId = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByName().get('English Test').getRecordTypeId());
        List<Contact_Qualification__c> lstQuals = AgentPortalServices.updateApplicationQualifications(app.id, new List<Contact_Qualification__c> {qual1, qual2});
        Assert.areEqual(2, lstQuals.size(), 'updateApplicationQualifications -- insert failed');
        Application__c appn = [SELECT id, name FROM Application__c WHERE id = :app.id LIMIT 1];
        AgentPortalPayload.Qualifications apQuals = AgentPortalServices.getContactQualificationsByApplicationId(appn.Name);
        Assert.isNotNull(apQuals, 'getWorkExperiencesByApplicationId -- failed ');
        Contact_Qualification__c qual3 = new Contact_Qualification__c(Contact__c = con.id, Other_Institution__c = 'ABC Institution', Other_Qualification__c = 'Test of English', RecordTypeId = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByName().get('English Test').getRecordTypeId());
        lstQuals = AgentPortalServices.updateApplicationQualifications(app.id, new List<Contact_Qualification__c> {qual2, qual3});
        Assert.areEqual(2, lstQuals.size(), 'updateApplicationQualifications -- sync failed');
    }
    @isTest
    private static void testGetAndUpdateApplicaitonDetails() {
        User u = [SELECT id, Username, contact.AccountId,ContactId FROM User WHERE Username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1];

        System.runAs(u){
            Test.startTest();
            // Reference data - Course
        Course__c course = StudFirst_TestHelper.createCourse();
        course.name = 'E6001';
        course.Course_Code__c = 'E6001_11';
        course.Version__c = '11';
        insert course;
        
        // Reference data - Course Offering
        List<Course_Offering__c> courseOfferings = new List<Course_Offering__c>();

        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        courseOffering.Course_Code__c = 'E6001';
        courseOffering.Course_Version_Number__c = 1;
        courseOffering.Admission_Calendar_Type__c = 'ADM-0';
        courseOffering.Location_Code__c = 'CLAYTON';
        courseOffering.Attendance_Type__c = 'FT';
        courseOffering.Attendance_Mode__c = 'IN';
        courseOffering.Admission_Category__c = 'UG-CSP';
        courseOffering.Academic_CI_Sequence_Number__c = 1111;
        courseOffering.Admission_CI_Sequence_Number__c = 1111;
        courseOffering.Citizenship_Type__c = 'DOM-AUS';
        courseOffering.Unit_Set_Code__c = null;
        courseOffering.Unit_Set_Version__c = null;
        courseOffering.Admission_Calendar_Description__c = 'CrOf0';
        courseOfferings.add(courseOffering);
        
        Course_Offering__c courseOffering_1 = StudFirst_TestHelper.createCourseOffering(course);
        courseOffering_1.Course_Code__c = 'E6001';
        courseOffering_1.Course_Version_Number__c = 1;
        courseOffering_1.Admission_Calendar_Type__c = 'ADM-0';
        courseOffering_1.Location_Code__c = 'CLAYTON';
        courseOffering_1.Attendance_Type__c = 'FT';
        courseOffering_1.Attendance_Mode__c = 'IN';
        courseOffering_1.Admission_Category__c = 'UG-CSP';
        courseOffering_1.Academic_CI_Sequence_Number__c = 1111;
        courseOffering_1.Admission_CI_Sequence_Number__c = 1111;
        courseOffering_1.Unit_Set_Code__c = null;
        courseOffering_1.Unit_Set_Version__c = null;
        courseOffering_1.Citizenship_type__c = 'INT-TEP';
        courseOffering_1.Admission_Calendar_Description__c = 'CrOf1';
        courseOfferings.add(courseOffering_1);
        
        Course_Offering__c courseOffering_2 = StudFirst_TestHelper.createCourseOffering(course);
        courseOffering_2.Course_Code__c = 'E6001';
        courseOffering_2.Course_Version_Number__c = 1;
        courseOffering_2.Admission_Calendar_Type__c = 'ADM-0';
        courseOffering_2.Location_Code__c = 'CLAYTON';
        courseOffering_2.Attendance_Type__c = 'FT';
        courseOffering_2.Attendance_Mode__c = 'EX';
        courseOffering_2.Admission_Category__c = 'UG-CSP';
        courseOffering_2.Academic_CI_Sequence_Number__c = 1111;
        courseOffering_2.Admission_CI_Sequence_Number__c = 1111;
        courseOffering_2.Unit_Set_Code__c = null;
        courseOffering_2.Unit_Set_Version__c = null;
        courseOffering_2.Citizenship_type__c = 'INT-TEP';
        courseOffering_2.Admission_Calendar_Description__c = 'CrOf2';
        courseOfferings.add(courseOffering_2);
        
        insert courseOfferings;
              List<Course_Offering__c> crOfs = [SELECT id FROM Course_offering__c WHERE Course_Code__c = 'E6001' LIMIT 3];

            Contact con = new Contact(First_Name__c = 'Test', Last_Name__c = 'Test Last', Personal_email__c = 'test123@getnad.com', BirthDate = Date.valueOf('2003-02-01'), OwnerId = UserInfo.getUserId());
            insert con;
            //Account acc= [select id from account where id=:u.contact.AccountId];
            Application__c app = new Application__c(Agent__c = u.contact.AccountId, Applicant__c = con.id, Status__c = 'Draft');
            insert app;
            app = [SELECT name FROM Application__c WHERE id = :app.id LIMIT 1];
            AgentPortalPayload.ApplicationDetails apApplicationDetails = AgentPortalServices.getApplicationDetails(app.name);
            Assert.isNotNull(apApplicationDetails.details, 'getAppliOcationDetails -- failed');
                Application_Course_Preference__c acp1 = new Application_Course_Preference__c(Applicant__c=con.id, Application__c=app.id, Course_Offering__c= crOfs[0].id);
                AgentPortalServices.updateApplicationCoursePreferences(app.id, new List<Application_Course_Preference__c> {acp1});
                apApplicationDetails = AgentPortalServices.getApplicationDetails(app.name);
                // Check if ACP1 is present
                Assert.isTrue(JSON.serialize(apApplicationDetails.coursePreferences).contains(crOfs[0].id), 'updateApplicationCoursePreferences - update -- failed');
                Application_Course_Preference__c acp2 = new Application_Course_Preference__c(Applicant__c=con.id, Application__c=app.id, Course_Offering__c= crOfs[1].id);
                Application_Course_Preference__c acp3 = new Application_Course_Preference__c(Applicant__c=con.id, Application__c=app.id, Course_Offering__c= crOfs[2].id);
                AgentPortalServices.updateApplicationCoursePreferences(app.id, new List<Application_Course_Preference__c> {acp2, acp3});
                apApplicationDetails = AgentPortalServices.getApplicationDetails(app.name);
            Test.stopTest();
            // Check if ACP1 is removed
            Assert.isFalse(JSON.serialize(apApplicationDetails.coursePreferences).contains(crOfs[0].id), 'updateApplicationCoursePreferences - sync -- failed');
        }
    }

    /** 
    * @description ensure that APNG user can update existing ACPs 
    * @author Ben Greenland | 2024-07-03 
    **/
    @isTest
    private static void testGetAndUpdateChangePreference() {
        User u = [SELECT id, Username, contact.AccountId,ContactId FROM User WHERE Username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1];

        System.runAs(u){
            Test.startTest();
            // Reference data - Course
        Course__c course = StudFirst_TestHelper.createCourse();
        course.name = 'E6001';
        course.Course_Code__c = 'E6001_11';
        course.Version__c = '11';
        insert course;
        
        // Reference data - Course Offering
        List<Course_Offering__c> courseOfferings = new List<Course_Offering__c>();

        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        courseOffering.Course_Code__c = 'E6001';
        courseOffering.Course_Version_Number__c = 1;
        courseOffering.Admission_Calendar_Type__c = 'ADM-0';
        courseOffering.Location_Code__c = 'CLAYTON';
        courseOffering.Attendance_Type__c = 'FT';
        courseOffering.Attendance_Mode__c = 'IN';
        courseOffering.Admission_Category__c = 'UG-CSP';
        courseOffering.Academic_CI_Sequence_Number__c = 1111;
        courseOffering.Admission_CI_Sequence_Number__c = 1111;
        courseOffering.Citizenship_Type__c = 'DOM-AUS';
        courseOffering.Unit_Set_Code__c = null;
        courseOffering.Unit_Set_Version__c = null;
        courseOffering.Admission_Calendar_Description__c = 'CrOf0';
        courseOfferings.add(courseOffering);
        
        Course_Offering__c courseOffering_1 = StudFirst_TestHelper.createCourseOffering(course);
        courseOffering_1.Course_Code__c = 'E6001';
        courseOffering_1.Course_Version_Number__c = 1;
        courseOffering_1.Admission_Calendar_Type__c = 'ADM-0';
        courseOffering_1.Location_Code__c = 'CLAYTON';
        courseOffering_1.Course_Title__c = 'Captain of Industry';
        courseOffering_1.Attendance_Type__c = 'FT';
        courseOffering_1.Attendance_Mode__c = 'IN';
        courseOffering_1.Admission_Category__c = 'UG-CSP';
        courseOffering_1.Academic_CI_Sequence_Number__c = 1111;
        courseOffering_1.Admission_CI_Sequence_Number__c = 1111;
        courseOffering_1.Unit_Set_Code__c = null;
        courseOffering_1.Unit_Set_Version__c = null;
        courseOffering_1.Citizenship_type__c = 'INT-TEP';
        courseOffering_1.Admission_Calendar_Description__c = 'CrOf1';
        courseOfferings.add(courseOffering_1);
    
        
        insert courseOfferings;
              List<Course_Offering__c> crOfs = [SELECT id FROM Course_offering__c WHERE Course_Code__c = 'E6001' LIMIT 2];

            Contact con = new Contact(First_Name__c = 'Test', Last_Name__c = 'Test Last', Personal_email__c = 'test123@getnad.com', BirthDate = Date.valueOf('2003-02-01'), OwnerId = UserInfo.getUserId());
            insert con;
            //Account acc= [select id from account where id=:u.contact.AccountId];
            Application__c app = new Application__c(Agent__c = u.contact.AccountId, Applicant__c = con.id, Status__c = 'Draft');
            insert app;
            app = [SELECT name FROM Application__c WHERE id = :app.id LIMIT 1];
            AgentPortalPayload.ApplicationDetails apApplicationDetails = AgentPortalServices.getApplicationDetails(app.name);
            Assert.isNotNull(apApplicationDetails.details, 'getAppliOcationDetails -- failed');
                Application_Course_Preference__c acp1 = new Application_Course_Preference__c(Applicant__c=con.id, Application__c=app.id, Course_Offering__c= crOfs[0].id);
                AgentPortalServices.updateApplicationCoursePreferences(app.id, new List<Application_Course_Preference__c> {acp1});
                apApplicationDetails = AgentPortalServices.getApplicationDetails(app.name);
                List<Application_Course_Preference__c> acpsToUpdate = AgentPortalServices.getApplicationCoursePreferences(app.name);
                String acpNameToTest = acpsToUpdate[0].External_id__c;
                // Check if ACP1 is present
                acpsToUpdate[0].Course_Offering__c = crOfs[1].id;
                AgentPortalServices.updateApplicationCoursePreferences(app.id, acpsToUpdate);
                apApplicationDetails = AgentPortalServices.getApplicationDetails(app.name);
            Test.stopTest();
            // Check if ACP1 is removed
            Assert.isTrue(JSON.serialize(apApplicationDetails.coursePreferences[0]).contains(acpNameToTest), 'updateApplicationCoursePreferences acp was created instead of updated');
            Assert.isTrue(JSON.serialize(apApplicationDetails.coursePreferences[0].Course_Title__c).contains('Captain'), 'updateApplicationCoursePreferences acp has wrong course');
        }
    }

    
    /**
    * @description check OES logic fires and is valid
    * @author Ben Greenland | 2024-05-24 
    **/
    @isTest
    private static void testGetAndUpdateApplicaitonDetailsOES() {
        User u = [SELECT id, Username, contact.AccountId,ContactId FROM User WHERE Username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1];
        //GIVEN course Offerings for an OES user
        System.runAs(u){
            
            // Reference data - Course
        Course__c course = StudFirst_TestHelper.createCourse();
        course.name = 'E6001';
        course.Course_Code__c = 'E6001_11';
        course.Version__c = '11';
        insert course;
        
        // Reference data - Course Offering
        List<Course_Offering__c> courseOfferings = new List<Course_Offering__c>();

        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        courseOffering.Course_Code__c = 'E6001';
        courseOffering.Course_Version_Number__c = 1;
        courseOffering.Admission_Calendar_Type__c = 'ADM-0';
        courseOffering.Location_Code__c = 'CLAYTON';
        courseOffering.Attendance_Type__c = 'FT';
        courseOffering.Attendance_Mode__c = 'IN';
        courseOffering.Admission_Category__c = 'UG-CSP';
        courseOffering.Academic_CI_Sequence_Number__c = 1111;
        courseOffering.Admission_CI_Sequence_Number__c = 1111;
        courseOffering.Citizenship_Type__c = 'DOM-AUS';
        courseOffering.Unit_Set_Code__c = null;
        courseOffering.Unit_Set_Version__c = null;
        courseOffering.Admission_Calendar_Description__c = 'CrOf0';
        courseOffering.Course_Offering_UID__c = 'uid0';
        courseOfferings.add(courseOffering);
        
        Course_Offering__c courseOffering_1 = StudFirst_TestHelper.createCourseOffering(course);
        courseOffering_1.Course_Code__c = 'E6001';
        courseOffering_1.Course_Version_Number__c = 1;
        courseOffering_1.Admission_Calendar_Type__c = 'ADM-0';
        courseOffering_1.Location_Code__c = 'CLAYTON';
        courseOffering_1.Attendance_Type__c = 'FT';
        courseOffering_1.Attendance_Mode__c = 'IN';
        courseOffering_1.Admission_Category__c = 'UG-CSP';
        courseOffering_1.Academic_CI_Sequence_Number__c = 1111;
        courseOffering_1.Admission_CI_Sequence_Number__c = 1111;
        courseOffering_1.Unit_Set_Code__c = null;
        courseOffering_1.Unit_Set_Version__c = null;
        courseOffering_1.Citizenship_type__c = 'INT-TEP';
        courseOffering_1.Admission_Calendar_Description__c = 'CrOf1';
        courseOffering_1.Course_Offering_UID__c = 'uid1';
        courseOfferings.add(courseOffering_1);
        
        Course_Offering__c courseOffering_2 = StudFirst_TestHelper.createCourseOffering(course);
        courseOffering_2.Course_Code__c = 'E6001';
        courseOffering_2.Course_Version_Number__c = 1;
        courseOffering_2.Admission_Calendar_Type__c = 'ADM-0';
        courseOffering_2.Location_Code__c = 'CLAYTON';
        courseOffering_2.Attendance_Type__c = 'FT';
        courseOffering_2.Attendance_Mode__c = 'EX';
        courseOffering_2.Admission_Category__c = 'UG-CSP';
        courseOffering_2.Academic_CI_Sequence_Number__c = 1111;
        courseOffering_2.Admission_CI_Sequence_Number__c = 1111;
        courseOffering_2.Unit_Set_Code__c = null;
        courseOffering_2.Unit_Set_Version__c = null;
        courseOffering_2.Citizenship_type__c = 'INT-TEP';
        courseOffering_2.Admission_Calendar_Description__c = 'CrOf2';
        courseOffering_2.Course_Offering_UID__c = 'uid2';
        courseOffering_2.Course_Title__c = 'Master of the universe';
        courseOfferings.add(courseOffering_2);
        
        insert courseOfferings;
        }

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
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId=u.Id, PermissionSetId=ps.Id);
            insert psa;

            List<Course_offering__C> coL =  [SELECT id,active__C FROM Course_offering__C  WHERE active__C=true limit 1];
            //Share Course offering with the OES user by Apex Managed sharing -To get around limitation as sharing rules are not evaluated in Test classes 
            List<Course_offering__Share> cosList = new List<Course_offering__Share>();
            for(Course_offering__C co:coL){
                Course_offering__Share coshare= new Course_offering__Share();
                coshare.ParentId = co.Id;
                coshare.UserOrGroupId  = u.Id;
                coshare.AccessLevel  = 'Read';
                coshare.RowCause = Schema.Course_offering__Share.RowCause.Manual;
                cosList.add(coshare);
            }
            List<Database.SaveResult> sr = Database.insert(cosList,false);
               
        }
        String testExternalId;
        System.runAs(u){
              List<Course_Offering__c> crOfs = [SELECT id,Course_Offering_UID__c FROM Course_offering__c WHERE Course_Code__c = 'E6001' LIMIT 3];

            Contact con = new Contact(First_Name__c = 'Test', Last_Name__c = 'Test Last', Personal_email__c = 'test123@getnad.com', BirthDate = Date.valueOf('2003-02-01'), OwnerId = UserInfo.getUserId());
            insert con;
            //Account acc= [select id from account where id=:u.contact.AccountId];
            Application__c app = new Application__c(Agent__c = u.contact.AccountId, Applicant__c = con.id, Status__c = 'Draft');
            insert app;
            app = [SELECT name FROM Application__c WHERE id = :app.id LIMIT 1];
            Test.startTest();
            AgentPortalPayload.ApplicationDetails apApplicationDetails = AgentPortalServices.getApplicationDetails(app.name);
            Assert.isNotNull(apApplicationDetails.details, 'getAppliOcationDetails -- failed');
                Application_Course_Preference__c acp1 = new Application_Course_Preference__c(Applicant__c=con.id, Application__c=app.id,  Course_Offering__r= new Course_Offering__c( Course_Offering_UID__c= crOfs[0].Course_Offering_UID__c));
                AgentPortalServices.updateApplicationCoursePreferences(app.id, new List<Application_Course_Preference__c> {acp1});
                apApplicationDetails = AgentPortalServices.getApplicationDetails(app.name);
                testExternalId = apApplicationDetails.coursePreferences[0].External_Id__c;
                // Check if ACP1 is present
                Assert.isTrue(JSON.serialize(apApplicationDetails.coursePreferences).contains(crOfs[0].id), 'updateApplicationCoursePreferences for OES - update -- failed');
                //we will update the ACP create above with courseOfferings_2 test data
                Application_Course_Preference__c acp2 = new Application_Course_Preference__c(External_Id__c=apApplicationDetails.coursePreferences[0].External_Id__c, Applicant__c=con.id, Application__c=app.id,   Course_Offering__r = new Course_Offering__c( Course_Offering_UID__c= crOfs[1].Course_Offering_UID__c));
                Application_Course_Preference__c acp3 = new Application_Course_Preference__c(Applicant__c=con.id, Application__c=app.id,   Course_Offering__r = new Course_Offering__c( Course_Offering_UID__c= crOfs[2].Course_Offering_UID__c));
                AgentPortalServices.updateApplicationCoursePreferences(app.id, new List<Application_Course_Preference__c> {acp2, acp3});
                apApplicationDetails = AgentPortalServices.getApplicationDetails(app.name);

            Test.stopTest();
            // Check if ACP1 is removed
            Assert.areEqual(2,apApplicationDetails.coursePreferences.size(), 'updateApplicationCoursePreferences - update expected 2 course preferences');
            //Assert.areEqual('Master of the universe',apApplicationDetails.coursePreferences[1].Course_Title__c, 'updateApplicationCoursePreferences - wrong course title');
            //Assert.areEqual(testExternalId,apApplicationDetails.coursePreferences[0].External_Id__c, 'updateApplicationCoursePreferences External id should not have changed');
        }
    }

    @isTest
    private static void testGetAndUpdateApplicant() {
        User u = [SELECT id, Username, ContactId FROM User WHERE Username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1];
        System.runAs(U)
        {

            Contact con = new Contact(First_Name__c = 'Test', Last_Name__c = 'Test Last', Personal_email__c = 'test123@getnad.com', BirthDate = Date.valueOf('2003-02-01'), OwnerId = UserInfo.getUserId(),Aboriginal_or_Torres_Strait_Islander__c ='Yes');
            insert con;
            con = [SELECT id, CRM_ID__c FROM Contact WHERE id = :con.id LIMIT 1];
            Application__c app = new Application__c(Applicant__c = con.id, Status__c = 'Draft');
            insert app;
            Test.startTest();
                AgentPortalPayload.ApplicantDetails apApplicantDetails = AgentPortalServices.getApplicantDetails(con.CRM_ID__c);
            Test.stopTest();
            Assert.isNotNull(apApplicantDetails.details, 'getApplicantDetails -- failed');
        }
    }
    @isTest
    private static void testGetAndUpdateApplications() {
        User u = [SELECT id, Username, ContactId FROM User WHERE Username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1];
        System.runAs(U)
        {
            Contact con = new Contact(First_Name__c = 'Test', Last_Name__c = 'Test Last', Personal_email__c = 'test123@getnad.com', BirthDate = Date.valueOf('2003-02-01'), OwnerId = UserInfo.getUserId());
            insert con;
            Application__c app = new Application__c(Applicant__c = con.id, Status__c = 'Draft');
            insert app;
            Test.startTest();
                List<Application__c> apps = AgentPortalServices.getApplicationsForApplicant(con.id);
                Assert.areEqual(1, apps.size(), 'getApplicationsForApplicant -- failed');
                apps[0].Status__c = 'Sent Draft Application to Applicant';
                AgentPortalServices.updateApplication(apps[0]);
                app = [SELECT id, Status__c FROM Application__c WHERE id = :apps[0].id LIMIT 1];
                Assert.areEqual('Sent Draft Application to Applicant', app.Status__c, 'updateApplication -- failed');
                app.Status__c = 'Review';
                AgentPortalServices.updateApplication(app);
                apps = AgentPortalServices.getSubmittedApplicationsForApplicant(con.id, new Set<Id> ());
                Assert.areEqual(1, apps.size(), 'getSubmittedApplicationsForApplicant -- failed');
            Test.stopTest();
        }
    }
    @isTest
    private static void testGetUser() {
        User u = [SELECT id, Username, ContactId FROM User WHERE Username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1];
        System.runAs(U)
        {
            Assert.isTrue(AgentPortalServices.getUser(u.ContactId) == null, 'GetUser - negative scenario failed');
            Assert.areEqual(u.ContactId, AgentPortalServices.getUser(u.Id).ContactId, 'GetUser - By ID Failed');
            Assert.areEqual(u.ContactId, AgentPortalServices.getUser(u.Username).ContactId, 'GetUser - By UserName Failed');
        }
   
    }
    @isTest
    private static void testFreezeUnFreezeUser() {
        User u = [SELECT id, Username, ContactId FROM User WHERE Username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1];
        AgentPortalServices.freezeUnFreezeUser(u.id, true);
        UserLogin ulogin = [SELECT Id, IsFrozen, UserId FROM UserLogin WHERE UserId = :u.id];
        Assert.areEqual(true, ulogin.IsFrozen, 'freezeUnFreezeUser -- failed');
    }

    //Test for Filtering out sharing setting for portal user
    @isTest
    private static void testEnsurePortalAgentCantSeeVarious() {
  
    User u = [SELECT id, Username, contact.AccountId,ContactId FROM User WHERE Username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1];


        // Reference data - Course
    Course__c course = StudFirst_TestHelper.createCourse();
    course.name = 'E6001';
    course.Course_Code__c = 'E6001_11';
    course.Version__c = '11';
    insert course;
    
    // Reference data - Course Offering
    List<Course_Offering__c> courseOfferings = new List<Course_Offering__c>();

    Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
    courseOffering.Course_Code__c = 'E6001';
    courseOffering.Course_Version_Number__c = 1;
    courseOffering.Admission_Calendar_Type__c = 'ADM-0';
    courseOffering.Location_Code__c = 'OS-CHI-THC';
    courseOffering.Attendance_Type__c = 'FT';
    courseOffering.Attendance_Mode__c = 'IN';
    courseOffering.Admission_Category__c = 'UG-CSP';
    courseOffering.Academic_CI_Sequence_Number__c = 1111;
    courseOffering.Admission_CI_Sequence_Number__c = 1111;
    courseOffering.Citizenship_Type__c = 'DOM-AUS';
    courseOffering.Unit_Set_Code__c = null;
    courseOffering.Unit_Set_Version__c = null;
    courseOffering.Admission_Calendar_Description__c = 'CrOf0';
    courseOffering.Portal_Available__c = true;
    courseOffering.Active__c = true;
    courseOfferings.add(courseOffering);
    
    Course_Offering__c courseOffering_1 = StudFirst_TestHelper.createCourseOffering(course);
    courseOffering_1.Course_Code__c = 'E6001';
    courseOffering_1.Course_Version_Number__c = 1;
    courseOffering_1.Admission_Calendar_Type__c = 'ADM-0';
    courseOffering_1.Location_Code__c = 'OS-SLA-CMB';
    courseOffering_1.Attendance_Type__c = 'FT';
    courseOffering_1.Attendance_Mode__c = 'IN';
    courseOffering_1.Admission_Category__c = 'UG-CSP';
    courseOffering_1.Academic_CI_Sequence_Number__c = 1111;
    courseOffering_1.Admission_CI_Sequence_Number__c = 1111;
    courseOffering_1.Unit_Set_Code__c = null;
    courseOffering_1.Unit_Set_Version__c = null;
    courseOffering_1.Citizenship_type__c = 'INT-TEP';
    courseOffering_1.Admission_Calendar_Description__c = 'CrOf1';
    courseOffering_1.Portal_Available__c = true;
    courseOffering_1.Active__c = true;
    courseOfferings.add(courseOffering_1);
    
    Course_Offering__c courseOffering_2 = StudFirst_TestHelper.createCourseOffering(course);
    courseOffering_2.Course_Code__c = 'E6001';
    courseOffering_2.Course_Version_Number__c = 1;
    courseOffering_2.Admission_Calendar_Type__c = 'ADM-0';
    courseOffering_2.Location_Code__c = 'INDONESIA';
    courseOffering_2.Attendance_Type__c = 'FT';
    courseOffering_2.Attendance_Mode__c = 'EX';
    courseOffering_2.Admission_Category__c = 'UG-CSP';
    courseOffering_2.Academic_CI_Sequence_Number__c = 1111;
    courseOffering_2.Admission_CI_Sequence_Number__c = 1111;
    courseOffering_2.Unit_Set_Code__c = null;
    courseOffering_2.Unit_Set_Version__c = null;
    courseOffering_2.Citizenship_type__c = 'INT-TEP';
    courseOffering_2.Admission_Calendar_Description__c = 'CrOf2';
    courseOffering_2.Portal_Available__c = true;
    courseOffering_2.Active__c = true;
    courseOfferings.add(courseOffering_2);
    
    insert courseOfferings;
    System.runAs(u){
        Test.startTest();
        Assert.areEqual(0, [SELECT Id FROM Course_Offering__c].size(), 'Course Offering count should be zero');
        Test.stopTest();
    }
}


    
  
    /**
    * @description 
    * @author Ben Greenland | 2024-06-19 
    **/
@isTest
    private static void testUpsertDataBasedOnIdType(){
        //GIVEN 
        User agent = AgentPortalTestDataFactory.util.getAgentUser();
        User userx = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true  LIMIT 1];
        //Assign OES_Permission_Set as System Admin to avoid cannot perform DML on what salesforce
        //calls setup objects(User,Profile,Group,RecordType in this case) and non-setup object in the same context
        System.runAs(userx){
            //Assign OES permission set to uplift AgentPortal user as OES user
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'OES_Permission_Set'];
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId=agent.Id, PermissionSetId=ps.Id);
            insert psa;
        }

        System.runAs(agent){
            Contact con = new Contact(First_Name__c = 'Test', Last_Name__c = 'Test Last', Personal_email__c = 'test123@getnad.com', BirthDate = Date.valueOf('2003-02-01'), OwnerId = UserInfo.getUserId());
            insert con;
            Application__c app = new Application__c(Applicant__c = con.id, Status__c = 'Draft');
            insert app;
            Work_Experience__c wex1 = new Work_Experience__c(Contact__c = con.id, Position__c = 'CEO', Employer_Name__c = 'Papa Afghanistan');
            Work_Experience__c wex2 = new Work_Experience__c(Contact__c = con.id, Position__c = 'CEO', Employer_Name__c = 'Papa Arabia');
            List<Work_Experience__c> lstWEX = AgentPortalServices.updateApplicationWorkExperiences(app.id, new List<Work_Experience__c> {wex1, wex2});
            Application__c appn = [SELECT id, name FROM Application__c WHERE id = :app.id LIMIT 1];
            AgentPortalPayload.WorkExperiences apWEXs = AgentPortalServices.getWorkExperiencesByApplicationId(appn.Name);
            List<sObject> records = new List<sObject>();
            Work_Experience__c wex3 = new Work_Experience__c(External_ID__c=apWEXs.applicationExperiences[0].External_ID__c, Contact__c = con.id, Position__c = 'Boss', Employer_Name__c = 'McDonalds');
            wex3.Id = null;
            records.add(wex3);
            Work_Experience__c wex4 = new Work_Experience__c(Id=apWEXs.applicationExperiences[1].id, Contact__c = con.id, Position__c = apWEXs.applicationExperiences[1].Position__c, Employer_Name__c = apWEXs.applicationExperiences[1].Employer_Name__c);
            records.add(wex4);
       
            Schema.SObjectField fieldName = Work_Experience__c.Fields.External_ID__c;
            Test.startTest();
            List<Database.UpsertResult> results = AgentPortalServices.upsertDataBasedOnIdType(records, fieldName);
            
            Test.stopTest();
            for(Database.UpsertResult ur : results){
                Assert.isTrue(ur.isSuccess(), 'Upsert failure '+JSON.serializePretty(results));
            }
        }
    }
}