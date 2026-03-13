/*******************************************************************************
* @author		Vishal Gupta
* @date         4/11/2024    
* @description  Test Class for GRDocumentRequestPatchToCallistaService Class
* @revision     14/10/2024 - Initial Version
*******************************************************************************/
@isTest(isParallel = true)
public class GRDocumentRequestPatchService_Test {

    @TestSetup
    static void makeData() {
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        //create application
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        app.Type_Of_Study__c = 'Graduate Research';
        insert app;
        // Create Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        // Creare Course Offering
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        insert courseOffering;

        //create Application_Course_Preference__c
        Application_Course_Preference__c coursePreference = StudFirst_TestHelper.createCoursePreferences(app, c, courseOffering, course);
        coursePreference.GradRes_Callista_Id__c = '76343274';
        insert coursePreference;

        // Create application checklist for
        Document_Checklist__c testChecklist = new Document_Checklist__c(
            Application__c = app.Id,
            RecordTypeId = Schema.SObjectType.Document_Checklist__c.getRecordTypeInfosByDeveloperName().get('Application_Assessment').getRecordTypeId(),
            Rule_DeveloperName__c = 'V2_Complete_Tertiary_Education_Check',
            Status__c = 'Requested',
            Unique_ID__c = String.valueOf(Date.today()),
            Document_Request_Type__c = 'MISC-DOC',
            Type__c = 'Qualification'
        );
        insert testChecklist;

        //create doc checklist comment
        insert new Document_Checklist_Comment__c(Document_Checklist__c = testChecklist.Id, Notify_Email_Addresses__c = 'test@test.com');

        //create contact document
        Contact_Document__c conDoc = new Contact_Document__c();
        conDoc.Contact__c = c.id;
        conDoc.Application__c = app.Id;
        conDoc.Document_Type__c = 'PARENT_GUARDIAN';
        conDoc.Filename__c = 'testdoc';
        conDoc.Document_Checklist__c = testChecklist.Id;
        insert conDoc;

    }
    /**
     * @author          Vishal Gupta
     * @description     for sending document request patch to callista 
     * @revision        14/10/2024 - Initial Version
     */
    @isTest static void testApplicationSendToCallistaService() {
        
        GRDocumentRequestPatchToCallistaAPIMock mock = new GRDocumentRequestPatchToCallistaAPIMock();
        mock.responseCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);
        //Given, GR application is submitted from my.app
        Application__c app = [SELECT Id, Applicant__c FROM Application__c LIMIT 1];
        Contact_Document__c conDoc = [SELECT Id, Application__c, Document_Checklist__c, CreatedDate FROM Contact_Document__c WHERE Application__c = :app.Id LIMIT 1];
        Test.startTest();
        //When, the document is sent to callista post application submission
        GRDocumentRequestPatchToCallistaService applicationSendService = new GRDocumentRequestPatchToCallistaService(
            conDoc,
            ''
        );
        applicationSendService.createRequestBody();
        applicationSendService.sendMessage();
        applicationSendService.handleResponse();
        Test.stopTest();
        //Then, the API request, response should be updated in Document checklist comment object
        Document_Checklist_Comment__c comments = [SELECT API_Request__c FROM Document_Checklist_Comment__c LIMIT 1];
        Assert.areNotEqual(NULL, comments.API_Request__c, 'API_Request__c should be populated');
    }
    
}