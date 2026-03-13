/**
 * @description       : Test class for Affiliation Trigger Handler 
 * @author            : Peter Sewell
 * @group             : Test
 * @last modified on  : 2023-03-14
 * @last modified by  : Peter Sewell
 * Modifications Log 
 * Date         Author          Modification
 * 2023-03-14 - Peter Sewell    - Initial Version
 * 2024-01-15 - Nick Guia       - added test coverage for exception logging when public group doesn't exist
**/
@isTest(isParallel=false) // APEX_DATA_ACCESS_RESTRICTION
public with sharing class AffiliationTriggerHandler_Test {

    static final String AGENCY_NAME = 'Test Partner Agency';
    static final String AGENT_FN = 'TestAgent';
    static final String AGENT_LN = 'TestPartnerAgency';
    static final String APPLICANT_FN = 'TestApplicantFirstName';
    static final String APPLICANT_LN = 'TestApplicantLastName';
    static final String EXTERNAL_ORGANISATION_NAME = 'Test Ext Org';

   /*******************************************************************************
    * @author       Peter Sewell
    * @date         23.Mar.2023
    * @description  Test setup
    *******************************************************************************/
    @TestSetup
    static void setup() {     
       

        // Create the following
        User partnerAccountOwner;
        String partnerAccountId;
        String partnerContactId;
        String partnerUserId;
        String applicantContactId;

        partnerAccountOwner = createPartnerAccountOwner();
        System.runAs(partnerAccountOwner) { // Run as accountOwner so partner account is owned by this user
            partnerAccountId = createPartnerAccount();
            partnerContactId = createPartnerContact(partnerAccountId);
            applicantContactId = createApplicantContact();
        }
        partnerUserId = createPartnerUser(partnerContactId);

        // NON SETUP RECORDS HERE TO AVOID MIXED DML
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // create an Agency (partner) without an active contact/user
            AgentPortalTestDataFactory apFactory = new AgentPortalTestDataFactory();
            Country_Attribute__c cAttr = apFactory.createCountryAttribute(BDPConstants.AUSTRALIA_CALLISTA_CODE, 'AUSTRALIA');
            insert cAttr;

            Account agency = apFactory.createAgencyAccount(cAttr);
            agency.Name = 'PARTNER_NO_USER';
            insert agency;
        }

        
    }

    /**
     * @description test that setup data is in place
     */
    @isTest 
    static void test_RetrievePartnerUserDetails() {
        User partnerUser = null;

        Test.startTest();
            partnerUser = getPartnerUser();
        Test.stopTest();

        Assert.isNotNull(partnerUser, 'Could not find Partner User');
    }

    /**
     * @description test Contact record sharing. In this test,
     *  an Agent should not have access to the Contact record
     */
    @isTest 
    static void test_ApplicantNotAccessibleToPartner() {

        Contact applicantContact = null;

        Test.startTest();
            System.runAs(getPartnerUser()) {
                // Should not return contact as contact is not shared to partner user
                applicantContact = getApplicantContact();
            }
        Test.stopTest();

        Assert.isNull(applicantContact, 'Applicant contact record should not be accessible to partner user');
    }

    /**
     * @description test Contact record sharing. In this test,
     *  an Agent should have access to the Contact record because an Affiliation is in place
     */
    @isTest 
    static void test_AffiliatedApplicantIsAccessibleToPartner() {

        Contact applicantContact = null;

        Test.startTest();
            Affiliation__c affil = createAffiliate(getPartnerAccount(), getApplicantContact(), AffiliationTriggerHandler.EDIT_SHARE);
            System.runAs(getPartnerUser()) {
                // Should return contact as contact should now be shared to partner user
                applicantContact = getApplicantContact();
            }
        Test.stopTest();

        Assert.isNotNull(applicantContact, 'Applicant contact record should be accessible to partner user due to affiliation');
    }

    /**
     * @description test Contact record sharing. In this test,
     *  an Agent should not have access to the Contact record anymore
     *  after deleting the related Affiliation record
     */
    @isTest 
    static void test_AffiliatedApplicantNotAccessibleAfterAffiliationDeleted() {

        Contact applicantContact = null;

        Test.startTest();
            Affiliation__c affil = createAffiliate(getPartnerAccount(), getApplicantContact(), AffiliationTriggerHandler.EDIT_SHARE);
            deleteAffiliate(affil);
            System.runAs(getPartnerUser()) {
                // Should not return contact as contact should no longer be shared to partner user
                applicantContact = getApplicantContact();
            }
        Test.stopTest();

        Assert.isNull(applicantContact, 'Applicant contact record should NOT be accessible to partner user after affiliation deleted');
    }

    @isTest 
    static void test_ApplicantNotAccessibleWhenAffiliatedToAnotherAccount() {

        Contact applicantContact = null;

        Test.startTest();
            Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
            Account testAccount = new Account(Name = 'Another Account That Should Not Work', RecordTypeId = partnerRecordTypeId);
            insert testAccount;
            Affiliation__c affil = createAffiliate(testAccount, getApplicantContact(), AffiliationTriggerHandler.EDIT_SHARE);
            System.runAs(getPartnerUser()) {
                // Should not return contact as contact should not be shared with this user
                applicantContact = getApplicantContact();
            }
        Test.stopTest();

        Assert.isNull(applicantContact, 'Applicant contact record should NOT be accessible to partner user after affiliated to another account');
    }

    @isTest 
    static void test_ApplicantNotAccessibleWhenAffiliationIsNotSharingEnabled() {

        Contact applicantContact = null;

        Test.startTest();
            Affiliation__c affil = createAffiliate(getPartnerAccount(), getApplicantContact(), AffiliationTriggerHandler.NO_SHARE);
            System.runAs(getPartnerUser()) {
                // Should not return contact as contact should NOT be shared to partner user when sharing mode is not set on affiliation
                applicantContact = getApplicantContact();
            }
        Test.stopTest();

        Assert.isNull(applicantContact, 'Applicant contact record should not be accessible to partner user when affiliation has no sharing mode set');
    }

    @isTest 
    static void test_AffiliatedApplicantStillAccessibleAfterAffiliationUpdate() {

        Contact applicantContact = null;

        Test.startTest();
            Affiliation__c affil = createAffiliate(getPartnerAccount(), getApplicantContact(), AffiliationTriggerHandler.EDIT_SHARE);
            updateAffiliateShareMode(affil, AffiliationTriggerHandler.READ_SHARE);
            System.runAs(getPartnerUser()) {
                applicantContact = getApplicantContact();
            }
        Test.stopTest();

        Assert.isNotNull(applicantContact, 'Applicant contact record should still be accessible to partner user after affiliation share mode updated');
    }

    @isTest 
    static void test_AffiliatedApplicantStillAccessibleAfterContactOwnerChanged() {

        Contact applicantContact = null;

        Test.startTest();
            Affiliation__c affil = createAffiliate(getPartnerAccount(), getApplicantContact(), AffiliationTriggerHandler.EDIT_SHARE);
            updateApplicantContactOwner(UserInfo.getUserId());
            System.runAs(getPartnerUser()) {
                applicantContact = getApplicantContact();
            }
        Test.stopTest();

        Assert.isNotNull(applicantContact, 'Applicant contact record should still be accessible to partner user after contact owner changed');
    }

    @isTest 
    static void test_ConflictingAffiliationShouldBeRejected() {

        Contact applicantContact = null;

        Test.startTest();
            try {
                Affiliation__c affil1 = createAffiliate(getPartnerAccount(), getApplicantContact(), AffiliationTriggerHandler.EDIT_SHARE);
                Affiliation__c affil2 = createAffiliate(getPartnerAccount(), getApplicantContact(), AffiliationTriggerHandler.READ_SHARE);
            } catch (DmlException ex) {
                // duplicate value found
                Assert.isTrue(ex.getMessage().containsIgnoreCase('duplicate value found'), 'Conflicting affiliation record should be rejected');
            } 
        Test.stopTest();

    }

    @isTest 
    static void test_DeepContains() {

        Boolean deepContains = false;
        Affiliation__c affil;
        List<Affiliation__c> affils = new List<Affiliation__c>();

        Test.startTest();
            affil = createAffiliate(getPartnerAccount(), getApplicantContact(), AffiliationTriggerHandler.EDIT_SHARE);
            affils.add(affil);
            deepContains = AffiliationTriggerHandler.deepContains(affil, affils);
        Test.stopTest();

        Assert.isTrue(deepContains, 'deepContains() should have returned true as affiliation record is in list');

    }

    @isTest 
    static void test_CompositeKey() {
        //GIVEN: Affiliation Record
        Id applicantRecordTypeId = Schema.SObjectType.Affiliation__c.getRecordTypeInfosByName().get('Applicant').getRecordTypeId();
        Affiliation__c affil;
        List<Affiliation__c> affils = new List<Affiliation__c>();     
        //WHEN: Affiliation record is created   
        Test.startTest();
            affil = createApplicantAffiliate(getPartnerAccount(), getApplicantContact(), AffiliationTriggerHandler.EDIT_SHARE);
        Test.stopTest();
        //THEN: Composite Key is being populated using the combination of contactid, accountId, and recordtypeid 
        Affiliation__c affilRecord = [Select Id, Contact__c, Account__c, Start_Date__c, Composite_Key__c from Affiliation__c];
        String compositeKey = String.valueOf(affilRecord.Contact__c) + String.valueOf(affilRecord.Account__c) + applicantRecordTypeId;
        Assert.areEqual(affilRecord.Composite_Key__c, compositeKey, 'Composite Key is not equal');
    }

    @isTest 
    static void test_RegenerateCompositeKey() {     
        //GIVEN: Affiliation Record  
        Id applicantRecordTypeId = Schema.SObjectType.Affiliation__c.getRecordTypeInfosByName().get('Applicant').getRecordTypeId();
        Affiliation__c affil;
        List<Affiliation__c> affils = new List<Affiliation__c>();        
        //WHEN: Affiliation record is updated  
        Test.startTest();
            affil = createApplicantAffiliate(getPartnerAccount(), getApplicantContact(), AffiliationTriggerHandler.EDIT_SHARE);
            affil.Account__c = createExternalOrgAccountToUpdateCompositeKey();
            update affil;
        Test.stopTest();
        //THEN: A new Composite Key is generated using the combination of contactid, accountId, and recordtypeid 
        Affiliation__c affilRecord = [Select Id, Contact__c, Account__c, Start_Date__c, Composite_Key__c from Affiliation__c];
        String compositeKey = String.valueOf(affilRecord.Contact__c) + String.valueOf(affilRecord.Account__c) + applicantRecordTypeId;
        Assert.areEqual(affilRecord.Composite_Key__c, compositeKey, 'Composite Key is not equal');
    }

    static User createPartnerAccountOwner() {
        
        // Create the partner account owner user
        String Username = 'User' + Math.random()*100 + Datetime.now().getTime() + '@test.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        UserRole r = new UserRole(DeveloperName = 'MyCustomAccountOwnerRole', Name = 'My Account Owner Role');
        insert r;

        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, UserRoleId = r.Id,
            TimeZoneSidKey='Australia/Sydney', UserName=Username);

        insert u;
        return u;
    }

    static string createPartnerAccount() {
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        Account testAccount = new Account(Name = AGENCY_NAME, RecordTypeId = partnerRecordTypeId);
        insert testAccount;
        return testAccount.Id;
    }
    

    static string createPartnerContact(String accountId) {
        Contact testContact = new Contact(FirstName = AGENT_FN, LastName = AGENT_LN, AccountId = accountId, Email = 'TestEmail@testemail.com');
        insert testContact;
        return testContact.Id;
    }    

    static string createPartnerUser(String contactId) {
        ExperienceAuthenticationServices.generatePartnerUser('{"ContactId":"' + contactId + '","FirstName":"' + AGENT_FN + '","MiddleName":"AgencyPartner","LastName":"' + AGENT_LN + '","Suffix":"TestSuffix","Email":"testemail@testemail.com","Username":"' + String.valueOf(Math.random()) + 'testemail@testemail.com","Nickname":"TestNickname","DelegatedAdmin":' + true + '}');
        User partnerUser = getPartnerUser();
        return partnerUser.Id;
    }   

    static string createApplicantContact() {
        Account testAccount = new Account(Name = APPLICANT_FN + APPLICANT_LN);
        insert testAccount;
        // Use this record type to restrict sharing
        Id rt = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Prospective Student').getRecordTypeId();
        Contact testContact = new Contact(FirstName = APPLICANT_FN, LastName = APPLICANT_LN, AccountId = testAccount.Id, Email = 'TestEmail@testemail.com', RecordTypeId = rt);
        insert testContact;
        return testContact.Id;
    } 

    static void updateApplicantContactOwner(String userId) {
        Contact applicant = getApplicantContact();
        applicant.OwnerId = userId;
        update applicant;
    } 

    static User getPartnerUser() {
        User partnerUser = [SELECT Id 
                    FROM User 
                    WHERE FirstName = :AGENT_FN
                        AND LastName = :AGENT_LN 
                        AND Contact.Account.Name = :AGENCY_NAME
                        AND Profile.Name = :Constants.PARTNER_USER_PROFILE 
                        AND IsActive = true LIMIT 1];    
        return partnerUser;
    }

    static Contact getApplicantContact() {
        List<Contact> cs = new List<Contact>();
        cs = [SELECT Id, Personal_email__c, Mobilephone, Email, FirstName
            FROM Contact 
            WHERE FirstName = :APPLICANT_FN
                AND LastName = :APPLICANT_LN 
            LIMIT 1];  
        
        if (!cs.isEmpty()) {
            return cs[0];
        } else {
            return null;
        }
    }

    static Account getPartnerAccount() {
        List<Account> accts = new List<Account>();
        accts = [SELECT Id 
            FROM Account 
            WHERE Name = :AGENCY_NAME
            LIMIT 1];  
        
        if (!accts.isEmpty()) {
            return accts[0];
        } else {
            return null;
        }
    }

    static Affiliation__c createAffiliate(Account acc, Contact ctc, String shareMode) {
        Affiliation__c affil = new Affiliation__c(Account__c = acc.id, Contact__c = ctc.id, Start_Date__c = Date.newInstance(2022, 1, 1), Share_Contact_to_Account_Role__c = shareMode);
        insert affil;
        return affil;
    }

    static Affiliation__c createApplicantAffiliate(Account acc, Contact ctc, String shareMode) {
        Id applicantRecordTypeId = Schema.SObjectType.Affiliation__c.getRecordTypeInfosByName().get('Applicant').getRecordTypeId();
        Affiliation__c affil = new Affiliation__c(Account__c = acc.id, Contact__c = ctc.id, Start_Date__c = Date.newInstance(2022, 1, 1), Share_Contact_to_Account_Role__c = shareMode,recordtypeID=applicantRecordTypeId);
        insert affil;
        return affil;
    }

    static string createExternalOrgAccountToUpdateCompositeKey() {
        Id externalRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('External Organisation').getRecordTypeId();
        Account testAccount = new Account(Name = EXTERNAL_ORGANISATION_NAME, RecordTypeId = externalRecordTypeId);
        insert testAccount;
        return testAccount.Id;
    }

    static void updateAffiliateShareMode(Affiliation__c affil, String shareMode) {
        affil.Share_Contact_to_Account_Role__c = shareMode;
        update affil;
    }

    static void deleteAffiliate(Affiliation__c affil) {
        delete affil;
    }

    @istest
    static void testUpdateOwnerToSystemDataOwner()
    {
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
        systemownerDetail.ByPassUser__c  = '0012A00000abcde';
        DataOwnerList.add(systemownerDetail);
        insert DataOwnerList;
        String Username = 'User' + Math.random()*100 + Datetime.now().getTime() + '@test.com';
        String Username2 = 'User2' + Math.random()*100 + Datetime.now().getTime() + '@test.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        
        List<User> userlist = new List<user>();

        User u = new User(Alias = 'standt', Email='cachesystemowner123contact@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='cachesystemowner123', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, federationidentifier = 'randomacc345',
            TimeZoneSidKey='Australia/Sydney', UserName=Username);
			userlist.add(u);
        User u1 = new User(Alias = 'standt', Email='cachesystemowner345account@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='cachesystemowner678', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, federationidentifier = 'randomacc123',
            TimeZoneSidKey='Australia/Sydney', UserName=Username2);
        userlist.add(u1);
        insert userlist;
        Affiliation__c affil;
        List<Affiliation__c> affils = new List<Affiliation__c>();

        Test.startTest();

        affil = createApplicantAffiliate(getPartnerAccount(), getApplicantContact(), AffiliationTriggerHandler.EDIT_SHARE);
        Assert.areEqual(contactDataOwner.FederationId__c, 'randomacc345');

        Test.stopTest();
    }

    /**
     * @description When affiliation sharing kicks off for an agency that doesn't
     * have an existing public group yet e.g. no active user within the partner account,
     * it should generate an exception log informing admins that it occurred for specific
     * Contact/Account
     */
    @isTest
    static void shouldCreateLogWhenSharingWithNoPublicGroup() {

        // GIVEN
        Account agency = [SELECT Id 
                        FROM Account 
                        WHERE Name = 'PARTNER_NO_USER' 
                        LIMIT 1];
        Contact con = getApplicantContact();
       
        //Insert custom settings for Bypass_Mute_Request__c
        Bypass_Mute_Request__c bmr = Bypass_Mute_Request__c.getOrgDefaults();
        bmr.Enable_LogUtility_Debug__c = true;
        bmr.Enable_LogUtility_ShowLimits__c = true;
        upsert bmr;  

        AgentPortalTestDataFactory apFactory = new AgentPortalTestDataFactory();
        Affiliation__c applicantAff = apFactory.createApplicantAffiliation(con, agency);
        applicantAff.Share_Contact_to_Account_Role__c = 'Read';
       
        Test.startTest();
        // WHEN
        insert applicantAff;
        Test.stopTest();
        
        // THEN
        Assert.areEqual(0, [select id from ContactShare where ContactId=:applicantAff.Contact__c and ContactAccessLevel=:applicantAff.Share_Contact_to_Account_Role__c].size(), 'Contact should not be shared');
    }

    /**
     * @description Test to verify that when an Affiliation is created, Contact Points Affiliation
     * creation also happens
     */
    @isTest 
    static void test_CPACreation() {

        //GIVEN 
        Contact applicantContact = getApplicantContact();
        applicantContact.Personal_email__c = 'testcontact@edu.com';
        applicantContact.Mobilephone = '044444444';
        update applicantContact;

        //Create Phone__c CP
        Phone__c testPrimaryPhone =
                new Phone__c(Name = applicantContact.Mobilephone, Contact__c = applicantContact.Id,
                Classification__c = 'Private', Type__c = 'Mobile',
                Source__c = 'Undefined',Is_Active__c = true,
                Start_Date__c = Date.today().addYears(-1), End_Date__c = null, Is_Primary__c = TRUE);
         insert testPrimaryPhone;
         
         //Create Email__C CP
         Email__C em = new Email__c(
            Contact__c = applicantContact.id,
            Source__c = 'Undefined', Is_Active__c = true,
            Name = applicantContact.Personal_email__c,
            Classification__c = 'Private',
            Start_Date__c = Date.today().addYears(-1)
        );
        insert em;

         //Create Address__c CP
        Address__c addRess = new Address__c();
        addRess.Contact__c = applicantContact.Id;
        addRess.Start_Date__c = Date.today();
        addRess.Is_Primary__c = true;
        addRess.Is_Active__c = true;
        addRess.Source__c = 'Undefined';
        addRess.Type__c = 'Physical';
        addRess.Classification__c = 'Private';
        addRess.Street_Name__c = '120 Collins Street';
        addRess.City__c = 'Melbourne';
        addRess.State__c = 'Victoria';
        addRess.Post_Code__c = '3000';
        addRess.Country2__c = 'Australia';
        insert addRess;

        //WHEN
        Test.startTest();
        AgentPortalTestDataFactory apFactory = new AgentPortalTestDataFactory();
        Affiliation__c applicantAff = apFactory.createApplicantAffiliation(applicantContact, getPartnerAccount());
        applicantAff.Share_Contact_to_Account_Role__c = 'Read';
        insert applicantAff;
        Test.stopTest();

        //THEN
        Assert.areEqual(3, [SELECT ID FROM Contact_Point_Affiliation__c where Contact__c=:applicantContact.Id]?.size(), '3 CPA records should be created');
    }
}