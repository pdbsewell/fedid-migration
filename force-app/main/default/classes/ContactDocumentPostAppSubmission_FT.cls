/**
 * @author      Kai-Fan Hsieh
 * @description Test class for flow Contact_Document_Post_Application_Submission
 * @since       12/11/2024
 */
@isTest(isParallel=false)//System.TypeException: Test.getStandardPricebookId() cannot be called from parallel Apex tests
private class ContactDocumentPostAppSubmission_FT {
    @TestSetup
    static void setup() {
        // Price book Creation
        TestDataFactory.createSObject(new Pricebook2(), true);

        // Creating a product for scholarship
        Product2 product1 = (Product2) TestDataFactory.createSObject(
            new Product2(
                Name = 'Monash Scholarship1',
                External_Id__c = '12345',
                Expiry_days__c = 15
            ), true);

        // Product always required a standard pricebook
        PricebookEntry pbe1 = (PricebookEntry) TestDataFactory.createSObject(
            new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = product1.Id,
                UnitPrice = -5000), true);

        // Create a community user
        User communityUserRec = StudFirst_TestHelper.createCommunityUser();
        TriggerCommon.disableTrigger('Application__c');
        List<Application__c> appList = new List<Application__c>();

        // Create a Submitted application
        Application__c appRecord = StudFirst_TestHelper.createApplication(communityUserRec.contactId);
        appRecord.Status__c = 'Submitted';
        appRecord.Callista_Application_Id__c = '012345678';
        appList.add(appRecord);

        // Create a new draft application
        Application__c draftAppRecord = StudFirst_TestHelper.createApplication(communityUserRec.contactId);
        draftAppRecord.Status__c = 'Draft';
        appList.add(draftAppRecord);
        insert appList;
        TriggerCommon.enableTrigger('Application__c');

        Contact contactRec = [
            SELECT Id, Residency_Status__c, AccountId, bulkapi_Applicant_Ids__c
            FROM Contact
            WHERE Id = :communityUserRec.contactId
        ];
        contactRec.Residency_Status__c = 'DOM-AUS';
        contactRec.bulkapi_Applicant_Ids__c = '1233333';
        TriggerCommon.disableTrigger('Contact');
        update contactRec;
        TriggerCommon.enableTrigger('Contact');

        // Tertiary institution & qualification
        Institution__c tertiaryInstitution = StudFirst_TestHelper.createTertiaryInstitution();
        insert tertiaryInstitution;

        Callista_Outcome_Status__c outcomeStatus = StudFirst_TestHelper.createOutcomeStatus();
        insert outcomeStatus;

        Contact_Qualification__c contactQualification = new Contact_Qualification__c();
        contactQualification.Country__c = 'Australia';
        contactQualification.First_Year_Enrolled__c = String.valueOf(Date.today().year() - 4);
        contactQualification.Last_Year_Enrolled__c = String.valueOf(Date.today().year());
        contactQualification.Other_Qualification__c = 'Certificate III';
        contactQualification.Institution_Code__c = tertiaryInstitution.Institution_Code__c;
        contactQualification.Institution_Name__c = tertiaryInstitution.Institution_Name__c;
        contactQualification.Status__c = 'CURRENTLY STUDYING';
        contactQualification.Contact__c = contactRec.Id;
        contactQualification.RecordTypeId = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByName().get('Tertiary Education').getRecordTypeId();
        TriggerCommon.disableTrigger('Contact_Qualification__c');
        insert contactQualification;
        TriggerCommon.enableTrigger('Contact_Qualification__c');

        Application_Qualification_Provided__c aqpRecord = new Application_Qualification_Provided__c();
        aqpRecord.Application__c = appRecord.Id;
        aqpRecord.Contact_Qualification__c = contactQualification.Id;
        insert aqpRecord;

