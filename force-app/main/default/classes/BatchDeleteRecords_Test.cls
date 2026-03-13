@isTest(isParallel=true)
private class BatchDeleteRecords_Test {
    static testMethod void test_BatchPurgeRecords() {
        Contact contact = new Contact();
        contact.LastName = 'BatchTestDelteCon';
        insert contact;

        Test.startTest();
        BatchDeleteRecords bch = new BatchDeleteRecords('SELECT Id FROM Contact');
        Database.executeBatch(bch);
        Test.stopTest();

        List<Contact> contacts = [SELECT Id FROM Contact];
        System.assertEquals(0, contacts.size(), 'ERROR: Records not deleted.');
    }
}