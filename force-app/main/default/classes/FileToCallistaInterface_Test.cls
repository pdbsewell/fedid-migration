/**
 * @author         J.Mapanao
 * @date           09.JAN.2020
 * @description    Test Class for FileToCallistaInterface Class
 * @revision
 * 09.JAN.2020     J.Mapanao - Initial Created
 * 08/02/2022      Vinothraja    - SFTG-2365 Added code to bulkify logging during & after callouts
 * 28/08/2024      Kai-Fan Hsieh - DANO-31 Add code to test appending channel field to comments that are sent to Callista
 */
@IsTest(IsParallel=true)
private class FileToCallistaInterface_Test {

    @IsTest
    private static void testContentTypeUnidentified() {
        // Given: Test data is created and a contact document of type 'PORTFOLIO' is retrieved
        List<Contact_Document__c> contactPortfolio = getContactDocumentByDocumentType('PORTFOLIO');
        String contactDocRec = JSON.serialize(contactPortfolio[0]);
        List<Application__c> applications = [SELECT Id FROM Application__c];

        ContentDocumentLink cdl = getContentDocumentLink(contactPortfolio[0].Id);
        String cdlRec = JSON.serialize(cdl);
        ContentDocument cd = getContentDocumentById(cdl.ContentDocumentId);
        String cdRec = JSON.serialize(cd);

        System.runAs(getAutoProcUser()) {
            Test.startTest();
            CallistaFileApiMock mock = new CallistaFileApiMock();
            mock.responseCode = 200;
            Test.setMock(HttpCalloutMock.class, mock);

            // When: FileToCallistaInterface is initialized and the message is sent
            List<FileToCallistaInterface> callistaRequests2 = new List<FileToCallistaInterface>();
            FileToCallistaInterface fci2 = new FileToCallistaInterface(contactDocRec, cdlRec, cdRec, applications[0].Id, null);
            callistaRequests2.add(fci2);
            fci2.sendMessage();
            fci2.handleResponse();

            // Then: The content type should be 'application/octet-stream'
            ObdSendDocumentsServiceRequest req2 = (ObdSendDocumentsServiceRequest) JSON.deserialize(
                JSON.serializePretty(fci2.jsonRequest), ObdSendDocumentsServiceRequest.class
            );
            System.assertEquals('application/octet-stream', req2.events[0].contentType, 'It is a wrong content Type');
            Test.stopTest();
        }
    }

    @IsTest
    private static void testContentTypePG() {
        // Given: Test data is created and a contact document of type 'PARENT_GUARDIAN' is retrieved
        List<Contact_Document__c> contactDocumentPG = getContactDocumentByDocumentType('PARENT_GUARDIAN');
        String contactDocRec = JSON.serialize(contactDocumentPG[0]);
        List<Application__c> applications = [SELECT Id FROM Application__c];

        // When: FileToCallistaInterface is initialized and the message is sent
        ContentDocumentLink cdl = getContentDocumentLink(contactDocumentPG[0].Id);
        String cdlRec = JSON.serialize(cdl);
        ContentDocument cd = getContentDocumentById(cdl.ContentDocumentId);
        String cdRec = JSON.serialize(cd);

        System.runAs(getAutoProcUser()) {
            Test.startTest();
            CallistaFileApiMock mock = new CallistaFileApiMock();
            mock.responseCode = 200;
            Test.setMock(HttpCalloutMock.class, mock);

            List<FileToCallistaInterface> callistaRequests2 = new List<FileToCallistaInterface>();
            FileToCallistaInterface fci2 = new FileToCallistaInterface(contactDocRec, cdlRec, cdRec, applications[0].id, null);
            callistaRequests2.add(fci2);
            fci2.sendMessage();
            fci2.handleResponse();

            // Then: The content type should be 'image/png'
            ObdSendDocumentsServiceRequest req2 = (ObdSendDocumentsServiceRequest) JSON.deserialize(
                JSON.serializePretty(fci2.jsonRequest), ObdSendDocumentsServiceRequest.class
            );
            Assert.areEqual('image/png', req2.events[0].contentType, 'It is a wrong content Type');
            Test.stopTest();
        }
    }

