/**
 * @description       : Test class for trigger handler class for LoginAsEventProxy__e platform events.
 * @author            : Peter Sewell
 * @group             : Test
 * @last modified on  : 2022-01-16
 * @last modified by  : Peter Sewell
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2022-01-16   Peter Sewell    Initial Version
**/
@isTest
private class LoginAsEventProxyTriggerHandler_Test {

	@TestSetup
	static void setup() {

	}

	@IsTest
	static void testDispatch() {
        // Create 2 users, one with elevated privs CP assigned
		String random = String.valueOf(System.currentTimeMillis());
        User thisUser = [SELECT Id, Username FROM User WHERE Id = :UserInfo.getUserId()];

        //Create user assigned ElevatedPrivilegesUser CP/PS
        Profile internalProfile = [SELECT Id FROM Profile WHERE name = 'System Administrator'];
        User elevatedPrivsUser = new User(
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
            Database.insert(elevatedPrivsUser);
			PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = :LoginAsEventProxyTriggerHandler.ELEVATED_PRIVILEGES_CP_NAME];
			PermissionSetAssignment psa = new PermissionSetAssignment(
				PermissionSetId = ps.Id, 
				AssigneeId = elevatedPrivsUser.Id);
				Database.insert(psa);  
        }

		LoginAsEventProxy__e pe = new LoginAsEventProxy__e (
			DelegatedUsername__c = thisUser.Username,
			Username__c = elevatedPrivsUser.Username,
            UserId__c = elevatedPrivsUser.Id
			);

		Test.startTest();
		EventBus.publish(pe);
		Test.stopTest();
	}
}