/**
 * @description       : Test Class for Email Message : AI: Manage Case & Message Update
 * @author            : Jackie Ho
 * @group             : 
 * @last modified on  : 27-08-2025
 * @last modified by  : Jackie Ho
**/
@isTest(isParallel=true)
public with sharing class EmailMessageAIManageCaseMessageUpdate_FT {
    @testSetup
    /**
    * @description  : Common setup for all test methods
    **/
    static void setupTestData() {
        // GIVEN: Common setup for all test methods
        insert new Bypass_Mute_Request__c(Bypass_All_Flows__c=false);
        TriggerCommon.disableTrigger('Contact');
        TriggerCommon.disableTrigger('Case');

        // GIVEN: Create a test applicant
        Contact testApplicant = new Contact(
            LastName = 'TestApplicant', 
            MailingCountry = 'Malaysia'
        );
        insert testApplicant;
        
        // GIVEN: Create a test application
        Application__c application = new Application__c();
        application.Callista_Application_Id__c = 'CAID-1239090';
        application.Fee_Payment__c = false;
        application.Fee_Waiver_Redeemed__c = 'Test';    
        application.Refused_entry_visa_to_any_country__c = 'Yes';
        application.Breached_visa_condition__c = 'Yes';
        application.Medical_health_prevent_visa__c = 'Yes';
        application.Protection_visa_in_any_country__c = 'Yes';
        application.Convicted_of_crime_offence__c = 'Yes';
        application.HasDisabilities__c = 'Yes';
        application.Submission_Progress__c = 'Submit';
        application.Assessment_Status__c = 'Required';
        application.Applicant__c = testApplicant.Id;
        insert application;
        
        // GIVEN: Create a test ACP for the application
        Application_Course_Preference__c acp = new Application_Course_Preference__c();
        acp.Admissions_Assessment_Status__c = 'Not Started';
        acp.Application__c = application.Id;
        acp.Workflow_Status__c = 'On Hold';
        acp.On_Hold_Reason__c ='Applicant Input required';
        acp.Release_Reason__c = '';
        insert acp;
        
        // GIVEN: Create a test enquiry for the application
        Case testEnquiry = new Case();
        testEnquiry.status = 'Open';
        testEnquiry.Application_Course_Preference__c = acp.Id;
        insert testEnquiry;

        TriggerCommon.enableTrigger('Contact');
        TriggerCommon.enableTrigger('Case');
    }
    
    @isTest
    /**
    * @description  : Test method for creating email message with insurance enquiry
    **/
    static void testCreateEmailMessageWithInsuranceEnquiry() {
        Case testEnquiry = [
            Select Id 
            From Case 
            ORDER BY CreatedDate DESC 
            LIMIT 1];
        testEnquiry.recordTypeId = (
            Schema.SObjectType.Case
            .getRecordTypeInfosByName()
            .get('Insurance Enquiry')
            .getRecordTypeId());
        update testEnquiry;

        // Create Email Message for Enquiry for application
        EmailMessage testEmailMessage =  new EmailMessage(
            ParentId = testEnquiry.Id,
            FromName = 'testSender',
            HTMLBody = 'test',
            Subject = 'testSubject',
            TextBody = 'test body',
            Incoming = true);
        
        Test.startTest();
        // WHEN : Email Sent for linked Enquiry
        insert testEmailMessage;
        Test.stopTest();
        
        // THEN : Check for Latest Inbound Email on Enquiry
        Case testEnquiryRetrieved = [
            Select Id, 
            ParentId, 
            Latest_Inbound_Email__c, 
            Mark_as_read__c 
            from Case 
            where Id = :testEnquiry.Id];
        Assert.isNotNull(
            testEnquiryRetrieved.Latest_Inbound_Email__c, 
            'Latest Inbound Email should not be null');
        Assert.areEqual(
            false, 
            testEnquiryRetrieved.Mark_as_read__c, 
            'Mark as read should be false');
    }

    @isTest
    /**
    * @description  : Test method for creating email message with DSS enquiry
    **/
    static void testCreateEmailMessageWithDSSEnquiry() {
        Case testEnquiry = [
            Select Id 
            From Case 
            ORDER BY CreatedDate DESC 
            LIMIT 1];
        testEnquiry.recordTypeId = (
            Schema.SObjectType.Case
            .getRecordTypeInfosByName()
            .get('Disability Support Services Enquiry')
            .getRecordTypeId());
        update testEnquiry;

        // Create Email Message for Enquiry for application
        EmailMessage testEmailMessage =  new EmailMessage(
            ParentId = testEnquiry.Id,
            FromName = 'testSender',
            HTMLBody = 'test',
            Subject = 'testSubject',
            TextBody = 'test body',
            MessageDate = System.today(),
            Incoming = true);
        
        Test.startTest();
        // WHEN : Email Sent for linked Enquiry
        insert testEmailMessage;
        Test.stopTest();
        
        // THEN : Check for Latest Inbound Email on Enquiry
        Case testEnquiryRetrieved = [
            Select Id, 
            ParentId, 
            Latest_Inbound_Email__c
            from Case 
            where Id = :testEnquiry.Id];
        Assert.isNotNull(
            testEnquiryRetrieved.Latest_Inbound_Email__c, 
            'Latest Inbound Email should not be null');
    }

    @isTest
    /**
    * @description  : Test method for creating email message with myResearch enquiry
    **/
    static void testCreateEmailMessageWithmyResearchEnquiry() {
        Case testEnquiry = [
            Select Id 
            From Case 
            ORDER BY CreatedDate DESC 
            LIMIT 1];
        testEnquiry.recordTypeId = (
            Schema.SObjectType.Case
            .getRecordTypeInfosByName()
            .get('myResearch')
            .getRecordTypeId());
        update testEnquiry;

        // Create Email Message for Enquiry for application
        EmailMessage testEmailMessage =  new EmailMessage(
            ParentId = testEnquiry.Id,
            FromName = 'testSender',
            HTMLBody = 'test',
            Subject = 'testSubject',
            TextBody = 'test body',
            Incoming = true);
        
        Test.startTest();
        // WHEN : Email Sent for linked Enquiry
        insert testEmailMessage;
        Test.stopTest();
        
        // THEN : Check for Latest Inbound Email on Enquiry
        Case testEnquiryRetrieved = [
            Select Id, 
            ParentId, 
            Latest_Inbound_Email__c, 
            Recent_Inbound_Email__c, 
            Mark_as_read__c 
            from Case 
            where Id = :testEnquiry.Id];
        Assert.isNotNull(
            testEnquiryRetrieved.Latest_Inbound_Email__c, 
            'Latest Inbound Email should not be null');
        Assert.isNotNull(
            testEnquiryRetrieved.Recent_Inbound_Email__c, 
            'Recent Inbound Email should not be null');
    }

    @isTest
    /**
    * @description  : Test method for creating email message with myResearch enquiry
    **/
    static void testIfEmailMessageHasAttachment() {
        Case testEnquiry = [
            Select Id 
            From Case 
            ORDER BY CreatedDate DESC 
            LIMIT 1];
        testEnquiry.recordTypeId = (
            Schema.SObjectType.Case
            .getRecordTypeInfosByName()
            .get('myResearch')
            .getRecordTypeId());
        update testEnquiry;

        // Create Email Message for Enquiry for application`
        EmailMessage testEmailMessage = new EmailMessage();
        testEmailMessage = (EmailMessage) fflib_ApexMocksUtils.setReadOnlyFields(
            testEmailMessage,
            EmailMessage.class,
                new Map<SObjectField, Object> {
                    EmailMessage.HasAttachment => true
                }
            );
        testEmailMessage.ParentId = testEnquiry.Id;
        testEmailMessage.FromName = 'testSender';
        testEmailMessage.HTMLBody = 'test';
        testEmailMessage.Subject = 'testSubject';
        testEmailMessage.TextBody = 'test body';
        testEmailMessage.Incoming = true;
        
        Test.startTest();
        // WHEN : Email Sent for linked Enquiry
        insert testEmailMessage;
        Test.stopTest();
        
        // THEN : Check for Latest Inbound Email on Enquiry
        Case testEnquiryRetrieved = [
            Select Id, 
            ParentId, 
            Latest_Inbound_Email__c, 
            Recent_Inbound_Email__c, 
            Mark_as_read__c 
            from Case 
            where Id = :testEnquiry.Id];
        Assert.isNotNull(
            testEnquiryRetrieved.Latest_Inbound_Email__c, 
            'Latest Inbound Email should not be null');
        Assert.isNotNull(
            testEnquiryRetrieved.Recent_Inbound_Email__c, 
            'Recent Inbound Email should not be null');
    }

    @isTest
    /**
    * @description  : Test method for creating email message with myResearch enquiry
    **/
    static void testIfEmailMessageEnquiryIsEmpty() { 
        Case testEnquiry = [
            Select Id 
            From Case 
            ORDER BY CreatedDate DESC 
            LIMIT 1];
        testEnquiry.recordTypeId = (
            Schema.SObjectType.Case
            .getRecordTypeInfosByName()
            .get('Admissions')
            .getRecordTypeId());
        testEnquiry.Description = null;
        testEnquiry.Subject = null;
        update testEnquiry;

        // Create Email Message for Enquiry for application
        EmailMessage testEmailMessage =  new EmailMessage(
            ParentId = testEnquiry.Id,
            FromName = 'testSender',
            HTMLBody = 'test',
            Subject = 'testSubject',
            TextBody = 'test body',
            Incoming = true);
        
        Test.startTest();
        // WHEN : Email Sent for linked Enquiry
        insert testEmailMessage;
        Test.stopTest();
        
        // THEN : Check for Latest Inbound Email on Enquiry
        Case testEnquiryRetrieved = [
            Select Id, 
            ParentId, 
            Description, 
            Subject 
            from Case 
            where Id = :testEnquiry.Id];
        Assert.areEqual(
            'test body', 
            testEnquiryRetrieved.Description, 
            'Description should not be null');
        Assert.areEqual(
            'testSubject', 
            testEnquiryRetrieved.Subject, 
            'Subject should not be null');
    }

    @isTest
    /**
    * @description  : Test method for If Email Message Enquiry Is From Monash Domain
    **/
    static void testIfEmailMessageEnquiryIsFromMonashDomainA() { 
        Case testEnquiry = [
            Select Id 
            From Case 
            ORDER BY CreatedDate DESC 
            LIMIT 1];
        testEnquiry.Origin = 'ask Monash Emails';
        update testEnquiry;

        // Create Email Message for Enquiry for application
        EmailMessage testEmailMessage =  new EmailMessage(
            ParentId = testEnquiry.Id,
            FromAddress = 'testfrom@monash.edu',
            ToAddress = 'ask.monash@monash.edu',
            FromName = 'testSender',
            HTMLBody = 'test',
            Subject = 'testSubject',
            TextBody = 'test body',
            Incoming = true);
        
        Test.startTest();
        // WHEN : Email Sent for linked Enquiry
        insert testEmailMessage;
        Test.stopTest();
        
        // THEN : Check for Latest Inbound Email on Enquiry
        Case testEnquiryRetrieved = [
            Select Id,
            Channel__c, 
            Origin, 
            OwnerId, 
            RecordTypeId, 
            Status
            From Case 
            Where Id = :testEnquiry.Id];

        Group testGroup = [SELECT Id FROM Group WHERE Id = '00G280000034FhHEAU'];
        RecordType testRecordType = [SELECT Id, Name FROM RecordType WHERE Id = '012280000015HrQ'];
        Assert.areEqual(
            'Web', 
            testEnquiryRetrieved.Channel__c, 
            'Channel should be Web');
        Assert.areEqual(
            'ask.monash@monash.edu', 
            testEnquiryRetrieved.Origin, 
            'Origin should be ask.monash@monash.edu');
        Assert.areEqual(
            testGroup.Id, 
            testEnquiryRetrieved.OwnerId, 
            'Owner should be HR');
        Assert.areEqual(
            testRecordType.Id, 
            testEnquiryRetrieved.RecordTypeId, 
            'Record Type should be HR Enquiry');
        Assert.areEqual(
            'New', 
            testEnquiryRetrieved.Status, 
            'Status should be New');
    }

    @isTest
    /**
    * @description  : Test method for If Email Message Enquiry Is From Monash Domain
    **/
    static void testIfEmailMessageEnquiryIsFromMonashDomainB() { 
        Case testEnquiry = [
            Select Id 
            From Case 
            ORDER BY CreatedDate DESC 
            LIMIT 1];
        testEnquiry.Origin = 'ask Monash Emails';
        update testEnquiry;

        // Create Email Message for Enquiry for application
        EmailMessage testEmailMessage =  new EmailMessage(
            ParentId = testEnquiry.Id,
            FromAddress = 'testfrom@test.edu',
            ToAddress = 'ask.monash@monash.edu',
            FromName = 'testSender',
            HTMLBody = 'test',
            Subject = 'testSubject',
            TextBody = 'test body',
            Incoming = true);
        
        Test.startTest();
        // WHEN : Email Sent for linked Enquiry
        insert testEmailMessage;
        Test.stopTest();
        
        // THEN : Check for Latest Inbound Email on Enquiry
        Case testEnquiryRetrieved = [
            Select Id,
            Origin, 
            OwnerId, 
            RecordTypeId
            From Case 
            Where Id = :testEnquiry.Id];

        Group testGroup = [SELECT Id FROM Group WHERE Id = '00G0I0000031XylUAE'];
        RecordType testRecordType = [SELECT Id, Name FROM RecordType WHERE Id = '01228000000Pnsk'];
        Assert.areEqual(
            'Email - Ask Monash', 
            testEnquiryRetrieved.Origin, 
            'Origin should be Email - Ask Monash');
        Assert.areEqual(
            testGroup.Id, 
            testEnquiryRetrieved.OwnerId, 
            'Owner should be Monash Connect Current Student');
        Assert.areEqual(
            testRecordType.Id, 
            testEnquiryRetrieved.RecordTypeId, 
            'Record Type should be Standard Enquiry');
    }
}