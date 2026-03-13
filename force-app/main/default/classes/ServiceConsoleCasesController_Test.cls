/*
 * @author	ayush.agrawal@monash.edu
 * @group	Student Administration
 */

@isTest
public class ServiceConsoleCasesController_Test {
	@testSetup
    static void setup() {
        // Contact.
        List<Contact> contacts = new List<Contact>();
        Contact contact_1 = new Contact(
            LastName = 'LastName'
        );
        contacts.add(contact_1);
        
        insert contacts;
        
        // Case.
        List<Case> cases = new List<Case>();
        Case case_1 = new Case(
            ContactId = contact_1.Id
        );
        cases.add(case_1);
        
        Case case_2 = new Case(
            ContactId = contact_1.Id,
            Enquiry_Type__c = 'Vaccinate Monash - Staff',
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Special_Consideration').getRecordTypeId()
        );
        cases.add(case_2);
        
        insert cases;
    }
	
    // Test Mark As Spam for non-sensitive cases.
    @isTest
    static void testMarkAsSpamNonSensitive() {
        Group spamQueue = [SELECT Id FROM Group WHERE DeveloperName = 'Spam' AND Type = 'Queue' LIMIT 1];
        
        Test.startTest();
        
        Case c = [SELECT Id FROM Case WHERE Enquiry_Type__c != 'Vaccinate Monash - Staff' LIMIT 1];
        
        ServiceConsoleCasesController.markAsSpam(c.Id);
        
        Test.stopTest();
        
        Case caseToAssert = [SELECT Id, ContactId, OwnerId FROM Case WHERE Id = :c.Id LIMIT 1];

        System.assertEquals(null, caseToAssert.ContactId, 'Mark As Spam is not working for non-sensitive cases.');
        System.assertEquals(spamQueue.Id, caseToAssert.OwnerId, 'Mark As Spam is not working for non-sensitive cases.');
    }
    
    // Test Mark As Spam for sensitive cases.
    @isTest
    static void testMarkAsSpamSensitive() {
        Group spamQueue = [SELECT Id FROM Group WHERE DeveloperName = 'Spam_Private' AND Type = 'Queue' LIMIT 1];
        
        Test.startTest();
        
        Case c = [SELECT Id FROM Case WHERE Enquiry_Type__c = 'Vaccinate Monash - Staff' LIMIT 1];
        
        ServiceConsoleCasesController.markAsSpam(c.Id);
        
        Test.stopTest();
        
        Case caseToAssert = [SELECT Id, ContactId, OwnerId FROM Case WHERE Id = :c.Id LIMIT 1];
        
        System.assertEquals(null, caseToAssert.ContactId, 'Mark As Spam is not working for sensitive cases.');
        System.assertEquals(spamQueue.Id, caseToAssert.OwnerId, 'Mark As Spam is not working for sensitive cases.');
    }

}