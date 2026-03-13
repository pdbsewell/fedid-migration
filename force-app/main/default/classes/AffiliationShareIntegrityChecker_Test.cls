/**
 * @description       : Test class for AffiliationShareIntegrityChecker 
 * @author            : Peter Sewell
 * @group             : Test
 * @last modified on  : 2023-12-25
 * @last modified by  : Peter Sewell
 * Modifications Log 
 * Date         Author          Modification
 * 2023-12-25 - Peter Sewell    Initial Version
 * 2023-01-15 - Peter Sewell    Update API version
**/

@isTest // (isParallel=true) not set due to DML operations not permitted PermissionSetAssignment
public without sharing class AffiliationShareIntegrityChecker_Test {

    static final string AGENCY_NAME = 'Affiliation Test Partner Agency';
    static final string AGENT_FN = 'TestAgent';
    static final string AGENT_LN = 'TestPartnerAgency';
    static final string APPLICANT_FN1 = 'TestApplicantFirstName1';
    static final string APPLICANT_LN1 = 'TestApplicantLastName1';
    static final string APPLICANT_FN2 = 'TestApplicantFirstName2';
    static final string APPLICANT_LN2 = 'TestApplicantLastName2';
    static final string APPLICANT_FN3 = 'TestApplicantFirstName3';
    static final string APPLICANT_LN3 = 'TestApplicantLastName3';
    static final string APPLICANT_FN4 = 'TestApplicantFirstName4';
    static final string APPLICANT_LN4 = 'TestApplicantLastName4';
    static final string EXTERNAL_ORGANISATION_NAME = 'Test Ext Org';

   /*******************************************************************************
    * @author       Peter Sewell
    * @date         23.Mar.2023
    * @description  Test setup
    *******************************************************************************/
    @testSetup
    static void setup() {       

        // Create the following
        User partnerAccountOwner;
        String partnerAccountId;
        String partnerContactId;
        String partnerUserId;
        List<String> applicantContactIds = new List<String>();
        List<Affiliation__c> affiliations = new List<Affiliation__c>();

        partnerAccountOwner = createPartnerAccountOwner();
        System.runAs(partnerAccountOwner) { // Run as accountOwner so partner account is owned by this user
            partnerAccountId = createPartnerAccount();
            partnerContactId = createPartnerContact(partnerAccountId);
            createPartnerUser(partnerContactId);
            createRunAsUser();
        }

        System.runAs(getPartnerUser()) { 
            applicantContactIds.add(createApplicantContact(APPLICANT_FN1, APPLICANT_LN1));
            applicantContactIds.add(createApplicantContact(APPLICANT_FN2, APPLICANT_LN2));
            applicantContactIds.add(createApplicantContact(APPLICANT_FN3, APPLICANT_LN3));
            applicantContactIds.add(createApplicantContact(APPLICANT_FN4, APPLICANT_LN4));

            affiliations.add(createApplicantAffiliate(getPartnerAccount(), getApplicantContact(APPLICANT_FN1, APPLICANT_LN1), AffiliationTriggerHandler.EDIT_SHARE));
            affiliations.add(createAffiliate(getPartnerAccount(), getApplicantContact(APPLICANT_FN2, APPLICANT_LN2), AffiliationTriggerHandler.EDIT_SHARE));
            affiliations.add(createAffiliate(getPartnerAccount(), getApplicantContact(APPLICANT_FN3, APPLICANT_LN3), AffiliationTriggerHandler.EDIT_SHARE));
        }
    }

    @isTest 
    static void testRetrievePartnerUserDetails() {
        // GIVEN
        User partnerUser = null;

        // WHEN a partner user is retrieved
        Test.startTest();
            partnerUser = getPartnerUser();
        Test.stopTest();

        // THEN parnter should not be null
        System.assert(partnerUser != null, 'ERROR: Could not find Partner User');
    }


    @isTest 
    static void testNoIntegrityIssues() {

        // GIVEN affiliation check is executed on good set of affiliations

        // WHEN it completes
        Test.startTest();
            Boolean isRepairMode = true;
            Boolean checkInactiveAffiliations = true;
            Id jobId = AffiliationShareIntegrityChecker.startBatchJob(isRepairMode, checkInactiveAffiliations);
        Test.stopTest();

        // THEN it should report zero discepencies
        AffiliationShareIntegrityChecker.JobStatus js = AffiliationShareIntegrityChecker.getBatchJobStatus(jobId);
        System.assert(js.discrepancies == 0, 'ERROR: Expected 0 integrity disprepancies but got ' + js.discrepancies);
    }

    @isTest 
    static void testIntegrityIssuesShareWithoutAffiliation() {

        // GIVEN a contact share has no matching affiliation
        //
        Affiliation__c affil = getAffiliation(APPLICANT_FN1, APPLICANT_LN1);

        user u = getRunAsUser();
        
        // Disable trigger so deleting affil should NOT delete contactshare
        //
        disableAffilTrigger(u.Username); 

        system.runAs(u) {
            delete affil;
        }

        // WHEN the integrity is checked
        Test.startTest();
            Boolean isRepairMode = true;
            Boolean checkInactiveAffiliations = true;
            Id jobId = AffiliationShareIntegrityChecker.startBatchJob(isRepairMode, checkInactiveAffiliations);
        Test.stopTest();

        // THEN a discrepancy should be found
        AffiliationShareIntegrityChecker.JobStatus js = AffiliationShareIntegrityChecker.getBatchJobStatus(jobId);
        System.assert(js.discrepancies == 1, 'ERROR: Expected 1 integrity disprepancy but got ' + js.discrepancies);
    }

    @isTest 
    static void testIntegrityIssuesAffiliationWithoutShare() {

        // GIVEN an affiliation share has no matching contact share
        ContactShare shr = getContactShare(APPLICANT_FN1, APPLICANT_LN1);
        delete shr;

        // WHEN the integrity is checked
        Test.startTest();
            Boolean isRepairMode = true;
            Boolean checkInactiveAffiliations = true;
            Id jobId = AffiliationShareIntegrityChecker.startBatchJob(isRepairMode, checkInactiveAffiliations);
        Test.stopTest();

        // THEN a discrepancy should be found
        AffiliationShareIntegrityChecker.JobStatus js = AffiliationShareIntegrityChecker.getBatchJobStatus(jobId);
        System.assert(js.discrepancies == 1, 'ERROR: Expected 1 integrity disprepancy but got ' + js.discrepancies);
    }

    @isTest 
    static void testIntegrityIssuesInactiveAffiliationHasShare() {

        // GIVEN an inactive affiliation share has a matching contact share
        Affiliation__c affil = getAffiliation(APPLICANT_FN1, APPLICANT_LN1);
        Date oneWeekAgo = System.today().addDays(-7);
        affil.End_Date__c = oneWeekAgo; // Should make affil inactive

        user u = getRunAsUser();
        disableAffilTrigger(u.Username); // Disable trigger so updating affil should NOT mess with contactshare
        system.runAs(u) {
            update affil;
        }

        // WHEN the integrity is checked and checkInactiveAffiliations is true
        Test.startTest();
            Boolean isRepairMode = true;
            Boolean checkInactiveAffiliations = true;
            Id jobId = AffiliationShareIntegrityChecker.startBatchJob(isRepairMode, checkInactiveAffiliations);
        Test.stopTest();

        // THEN a discrepancy should be found
        AffiliationShareIntegrityChecker.JobStatus js = AffiliationShareIntegrityChecker.getBatchJobStatus(jobId);
        System.assert(js.discrepancies == 1, 'ERROR: Expected 1 integrity disprepancy but got ' + js.discrepancies);
    }

    @isTest 
    static void testIntegrityIssuesBadCompositeKey() {

        // GIVEN an affiliation has a bad key
        Affiliation__c affil = getAffiliation(APPLICANT_FN1, APPLICANT_LN1);
        affil.Composite_Key__c = '0039p00000IngQQAAZ0019p00000L4bJVAAZ012000000000000000'; // Make a bad composite key
        update affil;

        // WHEN the integrity is checked
        Test.startTest();
            Boolean isRepairMode = true;
            Boolean checkInactiveAffiliations = true;
            Id jobId = AffiliationShareIntegrityChecker.startBatchJob(isRepairMode, checkInactiveAffiliations);
        Test.stopTest();

        // THEN a discrepancy should be found
        AffiliationShareIntegrityChecker.JobStatus js = AffiliationShareIntegrityChecker.getBatchJobStatus(jobId);
        System.assert(js.discrepancies == 1, 'ERROR: Expected 1 integrity disprepancy but got ' + js.discrepancies);
    }

    @isTest 
    static void testIntegrityIssuesBadSharingKey() {

        // GIVEN an affiliation has a bad key
        Affiliation__c affil = getAffiliation(APPLICANT_FN1, APPLICANT_LN1);
        affil.Sharing_Composite_Key__c = '0039p00000IngQQAAZ001000000000000000'; // Make a bad sharing key

        user u = getRunAsUser();
        disableAffilTrigger(u.Username); // Disable trigger so updating sharing key should auto regenerate
        system.runAs(u) {
            update affil;
        }

        // WHEN the integrity is checked
        Test.startTest();
            Boolean isRepairMode = true;
            Boolean checkInactiveAffiliations = true;
            Id jobId = AffiliationShareIntegrityChecker.startBatchJob(isRepairMode, checkInactiveAffiliations);
        Test.stopTest();

        // THEN a discrepancy should be found
        AffiliationShareIntegrityChecker.JobStatus js = AffiliationShareIntegrityChecker.getBatchJobStatus(jobId);
        System.assert(js.discrepancies == 1, 'ERROR: Expected 1 integrity disprepancy but got ' + js.discrepancies);
    }

    @isTest 
    static void testIgnoreBadCompositeKey() {

        // GIVEN an affiliation with a record type other than Applicant has a bad key
        Affiliation__c affil = getAffiliation(APPLICANT_FN2, APPLICANT_LN2); // No Applicant affiliation, should ignore bad key
        affil.Composite_Key__c = '0039p00000IngQQAAZ0019p00000L4bJVAAZ012000000000000000'; // Make a bad composite key
        update affil;

        // WHEN the integrity is checked
        Test.startTest();
            Boolean isRepairMode = true;
            Boolean checkInactiveAffiliations = true;
            Id jobId = AffiliationShareIntegrityChecker.startBatchJob(isRepairMode, checkInactiveAffiliations);
        Test.stopTest();

        // THEN the bad key should be ignored and zero discrepancies should be reported
        AffiliationShareIntegrityChecker.JobStatus js = AffiliationShareIntegrityChecker.getBatchJobStatus(jobId);
        System.assert(js.discrepancies == 0, 'ERROR: Expected 0 integrity disprepancies but got ' + js.discrepancies);
    }

    static User createPartnerAccountOwner() {
        
        // Create the partner account owner user
        String username = 'User' + Math.random()*100 + Datetime.now().getTime() + '@test.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        UserRole r = new UserRole(DeveloperName = 'MyCustomAccountOwnerRole', Name = 'My Account Owner Role');
        insert r;

        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, UserRoleId = r.Id,
            TimeZoneSidKey='Australia/Sydney', UserName=username);

        insert u;
        return u;
    }

    static string createPartnerAccount() {
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        Account testAccount = new Account(Name = AGENCY_NAME, RecordTypeId = partnerRecordTypeId);
        insert testAccount;
        testAccount.IsPartner = true;
        update testAccount;
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

    static string createApplicantContact(String fn, String ln) {
        Account testAccount = new Account(Name = fn + ln);
        insert testAccount;
        Id rt = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Prospective Student').getRecordTypeId();
        Contact testContact = new Contact(FirstName = fn, LastName = ln, AccountId = testAccount.Id, Email = 'TestEmail@testemail.com.' + fn + ln, RecordTypeId = rt);
        insert testContact;
        return testContact.Id;
    }

    static User getPartnerUser() {
        User partnerUser = [SELECT Id, IsPortalEnabled, UserRole.DeveloperName, UserRole.Name  
                    FROM User 
                    WHERE FirstName = :AGENT_FN
                        AND LastName = :AGENT_LN 
                        AND Contact.Account.Name = :AGENCY_NAME
                        AND Profile.Name = :Constants.PARTNER_USER_PROFILE 
                        AND IsActive = true LIMIT 1];    
        return partnerUser;
    }

    static Contact getApplicantContact(String fn, String ln) {
        List<Contact> cs = new List<Contact>();
        cs = [SELECT Id 
            FROM Contact 
            WHERE FirstName = :fn
                AND LastName = :ln 
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

    static Affiliation__c getAffiliation(String fn, String ln) {
        Contact c = getApplicantContact(fn, ln);
        return [SELECT Id, Account__c, Contact__c, Start_Date__c, End_Date__c, 
                        Share_Contact_to_Account_Role__c, Is_Active__c, isActive__c, 
                        Composite_Key__c, Sharing_Composite_Key__c,
                        RecordTypeId
                 FROM Affiliation__c WHERE Contact__c = :c.Id LIMIT 1];
    }

    static ContactShare getContactShare(String fn, String ln) {
        Contact c = getApplicantContact(fn, ln);
        return [SELECT Id FROM ContactShare WHERE ContactId = :c.Id AND Rowcause = 'Manual' LIMIT 1];
    }

    static void disableAffilTrigger(String username) {
        TriggerMuteRequest__c mr = new TriggerMuteRequest__c(Name = username, TriggersList__c = 'Affiliation__c');
        insert mr;
    }

    static void createRunAsUser() {
        String username = 'Urasoh' + Datetime.now().getTime() + '@t.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        UserRole r = new UserRole(DeveloperName = 'MyCustomTestRole', Name = 'My Custom Test Role');
        insert r;

        User u = new User(Alias = 'standt', Email='myrunasuser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, UserRoleId = r.Id,
            TimeZoneSidKey='Australia/Sydney', UserName=username);

        insert u;

        //  Assign the Integrity Checker tool perm set
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Affiliations_Integrity_Tool_User'];
        PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment(
            AssigneeId = u.Id,
            PermissionSetId = ps.Id
        );
        insert permissionSetAssignment;
    }

    static User getRunAsUser() {
        return [SELECT Id, Username FROM User WHERE Email = 'myrunasuser@testorg.com'];
    }
}