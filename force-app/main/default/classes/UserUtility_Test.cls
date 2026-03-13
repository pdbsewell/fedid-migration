/**
* @author Matthew Maramot
* @date 11/01/2023
* @group Test Class
* @description  This class contains unit tests for validating the behavior of UserUtility methods
*              
*/

@isTest(isParallel=true)
private class UserUtility_Test {
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
        for(PermissionSetAssignment psa : permSetsAssign) {
            System.debug(LoggingLevel.DEBUG, 'UserServices_Test.testAssignPermissionSets: User['+psa.Assignee.Username+'] was assigned with PermissionSet ['+psa.PermissionSet.Name+']');
        }
        System.assert(permSetsAssign.size()>0, 'No permission sets assigned to community user');
    }

    /**
     * Test method to validate internal permission sets are automatically assigned
     */
    @isTest
    static void testAssignPermissionSetsInternal() {
        Test.startTest();
        String random = String.valueOf(System.currentTimeMillis());
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        //Create user
        UserRole internalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
        Profile internalProfile = [SELECT Id FROM Profile WHERE name = 'System Administrator'];
        User internalUser = new User(
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
            Database.insert(internalUser);
        }

        Test.stopTest();

        List<PermissionSetAssignment> permSetsAssign = [SELECT PermissionSetId, PermissionSet.Name, AssigneeId, Assignee.Username FROM PermissionSetAssignment WHERE AssigneeId = :internalUser.Id];
        for(PermissionSetAssignment psa : permSetsAssign) {
            System.debug(LoggingLevel.DEBUG, 'UserServices_Test.testAssignPermissionSets: User['+psa.Assignee.Username+'] was assigned with PermissionSet ['+psa.PermissionSet.Name+']');
        }
        System.assert(permSetsAssign.size()>0, 'No permission sets assigned to internal user');
    }

    /**
     * Test method to validate exemption of a user assigned API-Only
     */
    @isTest
    static void testExemptedInternalApiOnlyUser() {
        Test.startTest();
        String random = String.valueOf(System.currentTimeMillis());
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        //Create user
        Profile internalProfile = [SELECT Id FROM Profile WHERE name = 'Salesforce API Only System Integrations']; // Should exempt user
        User internalUserExempted = new User(
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
            Database.insert(internalUserExempted); 
            // Assign API only license
            PermissionSetLicense psl = [SELECT Id FROM PermissionSetLicense WHERE DeveloperName = 'SalesforceAPIIntegrationPsl'];
            PermissionSetLicenseAssign licenseAssign = new PermissionSetLicenseAssign(
                AssigneeId = internalUserExempted.Id,
                PermissionSetLicenseId = psl.Id
            );
            Database.insert(licenseAssign);
        }

        Test.stopTest();
        
        List<Id> apiUsers = new List<Id>();
        Map<Id, User> oldUserMap = new Map<Id, User>{internalUserExempted.Id => internalUserExempted};
        System.assert(UserUtility.isInternal(internalUserExempted, apiUsers, oldUserMap) == false, 'Updated API only user was not exempted from internal user classification');
        System.assert(UserUtility.isInternal(internalUserExempted, apiUsers, new Map<Id, User>()) == false, 'Inserted API only user was not exempted from internal user classification');
    }

    /**
     * Test method to validate exemption of user with Monash_User_Type__c set to 'eSol Integration User'
     */
    @isTest
    static void testExemptedInternalUserEsolIntegration() {
        Test.startTest();
        String random = String.valueOf(System.currentTimeMillis());
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        //Create user
        UserRole internalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
        Profile internalProfile = [SELECT Id FROM Profile WHERE name = 'System Administrator'];
        User internalUserExempted = new User(
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
                TimeZoneSidKey='Australia/Sydney',
                Monash_User_Type__c = UserUtility.INTEGRATION_USER_TYPE // Should exempt user from isInternal test
        );
        System.runAs(thisUser) {
            Database.insert(internalUserExempted);
        }

        Test.stopTest();
        
        List<Id> apiUsers = new List<Id>();
        Map<Id, User> oldUserMap = new Map<Id, User>{internalUserExempted.Id => internalUserExempted};
        System.assert(UserUtility.isInternal(internalUserExempted, apiUsers, oldUserMap) == false, 'Updated user was not exempted from internal user classification');
        System.assert(UserUtility.isInternal(internalUserExempted, apiUsers, new Map<Id, User>()) == false, 'Inserted user was not exempted from internal user classification');
    }

    /**
    * @author      Matthew Maramot
    * @description Tests the retrieval of Permission Sets and Permission Set Groups from custom metadata
    * @revision    22/11/2022 - Matthew Maramot - Created
    */
    @isTest
    public static void permSetToMapTest() {
        //Create new rules to be tested
        List<System_Settings__mdt> testRulesList = new List<System_Settings__mdt>();
        testRulesList.add(new System_Settings__mdt(MasterLabel = 'TestPermSet',
                DeveloperName = 'TestPermSet',
                Is_Active__c = true,
                Feature__c = 'USER_DEFAULT_PERMISSIONS',
                DataType__c = 'JSON',
                Key__c = 'UDPCommunityStudent',
                Value__c = '{"Permission_Type": "Permission Set", "Permissions": "Customer_Community_Ask_Monash_Student"}'));
        testRulesList.add(new System_Settings__mdt(MasterLabel = 'TestPermSetGroup',
                DeveloperName = 'TestPermSetGroup',
                Is_Active__c = true,
                Feature__c = 'USER_DEFAULT_PERMISSIONS',
                DataType__c = 'JSON',
                Key__c = 'UDPInternal',
                Value__c = '{"Permission_Type": "Permission Set Group", "Permissions": "ADDON_All_Internal_Users_PSG"}'));

        
        Test.startTest(); 

        // Retrieve custom metadata and split based off Permission Sets and Permission Set Groups
        Map<String,Set<PermissionSet>> permissionSetMap = UserUtility.getDefaultPermSets(testRulesList);
        Map<String,Set<PermissionSetGroup>> permissionSetGroupMap = UserUtility.getDefaultPermSetGroups(testRulesList);
     

        Test.stopTest(); 

        //Start assertion
        System.assertEquals(1, permissionSetMap.get(UserUtility.USER_DEFAULT_PERMS_COMMUNITY_STUDENT).size(), 'Did not convert Metadata into Permission Set Map - expected 1 entry.');
        System.assertEquals(1, permissionSetGroupMap.get(UserUtility.USER_DEFAULT_PERMS_INTERNAL).size(), 'Did not convert Metadata into Permission Set Map - expected 1 entry.');
    }
}