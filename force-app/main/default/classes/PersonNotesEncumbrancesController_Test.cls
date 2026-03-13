/*
 * @author	Ayush Agrawal (ayush.agrawal@monash.edu)
 * @group	Student Admin
 * @revision	update api version. SS-99
 */

@isTest(isParallel=false) //APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on CustomPermissionSet object: 
private class PersonNotesEncumbrancesController_Test {

    @testSetup
    static void setup() {
        // Campaign.
        List<Campaign> campaigns = new List<Campaign>();
        Campaign campaign_1 = new Campaign(
        	Name = 'One',
            RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Advisory').getRecordTypeId(),
        	StartDate = Date.today()
        );

        campaign_1.EndDate = Date.newInstance(2100, 1, 1);
        campaigns.add(campaign_1);
        
        insert campaigns;
        
        // Contact.
        List<Contact> contacts = new List<Contact>();
        Contact contact_1 = new Contact(
            Birthdate = Date.newInstance(1975, 1, 1),
            LastName = 'LastName',
            Person_Id_Unique__c = '1'
        );
        contacts.add(contact_1);
        
        insert contacts;
        
        // Case.
        List<Case> cases = new List<Case>();
        Case case_1 = new Case(
            Campaign__c = campaign_1.Id,
            Category_Level_1__c = '2',
            ContactId = contact_1.Id,
            Origin = 'My Progress and Support',
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Academic_Progress_Assessment').getRecordTypeId(),
            Submitted_At__c = DateTime.now()
        );
        cases.add(case_1);
        
        insert cases;

        // Person Notes and Encumbrances.
        List<Person_Note__c> personNotes = new List<Person_Note__c>();
        List<Encumbrance__c> encumbrances = new List<Encumbrance__c>();

        for(Contact c : contacts) {
            personNotes.add(new Person_Note__c(Contact__c = c.Id, Expires__c = System.today(), Type__c = 'Type', Important__c = true, Notes__c = 'Test Note'));
            encumbrances.add(new Encumbrance__c(Contact__c = c.Id, enc_category__c = 'ACADEMIC', enc_comments__c = 'Test Encumbrance'));
        }
        insert personNotes;
        insert encumbrances;
    }
	
    // This method tests if the query for retrieving person notes
    // and encumbrances to display on the UI is working or not.
    static testMethod void testGetSpecialCareNotesAndEncumbrances() {
        Test.startTest();
        
        Case c = [SELECT Id FROM Case LIMIT 1];
        
        String jsonResponse = PersonNotesEncumbrancesController.getPersonNotesAndEncumbrances(c.Id, 'ContactId', true);
        PersonNotesEncumbrancesController.Data data = (PersonNotesEncumbrancesController.Data) JSON.deserialize(jsonResponse, PersonNotesEncumbrancesController.Data.class);
        
        Test.stopTest();
        
        Assert.areEqual('Test Note', data.contactRecord.Person_Notes__r[0].Notes__c, 'Person Note query logic is not working.');
        Assert.areEqual('Test Encumbrance', data.contactRecord.Encumbrance__r[0].enc_comments__c, 'Encumbrance query logic is not working.');
    }

    static testMethod void testHasCustomPermission() {
        // Test data setup
        //GIVEN - PermissionSet named PrivateCase
        PermissionSet permissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'PrivateCase' LIMIT 1];
        if (permissionSet == null) {
            permissionSet = new PermissionSet(Name = 'PrivateCase');
            insert permissionSet;
        }
        PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment(
            AssigneeId = UserInfo.getUserId(),
            PermissionSetId = permissionSet.Id
        );
        insert permissionSetAssignment;
        
        //WHEN - Check if the logged in user has the PrivateCase permission set
        Test.startTest();
        // Test the method
        Boolean result = PersonNotesEncumbrancesController.hasCustomPermission();
        Test.stopTest();
        
        //THEN - Should return true as we are assigning the current user the PrivateCase permission set
        Assert.isTrue(result, 'Expected result should be true as the user has the "PrivateCase" permission set');
    }
    
}