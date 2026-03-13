@isTest
public class UserEmailUpdateBatch_Test {
    @isTest
    static void testBatchExecute() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User testUser = new User(Firstname='TestLast', Lastname='Test', Username='TestUser@test.com.pauples', 
        Alias='tuser', TimeZonesidKey='Australia/Sydney', LocaleSidKey='en_AU',
        EmailEncodingKey='ISO-8859-1', ProfileID=p.ID, LanguageLocaleKey='en_US', Email='testuser@test.com');

        insert testUser;
        
        System.assert(testUser.id != null, 'Test contact could not be inserted.');

        Test.startTest();
        UserEmailUpdateBatch bch = new UserEmailUpdateBatch();
        Database.executeBatch(bch);
        Test.stopTest();

        System.assertEquals('testuser@test.com.invalid',
        [SELECT Email FROM User WHERE Id = :testUser.id].Email);
    }
    @isTest
    static void testExecute() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User testUser = new User(Firstname='TestLast', Lastname='Test', Username='TestUser@test.com.pauples', 
        Alias='tuser', TimeZonesidKey='Australia/Sydney', LocaleSidKey='en_AU',
        EmailEncodingKey='ISO-8859-1', ProfileID=p.ID, LanguageLocaleKey='en_US', Email='testuser@test.com');

        insert testUser;
        
        System.assert(testUser.id != null, 'Test contact could not be inserted.');

        Test.startTest();
        UserEmailUpdateBatch bch = new UserEmailUpdateBatch();
        bch.execute(null, new List<User>{testUser});
        Test.stopTest();

        System.assertEquals('testuser@test.com.invalid',
        [SELECT Email FROM User WHERE Id = :testUser.id].Email);
    }
}