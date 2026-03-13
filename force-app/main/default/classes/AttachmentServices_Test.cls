/**
 * @description test class for AttachmentServices Trigger handler
 * @author      Ant Custodio
 * @since       AUG.4.2017
 * @revision
 *  JUL.05.2019     - Suman Gunaganti   - (SF-2781) Removed Application Document provided object reference
 *  MAR.15.2024     - Mac Domingo       - (EPCP-3307) Change integration endpoint for Mule 4
 *  JUL.25.2024     - Nick Guia         - Refactored test class; Created TestSetup
 * 
 */
@isTest(isParallel=false) // APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object: User
private class AttachmentServices_Test {

    @TestSetup
    static void makeData() {

        // create an Applicant Contact
        TriggerCommon.disableTrigger('Account');
        TriggerCommon.disableTrigger('Contact');
        TriggerCommon.disableTrigger('User');

        Contact applicant = new Contact(
            LastName = 'AttachmentServices_Test',
            FirstName = 'AttachmentServices_Test',
            Email = 'testEmail@test.edu',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Student').getRecordTypeId(),
            Person_ID_unique__c = '865482146',
			Personal_email__c = 'testEmail@test.edu',
            Birthdate = Date.today().addYears(- 20),
            Gender__c = 'M',
            Last_Name__c = 'AttachmentServices_Test',
            Phone = '11112222',
            MailingStreet = '123 Test St',
            MailingCity = 'Melbourne',
            MailingCountry = 'Australia',
            MailingState = 'Victoria',
            MailingPostalCode = '3000',
            Residency_Status__c = 'DOM-AUS',
            Mobilephone = '04444444444'
        );

        // to avoid Error: 'Portal account owner must have a role'
        User adminUser = [SELECT Id FROM User 
                        WHERE Profile.Name = 'System Administrator' 
                        AND IsActive = true 
                        LIMIT 1];
        System.runAs(adminUser) {
            // create account for the applicant contact and assign an admin user as the owner
            Account applicantAccount = new Account(
                Name = applicant.FirstName + ' ' + applicant.LastName,
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                                .get(AccountServices.ACCOUNT_INDIVIDUAL_TYPE)
                                .getRecordTypeId(),
                OwnerId = adminUser.Id
            );
            insert applicantAccount;

            // link account and contact
            applicant.AccountId = applicantAccount.Id;
        }

        insert applicant;
        
        // create a myApp user for applicant
        User myAppUser = new ApplicationService().createMyAppUserFromApplicant(new List<Contact>{ applicant })[0];
        insert myAppUser;

        TriggerCommon.enableTrigger('Account');
        TriggerCommon.enableTrigger('Contact');
        TriggerCommon.enableTrigger('User');

        // create an Application record
        Application__c appRecord = StudFirst_TestHelper.createApplication(applicant.Id);
        appRecord.OwnerId = myAppUser.Id;
        appRecord.Status__c = 'Submitted';
        insert appRecord;

        //create Tertiary institution
        Institution__c tertInsRec = StudFirst_TestHelper.createTertiaryInstitution();
        insert tertInsRec;

        // create qualification
        Contact_Qualification__c conQualRec = new Contact_Qualification__c();
        conQualRec.Country__c = 'Australia';
        conQualRec.First_Year_Enrolled__c = String.valueOf(date.today().year()-4);
        conQualRec.Last_Year_Enrolled__c = String.valueOf(date.today().year());
        conQualRec.Other_Qualification__c = 'Certificate III';
        conQualRec.Institution_Code__c = tertInsRec.Institution_Code__c;
        conQualRec.Institution_Name__c = tertInsRec.Institution_Name__c;
        conQualRec.Status__c = 'CURRENTLY STUDYING';
        conQualRec.Contact__c = applicant.Id;
        conQualRec.RecordTypeId = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByDeveloperName().get('Tertiary_Education').getRecordTypeId();
        insert conQualRec;

        // callista outcome status
        Callista_Outcome_Status__c outcomeStatus = StudFirst_TestHelper.createOutcomeStatus();
        insert outcomeStatus;

        // application qualification
        Application_Qualification_Provided__c aqpRecord = new Application_Qualification_Provided__c();
        aqpRecord.Application__c = appRecord.Id;
        aqpRecord.Contact_Qualification__c = conQualRec.Id;
        insert aqpRecord;

        // work experience
        Work_Experience__c workExpRecord = new Work_Experience__c();
        workExpRecord = StudFirst_TestHelper.populateWorkExperienceRecord(workExpRecord);
        workExpRecord.Contact__c = applicant.Id;
        insert workExpRecord;

        // contact document
        Contact_Document__c contactDocu = new Contact_Document__c();
        contactDocu = StudFirst_TestHelper.createContactDocument(applicant.Id);
        insert contactDocu;

        // application work experience
        Application_Work_Experience_Provided__c aweRecord = new Application_Work_Experience_Provided__c();
        aweRecord.Application__c = appRecord.Id;
        aweRecord.Work_Experience__c = workExpRecord.Id;
        insert aweRecord;

        // create a Course
        Course__c courseRec = StudFirst_TestHelper.createCourse();
        insert courseRec;

        // create course offerings
        List<Course_Offering__c> courseOfferingList = new List<Course_Offering__c>();
        Course_Offering__c courseOfferingRec = StudFirst_TestHelper.createCourseOffering(courseRec); // with unit set
        courseOfferingList.add(courseOfferingRec);
        Course_Offering__c courseOfferingRecNoUnit = StudFirst_TestHelper.createCourseOfferingNoUnitSet(courseRec); // without unit set
        courseOfferingList.add(courseOfferingRecNoUnit);
        insert courseOfferingList;

        // create ACP
        Application_Course_Preference__c coursePrefA = StudFirst_TestHelper.createCoursePreferences(appRecord, applicant, courseOfferingRec, courseRec);
        coursePrefA.Outcome_Status__c = outcomeStatus.Name;
        coursePrefA.Offer_Response_Status__c = outcomeStatus.Name;
        coursePrefA.Preference_Number__c = '1';
        insert coursePrefA;

        // create Integration Settings
        IntegrationSettings_SubmitApplication__c is = new IntegrationSettings_SubmitApplication__c();
        is.Base_Url__c = 'https://mix-dev.monash.edu';
        is.Path__c = '/la/v1/admissions/applications';
        is.Method__c = 'POST';
        is.Header_ClientId__c = 'c8411f0ca73a4ae6a0c7081a1336630f';
        is.Header_ClientSecret__c = 'cd2d5b9e26fa4999A33FF6A7F12D65AD';
        is.Header_ContentType__c = 'application/json';
        is.Mock_Endpoint_Applications__c = 'http://monash.getsandbox.com/la/v1/admissions/applications';
        is.Enable_Mock__c = false;
        is.Timeout__c = '12000';
        insert is;
    }

