/**
 * @author      Kristian Vegerano
 * @description Test class for SendContentDocQueuable batch class
 * @group       Test Class
 * @revision    
 * 08/01/2020 - Kristian Vegerano - Created
 * 08/02/2022 - Vinothraja - SFTG-2365 Added code to bulkify logging during & after callouts
 * @revision    15.MAR.2024 Ven Vairavan > Update Mule4 endpoints.
 *              08.NOV.2024 Kai-Fan Hsieh - DANO-347: Test prevent sending documents have owner mismatch flag checked to callista
 */
@isTest(isParallel=false) /*System.TypeException: Test.getStandardPricebookId() cannot be called from parallel Apex tests */
private class SendContentDocQueuable_Test {
    @testSetup
    static void setup() {
        //Price book Creation
        TestDataFactory.createSObject(new Pricebook2(), true);

        //Creating a product for scholarship
        Product2 product1 = (Product2) TestDataFactory.createSObject(new Product2(Name = 'Monash Scholarship1', External_Id__c = '12345', Expiry_days__c = 15), true);
        //product always required a standard pricebook         
        PricebookEntry pbe1 = (PricebookEntry) TestDataFactory.createSObject(new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = product1.id, unitprice = -5000), true);

        //Create a community user
        User communityUserRec = StudFirst_TestHelper.createCommunityUser();
        TriggerCommon.disableTrigger('Application__c');
        List<Application__c> appList = new List<Application__c>();
        //create a Submitted application
        Application__c appRecord = StudFirst_TestHelper.createApplication(communityUserRec.ContactId);
        appRecord.Status__c = 'Submitted';
        appRecord.Callista_Application_Id__c = '012345678';
        appList.add(appRecord);

        //create a new draft application
        Application__c draftAppRecord = StudFirst_TestHelper.createApplication(communityUserRec.ContactId);
        draftAppRecord.Status__c = 'Draft';
        appList.add(draftAppRecord);
        insert appList;
        TriggerCommon.enableTrigger('Application__c');

        Contact contactRec = [SELECT Id, Residency_Status__c, AccountId, bulkapi_Applicant_Ids__c FROM Contact WHERE Id = :communityUserRec.ContactId];
        contactRec.Residency_Status__c = 'DOM-AUS';
        contactRec.bulkapi_Applicant_Ids__c = '1233333';
        TriggerCommon.disableTrigger('Contact');
        update contactRec;
        TriggerCommon.enableTrigger('Contact');

        //Tertiary institution & qualification
        Institution__c tertInsRec = StudFirst_TestHelper.createTertiaryInstitution();
        insert tertInsRec;

        Callista_Outcome_Status__c outcomeStatus = StudFirst_TestHelper.createOutcomeStatus();
        insert outcomeStatus;

        Contact_Qualification__c conQualRec = new Contact_Qualification__c();
        conQualRec.Country__c = 'Australia';
        conQualRec.First_Year_Enrolled__c = String.valueOf(date.today().year() - 4);
        conQualRec.Last_Year_Enrolled__c = String.valueOf(date.today().year());
        conQualRec.Other_Qualification__c = 'Certificate III';
        conQualRec.Institution_Code__c = tertInsRec.Institution_Code__c;
        conQualRec.Institution_Name__c = tertInsRec.Institution_Name__c;
        conQualRec.Status__c = 'CURRENTLY STUDYING';
        conQualRec.Contact__c = contactRec.Id;
        conQualRec.RecordTypeId = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByName().get('Tertiary Education').getRecordTypeId();
        TriggerCommon.disableTrigger('Contact_Qualification__c');
        insert conQualRec;
        TriggerCommon.enableTrigger('Contact_Qualification__c');

        Application_Qualification_Provided__c aqpRecord = new Application_Qualification_Provided__c();
        aqpRecord.Application__c = appRecord.Id;
        aqpRecord.Contact_Qualification__c = conQualRec.Id;
        insert aqpRecord;

