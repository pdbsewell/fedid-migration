/**
 * @author          Matthew Maramot
 * @description     Test class to verify the contact merge controller
 * @revision        1.0
 */
@isTest
public class ContactMergeController_Test {
    /**
     * @description Setup test data
     */
    @testSetup
    static void setup() {
        // Primary contact
        Contact con1 = new Contact(
            FirstName = 'Controller',
            LastName = 'Test',
            Email = 'Controller.Test@student.monash.edu',
            Personal_Email__c = 'Controller.Test_testonly@email.com',
            Person_ID_unique__c = '1' + String.valueOf(math.random()).substring(0,6).replaceAll('.',''),
            MobilePhone = '0423470137',
            Monash_Email_Address__c = 'Controller.Test@student.monash.edu',
            Contact_Profile__c = 'Alumni,Alumni No Degree,Donor',
            BirthDate = Date.valueOf('1991-12-12')
            );
        // Duplicate contact
        Contact con2 = new Contact(
            FirstName = 'Controller',
            LastName = 'Test2',
            Email = 'Controller.Test@student.monash.edu',
            Personal_Email__c = 'Controller.Test_testonly@email.com',
            Person_ID_unique__c = '2' + String.valueOf(math.random()).substring(0,6).replaceAll('.',''),
            MobilePhone = '0423470137',
            Monash_Email_Address__c = 'Controller.Test@student.monash.edu',
            BirthDate = Date.valueOf('1991-12-12')
            );
        List<Contact> cons = new List<Contact> {
            con1, con2
        };
        insert cons;
        // Primary user
        Profile portalProfile = [SELECT Id FROM Profile WHERE Name='Customer Community General User' Limit 1];
        Profile baseProf = [SELECT Id FROM Profile WHERE Name='Base Profile' Limit 1];
        User user1 = new User(
            UserName = con1.Email + math.random(),
            FirstName = con1.FirstName,
            LastName = con1.LastName,
            Alias = 'prim' + String.valueOf(math.random()).substring(0,4),
            email = con1.Email,
            ContactId = con1.Id,
            ProfileId = portalProfile.Id,
            EmailEncodingKey = 'UTF-8',
            CommunityNickName = 'a' + String.valueOf(math.random()).substring(0,6),
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            IsActive = true
            );
        // Duplicate user
        User user2 = new User(
            UserName = con2.Email + math.random(),
            FirstName = con2.FirstName,
            LastName = con2.LastName,
            Alias = 'dupl' + String.valueOf(math.random()).substring(0,4),
            email = 'Controller.Test@guerilla.com',
            ContactId = con2.Id,
            ProfileId = portalProfile.Id,
            EmailEncodingKey = 'UTF-8',
            CommunityNickName = 'b' + String.valueOf(math.random()).substring(0,6),
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            FederationIdentifier = 'dupltest',
            MonashObjectId__c = 'zzzzzzzz-1111-zzzz-11zz11-zzzzzzzzzzzz',
            IsActive = true
            );
        User nonAdminUsr = new User(
            UserName = 'nonadminuser@test.com' + math.random(),
            FirstName = 'NonAdmin',
            LastName = 'MonashUser',
            Alias = 'nonA' + String.valueOf(math.random()).substring(0,4),
            email = 'nonadminuser@test.com',
            ProfileId = baseProf.Id,
            EmailEncodingKey = 'UTF-8',
            CommunityNickName = 'nx' + String.valueOf(math.random()).substring(0,6),
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            FederationIdentifier = 'nonadUsr',
            MonashObjectId__c = 'xxxxxxxx-1111',
            IsActive = true
            );
        List<User> users = new List<User> {
            user1, user2, nonAdminUsr
        };
        insert users;
        //Assign the permission set
        List<PermissionSetAssignment> psaLists = new List<PermissionSetAssignment>();
        for (PermissionSet ps :[SELECT Id, Name FROM PermissionSet WHERE Name = 'Manage_User_and_Modify_All_Data' OR Name = 'Contact_Merge_App_Access']) {
            PermissionSetAssignment psa1 = new PermissionSetAssignment();
            psa1.AssigneeId = nonAdminUsr.Id;
            psa1.PermissionSetId = ps.Id;
            psaLists.add(psa1);
        }
        // Permission Set License
        PermissionSetLicense psLicense = [SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'SalesforceCPQ_CPQStandardPerm' LIMIT 1];
        PermissionSetLicenseAssign psUsrLic = new PermissionSetLicenseAssign();
        psUsrLic.AssigneeId = user2.Id;
        psUsrLic.PermissionSetLicenseId = psLicense.Id;
        //
        UserServices.InsertSobjectsQueueable insertPSLQueuable = new UserServices.InsertSobjectsQueueable(new List<PermissionSetLicenseAssign> {psUsrLic}, false); // do not fail all records if a particular item fails
        Id jobPSLId = System.enqueueJob(insertPSLQueuable);
        // Permission set
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Alumni_Portal_Permission_Set' LIMIT 1];
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = user2.Id;
        psa.PermissionSetId = ps.Id;
        psaLists.add(psa);
        //
        UserServices.InsertSobjectsQueueable insertQueuable = new UserServices.InsertSobjectsQueueable(psaLists, false); // do not fail all records if a particular item fails
        Id jobId = System.enqueueJob(insertQueuable);
        // Contact points
        List<Phone__c> conPoints = new List<Phone__c> {
            new Phone__c(
                Contact__c = con1.id,
                Name = '0411111111',
                Type__c = 'Mobile',
                Classification__c = 'Private'
                ),
            new Phone__c(     // Duplicatate for try catch clause
                Contact__c = con2.id,
                Name = '0411111111',
                Type__c = 'Mobile',
                Classification__c = 'Private'
                ),
            new Phone__c(
                Contact__c = con2.id,
                Name = '0425345759',
                Type__c = 'Mobile',
                Classification__c = 'Private'
                )
        };
        insert conPoints;
        // Lead
        List<Lead> leads = new List<Lead> {
            new Lead(
                Contact__c = con2.id,
                LastName =con2.LastName,
                Company='Monash University',
                Active_Lead_Contact_Id__c = con2.id,
                Status = 'Open')
        };
        insert leads;
    }