    @IsTest
    private static void testContentTypeOthers() {
        // Given: Test data is created and a contact document of type 'OTHERDCTYP' is retrieved
        List<Contact_Document__c> contactDocumentOthers = getContactDocumentByDocumentType('OTHERDCTYP');
        String contactDocRec = JSON.serialize(contactDocumentOthers[0]);
        List<Application__c> applications = [SELECT Id FROM Application__c];

        // When: FileToCallistaInterface is initialized and the message is sent
        ContentDocumentLink cdl = getContentDocumentLink(contactDocumentOthers[0].Id);
        String cdlRec = JSON.serialize(cdl);
        ContentDocument cd = getContentDocumentById(cdl.ContentDocumentId);
        String cdRec = JSON.serialize(cd);

        System.runAs(getAutoProcUser()) {
            Test.startTest();
            CallistaFileApiMock mock = new CallistaFileApiMock();
            mock.responseCode = 200;
            Test.setMock(HttpCalloutMock.class, mock);

            List<FileToCallistaInterface> callistaRequests2 = new List<FileToCallistaInterface>();
            FileToCallistaInterface fci2 = new FileToCallistaInterface(contactDocRec, cdlRec, cdRec, applications[0].Id, null);
            callistaRequests2.add(fci2);
            fci2.sendMessage();
            fci2.handleResponse();

            // Then: The content type should be 'image/jpeg'
            ObdSendDocumentsServiceRequest req2 = (ObdSendDocumentsServiceRequest) JSON.deserialize(
                JSON.serializePretty(fci2.jsonRequest), ObdSendDocumentsServiceRequest.class
            );
            Assert.areEqual('image/jpeg', req2.events[0].contentType, 'It is a wrong content Type');
            Test.stopTest();
        }
    }

    @IsTest
    private static void testContentTypeEducationResult() {
        // Given: Test data is created and a contact document of type 'TERTED_TRA' is retrieved
        List<Contact_Document__c> contactDocumentEducationResult = getContactDocumentByDocumentType('TERTED_TRA');
        String contactDocRec = JSON.serialize(contactDocumentEducationResult[0]);
        List<Application__c> applications = [SELECT Id FROM Application__c];

        // When: FileToCallistaInterface is initialized and the message is sent
        ContentDocumentLink cdl = getContentDocumentLink(contactDocumentEducationResult[0].Id);
        String cdlRec = JSON.serialize(cdl);
        ContentDocument cd = getContentDocumentById(cdl.ContentDocumentId);
        String cdRec = JSON.serialize(cd);

        System.runAs(getAutoProcUser()) {
            Test.startTest();
            CallistaFileApiMock mock = new CallistaFileApiMock();
            mock.responseCode = 200;
            Test.setMock(HttpCalloutMock.class, mock);

            List<FileToCallistaInterface> callistaRequests2 = new List<FileToCallistaInterface>();
            FileToCallistaInterface fci2 = new FileToCallistaInterface(contactDocRec, cdlRec, cdRec, applications[0].Id, null);
            callistaRequests2.add(fci2);
            fci2.sendMessage();
            fci2.handleResponse();

            // Then: The content type should be 'application/pdf'
            ObdSendDocumentsServiceRequest req2 = (ObdSendDocumentsServiceRequest) JSON.deserialize(
                JSON.serializePretty(fci2.jsonRequest), ObdSendDocumentsServiceRequest.class
            );
            Assert.areEqual('application/pdf', req2.events[0].contentType, 'It is a wrong content Type');
            Assert.areEqual('[Channel: CSSD]', req2.events[0].comments, 'Expected channel field to be assigned to comments');
            Test.stopTest();
        }
    }

    @IsTest
    private static void testContentTypeEducationResultWithExistingComments() {
        // Given: Test data is created and a contact document of type 'TERTED_TRA' is retrieved
        List<Contact_Document__c> contactDocumentEducationResult = getContactDocumentByDocumentType('TERTED_TRA');
        contactDocumentEducationResult[0].Comments__c = 'Test.';
        update contactDocumentEducationResult[0];
        String contactDocRec = JSON.serialize(contactDocumentEducationResult[0]);
        List<Application__c> applications = [SELECT Id FROM Application__c];

        // When: FileToCallistaInterface is initialized and the message is sent
        ContentDocumentLink cdl = getContentDocumentLink(contactDocumentEducationResult[0].Id);
        String cdlRec = JSON.serialize(cdl);
        ContentDocument cd = getContentDocumentById(cdl.ContentDocumentId);
        String cdRec = JSON.serialize(cd);

        System.runAs(getAutoProcUser()) {
            Test.startTest();
            CallistaFileApiMock mock = new CallistaFileApiMock();
            mock.responseCode = 200;
            Test.setMock(HttpCalloutMock.class, mock);

            List<FileToCallistaInterface> callistaRequests2 = new List<FileToCallistaInterface>();
            FileToCallistaInterface fci2 = new FileToCallistaInterface(contactDocRec, cdlRec, cdRec, applications[0].Id, null);
            callistaRequests2.add(fci2);
            fci2.sendMessage();
            fci2.handleResponse();

            // Then: The content type should be 'application/pdf'
            ObdSendDocumentsServiceRequest req2 = (ObdSendDocumentsServiceRequest) JSON.deserialize(
                JSON.serializePretty(fci2.jsonRequest), ObdSendDocumentsServiceRequest.class
            );
            Assert.areEqual('application/pdf', req2.events[0].contentType, 'It is a wrong content Type');
            Assert.areEqual('Test. [Channel: CSSD]', req2.events[0].comments, 'Expected channel field to be appended to comments');
            Test.stopTest();
        }
    }

