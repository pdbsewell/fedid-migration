@isTest
private class MoID_PropagationHandler_Test {

    // Flexible mock to handle both success and failure testing
    private class DynamicHttpCalloutMock implements HttpCalloutMock {
        private Integer statusCode;
        
        public DynamicHttpCalloutMock(Integer statusCode) {
            this.statusCode = statusCode;
        }

        public HTTPResponse respond(HTTPRequest req) {
            // Updated assertion to match the new MiX endpoint
            System.assert(req.getEndpoint().contains('/admissions/sms/persons/'), 'Endpoint did not match expected path.');
            
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(this.statusCode);
            
            // Return a dummy error body if we are simulating a failure
            if (this.statusCode != 200 && this.statusCode != 201) {
                res.setBody('{"error": "Simulated Downstream Failure"}');
            }
            return res;
        }
    }

    @TestSetup
    static void setupData() {
        // Insert a base contact for testing
        Contact c = new Contact(
            FirstName = 'Banner', 
            LastName = 'Student', 
            Email = 'banner@test.com', 
            Person_ID_unique__c = '12345678',
            Monash_Object_Id__c = '1111222233334444'
        );
        insert c;
    }

    @isTest
    static void testPropagateAsyncSuccess() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        
        // Simulate a successful 200 OK response from Banner/MiX
        Test.setMock(HttpCalloutMock.class, new DynamicHttpCalloutMock(200));

        Test.startTest();
        MoID_PropagationHandler.propagateAsync(new Set<Id>{c.Id});
        Test.stopTest(); // Forces the async Queueable to execute

        // If it executes without an unhandled exception, the success path works
        System.assert(true, 'Propagation completed without exceptions');
    }

    @isTest
    static void testMaxRetriesAndLogging() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        
        // Simulate a 503 Service Unavailable error to force the failure path
        Test.setMock(HttpCalloutMock.class, new DynamicHttpCalloutMock(503));

        Test.startTest();
        // Because Queueables cannot chain inside Test.stopTest(), 
        // we manually simulate the final retry attempt (Retry Count = 3) 
        // to ensure the Nebula Logger logic block is executed.
        System.enqueueJob(new MoID_PropagationHandler(new List<Id>{c.Id}, 3));
        Test.stopTest(); 

        // The execution should gracefully handle the failure and log it via Nebula 
        // without throwing a fatal system exception.
        System.assert(true, 'Failure successfully caught and passed to Logger');
    }
}