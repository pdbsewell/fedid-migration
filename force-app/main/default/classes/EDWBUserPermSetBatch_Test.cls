/****************************************************************************
@Name: EDWBUserPermSetBatch_Test
@Author: Kevin Evasco (GrowthOps)
@Date: 10/30/2019: Created class. This batch is to be executed only once upon deployment.
********************************************************************************/
@isTest(isParallel=true)
private class EDWBUserPermSetBatch_Test {

    static testMethod void testUserInfoClearout(){
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
        }

        Test.startTest();
			Database.executeBatch(new EDWBUserPermSetBatch());
        Test.stopTest();

		List<PermissionSetAssignment> permSetsAssign = [SELECT PermissionSetId, PermissionSet.Name, AssigneeId, Assignee.Username FROM PermissionSetAssignment WHERE AssigneeId = :userRecord.Id];
        for(PermissionSetAssignment psa : permSetsAssign) {
            System.debug(LoggingLevel.DEBUG, 'UserServices_Test.testAssignPermissionSets: User['+psa.Assignee.Username+'] was assigned with PermissionSet ['+psa.PermissionSet.Name+']');
        }
        System.assert(permSetsAssign.size()>0, 'No permission sets assigned to community user');
    }
}