/**
 * @description Test class to cover GRDocumentRequestImpl
 * @author Vishal Gupta
 * @since 29/10/2024
 */
@IsTest(IsParallel=true)
public class GRDocumentRequestImpl_Test {
    /**
     * @description Sets up test data including a Contact, Application, and Document Checklist for testing.
     */
    @TestSetup
    private static void setupData() {
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        //create application
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        app.Type_Of_Study__c = 'Graduate Research';
        app.Callista_Applicant_Id__c = 'testApplicantId';
        insert app;

        // Create Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        // Creare Course Offering
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        insert courseOffering;

        //create Application_Course_Preference__c
        Application_Course_Preference__c coursePreference = StudFirst_TestHelper.createCoursePreferences(app, c, courseOffering, course);
        coursePreference.GradRes_Callista_Id__c = 'testhdrnumber';
        insert coursePreference;

        //create Contact_Qualification__c
        Map<Id, RecordType> qualifficationType = new Map<Id, RecordType>([SELECT Id FROM RecordType WHERE sObjectType = 'Contact_Qualification__c']);
        List<Contact_Qualification__c> lstCQ = new List<Contact_Qualification__c>();
        for(Id recordTypeId : qualifficationType.keyset()) {
            Contact_Qualification__c cq = new Contact_Qualification__c();
            cq.Contact__c = applicant.ContactId;
            cq.RecordTypeId = recordTypeId;
            lstCQ.add(cq);
        }
                
        insert lstCQ;

        // create the apq
        List<Application_Qualification_Provided__c> lstAqp = new List<Application_Qualification_Provided__c>();
        for(Contact_Qualification__c contQual : lstCQ) {
            Application_Qualification_Provided__c aqp = new Application_Qualification_Provided__c();
            aqp.Contact_Qualification__c = contQual.Id;
            aqp.Application__c = app.Id;
            aqp.Sequence_Number__c = 1;
            lstAqp.add(aqp);
        }
        
        insert lstAqp;

        // Create application checklist for visa
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

        // Create a new Contact document for testing
        insert new Contact_Document__c(
            Contact__c = c.Id,
            Document_Type__c = 'OTHERDCTYP',
            Filename__c = 'Test_Issuer_Transcript.pdf',
            Application__c = app.Id,
            Document_Checklist__c = testChecklist.Id
        );
    }

