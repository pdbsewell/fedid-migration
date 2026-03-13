@isTest
private class FoC_OktaHook_Test {

    // Helper to generate the JSON format Okta sends
    private static String generateOktaPayload(String fname, String lname, String email, String vtacId) {
        Map<String, Object> profile = new Map<String, Object>{
            'firstName' => fname,
            'lastName' => lname,
            'email' => email,
            'vtacId' => vtacId 
        };
        
        Map<String, Object> data = new Map<String, Object>{
            'userProfile' => profile
        };
        
        Map<String, Object> root = new Map<String, Object>{
            'data' => data
        };
        
        return JSON.serialize(root);
    }

    @isTest
    static void testResolveIdentity_Success() {
        // 1. Arrange: Prepare the Mock Request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/api/identity/resolve';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(generateOktaPayload('Hook', 'Test', 'hook.test@monash.edu', '987654321'));
        
        // IMPORTANT: Assign to RestContext so the main class can see them
        RestContext.request = req;
        RestContext.response = res;

        // 2. Act: Call the entry point directly
        Test.startTest();
        FoC_OktaHook.resolveIdentity();
        Test.stopTest();

        // 3. Assert: Verify the Response (Status 200 is default)
        System.assertEquals(200, res.statusCode, 'Should return success status');
        System.assertNotEquals(null, res.responseBody, 'Response body should not be empty');

        // 4. Parse the Response to verify Okta Command format
        // Response format: { "commands": [ { "type": "...", "value": { "MoID": "..." } } ] }
        Map<String, Object> respMap = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        List<Object> commands = (List<Object>) respMap.get('commands');
        Map<String, Object> cmd = (Map<String, Object>) commands[0];
        Map<String, Object> val = (Map<String, Object>) cmd.get('value');
        
        String returnedMoID = (String) val.get('MoID');
        
        //  Check for format "XXXX-XXXX-XXXX-XXXX" instead of "MOID-"
        Pattern p = Pattern.compile('\\d{4}-\\d{4}-\\d{4}-\\d{4}');
        Matcher m = p.matcher(returnedMoID);
        System.assert(m.matches(), 'MoID (' + returnedMoID + ') should match format XXXX-XXXX-XXXX-XXXX');
        
        // 5. Verify the Database (Integration Check)
        Contact c = [SELECT Id, FirstName, Email FROM Contact WHERE Email = 'hook.test@monash.edu' LIMIT 1];
        System.assertNotEquals(null, c, 'Contact should have been created in the background');
        
        // Check the Child Object
        Contact_Identifier__c ci = [SELECT GuID__c FROM Contact_Identifier__c WHERE Contact__c = :c.Id LIMIT 1];
        System.assertEquals(returnedMoID, ci.GuID__c, 'Returned MoID should match database record');
    }
}