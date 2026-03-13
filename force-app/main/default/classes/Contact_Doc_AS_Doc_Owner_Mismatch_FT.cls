/**
 * @description Covers the Contact_Doc_AS_Doc_Owner_Mismatch flow
 * @author      Kai-Fan Hsieh
 * @since       20/09/2024
 */
@IsTest(isParallel=true)
private class Contact_Doc_AS_Doc_Owner_Mismatch_FT {
    private static final String EXISTING_ISSUER_DELIVERY_ID = '4d611b71-3512-4ada-8577-7f63158df249';
    private static final String EXISTING_ISSUER_DOCUMENT_ID = '67230a8b-7a3e-58c3-b2c7-f71ecfc049b5';
    /**
     * @description Sets up test data including a Contact, Application, and Document Checklist for testing.
     */
    @TestSetup
    private static void setupData() {
        // Create a new Contact for testing
        Contact testContact = StudFirst_TestHelper.createApplicant();
        testContact.Citizenship__c = MyApplicationUtilities.DOMESTIC;
        testContact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Non_Student').getRecordTypeId();
        Date dtToday = Date.today();
        testContact.Birthdate = dtToday.addYears(-20);
        insert testContact;

        // Create application for contact
        Application__c testApplication = StudFirst_TestHelper.createApplication(testContact.Id);
        testApplication.Fee_Payment__c = true;
        insert testApplication;

        // Create application checklist for visa
        Document_Checklist__c testChecklist = new Document_Checklist__c(
            Application__c = testApplication.Id,
            RecordTypeId = Schema.SObjectType.Document_Checklist__c.getRecordTypeInfosByDeveloperName().get('Application_Assessment').getRecordTypeId(),
            Rule_DeveloperName__c = 'V2_Complete_Tertiary_Education_Check',
            Status__c = AssessmentServicesConstants.APP_CHECKLIST_STATUS_REQUESTED,
            Unique_ID__c = String.valueOf(Date.today()),
            Allowed_Document_Type__c = 'DIPDEGCERT;OTHERDCTYP;TERTED_TRA;GRAD_SCALE',
            Type__c = 'Qualification'
        );
        insert testChecklist;

        // Create a new Contact document for testing
        Contact_Document__c contactDocument = new Contact_Document__c(
            Contact__c = testContact.Id,
            Document_Type__c = 'OTHERDCTYP',
            Filename__c = 'Test_Issuer_Transcript.pdf',
            Issuer_Delivery_Id__c = EXISTING_ISSUER_DELIVERY_ID,
            Issuer_Name__c = 'Test Issuer',
            Issuer_Document_Id__c = EXISTING_ISSUER_DOCUMENT_ID,
            Application__c = testApplication.Id,
            Document_Checklist__c = testChecklist.Id,
            Internal_Only__c = false,
            Channel__c = 'CSSD'
        );
        insert contactDocument;

        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test',
            PathOnClient = '/Test.pdf',
            VersionData = Blob.valueOf('Test ContentVersion Body')
        );
        insert contentVersion;

        Id contentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
        ContentDocumentLink cdl1 = new ContentDocumentLink(
            ContentDocumentId = contentDocumentId,
            LinkedEntityId = contactDocument.Id,
            ShareType = 'I',
            Visibility = 'AllUsers'
        );
        ContentDocumentLink cdl2 = new ContentDocumentLink(
            ContentDocumentId = contentDocumentId,
            LinkedEntityId = testApplication.Id,
            ShareType = 'I',
            Visibility = 'AllUsers'
        );
        ContentDocumentLink cdl3 = new ContentDocumentLink(
            ContentDocumentId = contentDocumentId,
            LinkedEntityId = testContact.Id,
            ShareType = 'I',
            Visibility = 'AllUsers'
        );

        insert new List<ContentDocumentLink>{cdl1, cdl2, cdl3};
    }

    /**
     * @description Tests the flow when document_owner_mismatch is changed to true
     */
    @IsTest
    private static void testDocumentOwnerMismatchIsChangedToTrue() {
        // Given: Set document_owner_mismatch initial state to false
        List<Contact_Document__c> contactDocuments = [SELECT Id, Application__c, Contact__c FROM Contact_Document__c];
        for (Contact_Document__c contactDocument : contactDocuments) {
            contactDocument.Document_Owner_Mismatch__c = false;
        }
        update contactDocuments;
        ContentVersion contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];
        for (ContentDocumentLink contentDocumentLink :  getContentDocumentLinks(contentVersion.ContentDocumentId)) {
            Assert.areEqual('AllUsers', contentDocumentLink.Visibility, 'Expected visibility to be AllUsers when Document_Owner_Mismatch__c is false');
        }
        //When: Set document_owner_mismatch to true
        for (Contact_Document__c contactDocument : contactDocuments) {
            contactDocument.Document_Owner_Mismatch__c = true;
        }
        update contactDocuments;
        // Then: Content document links' visibility should be InternalUsers
        for (ContentDocumentLink contentDocumentLink :  getContentDocumentLinks(contentVersion.ContentDocumentId)) {
            Assert.areEqual('InternalUsers', contentDocumentLink.Visibility, 'Expected visibility to be InternalUsers when Document_Owner_Mismatch__c is true');
        }
    }

    /**
     * @description Tests the flow when document_owner_mismatch is changed to false
     */
    @IsTest
    private static void testDocumentOwnerMismatchIsChangedToFalse() {
        // Given: Set document_owner_mismatch initial state to true
        List<Contact_Document__c> contactDocuments = [SELECT Id, Application__c, Contact__c FROM Contact_Document__c];
        for (Contact_Document__c contactDocument : contactDocuments) {
            contactDocument.Document_Owner_Mismatch__c = true;
        }
        update contactDocuments;
        ContentVersion contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];
        for (ContentDocumentLink contentDocumentLink :  getContentDocumentLinks(contentVersion.ContentDocumentId)) {
            Assert.areEqual('InternalUsers', contentDocumentLink.Visibility, 'Expected visibility to be InternalUsers when Document_Owner_Mismatch__c is true');
        }
        //When: Set document_owner_mismatch to false
        for (Contact_Document__c contactDocument : contactDocuments) {
            contactDocument.Document_Owner_Mismatch__c = false;
        }
        update contactDocuments;
        // Then: Content document links' visibility should be AllUsers and Application__c.Last_Verified_Document_Received_Date__c is populated
        for (ContentDocumentLink contentDocumentLink : getContentDocumentLinks(contentVersion.ContentDocumentId)) {
            Assert.areEqual('AllUsers', contentDocumentLink.Visibility, 'Expected visibility to be AllUsers when Document_Owner_Mismatch__c is false');
        }
        for(Application__c application: [SELECT Id, Last_Verified_Document_Received_Date__c FROM Application__c]){
            Assert.isNotNull(application.Last_Verified_Document_Received_Date__c, 'Expected Application__c.Last_Verified_Document_Received_Date__c to be populated');
        }
    }

    /**
     * @description Get Content Document Links by content document Id
     * @param contentDocumentId content document Id
     * @return List<ContentDocumentLink>
     */
    private static List<ContentDocumentLink> getContentDocumentLinks(Id contentDocumentId){
        return [SELECT Id, Visibility FROM ContentDocumentLink WHERE LinkedEntityId != :UserInfo.getUserId() AND ContentDocumentId =: contentDocumentId];
    }
}