    /**
     * @author       Anterey Custodio
     * @since        AUG.3.2017
     * @description  Email attachments should be cloned when Case has a linked ACP
     * @revision
     *   JUL.25.2024     - Nick Guia     - refactored to use test setup
     *                                   - removed get global describe to get record type id
     *                                   - updated assert statements
     */
    @isTest
    static void shouldCloneEmailAttachmentWhenCaseHasACP() {

        // GIVEN : An Email message with attachments is received for a Case with ACP

        // get setup applicant
        Contact applicant = [SELECT Id 
                            FROM Contact 
                            WHERE LastName = 'AttachmentServices_Test' 
                            LIMIT 1];
        // get setup acp
        Application_Course_Preference__c acp = [SELECT Id 
                                                FROM Application_Course_Preference__c 
                                                WHERE Applicant__c  = :applicant.Id 
                                                LIMIT 1];

        // create a Case
        Id admissionsRecType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Admissions').getRecordTypeId();
        Case caseRec = new  Case(
            SuppliedName = 'testName',
            SuppliedPhone = '0400000000',
            SuppliedEmail = 'testformEmail@monash.edu',
            ContactId = applicant.Id,
            AccountId = null,
            RecordTypeId = admissionsRecType,
            Notify_Agent__c = true,
            Application_Course_Preference__c = acp.Id
        );
        insert caseRec;

        EmailMessage emlMsg = new EmailMessage(
            ParentId = caseRec.id,
            FromAddress = 'testfrom@testmonash.edu',
            FromName = 'testSender',
            Subject = 'AttachmentServices_Test',
            HtmlBody = '<b>test body</b>',
            ToAddress = 'testEndpoint@monash.edu',
            Incoming = true
        );
        insert emlMsg;

        List<Attachment> attList = new List<Attachment>();

        Attachment attRec = new Attachment();
        attRec.Body = Blob.valueOf('Sample Text String');
        attRec.Name = String.valueOf('test.txt');
        attRec.ContentType = String.valueOf('text/plain');
        attRec.ParentId = emlMsg.Id;
        attList.add(attRec);

        Attachment attRec2 = new Attachment();
        attRec2.Body = Blob.valueOf('Sample Text String #2');
        attRec2.Name = String.valueOf('test2.doc');
        attRec2.ContentType = String.valueOf('application/msword');
        attRec2.ParentId = emlMsg.Id;
        attList.add(attRec2);

        //set mock response
        Test.setMock(HttpCalloutMock.class, new StudFirst_MockHttpResponseGenerator());
        
        Test.startTest();

        // WHEN : attachments from email message are inserted
        insert attList;

        Test.stopTest();

        // THEN : there should be a Contact Document created per Attachment
        List<Contact_Document__c> cdList = [SELECT Id
                                            FROM Contact_Document__c
                                            WHERE (Filename__c =: attRec.Name OR Filename__c =: attRec2.Name)
                                            AND Email_Attachment_Id__c != null];
        Assert.areEqual(2, cdList.size(), 'Unexpected number of Contact Document created');

        // THEN : Email Message - Has_Large_Small_Document_Received__c should b e flagged to true
        List<EmailMessage> emailMsg = [SELECT Id FROM EmailMessage WHERE Has_Large_Small_Document_Received__c = TRUE];
        Assert.areEqual(1, emailMsg.size(), 'Small Document not flagged');
    }