        Work_Experience__c workExpRecord = new Work_Experience__c();
        workExpRecord = StudFirst_TestHelper.populateWorkExperienceRecord(workExpRecord);
        workExpRecord.Contact__c = contactRec.Id;
        insert workExpRecord;

        TriggerCommon.disableTrigger('Contact_Document__c');
        List<Contact_Document__c> cdocsList = new List<Contact_Document__c>();
        Contact_Document__c contactDocu = new Contact_Document__c();
        contactDocu = StudFirst_TestHelper.createContactDocument(contactRec.Id);
        contactDocu.Application__c = appRecord.Id;
        cdocsList.add(contactDocu);

        Application__c draft = [select id from Application__c where status__C = 'Draft'];
        Contact_Document__c draftContactDoc = new Contact_Document__c();
        draftContactDoc = StudFirst_TestHelper.createContactDocument(contactRec.Id);
        draftContactDoc.Application__c = draft.Id;
        cdocsList.add(draftContactDoc);
        insert cdocsList;
        TriggerCommon.enableTrigger('Contact_Document__c');

        // create a file
        Blob bodyBlob = Blob.valueOf('Unit Test ContentVersion Body 1');
        ContentVersion cv = new ContentVersion(
            Title = 'Test File 1',
            PathOnClient = '/Test File1.jpg',
            VersionData = bodyBlob,
            origin = 'H'
        );
        insert cv;

        // retrieve it again to get the ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE id = :cv.Id];

        ContentDocumentLink cdLink1 = new ContentDocumentLink();
        cdLink1.LinkedEntityId = contactDocu.Id;
        cdLink1.ContentDocumentId = cv.ContentDocumentId;

        cdLink1.ShareType = 'v';
        cdLink1.Visibility = 'AllUsers';
        insert cdLink1;

        ContentDocumentLink cdLink3 = new ContentDocumentLink();
        cdLink3.LinkedEntityId = draftContactDoc.Id;
        cdLink3.ContentDocumentId = cv.ContentDocumentId;

        cdLink3.ShareType = 'v';
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

