/**
 * @author       P.Victoriano
 * @date         05/Nov/2021
 * @description  Test Class for UserDeactivateBatch
 * @revision
 *               05.Nov.21 P.Victoriano - Create Class
 **/
@IsTest(isParallel = false)
private class UserDeactivateBatch_Test {
    @IsTest
    static void deactivatingUsersItAccountTrue() {
        //Given
        Contact staffContact = (Contact)TestDataFactory.createSObject(new Contact(), 'TestDataFactorySettings.ContactDefaults');
        staffContact.Authcate__c = 'deactUser00001';
        staffContact.IT_account_disabled__c = true;
        insert staffContact;
        System.assertNotEquals(null, staffContact.Id, 'Test Contact record Failed');
        //
        Datetime deactiTime = Datetime.now();
        User staffUser = (User)TestDataFactory.createSObject(new User(), 'TestDataFactorySettings.UserDefaults');
        staffUser.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User']?.Id;
        staffUser.Username = staffUser.Username + '1';
        staffUser.Scheduled_Deactivation__c = deactiTime;
        staffUser.Pending_Deactivation__c = true;
        staffUser.FederationIdentifier = 'deactUser00001';
        staffUser.IsActive = true;
        insert staffUser;
        System.assertNotEquals(null, staffUser.Id, 'Test User record Failed');
        //When
        Test.startTest();
        UserDeactivateBatch batch = new UserDeactivateBatch();
        batch.testUserId = staffUser.Id;
        Database.executeBatch(batch, 1);
        Test.stopTest();
        //Then
        User usr = [SELECT Id,Username,Scheduled_Deactivation__c,Pending_Deactivation__c,Deactivated_DateTime__c,IsActive
                    FROM User WHERE Id =:staffUser.Id LIMIT 1];
        System.assertNotEquals(null, usr.Deactivated_DateTime__c, 'Failed Deactivation Procccess');
    }
    @IsTest
    static void deactivatingUsersThrowsException() {
        //Given
        Datetime deactiTime = Datetime.now();
        User staffUser = (User)TestDataFactory.createSObject(new User(), 'TestDataFactorySettings.UserDefaults');
        staffUser.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User']?.Id;
        staffUser.Username = staffUser.Username + '1';
        staffUser.Scheduled_Deactivation__c = deactiTime;
        staffUser.Pending_Deactivation__c = true;
        staffUser.FederationIdentifier = 'deactUser00001';
        staffUser.Deactivated_DateTime__c = null;
        staffUser.IsActive = true;
        insert staffUser;
        System.assertNotEquals(null, staffUser.Id, 'Test User record Failed');
        //When
        Test.startTest();
        UserDeactivateBatch batch = new UserDeactivateBatch();
        batch.testUserId = staffUser.Id;
        batch.forceError = true;
        Database.executeBatch(batch, 1);
        Test.stopTest();
        //Then
        User usr = [SELECT Id,Username,Scheduled_Deactivation__c,Pending_Deactivation__c,Deactivated_DateTime__c,IsActive
                    FROM User WHERE Id =:staffUser.Id LIMIT 1];
        System.assertEquals(true, usr.IsActive, 'Failed Deactivation Procccess User not active');
    }
}