    @isTest
    static void testQuery() {
        // Data wrapping
        Contact primaryContact = [SELECT id, Account.id, lastName, firstName, Email FROM Contact WHERE FirstName='Controller' AND LastName='Test' AND Monash_Email_Address__c='Controller.Test@student.monash.edu' LIMIT 1];
        List<ContactMergeData> entityDataList = ContactMergeController.getEntityData('', '', primaryContact.Email, '', '');
    }

    @isTest
    static void testMergeAcctConLeadPts() {
        // Data wrapping
        Contact primaryContact = [SELECT id, Account.id, lastName, firstName, Email FROM Contact WHERE FirstName='Controller' AND LastName='Test' AND Monash_Email_Address__c='Controller.Test@student.monash.edu' LIMIT 1];
        List<ContactMergeData> entityDataList = ContactMergeController.getEntityData(primaryContact.firstName, primaryContact.lastName + '*', '', '', '');
        // Merging Accounts
        Id primAccountId;
        Id dupAccountId;
        Id primContactId;
        Id dupContactId;
        for (ContactMergeData cmdObj :entityDataList) {
            if (cmdObj.isPrimary) {
                primAccountId = cmdObj.accountRecord.Id;
                primContactId = cmdObj.contactRecord.Id;
            } else {
                dupAccountId = cmdObj.accountRecord.Id;
                dupContactId = cmdObj.contactRecord.Id;
            }
        }
        System.assertNotEquals(primAccountId, null, 'primAccountId is Null');
        System.assertNotEquals(dupAccountId, null, 'dupAccountId is Null');
        System.assertNotEquals(primContactId, null, 'primContactId is Null');
        System.assertNotEquals(dupContactId, null, 'dupContactId is Null');
        Account primAccount = [SELECT Id, acn__c FROM Account WHERE Id =: primAccountId];
        primAccount.acn__c = '123456789';
        Account dupAccount = [SELECT Id, acn__c FROM Account WHERE Id =: dupAccountId];
        dupAccount.acn__c = '111111111';
        Map<Id,Account> accounts = new Map<Id,Account> {
            primAccountId=> primAccount,
            dupAccountId=> dupAccount
        };
        update accounts.values();
        ContactMergeController.mergeAccount(primAccountId,dupAccountId,primaryContact.Id);
        // Merging Accounts - Validation
        primAccount = [SELECT Id, acn__c FROM Account WHERE Id =: primAccountId];
        system.AssertEquals('123456789', primAccount.acn__c, 'Primary account did not maintain field.'); // Primary account should maintain field value
        Lead dupLead  = [SELECT Id, Active_Lead_Contact_Id__c FROM Lead LIMIT 1];
        // Merging Contacts
        ContactMergeController.mergeContact(primContactId,dupContactId);
        // Recalculating Lead
        ContactMergeController.recalculatePrimaryLeads(primaryContact.Id);
        System.assertEquals(primContactId, [SELECT Active_Lead_Contact_Id__c FROM Lead WHERE Id =: dupLead.Id].Active_Lead_Contact_Id__c, 'Primary contact did not receive lead from duplicate user');
        // Evaluate Contact Point
        List<Phone__c> contactPoints = [SELECT Id from Phone__c where Contact__c =: primContactId];
        ContactMergeController.evaluateCulateContactPoints(primContactId);
        System.assertEquals(False, [SELECT Id from Phone__c where Contact__c =: primContactId AND Name = '0425345759'].isEmpty(), 'Primary contact does not contain new contact point from duplicate contact' );
        // Recalc Contact Point
        ContactMergeController.recalCulateContactPoints(primContactId, false);
        Contact postMergeContact = [SELECT LastName FROM Contact WHERE Id =: primContactId LIMIT 1];
        System.assertEquals('Test2', postMergeContact.LastName, 'Primary contact post merge did not maintain last name.');
    }

