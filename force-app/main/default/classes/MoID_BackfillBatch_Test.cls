@isTest
private class MoID_BackfillBatch_Test {

    @testSetup
    static void setup() {
        // 1. Insert standard Contacts. The before insert trigger will auto-mint IDs for them.
        List<Contact> legacyContacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            legacyContacts.add(new Contact(
                FirstName = 'Legacy', 
                LastName = 'User ' + i, 
                Email = 'legacy' + i + '@monash.edu'
            ));
        }
        insert legacyContacts;
        
        // 2. Clear out the MoIDs to simulate old records created before the trigger existed
        for (Contact c : legacyContacts) {
            c.Monash_Object_Id__c = null;
        }
        // Because the trigger only mints on 'before insert', updating them to null here will stick.
        update legacyContacts;
        
        // 3. Create one Contact that successfully keeps its MoID to ensure the batch ignores it
        Contact modernContact = new Contact(
            FirstName = 'Modern', 
            LastName = 'User', 
            Email = 'modern@monash.edu'
        );
        insert modernContact;
    }

    @isTest
    static void testBatchFillsBlankMoIDs() {
        // 1. Assert the starting state (5 blank, 1 populated)
        System.assertEquals(5, [SELECT COUNT() FROM Contact WHERE Monash_Object_Id__c = null], 'Should be 5 legacy records without IDs');
        System.assertEquals(1, [SELECT COUNT() FROM Contact WHERE Monash_Object_Id__c != null], 'Should be 1 modern record with an ID');

        // 2. Execute the Batch
        Test.startTest();
        MoID_BackfillBatch batch = new MoID_BackfillBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // 3. Assert the ending state
        List<Contact> allContacts = [SELECT Id, Monash_Object_Id__c, FirstName FROM Contact];
        
        for (Contact c : allContacts) {
            System.assertNotEquals(null, c.Monash_Object_Id__c, 'Every contact should now have a MoID');
            System.assertEquals(36, c.Monash_Object_Id__c.length(), 'MoID must be exactly 36 characters long');
        }
        
        System.assertEquals(0, [SELECT COUNT() FROM Contact WHERE Monash_Object_Id__c = null], 'No contacts should be left with a blank MoID after the batch finishes');
    }
}