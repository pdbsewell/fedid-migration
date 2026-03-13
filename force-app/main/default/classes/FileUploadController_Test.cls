/**
 * Created by trentdelaney on 3/8/18.
 */

@isTest(isParallel=true)
private class FileUploadController_Test {


    static String getDocumentTypeValue(Integer i)
    {
        Schema.DescribeFieldResult fieldResult = Contact_Document__c.Document_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        Schema.PicklistEntry pleAtI = ple[i];

        if(pleAtI != null)
            return pleAtI.getValue();
        return null;
    }


    static ContentDocument createTestDocument(Boolean allAccess)
    {
        // create a file
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body');
        ContentVersion cv = new ContentVersion(
                Title='Header_Picture1',
                PathOnClient ='/Header_Picture1.jpg',
                VersionData = bodyBlob,
                origin = 'H'
        );


        insert cv;

        // retrieve it again to get the ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE id =: cv.Id];

        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId
        FROM ContentDocument
        WHERE id=:cv.ContentDocumentId];
        ContentDocument file = documents[0];

        if(allAccess)
        {
            ContentDocumentLink cdLink = new ContentDocumentLink();
            cdLink.LinkedEntityId = UserInfo.getOrganizationId();
            cdLink.ContentDocumentId = cv.ContentDocumentId;
            cdLink.ShareType = 'C';
            cdLink.Visibility = 'AllUsers';

            insert cdLink;

        }

