/*
 * @author       Kristian Vegerano
 * @date         29/07/2020
 * @description  test class for MyAppWelcomeEmailController class
 */
@isTest
public with sharing class MyAppWelcomeEmailController_Test {

    @testSetup static void setup() {
        //Account Creation
        Account acc1 = (Account)TestDataFactory.createSObject(new Account(Name='Test Accnt 1'), true);

        //Contact Creation
        Contact contact1 = (Contact)TestDataFactory.createSObject(new Contact(
            AccountId = acc1.Id,
            Email='contact1@email.com',
            Firstname='firstname',
            LastName='lastname'
        ), true);

        //Create Community User
        String random = String.valueOf(System.currentTimeMillis());
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = :UserServices.CUSTOMER_COMMUNITY_PROFILE_COMMON LIMIT 1];
        User communityUser = new User(
            UserName = random + contact1.Email,
            FirstName = contact1.FirstName,
            LastName = contact1.LastName,
            Alias = 'test_cu',
            CommunityNickname = 'test_cu' + random,
            email = contact1.Email,
            ContactId = contact1.Id,
            ProfileId = communityProfile.Id,
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'Australia/Sydney',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US'
        );
        insert communityUser;

        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId=acc1.Id,Pricebook2Id = Test.getStandardPricebookId(), CloseDate = Date.today().addDays(15)),true);
        SBQQ.TriggerControl.disable();
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        TriggerCommon.disableTrigger('SBQQ__QuoteLine__c');
        QuoteTriggerHandler.lockUserCreation = true;
        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Account__c=acc1.Id,SBQQ__PricebookId__c = Test.getStandardPricebookId(), SBQQ__PrimaryContact__c=contact1.Id,SBQQ__Status__c='Publish',Sub_Status__c='In Progress',SBQQ__Opportunity2__c=opp.Id,SBQQ__ExpirationDate__c = opp.CloseDate, SBQQ__Primary__c = true),true);
        quote1.SBQQ__ExpirationDate__c = System.TODAY().addDays(6);
        update quote1;

        TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote1.Id), true);     
        
        //Create setting for Countries
        Country_Attribute__c australia = new Country_Attribute__c(Name = 'AUSTRALIA',
                                                                  Callista_Code__c = BDPConstants.AUSTRALIA_CALLISTA_CODE,
                                                                  Country__c = 'Australia');
        insert australia;  
    }

    @isTest 
    static void test_RetrieveDetails(){
        Id contactId = [SELECT Id FROM Contact WHERE Email = 'contact1@email.com' ORDER BY CreatedDate DESC LIMIT 1][0].Id;
        Id quoteId = [SELECT Id FROM SBQQ__Quote__c ORDER BY CreatedDate DESC LIMIT 1][0].Id;

        Id offerRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Applicant_Enrolment').getRecordTypeId();
        Opportunity testOpportunity = [SELECT Id FROM Opportunity ORDER BY CreatedDate DESC LIMIT 1][0];
        testOpportunity.StageName = 'Publish';
        testOpportunity.RecordTypeId = offerRecordTypeId;
        testOpportunity.PrimaryContact__c = contactId;        
        testOpportunity.Regeneration_Reason__c = 'Test';
        testOpportunity.Primary_Quote_Regeneration_Date__c = System.TODAY().addDays(6);
        testOpportunity.SBQQ__PrimaryQuote__c = quoteId;
        update testOpportunity;

        String userFirstName;
        String headerContent;
        Boolean hasOffer;
        Boolean isUnder18;
        Boolean isShowExpire;
        String expireDate;
        Boolean isOfferRegenerated;
        String offerRegenerationReason;

        Test.startTest();
        MyAppWelcomeEmailController emailTemplateController = new MyAppWelcomeEmailController();
        emailTemplateController.UserContactID = contactId;
        emailTemplateController.initialized = true;
        emailTemplateController.contactEmail = 'testemail';
        emailTemplateController.networkUrlForUserEmails = 'testemail';
        userFirstName = emailTemplateController.getUserFirstName();
        headerContent = emailTemplateController.getHeaderContent();
        hasOffer = emailTemplateController.getHasOffer();
        isUnder18 = emailTemplateController.getIsUnder18();
        isShowExpire = emailTemplateController.getIsShowExpire();
        expireDate = emailTemplateController.getExpireDate();
        isOfferRegenerated = emailTemplateController.getIsOfferRegenerated();
        offerRegenerationReason = emailTemplateController.getOfferRegenerationReason();
        Test.stopTest(); 

        System.assertNotEquals(userFirstName, null);
        System.assertNotEquals(headerContent, null);
        System.assertNotEquals(hasOffer, null);
        System.assertNotEquals(isUnder18, null);
        System.assertNotEquals(isShowExpire, null);
        System.assertNotEquals(expireDate, null);
        System.assertNotEquals(isOfferRegenerated, null);
        System.assertNotEquals(offerRegenerationReason, null);
    }

    /**
     * @author      Kristian Vegerano
     * @description Tests retrieveing partner account details on welcome email
     * @revision    22/04/2021 - Kristian Vegerano - Created
     */
    @isTest 
    static void test_RetrievePartnerDetails(){
        // Initialize variables
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        Boolean hasPartnerInitiatedApplication = false;
        String partnerName = '';

        // Create partner details
        Account testAccount = new Account(Name = 'TestAccount', RecordTypeId = partnerRecordTypeId);
        insert testAccount;
        Contact testContact = new Contact(FirstName = 'TestFirstName', LastName = 'TestLastName', AccountId = testAccount.Id, Email = 'TestEmail@testemail.com');
        insert testContact;
        ExperienceAuthenticationServices.generatePartnerUser('{"ContactId":"' + testContact.Id + '","FirstName":"TestFirstName","MiddleName":"TestMiddleName","LastName":"TestLastName","Suffix":"TestSuffix","Email":"testemail@testemail.com","Username":"' + String.valueOf(Math.random()) + 'testemail@testemail.com","Nickname":"TestNickname","DelegatedAdmin":' + true + '}');
        User partnerUser = [SELECT Id 
                            FROM User 
                            WHERE ContactId = :testContact.Id 
                                AND Contact.AccountId = :testAccount.Id
                                AND Profile.Name = :Constants.PARTNER_USER_PROFILE 
                                AND IsActive = true LIMIT 1];

        // Create application as the partner user
        Contact testApplicantContact = new Contact(FirstName = 'TestFirstName', LastName = 'TestLastName', AccountId = testAccount.Id, Email = 'TestEmailApplicant@testemail.com');
        System.runAs(partnerUser){
            PartnerApplicationService.createApplication(JSON.serialize(testApplicantContact),
                                                        testAccount.Id,
                                                        'Exchange',
                                                        '1', 
                                                        'Australia',
                                                        'DOM-AUS');
        }

        // Start test
        Id contactId = [SELECT Id FROM Contact WHERE Email = 'TestEmailApplicant@testemail.com' ORDER BY CreatedDate DESC LIMIT 1][0].Id;
        Test.startTest();
            MyAppWelcomeEmailController emailTemplateController = new MyAppWelcomeEmailController();
            emailTemplateController.UserContactID = contactId;
            emailTemplateController.initialized = true;
            emailTemplateController.contactEmail = 'testemail';
            emailTemplateController.networkUrlForUserEmails = 'testemail';
            
            hasPartnerInitiatedApplication = emailTemplateController.getHasPartnerInitiatedApplication();
            partnerName = emailTemplateController.getPartnerName();
        Test.stopTest();
        
        // Check results
        // Email template detected that the latest draft application is created by a partner user
        System.assertEquals(hasPartnerInitiatedApplication, true);
        // Email template detected the partner account name
        System.assertEquals(partnerName, testAccount.Name);
    }
    
     /**
     * @author      Shalini Mendu
     * @description Tests retrieveing AgentPortal applicant contact details on welcome email
     * @revision    20/06/2023 - SMendu - Created
     */
    @isTest 
    static void test_RetrieveAgentDetails(){
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

        Contact testAgentCon = new Contact(RecordTypeId=agentRecType,FirstName = 'TestFirstName', LastName = 'TestLastName', AccountId = testAgency.Id
                                        , Email = 'TestEmail@testemail.com', Agency_Contact_Roles__c = 'Branch Manager;Delegated Admin');
        Contact secondAgentContact = new Contact(RecordTypeId=agentRecType, FirstName = 'Carborundum', LastName = 'TestLastName', AccountId = testAgency.Id, Email = 'TestEmail1996@testemail.com', Agency_Contact_Roles__c = 'Counsellor');
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
            
            PermissionSetGroup agentPSG = [SELECT Id, Status FROM permissionSetGroup WHERE developername = :AgentPortalConstants.AGENT_PERMISSION_SET_GROUP]; 
            // force calculation of the PSG if it is not already Updated
            if (agentPSG.Status != 'Updated') {
                Test.calculatePermissionSetGroup(agentPSG.Id);
            }
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId=testAgentUser.Id,PermissionSetGroupId=agentPSG.Id);
            insert psa;
        }
        User u = [SELECT id, Contact.AccountId FROM User WHERE username LIKE '%testAgentLastName@TestEmail.com.domain%' LIMIT 1 ];

        Contact con = new Contact(First_Name__c = 'Test', Last_Name__c = 'Test Last', Personal_email__c = 'test123@getnad.com', BirthDate = Date.valueOf('2003-02-01'), OwnerId = u.id);
        insert con;
        
        // TODO :: Affiliation based check has to be inserted here
        Application__c appPositive = new Application__c (Applicant__c = con.id, Agent__c = u.Contact.AccountId, Status__c =  'Draft', Source_System__c = 'AgentPortal');
        MyAppWelcomeEmailController emailTemplateController = null;
        Test.startTest();
            System.runAs(u){
                appPositive = (Application__c) AgentPortalServices.createApplication(appPositive,'test123@getnada.com', '98769876');
                appPositive.Status__c = AgentPortalConstants.SEND_DRAFT_APPLICATION_TO_APPLICANT;
                update appPositive;
                emailTemplateController = new MyAppWelcomeEmailController();
                emailTemplateController.UserContactID = con.Id;
                emailTemplateController.initialized = true;
                emailTemplateController.contactEmail = 'testemail@getnada.com';
                emailTemplateController.networkUrlForUserEmails = 'testemail';
             }
        Test.stopTest();
          System.assertEquals(true, emailTemplateController.getInitiatedSendDraftToApplicant(), 'It should be true');
          System.assertEquals( false, emailTemplateController.getDefaultApplication(), 'It should be false');
          System.assertEquals('TestAgencyAccount', emailTemplateController.getAgentName(), 'It should be TestAgencyAccount ');
    }
                 
    
}