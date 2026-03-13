/**
 * @description       : Test class for LoginAsEventProxyTrigger trigger on LoginAsEventProxy__e platform events.
 * @author            : Jackie Ho
 * @group             : Test
 * @last modified on  : 05-08-2025
 * @last modified by  : Jackie Ho
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   05-08-2025   Jackie Ho       Initial Version
**/
@isTest(isParallel=true)
private class LoginAsEventProxyTrigger_Test {
    @IsTest
    static void testTriggerExecution() {
        // GIVEN: Create 2 users, one with elevated privs CP assigned
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

        // WHEN: Create platform event record
        LoginAsEventProxy__e pe = new LoginAsEventProxy__e (
            DelegatedUsername__c = thisUser.Username,
            Username__c = elevatedPrivsUser.Username,
            UserId__c = elevatedPrivsUser.Id
        );

        Test.startTest();
        // WHEN: Publish the platform event which will invoke the trigger
        Database.SaveResult eventResult = EventBus.publish(pe);
        Test.stopTest();

        // THEN: Verify the event was published successfully
        Assert.isTrue(eventResult.isSuccess(), 'Unable to save platform event');
    }
}