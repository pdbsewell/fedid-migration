@isTest
private class MoID_OktaHook_Test {

    private static String generatePayload(String fname, String lname, String email, String vtacId) {
        return JSON.serialize(new Map<String, Object>{
            'data' => new Map<String, Object>{
                'userProfile' => new Map<String, String>{
                    'firstName' => fname, 'lastName' => lname, 'email' => email, 'vtacId' => vtacId 
                }
            }
        });
    }

    @isTest
    static void testResolve_GeneratesMoIDInMemory_WhenNoMatch() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/api/identity/resolve';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(generatePayload('New', 'User', 'new.user@monash.edu', 'V12345'));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        MoID_OktaHook.resolveIdentity();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        
        // Assert zero Contacts were created (Pass-Through Minting)
        List<Contact> contacts = [SELECT Id FROM Contact WHERE Email = 'new.user@monash.edu'];
        System.assertEquals(0, contacts.size(), 'Hook should NOT perform DML inserts on new users.');
        
        String body = RestContext.response.responseBody.toString();
        System.assert(body.contains('com.okta.user.profile.update'));
        System.assert(body.contains('MoID')); 
    }

    @isTest
    static void testResolve_ReturnsExistingMoID_WhenMatched() {
        String existingId = '9999888877776666';
        Contact c = new Contact(FirstName = 'Existing', LastName = 'User', Email = 'existing@monash.edu', Monash_Object_Id__c = existingId);
        insert c; 
        
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/api/identity/resolve';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(generatePayload('Existing', 'User', 'existing@monash.edu', null));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        MoID_OktaHook.resolveIdentity();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        String body = RestContext.response.responseBody.toString();
        System.assert(body.contains(existingId), 'Response must contain the existing MoID string');
    }

    @isTest
    static void testResolve_UpdatesContact_WhenMatchedButMissingID() {
        Contact c = new Contact(FirstName = 'Legacy', LastName = 'User', Email = 'legacy@monash.edu');
        // Temporarily bypass trigger to insert blank record for test setup if necessary
        insert c; 
        
        // Force field to be blank to simulate legacy record
        c.Monash_Object_Id__c = null;
        update c;

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/api/identity/resolve';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(generatePayload('Legacy', 'User', 'legacy@monash.edu', null));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        MoID_OktaHook.resolveIdentity();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        
        Contact updatedContact = [SELECT Monash_Object_Id__c FROM Contact WHERE Id = :c.Id LIMIT 1];
        System.assertNotEquals(null, updatedContact.Monash_Object_Id__c, 'Hook must update legacy contact with new ID');
        
        String body = RestContext.response.responseBody.toString();
        System.assert(body.contains(updatedContact.Monash_Object_Id__c));
    }
}