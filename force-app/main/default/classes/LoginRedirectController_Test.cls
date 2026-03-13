/**
 * @author       P.Sewell
 * @date         28.Aug.2024
 * @description  Test Class for LoginRedirectController
 * @revision
 *               28.Aug.24 P.Sewell - Create Class
 *               04.Sep.24 P.Sewell - Test removal of trailing slash from base URL if present
 *               22.Oct.24 P.Sewell - Additional tests for new param-based redirect methods 
 **/
@isTest(isParallel=false) // Parallel test not permitted on User object
private class LoginRedirectController_Test {
    
    @TestSetup
    static void setupTestData() {
        // Create two users
        User userWithPermSet = createUser('UserWithPermSet123@example.com', 'UserWithPermSet');
        User userWithoutPermSet = createUser('UserWithoutPermSet123@example.com', 'UserWithoutPermSet');

        // Insert the users
        insert new List<User> { userWithPermSet, userWithoutPermSet };
        
        // Assign permission sets to the user
        assignPermissionSetToUser(userWithPermSet.Id, LoginRedirectController.DEFAULT_MEMBER_PERMSET_TO_ASSIGN);

        // Create a custom setting record
        System.runAs(userWithPermSet) {
            Login_Redirect_Settings__c settingRecord = new Login_Redirect_Settings__c(
                Name = 'test_site',
                Network_Name__c = LoginRedirectController.DEFAULT_REDIRECT_NETWORK_NAME,
                Permission_Sets__c = LoginRedirectController.DEFAULT_MEMBER_PERMSET_TO_ASSIGN
            );
            insert settingRecord;
        }
    }

    @isTest
    static void testGetRedirectNetworkId() {
        
        //GIVEN - Some Context Before Tests
        String networkIdString = '';

        //WHEN - Behaviour to Test
        Test.startTest();
            networkIdString = LoginRedirectController.getRedirectNetworkId();
        Test.stopTest();
        
        //THEN - Expected Context After Test
        Assert.isFalse(
            String.isBlank(networkIdString),
            'Network Id should not be blank or null');
    }

    @isTest
    static void testGetSitePath() {
        
        //GIVEN - Some Context Before Tests
        String sitePath = '';

        //WHEN - Behaviour to Test
        Test.startTest();
            sitePath = LoginRedirectController.getSitePath();
        Test.stopTest();
        
        //THEN - Expected Context After Test
        Assert.isFalse(
            String.isBlank(sitePath),
            'Site Path should not be blank or null');
    }

    @isTest
    static void testGetRedirectUrl() {
        
        //GIVEN - Some Context Before Tests
        String redirectUrl = '';

        //WHEN - Behaviour to Test
        Test.startTest();
            redirectUrl = LoginRedirectController.getRedirectUrl();
        Test.stopTest();
        
        //THEN - Expected Context After Test
        Assert.isFalse(
            String.isBlank(redirectUrl),
            'Redirect URL should not be blank or null');
    }

    @isTest
    static void testGetRedirectUrlWithPath() {
        
        //GIVEN - Some Context Before Tests
        String redirectUrl = '';

        //WHEN - Behaviour to Test
        Test.startTest();
            redirectUrl = LoginRedirectController.getRedirectUrlWithPath('/s/somepath', 'test_site');
        Test.stopTest();
        
        //THEN - Expected Context After Test
        Assert.isTrue(
            !String.isBlank(redirectUrl) && redirectUrl.contains('somepath'),
            'Redirect URL should not be blank or null and contain redirect path');
    }

    @isTest
    static void testGetRedirectUrlWithPathBadSite() {
        
        //GIVEN - Some Context Before Tests
        String redirectUrl = '';
        Boolean caughtException = false;

        //WHEN - Behaviour to Test
        Test.startTest();
            try {
                redirectUrl = LoginRedirectController.getRedirectUrlWithPath('/s/somepath', 'test_site_bad');
            } catch (Exception ex) {
                caughtException = true;
            }

        Test.stopTest();
        
        //THEN - Expected Context After Test
        Assert.isTrue(
            caughtException,
            'Exception should have been thrown for a bad site name');
    }

    @isTest
    static void testGetRedirectUrlWithPathBadPath() {
        
        //GIVEN - Some Context Before Tests
        String redirectUrl = '';
        Boolean caughtException = false;

        //WHEN - Behaviour to Test
        Test.startTest();
            try {
                redirectUrl = LoginRedirectController.getRedirectUrlWithPath('https://www.google.com', 'test_site');
            } catch (Exception ex) {
                caughtException = true;
            }

        Test.stopTest();
        
        //THEN - Expected Context After Test
        Assert.isTrue(
            caughtException,
            'Exception should have been thrown for a bad path');
    }

    @isTest
    static void testMakeMemberOfTargetPortalByName() {
        
        //GIVEN - Some Context Before Tests
        User userWithoutPermSet = [SELECT Id FROM User WHERE Email = 'UserWithoutPermSet123@example.com' LIMIT 1];

        //WHEN - Behaviour to Test
        Test.startTest();
            System.runAs(userWithoutPermSet) {
                LoginRedirectController.makeMemberOfTargetPortalByName('test_site');
            }
        Test.stopTest();
        
        //THEN - Expected Context After Test
        
        // Query PermissionSetAssignment to check if the user has the permission set assigned
        PermissionSetAssignment assignment = [
            SELECT Id 
            FROM PermissionSetAssignment 
            WHERE AssigneeId = :userWithoutPermSet.Id 
            AND PermissionSet.Name = :LoginRedirectController.DEFAULT_MEMBER_PERMSET_TO_ASSIGN
            LIMIT 1
        ];
        
        Assert.isTrue(
            assignment != null,
            'Permission set was not assigned to the user as expected');
    }

