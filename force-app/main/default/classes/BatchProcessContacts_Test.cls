/**
 * @description Test class for BatchProcessContacts
 * @author      Vinothraja
 * @since       12/03/2025
 * @group       Platforms
 */
 @isTest(isParallel=true)
public with sharing class BatchProcessContacts_Test {
    @isTest
    private static void test_BatchProcessContacts() {

        // GIVEN
        // Create Test Contact
        Contact contact = StudFirst_TestHelper.createApplicant();
        insert contact;
        String oldEmail = [SELECT Email FROM Contact WHERE id = :contact.id LIMIT 1].Email;
    
        // WHEN
        Test.startTest();
            // Run Batch
            BatchProcessContacts batch = new BatchProcessContacts('SELECT Id, Email FROM Contact');
            Database.executeBatch(batch);
        Test.stopTest();     

        // THEN
        // Check if the email is updated
        String newEmail = [SELECT Id, Email FROM Contact WHERE id = :contact.id LIMIT 1].Email;
        Assert.areEqual(newEmail, oldEmail + '.test');
    }
}