    @TestSetup
    private static void createTestData() {
        // Given: Initial test data is created for contacts, contact documents, applications, and content versions
        Contact newContact = new Contact(
            FirstName = 'TestContact',
            LastName = 'TestContact',
            Person_ID_unique__c = 'IDA'
        );
        insert newContact;

        Application__c application = new Application__c(
            Applicant__c = newContact.Id,
            Campus_Location__c = null,
            Visa_Type__c = null,
            Australian_Immigration_Office_Issued__c = null,
            Visa_Number__c = null,
            Passport_Number__c = null,
            Visa_Start_Date__c = null,
            Visa_End_Date__c = null,
            Refused_entry_visa_to_any_country__c = null,
            Breached_visa_condition__c = null,
            Medical_health_prevent_visa__c = null,
            Protection_visa_in_any_country__c = null,
            Convicted_of_crime_offence__c = null
        );
        insert application;

        Contact_Document__c contactDocumentParentGuardian = new Contact_Document__c(
            Contact__c = newContact.Id,
            Document_Type__c = 'PARENT_GUARDIAN',
            Filename__c = 'ParentSignature',
            File_Upload_Successful__c = false
        );
        insert contactDocumentParentGuardian;
        insertContentVersionData('png', application.Id, contactDocumentParentGuardian.Id);

        Contact_Document__c contactDocumentOther = new Contact_Document__c(
            Contact__c = newContact.Id,
            Document_Type__c = 'OTHERDCTYP',
            Filename__c = 'Others',
            File_Upload_Successful__c = false
        );
        insert contactDocumentOther;
        insertContentVersionData('jpg', application.Id, contactDocumentOther.Id);

        Contact_Document__c contactDocumentPortfolio = new Contact_Document__c(
            Contact__c = newContact.Id,
            Document_Type__c = 'PORTFOLIO',
            Filename__c = 'Portfolio',
            File_Upload_Successful__c = false
        );
        insert contactDocumentPortfolio;
        insertContentVersionData('oct', application.Id, contactDocumentPortfolio.Id);

        Contact_Document__c contactDocumentEducationResult = new Contact_Document__c(
            Contact__c = newContact.Id,
            Document_Type__c = 'TERTED_TRA',
            Channel__c = 'CSSD',
            Filename__c = 'EducationResult',
            File_Upload_Successful__c = false
        );
        insert contactDocumentEducationResult;
        insertContentVersionData('pdf', application.Id, contactDocumentEducationResult.Id);
    }

    private static void insertContentVersionData(String fileExtension, Id applicationId, Id contactDocumentId) {
        Blob bodyBlob = Blob.valueOf('Unit Test ContentVersion Body');
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test',
            PathOnClient = '/Header_Picture1.' + fileExtension,
            VersionData = bodyBlob,
            Origin = 'H'
        );
        insert contentVersion;

        ContentVersion contentVersionInserted = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1];
        insert new ContentDocumentLink(
            LinkedEntityId = applicationId,
            ContentDocumentId = contentVersionInserted.ContentDocumentId,
            ShareType = 'V'
        );

        insert new ContentDocumentLink(
            LinkedEntityId = contactDocumentId,
            ContentDocumentId = contentVersionInserted.ContentDocumentId,
            ShareType = 'V'
        );
    }

    private static ContentDocumentLink getContentDocumentLink(Id linkedEntityId) {
        return [
            SELECT Id,
                ContentDocumentId,
                ContentDocument.LatestPublishedVersionId,
                LinkedEntityId
            FROM
                ContentDocumentLink
            WHERE LinkedEntityId = :linkedEntityId
            LIMIT 1
        ];
    }

    private static ContentDocument getContentDocumentById(Id contentDocumentId) {
        return [
            SELECT
                Id,
                Title,
                LatestPublishedVersionId,
                FileExtension,
                ArchivedById,
                ArchivedDate,
                ContentAssetId,
                ContentModifiedDate,
                ContentSize,
                Description,
                FileType,
                IsArchived,
                LastReferencedDate,
                LastViewedDate,
                OwnerId,
                ParentId,
                PublishStatus,
                SharingOption,
                SharingPrivacy
            FROM
                ContentDocument
            WHERE Id = :contentDocumentId
            LIMIT 1
        ];
    }

    private static List<Contact_Document__c> getContactDocumentByDocumentType(String documentType) {
        return [
            SELECT
                Id,
                File_Upload_Successful__c,
                Contact__c,
                Comments__c,
                Contact__r.Person_ID__c,
                Contact_Qualification__c,
                Document_Type__c,
                Document_Type_Name__c,
                Filename__c,
                Has_API_Request__c,
                Has_API_Response__c,
                API_Request__c,
                Submitted__c,
                Type__c,
                Channel__c
            FROM Contact_Document__c
            WHERE Document_Type__c = :documentType
        ];
    }

    private static User getAutoProcUser() {
        return [SELECT Id FROM User WHERE Alias = 'autoproc' LIMIT 1];
    }
}