    /**
     * @author       Majid Reisi Dehkordi
     * @since        SEP.13.2017
     * @description  Email attachments should be cloned once the case is updated with an ACP
     * @revision
     *   JUL.25.2024     - Nick Guia     - refactored to use test setup
     *                                   - removed get global describe to get record type id
     *                                   - updated assert statements
     */
    @isTest
    static void shouldCloneEmailAttachmentWhenOnCaseUpdateWithACP() {
        
        // GIVEN : An Email message with attachments is received for a Case without ACP

        // get setup applicant
        Contact applicant = [SELECT Id 
                            FROM Contact 
                            WHERE LastName = 'AttachmentServices_Test' 
                            LIMIT 1];
        // get setup acp
        Application_Course_Preference__c acp = [SELECT Id 
                                                FROM Application_Course_Preference__c 
                                                WHERE Applicant__c  = :applicant.Id 
                                                LIMIT 1];
                                                
        // create a Case without an ACP
        Id admissionsRecType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Admissions').getRecordTypeId();
        Case caseRec = new  Case(
            SuppliedName = 'testName',
            SuppliedPhone = '0400000000',
            SuppliedEmail = 'testformEmail@monash.edu',
            ContactId = applicant.Id,
            AccountId = null,
            RecordTypeId = admissionsRecType,
            Notify_Agent__c = true
        );
        insert caseRec;

        EmailMessage emlMsg = new EmailMessage(
            ParentId = caseRec.id,
            FromAddress = 'testfrom@testmonash.edu',
            FromName = 'testSender',
            Subject = 'AttachmentServices_Test',
            HtmlBody = '<b>test body</b>',
            ToAddress = 'testEndpoint@monash.edu',
            Incoming = true
        );
        insert emlMsg;

        //set mock response
        Test.setMock(HttpCalloutMock.class, new StudFirst_MockHttpResponseGenerator());

        List<Attachment> attList = new List<Attachment>();

        Attachment attRec = new Attachment();
        attRec.Body = Blob.valueOf('Sample Text String');
        attRec.Name = String.valueOf('test.txt');
        attRec.ContentType = String.valueOf('text/plain');
        attRec.ParentId = emlMsg.Id;
        attList.add(attRec);

        Attachment attRec2 = new Attachment();
        attRec2.Body = Blob.valueOf('Sample Text String #2');
        attRec2.Name = String.valueOf('test2.doc');
        attRec2.ContentType = String.valueOf('application/msword');
        attRec2.ParentId = emlMsg.Id;
        attList.add(attRec2);

        insert attList;

        Test.startTest();

        // WHEN : an ACP is linked to the Case

        caseRec.Application_Course_Preference__c = acp.Id;
        update caseRec;

        Test.stopTest();

        // THEN : there should be a Contact Document created per Attachment
        List<Contact_Document__c> cdList = [SELECT Id
                                            FROM Contact_Document__c
                                            WHERE (Filename__c =: attRec.Name OR Filename__c =: attRec2.Name)
                                            AND Email_Attachment_Id__c != null];
        Assert.areEqual(2, cdList.size(), 'Trigger did not create the expected number of Contact Documents');

        // THEN : Email Message - Has_Large_Small_Document_Received__c should b e flagged to true
        List<EmailMessage> emailMsg = [SELECT Id FROM EmailMessage WHERE Has_Large_Small_Document_Received__c = TRUE];
        Assert.areEqual(1, emailMsg.size(), 'Small Document not flagged');
    }

