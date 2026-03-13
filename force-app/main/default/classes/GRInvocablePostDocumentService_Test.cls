/**
 * @description Covers the GRInvocablePostDocumentService
 * @author      Vishal Gupta
 * @since       7/11/2024
 */
@IsTest(isParallel=true)
private class GRInvocablePostDocumentService_Test {
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
    }

    /**
     * @description Tests the Invocable method from Contact Document Post Application Submission when the feature switch is on
     */
    @IsTest
    private static void testDocumentSubmissionInvocable() {
        //Given: the Grad research application is submitted 
        List<Id> lstDocIds = new List<Id>();
        List<Contact_Document__c> contactDocuments = [SELECT Id, Application__c, Contact__c FROM Contact_Document__c];
        for (Contact_Document__c contactDocument : contactDocuments) {
            lstDocIds.add(contactDocument.Id);
        }
        //When: the invocable method is called and feature switch is on
        insert new Feature_Switch__c(Graduate_Research_Integration__c = true);

        GRInvocablePostDocumentService.queueFileToSend(lstDocIds);
        List<EventBusSubscriber> lstEvent = [SELECT Name, Position, Retries, LastError 
                        FROM EventBusSubscriber 
                        WHERE Topic='Async_Process__e' AND Type='ApexTrigger'
                        ];
        //Then: the document request should be triggered from the platform event
        Assert.areEqual(false, lstEvent.isEmpty(), 'Async process is fired to trigger the document request');
    }

}