    @istest
    static void testMergeUser() {
        // Retrieve primary and duplicate user
        User primaryUser = [SELECT id FROM User WHERE FirstName = 'Controller' AND LastName ='Test' AND Alias LIKE 'prim%'];
        User dupUser = [SELECT id, Username, FederationIdentifier FROM User WHERE FirstName = 'Controller' AND LastName ='Test2' AND Alias LIKE 'dupl%'];
        // Retrieving applied permission sets during setup
        Id permissionId = [SELECT Id FROM PermissionSet WHERE Name = 'Alumni_Portal_Permission_Set' LIMIT 1].Id;
        List<Id> primaryPerm = new List<Id> {};
        List<Id> dupPerm = new List<Id> {
            permissionId
        };
        List<Id> dupPermAll = new List<Id> {}; // For try clause
        for (PermissionSetAssignment psa : [SELECT PermissionSet.Id FROM PermissionSetAssignment WHERE Assignee.Id =: dupUser.Id]) {
            dupPermAll.add(psa.PermissionSet.Id);
        }
        // Testing try clause within method - expecting to fail due to profile permissions are included
        try {
            ContactMergeController.mergeUser(primaryUser.id, dupUser.id, primaryPerm, dupPermAll);
        }
        catch (Exception e) {
            System.debug('exception caught: ' + e);
        }
        // Merge
        ContactMergeController.mergeUser(primaryUser.id, dupUser.id, primaryPerm, dupPerm);
        // Verify changes
        primaryUser = [SELECT id, Username, FederationIdentifier FROM User WHERE FirstName = 'Controller' AND LastName ='Test' AND Alias LIKE 'prim%'];
        System.assertEquals(dupUser.FederationIdentifier, primaryUser.FederationIdentifier, 'Duplicate User FederationID did not transfer to Primary User FederationID. (User id: ' + primaryUser.id + ' FedID: ' + primaryUser.FederationIdentifier + ')');
        dupUser = [SELECT id, IsActive, Username, Email, FederationIdentifier FROM User WHERE FirstName = 'Controller' AND LastName ='Test2' ];
        System.assertEquals(False, dupUser.IsActive, 'Duplicate user is not inactive post merge. (User id: ' + dupUser.id + ' Status: ' + dupUser.IsActive + ')');
        System.assertEquals(null, dupUser.FederationIdentifier, 'Duplicate user FederationIdentifier is not null post merge. (User id: ' + dupUser.id + ')');
        List<ContactMergeController.MergeUserWrapper> mwrapper = new List<ContactMergeController.MergeUserWrapper>();
        ContactMergeController.MergeUserWrapper mo = new ContactMergeController.MergeUserWrapper();
        mo.userName = dupUser.Username;
        mo.userId = dupUser.Id;
        mo.email = dupUser.Email;
        mwrapper.add(mo);
        String sJSON = JSON.serializePretty(mwrapper);
        ContactMergeController.sendMergeConfirmation(
            primaryUser.id,
            sJSON);
    }

    @isTest
    static void testelevatePermissions() {
        User nonAdUsr = [SELECT Id, UserName, FirstName, LastName,Alias, Email, ProfileId, EmailEncodingKey, CommunityNickName, TimeZoneSidKey, LocaleSidKey, LanguageLocaleKey, FederationIdentifier, MonashObjectId__c,IsActive FROM User WHERE Email = 'nonadminuser@test.com' LIMIT 1];
        System.assertNotEquals(null, nonAdUsr, 'Non Admin User was not created');
        //Begin Testing as Non Admin User
        Test.startTest();
        //Negative scenario
        System.runAs(nonAdUsr) {
            System.assertEquals(nonAdUsr.UserName, UserInfo.getUserName(), 'Run as Non admin failed');
            //
            System.assertEquals(true,
                                ContactMergeController.elevatePermissions(true),
                                'Permission Elevation Failed');
            System.assertEquals(true,
                                ContactMergeController.elevatePermissions(false),
                                'Permission Removal Failed');
        }
        Test.stopTest();
        //
    }