    /**
     * @description Tests the handlePost method when provided with a valid request payload.
     */
    @IsTest
    private static void testHandlePost() {
        // Given : post request payload is valid and there are existing document checklist
        GRDocumentRequestPayload.PostRequest postRequestPayload = new GRDocumentRequestPayload.PostRequest();
        postRequestPayload.applicantId = 'testApplicantId';
        postRequestPayload.hdrApplicationNumber = 'testhdrnumber';
        postRequestPayload.requestType = 'MISC-DOC';

        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;
        // When : calling process method
        Test.startTest();
        RESTlib_ClientImplHandler clientImplHandler = new GRDocumentRequestImpl().getHandlePost();
        clientImplHandler.setPayloadType(GRDocumentRequestPayload.PostRequest.class, GRDocumentRequestPayload.PostResponse.class);
        clientImplHandler.execute();
        Test.stopTest();

        //then, it should create a checklist comment and change the checklist status to Insufficient
        Document_Checklist__c checklist = [SELECT Status__c FROM Document_Checklist__c WHERE Document_Request_Type__c = 'MISC-DOC' limit 1];
        Assert.areEqual('Insufficient', checklist.Status__c, 'Expected the checklist status changed as Insufficient');
    }
    /**
     * @description Tests the handlePost method when provided with a request of cancellation of a document request.
     */
    @IsTest
    private static void testHandlePostCancelComments() {
        // Given : post request payload is valid and there are existing document checklist
        GRDocumentRequestPayload.PostRequest postRequestPayload = new GRDocumentRequestPayload.PostRequest();
        postRequestPayload.applicantId = 'testApplicantId';
        postRequestPayload.hdrApplicationNumber = 'testhdrnumber';
        postRequestPayload.requestType = 'MISC-DOC';
        postRequestPayload.cancelledDate = '2024-04-01 10:47:25.000';
        postRequestPayload.requestReason = 'Test reason';

        Document_Checklist__c checklist = [SELECT Status__c FROM Document_Checklist__c WHERE Document_Request_Type__c = 'MISC-DOC' limit 1];
        Document_Checklist_Comment__c comments = new Document_Checklist_Comment__c();
        comments.Content__c = 'Test reason';
        comments.Document_Checklist__c = checklist.Id;
        insert comments;

        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;
        // When : calling process method with the cancellation request
        Test.startTest();
        RESTlib_ClientImplHandler clientImplHandler = new GRDocumentRequestImpl().getHandlePost();
        clientImplHandler.setPayloadType(GRDocumentRequestPayload.PostRequest.class, GRDocumentRequestPayload.PostResponse.class);
        clientImplHandler.execute();
        Test.stopTest();

        //then, it should revert a checklist comment and change the checklist status back to submitted
        Document_Checklist__c newChecklist = [SELECT Status__c FROM Document_Checklist__c WHERE Document_Request_Type__c = 'MISC-DOC' limit 1];
        Assert.areEqual('Submitted', newChecklist.Status__c, 'Expected the checklist status changed as Submitted');
    }
    /**
     * @description Tests the handlePost method when provided with a valid request of english document request.
     */
    @IsTest
    private static void testHandlePostEnglishChecklistRequired() {
        // Given : post request payload is valid and there are existing document checklist
        GRDocumentRequestPayload.PostRequest postRequestPayload = new GRDocumentRequestPayload.PostRequest();
        postRequestPayload.applicantId = 'testApplicantId';
        postRequestPayload.hdrApplicationNumber = 'testhdrnumber';
        postRequestPayload.requestType = 'ENG-TEST';
        postRequestPayload.description = 'test';

        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;
        // When : calling process method with requesting english document
        Test.startTest();
        RESTlib_ClientImplHandler clientImplHandler = new GRDocumentRequestImpl().getHandlePost();
        clientImplHandler.setPayloadType(GRDocumentRequestPayload.PostRequest.class, GRDocumentRequestPayload.PostResponse.class);
        clientImplHandler.execute();
        Test.stopTest();

        //then, it create the checklist for english document
        Contact_Qualification__c contactQualEng = [SELECT English_doc_required_during_assessment__c FROM Contact_Qualification__c WHERE RecordType.DeveloperName = 'English_Test' limit 1];
        Assert.areEqual(true, contactQualEng.English_doc_required_during_assessment__c, 'Expected the english test qualififcation document flag to true');
    }

    /**
     * @description Tests the handlePost method when provided with a valid request of misc document request.
     */
    @IsTest
    private static void testHandlePostMiscAdditionalDocument() {
        // Given : post request payload is valid and there are existing document checklist
        GRDocumentRequestPayload.PostRequest postRequestPayload = new GRDocumentRequestPayload.PostRequest();
        postRequestPayload.applicantId = 'testApplicantId';
        postRequestPayload.hdrApplicationNumber = 'testhdrnumber';
        postRequestPayload.requestType = 'MISC-DOC';
        postRequestPayload.claimSequenceNumber = 2;

        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;
        // When : calling process method requesting additional misc item
        Test.startTest();
        RESTlib_ClientImplHandler clientImplHandler = new GRDocumentRequestImpl().getHandlePost();
        clientImplHandler.setPayloadType(GRDocumentRequestPayload.PostRequest.class, GRDocumentRequestPayload.PostResponse.class);
        clientImplHandler.execute();
        Test.stopTest();

        //then, it create the checklist for misc document
        List<Contact_Qualification__c> contactQualMisc = [SELECT Id FROM Contact_Qualification__c WHERE RecordType.DeveloperName = 'Other_Qualification' ];
        Assert.areEqual(2, contactQualMisc.size(), 'Expected another misc document is created with checklist');
    }

    /**
     * @description Tests the handlePost method when provided withhout a valid request (blank application id).
     */
    @IsTest
    private static void testHandlePostBlankApplicationId() {
        // Given : post request payload is invalid
        GRDocumentRequestPayload.PostRequest postRequestPayload = new GRDocumentRequestPayload.PostRequest();

        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;
        //calling the unused method for test coverage
        new GRDocumentRequestImpl().getHandleGet();
        new GRDocumentRequestImpl().getHandlePut();
        new GRDocumentRequestImpl().getHandlePatch();

        // When : calling process method
        Test.startTest();
        RESTlib_ClientImplHandler clientImplHandler = new GRDocumentRequestImpl().getHandlePost();
        clientImplHandler.setPayloadType(GRDocumentRequestPayload.PostRequest.class, GRDocumentRequestPayload.PostResponse.class);
        clientImplHandler.execute();
        Test.stopTest();
        String responseBodyString = response.responseBody.toString();
        //then, it should throw the error
        GRDocumentRequestPayload.PostResponse customResponse =
                (GRDocumentRequestPayload.PostResponse) JSON.deserialize(responseBodyString, GRDocumentRequestPayload.PostResponse.class);
            Assert.isFalse(customResponse.success, 'Expected success to be false');
            Assert.areEqual('The applicant Id cannot be blank', customResponse.description, 'Expected error to match');
        
    }

