@isTest(isParallel=true)
private class UserLicenseServices_Test {
	
	private static Map<String, Id> getUserRoleName(){
        Map<String, Id> mapUserRolesByIds = new Map<String, Id>();
        for(UserRole userRole : [Select Id, Name from UserRole]){
            mapUserRolesByIds.put(userRole.Name, userRole.Id);
        }
        return mapUserRolesByIds;
    }
    
	@testSetup
	static void testSetupData(){
	    List<Business_License__c> testBusinessLicenses = new List<Business_License__c>();
	    
		Business_License__c testFacultyLicense = new Business_License__c();
		testFacultyLicense.Name = 'Faculty';
		testFacultyLicense.Baseline_Licenses__c = 100;
		testFacultyLicense.Paid_Licenses__c = 100;
		testBusinessLicenses.add(testFacultyLicense);
		
		Business_License__c testESolutionLicense = new Business_License__c();
		testESolutionLicense.Name = 'eSolutions';
		testESolutionLicense.Baseline_Licenses__c = 100;
		testESolutionLicense.Paid_Licenses__c = 100;
		testBusinessLicenses.add(testESolutionLicense);
		
		Business_License__c testMonashConnectLicense = new Business_License__c();
		testMonashConnectLicense.Name = 'Monash Connect';
		testMonashConnectLicense.Baseline_Licenses__c = 100;
		testMonashConnectLicense.Paid_Licenses__c = 100;
		testBusinessLicenses.add(testMonashConnectLicense);
		
		insert testBusinessLicenses;
		
	}
	
	@isTest static void test_all_scenario() {
		
		Map<String, Id> userRoleMap = getUserRoleName();
	    List<User> testUsers = new List<User>();
	    
		User testFacultyUser = new User();
		testFacultyUser.FirstName = 'TestFirst';
        testFacultyUser.LastName = 'TestLast';
        testFacultyUser.Username = 'Test_Facult_0001@test.org';
        testFacultyUser.Email = 'Test@test.org';
        testFacultyUser.Alias = 'test';
        testFacultyUser.ProfileId = [Select Id FROM Profile WHERE Name = 'Faculty' LIMIT 1].Id;
        testFacultyUser.LanguageLocaleKey='en_US';
        testFacultyUser.EmailEncodingKey='UTF-8';
        testFacultyUser.LocaleSidKey='en_GB';
        testFacultyUser.TimeZoneSidKey='Australia/Sydney';
        testFacultyUser.UserRoleId = userRoleMap.get('Faculty');
		testUsers.add(testFacultyUser);
        
        // FIRST TEST EVENT: INSERTION OF USER
        Test.StartTest();
            insert testUsers;
        Test.StopTest();
        
        
        // SECOND TEST EVENT: CHANGE THE USER'S ROLE
        User updateThisUser = [SELECT Id, UserRoleId FROM User WHERE Id =: testUsers[0].Id];
        updateThisUser.UserRoleId = userRoleMap.get('Monash Connect Leader');
        update updateThisUser;

        
        // THIRD TEST EVENT: REVERT THE CHANGE ROLE
        User updateThisUser2 = [SELECT Id, UserRoleId FROM User WHERE Id =: testUsers[0].Id];
        updateThisUser2.UserRoleId = userRoleMap.get('Faculty');
        update updateThisUser2;
        
        // TEST ASSERTION 1: A UNIT LICENSE MUST BE CREATED RELATED TO THE USER
        List<Role_License__c> createdUnitLicense = [SELECT Id, Status__c FROM Role_License__c WHERE User_Lookup__c =: testUsers[0].Id AND Role__c = 'Faculty'];
        System.Assert(!createdUnitLicense.isEmpty()); // assert that a unit license record looked up to the inserted user is created
        System.AssertEquals('Active', createdUnitLicense[0].Status__c);
        
        //  TEST ASSERTION 2: ROLL UP SUMMARY FOR NEW BUSINESS UNIT MUST UPDATE
        List<Business_License__c> facultyBusinessLicense = [SELECT Id, Total_Active_Licenses__c FROM Business_License__c WHERE Name = 'Faculty'];
        System.assertEquals(1, facultyBusinessLicense[0].Total_Active_Licenses__c);
	}
}