        //Start inserting quote
        Opportunity opp = (Opportunity) TestDataFactory.createSObject(new Opportunity(AccountId = contactRec.AccountId, PrimaryContact__c = contactRec.Id, Pricebook2Id = Test.getStandardPricebookId(), CloseDate = Date.today().addDays(15)), true);
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
        // create a file
        bodyBlob = Blob.valueOf('Unit Test ContentVersion Body 2');
        cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = '/Test File.jpg',
            VersionData = bodyBlob,
            Origin = 'H'
        );
        insert cv;

        // retrieve it again to get the ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE id = :cv.Id];

        ContentDocumentLink cdLink2 = new ContentDocumentLink();
        cdLink2.LinkedEntityId = opportunityContactDocument.Id;
        cdLink2.ContentDocumentId = cv.ContentDocumentId;

        cdLink2.ShareType = 'V';
        cdLink2.Visibility = 'AllUsers';
        insert cdLink2;
    }

    /**
     * @description Test to verify that Contact documents related to Applications/opportunity
     * in Submitted status only get transferred to Callista
     */
    @isTest
    static private void testSendContentDocQueue() {
        // Given: a list of contact documents of draft and submitted applications
        List<Id> contactDocIds = new List<Id>();
        for (Contact_Document__c cdRec : [
            SELECT Id
            FROM Contact_Document__c
        ]) {
            contactDocIds.add(cdRec.Id);
        }
        // Set mock response
        Test.setMock(HttpCalloutMock.class, new StudFirst_MockHttpResponseGenerator());
        Test.startTest();
        CallistaFileApiMock mock = new CallistaFileApiMock();
        mock.responseCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);
        // When: Enqueuing the SendContentDocQueuable to send documents to callista
        SendContentDocQueuable sdq = new SendContentDocQueuable(contactDocIds);
        System.enqueueJob(sdq);
        Test.stopTest();

        Set<String> cdIds = new Set<String>();
        for (Contact_Document__c cdRec : [
            SELECT Id
            FROM Contact_Document__c
            WHERE File_Upload_Successful__c = TRUE
        ]) {
            cdIds.add(cdRec.Id);
        }

        // Then: Only 2 documents got sent out successfully - from teh submitted application
        Assert.areEqual(2, cdIds.size(), 'There must be 2 Contact documents with file upload successful');
    }

    /**
    * @description Test to verify that Contact documents related to Applications
    * in Draft status does NOT get transferred to Callista
    */
    @isTest
    static private void testSendContactDocumentOnDraftApplication() {
        // Given: a draft application with contact documents
        List<Id> contactDocIds = new List<Id>();
        for (Contact_Document__c doc : [SELECT Id FROM Contact_Document__c WHERE Application__r.Status__c = 'Draft']) {
            contactDocIds.add(doc.Id);
        }
        Test.startTest();
        CallistaFileApiMock mock = new CallistaFileApiMock();
        mock.responseCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);
        // When: Send the contact document via queueable job
        SendContentDocQueuable sdq = new SendContentDocQueuable(contactDocIds);
        System.enqueueJob(sdq);

        Test.stopTest();

        Set<String> cdIds = new Set<String>();
        for (Contact_Document__c cdRec : [
            SELECT Id
            FROM Contact_Document__c
            WHERE File_Upload_Successful__c = TRUE
        ]) {
            cdIds.add(cdRec.Id);
        }
        // Then: no contact documents with file upload successful for Draft applications.
        Assert.areEqual(0, cdIds.size(), 'There must no Contact documents with file upload successful for Draft applications');
    }

    /**
    * @description Test to verify that Contact documents related to Applications
    * in Submitted status and the contact documents that have opportunity(with Application status=Submitted)
    * only gets transferred to Callista
    * Replicates Agent sending contact document with an opportunity/Application submission status
    */
    @isTest
    static private void testSendContactDocumentOnSubmittedApplication() {
        // Given: an submitted application with contact documents
        List<Id> contactDocIds = new List<Id>();
        for (Contact_Document__c doc : [SELECT Id FROM Contact_Document__c WHERE Application__r.Status__c = 'Submitted']) {
            contactDocIds.add(doc.Id);
        }
        Test.startTest();
        CallistaFileApiMock mock = new CallistaFileApiMock();
        mock.responseCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);
        // When: Send the contact document via queueable job
        SendContentDocQueuable sdq = new SendContentDocQueuable(contactDocIds);
        System.enqueueJob(sdq);

        Test.stopTest();

        Set<String> cdIds = new Set<String>();
        for (Contact_Document__c cdRec : [
            SELECT Id
            FROM Contact_Document__c
            WHERE File_Upload_Successful__c = TRUE
        ]) {
            cdIds.add(cdRec.Id);
        }
        // Then: The documents got sent out successfully - 1 for the Application and the other for the opportunity
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
        for (Contact_Document__c doc : [SELECT Id FROM Contact_Document__c WHERE Application__r.Status__c = 'Submitted']) {
            doc.Document_Owner_Mismatch__c = true;
            contactDocMap.put(doc.Id, doc);
        }
        update contactDocMap.values();

        Test.startTest();
        CallistaFileApiMock mock = new CallistaFileApiMock();
        mock.responseCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);

        // When: Enqueuing the SendContentDocQueuable to send documents to callista
        new SendContentDocQueuable(new List<Id>(contactDocMap.keySet()));
        Test.stopTest();

        List<Contact_Document__c> contactDocuments = [
            SELECT Id
            FROM Contact_Document__c
            WHERE
                File_Upload_Successful__c = TRUE AND
                Document_Owner_Mismatch__c = TRUE
        ];

        // Then: There should be no contact documents with file upload successful
        Assert.areEqual(0, contactDocuments.size(), 'There must be no contact document with file upload successful');
    }
}