    /**
     * @description when the email message's parent Case details passes the 
     * criteria defined in the cmdt, mark the resulting contact document as
     * Internal Only = true
     */
    @isTest
    static void shouldSetContactDocInternalOnlyWhenMuDocsCriteriaPassed() {

        // GIVEN : A case with Origin = 'Email - mu.documents'

        // get setup applicant
        Contact applicant = [SELECT Id 
                            FROM Contact 
                            WHERE LastName = 'AttachmentServices_Test' 
                            LIMIT 1];
        // get setup acp
        Application_Course_Preference__c acp = [SELECT Id 
                                                FROM Application_Course_Preference__c 
                                                WHERE Applicant__c  = :applicant.Id 
                                                LIMIT 1];

        Id admissionsRecType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Admissions').getRecordTypeId();
        Case caseRec = new  Case(
            SuppliedName = 'testName',
            SuppliedPhone = '0400000000',
            SuppliedEmail = 'testformEmail@monash.edu',
            ContactId = applicant.Id,
            AccountId = null,
            RecordTypeId = admissionsRecType,
            Notify_Agent__c = true,
            Application_Course_Preference__c = acp.Id,
            Origin = 'Email - mu.documents'
        );
        insert caseRec;

        EmailMessage emlMsg = new EmailMessage(
            ParentId = caseRec.id,
            FromAddress = 'testfrom@testmonash.edu',
            FromName = 'testSender',
            Subject = 'AttachmentServices_Test',
            HtmlBody = '<b>test body</b>',
            ToAddress = 'testEndpoint@monash.edu',
            Incoming = true
        );
        insert emlMsg;

        Attachment attRec;

        Test.startTest();

        //set mock response
        Test.setMock(HttpCalloutMock.class, new StudFirst_MockHttpResponseGenerator());

        // WHEN : an email message attachment is created
        attRec = new Attachment();
        attRec.Body = Blob.valueOf('Sample Text String');
        attRec.Name = String.valueOf('test.txt');
        attRec.ContentType = String.valueOf('text/plain');
        attRec.ParentId = emlMsg.Id;
        insert attRec;

        Test.stopTest();

        // THEN : the resulting Contact Document should be set to Internal_Only__c = true;
        List<Contact_Document__c> cdList = [SELECT Id, Internal_Only__c 
                                            FROM Contact_Document__c
                                            WHERE Email_Attachment_Id__c = :attRec.Id];
        Assert.areEqual(1, cdList.size(), 'Unexpected number of Contact Document created');
        Assert.areEqual(true, cdList[0].Internal_Only__c, 'Unable to set Contact Document as Internal Only for MU Docs Enquiry');

        // THEN : the resulting ContentDocumentLink should be set to Visibility = 'InternalUsers';
        ContentDocumentLink[] cdl = [SELECT Id, Visibility
                                FROM ContentDocumentLink
                                WHERE LinkedEntityId = :cdList[0].Id];
        Assert.areEqual(1, cdl.size(), '1 record is expected');
        Assert.areEqual('InternalUsers', cdl[0].Visibility, 'Unable to set ContentDocumentLink Visibility to InternalUsers');
    }