    @isTest
    static void testMakeMemberOfTargetPortal() {
        
        //GIVEN - Some Context Before Tests
        User userWithoutPermSet = [SELECT Id FROM User WHERE Email = 'UserWithoutPermSet123@example.com' LIMIT 1];

        //WHEN - Behaviour to Test
        Test.startTest();
            System.runAs(userWithoutPermSet) {
                LoginRedirectController.makeMemberOfTargetPortal();
            }
        Test.stopTest();
        
        //THEN - Expected Context After Test
        
        // Query PermissionSetAssignment to check if the user has the permission set assigned
        PermissionSetAssignment assignment = [
            SELECT Id 
            FROM PermissionSetAssignment 
            WHERE AssigneeId = :userWithoutPermSet.Id 
            AND PermissionSet.Name = :LoginRedirectController.DEFAULT_MEMBER_PERMSET_TO_ASSIGN
            LIMIT 1
        ];
        
        Assert.isTrue(
            assignment != null,
            'Permission set was not assigned to the user as expected');
    }

    @isTest
    static void testGetNetworkPermSetsBySettingName() {
        
        //GIVEN - Some Context Before Tests
        List<String> permSets = new List<String>();

        //WHEN - Behaviour to Test
        Test.startTest();
            permSets = LoginRedirectController.getNetworkPermSetsBySettingName('test_site');
        Test.stopTest();
        
        //THEN - Expected Context After Test
        Assert.isTrue(
            permSets.size() == 1,
            'Permission set name was not found as expected');
    }

    @isTest
    static void testGetNetworkPermSetsBySettingNameBadInput() {
        
        //GIVEN - Some Context Before Tests
        List<String> permSets = new List<String>();
        Boolean caughtException = false;

        //WHEN - Behaviour to Test
        Test.startTest();
        try {
            permSets = LoginRedirectController.getNetworkPermSetsBySettingName(null);
        } catch (Exception ex) {
            caughtException = true;
        }
        Test.stopTest();
        
        //THEN - Expected Context After Test
        Assert.isTrue(
            caughtException,
            'Exception was not thrown for bad input as expected');
    }

    @isTest
    static void testGetNetworkPermSetsBySettingNameBadSite() {
        
        //GIVEN - Some Context Before Tests
        List<String> permSets = new List<String>();
        Boolean caughtException = false;

        //WHEN - Behaviour to Test
        Test.startTest();
        try {
            permSets = LoginRedirectController.getNetworkPermSetsBySettingName('bad_site');
        } catch (Exception ex) {
            caughtException = true;
        }
        Test.stopTest();
        
        //THEN - Expected Context After Test
        Assert.isTrue(
            caughtException,
            'Exception was not thrown for bad site setting as expected');
    }

    @isTest
    static void testRemoveTrailingSlash() {
        
        //GIVEN - Some Context Before Tests
        String strWithSlash = 'https://connect.monash.edu/';

        //WHEN - Behaviour to Test
        Test.startTest();
            strWithSlash = LoginRedirectController.removeTrailingSlash(strWithSlash);
        Test.stopTest();
        
        //THEN - Expected Context After Test
        Assert.isFalse(
            strWithSlash.endsWith('/'),
            'String should not have as trailing slash');
    }

    @isTest
    static void testAssignPermissionSetIfNotAssigned() {
        
        //GIVEN - Some Context Before Tests
        User user1 = [SELECT Id FROM User WHERE Email = 'UserWithPermSet123@example.com' LIMIT 1];
        User user2 = [SELECT Id FROM User WHERE Email = 'UserWithoutPermSet123@example.com' LIMIT 1];
        PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = :LoginRedirectController.DEFAULT_MEMBER_PERMSET_TO_ASSIGN LIMIT 1];

        //WHEN - Behaviour to Test
        Test.startTest();
            LoginRedirectController.assignPermissionSetsIfNotAssigned(user1.Id, new List<String>{LoginRedirectController.DEFAULT_MEMBER_PERMSET_TO_ASSIGN});
            LoginRedirectController.assignPermissionSetsIfNotAssigned(user2.Id, new List<String>{LoginRedirectController.DEFAULT_MEMBER_PERMSET_TO_ASSIGN});
        Test.stopTest();
        
        //THEN - Expected Context After Test
        Assert.isTrue(permSet != null, 'Permset does not exist:' + LoginRedirectController.DEFAULT_MEMBER_PERMSET_TO_ASSIGN);  

        PermissionSetAssignment permSetAssignment1 = [
            SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :user1.Id AND PermissionSetId = :permSet.Id
        ];
        Assert.isTrue(permSetAssignment1 != null, 'User 1 should have permission set assigned.');  

        PermissionSetAssignment permSetAssignment2 = [
            SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :user2.Id AND PermissionSetId = :permSet.Id
        ];
        Assert.isTrue(permSetAssignment2 != null, 'User 2 should have permission set assigned.');  

    }

    // Helper method to create a user
    private static User createUser(String email, String lastName) {
        Profile standardUserProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User user = new User(
            FirstName = 'Test',
            LastName = lastName,
            Email = email,
            Username = email +  '.' + String.valueOf(Math.random()).substring(2, 8) + '.com',  
            Alias = lastName.substring(0, 5),
            ProfileId = standardUserProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        return user;
    }

    // Helper method to assign a permission set to a user
    private static void assignPermissionSetToUser(Id userId, String permSetName) {
        PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = :permSetName LIMIT 1];
        
        Assert.isTrue(permSet != null, 'Permset does not exist:' + permSetName);  

        if (permSet != null) {
            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = userId,
                PermissionSetId = permSet.Id
            );
            insert psa;
        }
    }


}