    /**
     * @description Tests the handlePost method when provided withhout a valid request (blank hdr application number)
     */
    @IsTest
    private static void testHandlePostBlankHDRAppNum() {
        // Given : post request payload is invalid
        GRDocumentRequestPayload.PostRequest postRequestPayload = new GRDocumentRequestPayload.PostRequest();
        postRequestPayload.applicantId = 'test';
        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;
        // When : calling process method
        Test.startTest();
        RESTlib_ClientImplHandler clientImplHandler = new GRDocumentRequestImpl().getHandlePost();
        clientImplHandler.setPayloadType(GRDocumentRequestPayload.PostRequest.class, GRDocumentRequestPayload.PostResponse.class);
        clientImplHandler.execute();
        Test.stopTest();
        //then, it should throw the error
        String responseBodyString = response.responseBody.toString();
        GRDocumentRequestPayload.PostResponse customResponse =
                (GRDocumentRequestPayload.PostResponse) JSON.deserialize(responseBodyString, GRDocumentRequestPayload.PostResponse.class);
            Assert.isFalse(customResponse.success, 'Expected success to be false');
            Assert.areEqual('The HDR Application Number cannot be blank', customResponse.description, 'Expected code to match');
        
    }
    /**
     * @description Tests the handlePost method when provided withhout a valid request (blank request type).
     */
    @IsTest
    private static void testHandlePostBlankRequestType() {
        // Given : post request payload is invalid
        GRDocumentRequestPayload.PostRequest postRequestPayload = new GRDocumentRequestPayload.PostRequest();
        postRequestPayload.applicantId = 'test';
        postRequestPayload.hdrApplicationNumber = 'testhdrnumber';
        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;
        // When : calling process method
        Test.startTest();
        RESTlib_ClientImplHandler clientImplHandler = new GRDocumentRequestImpl().getHandlePost();
        clientImplHandler.setPayloadType(GRDocumentRequestPayload.PostRequest.class, GRDocumentRequestPayload.PostResponse.class);
        clientImplHandler.execute();
        Test.stopTest();
        String responseBodyString = response.responseBody.toString();
        //then, it should throw the error
        GRDocumentRequestPayload.PostResponse customResponse =
                (GRDocumentRequestPayload.PostResponse) JSON.deserialize(responseBodyString, GRDocumentRequestPayload.PostResponse.class);
            Assert.isFalse(customResponse.success, 'Expected success to be false');
            Assert.areEqual('The Document request type cannot be blank', customResponse.description, 'Expected code to match');
        
    }
    /**
     * @description Tests the handlePost method when provided withhout a valid request (no application found).
     */
    @IsTest
    private static void testHandlePostApplicationNotFoundError() {
        // Given : post request payload is invalid
        GRDocumentRequestPayload.PostRequest postRequestPayload = new GRDocumentRequestPayload.PostRequest();
        postRequestPayload.applicantId = 'test';
        postRequestPayload.hdrApplicationNumber = 'testhdrnumber';
        postRequestPayload.requestType = 'TERT-QUAL';
        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;
        // When : calling process method
        Test.startTest();
        RESTlib_ClientImplHandler clientImplHandler = new GRDocumentRequestImpl().getHandlePost();
        clientImplHandler.setPayloadType(GRDocumentRequestPayload.PostRequest.class, GRDocumentRequestPayload.PostResponse.class);
        clientImplHandler.execute();
        Test.stopTest();
        String responseBodyString = response.responseBody.toString();
        //then, it should throw the error
        GRDocumentRequestPayload.PostResponse customResponse =
                (GRDocumentRequestPayload.PostResponse) JSON.deserialize(responseBodyString, GRDocumentRequestPayload.PostResponse.class);
            Assert.isFalse(customResponse.success, 'Expected success to be false');
            Assert.areEqual('Application not found', customResponse.description, 'Expected error to match');
    }
}