    /**
     * @description when the email message's parent Case details passes the 
     * criteria defined in the cmdt, mark the resulting contact document as
     * Internal Only = true
     */
    @isTest
    static void shouldSetContactDocInternalOnlyWhenAgentNominationsCriteriaPassed() {

        // GIVEN : A case with Origin = 'Email - Agent.Nominations'

        // get setup applicant
        Contact applicant = [SELECT Id 
                            FROM Contact 
                            WHERE LastName = 'AttachmentServices_Test' 
                            LIMIT 1];
        // get setup acp
        Application_Course_Preference__c acp = [SELECT Id 
                                                FROM Application_Course_Preference__c 
                                                WHERE Applicant__c  = :applicant.Id 
                                                LIMIT 1];

        Id admissionsRecType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Admissions').getRecordTypeId();
        Case caseRec = new  Case(
            SuppliedName = 'testName',
            SuppliedPhone = '0400000000',
            SuppliedEmail = 'testformEmail@monash.edu',
            ContactId = applicant.Id,
            AccountId = null,
            RecordTypeId = admissionsRecType,
            Notify_Agent__c = true,
            Application_Course_Preference__c = acp.Id,
            Origin = 'Email - Agent.Nominations'
        );
        insert caseRec;

        EmailMessage emlMsg = new EmailMessage(
            ParentId = caseRec.id,
            FromAddress = 'testfrom@testmonash.edu',
            FromName = 'testSender',
            Subject = 'AttachmentServices_Test',
            HtmlBody = '<b>test body</b>',
            ToAddress = 'testEndpoint@monash.edu',
            Incoming = true
        );
        insert emlMsg;

        Attachment attRec;

        Test.startTest();

        //set mock response
        Test.setMock(HttpCalloutMock.class, new StudFirst_MockHttpResponseGenerator());

        // WHEN : an email message attachment is created
        attRec = new Attachment();
        attRec.Body = Blob.valueOf('Sample Text String');
        attRec.Name = String.valueOf('test.txt');
        attRec.ContentType = String.valueOf('text/plain');
        attRec.ParentId = emlMsg.Id;
        insert attRec;

        Test.stopTest();

        // THEN : the resulting Contact Document should be set to Internal_Only__c = true;
        List<Contact_Document__c> cdList = [SELECT Id, Internal_Only__c 
                                            FROM Contact_Document__c
                                            WHERE Email_Attachment_Id__c = :attRec.Id];
        Assert.areEqual(1, cdList.size(), 'Unexpected number of Contact Document created');
        Assert.areEqual(true, cdList[0].Internal_Only__c, 'Unable to set Contact Document as Internal Only for MU Docs Enquiry');

        // THEN : the resulting ContentDocumentLink should be set to Visibility = 'InternalUsers';
        ContentDocumentLink[] cdl = [SELECT Id, Visibility
                                FROM ContentDocumentLink
                                WHERE LinkedEntityId = :cdList[0].Id];
        Assert.areEqual(1, cdl.size(), '1 record is expected');
        Assert.areEqual('InternalUsers', cdl[0].Visibility, 'Unable to set ContentDocumentLink Visibility to InternalUsers');
    }
}