    /**
     * Scenario:
     * GIVEN two or more Contacts are merged
     * WHEN duplicate contact points are re-parented
     * THEN the system must eliminate the duplicate and retain the latest greatest contact point
     */
    @IsTest
    static void reCalculateContactPoint_Test() {
        // GIVEN two duplicate contacts with duplicate contact points
        // Primary contact
        Contact testPrimaryContact = new Contact(
            FirstName = 'Contact',
            LastName = 'Rehash',
            Person_ID_unique__c = '0000001',
            Email = 'Controller.Test@testonly.com',
            BirthDate = Date.valueOf('1991-12-12')
            );
        // Duplicate contact
        Contact testDuplicateContact1 = new Contact(
            FirstName = 'Contact',
            LastName = 'Rehash',
            Person_ID_unique__c = '0000002',
            Email = 'Controller.Test@testonly.com',
            BirthDate = Date.valueOf('1991-12-12')
            );
        List<Contact> testContacts = new List<Contact> {
            testPrimaryContact, testDuplicateContact1
        };
        insert testContacts;
        // Contact points - EMAIL
        List<Email__c> conEmails = new List<Email__c> {
            new Email__c(
                Contact__c = testPrimaryContact.id,
                Source__c = 'Undefined',
                Name = 'testcommonemail@testonly.com',
                Classification__c = 'Private',
                Start_Date__c = Date.today().addYears(-1)
                ),
            new Email__c(     // Duplicatate for try catch clause
                Contact__c = testDuplicateContact1.id,
                Source__c = 'Undefined',
                Name = 'testcommonemail@testonly.com',
                Classification__c = 'Private',
                Start_Date__c = Date.today()         // DUPLICATE IS THE LATEST GREATEST (TODAY)
                )
        };
        insert conEmails;
        // Contact points - PHONE
        List<Phone__c> conPhones = new List<Phone__c> {
            new Phone__c(
                Contact__c = testPrimaryContact.id,
                Name = '0411111111',
                Type__c = 'Mobile',
                Classification__c = 'Private',
                Start_Date__c = Date.today().addDays(-14)
                ),
            new Phone__c(
                Contact__c = testDuplicateContact1.id,
                Name = '0411111111',
                Type__c = 'Mobile',
                Classification__c = 'Private',
                Start_Date__c = Date.today().addDays(-7)         // DUPLICATE IS THE LATEST GREATEST
                )
        };
        insert conPhones;
        // Contact points - ADDRESS
        List<Address__c> conAddresses = new List<Address__c> {
            new Address__c(
                Contact__c = testPrimaryContact.id,
                Street_Name__c = '700 Blackburn Rd',
                City__c = 'Clayton',
                State__c = 'VIC',
                Post_Code__c = '3168',
                Country2__c = 'Australia',
                Type__c = 'Mailing',
                Classification__c = 'Private',
                Start_Date__c = Date.today().addDays(-14)         // PRIMARY IS THE LATEST GREATEST
                ),
            new Address__c(
                Contact__c = testDuplicateContact1.id,
                Street_Name__c = '700 Blackburn Rd',
                City__c = 'Clayton',
                State__c = 'VIC',
                Post_Code__c = '3168',
                Country2__c = 'Australia',
                Type__c = 'Mailing',
                Classification__c = 'Private',
                Start_Date__c = Date.today().addYears(-1)
                )
        };
        insert conAddresses;
        // WHEN THE TWO CONTACTS ARE MERGED
        Test.startTest();
        Contact primaryContact = [SELECT id, Account.id, lastName, firstName, Email FROM Contact WHERE FirstName='Contact' AND LastName='Rehash' LIMIT 1];
        List<ContactMergeData> entityDataList = ContactMergeController.getEntityData(primaryContact.firstName, primaryContact.lastName + '*', '', '', '');
        // Merging Accounts
        Id primAccountId;
        Id dupAccountId;
        Id primContactId;
        Id dupContactId;
        for (ContactMergeData cmdObj :entityDataList) {
            if (cmdObj.isPrimary) {
                primAccountId = cmdObj.accountRecord.Id;
                primContactId = cmdObj.contactRecord.Id;
            } else {
                dupAccountId = cmdObj.accountRecord.Id;
                dupContactId = cmdObj.contactRecord.Id;
            }
        }
        System.assertNotEquals(primAccountId, null, 'primAccountId is Null');
        System.assertNotEquals(dupAccountId, null, 'dupAccountId is Null');
        System.assertNotEquals(primContactId, null, 'primContactId is Null');
        System.assertNotEquals(dupContactId, null, 'dupContactId is Null');
        ContactMergeController.mergeAccount(primAccountId,dupAccountId,primaryContact.Id);
        // Merging Contacts
        ContactMergeController.mergeContact(primContactId,dupContactId);
        // Recalculating Lead
        ContactMergeController.recalculatePrimaryLeads(primaryContact.Id);
        // Evaluate Contact Point
        ContactMergeController.evaluateCulateContactPoints(primContactId);
        // Recalc Contact Point
        ContactMergeController.recalCulateContactPoints(primContactId, false);
        Test.stopTest();
        // THEN THE SYSTEM MUST ROLL UP THE LATEST GREATEST CONTACT POINTS WITH ELIMINATING THE DUPLICATES
        Contact postMergeContact = [SELECT Id, FirstName, LastName,
                                    (SELECT Id, Start_Date__c, Is_Active__c FROM Phones__r WHERE Is_Primary__c = TRUE),
                                    (SELECT Id, Start_Date__c, Is_Active__c FROM Emails__r WHERE Is_Primary__c = TRUE),
                                    (SELECT Id, Start_Date__c, Is_Active__c FROM Addresses__r WHERE Is_Primary__c = TRUE)
                                    FROM Contact WHERE Id =: primContactId LIMIT 1];
        System.assertEquals(postMergeContact.Emails__r[0].Start_Date__c, Date.today());
        System.assertEquals(postMergeContact.Phones__r[0].Start_Date__c, Date.today().addDays(-7));
        System.assertEquals(postMergeContact.Addresses__r[0].Start_Date__c, Date.today().addDays(-14));
    }

