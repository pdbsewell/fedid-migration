/**
 * @author      Kristian Vegerano
 * @description Test class for ContactDocumentServices class
 * @group       Test Class
 * @revision    16/09/2019 - Kristian Vegerano - Created
 *  19/07/2023 Ken McGuire enhanced security around deletion of documents
 */
@IsTest/*(isParallel=true) APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object*/
public with sharing class ContactDocumentServices_Test {

    /**
     * @description Setup test data
     */
    @testSetup 
    static void setup() {
    }

    /**
     * @description Test saveFileAndContactDocument
     */
    @isTest 
    public static void test_saveFileAndContactDocument() {
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        // Create Qualifications
        Qualification__c qual1 = StudFirst_TestHelper.createQualification('Secondary');
        insert qual1;

        // Create Contact Qualifications
        Contact_Qualification__c cq1 = StudFirst_TestHelper.createContactQualification(c, qual1, 'Secondary Education');
        insert cq1;

        Application__c app = StudFirst_TestHelper.createApplication(c);
        insert app;

        ContentDocument file = createTestDocument(true);

        String docTypeValue = getDocumentTypeValue(0);
        String docSubType = '';
        String comments = 'testing some comments ';

        // Create application checklist for visa
        Document_Checklist__c checklistVisa = new Document_Checklist__c(
            Application__c = app.Id,
            Rule_DeveloperName__c = 'Visa_Check',
            Status__c = ContactDocumentServices.CHECKLIST_STATUS_REQUESTED,
            Unique_ID__c = String.valueOf(Date.today()),
            Allowed_Document_Type__c = 'OTHERDCTYP',
            Type__c = 'Visa'
        );
        insert checklistVisa;

        Test.startTest();
            // SUCCESS
            Map<String, Object> mapResults = ContactDocumentServices.saveFileAndContactDocumentChecklist(file.Id, c.Id, app.Id, docTypeValue, docSubType, comments, checklistVisa.Id, cq1.Id, null, false);
            String saveStatus = (String) mapResults.get(ContactDocumentServices.FIELD_SAVE_STATUS);
            System.assertEquals(ContactDocumentServices.SUCCESS, saveStatus, mapResults.get(ContactDocumentServices.FIELD_MESSAGE));

            // bad file Id
            mapResults = ContactDocumentServices.saveFileAndContactDocumentChecklist(c.Id, c.Id, app.Id, docTypeValue, docSubType, comments, checklistVisa.Id, cq1.Id, null, false);
            saveStatus = (String) mapResults.get(ContactDocumentServices.FIELD_SAVE_STATUS);
            System.assertEquals(ContactDocumentServices.FAILED, saveStatus, 'Bad file Id should have failed');

            // no file Id
            mapResults = ContactDocumentServices.saveFileAndContactDocumentChecklist(null, c.Id, app.Id, docTypeValue, docSubType, comments, checklistVisa.Id, cq1.Id, null, false);
            saveStatus = (String) mapResults.get(ContactDocumentServices.FIELD_SAVE_STATUS);
            System.assertEquals(ContactDocumentServices.FAILED, saveStatus, 'No file Id should have failed');
        Test.stopTest();
    }

    /**
     * @description Test removeContactDocument
     */
    @isTest
    public static void test_RemoveContactDocumentCommunityUser() {
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        // Create Qualifications
        Qualification__c qual1 = StudFirst_TestHelper.createQualification('Secondary');
        insert qual1;

        // Create Contact Qualifications
        Contact_Qualification__c cq1 = StudFirst_TestHelper.createContactQualification(c, qual1, 'Secondary Education');
        insert cq1;

        Application__c app = StudFirst_TestHelper.createApplication(c);
        insert app;

        ContentDocument file = createTestDocument(true);

        String docTypeValue = getDocumentTypeValue(0);
        String docSubType = '';
        String comments = 'testing some comments ';

        // Create application checklist for visa
        Document_Checklist__c checklistVisa = new Document_Checklist__c(
            Application__c = app.Id,
            Rule_DeveloperName__c = 'Visa_Check',
            Status__c = ContactDocumentServices.CHECKLIST_STATUS_REQUESTED,
            Unique_ID__c = String.valueOf(Date.today()),
            Allowed_Document_Type__c = 'OTHERDCTYP',
            Type__c = 'Visa'
        );
        insert checklistVisa;
        Test.startTest();
       
            // SUCCESSFUL SAVE
            Map<String, Object> mapResults = ContactDocumentServices.saveFileAndContactDocumentChecklist(file.Id, c.Id, app.Id, docTypeValue, docSubType, comments, checklistVisa.Id, cq1.Id, null, false);
            String saveStatus = (String) mapResults.get(ContactDocumentServices.FIELD_SAVE_STATUS);
            System.assertEquals(ContactDocumentServices.SUCCESS, saveStatus, 'Save should have completed successfully');
            List<Contact_Document__c> conDocs = [
                SELECT Id, Document_Checklist__c
                FROM Contact_Document__c 
                WHERE Contact__c = :c.Id
                ];
            // REMOVE no Bad ConDoc Id
            Map<String, Object> mapRemove = ContactDocumentServices.removeContactDocumentChecklist(app.Id, app.Id);
            String deleteStatus = (String) mapRemove.get(ContactDocumentServices.FIELD_DELETE_STATUS);
            System.assertEquals(ContactDocumentServices.FAILED, deleteStatus, 'Contact Document should have failed for a bad Contact Document Id');
            System.runAs(applicant)
            {
                // SUCCESSFUL REMOVE
                List<Contact_Document__c> listConDocs = (List<Contact_Document__c>) mapResults.get(ContactDocumentServices.FIELD_CONTACT_DOCUMENTS);
                Contact_Document__c conDoc = listConDocs[0];
                mapRemove = ContactDocumentServices.removeContactDocumentChecklist(conDoc.Id, app.Id);

                deleteStatus = (String) mapRemove.get(FileUploadController.FIELD_DELETE_STATUS);
                System.assertEquals(FileUploadController.SUCCESS, deleteStatus, 'Contact Document should have succeeded');
            }
        Test.stopTest();
    }


     /**
     * @description Test removeContactDocument
     */
    @isTest
    public static void test_RemoveContactDocumentOtherUser() {
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        // Create Qualifications
        Qualification__c qual1 = StudFirst_TestHelper.createQualification('Secondary');
        insert qual1;

        // Create Contact Qualifications
        Contact_Qualification__c cq1 = StudFirst_TestHelper.createContactQualification(c, qual1, 'Secondary Education');
        insert cq1;

        Application__c app = StudFirst_TestHelper.createApplication(c);
        insert app;

        ContentDocument file = createTestDocument(true);

        String docTypeValue = getDocumentTypeValue(0);
        String docSubType = '';
        String comments = 'testing some comments ';

        // Create application checklist for visa
        Document_Checklist__c checklistVisa = new Document_Checklist__c(
            Application__c = app.Id,
            Rule_DeveloperName__c = 'Visa_Check',
            Status__c = ContactDocumentServices.CHECKLIST_STATUS_REQUESTED,
            Unique_ID__c = String.valueOf(Date.today()),
            Allowed_Document_Type__c = 'OTHERDCTYP',
            Type__c = 'Visa'
        );
        insert checklistVisa;
        Test.startTest();
       
            // SUCCESSFUL SAVE
            Map<String, Object> mapResults = ContactDocumentServices.saveFileAndContactDocumentChecklist(file.Id, c.Id, app.Id, docTypeValue, docSubType, comments, checklistVisa.Id, cq1.Id, null, false);
            String saveStatus = (String) mapResults.get(ContactDocumentServices.FIELD_SAVE_STATUS);
            System.assertEquals(ContactDocumentServices.SUCCESS, saveStatus, 'Save should have completed successfully');
            List<Contact_Document__c> conDocs = [
                SELECT Id, Document_Checklist__c
                FROM Contact_Document__c 
                WHERE Contact__c = :c.Id
                ];
            // REMOVE no Bad ConDoc Id
            Map<String, Object> mapRemove = ContactDocumentServices.removeContactDocumentChecklist(app.Id, app.Id);
            String deleteStatus = (String) mapRemove.get(ContactDocumentServices.FIELD_DELETE_STATUS);
            System.assertEquals(ContactDocumentServices.FAILED, deleteStatus, 'Contact Document should have failed for a bad Contact Document Id');

            // SUCCESSFUL REMOVE
            List<Contact_Document__c> listConDocs = (List<Contact_Document__c>) mapResults.get(ContactDocumentServices.FIELD_CONTACT_DOCUMENTS);
            Contact_Document__c conDoc = listConDocs[0];
            mapRemove = ContactDocumentServices.removeContactDocumentChecklist(conDoc.Id, app.Id);

            deleteStatus = (String) mapRemove.get(FileUploadController.FIELD_DELETE_STATUS);
            System.assertEquals(FileUploadController.SUCCESS, deleteStatus, 'Contact Document should have succeeded');
            
        Test.stopTest();
    }

    static ContentDocument createTestDocument(Boolean allAccess) {
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

        if(allAccess) {
            ContentDocumentLink cdLink = new ContentDocumentLink();
            cdLink.LinkedEntityId = UserInfo.getOrganizationId();
            cdLink.ContentDocumentId = cv.ContentDocumentId;
            cdLink.ShareType = 'C';
            cdLink.Visibility = 'AllUsers';

            insert cdLink;
        }

        return file;
    }

    static String getDocumentTypeValue(Integer i)
    {
        Schema.DescribeFieldResult fieldResult = Contact_Document__c.Document_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        Schema.PicklistEntry pleAtI = ple[i];

        if(pleAtI != null)
            return pleAtI.getValue();
        return null;
    }

}