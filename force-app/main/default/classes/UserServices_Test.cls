/**
 * @author          Carl Vescovi, PwC
 * @group           Test Class
 * @description     Services class to provide User sObject centric logical support
 * @revision        
 *  2017-04-02 - Ant Custodio - Added trigger handler logic to map user details to contact (for community users) <br/>
 *  2019-02-15 - Stefan Scheit - Added trigger handler logic to assign detault permission sets to community users <br/>
 *  2019-10-30 - KEvasco (GrowthOps) - Added auto permission set assignment for Einstein Discovery Writeback <br/>
 *  2019-12-20 - APRivera - Increase Coverage <br/>
 *  2021-04-05 - Vinothraja - Added trigger handler logic to sync Partner User profile updates to Associated Contact
 *  2021-10-10 - Peter Sewell - Added auto permission set assignment for MFA enforcement [EPCP-1667]
 *  2021-11-01 - Peter Sewell - Added test for insert/update of records to UserShadow when auditable changes are made to User
 *  2023-04-24 - Peter Sewell - Added test that MFA_Mobile_Verified_External__c is cleared when MobilePhone is updated
 */
@isTest(isParallel=false) // disabling due to APEX_DATA_ACCESS_RESTRICTION: In parallel Apex tests, DML operations aren't permitted on this type of object: User: [] 
private class UserServices_Test {

    // Dummy numbers from https://fakenumber.org/australia/mobile
    Static final string DUMMY_MOBILE_VERIFIED = '+61 491570156';
    Static final string DUMMY_MOBILE_UNVERIFIED = '+61 491570157';
    Static final string TEST_USER_EMAIL = 't_userservices@monash.edu.test';

    /*******************************************************************************
    * @author      Peter Sewell
    * @date        24.Apr.2023
    * @description  Test setup
    *******************************************************************************/
    @TestSetup
    static void setupData(){
       
        // Create a user with a verified mobile phone
        createTestUserWithVerfiedMobile(DUMMY_MOBILE_VERIFIED);
    }

    static testMethod void testUserInfoClearout() {
        Test.startTest();
        Contact contactRecord = new Contact();
        contactRecord.FirstName='Test';
        contactRecord.LastName = 'Test 2';
        contactRecord.Email = 'Test@testmail.com';
        //contactRecord.Birthdate = '09.12.2016';
        //contactRecord.Salutation = contactUserMap.get(contactRec.Id).App_Salutation__c;
        contactRecord.Gender__c = 'M';
        contactRecord.MobilePhone = '1234567890';
        contactRecord.Phone = '1234567890';
        contactRecord.Citizenship__c = 'DOMESTIC';
        contactRecord.Previous_Surname__c = 'Testing';
        contactRecord.Previous_Monash_ID__c = '998929282928';
        contactRecord.Previous_Monash_Institution__c = 'Monash University';
        contactRecord.Country_of_Residence__c = 'Australia';
        contactRecord.Previously_Studied_at_Monash__c = TRUE;
        contactRecord.Residency_Status__c = 'DOM-NZ';
        contactRecord.HomePhone = '1234567890';
        //contactRecord.HasDisabilities__c = contactUserMap.get(contactRec.Id).App_HasDisabilities__c;
        contactRecord.Aboriginal_or_Torres_Strait_Islander__c = 'No';
        contactRecord.MailingStreet = 'Test';
        contactRecord.MailingCity = 'Test';
        contactRecord.MailingState = 'NSW';
        contactRecord.MailingPostalCode = '12345';
        contactRecord.MailingCountry = 'Test';
        contactRecord.Other_Given_Name__c = 'Test';
        List<Contact> ContactList=new List<Contact>();
        ContactList.add(contactRecord);
        insert contactRecord;

        // User
        String profileName = 'Customer Community General User';
        Id profileId = [select id from Profile where name =:profileName limit 1].Id;
        Assert.isNotNull(profileId,'No user profile found for user setup');
        List<User> users = new List<User>();
        Integer rnd = Integer.valueOf(Math.random()*9999);
        users.add(new User(Alias = String.valueOf(rnd)+ 'usr',
                Email= String.valueOf(rnd) +'testuser@mutesting.edu',
                EmailEncodingKey='UTF-8',
                LastName='TestingUser',
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_GB',
                ContactId = contactRecord.Id,
                ProfileId = profileId,
                TimeZoneSidKey='Australia/Sydney',
                UserName= String.valueOf(rnd) +'testuser@mutesting.edu'));
        insert users;
        User usr = StudFirst_TestHelper.createCommunityUser();
        usr.Queue__c = 'test';
        usr.Location__c = 'test';
        usr.Enquiry_Role__c = 'test';
        System.runAs(usr) {
            usr = UserServices.contextUser;
            UserServices.updateUsers(users);
        }
        Test.stopTest();
    }

