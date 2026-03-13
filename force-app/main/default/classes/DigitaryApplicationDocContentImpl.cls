/**
 * @description Implementation class for Digitary-specific Application Documents
 * @author      Nick Guia
 * @since       MAY.20.2024
 * @revision
 * 2024-09-20 - Kai-Fan Hsieh - Modified logic to accept ContentVersion ID in the request payload to overcome
 *              the file upload size issue related to the APEX 6MB heap size limit when converting base64 content to binary.
 *              A 5MB file roughly translates to 7MB of base64 content, which exceeds the APEX 6MB heap size limit.
 *              MIX will upload the file via the standard API first, then call this custom REST APEX.
 *              The standard SObject ContentVersion REST API does not have the 6MB heap size limit
 *              and can handle up to 50MB of base64 content, which is approximately equal to a 35MB file.
 */
public with sharing class DigitaryApplicationDocContentImpl implements RESTlib_IClientImpl {
    public static final String FILE_FORMAT = 'application/pdf';
    // Digitary error codes that are listed in their API specification v1.5
    // The delivery ID does not refer to an existing delivery
    public static final String DIGITARY_ERROR_CODE_INVALID_DELIVERY = 'invalid_delivery';
    // The document ID does not refer to a document included in the delivery
    public static final String DIGITARY_ERROR_CODE_INVALID_DOCUMENT = 'invalid_document';
    // The Content-Type header was something other than "application/pdf"
    public static final String DIGITARY_ERROR_CODE_INVALID_FILE_FORMAT = 'illegal_document_file_format';
    // The request body was blank
    public static final String DIGITARY_ERROR_CODE_INVALID_NO_BODY = 'no_body';
    public static ElevatedContentVersionSelector elevatedContentVersionSelector = new ElevatedContentVersionSelector();
    private static Contact_Document__c lastExistingContactDocument;
    private static List<Contact_Document__c> existingContactDocuments = new List<Contact_Document__c>();

    /**
     * @description Should return the concrete handler class of the client implementation
     * @return `RESTlib_ClientImplHandler`
     */
    public RESTlib_ClientImplHandler getHandleGet() {
        return null; // Not implemented yet
    }

    /**
     * @description Should return the concrete handler class of the client implementation
     * @return `RESTlib_ClientImplHandler`
     */
    public RESTlib_ClientImplHandler getHandlePost() {
        return new HandlePost();
    }

    /**
     * @description Should return the concrete handler class of the client implementation
     * @return `RESTlib_ClientImplHandler`
     */
    public RESTlib_ClientImplHandler getHandlePut() {
        return null; // Not implemented yet
    }

    /**
     * @description Should return the concrete handler class of the client implementation
     * @return `RESTlib_ClientImplHandler`
     */
    public RESTlib_ClientImplHandler getHandlePatch() {
        return null; // Not implemented yet
    }

    /**
     * @description Processes POST requests for uploading application documents,
     *              handling validation, storage, and record linking.
     * @author      Kai-Fan Hsieh
     * @since       08/08/2024
     */
    public with sharing virtual class HandlePost extends RESTlib_ClientImplHandler {
        private final Utils utils = new Utils();

        /**
         * @description Set request type
         * @return `Type`
         */
        public override Type getRequestType() {
            return DigitaryApplicationDocContentPayload.PostRequest.class;
        }

        /**
         * @description Set response type
         * @return `Type`
         */
        public override Type getResponseType() {
            return DigitaryApplicationDocContentPayload.PostResponse.class;
        }

        /**
         * @description Validation rules
         * @param reqObj Request
         * @throws RESTlib_Ex.InvalidRequestException Custom exception
         */
        public override void validate(RESTlib_Payload.Request reqObj) {
            DigitaryApplicationDocContentPayload.PostRequest req = (DigitaryApplicationDocContentPayload.PostRequest) reqObj;
            nebula.Logger.finest('postRequest details').setRestRequestDetails(RestContext.request).addTag(RestContext.request.requestURI);

            // Check if content type is supported
            if (FILE_FORMAT != req.contentType) {
                utils.logErrorWithRequestAndDelete('The content type is invalid', req.contentVersionId);
                throw new RESTlib_Ex.InvalidRequestException(DIGITARY_ERROR_CODE_INVALID_FILE_FORMAT);
            }

            if (String.isBlank(req.contentVersionId)) {
                utils.logErrorWithRequest('The contentVersionId cannot be blank');
                throw new RESTlib_Ex.InvalidRequestException(DIGITARY_ERROR_CODE_INVALID_NO_BODY);
            }

            // Check if ContentVersion exists with the given contentVersionId
            List<ContentVersion> contentVersions = elevatedContentVersionSelector.selectById(req.contentVersionId);
            if (contentVersions.isEmpty()) {
                utils.logErrorWithRequest('No ContentVersion found with provided contentVersionId');
                throw new RESTlib_Ex.InvalidRequestException(DIGITARY_ERROR_CODE_INVALID_NO_BODY);
            }

            if (String.isBlank(req.issuerDeliveryId)) {
                utils.logErrorWithRequestAndDelete('The delivery ID cannot be blank', req.contentVersionId);
                throw new RESTlib_Ex.InvalidRequestException(DIGITARY_ERROR_CODE_INVALID_DELIVERY);
            }

            if (String.isBlank(req.issuerDocumentId)) {
                utils.logErrorWithRequestAndDelete('The document ID cannot be blank', req.contentVersionId);
                throw new RESTlib_Ex.InvalidRequestException(DIGITARY_ERROR_CODE_INVALID_DOCUMENT);
            }

            List<Contact_Document__c> contactDocuments = new ElevatedContactDocumentSelector().selectByIssuerDeliveryId(req.issuerDeliveryId);
            if (contactDocuments.isEmpty()) {
                utils.logErrorWithRequestAndDelete('The delivery ID does not refer to an existing delivery', req.contentVersionId);
                throw new RESTlib_Ex.InvalidRequestException(DIGITARY_ERROR_CODE_INVALID_DELIVERY);
            }

            // Search for existing contact documents with same delivery Id and document Id.
            // There could be more than one match as Digitary documents can have multiple versions
            for (Contact_Document__c contactDocument : contactDocuments) {
                if (req.issuerDocumentId != null && contactDocument.Issuer_Document_Id__c == req.issuerDocumentId) {
                    lastExistingContactDocument = contactDocument;
                    existingContactDocuments.add(contactDocument);
                }
            }
            utils.contactDocumentId = lastExistingContactDocument?.Id;
            nebula.Logger.finest('existingContactDocument.Id ' + lastExistingContactDocument?.Id).addTag(RestContext.request.requestURI);

            if (lastExistingContactDocument == null) {
                utils.logErrorWithRequestAndDelete('The document ID does not refer to a document included in the delivery', req.contentVersionId);
                throw new RESTlib_Ex.InvalidRequestException(DIGITARY_ERROR_CODE_INVALID_DOCUMENT);
            }

            // Check if ContentDocument is already linked to a Contact_Document__c
            Id contentDocumentId = contentVersions.get(0).ContentDocumentId;
            List<ContentDocumentLink> existingLinks =
                new ElevatedContentDocumentLinkSelector().selectByLinkedEntityIdContentDocumentIds(
                    new Map<Id, Contact_Document__c>(existingContactDocuments).keySet(), contentDocumentId);
            if (!existingLinks.isEmpty()) {
                utils.logErrorWithRequest('The ContentDocument is already linked to a Contact Document');
                throw new RESTlib_Ex.InvalidRequestException(DIGITARY_ERROR_CODE_INVALID_DOCUMENT);
            }
        }

        /**
         * @description Creates a Content Document based on the payload request
         * @param reqObj Request
         * @param responseObj Response
         * @return `RESTlib_Payload.Response`
         * @throws RESTlib_Ex.InvalidRequestException Custom exception
         */
        public virtual override RESTlib_Payload.Response process(RESTlib_Payload.Request reqObj, RESTlib_Payload.Response responseObj) {
            nebula.Logger.finest('process').setRestRequestDetails(RestContext.request).addTag(RestContext.request.requestURI);
            DigitaryApplicationDocContentPayload.PostRequest req = (DigitaryApplicationDocContentPayload.PostRequest) reqObj;
            DigitaryApplicationDocContentPayload.PostResponse resp = (DigitaryApplicationDocContentPayload.PostResponse) responseObj;
            ElevatedDAO elevatedDAO = new ElevatedDAO();
            /**
             * STEP 1:
             *  - If an existing content document is found, the file will be uploaded as a new version of that content document.
             *  - If no existing content document is found, the file will be uploaded as the first version, and a new content document will be created.
             *  - Insert the content version.
             *  - Publish a platform event to trigger a listener in the My.App LWC, allowing it to refresh the file cards.
             */
            ContentVersion contentVer = elevatedContentVersionSelector.selectById(req.contentVersionId).get(0);

            // Check if Contact_Document__c already has ContentDocumentLink to see if first version is already uploaded
            Boolean contactDocumentHasLink = false;
            List<ContentDocumentLink> contactDocLinks = new ElevatedContentDocumentLinkSelector().selectByLinkedEntityId(lastExistingContactDocument.Id);
            if (!contactDocLinks.isEmpty()) {
                contactDocumentHasLink = true;
            }

            if (contactDocumentHasLink) {
                // Clone the Contact_Document__c record
                Contact_Document__c clonedContactDocument = new Contact_Document__c(
                    Contact__c = lastExistingContactDocument.Contact__c,
                    Application__c = lastExistingContactDocument.Application__c,
                    Document_Type__c = lastExistingContactDocument.Document_Type__c,
                    Document_Checklist__c = lastExistingContactDocument.Document_Checklist__c,
                    Internal_Only__c = false,
                    Channel__c = lastExistingContactDocument.Channel__c,
                    Issuer_Delivery_Id__c = req.issuerDeliveryId,
                    Issuer_Name__c = lastExistingContactDocument.Issuer_Name__c,
                    Issuer_Document_Type__c = lastExistingContactDocument.Issuer_Document_Type__c,
                    Inception_Date__c = lastExistingContactDocument.Inception_Date__c,
                    Issuer_Document_Id__c = lastExistingContactDocument.Issuer_Document_Id__c,
                    Issuer_Document_Owner_Name__c = lastExistingContactDocument.Issuer_Document_Owner_Name__c,
                    Issuer_Document_Owner_Email__c = lastExistingContactDocument.Issuer_Document_Owner_Email__c,
                    Document_Owner_Mismatch__c = lastExistingContactDocument.Document_Owner_Mismatch__c,
                    Verified__c = true);
                if (lastExistingContactDocument.Submitted__c == true) {
                    clonedContactDocument.Submitted__c = true;
                    clonedContactDocument.Post_Submission__c = true;
                }
                // Insert the cloned record
                elevatedDAO.insertRecord(clonedContactDocument);
                new DigitaryApplicationDocumentImpl.Utils().updateFilenames(new List<Contact_Document__c>{clonedContactDocument});
                lastExistingContactDocument = clonedContactDocument;
                utils.contactDocumentId = clonedContactDocument.Id;
            }

            // Proceed to link the ContentDocument to the (possibly cloned) Contact_Document__c
            // Update the ContentVersion title to match the (possibly new) filename
            contentVer.Title = lastExistingContactDocument.Filename__c;
            update contentVer;

            /**
             * STEP 2 : create the content document links for:
             * - Application
             * - Contact
             * - Contact Document
             */
            List<ContentDocumentLink> contentDocLinkList = new List<ContentDocumentLink>();
            ContentDocumentLink appCdLink = createContentDocumentLink(contentVer, lastExistingContactDocument.Application__c, lastExistingContactDocument);
            ContentDocumentLink conCdLink = createContentDocumentLink(contentVer, lastExistingContactDocument.Contact__c, lastExistingContactDocument);
            ContentDocumentLink contactDocCdLink = createContentDocumentLink(contentVer, lastExistingContactDocument.Id, lastExistingContactDocument);
            contentDocLinkList.add(appCdLink);
            contentDocLinkList.add(conCdLink);
            contentDocLinkList.add(contactDocCdLink);
            elevatedDAO.insertRecords(contentDocLinkList);

            /**
            * STEP 3: Update the contact document.
            * This update is necessary after insertion due to a circular reference issue.
            * The content document link requires the contact document to be created first.
            * Once `Submitted__c` and `Post_Submission__c` are updated, the process builder on the contact document will trigger.
            * It will then retrieve the document via the content document link and send it to Callista.
            * Note: `Submitted__c` and `Post_Submission__c` should be set before the content document link is created.
            */
            // Update the contact document if application status is 'Submitted' or 'Sent for Submission'
            if (lastExistingContactDocument.Application__r.Status__c == 'Submitted' ||
                lastExistingContactDocument.Application__r.Status__c == 'Sent for Submission') {
                Contact_Document__c contactDocumentToUpdate = new Contact_Document__c(
                    Id = lastExistingContactDocument.Id,
                    Submitted__c = true,
                    Post_Submission__c = true);
                elevatedDAO.updateRecord(contactDocumentToUpdate);
            }

            // Update document checklist item status
            if (lastExistingContactDocument.Document_Checklist__c != null &&
                (lastExistingContactDocument.Document_Checklist__r.Status__c == AssessmentServicesConstants.APP_CHECKLIST_STATUS_REQUESTED ||
                 lastExistingContactDocument.Document_Checklist__r.Status__c == AssessmentServicesConstants.APP_CHECKLIST_STATUS_INSUFFICIENT)) {
                Document_Checklist__c documentChecklistToUpdate = new Document_Checklist__c(
                    Id = lastExistingContactDocument.Document_Checklist__c,
                    Status__c = AssessmentServicesConstants.APP_CHECKLIST_STATUS_SUBMITTED);
                elevatedDAO.updateRecord(documentChecklistToUpdate);
            }

            // Update Application__c.Last_Verified_Document_Received_Date__c so email notification can be sent out by flow
            if (lastExistingContactDocument.Document_Owner_Mismatch__c == false) {
                Application__c applicationTpUpdate = new Application__c(
                    Id = lastExistingContactDocument.Application__c,
                    Last_Verified_Document_Received_Date__c = System.now()
                );
                elevatedDAO.updateRecord(applicationTpUpdate);
            }

            // Framework updates the response status
            return resp;
        }

        /**
         * @description Creates a ContentDocumentLink record
         * @param contentVersion ContentVersion record
         * @param relatedId The parent record Id
         * @param contactDocument The Contact_Document__c record
         * @return `ContentDocumentLink`
         */
        protected virtual ContentDocumentLink createContentDocumentLink(ContentVersion contentVersion, Id relatedId, Contact_Document__c contactDocument) {
            if (Schema.SObjectType.ContentDocumentLink.isCreateable()) {
                return new ContentDocumentLink(
                    ContentDocumentId = contentVersion.ContentDocumentId,
                    LinkedEntityId = relatedId,
                    ShareType = 'I', // inferred
                    Visibility = contactDocument.Document_Owner_Mismatch__c ? 'InternalUsers' : 'AllUsers'
                );
            } else {
                throw new DmlException('Operation failed due to object being inaccessible on SObject ContentDocumentLink');
            }
        }
    }

    /**
     * @description Classes for elevated access selectors utilizing DynamicSoqlBuilder for ContentVersion SObject queries without sharing enforcement.
     */
    private without sharing class ElevatedContentVersionSelector {
        private final DynamicSoqlBuilder soqlBuilder;
        private final Set<String> contentVersionFields = new Set<String>{
            'ContentDocumentId'
        };

        /**
         * @description Constructor. Initializes soql builder to not enforce security (given this is for elevated access) and not validate fields
         *              given that fields are static.
         */
        public ElevatedContentVersionSelector() {
            this.soqlBuilder = DynamicSoqlBuilder.getInstance()
                .setEnforced(false) // Do not enforce sharing for elevated access
                .validateFields(false); // No need to validate fields, they are static
        }

        /**
         * @description Query ContentVersion record
         * @param contentVersionId Id of the ContentVersion
         * @return `List<ContentVersion>`
         */
        public List<ContentVersion> selectById(String contentVersionId) {
            String whereClause = 'Id = :contentVersionId';
            String soqlStr = this.soqlBuilder.querySObject('ContentVersion')
                .queryFields(contentVersionFields)
                .getQuery(whereClause);
            return Database.query(soqlStr);
        }
    }

    /**
     * @description Classes for elevated access selectors utilizing DynamicSoqlBuilder
     *              for Contact_Document__c SObject queries without sharing enforcement.
     */
    private without sharing class ElevatedContactDocumentSelector {
        private final DynamicSoqlBuilder soqlBuilder;
        private final Set<String> contactDocumentFields = new Set<String>{
            'Id',
            'Issuer_Delivery_Id__c',
            'Issuer_Document_Id__c',
            'Issuer_Name__c',
            'Issuer_Document_Type__c',
            'Inception_Date__c',
            'Issuer_Document_Owner_Name__c',
            'Issuer_Document_Owner_Email__c',
            'Application__c',
            'Application__r.Status__c',
            'Document_Checklist__c',
            'Document_Checklist__r.Status__c',
            'Filename__c',
            'Contact__c',
            'Document_Owner_Mismatch__c',
            'Document_Type__c',
            'Document_Checklist__c',
            'Internal_Only__c',
            'Channel__c',
            'Verified__c',
            'Submitted__c'
        };

        /**
         * @description constructor. Initialises soql builder to not enforce security (given this is for elevated access)
         * and not have to validate fields given that fields will be static.
         */
        public ElevatedContactDocumentSelector() {
            this.soqlBuilder = DynamicSoqlBuilder.getInstance()
                .setEnforced(false) // Do not enforce sharing for elevated access
                .validateFields(false); // No need to validate fields, they are static
        }

        /**
         * @description query ContentVersion record
         * @param issuerDeliveryId : issuer delivery id
         * @return `List<Contact_Document__c>`
         */
        public List<Contact_Document__c> selectByIssuerDeliveryId(String issuerDeliveryId) {
            String whereClause =
                'Issuer_Delivery_Id__c = :issuerDeliveryId AND Issuer_Delivery_Id__c != NULL ORDER BY CreatedDate';
            String soqlStr = this.soqlBuilder.querySObject('Contact_Document__c')
                .queryFields(contactDocumentFields)
                .getQuery(whereClause);

            return Database.query(soqlStr);
        }
    }

    /**
     * @description Classes for elevated access selectors utilizing DynamicSoqlBuilder for Contact Document SObject queries without sharing enforcement.
     */
    private without sharing class ElevatedContentDocumentLinkSelector {
        private final DynamicSoqlBuilder soqlBuilder;
        private final Set<String> contentDocumentLinkFields = new Set<String>{
            'Id',
            'ContentDocumentId'
        };

        /**
         * @description Constructor. Initializes soql builder to not enforce security
         *              (given this is for elevated access) and not validate fields
         *              given that fields are static.
         */
        public ElevatedContentDocumentLinkSelector() {
            this.soqlBuilder = DynamicSoqlBuilder.getInstance()
                .setEnforced(false) // Do not enforce sharing for elevated access
                .validateFields(false); // No need to validate fields, they are static
        }

        /**
         * @description Query ContentDocumentLink records
         * @param linkedEntityId Linked entity Id
         * @return `List<ContentDocumentLink>`
         */
        public List<ContentDocumentLink> selectByLinkedEntityId(Id linkedEntityId) {
            String whereClause = 'LinkedEntityId = :linkedEntityId';
            String soqlStr = this.soqlBuilder.querySObject('ContentDocumentLink')
                .queryFields(contentDocumentLinkFields)
                .getQuery(whereClause);
            return Database.query(soqlStr);
        }

        /**
         * @description Query ContentDocumentLink records
         * @param linkedEntityId Linked entity Id
         * @param contentDocumentId Content document Id
         * @return `List<ContentDocumentLink>`
         */
        public List<ContentDocumentLink> selectByLinkedEntityIdContentDocumentIds(Set<Id> linkedEntityIds, Id contentDocumentId) {
            String whereClause = 'LinkedEntityId IN :linkedEntityIds AND ContentDocumentId = :contentDocumentId';
            String soqlStr = this.soqlBuilder.querySObject('ContentDocumentLink')
                .queryFields(contentDocumentLinkFields)
                .getQuery(whereClause);
            return Database.query(soqlStr);
        }
    }

    /**
     * @description Classes for helper methods.
     */
    private with sharing class Utils {
        /**
         * @description contact document Id that is going to be linked to the log
         */
        public Id contactDocumentId;

        /**
        * @description  log error with request
        * @param message error message
        */
        private void logErrorWithRequest(String message) {
            nebula.Logger.error(message).setRestRequestDetails(RestContext.request).addTag(RestContext.request.requestURI).setRecord(contactDocumentId);
        }

        /**
         * @description Log error with request details and delete associated ContentDocument.
         * @param message Error message.
         * @param contentVersionId ContentVersionId to delete the associated ContentDocument.
         */
        private void logErrorWithRequestAndDelete(String message, String contentVersionId) {
            nebula.Logger.error(message).setRestRequestDetails(RestContext.request).addTag(RestContext.request.requestURI).setRecord(contactDocumentId);
            deleteContentDocument(contentVersionId);
        }

        /**
         * @description Deletes the ContentDocument associated with the given ContentVersionId.
         * @param contentVersionId The ID of the ContentVersion whose ContentDocument
         *                         needs to be deleted.
         */
        private void deleteContentDocument(String contentVersionId) {
            if (String.isNotBlank(contentVersionId)) {
                List<ContentVersion> contentVersions = [
                    SELECT ContentDocumentId
                    FROM ContentVersion
                    WHERE Id = :contentVersionId
                ];
                if (!contentVersions.isEmpty()) {
                    Id contentDocumentId = contentVersions[0].ContentDocumentId;
                    ContentDocument contentDoc = [
                        SELECT Id
                        FROM ContentDocument
                        WHERE Id = :contentDocumentId
                    ];
                    // Perform deletion without ElevatedDAO
                    delete contentDoc;
                    nebula.Logger.info('Deleted ContentDocument with Id: ' +
                        contentDocumentId);
                }
            }
        }
    }
}