    /**
     * Scenario:
     * GIVEN two or more Contacts are merged
     * WHEN duplicate contact points are re-parented
     * AND CPA merge are enabled in the Feature Switch setting
     * THEN the system must eliminate the duplicate and retain the latest greatest contact point
     * TODO : this test class requires an upgrade in the subsequent releases, the current code coverage is only around 77%
     */
    @IsTest
    static void shouldIncludeCPAsOnMerge() {
        // GIVEN two duplicate contacts with duplicate contact points
        // Primary contact
        Contact testPrimaryContact = new Contact(
            FirstName = 'Contact',
            LastName = 'Rehash',
            Person_ID_unique__c = '0000001',
            Email = 'Controller.Test@testonly.com',
            BirthDate = Date.valueOf('1991-12-12')
            );
        // Duplicate contact
        Contact testDuplicateContact1 = new Contact(
            FirstName = 'Contact',
            LastName = 'Rehash',
            Person_ID_unique__c = '0000002',
            Email = 'Controller.Test@testonly.com',
            BirthDate = Date.valueOf('1991-12-12')
            );
        List<Contact> testContacts = new List<Contact> {
            testPrimaryContact, testDuplicateContact1
        };
        insert testContacts;
        // Contact points - EMAIL
        List<Email__c> conEmails = new List<Email__c> {
            new Email__c(
                Contact__c = testPrimaryContact.id,
                Source__c = 'Undefined',
                Name = 'testcommonemail@testonly.com',
                Classification__c = 'Private',
                Start_Date__c = Date.today().addYears(-1)
                ),
            new Email__c(     // Duplicatate for try catch clause
                Contact__c = testDuplicateContact1.id,
                Source__c = 'Undefined',
                Name = 'testcommonemail@testonly.com',
                Classification__c = 'Private',
                Start_Date__c = Date.today()         // DUPLICATE IS THE LATEST GREATEST (TODAY)
                )
        };
        insert conEmails;
        // Contact points - PHONE
        List<Phone__c> conPhones = new List<Phone__c> {
            new Phone__c(
                Contact__c = testPrimaryContact.id,
                Name = '0411111111',
                Type__c = 'Mobile',
                Classification__c = 'Private',
                Start_Date__c = Date.today().addDays(-14)
                ),
            new Phone__c(
                Contact__c = testDuplicateContact1.id,
                Name = '0411111111',
                Type__c = 'Mobile',
                Classification__c = 'Private',
                Start_Date__c = Date.today().addDays(-7)         // DUPLICATE IS THE LATEST GREATEST
                )
        };
        insert conPhones;
        // Contact points - ADDRESS
        List<Address__c> conAddresses = new List<Address__c> {
            new Address__c(
                Contact__c = testPrimaryContact.id,
                Street_Name__c = '700 Blackburn Rd',
                City__c = 'Clayton',
                State__c = 'VIC',
                Post_Code__c = '3168',
                Country2__c = 'Australia',
                Type__c = 'Mailing',
                Classification__c = 'Private',
                Start_Date__c = Date.today().addDays(-14)         // PRIMARY IS THE LATEST GREATEST
                ),
            new Address__c(
                Contact__c = testDuplicateContact1.id,
                Street_Name__c = '700 Blackburn Rd',
                City__c = 'Clayton',
                State__c = 'VIC',
                Post_Code__c = '3168',
                Country2__c = 'Australia',
                Type__c = 'Mailing',
                Classification__c = 'Private',
                Start_Date__c = Date.today().addYears(-1)
                )
        };
        insert conAddresses;

        // enable CPA merge
        Feature_Switch__c fs = new  Feature_Switch__c();
        fs.Enable_CPA_for_Contact_Merge__c = true;
        insert fs;

        // WHEN THE TWO CONTACTS ARE MERGED
        Test.startTest();
        Contact primaryContact = [SELECT id, Account.id, lastName, firstName, Email FROM Contact WHERE FirstName='Contact' AND LastName='Rehash' LIMIT 1];
        List<ContactMergeData> entityDataList = ContactMergeController.getEntityData(primaryContact.firstName, primaryContact.lastName + '*', '', '', '');
        // Merging Accounts
        Id primAccountId;
        Id dupAccountId;
        Id primContactId;
        Id dupContactId;
        for (ContactMergeData cmdObj :entityDataList) {
            if (cmdObj.isPrimary) {
                primAccountId = cmdObj.accountRecord.Id;
                primContactId = cmdObj.contactRecord.Id;
            } else {
                dupAccountId = cmdObj.accountRecord.Id;
                dupContactId = cmdObj.contactRecord.Id;
            }
        }
        System.assertNotEquals(primAccountId, null, 'primAccountId is Null');
        System.assertNotEquals(dupAccountId, null, 'dupAccountId is Null');
        System.assertNotEquals(primContactId, null, 'primContactId is Null');
        System.assertNotEquals(dupContactId, null, 'dupContactId is Null');
        ContactMergeController.mergeAccount(primAccountId,dupAccountId,primaryContact.Id);
        // Merging Contacts
        ContactMergeController.mergeContact(primContactId,dupContactId);
        // Recalculating Lead
        ContactMergeController.recalculatePrimaryLeads(primaryContact.Id);
        // Evaluate Contact Point
        ContactMergeController.evaluateCulateContactPoints(primContactId);

        Test.stopTest();
        // THEN THE SYSTEM MUST ROLL UP THE LATEST GREATEST CONTACT POINTS WITH ELIMINATING THE DUPLICATES
        Contact postMergeContact = [SELECT Id, FirstName, LastName,
                                    (SELECT Id, Start_Date__c, Is_Active__c FROM Phones__r WHERE Is_Primary__c = TRUE),
                                    (SELECT Id, Start_Date__c, Is_Active__c FROM Emails__r WHERE Is_Primary__c = TRUE),
                                    (SELECT Id, Start_Date__c, Is_Active__c FROM Addresses__r WHERE Is_Primary__c = TRUE)
                                    FROM Contact WHERE Id =: primContactId LIMIT 1];
        System.assertEquals(postMergeContact.Emails__r[0].Start_Date__c, Date.today());
        System.assertEquals(postMergeContact.Phones__r[0].Start_Date__c, Date.today().addDays(-7));
        System.assertEquals(postMergeContact.Addresses__r[0].Start_Date__c, Date.today().addDays(-14));
    }

