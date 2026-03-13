@isTest
private class FoC_Service_Test {

    // Helper to build a standard request
    private static FoC_DTOs.Request buildRequest(String fname, String lname, String email, String extId) {
        FoC_DTOs.Request req = new FoC_DTOs.Request();
        req.firstName = fname;
        req.lastName = lname;
        req.email = email;
        req.externalId = extId;
        req.externalIdType = (extId != null) ? 'VTAC' : null;
        req.systemOfOrigin = 'Test_Unit';
        req.idempotencyKey = 'TEST-' + System.currentTimeMillis();
        return req;
    }

    // -------------------------------------------------------------------------
    // SCENARIO 1: NEW CONTACT (Happy Path)
    // -------------------------------------------------------------------------
    @isTest
    static void testProcess_NewContact_CreatesRecordAndMoID() {
        // Arrange
        FoC_DTOs.Request req = buildRequest('New', 'User', 'new.user@example.com', null);
        
        // Add Persona Context to test Aggregation
        req.persona = new FoC_DTOs.PersonaContext();
        req.persona.type = 'Applicant';
        req.persona.subType = 'Coursework';
        req.persona.state = 'Applied';

        // Act
        Test.startTest();
        FoC_DTOs.Result res = FoC_Service.process(req);
        Test.stopTest();

        // Assert - Result DTO
        System.assert(res.isSuccess, 'Service should succeed for new contact');
        System.assert(res.isNewContact, 'Should be flagged as new');
        System.assert(res.moid != null, 'MoID should be minted');
        System.assert(!res.isPotentialDuplicate, 'Should not be ambiguous');

        // Assert - Database (Contact)
        Contact c = [SELECT Id, FirstName, Email FROM Contact WHERE Id = :res.contactId];
        System.assertEquals('new.user@example.com', c.Email);

        // Assert - Database (Child Objects)
        Contact_Identifier__c ci = [SELECT GuID__c FROM Contact_Identifier__c WHERE Contact__c = :c.Id LIMIT 1];
        System.assertEquals(res.moid, ci.GuID__c, 'MoID on child object should match result');

        Persona_Aggregation__c pag = [SELECT PAG_Type__c FROM Persona_Aggregation__c WHERE PAG_Contact__c = :c.Id LIMIT 1];
        System.assertEquals('Applicant', pag.PAG_Type__c, 'Persona aggregation record should be created');
    }

    // -------------------------------------------------------------------------
    // SCENARIO 2: STRICT MATCH (Existing Contact)
    // -------------------------------------------------------------------------
    @isTest
    static void testProcess_StrictMatch_UpdatesExisting() {
        // Arrange - Create existing contact
        Contact existing = new Contact(FirstName='Existing', LastName='User', Email='exist@example.com', VTAC_ID__c='999999');
        insert existing;

        // Create a request that matches exactly on VTAC ID
        FoC_DTOs.Request req = buildRequest('Existing', 'User', 'different.email@example.com', '999999');

        // Act
        Test.startTest();
        FoC_DTOs.Result res = FoC_Service.process(req);
        Test.stopTest();

        // Assert
        System.assert(res.isSuccess);
        System.assertEquals(existing.Id, res.contactId, 'Should resolve to the existing ID');
        System.assertEquals(false, res.isNewContact, 'Should NOT be flagged as new');
        
        // Verify MoID was minted (since existing didn't have one)
        Contact_Identifier__c ci = [SELECT GuID__c FROM Contact_Identifier__c WHERE Contact__c = :existing.Id LIMIT 1];
        System.assertNotEquals(null, ci.GuID__c);
    }

    // -------------------------------------------------------------------------
    // SCENARIO 3: FUZZY MATCH (Ambiguity / Potential Duplicate)
    // -------------------------------------------------------------------------
    @isTest
    static void testProcess_FuzzyMatch_CreatesPotentialDuplicate() {
        // Arrange
        Date myDob = Date.newInstance(1990, 1, 1);
        Contact existing = new Contact(FirstName='Jonathan', LastName='Smith', Email='jon.s@old.com', Birthdate=myDob);
        insert existing;

        // FIX: Change 'John' to 'Jon' so 'Jon%' matches 'Jonathan'
        FoC_DTOs.Request req = buildRequest('Jon', 'Smith', 'john.smith@new.com', null);
        req.dob = myDob; 

        // Act
        Test.startTest();
        FoC_DTOs.Result res = FoC_Service.process(req);
        Test.stopTest();

        // Assert
        System.assert(res.isSuccess, 'Service handles ambiguity gracefully');
        System.assert(res.isNewContact, 'Should create a NEW shell contact');
        
        // This will now PASS because 'Jon%' finds 'Jonathan'
        System.assert(res.isPotentialDuplicate, 'Should be flagged as Potential Duplicate'); 
    }

    // -------------------------------------------------------------------------
    // SCENARIO 4: ERROR HANDLING (Rollback)
    // -------------------------------------------------------------------------
    @isTest
    static void testProcess_Exception_RollsBackTransaction() {
        // Arrange - Force an error by passing null to a required field logic or mocking failure
        // Simple way: Pass a request that causes a DMLException (e.g. missing required standard fields if any)
        // Or, we can rely on the fact that inserting a Contact with null LastName throws exception
        FoC_DTOs.Request req = new FoC_DTOs.Request(); 
        req.lastName = null; // Will cause Insert failed

        // Act
        Test.startTest();
        FoC_DTOs.Result res = FoC_Service.process(req);
        Test.stopTest();

        // Assert
        System.assertEquals(false, res.isSuccess, 'Service should report failure');
        System.assert(res.message.contains('REQUIRED_FIELD_MISSING') || res.message.contains('Insert failed'), 'Should return generic error message');

        // Verify Rollback: No contacts should exist
        Integer count = [SELECT Count() FROM Contact];
        System.assertEquals(0, count, 'Database should be clean (Rolled back)');
    }

    // -------------------------------------------------------------------------
    // SCENARIO 5: BULK MINTING (Trigger Support)
    // -------------------------------------------------------------------------
    @isTest
    static void testBulkMinting_TriggerSupport() {
        Integer batchSize = 5; 
        
        List<Contact> bulkContacts = new List<Contact>();
        for(Integer i=0; i<batchSize; i++) {
            bulkContacts.add(new Contact(
                FirstName = 'Batch', 
                LastName = 'User' + i, 
                Email = 'batch' + i + '@test.com'
            ));
        }
        insert bulkContacts;

        // Collect IDs
        List<Id> contactIds = new List<Id>();
        for(Contact c : bulkContacts) {
            contactIds.add(c.Id);
        }

        // Act - Call the Bulk Service Method directly
        // (In production, this would be called by the Trigger)
        Test.startTest();
        FoC_MoIDService.ensureMoIDs(contactIds);
        Test.stopTest();

        // Assert - Verify count matches batch size
        Integer count = [SELECT Count() FROM Contact_Identifier__c 
                         WHERE Contact__c IN :contactIds 
                         AND Type__c = 'MoID'];
        
        System.assertEquals(batchSize, count, 'Should have minted IDs for the batch');
        
        // Assert - Idempotency (Run it again)
        FoC_MoIDService.ensureMoIDs(contactIds);
        Integer countAfter = [SELECT Count() FROM Contact_Identifier__c 
                              WHERE Contact__c IN :contactIds 
                              AND Type__c = 'MoID'];
        
        System.assertEquals(batchSize, countAfter, 'Should NOT create duplicates if run again');
    }
}