/**
 * @description       : Test Class for Email Message : AS: Process Messages & Case Management
 * @author            : Jackie Ho
 * @group             : 
 * @last modified on  : 27-08-2025
 * @last modified by  : Jackie Ho
**/
@isTest(isParallel=true)
public with sharing class EmailMessageASMessagesCaseManagement_FT {
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
    * @description  : Test method for incoming email alert is not required
    **/
    static void testIncomingEmailAlertIsNotRequired() {
        Case testEnquiry = [
            Select Id 
            From Case 
            ORDER BY CreatedDate DESC 
            LIMIT 1];
        testEnquiry.recordTypeId = (
            Schema.SObjectType.Case
            .getRecordTypeInfosByName()
            .get('Complaint')
            .getRecordTypeId());
        testEnquiry.Incoming_Email__c = true;
        TriggerCommon.disableTrigger('Case');
        update testEnquiry;
        TriggerCommon.enableTrigger('Case');

        EmailMessage testEmailMessage = new EmailMessage();
        testEmailMessage.ParentId = testEnquiry.Id;
        testEmailMessage.FromName = 'testSender';
        testEmailMessage.HTMLBody = 'test';
        testEmailMessage.Subject = 'testSubject';
        testEmailMessage.TextBody = 'test body';
        testEmailMessage.Status = '1';
        
        Test.startTest();
        // WHEN : Email Sent for linked Enquiry
        insert testEmailMessage;
        Test.stopTest();
        
        // THEN : Check for Latest Inbound Email on Enquiry
        Case testEnquiryRetrieved = [
            Select Id,
            Incoming_Email__c
            from Case 
            where Id = :testEnquiry.Id];
        Assert.areEqual(
            false, 
            testEnquiryRetrieved.Incoming_Email__c, 
            'Incoming Email should be false');
    }

    @isTest
    /**
    * @description  : Test method for incoming email alert is required
    **/
    static void testIncomingEmailAlertIsRequired() {
        Case testEnquiry = [
            Select Id
            From Case 
            ORDER BY CreatedDate DESC 
            LIMIT 1];
        testEnquiry.recordTypeId = (
            Schema.SObjectType.Case
            .getRecordTypeInfosByName()
            .get('Complaint')
            .getRecordTypeId());
        TriggerCommon.disableTrigger('Case');
        update testEnquiry;
        TriggerCommon.enableTrigger('Case');

        EmailMessage testEmailMessage = new EmailMessage();
        testEmailMessage = (EmailMessage) fflib_ApexMocksUtils.setReadOnlyFields(
            testEmailMessage,
            EmailMessage.class,
                new Map<SObjectField, Object> {
                    EmailMessage.Incoming => true
                }
            );
        testEmailMessage.ParentId = testEnquiry.Id;
        testEmailMessage.FromName = 'testSender';
        testEmailMessage.HTMLBody = 'test';
        testEmailMessage.Subject = 'testSubject';
        testEmailMessage.TextBody = 'test body';
        testEmailMessage.MessageDate = System.today();
        testEmailMessage.Status = '0';
        
        Test.startTest();
        // WHEN : Email Sent for linked Enquiry
        insert testEmailMessage;
        Test.stopTest();
        
        // THEN : Check for Latest Inbound Email on Enquiry
        Case testEnquiryRetrieved = [
            Select Id,
            Incoming_Email__c,
            Latest_Inbound_Email__c
            from Case 
            where Id = :testEnquiry.Id];
        Assert.areEqual(
            true, 
            testEnquiryRetrieved.Incoming_Email__c, 
            'Incoming Email should be true');
        Assert.areEqual(
            System.today(), 
            testEnquiryRetrieved.Latest_Inbound_Email__c, 
            'Latest Inbound Email should be Message Date');
    }

    @IsTest
    /**
    * @description  : Test method for incoming email and case status
    **/
    static void testIncomingEmailAndCase() {
        Case testEnquiry = [
            Select Id 
            From Case 
            ORDER BY CreatedDate DESC 
            LIMIT 1];
        testEnquiry.recordTypeId = (
            Schema.SObjectType.Case
            .getRecordTypeInfosByName()
            .get('SEBS')
            .getRecordTypeId());
        testEnquiry.Status = 'Awaiting Customer Feedback';
        TriggerCommon.disableTrigger('Case');
        update testEnquiry;
        TriggerCommon.enableTrigger('Case');

        EmailMessage testEmailMessage = new EmailMessage();
        testEmailMessage.Incoming = true;
        testEmailMessage.ParentId = testEnquiry.Id;
        testEmailMessage.FromName = 'testSender';
        testEmailMessage.HTMLBody = 'test';
        testEmailMessage.Subject = 'testSubject';
        testEmailMessage.TextBody = 'test body';
        testEmailMessage.MessageDate = System.today();
        testEmailMessage.Status = '1';
        
        Test.startTest();
        // WHEN : Email Sent for linked Enquiry
        insert testEmailMessage;
        Test.stopTest();
        
        // THEN : Check for Latest Inbound Email on Enquiry
        Case testEnquiryRetrieved = [
            Select Id,
            Incoming_Email__c,
            Status
            from Case 
            where Id = :testEnquiry.Id];
        Assert.areEqual(
            true, 
            testEnquiryRetrieved.Incoming_Email__c, 
            'Incoming Email should be true');
        Assert.areEqual(
            'Updated', 
            testEnquiryRetrieved.Status, 
            'Status should be Updated');
    }

    @IsTest
    /**
    * @description  : Test method for email notification on case status
    **/
    static void testEmailNotificationOnCaseStatus() {
        Case testEnquiry = [
            Select Id 
            From Case 
            ORDER BY CreatedDate DESC 
            LIMIT 1];
        testEnquiry.recordTypeId = (
            Schema.SObjectType.Case
            .getRecordTypeInfosByName()
            .get('HR')
            .getRecordTypeId());
        testEnquiry.Status = 'In Progress';
        TriggerCommon.disableTrigger('Case');
        update testEnquiry;
        TriggerCommon.enableTrigger('Case');

        EmailMessage testEmailMessage = new EmailMessage();
        testEmailMessage.Incoming = true;
        testEmailMessage.ParentId = testEnquiry.Id;
        testEmailMessage.FromName = 'testSender';
        testEmailMessage.HTMLBody = 'test';
        testEmailMessage.Subject = 'testSubject';
        testEmailMessage.TextBody = 'test body';
        testEmailMessage.MessageDate = System.today();
        testEmailMessage.Status = '1';
        
        Test.startTest();
        // WHEN : Email Sent for linked Enquiry
        insert testEmailMessage;
        Test.stopTest();
        
        // THEN : Check for Latest Inbound Email on Enquiry
        Case testEnquiryRetrieved = [
            Select Id,
            Status
            from Case 
            where Id = :testEnquiry.Id];
        Assert.areEqual(
            'Updated', 
            testEnquiryRetrieved.Status, 
            'Status should be Updated');
    }

    
    @IsTest
    /**
    * @description  : Test method for email notification on case status
    **/
    static void testUserEmailCaseType() {
        Case testEnquiry = [
            Select Id
            From Case 
            ORDER BY CreatedDate DESC 
            LIMIT 1];
        testEnquiry.recordTypeId = (
            Schema.SObjectType.Case
            .getRecordTypeInfosByName()
            .get('SEBS')
            .getRecordTypeId());
        testEnquiry.Status = 'Closed';
        TriggerCommon.disableTrigger('Case');
        update testEnquiry;
        TriggerCommon.enableTrigger('Case');

        EmailMessage testEmailMessage = new EmailMessage();
        testEmailMessage.Incoming = true;
        testEmailMessage.ParentId = testEnquiry.Id;
        testEmailMessage.FromName = 'testSender';
        testEmailMessage.HTMLBody = 'test';
        testEmailMessage.Subject = 'testSubject';
        testEmailMessage.TextBody = 'test text body';
        
        Test.startTest();
        // WHEN : Email Sent for linked Enquiry
        insert testEmailMessage;
        Test.stopTest();
        
        // THEN : Check for Latest Inbound Email on Enquiry
        Case testEnquiryRetrieved = [
            Select Id,
            Status,
            Email_Body_Message_Copy__c
            from Case 
            where Id = :testEnquiry.Id];
        Assert.areEqual(
            'Reopened', 
            testEnquiryRetrieved.Status, 
            'Status should be Reopened');
        Assert.areEqual(
            'test text body', 
            testEnquiryRetrieved.Email_Body_Message_Copy__c, 
            'Email Body Message Copy should be test text body');
    }

    @IsTest
    /**
    * @description  : Test method for Alumni case email
    **/
    static void testAlumniCaseEmail() {
        Case testEnquiry = [
            Select Id
            From Case 
            ORDER BY CreatedDate DESC 
            LIMIT 1];
        testEnquiry.recordTypeId = (
            Schema.SObjectType.Case
            .getRecordTypeInfosByName()
            .get('Alumni Engagement')
            .getRecordTypeId());
        testEnquiry.Status = 'Closed';
        TriggerCommon.disableTrigger('Case');
        update testEnquiry;
        TriggerCommon.enableTrigger('Case');

        EmailMessage testEmailMessage = new EmailMessage();
        testEmailMessage.Incoming = true;
        testEmailMessage.ParentId = testEnquiry.Id;
        testEmailMessage.FromName = 'testSender';
        testEmailMessage.HTMLBody = 'test';
        testEmailMessage.Subject = 'testSubject';
        testEmailMessage.TextBody = 'test body';
        
        Test.startTest();
        // WHEN : Email Sent for linked Enquiry
        insert testEmailMessage;
        Test.stopTest();
        
        // THEN : Check for Latest Inbound Email on Enquiry
        Case testEnquiryRetrieved = [
            Select Id,
            Status
            from Case 
            where Id = :testEnquiry.Id];
        Assert.areEqual(
            'Open', 
            testEnquiryRetrieved.Status, 
            'Status should be Open');
    }

    @IsTest
    /**
    * @description  : Test method for Reopen Referred Case
    **/
    static void testInboundEmailForReferredCase() {
        Case testEnquiry = [
            Select Id 
            From Case 
            ORDER BY CreatedDate DESC 
            LIMIT 1];
        Contact testContact = [
            Select Id 
            From Contact 
            ORDER BY CreatedDate DESC 
            LIMIT 1];
        testEnquiry.recordTypeId = (
            Schema.SObjectType.Case
            .getRecordTypeInfosByName()
            .get('HR')
            .getRecordTypeId());
        testEnquiry.Status = 'Referred';
        testEnquiry.Referred_To__c = testContact.Id;
        TriggerCommon.disableTrigger('Case');
        update testEnquiry;
        TriggerCommon.enableTrigger('Case');

        EmailMessage testEmailMessage = new EmailMessage();
        testEmailMessage.Incoming = true;
        testEmailMessage.ParentId = testEnquiry.Id;
        testEmailMessage.FromName = 'testSender';
        testEmailMessage.HTMLBody = 'test';
        testEmailMessage.Subject = 'testSubject';
        testEmailMessage.TextBody = 'test body';
        
        Test.startTest();
        // WHEN : Email Sent for linked Enquiry
        insert testEmailMessage;
        Test.stopTest();
        
        // THEN : Check for Latest Inbound Email on Enquiry
        Case testEnquiryRetrieved = [
            Select Id,
            Referral_Response_Received__c,
            Email_Received_Open_Status__c
            from Case 
            where Id = :testEnquiry.Id];
        Assert.areEqual(
            true, 
            testEnquiryRetrieved.Referral_Response_Received__c, 
            'Referral Response Received should be true');
        Assert.areEqual(
            true, 
            testEnquiryRetrieved.Email_Received_Open_Status__c, 
            'Email Received Open Status should be true');
    }

    @IsTest
    /**
    * @description  : Test method for Email Is Read My Research and SEBS
    **/
    static void testEmailIsReadMyResearchAndSEBS() {
        Case testEnquiry = [
            Select Id 
            From Case 
            ORDER BY CreatedDate DESC 
            LIMIT 1];
        testEnquiry.recordTypeId = (
            Schema.SObjectType.Case
            .getRecordTypeInfosByName()
            .get('SEBS')
            .getRecordTypeId());
        TriggerCommon.disableTrigger('Case');
        update testEnquiry;
        TriggerCommon.enableTrigger('Case');

        EmailMessage testEmailMessage = new EmailMessage();
        testEmailMessage.ParentId = testEnquiry.Id;
        testEmailMessage.FromName = 'testSender';
        testEmailMessage.HTMLBody = 'test';
        testEmailMessage.Subject = 'testSubject';
        testEmailMessage.TextBody = 'test body';
        testEmailMessage.Status = '3';
        
        Test.startTest();
        // WHEN : Email Sent for linked Enquiry
        insert testEmailMessage;
        Test.stopTest();
        
        // THEN : Check for Latest Inbound Email on Enquiry
        Case testEnquiryRetrieved = [
            Select Id,
            Incoming_Email__c
            from Case 
            where Id = :testEnquiry.Id];
        Assert.areEqual(
            false, 
            testEnquiryRetrieved.Incoming_Email__c, 
            'Incoming Email should be false');
    }

    @IsTest
    /**
    * @description  : Test method for Incoming Email for Case Update
    **/
    static void testIncomingEmailForCaseUpdate() {
        Case testEnquiry = [
            Select Id 
            From Case 
            ORDER BY CreatedDate DESC 
            LIMIT 1];
        testEnquiry.recordTypeId = (
            Schema.SObjectType.Case
            .getRecordTypeInfosByName()
            .get('Standard Enquiry')
            .getRecordTypeId());
        testEnquiry.Status = 'Draft';
        TriggerCommon.disableTrigger('Case');
        update testEnquiry;
        TriggerCommon.enableTrigger('Case');

        EmailMessage testEmailMessage = new EmailMessage();
        testEmailMessage.Incoming = true;
        testEmailMessage.ParentId = testEnquiry.Id;
        testEmailMessage.FromName = 'testSender';
        testEmailMessage.HTMLBody = 'test';
        testEmailMessage.Subject = 'testSubject';
        testEmailMessage.TextBody = 'test body';
        testEmailMessage.MessageDate = System.today();
        
        Test.startTest();
        // WHEN : Email Sent for linked Enquiry
        insert testEmailMessage;
        Test.stopTest();
        
        // THEN : Check for Latest Inbound Email on Enquiry
        Case testEnquiryRetrieved = [
            Select Id,
            Latest_Inbound_Email__c
            from Case 
            where Id = :testEnquiry.Id];
        Assert.areEqual(
            System.today(), 
            testEnquiryRetrieved.Latest_Inbound_Email__c, 
            'Latest Inbound Email should be today');
    }

    @IsTest
    /**
    * @description  : Test method for Reopen My Research Enquiry
    **/
    static void testReopenMyResearchEnquiry() {
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
        testEnquiry.Status = 'Closed';
        TriggerCommon.disableTrigger('Case');
        update testEnquiry;
        TriggerCommon.enableTrigger('Case');

        EmailMessage testEmailMessage = new EmailMessage();
        testEmailMessage.Incoming = true;
        testEmailMessage.ParentId = testEnquiry.Id;
        testEmailMessage.FromName = 'testSender';
        testEmailMessage.HTMLBody = 'test';
        testEmailMessage.Subject = 'testSubject';
        testEmailMessage.TextBody = 'test body';
        testEmailMessage.Status = '3';
        
        Test.startTest();
        // WHEN : Email Sent for linked Enquiry
        insert testEmailMessage;
        Test.stopTest();
        
        // THEN : Check for Latest Inbound Email on Enquiry
        Case testEnquiryRetrieved = [
            Select Id,
            OwnerId,
            Status
            from Case 
            where Id = :testEnquiry.Id];
        Group testGroup = [SELECT Id FROM Group WHERE Id = '00G280000033o1BEAQ'];
        Assert.areEqual(
            'Open', 
            testEnquiryRetrieved.Status, 
            'Status should be Open');
        Assert.areEqual(
            testGroup.Id, 
            testEnquiryRetrieved.OwnerId, 
            'Owner Id should be myResearch Support');
    }

    @IsTest
    /**
    * @description  : Test method for Reopen HR Enquiry
    **/
    static void testReopenHREnquiry() {
        Case testEnquiry = [
            Select Id 
            From Case 
            ORDER BY CreatedDate DESC 
            LIMIT 1];
        testEnquiry.recordTypeId = (
            Schema.SObjectType.Case
            .getRecordTypeInfosByName()
            .get('HR')
            .getRecordTypeId());
        testEnquiry.Status = 'Closed';
        TriggerCommon.disableTrigger('Case');
        update testEnquiry;
        TriggerCommon.enableTrigger('Case');

        EmailMessage testEmailMessage = new EmailMessage();
        testEmailMessage.Incoming = true;
        testEmailMessage.ParentId = testEnquiry.Id;
        testEmailMessage.FromName = 'testSender';
        testEmailMessage.HTMLBody = 'test';
        testEmailMessage.Subject = 'testSubject';
        testEmailMessage.TextBody = 'test body';
        testEmailMessage.Status = '3';
        
        Test.startTest();
        // WHEN : Email Sent for linked Enquiry
        insert testEmailMessage;
        Test.stopTest();
        
        // THEN : Check for Latest Inbound Email on Enquiry
        Case testEnquiryRetrieved = [
            Select Id,
            OwnerId,
            Status,
            Priority
            from Case 
            where Id = :testEnquiry.Id];
        Group testGroup = [SELECT Id FROM Group WHERE Id = '00G280000034FhHEAU'];
        Assert.areEqual(
            'Reopened', 
            testEnquiryRetrieved.Status, 
            'Status should be Reopened');
        Assert.areEqual(
            testGroup.Id, 
            testEnquiryRetrieved.OwnerId, 
            'Owner Id should be HR');
        Assert.areEqual(
            'High', 
            testEnquiryRetrieved.Priority, 
            'Priority should be High');
    }

    @IsTest
    /**
    * @description  : Test method for Reopen Admissions Enquiry
    **/
    static void testReopenAdmissionsEnquiry() {
        User testUser = [
            Select Id, Name, Profile.Name, IsActive 
            from User 
            Where IsActive = true AND Profile.Name = 'Admissions Profile'
            LIMIT 1];
        Application_Course_Preference__c testACP = [
            Select Id 
            From Application_Course_Preference__c 
            ORDER BY CreatedDate DESC 
            LIMIT 1];

        Case testEnquiry = new Case();
        testEnquiry.Application_Course_Preference__c = testACP.Id;
        testEnquiry.status = 'Open';
        testEnquiry.recordTypeId = (
            Schema.SObjectType.Case
            .getRecordTypeInfosByName()
            .get('Admissions')
            .getRecordTypeId());
        testEnquiry.Status = 'Closed';
        testEnquiry.Latest_Unassigned_Queue_OwnerId__c = testUser.Id;

        System.runAs(testUser) {
            TriggerCommon.disableTrigger('Case');
            insert testEnquiry;
            TriggerCommon.enableTrigger('Case');
        }

        EmailMessage testEmailMessage = new EmailMessage();
        testEmailMessage.Incoming = true;
        testEmailMessage.ParentId = testEnquiry.Id;
        testEmailMessage.FromName = 'testSender';
        testEmailMessage.HTMLBody = 'test';
        testEmailMessage.Subject = 'testSubject';
        testEmailMessage.TextBody = 'test body';
        testEmailMessage.Status = '3';
        testEmailMessage.CreatedDate = System.today();
        
        Test.startTest();
        // WHEN : Email Sent for linked Enquiry
        insert testEmailMessage;
        Test.stopTest();
        
        // THEN : Check for Latest Inbound Email on Enquiry
        Case testEnquiryRetrieved = [
            Select Id,
            Latest_Inbound_Email__c,
            Status
            from Case
            where Id = :testEnquiry.Id];
        Assert.areEqual(
            'Open', 
            testEnquiryRetrieved.Status, 
            'Status should be Open');
        Assert.areEqual(
            System.today(), 
            testEnquiryRetrieved.Latest_Inbound_Email__c, 
            'Latest Inbound Email should be today');
    }

    @IsTest
    /**
    * @description  : Test method for Reopen PDEnquiry
    **/
    static void testReopenPDEnquiry() {
        Case testEnquiry = [
            Select Id 
            From Case 
            ORDER BY CreatedDate DESC 
            LIMIT 1];
        testEnquiry.recordTypeId = (
            Schema.SObjectType.Case
            .getRecordTypeInfosByName()
            .get('Professional Development')
            .getRecordTypeId());
        testEnquiry.Status = 'Closed';
        TriggerCommon.disableTrigger('Case');
        update testEnquiry;
        TriggerCommon.enableTrigger('Case');

        EmailMessage testEmailMessage = new EmailMessage();
        testEmailMessage.Incoming = true;
        testEmailMessage.ParentId = testEnquiry.Id;
        testEmailMessage.FromName = 'testSender';
        testEmailMessage.HTMLBody = 'test';
        testEmailMessage.Subject = 'testSubject';
        testEmailMessage.TextBody = 'test body';
        testEmailMessage.Status = '3';
        testEmailMessage.MessageDate = System.today();
       
        Test.startTest();
        // WHEN : Email Sent for linked Enquiry
        insert testEmailMessage;
        Test.stopTest();
        
        // THEN : Check for Latest Inbound Email on Enquiry
        Case testEnquiryRetrieved = [
            Select Id,
            Status
            from Case
            where Id = :testEnquiry.Id];
        Assert.areEqual(
            'Open', 
            testEnquiryRetrieved.Status, 
            'Status should be Open');
    }

    @IsTest
    /**
    * @description  : Test method for Reopen MGEEnquiry
    **/
    static void testReopenMGEEnquiry() {
        Case testEnquiry = [
            Select Id 
            From Case 
            ORDER BY CreatedDate DESC 
            LIMIT 1];
        testEnquiry.recordTypeId = (
            Schema.SObjectType.Case
            .getRecordTypeInfosByName()
            .get('MGRO Enquiry')
            .getRecordTypeId());
        testEnquiry.Status = 'Closed';
        TriggerCommon.disableTrigger('Case');
        update testEnquiry;
        TriggerCommon.enableTrigger('Case');

        EmailMessage testEmailMessage = new EmailMessage();
        testEmailMessage.Incoming = true;
        testEmailMessage.ParentId = testEnquiry.Id;
        testEmailMessage.FromName = 'testSender';
        testEmailMessage.HTMLBody = 'test';
        testEmailMessage.Subject = 'testSubject';
        testEmailMessage.TextBody = 'test body';
        testEmailMessage.Status = '4';
      
        Test.startTest();
        // WHEN : Email Sent for linked Enquiry
        insert testEmailMessage;
        Test.stopTest();
        
        // THEN : Check for Latest Inbound Email on Enquiry
        Case testEnquiryRetrieved = [
            Select Id,
            Status,
            Incoming_Email__c
            from Case
            where Id = :testEnquiry.Id];
        Assert.areEqual(
            'Open', 
            testEnquiryRetrieved.Status, 
            'Status should be Open');
    }

    @IsTest
    /**
    * @description  : Test method for Reopen DSSEnquiry
    **/
    static void testReopenDSSEnquiry() {
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
        testEnquiry.Status = 'Closed';
        TriggerCommon.disableTrigger('Case');
        update testEnquiry;
        TriggerCommon.enableTrigger('Case');

        EmailMessage testEmailMessage = new EmailMessage();
        testEmailMessage.Incoming = true;
        testEmailMessage.ParentId = testEnquiry.Id;
        testEmailMessage.FromName = 'testSender';
        testEmailMessage.HTMLBody = 'test';
        testEmailMessage.Subject = 'testSubject';
        testEmailMessage.TextBody = 'test body';
        testEmailMessage.Status = '0';
        
        Test.startTest();
        // WHEN : Email Sent for linked Enquiry
        insert testEmailMessage;
        Test.stopTest();
        
        // THEN : Check for Latest Inbound Email on Enquiry
        Case testEnquiryRetrieved = [
            Select Id,
            Status,
            Incoming_Email__c
            from Case
            where Id = :testEnquiry.Id];
        Assert.areEqual(
            'Open', 
            testEnquiryRetrieved.Status, 
            'Status should be Open');
    }

    @IsTest
    /**
    * @description  : Test method for Reopen Professional Year Enquiry
    **/
    static void testReopenProfessionalYearEnquiry() {
        Case testEnquiry = [
            Select Id 
            From Case 
            ORDER BY CreatedDate DESC 
            LIMIT 1];
        testEnquiry.recordTypeId = (
            Schema.SObjectType.Case
            .getRecordTypeInfosByName()
            .get('Professional Year Enquiry')
            .getRecordTypeId());
        testEnquiry.Status = 'Awaiting Customer Feedback';
        TriggerCommon.disableTrigger('Case');
        update testEnquiry;
        TriggerCommon.enableTrigger('Case');

        EmailMessage testEmailMessage = new EmailMessage();
        testEmailMessage.Incoming = true;
        testEmailMessage.ParentId = testEnquiry.Id;
        testEmailMessage.FromName = 'testSender';
        testEmailMessage.HTMLBody = 'test';
        testEmailMessage.Subject = 'testSubject';
        testEmailMessage.TextBody = 'test body';
        testEmailMessage.Status = '3';
        
        Test.startTest();
        // WHEN : Email Sent for linked Enquiry
        insert testEmailMessage;
        Test.stopTest();
        
        // THEN : Check for Latest Inbound Email on Enquiry
        Case testEnquiryRetrieved = [
            Select Id,
            Status
            from Case
            where Id = :testEnquiry.Id];
        Assert.areEqual(
            'Open', 
            testEnquiryRetrieved.Status, 
            'Status should be Open');
    }
}