    /**
     * Scenario:
     * GIVEN two or more Contacts are potential duplicates
     * WHEN the contact merge tool search for potential matches
     * THEN the system must consider the contact point existence if it matches the search parameter
     */
    @IsTest
    static void getMatchingContactPoints_Test() {
        // GIVEN two duplicate contacts with duplicate contact points
        // Primary contact
        Contact testPrimaryContact = new Contact(
            FirstName = 'Jane',
            LastName = 'Doe',
            Person_ID_unique__c = '0000001',
            Email = 'jane.doe.test@testonly.com',
            BirthDate = Date.valueOf('1991-12-12')
            );
        // Duplicate contact
        Contact testDuplicateContact1 = new Contact(
            FirstName = 'Jane',
            LastName = 'Doe',
            Email = 'jane.doe.test@testonly.com',
            BirthDate = Date.valueOf('1991-12-12')
            );
        // Duplicate contact
        Contact testDuplicateContact2 = new Contact(
            FirstName = 'Jane',
            LastName = 'Doe',
            Email = 'jane.doe.test@testonly.com',
            BirthDate = Date.valueOf('1991-12-12')
            );
        List<Contact> testContacts = new List<Contact> {
            testPrimaryContact, testDuplicateContact1, testDuplicateContact2
        };
        insert testContacts;
        // WHEN the initially duplicate contact gets updated (system will create a new contact point)
        testDuplicateContact1.LastName = 'Doe - Johnson';
        testDuplicateContact1.Email = 'jane.johnson.test@testonly.com';
        update testDuplicateContact1;
        Name__c testPrimaryName = new Name__c(First_Name__c = 'Jane', Last_Name__c = 'Doe', Contact__c = testPrimaryContact.Id, Start_Date__c = Date.today().addYears(-10), End_Date__c = null, Type__c = 'Common', Source__c = 'Undefined');
        Name__c testDuplicateName = new Name__c(First_Name__c = 'Jane', Last_Name__c = 'Doe', Contact__c = testDuplicateContact1.Id, Start_Date__c = Date.today().addYears(-10), End_Date__c = null, Type__c = 'Common', Source__c = 'Undefined');
        Name__c testDuplicateName1 = new Name__c(First_Name__c = 'Jane', Last_Name__c = 'Doe', Contact__c = testDuplicateContact2.Id, Start_Date__c = Date.today().addYears(-10), End_Date__c = null, Type__c = 'Common', Source__c = 'Undefined');
        Name__c testDuplicateName2 = new Name__c(First_Name__c = 'Jane', Last_Name__c = 'Doe - Johnson', Contact__c = testDuplicateContact2.Id, Start_Date__c = Date.today(), End_Date__c = null, Type__c = 'Common', Source__c = 'Undefined');
        insert new List<Name__c> {
            testPrimaryName, testDuplicateName, testDuplicateName1, testDuplicateName2
        };
        Email__c testPrimaryEmail = new Email__c(Name = 'jane.doe.test@testonly.com', Contact__c = testPrimaryContact.Id, Classification__c = 'Private', Source__c = 'Undefined', Start_Date__c = Date.today().addYears(-2), End_Date__c = null);
        Email__c testDuplicateEmail = new Email__c(Name = 'jane.doe.test@testonly.com',Contact__c = testDuplicateContact1.Id, Classification__c = 'Private', Source__c = 'Undefined', Start_Date__c = Date.today().addYears(-2), End_Date__c = null);
        Email__c testDuplicateEmail1 = new Email__c(Name = 'jane.doe.test@testonly.com',Contact__c = testDuplicateContact2.Id, Classification__c = 'Private', Source__c = 'Undefined', Start_Date__c = Date.today().addYears(-2), End_Date__c = null);
        Email__c testDuplicateEmail2 = new Email__c(Name = 'jane.johnson.test@testonly.com',Contact__c = testDuplicateContact2.Id, Classification__c = 'Private', Source__c = 'Undefined', Start_Date__c = Date.today(), End_Date__c = null);
        insert new List<Email__c> {
            testPrimaryEmail, testDuplicateEmail, testDuplicateEmail1, testDuplicateEmail2
        };
        // WHEN THE CONTACT MERGE TOOL SEARCHES FOR POTENTIAL MATCH
        Test.startTest();
        List<ContactMergeData> entityDataList = ContactMergeController.getEntityData('Jane', 'Doe', '', '', '');
        Test.stopTest();
        // THEN THE SYSTEM MUST RETRIEVE THE NEWLY UPDATED DUPLICATE AS IT HAS A HISTORICAL CONTACT POINT THAT MATCHES THE SEARCH
        System.assertEquals(3, entityDataList.size());
        System.assertEquals(true, entityDataList[0].isPrimary); // the first record in the list is the surviving contact
        System.assertEquals(false, entityDataList[2].isPrimary); // the third record (duplicate) is the duplicate
        System.assertEquals(false, entityDataList[2].isIncluded); // the third record is not auto-included in the merge
        System.assertEquals('Contact_Point_Match', entityDataList[2].dupFieldInfo.dupRuleName); // the third record is a potential match through contact point
    }

