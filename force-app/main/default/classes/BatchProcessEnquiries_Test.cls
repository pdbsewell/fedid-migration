@isTest(isParallel=true)
private class BatchProcessEnquiries_Test {
    static testMethod void test_processEnquiries() {
        PDTestHelper.createContact();
        PDTestHelper.createEnquiry();


        Test.startTest();
        String query = 'SELECT Id, ContactId, Course__c, Preferred_Time__c, CreatedDate, Legacy_Course_ID__c, Legacy_Contact_ID__c, Legacy_Preferred_Time_ID__c, Legacy_Processed_Flag__c FROM Case';
        BatchProcessEnquiries bch = new BatchProcessEnquiries(query);
        Database.executeBatch(bch);
        Test.stopTest();

        List<Contact> contacts = [SELECT Id FROM Contact];
        System.assertEquals(1, contacts.size(), 'ERROR: Records not deleted.');
    }
}