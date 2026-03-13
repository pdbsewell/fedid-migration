/**
 * @description Covers the Contact_Document_AS_Post_Application_Submission flow
 * @author      Vishal Gupta
 * @since       5/11/2024
 */
@IsTest(isParallel=true)
private class Contact_Document_AS_Post_Application_FT {
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
        testApplication.Type_Of_Study__c = 'Graduate Research';
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
            Issuer_Name__c = 'Test Issuer',
            Application__c = testApplication.Id,
            Document_Checklist__c = testChecklist.Id,
            Internal_Only__c = false,
            Channel__c = 'CSSD',
            Post_Submission__c = true
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
     * @description Tests the flow when Submitted__c flag is changed to true
     */
    @IsTest
    private static void testDocumentPostSubmissionTrue() {
        //Given: the Grad research application is submitted 
        List<Contact_Document__c> contactDocuments = [SELECT Id, Application__c, Contact__c FROM Contact_Document__c];
        for (Contact_Document__c contactDocument : contactDocuments) {
            contactDocument.Submitted__c = true;
        }
        //When: the document is craeted or updated Submitted__c to true
        update contactDocuments;
        List<EventBusSubscriber> lstEvent = [SELECT Name, Position, Retries, LastError 
                        FROM EventBusSubscriber 
                        WHERE Topic='Async_Process__e' AND Type='ApexTrigger'
                        ];
        //Then: the document request should be triggered from the platform event
        Assert.areNotEqual(true, lstEvent.isEmpty(), 'Async process is fired to trigger the document request');
    }

}