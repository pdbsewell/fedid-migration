/**
 * @description Covers the Async_Process_PE_Document_Request_Email flow
 * @author      Vishal Gupta
 * @since       18/12/2024
 */
@IsTest(isParallel=true)
private class Async_Process_PE_Document_Req_Email_FT {
    /**
     * @description Tests the document request email when student upload the document and the response comes back from Callista
     */
    @IsTest
    private static void testDocumentPostSubmissionTrue() {
        //Given: the Grad research application is submitted 
        GRDocumentRequestEmailController emailJson = new GRDocumentRequestEmailController(); 
        emailJson.applicantName = 'test';
        emailJson.personId = 'test';
        emailJson.recipientEmail = 'test@test.test';
        String jsonRequestString = JSON.serializePretty(emailJson);
        Async_Process__e event = new Async_Process__e(
            Process_Name__c = 'GRDocumentRequestEmailController',
            Parameter__c = jsonRequestString
        );
        // Fire the event
        Test.startTest();
        //When: Student upload the document and the response comes back from Callista
        Database.SaveResult result = EventBus.publish(event);
        Test.stopTest();
        List<EventBusSubscriber> lstEvent = [SELECT Name, Position, Retries, LastError 
                        FROM EventBusSubscriber 
                        WHERE Topic='Async_Process__e' AND Type='ApexTrigger'
                        ];
        //Then: the platform event should trigger the email to staff who is reviewing the application
        Assert.areNotEqual(true, lstEvent.isEmpty(), 'Async process is fired to trigger the document request');
        Assert.areEqual(GRDocumentRequestEmailController.isSuccess, true, 'Document request email has been sent');
    }

    @IsTest
    private static void testApplicationSubmissionEmailTrue() {
        //Given: the Grad research application is integrated
        GRApplicationSubmissionEmail emailJson = new GRApplicationSubmissionEmail(); 
        emailJson.recipientEmail = 'test@test.test';
        emailJson.firstName = 'test';
        emailJson.fullName = 'test test';
        emailJson.callistaApplicantId = '2344324';
        emailJson.applicationId = 'A-2577505';
        emailJson.gradResCallistaId = '12345678';
        emailJson.gradResAppType = 'Admissions';
        emailJson.proposedCommencementDate = '30/04/2025';
        emailJson.course = '1322';
        emailJson.submitedDate = '01 Apr 2025 14:45';

        String jsonRequestString = JSON.serializePretty(emailJson);
        Async_Process__e event = new Async_Process__e(
            Process_Name__c = 'GRApplicationSubmissionEmail',
            Parameter__c = jsonRequestString
        );
        // Fire the event
        Test.startTest();
        //When: ACPs GradResCallistaId is populated
        Database.SaveResult result = EventBus.publish(event);
        Test.stopTest();
        List<EventBusSubscriber> lstEvent = [SELECT Name, Position, Retries, LastError 
                        FROM EventBusSubscriber 
                        WHERE Topic='Async_Process__e' AND Type='ApexTrigger'
                        ];
        //Then: the platform event should trigger the email to inform student of their application Ids
        Assert.areNotEqual(true, lstEvent.isEmpty(), 'Async process is fired to trigger the application submission email');
        Assert.areEqual(GRApplicationSubmissionEmail.isSuccess, true, 'Application submission email email has been sent');
    }

}