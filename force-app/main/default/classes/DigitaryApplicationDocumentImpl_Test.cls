/**
 * @description Test class to cover DigitaryApplicationDocumentImpl
 * @author Kai-Fan Hsieh
 * @since 01 July 2024
 */
@isTest(isParallel=true)
public class DigitaryApplicationDocumentImpl_Test {
    private static final String EXISTING_ISSUER_DELIVER_ID = '4d611b71-3512-4ada-8577-7f63158df249';
    private static final String NEW_ISSUER_DELIVER_ID = '4d611b71-3512-4ada-8577-7f63158df235';
    private static final String EXISTING_ISSUER_DOCUMENT_ID = '67230a8b-7a3e-58c3-b2c7-f71ecfc049b5';
    private static final String CONTACT_PREVIOUS_EMAIL = 'previous@email.com';

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
        insert new List<Email__c>{
            new Email__c(
                Contact__c = testContact.Id,
                Name = testContact.Email,
                Classification__c = 'Private'),
            new Email__c(
                Contact__c = testContact.Id,
                Name = CONTACT_PREVIOUS_EMAIL,
                Classification__c = 'Private')
        };

        // Create application for contact
        Application__c testApplication = StudFirst_TestHelper.createApplication(testContact.Id);
        testApplication.Fee_Payment__c = true;
        insert testApplication;

        // Create application checklist for visa
        Document_Checklist__c testChecklist = new Document_Checklist__c(
            Application__c = testApplication.Id,
            RecordTypeId = Schema.SObjectType.Document_Checklist__c.getRecordTypeInfosByDeveloperName().get('Application_Assessment').getRecordTypeId(),
            Rule_DeveloperName__c = 'V2_Complete_Tertiary_Education_Check',
            Status__c = ContactDocumentServices.CHECKLIST_STATUS_SUBMITTED,
            Unique_ID__c = String.valueOf(Date.today()),
            Allowed_Document_Type__c = 'DIPDEGCERT;OTHERDCTYP;TERTED_TRA;GRAD_SCALE',
            Type__c = 'Qualification'
        );
        insert testChecklist;