    /**
     * Test method to validate community permission sets are automatically assigned
     */
    @isTest
    static void testAssignPermissionSets() {
        String random = String.valueOf(System.currentTimeMillis());
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        //Create community user's account owner
        UserRole internalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
        Profile internalProfile = [SELECT Id FROM Profile WHERE name = 'System Administrator'];
        User accountOwner = new User(
                UserRoleId = internalRole.Id,
                ProfileId = internalProfile.Id,
                Username = random + 'testing@monash.edu',
                Alias = 'test_ao',
                Email='test_ao@monash.edu',
                EmailEncodingKey='UTF-8',
                Firstname='Firstname' + random,
                Lastname='Lastname' + random,
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                TimeZoneSidKey='Australia/Sydney'
        );
        System.runAs(thisUser) {
            Database.insert(accountOwner);
        }

        // Create account record
        Account act = new Account(
                Name='TestAccount' + random,
                OwnerId = accountOwner.id
        );
        Database.insert(act);

        // Create contact
        Contact communityContact = new Contact();
        communityContact.FirstName = 'Firstname' + random;
        communityContact.Lastname = 'Lastname' + random;
        communityContact.Email = 'test_cc@monash.edu';
        communityContact.Person_Id_unique__c = '87654321'; // is a student
        communityContact.SAP_Staff_Id__c = '87654321'; // is a staff
        communityContact.AccountId = act.Id;
        Database.insert(communityContact);

        Test.startTest(); // insert community user, should assign permsets as well

        //Create Community User
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = :UserServices.CUSTOMER_COMMUNITY_PROFILE_COMMON LIMIT 1];
        User communityUser = new User(
                UserName = random + communityContact.Email,
                FirstName = communityContact.FirstName,
                LastName = communityContact.LastName,
                Alias = 'test_cu',
                CommunityNickname = 'test_cu' + random,
                email = communityContact.Email,
                ContactId = communityContact.Id,
                ProfileId = communityProfile.Id,
                //Community_Access__c = 'ask.monash',
                EmailEncodingKey = 'UTF-8',
                TimeZoneSidKey = 'Australia/Sydney',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
        );
        System.runAs(thisUser) {
            Database.insert(communityUser);
            communityUser.Community_Access__c = 'ask.monash'; // mimicks a community login (via JitHandler)
            Database.update(communityUser);
        }
        Test.stopTest();
        List<PermissionSetAssignment> permSetsAssign = [SELECT PermissionSetId, PermissionSet.Name, AssigneeId, Assignee.Username FROM PermissionSetAssignment WHERE AssigneeId = :communityUser.Id];
        Assert.isTrue(permSetsAssign.size()>0, 'No permission sets assigned to community user');
    }

    @isTest
    static void testReassignPermissionSets() {
        String random = String.valueOf(System.currentTimeMillis());
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        //Create community user's account owner
        UserRole internalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
        Profile internalProfile = [SELECT Id FROM Profile WHERE name = 'System Administrator'];
        User userRecord = new User(
                UserRoleId = internalRole.Id,
                ProfileId = internalProfile.Id,
                Username = random + 'testing@monash.edu',
                Alias = 'test_ao',
                Email='test_ao@monash.edu',
                EmailEncodingKey='UTF-8',
                Firstname='Firstname' + random,
                Lastname='Lastname' + random,
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                TimeZoneSidKey='Australia/Sydney'
        );
        System.runAs(thisUser) {
            Database.insert(userRecord);

            userRecord.IsActive = false;
            Database.update(userRecord);

            userRecord.IsActive = true;
            Database.update(userRecord);
        }

        List<PermissionSetAssignment> permSetsAssign = [SELECT PermissionSetId, PermissionSet.Name, AssigneeId, Assignee.Username FROM PermissionSetAssignment WHERE AssigneeId = :userRecord.Id];
        Assert.isTrue(permSetsAssign.size()>0, 'No permission sets assigned to community user');
    }


    // test the following methods:
    // userOrGroupName; userRoleName
    @isTest
    static void testOtherBehavior(){
        Test.startTest();
        Map<Id, String> userOrGroupName = UserServices.userOrGroupName;
        System.assertNotEquals(null, userOrGroupName);

        Map<Id, String> userRoleName = UserServices.userRoleName;
        System.assertNotEquals(null, userRoleName);

        Test.stopTest();
    }

    // test the following methods:
    // addPermSetToPortalUsers, addPackageLicenseToPortalUsers; 
    // getPermiSetsToAdd, getPackageLicenseToAdd;
    // getExistingUserPackageLicense, getExistingPermSetAssigment;
    @isTest
    static void testMethodsRequiredDuringOfferAcceptance(){      
        Contact contactRecord = new Contact();
        contactRecord.FirstName='Test';
        contactRecord.LastName = 'Test 2';
        contactRecord.Email = 'Test@testmail.com';
        //contactRecord.Birthdate = '09.12.2016';
        //contactRecord.Salutation = contactUserMap.get(contactRec.Id).App_Salutation__c;
        contactRecord.Gender__c = 'M';
        contactRecord.MobilePhone = '1234567890';
        contactRecord.Phone = '1234567890';
        contactRecord.Citizenship__c = 'DOMESTIC';
        contactRecord.Previous_Surname__c = 'Testing';
        contactRecord.Previous_Monash_ID__c = '998929282928';
        contactRecord.Previous_Monash_Institution__c = 'Monash University';
        contactRecord.Country_of_Residence__c = 'Australia';
        contactRecord.Previously_Studied_at_Monash__c = TRUE;
        contactRecord.Residency_Status__c = 'DOM-NZ';
        contactRecord.HomePhone = '1234567890';
        //contactRecord.HasDisabilities__c = contactUserMap.get(contactRec.Id).App_HasDisabilities__c;
        contactRecord.Aboriginal_or_Torres_Strait_Islander__c = 'No';
        contactRecord.MailingStreet = 'Test';
        contactRecord.MailingCity = 'Test';
        contactRecord.MailingState = 'NSW';
        contactRecord.MailingPostalCode = '12345';
        contactRecord.MailingCountry = 'Test';
        contactRecord.Other_Given_Name__c = 'Test';
        List<Contact> ContactList=new List<Contact>();
        ContactList.add(contactRecord);
        insert contactRecord;

        // User
        String profileName = 'Customer Community General User';
        Id profileId = [select id from Profile where name =:profileName limit 1].Id;
        Assert.isNotNull(profileId,'No user profile found for user setup');
        List<User> userList = new List<User>();
        Integer rnd = Integer.valueOf(Math.random()*9999);
        userList.add(new User(Alias = String.valueOf(rnd)+ 'usr',
                Email= String.valueOf(rnd) +'testuser@mutesting.edu',
                EmailEncodingKey='UTF-8',
                LastName='TestingUser',
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_GB',
                ContactId = contactRecord.Id,
                ProfileId = profileId,
                TimeZoneSidKey='Australia/Sydney',
                UserName= String.valueOf(rnd) +'testuser@mutesting.edu'));
        insert userList;

        Test.startTest();

        List<PackageLicense> packageLicensesToAdd = UserServices.getPackageLicenseToAdd('packlicense');
        List<PermissionSet> permSetsToAdd = UserServices.getPermiSetsToAdd('SteelBrickCPQCustomerUser');
        Boolean isQueueable = false;
            
        UserServices.addPermSetToPortalUsers(userList,permSetsToAdd, isQueueable);
        UserServices.addPackageLicenseToPortalUsers(userList, packageLicensesToAdd, isQueueable);
        Test.stopTest();
    }

    /**
     * @author      Kristian Vegerano
     * @description Tests CreateAssociatedPartnerContact method
     *              Test creates partner portal user with empty contact id
     *              Validates that the partner user with no contact id automatically have its contact id populated after insert
     * @revision    27/02/2021 - Kristian Vegerano - Created
     */
    @isTest 
    static void test_CreateAssociatedPartnerContact() {
        Map<String, Object> resultsMap = new Map<String, Object>();
        Id partnerProfileId = [SELECT Id FROM Profile WHERE Name = :Constants.PARTNER_USER_PROFILE LIMIT 1].Id;
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();

        Account testAccount = new Account(Name = 'TestAccount', RecordTypeId = partnerRecordTypeId, OwnerId = UserInfo.getUserId());
        insert testAccount;
        Contact testContact = new Contact(FirstName = 'TestFirstName', LastName = 'TestLastName', AccountId = testAccount.Id, Email = 'TestEmail@testemail.com', OwnerId = UserInfo.getUserId());
        insert testContact;
        ExperienceAuthenticationServices.generatePartnerUser('{"ContactId":"' + testContact.Id + '","FirstName":"TestFirstName","MiddleName":"TestMiddleName","LastName":"TestLastName","Suffix":"TestSuffix","Email":"testemail@testemail.com","Username":"' + String.valueOf(Math.random()) + 'testemail@testemail.com","Nickname":"TestNickname","DelegatedAdmin":' + true + '}');
        User partnerUser = [SELECT Id, ProfileId FROM User WHERE Profile.Name = :Constants.PARTNER_USER_PROFILE AND IsActive = true LIMIT 1];
                
        //Create user
        String random = String.valueOf(System.currentTimeMillis());
        User communityUser = new User(
            UserName = random + 'testusername@testemail.com',
            FirstName = 'TestFirstName',
            LastName = 'TestLast',
            Alias = 'test_cu',
            CommunityNickname = 'test_cu' + random,
            email = random + 'testusername@testemail.com',
            ProfileId = partnerProfileId,
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'Australia/Sydney',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US'
        );

        Test.startTest();
            Database.insert(communityUser);
        Test.stopTest();      
        
        //Start assertion - check that the user has a contact record associated to it
        Assert.isNotNull([SELECT Id, ContactId FROM User WHERE Id =: communityUser.Id].ContactId);
    }
    /**
     * @author      SMendu
     * @date        29.Sep.2021
     * @description Tests Prevention of deactivation of Primary Account Holder user 
     */
    @isTest
    static void test_ValidateUserDeactivatePrevention() {
        User partnerUser = StudFirst_TestHelper.createContactAndPartnerPortalUser();
        Account acc = [select name from Account where name='TestAccount'][0]; 
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
           AccountTeamMember atm = new AccountTeamMember(UserId = partnerUser.Id,AccountId = acc.Id, TeamMemberRole = 'Primary Account Holder');
           insert atm;
        }
        Test.startTest();
        System.runAs(thisUser) {
            try{
                partnerUser.IsActive = false;
                update partnerUser;
            }
            catch(Exception e){
                Assert.isTrue(e.getMessage().contains(System.Label.StopPrimaryUserDeactivation));
            }
        }
        Test.stopTest();
    }
       
    /**
    * @author      Vinothraja
    * @description Tests SyncPartnerUser method
    *              Test updates Partner User
    *              Validates whether the Associated Contact is updated, when User details are updated
    * @revision    13/10/2021 - Vinothraja - Created
    */
    @isTest
    public static void test_SyncPartnerUser() {
        User partnerUser = StudFirst_TestHelper.createContactAndPartnerPortalUser();
        Contact testContact = [SELECT id, LastName FROM Contact WHERE id =:partnerUser.contactId LIMIT 1];
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runas(thisUser) {
            Test.startTest();
            partnerUser.LastName = 'TestLastComm';
            Database.update(partnerUser);
            Test.stopTest();
        }
        //Start assertion - check that the partner portal user is updated
        Assert.areEqual('TestLastComm', [SELECT Id, LastName FROM Contact WHERE id =: testContact.Id LIMIT 1].LastName);
    }
    /**
     * Test method to validate MFA enforcement would be bypassed for users with specific properties [EPCP-1667]
     * i.e. User.Monash_User_Type__c = 'eSol Test User'
     */
    @isTest
    static void testMfaEnforcementBypass() {
                
        Test.startTest(); 

        // Fudge sandbox name to a sandbox in-scope for MFA so test runs even in Prod
        Sandbox_Details__c setting = Sandbox_Details__c.getOrgDefaults();
        setting.sandboxName__c = SecurityServices.SIT_SANDBOX_NAME;

        // Insert user with attributes to bypass MFA enforcement 
        // i.e. Monash_User_Type__c = 'eSol Test User'
        String random = String.valueOf(System.currentTimeMillis());
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        UserRole internalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
        Profile internalProfile = [SELECT Id FROM Profile WHERE name = 'System Administrator'];
        User userRecord = new User(
                UserRoleId = internalRole.Id,
                ProfileId = internalProfile.Id,
                Username = random + '.nomfa@monash.edu',
                Alias = 't_nomfa',
                Email='t_nomfa@monash.edu',
                EmailEncodingKey='UTF-8',
                Firstname='Firstname' + random,
                Lastname='Lastname' + random,
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                TimeZoneSidKey='Australia/Sydney',
                IsActive=true,
                Monash_User_Type__c = 'eSol Test User' // Should exclude user from MFA
        );
        System.runAs(thisUser) {
            Database.upsert(setting);
            Database.insert(userRecord);
        }

        Test.stopTest();

        // Get Id of MFA enforcement perm set 
        List<PermissionSet> permSets = new List<PermissionSet>();
        permSets = [SELECT Id FROM PermissionSet WHERE Name = :SecurityServices.MFA_ENFORCEMENT_PERM_SET LIMIT 1];
        Assert.areEqual(permSets.size(),1, 'MFA enforcement perm set not found in Org') ;
        Id mfaPermSetId = permSets[0].Id;

        // Get MFA enforcement perm set assigned to test user (should not find anything!)
        List<PermissionSetAssignment> permSetsAssign = new List<PermissionSetAssignment>();
        permSetsAssign = [SELECT PermissionSetId, PermissionSet.Name, AssigneeId, Assignee.Username FROM PermissionSetAssignment WHERE AssigneeId = :userRecord.Id AND PermissionSetId = :mfaPermSetId];
        Assert.areEqual(permSetsAssign.size(),0, 'User with Monash_User_Type__c = "eSol Test User" should not be assigned MFA permission set') ;
    }

    /**
     * Test method to validate MFA enforcement perm set assigned to user in in-scope Sandbox [EPCP-1667]
     */
    @isTest
    static void testMfaEnforcementPermSetAssignment() {

        // MFA is not enforced in Prod, so we'll need to check for this
        Boolean runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
                
        Test.startTest(); 

        // Fudge sandbox name to a sandbox in-scope for MFA so test runs
        Sandbox_Details__c setting = Sandbox_Details__c.getOrgDefaults();
        setting.sandboxName__c = SecurityServices.SIT_SANDBOX_NAME;

        // Insert user with attributes requiring MFA enforcement 
        String random = String.valueOf(System.currentTimeMillis());
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        UserRole internalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
        Profile internalProfile = [SELECT Id FROM Profile WHERE name = 'System Administrator'];
        User userRecord = new User(
                UserRoleId = internalRole.Id,
                ProfileId = internalProfile.Id,
                Username = random + '.ismfa@monash.edu',
                Alias = 't_ismfa',
                Email='t_ismfa@monash.edu',
                EmailEncodingKey='UTF-8',
                Firstname='Firstname' + random,
                Lastname='Lastname' + random,
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                TimeZoneSidKey='Australia/Sydney',
                IsActive=true
        );
        System.runAs(thisUser) {
            Database.upsert(setting);
            Database.insert(userRecord);
        }

        Test.stopTest();

        // Get Id of MFA enforcement perm set 
        List<PermissionSet> permSets = new List<PermissionSet>();
        permSets = [SELECT Id FROM PermissionSet WHERE Name = :SecurityServices.MFA_ENFORCEMENT_PERM_SET LIMIT 1];
        Assert.areEqual (permSets.size(),1, 'MFA enforcement perm set not found in Org') ;
        Id mfaPermSetId = permSets[0].Id;

        // Get MFA enforcement perm set assigned to test user
        List<PermissionSetAssignment> permSetsAssign = new List<PermissionSetAssignment>();
        permSetsAssign = [SELECT PermissionSetId, PermissionSet.Name, AssigneeId, Assignee.Username FROM PermissionSetAssignment WHERE AssigneeId = :userRecord.Id AND PermissionSetId = :mfaPermSetId];

        // Should only be assigned MFA perm set if in a sandbox
        if (runningInASandbox) {
            Assert.areEqual(permSetsAssign.size(),1, 'User should have been assigned MFA enforcement permission set') ;
        } else {
            Assert.areEqual(permSetsAssign.size(),0, 'User should not be assigned MFA enforcement permission set in a Prod Org') ;
        }
    }
    
    /**
     * Test method to validate MFA enforcement perm set assignment is bypassed for out of scope sandbox [EPCP-1667]
     */
    @isTest
    static void testMfaEnforcementBypassOutOfScopeSandbox () {
                
        Test.startTest(); 

        // Fudge sandbox name to a sandbox name out-of-scope for MFA 
        Sandbox_Details__c setting = Sandbox_Details__c.getOrgDefaults();
        setting.sandboxName__c = 'someoutofscopesandboxname99';

        // Insert user with attributes requiring MFA enforcement 
        String random = String.valueOf(System.currentTimeMillis());
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        UserRole internalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
        Profile internalProfile = [SELECT Id FROM Profile WHERE name = 'System Administrator'];
        User userRecord = new User(
                UserRoleId = internalRole.Id,
                ProfileId = internalProfile.Id,
                Username = random + '.ismfa@monash.edu',
                Alias = 't_ismfa',
                Email='t_ismfa@monash.edu',
                EmailEncodingKey='UTF-8',
                Firstname='Firstname' + random,
                Lastname='Lastname' + random,
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                TimeZoneSidKey='Australia/Sydney',
                IsActive=true
        );
        System.runAs(thisUser) {
            Database.upsert(setting);
            Database.insert(userRecord);
        }

        Test.stopTest();

        // Get Id of MFA enforcement perm set 
        List<PermissionSet> permSets = new List<PermissionSet>();
        permSets = [SELECT Id FROM PermissionSet WHERE Name = :SecurityServices.MFA_ENFORCEMENT_PERM_SET LIMIT 1];
        Assert.areEqual (permSets.size(),1, 'MFA enforcement perm set not found in Org') ;
        Id mfaPermSetId = permSets[0].Id;

        // Get MFA enforcement perm set assigned to test user, should not find anything
        List<PermissionSetAssignment> permSetsAssign = new List<PermissionSetAssignment>();
        permSetsAssign = [SELECT PermissionSetId, PermissionSet.Name, AssigneeId, Assignee.Username FROM PermissionSetAssignment WHERE AssigneeId = :userRecord.Id AND PermissionSetId = :mfaPermSetId];

        // Should not be assigned MFA perm set
        Assert.areEqual(permSetsAssign.size(),0, 'User should not have been assigned MFA enforcement permission set in out of scope sandbox') ;
	}
    /**
    * @author      Peter Sewell
    * @description Tests SyncUserToUserShadow method
    *              Validates whether the associated user in the ShadowUser object is inserted/updated, when User details are inserted/updated
    * @revision    01/11/2021 - Peter Sewell - Created
    */
    @isTest
    public static void testSyncUserToUserShadow() {
  
        // Insert user  
        String random = String.valueOf(System.currentTimeMillis());

        UserRole internalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
        Profile internalProfile = [SELECT Id FROM Profile WHERE name = 'System Administrator'];
        User userRecord = new User(
                Provisioning_Request_Id__c = 'REQ1234567',
                Last_Provisioning_Action__c = 'Setup new account',
                Provisioning_Source__c = 'Other',
                UserRoleId = internalRole.Id,
                ProfileId = internalProfile.Id,
                Username = random + '.isauser@monash.edu',
                Alias = 't_isau',
                Email='t_isauser@monash.edu',
                EmailEncodingKey='UTF-8',
                Firstname='Firstname' + random,
                Lastname='Lastname' + random,
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                TimeZoneSidKey='Australia/Sydney',
                IsActive=true
        );
        
        Test.startTest(); 

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            Database.insert(userRecord);

            userRecord.Provisioning_Request_Id__c = 'REQ999999';
            userRecord.Last_Provisioning_Action__c = 'Deactivate account';
            userRecord.IsActive = false;
            Database.update(userRecord);
        }

        Test.stopTest(); 

        //Start assertion - check that the ShadowUser records are correctly updated - match with last action Last_Provisioning_Action__c = 'Deactivate account'
        List<UserShadow__c> us = new List<UserShadow__c>(
            [SELECT Username__c, IsActive__c, Last_Provisioning_Action__c,  Provisioning_Request_Id__c FROM UserShadow__c WHERE Last_Provisioning_Action__c = 'Deactivate account' LIMIT 1]
        );
        Assert.areEqual('REQ999999', us[0].Provisioning_Request_Id__c, 'testSyncUserToUserShadow - Provisioning_Request_Id__c should have been "REQ999999"');
        Assert.areEqual('Deactivate account', us[0].Last_Provisioning_Action__c, 'testSyncUserToUserShadow - Provisioning_Action__c should have been "Deactivate account"');
        Assert.isFalse(us[0].IsActive__c, 'testSyncUserToUserShadow - IsActive__c should have been "false"');
    }

    @isTest
    static void clearFedIdUserNameTest() {
        //GIVEN - Deactivatd User
        Profile internalProfile = [SELECT Id FROM Profile WHERE name = 'System Administrator' LIMIT 1];
        //Create user
        String random = String.valueOf(System.currentTimeMillis());
        User recUser = new User(
            UserName = random + 'testusername@clearFedIds.com',
            FirstName = 'TestFirstName',
            LastName = 'TestLast',
            Alias = 'test_cu',
            CommunityNickname = 'clerFeds' + random,
            Email = random + 'testusername@clearFedIds.com',
            ProfileId = internalProfile.Id,
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'Australia/Sydney',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            FederationIdentifier = 'FEDID' + random,
            IsActive = false
            );
        User usrClone = recUser.clone(true, true);
        usrClone.IsActive = true;
        //WHEN - Behaviour to Test
        Test.startTest();
        UserServices.ClearFedIdUserName stub = new UserServices.ClearFedIdUserName();
        stub.process(recUser);
        stub.process(recUser, usrClone);
        stub.execute();
        Test.stopTest();
        //THEN - Expected Context After Test
        Assert.isNull(recUser.FederationIdentifier, 'Not Cleared');
    }

    @isTest
    static void removePermissionsUserTests() {
        //GIVEN - Active User
        String random = String.valueOf(System.currentTimeMillis());
        String emStr = 'testRemove.USer@permissions.com';
        Profile baseProfile = [SELECT Id FROM Profile WHERE Name = 'Base Profile' LIMIT 1];
        User baseUser = new User(
            UserName = random + emStr,
            FirstName = 'TestRemove',
            LastName = 'User Removal',
            Alias = 'test_rp',
            CommunityNickname = 'test_rp' + random,
            email = emStr,
            ProfileId = baseProfile.Id,
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'Australia/Sydney',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            IsActive = true
            );
        Database.insert(baseUser);
        Assert.isNotNull(baseUser.Id, 'Insert Failed');
        PermissionSet permSetRec = [SELECT Id FROM PermissionSet WHERE Name = 'Contact_Merge_App_Access' LIMIT 1];
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = baseUser.Id;
        psa.PermissionSetId = permSetRec.Id;
        UserServices.InsertSobjectsQueueable insertPSAQueuable = new UserServices.InsertSobjectsQueueable(new List<PermissionSetAssignment> {psa}, false); // do not fail all records if a particular item fails
        System.enqueueJob(insertPSAQueuable);
        //
        // Permission Set License
        PermissionSetLicense psLicense = [SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'SalesforceCPQ_CPQStandardPerm' LIMIT 1];
        PermissionSetLicenseAssign psUsrLic = new PermissionSetLicenseAssign();
        psUsrLic.AssigneeId = baseUser.Id;
        psUsrLic.PermissionSetLicenseId = psLicense.Id;
        UserServices.InsertSobjectsQueueable insertPSLQueuable = new UserServices.InsertSobjectsQueueable(new List<PermissionSetLicenseAssign> {psUsrLic}, false); // do not fail all records if a particular item fails
        System.enqueueJob(insertPSLQueuable);
        //WHEN - Setting User to inactive
        Test.startTest();
        //
        Assert.areNotEqual(0,[SELECT count() FROM PermissionSetAssignment WHERE AssigneeId =: baseUser.Id],'Permission Sets not assigned up');
        UserServices.RemovePermissionsUser rmClass = new  UserServices.RemovePermissionsUser();
        User uClone = baseUser.clone(true, true, true, true);
        uClone.IsActive = false;
        rmClass.process(uClone, baseUser);
        rmClass.execute();
        //THEN - Expected PermissionSet and PermissionSetLicense removed from inactive user
        Assert.areEqual(0,
                            [SELECT count() FROM PermissionSetAssignment WHERE AssigneeId =: baseUser.Id AND PermissionSet.Name = 'Contact_Merge_App_Access' AND PermissionSet.IsOwnedByProfile = false],
                            'Permission Sets not cleaned up');
        Assert.areEqual(0,
                            [SELECT count() FROM PermissionSetLicenseAssign WHERE AssigneeId =: baseUser.Id AND PermissionSetLicense.DeveloperName = 'SalesforceCPQ_CPQStandardPerm'],
                            'PermissionSetLicense not cleaned up');
        Test.stopTest();
    }

    /**
     * Validate that a change to MobilePhone results in clearing of MFA_Mobile_Verified_External__c field
     */
    @isTest
    static void testClearVerifiedMobileFlagOnMobileChange() {

        User userBefore = getTestUserWithMobile();
        Test.startTest(); 
            // Updating mobile phone should clear MFA_Mobile_Verified_External__c
            userBefore.MobilePhone = DUMMY_MOBILE_UNVERIFIED; 
            Database.update(userBefore);
        Test.stopTest();

        User userAfter = getTestUserWithMobile();
        Assert.isFalse(userAfter.MFA_Mobile_Verified_External__c,'MFA_Mobile_Verified_External__c expected to be false after MobilePhone field updated');
    }
    
    // Create test user
    static void createTestUserWithVerfiedMobile(String mobileNumber) {
        String random = String.valueOf(System.currentTimeMillis());
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        UserRole internalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
        Profile internalProfile = [SELECT Id FROM Profile WHERE name = 'System Administrator'];
        User userRecord = new User(
                UserRoleId = internalRole.Id,
                ProfileId = internalProfile.Id,
                Username = random + '.someuser@monash.edu',
                Alias = 't_someu',
                Email=TEST_USER_EMAIL,
                EmailEncodingKey='UTF-8',
                Firstname='Firstname' + random,
                Lastname='Lastname' + random,
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                TimeZoneSidKey='Australia/Sydney',
                IsActive=true,
                MobilePhone = mobileNumber, 
                MFA_Mobile_Verified_External__c = true
        );

        System.runAs(thisUser) {
            Database.insert(userRecord);
        }	
    }

    // Get test user
    static User getTestUserWithMobile() {        
        for (User u : [SELECT Id, MobilePhone, MFA_Mobile_Verified_External__c FROM User WHERE Email = :TEST_USER_EMAIL ORDER BY CreatedDate DESC LIMIT 1 ]) {
            return u;
        }
        return null;
    }

    @IsTest
    static void testSyncDetailsFromContact() {
        // flush events from setupData
        Test.getEventBus().deliver();
        Test.getEventBus().deliver();

        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Up__c = true;
        cs.Enable_Roll_Down__c = true;
        cs.EnableChannelBreakUp__c = true;
        cs.Run_Roll_Up_Asynchronously__c = true;
        upsert cs;

        // GIVEN - contact record exists with PFN rolled up
        Contact con = TestHelper.createStaffContacts(1)[0];
        con.Preferred_Name__c = 'John';
        con.Authcate__c = 'abc123';
        
        insert con;
        Test.getEventBus().deliver();
        Test.getEventBus().deliver(); // do rollup


        con = [SELECT FirstName, Preferred_Name__c FROM Contact WHERE Authcate__c = 'abc123'];
        Assert.areEqual(con.Preferred_Name__c, con.FirstName);

        System.runAs(new User(Id = UserInfo.getUserId())){
            Test.startTest();
            //WHEN - A Staff user record is created (same authcate as contact)
            User user = TestHelper.createTestUsers('Standard User', 1, false)[0];
            user.FederationIdentifier = 'abc123';
            insert user;
            Test.stopTest();

            // THEN Staff user should update to reflect the correct FirstName (PFN) from the Contact
            user = [SELECT FirstName FROM User WHERE FederationIdentifier = 'abc123'];
            Assert.areEqual(con.FirstName, user.FirstName);
        }
    }

    @IsTest
    static void testSyncDetailsFromContact_Multiple() {
        // flush events from setupData
        Test.getEventBus().deliver();
        Test.getEventBus().deliver();

        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Enable_Roll_Up__c = true;
        cs.Enable_Roll_Down__c = true;
        cs.EnableChannelBreakUp__c = true;
        cs.Run_Roll_Up_Asynchronously__c = true;
        upsert cs;

        // GIVEN - 2 contact records exist with PFN rolled up & same authcate
        Contact con = TestHelper.createStaffContacts(1)[0];
        con.Preferred_Name__c = 'John';
        con.Authcate__c = 'abc123';

        Contact con2 = TestHelper.createStaffContacts(1)[0];
        con2.Preferred_Name__c = 'Jim';
        con2.Authcate__c = 'abc123';
        
        insert new List<Contact>{con, con2};
        Test.getEventBus().deliver();
        Test.getEventBus().deliver(); // do rollup

        con = [SELECT FirstName, Preferred_Name__c FROM Contact WHERE Preferred_Name__c = 'John'];
        System.assertEquals(con.Preferred_Name__c, con.FirstName);

        con2 = [SELECT FirstName, Preferred_Name__c FROM Contact WHERE Preferred_Name__c = 'Jim'];
        System.assertEquals(con2.Preferred_Name__c, con2.FirstName);

        System.runAs(new User(Id = UserInfo.getUserId())){
           
            Test.startTest();
            update con2; // dummy update to make it recently modified

            //WHEN - A user record is created (same authcate as contacts)
            User user = TestHelper.createTestUsers('Standard User', 1, false)[0];
            user.FederationIdentifier = 'abc123';
            insert user;
            Test.stopTest();

            // THEN  user should update to reflect the correct FirstName (PFN) from the recently modified Contact
            user = [SELECT FirstName FROM User WHERE FederationIdentifier = 'abc123'];
            Assert.areNotEqual(con.FirstName, user.FirstName);
            Assert.areEqual(con2.FirstName, user.FirstName);
        }
    }

    /**
    * @author      Angelo Rivera
    * @description Test sync username from User to contact
    * @revision    10/14/2024 - Angelo Rivera - Created
    */
    @isTest
    static void test_RollupUsernameToContact() {
        Id partnerProfileId = [SELECT Id FROM Profile WHERE Name = :Constants.PARTNER_USER_PROFILE LIMIT 1].Id;
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();

        Account testAccount = new Account(Name = 'TestAccount', RecordTypeId = partnerRecordTypeId, OwnerId = UserInfo.getUserId());
        insert testAccount;
        Contact testContact = new Contact(FirstName = 'TestFirstName', LastName = 'TestLastName', AccountId = testAccount.Id, Email = 'TestEmail@testemail.com', OwnerId = UserInfo.getUserId());
        insert testContact;

        //Create user
        String random = String.valueOf(System.currentTimeMillis());
        User communityUser = new User(
                Username = 'newtestusername@testemail.com',
                FirstName = 'TestFirstName',
                LastName = 'TestLast',
                Alias = 'test_cu',
                CommunityNickname = 'test_cu' + random,
                Email = random + 'testusername@testemail.com',
                ProfileId = partnerProfileId,
                EmailEncodingKey = 'UTF-8',
                TimeZoneSidKey = 'Australia/Sydney',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                ContactId = testContact.Id
        );

        Test.startTest();
        Database.insert(communityUser);
        Test.stopTest();

        //Start assertion - check that the user has a contact record associated to it
        Assert.areEqual('newtestusername@testemail.com', [SELECT Id, MyApp_Username__c FROM Contact WHERE Id =: communityUser.ContactId].MyApp_Username__c);

    }

}