        Work_Experience__c workExpRecord = new Work_Experience__c();
        workExpRecord = StudFirst_TestHelper.populateWorkExperienceRecord(workExpRecord);
        workExpRecord.Contact__c = contactRec.Id;
        insert workExpRecord;

        TriggerCommon.disableTrigger('Contact_Document__c');
        List<Contact_Document__c> contactDocumentList = new List<Contact_Document__c>();
        Contact_Document__c contactDocument = new Contact_Document__c();
        contactDocument = StudFirst_TestHelper.createContactDocument(contactRec.Id);
        contactDocument.Application__c = appRecord.Id;
        contactDocumentList.add(contactDocument);

        Application__c draftApplication = [SELECT Id FROM Application__c WHERE Status__c = 'Draft'];
        Contact_Document__c draftContactDoc = new Contact_Document__c();
        draftContactDoc = StudFirst_TestHelper.createContactDocument(contactRec.Id);
        draftContactDoc.Application__c = draftApplication.Id;
        contactDocumentList.add(draftContactDoc);
        insert contactDocumentList;
        TriggerCommon.enableTrigger('Contact_Document__c');

        // Create a file
        Blob bodyBlob = Blob.valueOf('Unit Test ContentVersion Body 1');
        ContentVersion cv = new ContentVersion(
            Title = 'Test File 1',
            PathOnClient = '/Test File1.jpg',
            VersionData = bodyBlob,
            Origin = 'H'
        );
        insert cv;

        // Retrieve it again to get the ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        ContentDocumentLink cdLink1 = new ContentDocumentLink();
        cdLink1.LinkedEntityId = contactDocument.Id;
        cdLink1.ContentDocumentId = cv.ContentDocumentId;

        cdLink1.ShareType = 'V';
        cdLink1.Visibility = 'AllUsers';
        insert cdLink1;

        ContentDocumentLink cdLink3 = new ContentDocumentLink();
        cdLink3.LinkedEntityId = draftContactDoc.Id;
        cdLink3.ContentDocumentId = cv.ContentDocumentId;

        cdLink3.ShareType = 'V';
        cdLink3.Visibility = 'AllUsers';
        insert cdLink3;
        TriggerCommon.disableTrigger('Application_Work_Experience_Provided__c');
        TriggerCommon.disableTrigger('Course__c');
        TriggerCommon.disableTrigger('Course_Offering__c');
        TriggerCommon.disableTrigger('Application_Course_Preference__c');

        Application_Work_Experience_Provided__c aweRecord = new Application_Work_Experience_Provided__c();
        aweRecord.Application__c = appRecord.Id;
        aweRecord.Work_Experience__c = workExpRecord.Id;
        insert aweRecord;

        Course__c courseRec = StudFirst_TestHelper.createCourse();
        insert courseRec;

        Course_Offering__c courseOfferingRec = StudFirst_TestHelper.createCourseOffering(courseRec);
        insert courseOfferingRec;

        Course_Offering__c courseOfferingRecNoUnit = StudFirst_TestHelper.createCourseOfferingNoUnitSet(courseRec);
        insert courseOfferingRecNoUnit;

        Application_Course_Preference__c coursePrefA = StudFirst_TestHelper.createCoursePreferences(appRecord, contactRec, courseOfferingRec, courseRec);
        coursePrefA.Outcome_Status__c = 'TEST-STATUS';
        coursePrefA.Offer_Response_Status__c = 'TEST-STATUS';
        coursePrefA.Preference_Number__c = '1';
        insert coursePrefA;

        TriggerCommon.enableTrigger('Application_Work_Experience_Provided__c');
        TriggerCommon.enableTrigger('Course__c');
        TriggerCommon.enableTrigger('Course_Offering__c');
        TriggerCommon.enableTrigger('Application_Course_Preference__c');