        // Create a new Contact document for testing
        Contact_Document__c contactDocument = new Contact_Document__c();
        contactDocument.Contact__c = testContact.Id;
        contactDocument.Document_Type__c = 'OTHERDCTYP';
        contactDocument.Issuer_Delivery_Id__c = EXISTING_ISSUER_DELIVER_ID;
        contactDocument.Issuer_Document_Id__c = EXISTING_ISSUER_DOCUMENT_ID;
        contactDocument.Application__c = testApplication.Id;
        contactDocument.Document_Checklist__c = testChecklist.Id;
        contactDocument.Channel__c = 'CSSD';
        insert contactDocument;
    }

    /**
     * @description Tests the handlePost method when provided with a valid Application name in the request payload.
     */
    @IsTest
    private static void testHandlePostApplicationId() {
        // Given :
        // Post request payload is valid.
        // Document owner name is same as applicant's legal name in My.App
        // Document owner email address is different to applicant's email addresses in My.App.
        Application__c application = [SELECT Name FROM Application__c LIMIT 1];
        Contact testContact = [SELECT Id, First_Name__c, Last_Name__c, Email FROM Contact LIMIT 1];

        DigitaryApplicationDocumentPayload.PostRequest postRequestPayload = createPostRequestPayload(application.Name, NEW_ISSUER_DELIVER_ID);
        postRequestPayload.issuerDocumentOwnerName = testContact.First_Name__c + ' ' + testContact.Last_Name__c;
        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;

        // When : calling process method
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocumentImpl().getHandlePost();
            clientImplHandler.setPayloadType(DigitaryApplicationDocumentPayload.PostRequest.class, DigitaryApplicationDocumentPayload.PostResponse.class);
            Assert.areEqual(clientImplHandler.getRequestType(), DigitaryApplicationDocumentPayload.PostRequest.class, 'Request type should match');
            Assert.areEqual(clientImplHandler.getResponseType(), DigitaryApplicationDocumentPayload.PostResponse.class, 'Response type should match');
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then : return success status
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        DigitaryApplicationDocumentPayload.PostResponse customResponse =
            (DigitaryApplicationDocumentPayload.PostResponse) JSON.deserialize(responseBodyString, DigitaryApplicationDocumentPayload.PostResponse.class);
        Assert.isTrue(customResponse.success, 'Expected success to be true');
        List<Contact_Document__c> contactDocuments = [
            SELECT Id, Document_Owner_Mismatch__c
            FROM Contact_Document__c
            WHERE Application__c = :application.Id
            AND Issuer_Delivery_Id__c = :NEW_ISSUER_DELIVER_ID
        ];
        Assert.areEqual(2, contactDocuments.size(), 'Expected 2 contact documents');
        for (Contact_Document__c contactDocument : contactDocuments) {
            Assert.isFalse(contactDocument.Document_Owner_Mismatch__c, 'Expected Document_Owner_Mismatch__c to be false');
        }
    }

    /**
     * @description Tests the handlePost method when provided with a valid Document Checklist ID in the request payload.
     */
    @IsTest
    private static void testHandlePostDocumentChecklistId() {
        // Given :
        // Post request payload is valid.
        // Document owner name is different to applicant's legal name in My.App
        // Document owner email address is same as applicant's previous email address in My.App.
        Document_Checklist__c documentChecklistItem = [SELECT Name FROM Document_Checklist__c LIMIT 1];

        DigitaryApplicationDocumentPayload.PostRequest postRequestPayload = createPostRequestPayload(documentChecklistItem.Name, NEW_ISSUER_DELIVER_ID);
        postRequestPayload.issuerDocumentOwnerEmail = CONTACT_PREVIOUS_EMAIL;
        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;

        // When : calling process method
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocumentImpl().getHandlePost();
            clientImplHandler.setPayloadType(DigitaryApplicationDocumentPayload.PostRequest.class, DigitaryApplicationDocumentPayload.PostResponse.class);
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then : return success status
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        DigitaryApplicationDocumentPayload.PostResponse customResponse =
            (DigitaryApplicationDocumentPayload.PostResponse) JSON.deserialize(responseBodyString, DigitaryApplicationDocumentPayload.PostResponse.class);
        Assert.isTrue(customResponse.success, 'Expected success to be true');
        List<Contact_Document__c> contactDocuments = [
            SELECT Id, Document_Owner_Mismatch__c
            FROM Contact_Document__c
            WHERE Document_Checklist__c = :documentChecklistItem.Id
            AND Issuer_Delivery_Id__c = :NEW_ISSUER_DELIVER_ID
        ];
        Assert.areEqual(2, contactDocuments.size(), 'Expected 2 contact documents');
        for (Contact_Document__c contactDocument : contactDocuments) {
            Assert.isFalse(contactDocument.Document_Owner_Mismatch__c, 'Expected Document_Owner_Mismatch__c to be false');
        }
    }

    /**
     * @description Tests the handlePost method when provided with document owner name and email do not match.
     */
    @IsTest
    private static void testHandlePostWhenDocumentOwnerMismatch() {
        // Given :
        // Post request payload is valid
        // Document owner name is different to applicant's legal name in My.App
        // Document owner email address is different to applicant's email addresses in My.App.
        Application__c application = [SELECT Name FROM Application__c LIMIT 1];

        DigitaryApplicationDocumentPayload.PostRequest postRequestPayload = createPostRequestPayload(application.Name, NEW_ISSUER_DELIVER_ID);
        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;

        // When : calling process method
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocumentImpl().getHandlePost();
            clientImplHandler.setPayloadType(DigitaryApplicationDocumentPayload.PostRequest.class, DigitaryApplicationDocumentPayload.PostResponse.class);
            Assert.areEqual(clientImplHandler.getRequestType(), DigitaryApplicationDocumentPayload.PostRequest.class, 'Request type should match');
            Assert.areEqual(clientImplHandler.getResponseType(), DigitaryApplicationDocumentPayload.PostResponse.class, 'Response type should match');
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then : return success status
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        DigitaryApplicationDocumentPayload.PostResponse customResponse =
            (DigitaryApplicationDocumentPayload.PostResponse) JSON.deserialize(responseBodyString, DigitaryApplicationDocumentPayload.PostResponse.class);
        Assert.isTrue(customResponse.success, 'Expected success to be true');
        List<Contact_Document__c> contactDocuments = [
            SELECT Id, Document_Owner_Mismatch__c
            FROM Contact_Document__c
            WHERE Application__c = :application.Id
            AND Issuer_Delivery_Id__c = :NEW_ISSUER_DELIVER_ID
        ];
        Assert.areEqual(2, contactDocuments.size(), 'Expected 2 contact documents');
        for (Contact_Document__c contactDocument : contactDocuments) {
            Assert.isTrue(contactDocument.Document_Owner_Mismatch__c, 'Expected Document_Owner_Mismatch__c to be true');
        }
    }

    /**
     * @description Tests the handlePost method when provided with an invalid request payload - missing monash reference Id.
     */
    @isTest
    private static void testHandlePostWhenMissingMonashReferenceId() {
        // Given : post request payload is invalid - missing monash reference Id
        Application__c application = [SELECT Name FROM Application__c LIMIT 1];
        DigitaryApplicationDocumentPayload.PostRequest postRequestPayload = createPostRequestPayload(application.Name, NEW_ISSUER_DELIVER_ID);
        postRequestPayload.parameters.monash_reference_id = null;

        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;

        // When : calling process method
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocumentImpl().getHandlePost();
            clientImplHandler.setPayloadType(DigitaryApplicationDocumentPayload.PostRequest.class, DigitaryApplicationDocumentPayload.PostResponse.class);
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then : return custom response and error code to match
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        DigitaryApplicationDocumentPayload.PostResponse customResponse =
            (DigitaryApplicationDocumentPayload.PostResponse) JSON.deserialize(responseBodyString, DigitaryApplicationDocumentPayload.PostResponse.class);
        Assert.isFalse(customResponse.success, 'Expected success to be false');
        Assert.areEqual(DigitaryApplicationDocumentImpl.DIGITARY_ERROR_CODE_INVALID_PARAMETERS, customResponse.description, 'Expected error code to match');
    }

    /**
     * @description Tests the handlePost method when provided with an invalid request payload - record does not exist and email been sent to document owner.
     */
    @isTest
    private static void testHandlePostWhenRecordNotFoundAndEmailSent() {
        // Given : post request payload is invalid - no record can be found with given monash reference Id
        Environment_Settings__c environmentSettings = new Environment_Settings__c();
        environmentSettings.MyAppPortalURL__c =  'https://test.com.au';
        insert environmentSettings;
        DigitaryApplicationDocumentPayload.PostRequest postRequestPayload = createPostRequestPayload('Non-existent Id', NEW_ISSUER_DELIVER_ID);

        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;

        // When : calling process method
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocumentImpl().getHandlePost();
            clientImplHandler.setPayloadType(DigitaryApplicationDocumentPayload.PostRequest.class, DigitaryApplicationDocumentPayload.PostResponse.class);
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then : return custom response
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        DigitaryApplicationDocumentPayload.PostResponse customResponse =
            (DigitaryApplicationDocumentPayload.PostResponse) JSON.deserialize(responseBodyString, DigitaryApplicationDocumentPayload.PostResponse.class);
        Assert.isFalse(customResponse.success, 'Expected success to be false');
        Assert.areEqual(DigitaryApplicationDocumentImpl.DIGITARY_ERROR_CODE_INVALID_PARAMETERS, customResponse.description, 'Expected error code to match');
        Assert.isTrue(DigitaryApplicationDocumentImpl.emailResults.get(0).isSuccess(), 'One email should have been sent.');
    }

    /**
     * @description Tests the handlePost method when provided with an invalid request payload - record does not exist and email not been sent to document owner.
     */
    @isTest
    private static void testHandlePostWhenRecordNotFoundAndEmailError() {
        // Given : post request payload is invalid - no record can be found with given monash reference Id
        Environment_Settings__c environmentSettings = new Environment_Settings__c();
        environmentSettings.MyAppPortalURL__c =  'https://test.com.au';
        insert environmentSettings;
        DigitaryApplicationDocumentPayload.PostRequest postRequestPayload = createPostRequestPayload('Non-existent Id', NEW_ISSUER_DELIVER_ID);
        postRequestPayload.issuerDocumentOwnerEmail = 'invalid.email';

        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;

        // When : calling process method
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocumentImpl().getHandlePost();
            clientImplHandler.setPayloadType(DigitaryApplicationDocumentPayload.PostRequest.class, DigitaryApplicationDocumentPayload.PostResponse.class);
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then : return custom response
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        DigitaryApplicationDocumentPayload.PostResponse customResponse =
            (DigitaryApplicationDocumentPayload.PostResponse) JSON.deserialize(responseBodyString, DigitaryApplicationDocumentPayload.PostResponse.class);
        Assert.isFalse(customResponse.success, 'Expected success to be false');
        Assert.areEqual(DigitaryApplicationDocumentImpl.DIGITARY_ERROR_CODE_INVALID_PARAMETERS, customResponse.description, 'Expected error code to match');
        Assert.isFalse(DigitaryApplicationDocumentImpl.emailResults.get(0).isSuccess(), 'No email should have been sent.');
    }


    /**
     * @description Tests the handlePost method when provided with an invalid request payload - missing channel.
     */
    @isTest
    private static void testHandlePostWhenMissingChannel() {
        // Given : post request payload is invalid - missing channel
        Application__c application = [SELECT Name FROM Application__c LIMIT 1];
        DigitaryApplicationDocumentPayload.PostRequest postRequestPayload = createPostRequestPayload(application.Name, NEW_ISSUER_DELIVER_ID);
        postRequestPayload.channel = null;

        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;

        // When : calling process method
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocumentImpl().getHandlePost();
            clientImplHandler.setPayloadType(DigitaryApplicationDocumentPayload.PostRequest.class, DigitaryApplicationDocumentPayload.PostResponse.class);
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then : return custom response
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        DigitaryApplicationDocumentPayload.PostResponse customResponse =
            (DigitaryApplicationDocumentPayload.PostResponse) JSON.deserialize(responseBodyString, DigitaryApplicationDocumentPayload.PostResponse.class);
        Assert.isFalse(customResponse.success, 'Expected success to be false');
        Assert.areEqual(DigitaryApplicationDocumentImpl.DIGITARY_ERROR_CODE_PARSE_ERROR, customResponse.description, 'Expected error code to match');
    }

    /**
     * @description Tests the handlePost method when provided with an invalid request payload - missing document owner name.
     */
    @isTest
    private static void testHandlePostWhenMissingDocumentOwnerName() {
        // Given : post request payload is invalid - missing document owner name
        Application__c application = [SELECT Name FROM Application__c LIMIT 1];
        DigitaryApplicationDocumentPayload.PostRequest postRequestPayload = createPostRequestPayload(application.Name, NEW_ISSUER_DELIVER_ID);
        postRequestPayload.issuerDocumentOwnerName = null;

        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;

        // When : calling process method
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocumentImpl().getHandlePost();
            clientImplHandler.setPayloadType(DigitaryApplicationDocumentPayload.PostRequest.class, DigitaryApplicationDocumentPayload.PostResponse.class);
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then : return custom response
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        DigitaryApplicationDocumentPayload.PostResponse customResponse =
            (DigitaryApplicationDocumentPayload.PostResponse) JSON.deserialize(responseBodyString, DigitaryApplicationDocumentPayload.PostResponse.class);
        Assert.isFalse(customResponse.success, 'Expected success to be false');
        Assert.areEqual(DigitaryApplicationDocumentImpl.DIGITARY_ERROR_CODE_PARSE_ERROR, customResponse.description, 'Expected error code to match');
    }

    /**
     * @description Tests the handlePost method when provided with an invalid request payload - missing document owner email.
     */
    @isTest
    private static void testHandlePostWhenMissingDocumentOwnerEmail() {
        // Given : post request payload is invalid - missing document owner email
        Application__c application = [SELECT Name FROM Application__c LIMIT 1];
        DigitaryApplicationDocumentPayload.PostRequest postRequestPayload = createPostRequestPayload(application.Name, NEW_ISSUER_DELIVER_ID);
        postRequestPayload.issuerDocumentOwnerEmail = null;

        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;

        // When : calling process method
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocumentImpl().getHandlePost();
            clientImplHandler.setPayloadType(DigitaryApplicationDocumentPayload.PostRequest.class, DigitaryApplicationDocumentPayload.PostResponse.class);
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then : return custom response
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        DigitaryApplicationDocumentPayload.PostResponse customResponse =
            (DigitaryApplicationDocumentPayload.PostResponse) JSON.deserialize(responseBodyString, DigitaryApplicationDocumentPayload.PostResponse.class);
        Assert.isFalse(customResponse.success, 'Expected success to be false');
        Assert.areEqual(DigitaryApplicationDocumentImpl.DIGITARY_ERROR_CODE_PARSE_ERROR, customResponse.description, 'Expected error code to match');
    }

    /**
     * @description Tests the handlePost method when provided with an invalid request payload - missing documents.
     */
    @isTest
    private static void testHandlePostWhenMissingDocuments() {
        // Given : post request payload is invalid - missing documents
        Application__c application = [SELECT Name FROM Application__c LIMIT 1];
        DigitaryApplicationDocumentPayload.PostRequest postRequestPayload = createPostRequestPayload(application.Name, NEW_ISSUER_DELIVER_ID);
        postRequestPayload.documents = null;

        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;

        // When : calling process method
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocumentImpl().getHandlePost();
            clientImplHandler.setPayloadType(DigitaryApplicationDocumentPayload.PostRequest.class, DigitaryApplicationDocumentPayload.PostResponse.class);
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then : return custom response
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        DigitaryApplicationDocumentPayload.PostResponse customResponse =
            (DigitaryApplicationDocumentPayload.PostResponse) JSON.deserialize(responseBodyString, DigitaryApplicationDocumentPayload.PostResponse.class);
        Assert.isFalse(customResponse.success, 'Expected success to be false');
        Assert.areEqual(DigitaryApplicationDocumentImpl.DIGITARY_ERROR_CODE_PARSE_ERROR, customResponse.description, 'Expected error code to match');
    }

    /**
     * @description Tests the handlePost method when provided with an invalid request payload - missing document Id.
     */
    @isTest
    private static void testHandlePostWhenMissingDocumentId() {
        // Given : post request payload is invalid - missing document Id
        Application__c application = [SELECT Name FROM Application__c LIMIT 1];
        DigitaryApplicationDocumentPayload.PostRequest postRequestPayload = createPostRequestPayload(application.Name, NEW_ISSUER_DELIVER_ID);
        postRequestPayload.documents.get(0).issuerDocumentId = null;

        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;

        // When : calling process method
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocumentImpl().getHandlePost();
            clientImplHandler.setPayloadType(DigitaryApplicationDocumentPayload.PostRequest.class, DigitaryApplicationDocumentPayload.PostResponse.class);
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then : return custom response
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        DigitaryApplicationDocumentPayload.PostResponse customResponse =
            (DigitaryApplicationDocumentPayload.PostResponse) JSON.deserialize(responseBodyString, DigitaryApplicationDocumentPayload.PostResponse.class);
        Assert.isFalse(customResponse.success, 'Expected success to be false');
        Assert.areEqual(DigitaryApplicationDocumentImpl.DIGITARY_ERROR_CODE_PARSE_ERROR, customResponse.description, 'Expected error code to match');
    }

    /**
     * @description Tests the handlePost method when provided with an invalid request payload - missing issuerDate.
     */
    @isTest
    private static void testHandlePostWhenMissingIssuerDate() {
        // Given : post request payload is invalid - missing issuerDate
        Application__c application = [SELECT Name FROM Application__c LIMIT 1];
        DigitaryApplicationDocumentPayload.PostRequest postRequestPayload = createPostRequestPayload(application.Name, NEW_ISSUER_DELIVER_ID);
        postRequestPayload.documents.get(0).issuerDate = null;

        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;

        // When : calling process method
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocumentImpl().getHandlePost();
            clientImplHandler.setPayloadType(DigitaryApplicationDocumentPayload.PostRequest.class, DigitaryApplicationDocumentPayload.PostResponse.class);
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then : return custom response
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        DigitaryApplicationDocumentPayload.PostResponse customResponse =
            (DigitaryApplicationDocumentPayload.PostResponse) JSON.deserialize(responseBodyString, DigitaryApplicationDocumentPayload.PostResponse.class);
        Assert.isFalse(customResponse.success, 'Expected success to be false');
        Assert.areEqual(DigitaryApplicationDocumentImpl.DIGITARY_ERROR_CODE_PARSE_ERROR, customResponse.description, 'Expected error code to match');
    }

    /**
     * @description Tests the handlePost method when provided with an invalid request payload - missing issuerName.
     */
    @isTest
    private static void testHandlePostWhenMissingIssuerName() {
        // Given : post request payload is invalid - missing issuerName
        Application__c application = [SELECT Name FROM Application__c LIMIT 1];
        DigitaryApplicationDocumentPayload.PostRequest postRequestPayload = createPostRequestPayload(application.Name, NEW_ISSUER_DELIVER_ID);
        postRequestPayload.documents.get(0).issuerName = null;

        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;

        // When : calling process method
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocumentImpl().getHandlePost();
            clientImplHandler.setPayloadType(DigitaryApplicationDocumentPayload.PostRequest.class, DigitaryApplicationDocumentPayload.PostResponse.class);
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then : return custom response
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        DigitaryApplicationDocumentPayload.PostResponse customResponse =
            (DigitaryApplicationDocumentPayload.PostResponse) JSON.deserialize(responseBodyString, DigitaryApplicationDocumentPayload.PostResponse.class);
        Assert.isFalse(customResponse.success, 'Expected success to be false');
        Assert.areEqual(DigitaryApplicationDocumentImpl.DIGITARY_ERROR_CODE_PARSE_ERROR, customResponse.description, 'Expected error code to match');
    }

    /**
     * @description Tests the handlePost method when provided with an invalid request payload - missing issuerDocumentType.
     */
    @isTest
    private static void testHandlePostWhenMissingIssuerDocumentType() {
        // Given : post request payload is invalid - missing issuerDocumentType
        Application__c application = [SELECT Name FROM Application__c LIMIT 1];
        DigitaryApplicationDocumentPayload.PostRequest postRequestPayload = createPostRequestPayload(application.Name, NEW_ISSUER_DELIVER_ID);
        postRequestPayload.documents.get(0).issuerDocumentType = null;

        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;

        // When : calling process method
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocumentImpl().getHandlePost();
            clientImplHandler.setPayloadType(DigitaryApplicationDocumentPayload.PostRequest.class, DigitaryApplicationDocumentPayload.PostResponse.class);
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then : return custom response
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        DigitaryApplicationDocumentPayload.PostResponse customResponse =
            (DigitaryApplicationDocumentPayload.PostResponse) JSON.deserialize(responseBodyString, DigitaryApplicationDocumentPayload.PostResponse.class);
        Assert.isFalse(customResponse.success, 'Expected success to be false');
        Assert.areEqual(DigitaryApplicationDocumentImpl.DIGITARY_ERROR_CODE_PARSE_ERROR, customResponse.description, 'Expected error code to match');
    }

    /**
     * @description Tests the handlePost method when provided with duplicate delivery Id
     */
    @isTest
    private static void testHandlePostWhenDuplicateDelivery() {
        // Given : post request payload is valid but with existing delivery Id
        Application__c application = [SELECT Name FROM Application__c LIMIT 1];

        DigitaryApplicationDocumentPayload.PostRequest postRequestPayload = createPostRequestPayload(application.Name, EXISTING_ISSUER_DELIVER_ID);
        postRequestPayload.issuerDeliveryId = EXISTING_ISSUER_DELIVER_ID;

        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;

        // When : calling process method
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocumentImpl().getHandlePost();
            clientImplHandler.setPayloadType(DigitaryApplicationDocumentPayload.PostRequest.class, DigitaryApplicationDocumentPayload.PostResponse.class);
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then : return custom response and DIGITARY_ERROR_CODE_DUPLICATE_DELIVERY error code
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        DigitaryApplicationDocumentPayload.PostResponse customResponse =
            (DigitaryApplicationDocumentPayload.PostResponse) JSON.deserialize(responseBodyString, DigitaryApplicationDocumentPayload.PostResponse.class);
        Assert.isFalse(customResponse.success, 'Expected success to be false');
        Assert.areEqual(DigitaryApplicationDocumentImpl.DIGITARY_ERROR_CODE_DUPLICATE_DELIVERY, customResponse.description, 'Expected error code to match');
    }

    /**
     * @description Tests the handlePost with valid payload
     */
    @isTest
    private static void testHandlePatch() {
        // Given : patch request payload is valid
        DigitaryApplicationDocumentPayload.PatchRequest patchRequestPayload = createPatchRequestPayload(EXISTING_ISSUER_DELIVER_ID);

        RestRequest request = new RestRequest();
        request.httpMethod = 'PATCH';
        request.requestBody = Blob.valueOf(JSON.serialize(patchRequestPayload));
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;

        // When : calling process method
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocumentImpl().getHandlePatch();
            clientImplHandler.setPayloadType(DigitaryApplicationDocumentPayload.PatchRequest.class, DigitaryApplicationDocumentPayload.PatchResponse.class);
            Assert.areEqual(clientImplHandler.getRequestType(), DigitaryApplicationDocumentPayload.PatchRequest.class, 'Request type should match');
            Assert.areEqual(clientImplHandler.getResponseType(), DigitaryApplicationDocumentPayload.PatchResponse.class, 'Response type should match');
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then : return custom response
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        DigitaryApplicationDocumentPayload.PatchResponse customResponse =
            (DigitaryApplicationDocumentPayload.PatchResponse) JSON.deserialize(responseBodyString, DigitaryApplicationDocumentPayload.PatchResponse.class);
        Assert.isTrue(customResponse.success, 'Expected success to be true');
    }

    /**
     * @description Tests the handlePost with invalid payload - missing deliveryId
     */
    @isTest
    private static void testHandlePatchWhenDeliveryIdMissing() {
        // Given : patch request payload is valid
        DigitaryApplicationDocumentPayload.PatchRequest patchRequestPayload = new DigitaryApplicationDocumentPayload.PatchRequest();
        RestRequest request = new RestRequest();
        request.httpMethod = 'PATCH';
        request.requestBody = Blob.valueOf(JSON.serialize(patchRequestPayload));
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;

        // When : calling process method
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocumentImpl().getHandlePatch();
            clientImplHandler.setPayloadType(DigitaryApplicationDocumentPayload.PatchRequest.class, DigitaryApplicationDocumentPayload.PatchResponse.class);
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then : return custom response with error
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        DigitaryApplicationDocumentPayload.PatchResponse customResponse =
            (DigitaryApplicationDocumentPayload.PatchResponse) JSON.deserialize(responseBodyString, DigitaryApplicationDocumentPayload.PatchResponse.class);
        Assert.isFalse(customResponse.success, 'Expected success to be false');
        Assert.areEqual(customResponse.description, DigitaryApplicationDocumentImpl.DIGITARY_ERROR_CODE_UNKNOWN_DELIVERY, 'Expected error code to match');
    }

    /**
     * @description Tests the handlePatch with invalid payload - existing contact documents with same delivery Id not found
     */
    @isTest
    private static void testHandlePatchWhenExistingContactDocumentsWithSameDeliveryIdNotFound() {
        // Given : patch request payload is valid
        DigitaryApplicationDocumentPayload.PatchRequest patchRequestPayload = createPatchRequestPayload(NEW_ISSUER_DELIVER_ID);
        RestRequest request = new RestRequest();
        request.httpMethod = 'PATCH';
        request.requestBody = Blob.valueOf(JSON.serialize(patchRequestPayload));
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;

        // When : calling process method
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocumentImpl().getHandlePatch();
            clientImplHandler.setPayloadType(DigitaryApplicationDocumentPayload.PatchRequest.class, DigitaryApplicationDocumentPayload.PatchResponse.class);
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then : return custom response with error
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        DigitaryApplicationDocumentPayload.PatchResponse customResponse =
            (DigitaryApplicationDocumentPayload.PatchResponse) JSON.deserialize(responseBodyString, DigitaryApplicationDocumentPayload.PatchResponse.class);
        Assert.isFalse(customResponse.success, 'Expected success to be false');
        Assert.areEqual(customResponse.description, DigitaryApplicationDocumentImpl.DIGITARY_ERROR_CODE_UNKNOWN_DELIVERY, 'Expected error code to match');
    }

    /**
     * @description Tests the handlePatch with invalid payload - found existing contact documents with same delivery Id and issuer document Id
     */
    @isTest
    private static void testHandlePatchWhenExistingContactDocumentsWithSameIssuerDocumentIdFound() {
        // Given : patch request payload is invalid - with same existing issuer document Id and delivery Id
        DigitaryApplicationDocumentPayload.PatchRequest patchRequestPayload = createPatchRequestPayload(EXISTING_ISSUER_DELIVER_ID);
        patchRequestPayload.documents.get(0).issuerDocumentId = EXISTING_ISSUER_DOCUMENT_ID;
        RestRequest request = new RestRequest();
        request.httpMethod = 'PATCH';
        request.requestBody = Blob.valueOf(JSON.serialize(patchRequestPayload));
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;

        // When : calling process method
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocumentImpl().getHandlePatch();
            clientImplHandler.setPayloadType(DigitaryApplicationDocumentPayload.PatchRequest.class, DigitaryApplicationDocumentPayload.PatchResponse.class);
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then : return custom response with error
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        DigitaryApplicationDocumentPayload.PatchResponse customResponse =
            (DigitaryApplicationDocumentPayload.PatchResponse) JSON.deserialize(responseBodyString, DigitaryApplicationDocumentPayload.PatchResponse.class);
        Assert.isFalse(customResponse.success, 'Expected success to be false');
        Assert.areEqual(customResponse.description, DigitaryApplicationDocumentImpl.DIGITARY_ERROR_CODE_DUPLICATE_DOCUMENT, 'Expected error code to match');
    }

    private static DigitaryApplicationDocumentPayload.PostRequest createPostRequestPayload(String monashReferenceId, String issuerDeliveryId) {
        DigitaryApplicationDocumentPayload.PostRequest postRequestPayload = new DigitaryApplicationDocumentPayload.PostRequest();
        postRequestPayload.channel = 'CSSD';
        postRequestPayload.issuerDocumentOwnerName = 'Test Owner';
        postRequestPayload.issuerDocumentOwnerEmail = 'Test.Owner@email.com';
        postRequestPayload.issuerDeliveryId = issuerDeliveryId;
        postRequestPayload.documents = createDocumentsRequestPayload();
        postRequestPayload.parameters = new DigitaryApplicationDocumentPayload.Parameters();
        postRequestPayload.parameters.monash_reference_id = monashReferenceId;
        return postRequestPayload;
    }

    private static DigitaryApplicationDocumentPayload.PatchRequest createPatchRequestPayload(String issuerDeliveryId) {
        DigitaryApplicationDocumentPayload.PatchRequest patchRequestPayload = new DigitaryApplicationDocumentPayload.PatchRequest();
        patchRequestPayload.issuerDeliveryId = issuerDeliveryId;
        patchRequestPayload.documents = createDocumentsRequestPayload();
        return patchRequestPayload;
    }

    private static List<DigitaryApplicationDocumentPayload.Document> createDocumentsRequestPayload() {
        DigitaryApplicationDocumentPayload.Document documentPayload1 = new DigitaryApplicationDocumentPayload.Document();
        documentPayload1.issuerName = 'Test issuer name';
        documentPayload1.issuerDocumentType = 'Test issuer document type 1';
        documentPayload1.issuerDate = Date.today();
        documentPayload1.issuerDocumentId = '67230a8b-7a3e-58c3-b2c7-f71ecfc049b6';
        DigitaryApplicationDocumentPayload.Document documentPayload2 = new DigitaryApplicationDocumentPayload.Document();
        documentPayload2.issuerName = 'Test issuer name';
        documentPayload2.issuerDocumentType = 'Test issuer document type 2';
        documentPayload2.issuerDate = Date.today();
        documentPayload2.issuerDocumentId = '67230a8b-7a3e-58c3-b2c7-f71ecfc049b7';
        return new List<DigitaryApplicationDocumentPayload.Document>{
            documentPayload1,
            documentPayload2
        };
    }
}