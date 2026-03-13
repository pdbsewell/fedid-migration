/**
 * @description       : Test class for EmailRedirectionEventTriggerHandler
 * @author            : Matthew Maramot
 * @group             : Platform
**/
@isTest(isParallel=true)
public with sharing class EmailRedirectionEventTriggerHandler_Test {

    /*******************************************************************************
    * @author       Matthew Maramot
    * @date         8.Apr.2024
    * @description  Test setup
    *******************************************************************************/    
    @testSetup
    static void setup() {
        //Create test routing address
        EmailRoutingAddress testRoutingAddress = new EmailRoutingAddress(Id = fflib_IDGenerator.generate(EmailRoutingAddress.SObjectType),
        Address = 'disabilitysupportservices@test-monash.edu');

        //Create a test enquiry
        Case testCase = TestHelper.webToCaseForms(1)[0];
        testCase.createdDate = System.TODAY().addDays(-32);
        testCase.closedDate = System.TODAY().addDays(-31);
        testCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Admissions').getRecordTypeId();
        insert testCase;

        //Create original & cloned email messages
        List<EmailMessage> attachmentEmail = new List<EmailMessage>();
        attachmentEmail.add(new EmailMessage( ParentId = testCase.id,
        FromAddress = 'testfrom@testmonash.edu',
        FromName = 'testSender',
        Subject = 'testSubject',
        TextBody = 'test body',
        EmailRoutingAddressId = testRoutingAddress.Id,
        Incoming = true,
        MessageIdentifier = '<test1@sfdc.net>',
        ToAddress = 'testEndpoint@monash.edu'
        ));
        
        attachmentEmail.add(new EmailMessage( ParentId = testCase.id,
        FromAddress = 'clonedfrom@testmonash.edu',
        FromName = 'clonedSender',
        Subject = 'clonedSubject',
        TextBody = 'cloned body',
        MessageIdentifier = '<cloned1@sfdc.net>',
        ToAddress = 'clonedEndpoint@monash.edu'
        ));
		insert attachmentEmail;

        //Create attachment
        Attachment att = new Attachment (
            Name = 'Test Attachment',
            Body = Blob.valueOf('Test Attachment Body'),
            ParentId = attachmentEmail[0].Id
        );
        List<Attachment> attachmentList = new List<Attachment>();
        insert att;
    }
    
    /*******************************************************************************
     * @author       Matthew Maramot
     * @date         8.Apr.2024
     * @description  Tests the Clone Attachments platform event 
    *******************************************************************************/ 
	@isTest 
    static void attachmentEvent_Test() {
        
        //GIVEN
        //We have an EmailRedirection Platform Event for Attachment Cloning
        Map<String, Id> messageIdToClonedIdsMap = new Map<String, Id>();
        EmailMessage original = [SELECT Id, MessageIdentifier, EmailRoutingAddressId FROM EmailMessage WHERE Subject ='testSubject'];
        EmailMessage cloned = [SELECT Id, MessageIdentifier FROM EmailMessage WHERE Subject ='clonedSubject'];

        String messageId = emailMessageUtility.getRedirectionId(original) + '@@@@' + original.EmailRoutingAddressId;
        messageIdToClonedIdsMap.put(messageId, cloned.id);

        //Stringify map and create Event record
        String messageIdToClonedIdsString = JSON.serialize(messageIdToClonedIdsMap);
        Email_Redirection_Event__e event = new Email_Redirection_Event__e();
        event.Action__c = 'cloneAttachment';
        event.Parameter__c = messageIdToClonedIdsString;

        
        //WHEN - The Platform Event is published
        //Start test
        Test.startTest();
        EventBus.publish(event);
        Test.stopTest();
          
        //THEN - Attachment linked to original email message is copied to the cloned email message
        List<Attachment> attachmentsListA = [SELECT Id FROM Attachment WHERE ParentId =: original.Id];
        List<Attachment> attachmentsListB = [SELECT Id FROM Attachment WHERE ParentId =: cloned.Id];

        System.assertEquals(1, attachmentsListA.size(), 'Expected attachment is still linked to original email message');
        System.assertEquals(1, attachmentsListB.size(), 'Expected attachment is cloned to cloned email message.');        
    }
}