        IntegrationSettings_SubmitApplication__c is = new IntegrationSettings_SubmitApplication__c();
        is.Base_Url__c = 'https://mix-dev.monash.edu';
        is.Path__c = '/la/admissions/v1/applications';
        is.Method__c = 'POST';
        is.Header_ClientId__c = 'c8411f0ca73a4ae6a0c7081a1336630f';
        is.Header_ClientSecret__c = 'cd2d5b9e26fa4999A33FF6A7F12D65AD';
        is.Header_ContentType__c = 'application/json';
        is.Mock_Endpoint_Applications__c = 'http://monash.getsandbox.com/la/admissions/v1/applications';
        is.Enable_Mock__c = false;
        is.Timeout__c = '12000';

        insert is;

        // Start inserting quote
        Opportunity opp = (Opportunity) TestDataFactory.createSObject(
            new Opportunity(
                AccountId = contactRec.AccountId,
                PrimaryContact__c = contactRec.Id,
                Pricebook2Id = Test.getStandardPricebookId(),
                CloseDate = Date.today().addDays(15)
            ), true);

        SBQQ.TriggerControl.disable();
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        TriggerCommon.disableTrigger('SBQQ__QuoteLine__c');
        QuoteTriggerHandler.lockUserCreation = true;

        TestDataFactory.createSObject(
            new SBQQ__Quote__c(
                SBQQ__Account__c = contactRec.AccountId,
                SBQQ__PricebookId__c = Test.getStandardPricebookId(),
                SBQQ__PrimaryContact__c = contactRec.Id,
                SBQQ__Status__c = 'Created',
                Sub_Status__c = 'In Progress',
                SBQQ__Opportunity2__c = opp.Id,
                SBQQ__ExpirationDate__c = opp.CloseDate,
                SBQQ__Primary__c = true
            ), true);

        TestDataFactory.createSObject(
            new OpportunityLineItem(
                OpportunityId = opp.Id,
                Application_Course_Preference__c = coursePrefA.Id,
                Product2Id = product1.Id,
                PricebookEntryId = pbe1.Id
            ), true);

        Contact_Document__c opportunityContactDocument = new Contact_Document__c();
        opportunityContactDocument = StudFirst_TestHelper.createContactDocument(contactRec.Id);
        opportunityContactDocument.Opportunity__c = opp.Id;
        opportunityContactDocument.Application__c = appRecord.Id;
        insert opportunityContactDocument;