    /**
     * Scenario:
     * GIVEN two or more Contacts are potential duplicates
     * WHEN the contact merge tool search for potential matches
     * THEN the system must by pass the Person360 RollDown
     * SO no new records should be created whenever new contact point values are mapped from victim contact to surviving contact if the surviving contact point field is blank
     */
    @IsTest
    static void bypassRollDown_Test() {
        // GIVEN two duplicate contacts with duplicate contact points
        // Primary contact
        Contact testPrimaryContact = new Contact(
            FirstName = 'Jane',
            LastName = 'Doe',
            Person_ID_unique__c = '0000001',
            BirthDate = Date.valueOf('1991-12-12')
            );
        // Duplicate contact
        Contact testDuplicateContact1 = new Contact(
            FirstName = 'Jane',
            LastName = 'Doe',
            BirthDate = Date.valueOf('1991-12-12')
            );
        List<Contact> testContacts = new List<Contact> {
            testPrimaryContact, testDuplicateContact1
        };
        insert testContacts;
        Phone__c testPrimaryPhone = new Phone__c(Name = '0423470137', Contact__c = testPrimaryContact.Id, Classification__c = 'Private', Type__c = 'Mobile', Source__c = 'Undefined', Start_Date__c = Date.today().addYears(-1), End_Date__c = null, Is_Primary__c = TRUE);
        Phone__c testDuplicatePhone = new Phone__c(Name = '0223470138',Contact__c = testDuplicateContact1.Id, Classification__c = 'Private', Type__c = 'Landline', Source__c = 'Undefined', Start_Date__c = Date.today().addYears(-2), End_Date__c = null, Is_Primary__c = TRUE);
        insert new List<Phone__c> {
            testPrimaryPhone, testDuplicatePhone
        };
        // WHEN THE CONTACT MERGE TOOL MERGE THE CONTACTS, RE-EVALUATE AND RE-CALCULATE PRIMARY CONTACT POINTS
        Test.startTest();
        String primaryContactId = ContactMergeController.mergeContact(testPrimaryContact.Id, testDuplicateContact1.Id);
        String reEvaluatedContactId = ContactMergeController.evaluateCulateContactPoints(testPrimaryContact.Id);
        String reCalculatedContactId = ContactMergeController.recalCulateContactPoints(testPrimaryContact.Id, false);
        Test.stopTest();
        // THEN THE SYSTEM MUST MUST NOT CREATE NEW CONTACT POINT
        Contact primaryContactAfterMerge = [SELECT Id, Phone, MobilePhone, HomePhone, (SELECT Id, Name, Is_Primary__c, Start_Date__c FROM Phones__r WHERE Is_Primary__c = TRUE) FROM Contact WHERE Id =: testPrimaryContact.Id];
        System.assertEquals(1, primaryContactAfterMerge.Phones__r.size()); // there should only be 1 primary email
        System.assertEquals(testPrimaryPhone.Name, primaryContactAfterMerge.Phones__r[0].Name);  // primary phone should be rolled up
        System.assertNotEquals(Date.Today(), primaryContactAfterMerge.Phones__r[0].Start_Date__c);  // primary phone should not start TODAY
        System.assertNotEquals(primaryContactAfterMerge.Phone, testPrimaryPhone.Name);  // primary phone should not the mobile phone
        System.assertNotEquals(primaryContactAfterMerge.MobilePhone, testPrimaryPhone.Name);  // mobile phone should be the mobile private phone
        System.assertNotEquals(primaryContactAfterMerge.HomePhone, testDuplicatePhone.Name);  // home phone phone should be the landline private phone
    }

