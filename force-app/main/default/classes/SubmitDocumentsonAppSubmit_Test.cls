/*******************************************************************************
* @author		J.Mapanao
* @date         08.JAN.2020     
* @description  test class for SubmitDocumentsonAppSubmit.cls
* @revision     08.JAN.2020 - J.Mapanao - Initial Created
* 08/02/2022 - Vinothraja   - SFTG-2365 Added code to bulkify logging during & after callouts
* 08/11/2024 - Kai-Fan Hsieh - DANO-347: Test prevent sending documents have owner mismatch flag checked to callista
*******************************************************************************/
@IsTest(IsParallel=false) //APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object: User: []
private class SubmitDocumentsonAppSubmit_Test {
    private static final Integer NUMBER_OF_DOCUMENTS = 2;

    /**
    * @description : Test submission of multiple docs
    */
    @IsTest
    private static void testMultipleDocumentSubmission() {
        // Given: An application with multiple documents
        Application__c app = [SELECT Id, Status__c FROM Application__c LIMIT 1];
        Test.startTest();
        CallistaFileApiMock mock = new CallistaFileApiMock();
        mock.responseCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);
        // When: submitDocumentsToCallista is called
        SubmitDocumentsonAppSubmit.submitDocumentsToCallista(app.Id);
        Test.stopTest();
        // Then: The documents are sent to Callista
        List<Contact_Document__c> contactDocuments = [
            SELECT Id, Application__c
            FROM Contact_Document__c
            WHERE File_Upload_Successful__c = TRUE
        ];
        Assert.areEqual(
            NUMBER_OF_DOCUMENTS, contactDocuments.size(),
            'Expected ' + NUMBER_OF_DOCUMENTS + ' contact documents to be sent to Callista'
        );
    }

    /**
    * @description : Test submission of multiple docs with owner mismatch flag checked
    */
    @IsTest
    private static void testMultipleOwnerMismatchDocumentSubmission() {
        // Given: An application with multiple documents with owner mismatch
        Application__c app = [SELECT Id, Status__c FROM Application__c LIMIT 1];
        List<Contact_Document__c> existingContactDocuments = [SELECT Id FROM Contact_Document__c];
        for (Contact_Document__c contactDocument : existingContactDocuments) {
            contactDocument.Document_Owner_Mismatch__c = true;
        }
        update existingContactDocuments;

        Test.startTest();
        CallistaFileApiMock mock = new CallistaFileApiMock();
        mock.responseCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);
        // When: submitDocumentsToCallista is called
        SubmitDocumentsonAppSubmit.submitDocumentsToCallista(app.Id);
        Test.stopTest();
        // Then: The documents are not sent to Callista
        List<Contact_Document__c> contactDocuments = [
            SELECT Id, Application__c
            FROM Contact_Document__c
            WHERE File_Upload_Successful__c = TRUE AND Document_Owner_Mismatch__c = TRUE
        ];
        Assert.areEqual(0, contactDocuments.size(), 'Expected 0 contact documents to be sent to Callista');
    }

    @TestSetup
    static void makeData() {
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT Id FROM Contact WHERE Id = :applicant.contactId];
        Application__c app = StudFirst_TestHelper.createApplication(c);
        app.Status__c = 'Sent for Submission';
        insert app;
        createMultipleTestDocuments(true, app, c, NUMBER_OF_DOCUMENTS);
    }

    static void createMultipleTestDocuments(Boolean allAccess, Application__c app, Contact c, Integer noOfDocs) {
        // create files
        List<ContentVersion> lstFiles = new List<ContentVersion> ();
        for (Integer i = 0; i < noOfDocs; i++) {
            ContentVersion cv = new ContentVersion(
                Title = 'Test File ' + i,
                PathOnClient = '/Test_File_' + i + '.jpg',
                VersionData = EncodingUtil.base64Decode('Unit Test ContentVersion Body' + i),
                Origin = 'H'
            );
            lstFiles.add(cv);
        }
        insert lstFiles;

        // collect the contact Document IDs
        Set<Id> fileIds = new Set<Id> ();
        for (ContentVersion cv : lstFiles) {
            fileIds.add(cv.Id);
        }

        // retrieve it again to get the ContentDocumentId
        lstFiles = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :fileIds];
        Set<Id> contentDocumentIDs = new Set<Id> ();
        for (ContentVersion cv : lstFiles) {
            contentDocumentIDs.add(cv.ContentDocumentId);
        }

        // create Content Document Links
        List<ContentDocumentLink> lstContentDocumentLink = new List<ContentDocumentLink> ();
        List<Contact_Document__c> lstContactDocument = new List<Contact_Document__c> ();
        List<ContentDocument> lstDocuments = [
            SELECT Id, Title, LatestPublishedVersionId
            FROM ContentDocument
            WHERE Id IN :contentDocumentIDs
        ];
        for (ContentDocument document : lstDocuments) {

            if (allAccess) {
                ContentDocumentLink cdLink = new ContentDocumentLink();
                cdLink.LinkedEntityId = app.Id;
                cdLink.ContentDocumentId = document.Id;
                cdLink.ShareType = 'V';
                cdLink.Visibility = 'AllUsers';
                lstContentDocumentLink.add(cdLink);
            }
            // create Contact_Document__c
            Contact_Document__c contactDocument = new Contact_Document__c();
            contactDocument.Application__c = app.Id;
            contactDocument = StudFirst_TestHelper.createContactDocument(c.Id);
            contactDocument.Document_Type__c = 'PARENT_GUARDIAN';
            contactDocument.Submitted__c = true;
            lstContactDocument.add(contactDocument);
        }

        insert lstContentDocumentLink;
        insert lstContactDocument;

        // create Content Document Links
        Integer i = 0;
        lstContentDocumentLink.clear();
        for (Contact_Document__c contactDocument : lstContactDocument) {
            ContentDocumentLink cdLink1 = new ContentDocumentLink();
            cdLink1.LinkedEntityId = contactDocument.Id;
            cdLink1.ContentDocumentId = lstDocuments[i++].Id;
            cdLink1.ShareType = 'V';
            cdLink1.Visibility = 'AllUsers';
            lstContentDocumentLink.add(cdLink1);
        }
        insert lstContentDocumentLink;
    }
}