        return file;
    }



    TestMethod
    public static void test_getInitLoad()
    {
        // create community user
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        // create application
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        insert app;

        Schema.DescribeFieldResult fieldResult = Contact_Document__c.Document_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        Test.startTest();
        System.runAs(applicant) {
            Map<String, Object> mapResults = FileUploadController.getInitLoad(app.Id);
            Id contactId = (Id) mapResults.get(FileUploadController.FIELD_CONTACT_ID);
            System.assertEquals(c.Id, contactId, 'Contact Id should be returned');

            List<Map<String, String>> docTypes = (List<Map<String, String>>) mapResults.get(FileUploadController.FIELD_DOCUMENT_TYPES);
            System.assertEquals(ple.size(), docTypes.size(), 'The Document Types should match');
        }

        Test.stopTest();
    }

    TestMethod
    public static void test_badDocTypeValue()
    {
        Test.startTest();
        String sValue = FileUploadController.getDocTypeLabel('');
        System.assertEquals('', sValue, 'Bad value should give a blank string');
        Test.stopTest();
    }


    TestMethod
    public static void test_deleteUploadedFile()
    {
        // create community user
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        ContentDocument file = createTestDocument(true);

        Test.startTest();
        System.runAs(applicant) {

            Map<String, Object> mapResults = FileUploadController.deleteUploadedFile(file.Id);
            String deleteStatus = (String) mapResults.get(FileUploadController.FIELD_DELETE_STATUS);
            System.assertEquals(FileUploadController.SUCCESS, deleteStatus, 'File should have been deleted');



            Map<String, Object> mapResultsNull = FileUploadController.deleteUploadedFile(null);
            deleteStatus = (String) mapResultsNull.get(FileUploadController.FIELD_DELETE_STATUS);
            System.assertEquals(FileUploadController.FAILED, deleteStatus, 'Null Id should have failed');

        }

        Test.stopTest();
    }

    TestMethod
    public static void test_saveFileAndContactDocument()
    {
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        Application__c app = StudFirst_TestHelper.createApplication(c);
        insert app;

        ContentDocument file = createTestDocument(true);

        String docTypeValue = getDocumentTypeValue(0);
        String docSubType = '';
        String comments = 'testing some comments ';

        Test.startTest();
        System.runAs(applicant)
        {
            // SUCCESS
            Map<String, Object> mapResults = FileUploadController.saveFileAndContactDocument(file.Id, c.Id, app.Id,docTypeValue, docSubType, comments);
            String saveStatus = (String) mapResults.get(FileUploadController.FIELD_SAVE_STATUS);
            System.assertEquals(FileUploadController.SUCCESS, saveStatus, 'Save should have completed successfully');

            // bad file Id
            mapResults = FileUploadController.saveFileAndContactDocument(c.Id, c.Id, app.Id,docTypeValue, docSubType, comments);
            saveStatus = (String) mapResults.get(FileUploadController.FIELD_SAVE_STATUS);
            System.assertEquals(FileUploadController.FAILED, saveStatus, 'Bad file Id should have failed');

            // no file Id
            mapResults = FileUploadController.saveFileAndContactDocument(null, c.Id, app.Id,docTypeValue, docSubType, comments);
            saveStatus = (String) mapResults.get(FileUploadController.FIELD_SAVE_STATUS);
            System.assertEquals(FileUploadController.FAILED, saveStatus, 'No file Id should have failed');
        }
        Test.stopTest();
    }

    TestMethod
    public static void test_RemoveContactDocument()
    {
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        Application__c app = StudFirst_TestHelper.createApplication(c);
        insert app;

        ContentDocument file = createTestDocument(true);

        String docTypeValue = getDocumentTypeValue(0);
        String docSubType = '';
        String comments = 'testing some comments ';

        Test.startTest();
        System.runAs(applicant)
        {
            // SUCCESSFUL SAVE
            Map<String, Object> mapResults = FileUploadController.saveFileAndContactDocument(file.Id, c.Id, app.Id,docTypeValue, docSubType, comments);
            String saveStatus = (String) mapResults.get(FileUploadController.FIELD_SAVE_STATUS);
            System.assertEquals(FileUploadController.SUCCESS, saveStatus, 'Save should have completed successfully');

            // REMOVE no Bad ConDoc Id
            Map<String, Object> mapRemove = FileUploadController.RemoveContactDocument(app.Id, app.Id);
            String deleteStatus = (String) mapRemove.get(FileUploadController.FIELD_DELETE_STATUS);
            System.assertEquals(FileUploadController.FAILED, deleteStatus, 'Contact Document should have failed for a bad Contact Document Id');

            // SUCCESSFUL REMOVE
            List<Contact_Document__c> listConDocs = (List<Contact_Document__c>) mapResults.get(FileUploadController.FIELD_CONTACT_DOCUMENTS);
            Contact_Document__c conDoc = listConDocs[0];
            mapRemove = FileUploadController.RemoveContactDocument(conDoc.Id, app.Id);
            System.debug('test_RemoveContactDocument::mapRemove = ' + mapRemove);

            deleteStatus = (String) mapRemove.get(FileUploadController.FIELD_DELETE_STATUS);
            System.assertEquals(FileUploadController.SUCCESS, deleteStatus, 'Contact Document should have succeeded');
        }
        Test.stopTest();
    }


    TestMethod
    public static void test_SubmitDocuments()
    {
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        Application__c app = StudFirst_TestHelper.createApplication(c);
        insert app;

        ContentDocument file = createTestDocument(true);

        String docTypeValue = getDocumentTypeValue(0);
        String docSubType = '';
        String comments = 'testing some comments ';

        Test.startTest();
        System.runAs(applicant)
        {
            // SUCCESSFUL SAVE
            Map<String, Object> mapResults = FileUploadController.saveFileAndContactDocument(file.Id, c.Id, app.Id,docTypeValue, docSubType, comments);
            String saveStatus = (String) mapResults.get(FileUploadController.FIELD_SAVE_STATUS);
            System.assertEquals(FileUploadController.SUCCESS, saveStatus, 'Save should have completed successfully');

            // Submit Documents
            Boolean result = FileUploadController.SubmitDocuments(app.Id, true);
            System.assertEquals(true, result, 'Submit should pass');
        }
        Test.stopTest();
    }


    /*

    static String getDocumentTypeLabel(Integer i)
    {
        Schema.DescribeFieldResult fieldResult = Contact_Document__c.Document_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        Schema.PicklistEntry pleAtI = ple[i];

        if(pleAtI != null)
            return pleAtI.getLabel();
        return null;
    }

    static ContentDocument createTestDocument()
    {
        // create a file
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body');
        ContentVersion cv = new ContentVersion(
                Title='Header_Picture1',
                PathOnClient ='/Header_Picture1.jpg',
                VersionData = bodyBlob,
                origin = 'H'
        );
        insert cv;

        // retrieve it again to get the ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE id =: cv.Id];

        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId
        FROM ContentDocument
        WHERE id=:cv.ContentDocumentId];
        ContentDocument file = documents[0];

        return file;
    }

    static ContentDocumentLink linkFileToContactDocument(Id fileId, Id cdId)
    {
        ContentDocumentLink cdLink = new ContentDocumentLink();
        cdLink.ContentDocumentId = fileId;
        cdLink.LinkedEntityId = cdId;
        cdLink.ShareType = 'v';
        cdLink.Visibility = 'AllUsers';
        insert cdLink;

        return cdLink;
    }


    @isTest
    static void test_GetContactDocuments() {
        Contact applicant = StudFirst_TestHelper.createApplicant();
        insert applicant;
        Application__c app = StudFirst_TestHelper.createApplication(applicant);
        insert app;

        Contact_Document__c doc = StudFirst_TestHelper.createContactDocument(applicant.Id);
        insert doc;

        List<Contact_Document__c> documents = FileUploadController.GetContactDocuments(app.Id);

        System.assert(documents.size() > 0);
    }

    @isTest
    public static void test_CreateContactDocument() {
        Contact c = StudFirst_TestHelper.createApplicant();
        insert c;

        Application__c app = StudFirst_TestHelper.createApplication(c);
        insert app;

        //Document Types - References an object not data.
        //Contact_Document__c doc = FileUploadController.CreateContactDocument('EMPREFRNCE', 'Document_Type__c', 'Contact_Document__c');
        Contact_Document__c doc = FileUploadController.CreateContactDocument('Qualification: Secondary School Results', '', app.Id);

        System.assertNotEquals(null, doc);
    }

    @isTest
    public static void test_InvalidCreateContactDocument() {
        Contact c = StudFirst_TestHelper.createApplicant();
        insert c;

        Application__c app = StudFirst_TestHelper.createApplication(c);
        insert app;

        Contact_Document__c doc = FileUploadController.CreateContactDocument('Qualification: Secondary School Results', '', 'novalue');
        System.assertEquals(null, doc);
    }

    TestMethod
    public static void test_UpdateContactDocument() {
        Contact c = StudFirst_TestHelper.createApplicant();
        insert c;

        Application__c app = StudFirst_TestHelper.createApplication(c);
        insert app;

        String docType = getDocumentTypeLabel(0);
        Contact_Document__c doc = FileUploadController.CreateContactDocument(docType, '', app.Id);
        System.assertNotEquals(null, doc, 'Contact Document should be created');

        ContentDocument file = createTestDocument();
        ContentDocumentLink cdLink = linkFileToContactDocument(file.Id, doc.Id);
        System.assertNotEquals(null, cdLink, 'File should have been linked to Contact Document');


        Contact_Document__c returnedDoc = FileUploadController.UpdateContactDocument(doc.Id, docType, '', 'This is a test comment', file.Title);

        //System.assertNotEquals(doc, returnedDoc, '');
        System.assertNotEquals(null, returnedDoc.Filename__c, 'File name should have been updated');
        System.assertNotEquals(null, returnedDoc.Comments__c, 'Comments should have been populated');

    }

    @isTest
    public static void test_RemoveContactDocument() {
        Contact c = StudFirst_TestHelper.createApplicant();
        insert c;

        Application__c app = StudFirst_TestHelper.createApplication(c);
        insert app;

        Contact_Document__c doc = FileUploadController.CreateContactDocument('Qualification: Secondary School Results', '', app.Id);
        System.assertNotEquals(null, doc);
        ContentDocument file = createTestDocument();
        ContentDocumentLink cdLink = linkFileToContactDocument(file.Id, doc.Id);

        Boolean result = FileUploadController.RemoveContactDocument(doc.Id);

        System.assertEquals(true, result);
    }

    @isTest public static void test_RemoveBadContactDocument() {
        Contact c = StudFirst_TestHelper.createApplicant();
        insert c;

        Application__c app = StudFirst_TestHelper.createApplication(c);
        insert app;

        Contact_Document__c doc = FileUploadController.CreateContactDocument('Qualification: Secondary School Results', '', app.Id);
        System.assertNotEquals(null, doc);

        Boolean result = FileUploadController.RemoveContactDocument('badId');

        System.assertEquals(false, result);
    }

    @isTest
    public static void test_GetPicklistValues() {
        List<String> values = FileUploadController.GetPicklistValues('Document_Type__c', 'Contact_Document__c');

        System.assert(values.size() > 0);
    }


    TestMethod
    public static void test_AddApplicationFile_NoDelete()
    {
        Contact c = StudFirst_TestHelper.createApplicant();
        insert c;

        Application__c app = StudFirst_TestHelper.createApplication(c);
        insert app;

        Contact_Document__c doc = FileUploadController.CreateContactDocument('Qualification: Secondary School Results', '', app.Id);
        System.assertNotEquals(null, doc);
        ContentDocument file = createTestDocument();
        ContentDocumentLink cdLink = linkFileToContactDocument(file.Id, doc.Id);

        Test.startTest();
        Map<String, Object> mapResults = FileUploadController.AddApplicationFile(app.Id, file.Id, doc.Id);
        String saveStatus = (String) mapResults.get(FileUploadController.FIELD_SAVE_STATUS);
        System.assertEquals(FileUploadController.SUCCESS, saveStatus, 'Save should have succeeded');
        Test.stopTest();
    }


    TestMethod
    public static void test_AddApplicationFile_WithDelete()
    {
        Contact c = StudFirst_TestHelper.createApplicant();
        insert c;

        Application__c app = StudFirst_TestHelper.createApplication(c);
        insert app;

        Contact_Document__c doc = FileUploadController.CreateContactDocument('Qualification: Secondary School Results', '', app.Id);
        System.assertNotEquals(null, doc);
        ContentDocument file1 = createTestDocument();
        ContentDocumentLink cdLink1 = linkFileToContactDocument(file1.Id, doc.Id);

        ContentDocument file2 = createTestDocument();
        ContentDocumentLink cdLink2 = linkFileToContactDocument(file2.Id, doc.Id);

        Test.startTest();
        Map<String, Object> mapResults = FileUploadController.AddApplicationFile(app.Id, file2.Id, doc.Id);
        String saveStatus = (String) mapResults.get(FileUploadController.FIELD_SAVE_STATUS);
        System.assertEquals(FileUploadController.SUCCESS, saveStatus, 'Save should have succeeded');

        List<ContentDocument> delFiles = [SELECT Id FROM ContentDocument WHERE Id =: file1.Id];
        System.assertEquals(0, delFiles.size(), 'File 1 should have been deleted');

        List<ContentDocumentLink> delLinks = [SELECT Id FROM ContentDocumentLink WHERE Id =: cdLink1.Id];
        System.assertEquals(0, delLinks.size(), 'Link 1 should have been deleted');

        Test.stopTest();
    }
    */

}