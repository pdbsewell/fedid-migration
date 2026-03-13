/**
 * @description     :   Functional test class for validating the Contact : AS : Update Fields Flow logic.
 *                      This includes verifying record type assignment, deceased status handling,
 *                      marketing opt-out logic, and updates triggered via Person_ID_unique__c or flags like DoNotCall.
 * @author          :   Sachin Shetty
 * @date            :   27-06-2025
 * @group           :   Platforms
 * @revision
 *  27-06-2025      Sachin Shetty    - EPCP-4497  Created test class to test the Contact : AS : Update Fields flow
 */ 
@isTest (isParallel = true)
public class ContactASUpdateFields_FT {
    
    // Static test constant for shared Contact last name used in multiple tests
    static final string testLastname1 = 'Lastname 1234';
    
    /**
     * Prepares test data required for all tests.
     * - Disables Person360 automation
     * - Disables Contact trigger
     * - Inserts a Contact with Record Type 'Role Email Contact'
     */
    @testSetup 
    static void setup() {
        
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;
        
        TriggerCommon.disableTrigger('Contact');
        
        Contact testContact = new Contact(
                                    Firstname='FName', 
                                    Lastname=testLastname1,
            						Person_ID_unique__c = '54321',
        							RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Role Email Contact').getRecordTypeId());
        insert testContact;
        
        TriggerCommon.enableTrigger('Contact');
    }
    
    /**
     * Test method to verify that when a new Contact is created with a Person ID,
     * the Contact's record type is automatically updated to "Student".
     */
    @isTest
    static void testAssignStudentLayoutInsertSuccess() {
        
        // GIVEN : Person360 roll up and roll down and contact trigger are muted since they are not relevant to this test
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;
        
        // Temporarily disable Contact trigger
        TriggerCommon.disableTrigger('Contact');
        
        // WHEN : New Contact is created with Person Id
        String testLastname = 'Lastname ' + String.valueOf(System.now());
        Contact testContact = new Contact(
                                    Firstname='FName', 
                                    Lastname=testLastname,
                                	Person_ID_unique__c = '12345');
        
        // Perform the insert operation within the test context
        Test.startTest();
        	insert testContact;
        Test.stopTest();
        TriggerCommon.enableTrigger('Contact');
        
        // THEN : Retrieve the inserted Contact to verify the record type
        testContact = [SELECT id, RecordType.DeveloperName FROM Contact WHERE Lastname = :testLastname][0];
        // Assert that the Contact was inserted successfully
        Assert.isNotNull(testContact.id, 'Test contact has not been inserted successfully');
        
        // Assert that the Contact's record type was updated to 'Student'
        Assert.areEqual('Student', testContact.RecordType.DeveloperName, 'Contact record type has to be Student');
    }
    
    /** 
     * Verifies that when a new Contact is created **without** a Person ID or SAP Staff ID,
     * the record type is **not updated to 'Student'**. This ensures the record type assignment
     * logic only applies when identifier fields are provided.
     */
    @isTest
    static void testAssignStudentLayoutInsertFailure() {
        
        // GIVEN : Person360 roll up and roll down and contact trigger are muted since they are not relevant to this test
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;
        
        TriggerCommon.disableTrigger('Contact');
        
        // WHEN: New Contact is created without Person_ID_unique__c or SAP Staff ID
        String testLastname = 'Lastname ' + String.valueOf(System.now());
        Contact testContact = new Contact(
                                    Firstname='FName', 
                                    Lastname=testLastname);
        
        // run test
        Test.startTest();
        	insert testContact;
        Test.stopTest();
        TriggerCommon.enableTrigger('Contact');
        
        // THEN: Verify that the Contact was inserted and record type is NOT set to 'Student'
        testContact = [SELECT id, RecordType.DeveloperName FROM Contact WHERE Lastname = :testLastname][0];

        Assert.isNotNull(testContact.id, 'Test contact has not been inserted successfully');
        Assert.areNotEqual('Student', testContact.RecordType.DeveloperName, 'Contact record type should not be Student');
    }
    
    /**
     * If the Person Unique Id on Contact is updated, then contact record type is updated to Student
     */
    @isTest
    static void testAssignStudentLayoutUpdateSuccess() {
        
        // GIVEN : Person360 roll up and roll down and contact trigger are muted since they are not relevant to this test
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;
        
        // WHEN : Contact retrieved for update
        Contact testContact = [SELECT id, RecordType.DeveloperName, Person_ID_unique__c FROM Contact WHERE Lastname = :testLastname1][0];
        
        // Update Person Id on Contact
        testContact.Person_ID_unique__c = '123456';
        
        TriggerCommon.disableTrigger('Contact');
        // run test
        Test.startTest();
        	upsert testContact;
        Test.stopTest();
        TriggerCommon.enableTrigger('Contact');
        
        // THEN : The record type is updated to Student
        testContact = [SELECT id, RecordType.DeveloperName FROM Contact WHERE Lastname = :testLastname1][0];
        Assert.areEqual('Student', testContact.RecordType.DeveloperName, 'Contact record type has to be Student');
    }
    
    /**
     * If the Person Unique Id on Contact is updated to blank, then contact record type is updated to Student
     */
    @isTest
    static void testAssignStudentLayoutUpdateFailure() {
        
        // GIVEN : Person360 roll up and roll down and contact trigger are muted since they are not relevant to this test
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;
        
        // WHEN : Contact retrieved for update
        Contact testContact = [SELECT id, Deceased__c, Person_ID_unique__c FROM Contact WHERE Lastname = :testLastname1][0];
        Test.startTest();
        
        // Update Person Id on Contact is not updated
        testContact.Person_ID_unique__c = '';
        testContact.Deceased__c = true;
        
        TriggerCommon.disableTrigger('Contact');
        // run test
        upsert testContact;
        Test.stopTest();
        TriggerCommon.enableTrigger('Contact');
        
        // THEN : The record type is not updated to Student
        testContact = [SELECT id, RecordType.DeveloperName FROM Contact WHERE Lastname = :testLastname1][0];
        Assert.areNotEqual('Student', testContact.RecordType.DeveloperName, 'Contact record type should not be Student');
    }
    
    /**
     * If the new contact has certain record type, then contact record type is updated to Non_Student.
     */
    @isTest
    static void testAssignNonStudentLayoutInsertSuccess() {
        
        // GIVEN : Person360 roll up and roll down and contact trigger are muted since they are not relevant to this test
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;
        
        TriggerCommon.disableTrigger('Contact');
        
        // WHEN : New Contact of record type Role Email Contact is created
        String testLastname = 'Lastname ' + String.valueOf(System.now());
        Contact testContact = new Contact(
                                    Firstname='FName',
                                    Lastname=testLastname,
        							RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Role Email Contact').getRecordTypeId());
        
        // run test
        Test.startTest();
        	insert testContact;
        Test.stopTest();
        TriggerCommon.enableTrigger('Contact');
        
        // THEN : The record type is updated to Non_Student
        testContact = [SELECT id, RecordType.DeveloperName FROM Contact WHERE Lastname = :testLastname][0];
        // validate contact was stored
        Assert.isNotNull(testContact.id, 'Test contact has not been inserted successfully');
        Assert.areEqual('Non_Student', testContact.RecordType.DeveloperName, 'Contact record type has to be Non Student');
    }
    
    /**
     * If the new contact is of record type Prospective Student, then contact record type is updated to Non_Student.
     */
    @isTest
    static void testAssignNonStudentLayoutInsertFailure() {
        
        // GIVEN : Person360 roll up and roll down and contact trigger are muted since they are not relevant to this test
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;
        
        TriggerCommon.disableTrigger('Contact');
        
        // WHEN : New Contact of record type Role Email Contact is created
        String testLastname = 'Lastname ' + String.valueOf(System.now());
        Contact testContact = new Contact(
                                    Firstname='FName',
                                    Lastname=testLastname,
        							RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Prospective Student').getRecordTypeId());
        
        // run test
        Test.startTest();
        	insert testContact;
        Test.stopTest();
        TriggerCommon.enableTrigger('Contact');
        
        // THEN : The record type is updated to Non_Student
        testContact = [SELECT id, RecordType.DeveloperName FROM Contact WHERE Lastname = :testLastname][0];
        // validate contact was stored
        Assert.isNotNull(testContact.id, 'Test contact has not been inserted successfully');
        Assert.areNotEqual('Non_Student', testContact.RecordType.DeveloperName, 'Contact record type should not be Non Student');
    }
    
    /**
     * If the Person Unique Id on Contact is made blank, then contact record type is updated to Non_Student
     */
    @isTest
        static void testAssignNonStudentLayoutUpdateSuccess() {
        
        // GIVEN : Person360 roll up and roll down and contact trigger are muted since they are not relevant to this test
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;
        
        // WHEN : Contact retrieved for update
        Contact testContact = [SELECT id, RecordType.DeveloperName, RecordTypeId, Person_ID_unique__c FROM Contact WHERE Lastname = :testLastname1][0];
        Assert.areNotEqual('Non_Student', testContact.RecordType.DeveloperName, 'Contact record type should not be Student');
        
        // Update Person Id on Contact
        testContact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Role Email Contact').getRecordTypeId();
        testContact.Person_ID_unique__c = '';
        
        TriggerCommon.disableTrigger('Contact');
        // run test
        Test.startTest();
        	update testContact;
        Test.stopTest();
        TriggerCommon.enableTrigger('Contact');
        
        // THEN : The record type is updated to Student
        testContact = [SELECT id, RecordType.DeveloperName FROM Contact WHERE Lastname = :testLastname1][0];
        Assert.areEqual('Non_Student', testContact.RecordType.DeveloperName, 'Contact record type has to be Non Student');
    }

    /**
     * If the Contact is updated and still has Person Id or SAP Staff Id, then contact record type is not updated to Non_Student
     */
    @isTest
    static void testAssignNonStudentLayoutUpdateFailure() {
        
        // GIVEN : Person360 roll up and roll down and contact trigger are muted since they are not relevant to this test
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;
        
        // WHEN : Contact retrieved for update
        Contact testContact = [SELECT id, RecordType.DeveloperName, Deceased__c FROM Contact WHERE Lastname = :testLastname1][0];
        Assert.areNotEqual('Non_Student', testContact.RecordType.DeveloperName, 'Contact record type should not be Student');
        
        // Update Person Id on Contact
        testContact.Deceased__c = true;
        
        TriggerCommon.disableTrigger('Contact');
        // run test
        Test.startTest();
        	upsert testContact;
        Test.stopTest();
        TriggerCommon.enableTrigger('Contact');
        
        // THEN : The record type is updated to Student
        testContact = [SELECT id, RecordType.DeveloperName FROM Contact WHERE Lastname = :testLastname1][0];
        Assert.areNotEqual('Non_Student', testContact.RecordType.DeveloperName, 'Contact record type should not be Non Student');
    }
    
    /**
     * If a new contact has Deceased marked as True, then the HasOptedOutOfEmail field is set to True
     */
    @isTest
    static void testOptContactOutOfMarketingInsertSuccess() {
        
        // GIVEN : Person360 roll up and roll down and contact trigger are muted since they are not relevant to this test
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;
        
        // WHEN : New Contact with Deceased set to true is created
        String testLastname = 'Lastname ' + String.valueOf(System.now());
        Contact testContact = new Contact(
                                    Firstname='FName',
                                    Lastname=testLastname,
        							Deceased__c = true);
        
        // run test
        TriggerCommon.disableTrigger('Contact');
        Test.startTest();
        	insert testContact;
        Test.stopTest();
        TriggerCommon.enableTrigger('Contact');
        
        // THEN : The record type is updated to Student
        testContact = [SELECT id, HasOptedOutOfEmail FROM Contact WHERE Lastname = :testLastname][0];
        // validate contact was stored
        Assert.isNotNull(testContact.id, 'Test contact has not been inserted successfully');
        Assert.isTrue(testContact.HasOptedOutOfEmail, 'If Deceased opt contact out of marketing');
    }
    
    /**
     * If a new contact has Deceased is not marked as True, then the HasOptedOutOfEmail field is not set to True
     */
    @isTest
    static void testOptContactOutOfMarketingInsertFailure() {
        
        // GIVEN : Person360 roll up and roll down and contact trigger are muted since they are not relevant to this test
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;
        
        TriggerCommon.disableTrigger('Contact');
        
        // WHEN : New Contact with Deceased set to true is created
        String testLastname = 'Lastname ' + String.valueOf(System.now());
        Contact testContact = new Contact(
                                    Firstname='FName',
                                    Lastname=testLastname);
        
        // run test
        Test.startTest();
        	insert testContact;
        Test.stopTest();
        TriggerCommon.enableTrigger('Contact');
        
        // THEN : The record type is updated to Student
        testContact = [SELECT id, HasOptedOutOfEmail FROM Contact WHERE Lastname = :testLastname][0];
        // validate contact was stored
        Assert.isNotNull(testContact.id, 'Test contact has not been inserted successfully');
        Assert.isFalse(testContact.HasOptedOutOfEmail, 'Opt contact out of marketing should not be set');
    }
    
    /**
     * If a contact is updated by marking Deceased as True, then the HasOptedOutOfEmail field is set to True
     */
    @isTest
        static void testOptContactOutOfMarketingUpdateSuccess() {
        
        // GIVEN : Person360 roll up and roll down and contact trigger are muted since they are not relevant to this test
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;
        
        // WHEN : Contact retrieved for update
        Contact testContact = [SELECT id, HasOptedOutOfEmail, Deceased__c FROM Contact WHERE Lastname = :testLastname1][0];
        Assert.isFalse(testContact.HasOptedOutOfEmail, 'Opt contact out of marketing should not be set');
        
        // Update Person Id on Contact
        testContact.Deceased__c = true;
        
        TriggerCommon.disableTrigger('Contact');
        // run test
        Test.startTest();
        	update testContact;
        Test.stopTest();
        TriggerCommon.enableTrigger('Contact');
        
        // THEN : The record type is updated to Student
        testContact = [SELECT id, HasOptedOutOfEmail FROM Contact WHERE Lastname = :testLastname1][0];
        Assert.isTrue(testContact.HasOptedOutOfEmail, 'If Deceased opt contact out of marketing');
    }
    
    /**
     * If a contact is updated but Deceased field is not update to True, then the HasOptedOutOfEmail field is  not set to True
     */
    @isTest
        static void testOptContactOutOfMarketingUpdateFailure() {
        
        // GIVEN : Person360 roll up and roll down and contact trigger are muted since they are not relevant to this test
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;
        
        // WHEN : Contact retrieved for update
        Contact testContact = [SELECT id, HasOptedOutOfEmail, Deceased__c FROM Contact WHERE Lastname = :testLastname1][0];
        Assert.isFalse(testContact.HasOptedOutOfEmail, 'Opt contact out of marketing should not be set');
        
        // Update to Contact but not deceased
        testContact.Person_ID_unique__c = '222';
        
        TriggerCommon.disableTrigger('Contact');
        // run test
        Test.startTest();
        	update testContact;
        Test.stopTest();
        TriggerCommon.enableTrigger('Contact');
        
        // THEN : The record type is updated to Student
        testContact = [SELECT id, HasOptedOutOfEmail FROM Contact WHERE Lastname = :testLastname1][0];
        Assert.isFalse(testContact.HasOptedOutOfEmail, 'Opt contact out of marketing should not be set');
    }
    
    /**
     * If a new contact is created with Marketing Communications Status is Opted In and Do Not Call is True, 
     * then the Marketing Communications Status field is set to Opted out
     */
    @isTest
    static void testMarketingStatusOptedOutDoNotCallInsertSuccess() {
        
        // GIVEN : Person360 roll up and roll down and contact trigger are muted since they are not relevant to this test
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;

        TriggerCommon.disableTrigger('Contact');
        
        // WHEN : New Contact with Marketing_Communications_Status Opted In is created but Do Not Call is Set
        String testLastname = 'Lastname ' + String.valueOf(System.now());
        Contact testContact = new Contact(
                                    Firstname='FName',
                                    Lastname=testLastname,
            						Marketing_Communications_Status__c = 'Opted in',
            						DoNotCall = True);
        
        // run test
        Test.startTest();
        	insert testContact;
        Test.stopTest();
        TriggerCommon.enableTrigger('Contact');
        
        testContact = [SELECT id, Marketing_Communications_Status__c FROM Contact WHERE Lastname = :testLastname][0];
        // validate contact was stored
        Assert.areEqual('Opted out',testContact.Marketing_Communications_Status__c, 'Marketing Communication Status should be Opted Out');
    }
    
    /**
     * If a new contact is created with Marketing Communications Status is Opted In but Do Not Call is False, 
     * then the Marketing Communications Status field is not set to Opted out
     */
    @isTest
    static void testMarketingStatusOptedOutDoNotCallInsertFailure() {
        
        // GIVEN : Person360 roll up and roll down and contact trigger are muted since they are not relevant to this test
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;

        TriggerCommon.disableTrigger('Contact');
        
        // WHEN : New Contact with Marketing_Communications_Status Opted In is created but Do Not Call is Set
        String testLastname = 'Lastname ' + String.valueOf(System.now());
        Contact testContact = new Contact(
                                    Firstname='FName',
                                    Lastname=testLastname,
            						Marketing_Communications_Status__c = 'Opted in',
            						DoNotCall = false);
        
        // run test
        Test.startTest();
        	insert testContact;
        Test.stopTest();
        TriggerCommon.enableTrigger('Contact');
        
        testContact = [SELECT id, Marketing_Communications_Status__c FROM Contact WHERE Lastname = :testLastname][0];
        // validate contact was stored
        Assert.areNotEqual('Opted out',testContact.Marketing_Communications_Status__c, 'Marketing Communication Status should not be Opted Out');
    }
    
    /**
     * If a contact is has Marketing Communications Status as Opted In and Do Not Call is updated to True, 
     * then the Marketing Communications Status field is set to Opted out
     */
    @isTest
    static void testMarketingStatusOptedOutDoNotCallUpdateSuccess() {
        
        // GIVEN : Person360 roll up and roll down and contact trigger are muted since they are not relevant to this test
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;

        // Temporarily disable Contact trigger logic to isolate the test conditions
        TriggerCommon.disableTrigger('Contact');
        
        // Retrieve a test Contact and assert that it is not already opted out
        Contact testContact = [SELECT id, Marketing_Communications_Status__c, DoNotCall FROM Contact WHERE Lastname = :testLastname1][0];
        Assert.areNotEqual('Opted out',testContact.Marketing_Communications_Status__c, 'Marketing Communication Status should not be Opted out');
        
        // WHEN : Set Do Not Call to true on the Contact
        testContact.DoNotCall = true;
        
        // Perform the update inside a Test context to trigger any logic that might run
        Test.startTest();
        	update testContact;
        Test.stopTest();
        
        // Re-enable the Contact trigger logic
        TriggerCommon.enableTrigger('Contact');
        
        // THEN : Re-query the Contact to verify that the Marketing_Communications_Status__c was updated to 'Opted out'
        testContact = [SELECT id, Marketing_Communications_Status__c FROM Contact WHERE Lastname = :testLastname1][0];
        // Assert that the status has changed as expected
        Assert.areEqual('Opted out',testContact.Marketing_Communications_Status__c, 'Marketing Communication Status should be Opted Out');
    }

    /**
     * Test case: If a Contact has Marketing Communications Status set to 'Opted In' and 
     * Do Not Call is updated to **false**, then the Marketing Communications Status 
     * should remain unchanged (i.e., should NOT be set to 'Opted out').
     */
    @isTest
    static void testMarketingStatusOptedOutDoNotCallUpdateFailure() {
        
        // GIVEN : Disable Person360 roll-up/down logic and Contact triggers to isolate the test scenario
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;

        // Disable Contact trigger logic temporarily
        TriggerCommon.disableTrigger('Contact');
        
        // Retrieve an existing test Contact and verify that it's not already marked as 'Opted out'
        Contact testContact = [SELECT id, Marketing_Communications_Status__c, DoNotCall FROM Contact WHERE Lastname = :testLastname1][0];
        Assert.areNotEqual('Opted out',testContact.Marketing_Communications_Status__c, 'Marketing Communication Status should not be Opted out');
        
        // WHEN : Set Do Not Call to false (should not trigger any change in Marketing Status)
        testContact.DoNotCall = false;
        
        // Perform update inside a test context to capture any automation
        Test.startTest();
        	update testContact;
        Test.stopTest();
        
        // Re-enable Contact trigger logic
        TriggerCommon.enableTrigger('Contact');
        
        // THEN : Re-query the Contact and verify the Marketing Status was NOT changed to 'Opted out'
        testContact = [SELECT id, Marketing_Communications_Status__c FROM Contact WHERE Lastname = :testLastname1][0];
        Assert.areNotEqual('Opted out',testContact.Marketing_Communications_Status__c, 'Marketing Communication Status should not be Opted out');
    }
    
    /**
     * Test method validating that when a Contact is inserted with:
     * - Marketing Communications Status set to 'Opted in'
     * - Email Opt-Out set to true
     * 
     * THEN:
     * - The Contact’s Marketing Communications Status should be updated to 'Opted out'
     */
    @isTest
    static void testMarketingStatusOptOutedEmailOptOutInsertSuccess() {
        
        // GIVEN : Disable Person360 roll-up/down logic and Contact trigger to isolate test behavior
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;

        // Disable Contact trigger logic temporarily
        TriggerCommon.disableTrigger('Contact');
        
        // WHEN : Create a new test Contact with:
        // - 'Opted in' Marketing Status
        // - Email opt-out set to true
        String testLastname = 'Lastname ' + String.valueOf(System.now());
        Contact testContact = new Contact(
                                    Firstname='FName',
                                    Lastname=testLastname,
            						Marketing_Communications_Status__c = 'Opted in',
            						HasOptedOutOfEmail = True);
        
        // Insert the Contact and trigger automation logic
        Test.startTest();
        	insert testContact;
        Test.stopTest();
        TriggerCommon.enableTrigger('Contact');
        
        // THEN : Re-query the inserted Contact to verify that the Marketing Status was updated
        testContact = [SELECT id, Marketing_Communications_Status__c FROM Contact WHERE Lastname = :testLastname][0];
        // Validate that the Marketing Status was updated to 'Opted out' due to email opt-out
        Assert.areEqual('Opted out',testContact.Marketing_Communications_Status__c, 'Marketing Communication Status should be Opted Out');
    }
    
    /**
     * Test method validating that when a Contact is inserted with:
     * - Marketing Communications Status set to 'Opted in'
     * - Email Opt-Out set to false
     *
     * THEN:
     * - The Marketing Communications Status should remain 'Opted in'
     * - No automatic update to 'Opted out' should occur
     */
    @isTest
    static void testMarketingStatusOptOutedEmailOptOutInsertFailure() {
        
        // GIVEN : Person360 roll up and roll down and contact trigger are muted since they are not relevant to this test
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;

        // Disable Contact trigger logic temporarily
        TriggerCommon.disableTrigger('Contact');
        
        // WHEN :
        // Create a new Contact with:
    	// - 'Opted in' status
    	// - Email opt-out set to false (should NOT trigger a marketing status update)
        String testLastname = 'Lastname ' + String.valueOf(System.now());
        Contact testContact = new Contact(
                                    Firstname='FName',
                                    Lastname=testLastname,
            						Marketing_Communications_Status__c = 'Opted in',
            						HasOptedOutOfEmail = false);
        
        // Insert the contact and trigger automation logic
        Test.startTest();
        	insert testContact;
        Test.stopTest();
        
        // Re-enable Contact triggers
        TriggerCommon.enableTrigger('Contact');
        
        // THEN : Re-query the inserted Contact and confirm the marketing status remains unchanged
        testContact = [SELECT id, Marketing_Communications_Status__c FROM Contact WHERE Lastname = :testLastname][0];
        // Ensure that the Marketing Status was NOT updated to 'Opted out'
        Assert.areNotEqual('Opted out',testContact.Marketing_Communications_Status__c, 'Marketing Communication Status should not be Opted Out');
    }
    
    /**
     * Test method validating that when an existing Contact is updated to:
     * - Marketing Communications Status = 'Opted in'
     * - HasOptedOutOfEmail = true
     * 
     * THEN:
     * - The system should automatically update the Marketing Communications Status to 'Opted out'
     */
    @isTest
    static void testMarketingStatusOptOutedEmailOptOutUpdateSuccess() {
        
        // GIVEN : Person360 roll up and roll down and contact trigger are muted since they are not relevant to this test
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;

        // Disable Contact trigger logic temporarily
        TriggerCommon.disableTrigger('Contact');
        
        // WHEN : New Contact with Marketing_Communications_Status Opted In is created but has opted out of Email
        Contact testContact = [SELECT id, Marketing_Communications_Status__c, HasOptedOutOfEmail FROM Contact WHERE Lastname = :testLastname1][0];
        // Confirm precondition: Contact is not already marked as 'Opted out'
        Assert.areNotEqual('Opted out',testContact.Marketing_Communications_Status__c, 'Marketing Communication Status should not be Opted Out');
        
        // Set Marketing Status to 'Opted in' and opt the user out of email communication
        testContact.Marketing_Communications_Status__c = 'Opted in';
        testContact.HasOptedOutOfEmail = True;
        
        // Perform update in test context to trigger automation logic
        Test.startTest();
        	update testContact;
        Test.stopTest();
        
        // Re-enable Contact trigger
        TriggerCommon.enableTrigger('Contact');
        
        // THEN : Re-query the Contact and validate that the Marketing Status has been updated to 'Opted out'
        testContact = [SELECT id, Marketing_Communications_Status__c FROM Contact WHERE Lastname = :testLastname1][0];
        // Assert the expected change occurred
        Assert.areEqual('Opted out',testContact.Marketing_Communications_Status__c, 'Marketing Communication Status should be Opted Out');
    }
    
    /**
     * Test method validating that when an existing Contact is updated:
     * - WITHOUT setting HasOptedOutOfEmail = true
     * - And with no relevant change to marketing preferences
     * 
     * THEN:
     * - The Marketing Communications Status should remain unchanged (i.e., not set to 'Opted out')
     */
    @isTest
    static void testMarketingStatusOptOutedEmailOptOutUpdateFailure() {
        
        // GIVEN : Person360 roll up and roll down and contact trigger are muted since they are not relevant to this test
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;

        // Disable Contact trigger logic temporarily
        TriggerCommon.disableTrigger('Contact');
        
        // Retrieve an existing test Contact
        Contact testContact = [SELECT id, Marketing_Communications_Status__c, Faculty_Portfolio_Code__c FROM Contact WHERE Lastname = :testLastname1][0];
        // Ensure the Contact is not already marked as 'Opted out'
        Assert.areNotEqual('Opted out',testContact.Marketing_Communications_Status__c, 'Marketing Communication Status should not be Opted Out');
        
        // WHEN :
        // Update a non-marketing-related field (Faculty_Portfolio_Code__c)
        // This should not affect the Marketing Communications Status
        testContact.Faculty_Portfolio_Code__c = '123';
        
        // Execute the update
        Test.startTest();
        	update testContact;
        Test.stopTest();
        
        // Re-enable Contact trigger
        TriggerCommon.enableTrigger('Contact');
        
        // THEN : Re-query the Contact to verify that the Marketing Communications Status has not changed
        testContact = [SELECT id, Marketing_Communications_Status__c FROM Contact WHERE Lastname = :testLastname1][0];
        // Assert that Marketing Communications Status was NOT incorrectly set to 'Opted out'
        Assert.areNotEqual('Opted out',testContact.Marketing_Communications_Status__c, 'Marketing Communication Status should not be Opted Out');
    }
    
    /**
     * Test method validating that when a Contact is inserted with:
     * - No Account (null AccountId)
     * - Marketing Communications Status set to 'Opted in'
     * - Deceased__c set to true
     *
     * THEN:
     * - A new Account of type 'Individual' is created (implied)
     * - The Marketing Communications Status is automatically updated to 'Opted out'
     */
    @isTest
    static void testMarketingStatusOptedOutDeceasedInsertSuccess() {
        
        // GIVEN : Person360 roll up and roll down and contact trigger are muted since they are not relevant to this test
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;

        // Temporarily disable the Contact trigger to isolate test logic
        TriggerCommon.disableTrigger('Contact');
        
        // WHEN : Create a test Contact with:
        // - 'Opted in' Marketing Status
        // - Deceased__c = true
        String testLastname = 'Lastname ' + String.valueOf(System.now());
        Contact testContact = new Contact(
                                    Firstname='FName',
                                    Lastname=testLastname,
        							Deceased__c = true,
            						Marketing_Communications_Status__c = 'Opted in');
        
        // Insert the Contact and allow automation to run
        Test.startTest();
        	insert testContact;
        Test.stopTest();
        
        // Re-enable Contact trigger
        TriggerCommon.enableTrigger('Contact');
        
        // THEN : Re-query the Contact to verify that Marketing Status was updated
        testContact = [SELECT id, Marketing_Communications_Status__c FROM Contact WHERE Lastname = :testLastname][0];
        // Validate that the Marketing Communications Status was updated to 'Opted out'
        Assert.areEqual('Opted out',testContact.Marketing_Communications_Status__c, 'Marketing Communication Status should be Opted Out');
    }
    
    /**
     * Test method validating that when a Contact is inserted with:
     * - Marketing Communications Status set to 'Opted in'
     * - Deceased__c = false
     * 
     * THEN:
     * - The Marketing Communications Status should remain 'Opted in' (not automatically set to 'Opted out')
     * - This ensures that the deceased logic is only applied when Deceased__c = true
     */
    @isTest
    static void testMarketingStatusOptedOutDeceasedInsertFailure() {
        
        // GIVEN : Person360 roll up and roll down and contact trigger are muted since they are not relevant to this test
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;

        // Temporarily disable the Contact trigger to isolate test logic
        TriggerCommon.disableTrigger('Contact');
        
        // Create a test Contact with:
        // - Deceased__c = false
        // - Marketing_Communications_Status__c = 'Opted in'
        // This scenario should NOT trigger a marketing status update
        String testLastname = 'Lastname ' + String.valueOf(System.now());
        Contact testContact = new Contact(
                                    Firstname='FName',
                                    Lastname=testLastname,
        							Deceased__c = false,
            						Marketing_Communications_Status__c = 'Opted in');
        
        // WHEN : Insert the Contact record
        Test.startTest();
        	insert testContact;
        Test.stopTest();
        
        // Re-enable Contact trigger
        TriggerCommon.enableTrigger('Contact');
        
        // THEN : Query the Contact to validate that the Marketing Status remains unchanged
        testContact = [SELECT id, Marketing_Communications_Status__c FROM Contact WHERE Lastname = :testLastname][0];
        // Assert that the Marketing Status was NOT incorrectly changed to 'Opted out'
        Assert.areNotEqual('Opted out',testContact.Marketing_Communications_Status__c, 'Marketing Communication Status should not be Opted out');
    }
    
    /**
     * Test method validating that when an existing Contact is updated to:
     * - Deceased__c = true
     * - While Marketing Communications Status is 'Opted in'
     *
     * THEN:
     * - The Marketing Communications Status should automatically update to 'Opted out'
     */
    @isTest
    static void testMarketingStatusOptedOutDeceasedUpdateSuccess() {
        
        // GIVEN : Person360 roll up and roll down and contact trigger are muted since they are not relevant to this test
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;

        // Temporarily disable the Contact trigger to isolate test logic
        TriggerCommon.disableTrigger('Contact');
        
        // Retrieve an existing test Contact record
        Contact testContact = [SELECT id, Marketing_Communications_Status__c, Deceased__c FROM Contact WHERE Lastname = :testLastname1][0];
        
        // Assert preconditions to ensure test starts with a valid state
        Assert.areEqual(False, testContact.Deceased__c, 'Deceased should not be set');
        Assert.areNotEqual('Opted out',testContact.Marketing_Communications_Status__c, 'Marketing Communication Status should not be Opted Out');
        
        // WHEN : Mark the contact as deceased
        testContact.Deceased__c = True;
            
        // Update the contact to trigger automation
        Test.startTest();
        	update testContact;
        Test.stopTest();
        
        // Re-enable Contact trigger logic
        TriggerCommon.enableTrigger('Contact');
        
        // THEN : Re-query the Contact record to verify post-update values
        testContact = [SELECT id, Marketing_Communications_Status__c FROM Contact WHERE Lastname = :testLastname1][0];
        // Assert that Marketing Status was updated to 'Opted out'
        Assert.areEqual('Opted out',testContact.Marketing_Communications_Status__c, 'Marketing Communication Status should be Opted Out');
    }
    
    /**
     * Test method validating that when a Contact is updated:
     * - WITHOUT changing Deceased__c to true
     * - And only a non-marketing-related field is changed (Faculty_Portfolio_Code__c)
     * 
     * THEN:
     * - The Marketing Communications Status should remain unchanged (i.e., not set to 'Opted out')
     */
    @isTest
    static void testMarketingStatusOptedOutDeceasedUpdateFailure() {
        
        // GIVEN : Person360 roll up and roll down and contact trigger are muted since they are not relevant to this test
        Person360Muting__c cs = Person360Muting__c.getOrgDefaults();
        cs.Run_Roll_Up_Asynchronously__c = false;
        cs.Enable_Roll_Up__c = false;
        cs.Enable_Roll_Down__c = false;
        upsert cs;

        // Temporarily disable the Contact trigger to isolate test logic
        TriggerCommon.disableTrigger('Contact');
        
        // Fetch a test Contact record
        Contact testContact = [SELECT id, Marketing_Communications_Status__c, Deceased__c, Faculty_Portfolio_Code__c FROM Contact WHERE Lastname = :testLastname1][0];
        
        // Validate initial state
        Assert.areEqual(False, testContact.Deceased__c, 'Deceased should not be set');
        Assert.areNotEqual('Opted out',testContact.Marketing_Communications_Status__c, 'Marketing Communication Status should not be Opted Out');
        
        // WHEN : Update a non-marketing-related field (Faculty_Portfolio_Code__c) only
        testContact.Faculty_Portfolio_Code__c = '123';
            
        // Perform the update within a test context
        Test.startTest();
        	update testContact;
        Test.stopTest();
        
        // Re-enable Contact trigger after test
        TriggerCommon.enableTrigger('Contact');
        
        // THEN : Re-query the Contact record to check the post-update status
        testContact = [SELECT id, Marketing_Communications_Status__c FROM Contact WHERE Lastname = :testLastname1][0];
        // Assert that the Marketing Status was not incorrectly changed to 'Opted out'
        Assert.areNotEqual('Opted out',testContact.Marketing_Communications_Status__c, 'Marketing Communication Status should not be Opted Out');
    }
}