/**
 * @description Test class for SessionUtils, ensuring session management utility functions work as expected.
 * @author      Kai-Fan Hsieh
 * @since       19/08/2024
 */
@IsTest(IsParallel=true)
private class SessionUtils_Test {
    private static final String testKey = 'TestKey';
    private static final Integer ttlSeconds = 900;
    
    @TestSetup
    static void setupData(){
        // insert experience mfa custom setting
        ExperienceMFASetting__c	mfaSetting = new ExperienceMFASetting__c();
        mfaSetting.Autotest_Bypass_Key__c = 'bypasskeyword';
        insert mfaSetting;
        
        User LoggedInUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs ( LoggedInUser ) {
            //Create account
            Account portalAccount1 = new Account(
            Name = 'TestAccount',
            OwnerId = UserInfo.getUserId());
            Database.insert(portalAccount1);       

            //create contact (needed by user)
            Contact contact = new contact(LastName = 'LastName', Firstname = 'FirstName');
            contact.Birthdate =  Date.valueOf('2019-09-24');
            contact.AccountId = portalAccount1.Id;
            insert contact;

            User user = new User();
            user.FirstName = 'Customer';
            user.LastName = 'User';
            user.Alias = 'test';
            user.MobilePhone = '+61 0401234567';
            user.Mobile_Phone_Country__c = 'Australia';
            user.CommunityNickname = 'Test1';
            user.TimeZoneSidKey = 'America/New_York';
            user.LocaleSidKey = 'en_US';
            user.MFA_Email_Verification_Count__c = 1;
            user.EmailEncodingKey = 'UTF-8';
            user.Email = 'testEmail925@gmail.com';
            user.Username = 'testEmail925@gmail.com';
            user.IsActive = true;
            user.LanguageLocaleKey = 'en_US';
            user.App_Birthdate__c = Date.valueOf('2019-09-24');        
            
            List<Profile> profiles = [SELECT Id FROM Profile WHERE Name ='Customer Community General User']; //MUST use a profile that is a portal user!
            if(profiles.size() > 0){
                user.ProfileID = profiles[0].Id;       		
                user.ContactId = contact.Id;
                insert user;

                // Grant Permission Set
                List<PermissionSetAssignment> mfaAndPortalAccess = new List<PermissionSetAssignment>();
                for(PermissionSet mfaPermSet : [SELECT Id FROM PermissionSet WHERE Name = 'Experience_Custom_MFA' OR Name = 'Alumni_Portal_Permission_Set']){
                    mfaAndPortalAccess.add(new PermissionSetAssignment(PermissionSetId = mfaPermSet.Id, AssigneeId = user.Id));
                }
                insert mfaAndPortalAccess;
            }  
        }
    }
    /**
     * @description Test case for retrieving the session ID.
     */
    @isTest
    private static void testRetrieveSessionId() {
        // Given: A valid session is available.

        // When: The retrieveSessionId method is called.
        System.runAs(New User(Id = UserInfo.getUserId())) {
            Test.startTest();
            String sessionId = SessionUtils.getSessionId();
            Test.stopTest();
            // Then: The returned session ID should not be null.
            Assert.areNotEqual(null, sessionId, 'Session Id should not be null');
        }
    }

    @isTest static void testSetAndGetCacheValue() {
        // Run as the created Community User
        User communityUser = [SELECT Id FROM User WHERE Email = 'testEmail925@gmail.com' LIMIT 1];
        System.runAs(communityUser) {
            // Set a value in the cache
            Boolean setResult = SessionUtils.setCacheValue(testKey, 'TestValue', ttlSeconds);
            Assert.areEqual(true, setResult, 'Cache set should return true');
            
            // Retrieve the value from the cache
            String value = SessionUtils.getCacheValue(testKey);
            Assert.areEqual('TestValue', value, 'The cached value should match the set value');
        }
    }

    @isTest static void testClearCacheValue() {
        // Set a value in the cache
                // Run as the created Community User
                User communityUser = [SELECT Id FROM User WHERE Email = 'testEmail925@gmail.com' LIMIT 1];
                System.runAs(communityUser) {
        SessionUtils.setCacheValue(testKey, 'TestValue', ttlSeconds);
        
        // Clear the value from the cache
        SessionUtils.clearCacheValue(testKey);
        
        // Ensure the value is cleared (i.e., returns null)
        String value = SessionUtils.getCacheValue(testKey);
        Assert.areEqual(null, value, 'The cache value should be null after clearing');}
    }
    @isTest static void testValidteExceptions() {
        // Use a unique key for OTP attempt tracking to avoid conflicts
        // Run as the created Community User
        User communityUser = [SELECT Id FROM User WHERE Email = 'testEmail925@gmail.com' LIMIT 1];
        System.runAs(communityUser) {
            SessionUtils.PARTITION = 'InvalidPartition';
            // On the 6th attempt, the method should throw an exception
            try {
                SessionUtils.setCacheValue('04000000000','10',10);
            } catch (Exception e) {
                Assert.isTrue(e.getMessage().contains('Invalid partition'), 
                            'Exception message should indicate Invalid partition');
            }
            try {
                SessionUtils.getCacheValue('04000000000');
            } catch (Exception e) {
                Assert.isTrue(e.getMessage().contains('Invalid partition'), 
                            'Exception message should indicate Invalid partition while getting cache value');
            }
            try {
                SessionUtils.clearCacheValue('04000000000');
            } catch (Exception e) {
                Assert.isTrue(e.getMessage().contains('Invalid partition'), 
                            'Exception message should indicate Invalid partition while clearing cache value');
            }
        }
    }
}