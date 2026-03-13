/**
 * @description Test class to cover DigitaryApplicationDocContentImpl
 * @author Kai-Fan Hsieh
 * @since 08/08/2024
 */
@IsTest(IsParallel=true)
public class DigitaryApplicationDocContentImpl_Test {
    private static final String EXISTING_ISSUER_DELIVERY_ID = '4d611b71-3512-4ada-8577-7f63158df249';
    private static final String NEW_ISSUER_DELIVERY_ID = '4d611b71-3512-4ada-8577-7f63158df235';
    private static final String EXISTING_ISSUER_DOCUMENT_ID = '67230a8b-7a3e-58c3-b2c7-f71ecfc049b5';
    private static final String NEW_ISSUER_DOCUMENT_ID = '67230a8b-7a3e-58c3-b2c7-f71ecfc049c5';

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
        insert new Contact_Document__c(
            Contact__c = testContact.Id,
            Document_Type__c = 'OTHERDCTYP',
            Filename__c = 'Test_Issuer_Transcript.pdf',
            Issuer_Delivery_Id__c = EXISTING_ISSUER_DELIVERY_ID,
            Issuer_Document_Id__c = EXISTING_ISSUER_DOCUMENT_ID,
            Application__c = testApplication.Id,
            Document_Checklist__c = testChecklist.Id,
            Channel__c = 'CSSD'
        );
    }

    // Overloaded setPostRequest method
    private static RestResponse setPostRequest(String issuerDeliveryId, String issuerDocumentId, String contentType, Boolean createContentVersion) {
        return setPostRequest(issuerDeliveryId, issuerDocumentId, contentType, createContentVersion, null);
    }


    // New setPostRequest method with contentVersionId parameter
    private static RestResponse setPostRequest(String issuerDeliveryId, String issuerDocumentId, String contentType, Boolean createContentVersion, String contentVersionId) {
        ContentVersion contentVersion;
        if (createContentVersion) {
            contentVersion = new ContentVersion(
                Title = 'Test',
                PathOnClient = '/Test.pdf',
                VersionData = Blob.valueOf('Test ContentVersion Body')
            );
            insert contentVersion;
        }

        DigitaryApplicationDocContentPayload.PostRequest postRequestPayload = new DigitaryApplicationDocContentPayload.PostRequest();
        postRequestPayload.issuerDeliveryId = issuerDeliveryId;
        postRequestPayload.issuerDocumentId = issuerDocumentId;
        if (contentVersionId != null) {
            postRequestPayload.contentVersionId = contentVersionId;
        } else if (createContentVersion) {
            postRequestPayload.contentVersionId = contentVersion.Id;
        } else {
            postRequestPayload.contentVersionId = null;
        }
        postRequestPayload.contentType = contentType;

        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;

        return response;
    }

    /**
     * @description Tests the handlePost method when provided with a valid request payload.
     */
    @IsTest
    private static void testHandlePost() {
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            // Given : post request payload is valid and contact document's Document_Owner_Mismatch__c is false
            setPostRequest(EXISTING_ISSUER_DELIVERY_ID, EXISTING_ISSUER_DOCUMENT_ID, DigitaryApplicationDocContentImpl.FILE_FORMAT, true);
            // When : calling process method
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocContentImpl().getHandlePost();
            clientImplHandler.setPayloadType(DigitaryApplicationDocContentPayload.PostRequest.class, DigitaryApplicationDocContentPayload.PostResponse.class);
            Assert.areEqual(clientImplHandler.getRequestType(), DigitaryApplicationDocContentPayload.PostRequest.class, 'Request type should match');
            Assert.areEqual(clientImplHandler.getResponseType(), DigitaryApplicationDocContentPayload.PostResponse.class, 'Response type should match');
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then : content document link is created
        Contact_Document__c contactDocument = [
            SELECT Id, Submitted__c, Post_Submission__c, Document_Owner_Mismatch__c, Application__r.Last_Verified_Document_Received_Date__c
            FROM Contact_Document__c
            WHERE Issuer_Delivery_Id__c = :EXISTING_ISSUER_DELIVERY_ID
            AND Issuer_Document_Id__c = :EXISTING_ISSUER_DOCUMENT_ID
            LIMIT 1
        ];

        List<ContentDocumentLink> contentDocumentLinks = [
            SELECT Id, Visibility
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :contactDocument.Id
        ];

        Assert.areEqual(1, contentDocumentLinks.size(), 'Expected 1 ContentDocumentLink');
        Assert.isFalse(contactDocument.Document_Owner_Mismatch__c, 'Expected Document_Owner_Mismatch__c to be false');
        Assert.isTrue(contactDocument.Application__r.Last_Verified_Document_Received_Date__c != null, 'Expected Last_Verified_Document_Received_Date__c to be populated');
        Assert.areEqual('AllUsers', contentDocumentLinks.get(0).Visibility, 'Expected Visibility to be All Users');
    }

    /**
     * @description Tests the handlePost method when provided with a valid request payload when document owner mismatch.
     */
    @IsTest
    private static void testHandlePostWhenDocumentOwnerMismatch() {
        // Given : post request payload is valid and contact document's Document_Owner_Mismatch__c is true
        Contact_Document__c contactDocument = [
            SELECT Id, Submitted__c, Post_Submission__c, Document_Owner_Mismatch__c
            FROM Contact_Document__c
            WHERE Issuer_Delivery_Id__c = :EXISTING_ISSUER_DELIVERY_ID
            AND Issuer_Document_Id__c = :EXISTING_ISSUER_DOCUMENT_ID
            LIMIT 1
        ];

        contactDocument.Document_Owner_Mismatch__c = true;
        update contactDocument;
        // When : calling process method
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            setPostRequest(EXISTING_ISSUER_DELIVERY_ID, EXISTING_ISSUER_DOCUMENT_ID, DigitaryApplicationDocContentImpl.FILE_FORMAT, true);
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocContentImpl().getHandlePost();
            clientImplHandler.setPayloadType(DigitaryApplicationDocContentPayload.PostRequest.class, DigitaryApplicationDocContentPayload.PostResponse.class);
            Assert.areEqual(clientImplHandler.getRequestType(), DigitaryApplicationDocContentPayload.PostRequest.class, 'Request type should match');
            Assert.areEqual(clientImplHandler.getResponseType(), DigitaryApplicationDocContentPayload.PostResponse.class, 'Response type should match');
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then : content document link is created
        List<ContentDocumentLink> contentDocumentLinks = [
            SELECT Id, Visibility
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :contactDocument.Id
        ];

        Assert.areEqual(1, contentDocumentLinks.size(), 'Expected 1 ContentDocumentLink');
        Assert.isTrue(contactDocument.Document_Owner_Mismatch__c, 'Expected Document_Owner_Mismatch__c to be true');
        Assert.areEqual('InternalUsers', contentDocumentLinks.get(0).Visibility, 'Expected Visibility to be Internal Users');
    }

    /**
     * @description Tests the handlePost method when provided with a valid request payload for a submitted application.
     */
    @IsTest
    private static void testHandlePostForSubmittedApplication() {
        // Given : post request payload is valid and application is submitted
        Application__c application = [SELECT Id FROM Application__c LIMIT 1];
        application.Status__c = 'Submitted';
        TriggerCommon.disableTrigger('Application__c');
        update application;
        RestResponse response;
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            response = setPostRequest(EXISTING_ISSUER_DELIVERY_ID, EXISTING_ISSUER_DOCUMENT_ID, DigitaryApplicationDocContentImpl.FILE_FORMAT, true);
            // When : calling process method
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocContentImpl().getHandlePost();
            clientImplHandler.setPayloadType(DigitaryApplicationDocContentPayload.PostRequest.class, DigitaryApplicationDocContentPayload.PostResponse.class);
            Assert.areEqual(clientImplHandler.getRequestType(), DigitaryApplicationDocContentPayload.PostRequest.class, 'Request type should match');
            Assert.areEqual(clientImplHandler.getResponseType(), DigitaryApplicationDocContentPayload.PostResponse.class, 'Response type should match');
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then : return success status
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        DigitaryApplicationDocContentPayload.PostResponse customResponse =
            (DigitaryApplicationDocContentPayload.PostResponse) JSON.deserialize(responseBodyString, DigitaryApplicationDocContentPayload.PostResponse.class);
        Contact_Document__c contactDocument = [
            SELECT Id, Submitted__c, Post_Submission__c
            FROM Contact_Document__c
            WHERE Issuer_Delivery_Id__c = :EXISTING_ISSUER_DELIVERY_ID
            AND Issuer_Document_Id__c = :EXISTING_ISSUER_DOCUMENT_ID
            LIMIT 1
        ];

        // ContentDocument should be created and Contact_Document__c record should be submitted
        Assert.isTrue(customResponse.success, 'Expected success status is true');
        Assert.isTrue(contactDocument.Submitted__c, 'Expected Submitted__c to be true as application is submitted');
        Assert.isTrue(contactDocument.Post_Submission__c, 'Expected Post_Submission__c to be true as application is submitted');
    }

    /**
     * @description Tests the handlePost method when provided with an invalid content type.
     */
    @IsTest
    private static void testHandlePostInvalidContentType() {
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            // Given : post request payload is invalid - content type
            RestResponse response = setPostRequest(EXISTING_ISSUER_DELIVERY_ID, EXISTING_ISSUER_DOCUMENT_ID, 'image/jpeg', true);
            Assert.areEqual(1, [SELECT Id FROM ContentVersion].size(), 'Expected content version to be created');
            // When : calling process method
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocContentImpl().getHandlePost();
            clientImplHandler.setPayloadType(DigitaryApplicationDocContentPayload.PostRequest.class, DigitaryApplicationDocContentPayload.PostResponse.class);
            clientImplHandler.execute();
            Test.stopTest();
            // Then : return success status
            String responseBodyString = response.responseBody.toString();
            // Deserialize string to custom payload class
            DigitaryApplicationDocContentPayload.PostResponse customResponse =
                (DigitaryApplicationDocContentPayload.PostResponse) JSON.deserialize(responseBodyString, DigitaryApplicationDocContentPayload.PostResponse.class);
            Assert.isFalse(customResponse.success, 'Expected success to be false');
            Assert.areEqual(DigitaryApplicationDocContentImpl.DIGITARY_ERROR_CODE_INVALID_FILE_FORMAT, customResponse.description, 'Expected error code to match');
            List<ContentVersion> contentVersions = [SELECT Id FROM ContentVersion];
            Assert.areEqual(0, contentVersions.size(), 'Expected content version to be deleted when validation or error occurs');
        }
    }

    /**
     * @description Tests the handlePost method when missing delivery Id.
     */
    @IsTest
    private static void testHandlePostMissingDeliveryId() {
        RestResponse response;
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            // Given : post request payload is invalid - missing delivery Id
            response = setPostRequest(null, EXISTING_ISSUER_DOCUMENT_ID, DigitaryApplicationDocContentImpl.FILE_FORMAT, true);
            // When : calling process method
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocContentImpl().getHandlePost();
            clientImplHandler.setPayloadType(DigitaryApplicationDocContentPayload.PostRequest.class, DigitaryApplicationDocContentPayload.PostResponse.class);
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then : return success status
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        DigitaryApplicationDocContentPayload.PostResponse customResponse =
            (DigitaryApplicationDocContentPayload.PostResponse) JSON.deserialize(responseBodyString, DigitaryApplicationDocContentPayload.PostResponse.class);
        Assert.isFalse(customResponse.success, 'Expected success to be false');
        Assert.areEqual(DigitaryApplicationDocContentImpl.DIGITARY_ERROR_CODE_INVALID_DELIVERY, customResponse.description, 'Expected error code to match');
    }

    /**
     * @description Tests the handlePost method when delivery Id does not exist.
     */
    @IsTest
    private static void testHandlePostWrongDeliveryId() {
        RestResponse response;
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            // Given : post request payload is invalid - missing delivery Id
            response = setPostRequest(NEW_ISSUER_DELIVERY_ID, EXISTING_ISSUER_DOCUMENT_ID, DigitaryApplicationDocContentImpl.FILE_FORMAT, true);
            // When : calling process method
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocContentImpl().getHandlePost();
            clientImplHandler.setPayloadType(DigitaryApplicationDocContentPayload.PostRequest.class, DigitaryApplicationDocContentPayload.PostResponse.class);
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then : return success status
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        DigitaryApplicationDocContentPayload.PostResponse customResponse =
            (DigitaryApplicationDocContentPayload.PostResponse) JSON.deserialize(responseBodyString, DigitaryApplicationDocContentPayload.PostResponse.class);
        Assert.isFalse(customResponse.success, 'Expected success to be false');
        Assert.areEqual(DigitaryApplicationDocContentImpl.DIGITARY_ERROR_CODE_INVALID_DELIVERY, customResponse.description, 'Expected error code to match');
    }

    /**
     * @description Tests the handlePost method when missing document Id.
     */
    @IsTest
    private static void testHandlePostMissingDocumentId() {
        RestResponse response;
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            // Given : post request payload is invalid - missing document Id
            response = setPostRequest(EXISTING_ISSUER_DELIVERY_ID, null, DigitaryApplicationDocContentImpl.FILE_FORMAT, true);
            // When : calling process method
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocContentImpl().getHandlePost();
            clientImplHandler.setPayloadType(DigitaryApplicationDocContentPayload.PostRequest.class, DigitaryApplicationDocContentPayload.PostResponse.class);
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then : return success status
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        DigitaryApplicationDocContentPayload.PostResponse customResponse =
            (DigitaryApplicationDocContentPayload.PostResponse) JSON.deserialize(responseBodyString, DigitaryApplicationDocContentPayload.PostResponse.class);
        Assert.isFalse(customResponse.success, 'Expected success to be false');
        Assert.areEqual(DigitaryApplicationDocContentImpl.DIGITARY_ERROR_CODE_INVALID_DOCUMENT, customResponse.description, 'Expected error code to match');
    }

    /**
     * @description Tests the handlePost method when provided with a wrong document Id.
     */
    @IsTest
    private static void testHandlePostWrongDocumentId() {
        RestResponse response;
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            // Given : post request payload is invalid - wrong document Id
            response = setPostRequest(EXISTING_ISSUER_DELIVERY_ID, NEW_ISSUER_DOCUMENT_ID, DigitaryApplicationDocContentImpl.FILE_FORMAT, true);
            // When : calling process method
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocContentImpl().getHandlePost();
            clientImplHandler.setPayloadType(DigitaryApplicationDocContentPayload.PostRequest.class, DigitaryApplicationDocContentPayload.PostResponse.class);
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then : return success status
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        DigitaryApplicationDocContentPayload.PostResponse customResponse =
            (DigitaryApplicationDocContentPayload.PostResponse) JSON.deserialize(responseBodyString, DigitaryApplicationDocContentPayload.PostResponse.class);
        Assert.isFalse(customResponse.success, 'Expected success to be false');
        Assert.areEqual(DigitaryApplicationDocContentImpl.DIGITARY_ERROR_CODE_INVALID_DOCUMENT, customResponse.description, 'Expected error code to match');
    }

    /**
     * @description Tests the handlePost method when no file content.
     */
    @IsTest
    private static void testHandlePostNoFile() {
        RestResponse response;
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            // Given : post request payload is invalid - not file content
            response = setPostRequest(EXISTING_ISSUER_DELIVERY_ID, EXISTING_ISSUER_DOCUMENT_ID, DigitaryApplicationDocContentImpl.FILE_FORMAT, false);
            // When : calling process method
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocContentImpl().getHandlePost();
            clientImplHandler.setPayloadType(DigitaryApplicationDocContentPayload.PostRequest.class, DigitaryApplicationDocContentPayload.PostResponse.class);
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then : return success status
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        DigitaryApplicationDocContentPayload.PostResponse customResponse =
            (DigitaryApplicationDocContentPayload.PostResponse) JSON.deserialize(responseBodyString, DigitaryApplicationDocContentPayload.PostResponse.class);
        Assert.isFalse(customResponse.success, 'Expected success to be false');
        Assert.areEqual(DigitaryApplicationDocContentImpl.DIGITARY_ERROR_CODE_INVALID_NO_BODY, customResponse.description, 'Expected error code to match');
    }

    /**
     * @description Tests the handlePost method when the ContentVersion does not exist.
     */
    @IsTest
    private static void testHandlePostContentVersionDoesNotExist() {
        RestResponse response;
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            // Given: post request with non-existent contentVersionId
            String fakeContentVersionId = FakeRecordIdGenerator.generateId(ContentVersion.getSObjectType()); // Assuming this ID does not exist
            response = setPostRequest(
                EXISTING_ISSUER_DELIVERY_ID,
                EXISTING_ISSUER_DOCUMENT_ID,
                DigitaryApplicationDocContentImpl.FILE_FORMAT,
                false,
                fakeContentVersionId
            );

            // When: calling process method
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocContentImpl().getHandlePost();
            clientImplHandler.setPayloadType(
                DigitaryApplicationDocContentPayload.PostRequest.class,
                DigitaryApplicationDocContentPayload.PostResponse.class
            );
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then: expect failure response with specific error code
        String responseBodyString = response.responseBody.toString();
        DigitaryApplicationDocContentPayload.PostResponse customResponse =
            (DigitaryApplicationDocContentPayload.PostResponse) JSON.deserialize(
                responseBodyString,
                DigitaryApplicationDocContentPayload.PostResponse.class
            );

        Assert.isFalse(customResponse.success, 'Expected success to be false');
        Assert.areEqual(
            DigitaryApplicationDocContentImpl.DIGITARY_ERROR_CODE_INVALID_NO_BODY,
            customResponse.description,
            'Expected error code to match'
        );
    }

    /**
     * @description Tests that when the Contact_Document__c already has a ContentDocumentLink, it is cloned and the new ContentDocument is linked to it.
     */
    @IsTest
    private static void testContactDocumentAlreadyHasLink() {
        //Given: Create the initial ContentVersion and link it to the Contact_Document__c
        ContentVersion contentVersion1 = new ContentVersion(
            Title = 'Test1',
            PathOnClient = '/Test1.pdf',
            VersionData = Blob.valueOf('Test ContentVersion Body 1')
        );
        insert contentVersion1;

        // Link the initial ContentDocument to the Contact_Document__c
        Contact_Document__c existingContactDocument = [SELECT Id FROM Contact_Document__c LIMIT 1];
        ContentDocumentLink cdl1 = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion1.Id].ContentDocumentId,
            LinkedEntityId = existingContactDocument.Id,
            ShareType = 'I',
            Visibility = 'AllUsers'
        );
        insert cdl1;

        ContentVersion contentVersion2;

        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            // Create a new ContentVersion to simulate a new upload
            contentVersion2 = new ContentVersion(
                Title = 'Test2',
                PathOnClient = '/Test2.pdf',
                VersionData = Blob.valueOf('Test ContentVersion Body 2')
            );
            insert contentVersion2;

            // Set up the POST request with the new ContentVersionId
            setPostRequest(
                EXISTING_ISSUER_DELIVERY_ID,
                EXISTING_ISSUER_DOCUMENT_ID,
                DigitaryApplicationDocContentImpl.FILE_FORMAT,
                false,
                contentVersion2.Id
            );

            // When: calling process method
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new DigitaryApplicationDocContentImpl().getHandlePost();
            clientImplHandler.setPayloadType(
                DigitaryApplicationDocContentPayload.PostRequest.class,
                DigitaryApplicationDocContentPayload.PostResponse.class
            );
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then: Clone Contact_Document__c record is created and the new ContentDocument is linked to the cloned Contact_Document__c
        List<Contact_Document__c> contactDocs = [
            SELECT Id, Filename__c
            FROM Contact_Document__c
            WHERE Issuer_Delivery_Id__c = :EXISTING_ISSUER_DELIVERY_ID
        ];
        Assert.areEqual(2, contactDocs.size(), 'Expected two Contact_Document__c records');

        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion2.Id].ContentDocumentId;
        List<ContentDocumentLink> cdlList = [
            SELECT Id, ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :contentDocumentId
        ];
        Assert.areNotEqual(1, cdlList.size(), 'Expected one ContentDocumentLink for the new ContentDocument');
        Assert.areNotEqual(existingContactDocument.Id, cdlList[0].LinkedEntityId, 'ContentDocument should be linked to the cloned Contact_Document__c');
    }
}