    @IsTest
    static void testUpdateUserMergeStatusUsingContactId() {
        // Given
        Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'Controller' AND LastName = 'Test' LIMIT 1];
        List<User> l_usersToUpdate = [SELECT Id, Duplicate_Merge_Status__c FROM User WHERE ContactId = :testContact.Id];
        Set<Id> s_userIds = (new Map<Id,User>(l_usersToUpdate)).keySet();
        for (User userToUpdate : l_usersToUpdate) {
            userToUpdate.Duplicate_Merge_Status__c = ContactMergeController.MERGE_STATUS_INPROGRESS;
        }
        update l_usersToUpdate;
        // When
        ContactMergeController.updateUserMergeStatus(testContact.Id);
        // Then
        l_usersToUpdate = [SELECT Id, Duplicate_Merge_Status__c FROM User WHERE Id IN :s_userIds];
        System.assertEquals(1, l_usersToUpdate.size(), 'Incorrect number of user records');
        for (User updatedUser : l_usersToUpdate) {
            System.assertEquals(ContactMergeController.MERGE_STATUS_COMPLETED, updatedUser.Duplicate_Merge_Status__c, 'Incorrect status set on the the user record');
        }
    }

    @IsTest
    static void testUpdateUserMergeStatusUsingUserId() {
        // Given
        Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'Controller' AND LastName = 'Test' LIMIT 1];
        List<User> l_usersToUpdate = [SELECT Id, Duplicate_Merge_Status__c FROM User WHERE ContactId = :testContact.Id];
        Set<Id> s_userIds = (new Map<Id,User>(l_usersToUpdate)).keySet();
        for (User userToUpdate : l_usersToUpdate) {
            userToUpdate.Duplicate_Merge_Status__c = ContactMergeController.MERGE_STATUS_INPROGRESS;
        }
        update l_usersToUpdate;
        // When
        ContactMergeController.updateUserMergeStatus(l_usersToUpdate.get(0).Id);
        // Then
        l_usersToUpdate = [SELECT Id, Duplicate_Merge_Status__c FROM User WHERE Id IN :s_userIds];
        System.assertEquals(1, l_usersToUpdate.size(), 'Incorrect number of user records');
        for (User updatedUser : l_usersToUpdate) {
            System.assertEquals(ContactMergeController.MERGE_STATUS_COMPLETED, updatedUser.Duplicate_Merge_Status__c, 'Incorrect status set on the the user record');
        }
    }

    @IsTest
    static void testUpdateUserMergeStatusNoRecordsUpdated() {
        // Given
        Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'Controller' AND LastName = 'Test' LIMIT 1];
        List<User> l_usersToUpdate = [SELECT Id, Duplicate_Merge_Status__c FROM User WHERE ContactId = :testContact.Id];
        Set<Id> s_userIds = (new Map<Id,User>(l_usersToUpdate)).keySet();
        // When
        ContactMergeController.updateUserMergeStatus(testContact.Id);
        // Then
        l_usersToUpdate = [SELECT Id, Duplicate_Merge_Status__c FROM User WHERE Id IN :s_userIds];
        System.assertEquals(1, l_usersToUpdate.size(), 'Incorrect number of user records');
        for (User updatedUser : l_usersToUpdate) {
            System.assertNotEquals(ContactMergeController.MERGE_STATUS_COMPLETED, updatedUser.Duplicate_Merge_Status__c, 'Incorrect status set on the the user record');
        }
    }

    @isTest
    static void testhasValidationBypass() {
        // Given
        Id userId = UserInfo.getUserId();
        List<PermissionSetAssignment> psaAssigned = [SELECT Id FROM PermissionSetAssignment WHERE
                                                     AssigneeId =:userId AND
                                                                  PermissionSet.Name = 'Contact_Merge_Bypass_Check'];
        if (!psaAssigned.isEmpty()) {
            delete psaAssigned;
        }
        // When
        Boolean hasAccess = ContactMergeController.hasValidationBypass();
        // Then
        Assert.areEqual(false, hasAccess, 'Validation Bypass Failed...');
    }

    @isTest
    static void testgetContactData() {
        // Given
        List<Id> contactIds = new List<Id>();

        //Retrieve existing contact ids
        for(Contact loopContact : [SELECT Id FROM Contact LIMIT 2]){
            contactIds.add(loopContact.Id);
        }

        // When
	 	Test.startTest();
            List<Contact> testContactList = new List<Contact>();
            testContactList = ContactMergeController.getContactData(contactIds);
	 	Test.stopTest();

        // Then
        Assert.areEqual(2, testContactList.size(), 'Expected 2 Contact records');
        
    }
}