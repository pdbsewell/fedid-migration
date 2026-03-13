@isTest
private class MoID_Service_Test {

    @isTest
    static void testGenerateMoIDString_Returns16Digits() {
        String generatedId = MoID_Service.generateMoIDString();
        
        System.assertNotEquals(null, generatedId);
        System.assertEquals(36, generatedId.length(), 'MoID string must be exactly 36 characters long');
        System.assert(generatedId.isNumeric(), 'MoID string must contain only numeric characters');
    }

    @isTest
    static void testEnsureMoIDs_MintsWhenBlank() {
        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName = 'Test', LastName = 'Blank', Email = 'blank@test.com')
        };
        
        Test.startTest();
        MoID_Service.ensureMoIDs(contacts);
        Test.stopTest();
        
        System.assertNotEquals(null, contacts[0].Monash_Object_Id__c, 'Service should have populated the blank field');
        System.assertEquals(36, contacts[0].Monash_Object_Id__c.length());
    }

    @isTest
    static void testEnsureMoIDs_SkipsWhenPopulated() {
        String preMintedId = '1234567890123456';
        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName = 'Test', LastName = 'Populated', Email = 'populated@test.com', Monash_Object_Id__c = preMintedId)
        };
        
        Test.startTest();
        MoID_Service.ensureMoIDs(contacts);
        Test.stopTest();
        
        System.assertEquals(preMintedId, contacts[0].Monash_Object_Id__c, 'Service must not overwrite a pre-minted MoID');
    }
}