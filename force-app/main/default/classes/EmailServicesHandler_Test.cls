/*
 * @author	Ayush Agrawal (ayush.agrawal@monash.edu)
 * @group	Student Admin - Academic Progress
 */

@isTest(isParallel=true)
private class EmailServicesHandler_Test {

    @testSetup
    static void setup() {
        // Campaign.
        List<Campaign> campaigns = new List<Campaign>();
        Campaign campaign_1 = new Campaign(
        	Name = 'One',
            RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Advisory').getRecordTypeId(),
        	StartDate = Date.today(),
            EndDate = Date.today().addDays(1)
        );
        campaigns.add(campaign_1);
        
        insert campaigns;
        
        // Contact.
        List<Contact> contacts = new List<Contact>();
        Contact contact_1 = new Contact(
            Birthdate = Date.newInstance(1975, 1, 1),
            LastName = 'LastName',
            Monash_Email_Address__c = 'test@monash.edu',
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
    }
	
    // This method tests if the email received is successfully created as an
    // EmailMessage and linked to the referenced Case.
    @isTest
    static void testHandleInboundEmail() {
        Case c = [SELECT Id, ContactId, Contact.Monash_Email_Address__c FROM Case LIMIT 1];
        
        Test.startTest();

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        env.FromAddress = 'noreply@a.e.monash.edu';
        
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.Subject = 'Subject';

        email.PlainTextBody = 'ParentId: refParentId:' + c.Id + ':refParentId';
        email.plainTextBody += '\r\n';
        email.plainTextBody += 'ToAddress: refToAddress:' + c.Contact.Monash_Email_Address__c + ':refToAddress';
        email.plainTextBody += '\r\n';
        email.plainTextBody += 'ToId: refToId:' + c.ContactId + ':refToId';
        
        EmailServicesHandler esh = new EmailServicesHandler();
        esh.handleInboundEmail(email, env);

        Test.stopTest();
        
        List<EmailMessage> emailMessages = [SELECT Id FROM EmailMessage WHERE ParentId = :c.Id];
        
        System.assertEquals(1, emailMessages.size(), 'EmailServicesHandler.handleInboundEmail is not working.');
    }
    
}