        // Create a file
        bodyBlob = Blob.valueOf('Unit Test ContentVersion Body 2');
        cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = '/Test File.jpg',
            VersionData = bodyBlob,
            Origin = 'H'
        );
        insert cv;

        // Retrieve it again to get the ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        ContentDocumentLink cdLink2 = new ContentDocumentLink();
        cdLink2.LinkedEntityId = opportunityContactDocument.Id;
        cdLink2.ContentDocumentId = cv.ContentDocumentId;

        cdLink2.ShareType = 'V';
        cdLink2.Visibility = 'AllUsers';
        insert cdLink2;
    }

    /**
    * @description Test to verify that Contact documents created post application submission get transferred to Callista
    */
    @IsTest
    static private void testSendContactDocumentOnPostSubmission() {
        // Given: an submitted application with contact documents
        Map<Id, Contact_Document__c> contactDocIdMap = new Map<Id, Contact_Document__c>();
        for (Contact_Document__c contactDocument : [SELECT Id, File_Upload_Successful__c, Submitted__c, Document_Owner_Mismatch__c, Post_Submission__c FROM Contact_Document__c WHERE Application__r.Status__c = 'Submitted']) {
            Assert.areEqual(false, contactDocument.File_Upload_Successful__c, 'Expected File_Upload_Successful__c to be false');
            contactDocIdMap.put(contactDocument.Id, contactDocument);
        }
        CallistaFileApiMock mock = new CallistaFileApiMock();
        mock.responseCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        // When: contact documents are marked as post submission
        for (Contact_Document__c contactDocument: contactDocIdMap.values()){
            contactDocument.Submitted__c = true;
            contactDocument.Post_Submission__c = true;
        }
        update contactDocIdMap.values();
        Test.stopTest();

        Set<String> cdIds = new Set<String>();
        for (Contact_Document__c cdRec : [
            SELECT Id
            FROM Contact_Document__c
            WHERE File_Upload_Successful__c = TRUE
        ]) {
            cdIds.add(cdRec.Id);
        }
        // Then: The documents got sent out successfully as Document Owner Mismatch flag is unchecked
        Assert.areEqual(2, cdIds.size(), 'There must be 2 Contact documents with file upload successful');
    }

    /**
     * @description Test to ensure that Contact documents associated with Applications
     * in Submitted status, where the Document Owner Mismatch flag is checked, do not get transferred to Callista.
     */
    @IsTest
    static private void testSendOwnerMismatchContactDocumentOnSubmittedApplication() {
        // Given: Set the Document Owner Mismatch flag to true
        Map<Id, Contact_Document__c> contactDocMap = new Map<Id, Contact_Document__c>();
        for (Contact_Document__c contactDocument : [SELECT Id FROM Contact_Document__c WHERE Application__r.Status__c = 'Submitted']) {
            contactDocument.Submitted__c = true;
            contactDocument.Document_Owner_Mismatch__c = true;
            contactDocMap.put(contactDocument.Id, contactDocument);
        }

        CallistaFileApiMock mock = new CallistaFileApiMock();
        mock.responseCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        // When: update the contact documents
        update contactDocMap.values();
        Test.stopTest();

        List<Contact_Document__c> contactDocuments = [
            SELECT Id
            FROM Contact_Document__c
            WHERE File_Upload_Successful__c = TRUE
        ];

        // Then: There should be no contact documents with file upload successful as the Document Owner Mismatch flag is checked
        Assert.areEqual(0, contactDocuments.size(), 'There must be no contact document with file upload successful');
    }

    /**
     * @description Test to ensure that Contact documents associated with Applications
     * in Submitted status, where the Document Owner Mismatch flag is changed from true to false, do get transferred to Callista.
     */
    @IsTest
    static private void testSendContactDocumentOnSubmittedApplicationWhenDocumentOwnerMismatchChangedToFalse() {
        // Given: Set the Document Owner Mismatch flag to true
        Map<Id, Contact_Document__c> contactDocMap = new Map<Id, Contact_Document__c>();
        for (Contact_Document__c contactDocument : [SELECT Id FROM Contact_Document__c WHERE Application__r.Status__c = 'Submitted']) {
            contactDocument.Submitted__c = true;
            contactDocument.Document_Owner_Mismatch__c = true;
            contactDocMap.put(contactDocument.Id, contactDocument);
        }
        update contactDocMap.values();

        List<Contact_Document__c> contactDocuments = [
            SELECT Id
            FROM Contact_Document__c
            WHERE File_Upload_Successful__c = TRUE
        ];

        //There should be no contact documents with file upload successful as the Document Owner Mismatch flag is checked
        Assert.areEqual(0, contactDocuments.size(), 'There must be no documents with file upload successful');

        CallistaFileApiMock mock = new CallistaFileApiMock();
        mock.responseCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        // When: update the contact documents
        for (Contact_Document__c contactDocument: contactDocMap.values()){
            contactDocument.Document_Owner_Mismatch__c = false;
        }
        update contactDocMap.values();
        Test.stopTest();

        List<Contact_Document__c> contactDocumentsAfterSetOwnerMismatchToFalse = [
            SELECT Id
            FROM Contact_Document__c
            WHERE File_Upload_Successful__c = TRUE
        ];

        // Then: There should be no contact documents with file upload successful as the Document Owner Mismatch flag is unchecked
        Assert.areEqual(2, contactDocumentsAfterSetOwnerMismatchToFalse.size(), 'There must be 2 contact documents with file upload successful');
    }
}