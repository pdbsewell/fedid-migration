/**
 * @description Base Implementation for Application Documents.
 * Lift-and-shift from CRMDocumentSubmitWS
 * @author      Nick Guia
 * @since       MAY.20.2024
 */
public with sharing class BaseApplicationDocumentImpl implements RESTlib_IClientImpl {
    /**
     * @description should return the concrete handler class of the client implementation
     * @return `RESTlib_ClientImplHandler`
     */
    public RESTlib_ClientImplHandler getHandleGet() {
        return null; // Not implemented yet
    }
    /**
     * @description should return the concrete handler class of the client implementation
     * @return `RESTlib_ClientImplHandler`
     */
    public RESTlib_ClientImplHandler getHandlePost() {
        return new HandlePost();
    }
    /**
     * @description should return the concrete handler class of the client implementation
     * @return `RESTlib_ClientImplHandler`
     */
    public RESTlib_ClientImplHandler getHandlePut() {
        return null; // Not implemented yet
    }
    /**
     * @description should return the concrete handler class of the client implementation
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
    private virtual with sharing class HandlePost extends RESTlib_ClientImplHandler {
        /**
         * @description SFTG-3449 : NetworkId is mandatory when files are uploaded by a Portal user
         * Earlier class was invoked by MiX user, under Integration Profile
         */
        @TestVisible
        private Id networkId {
            get {
                if (networkId == null) {
                    networkId = [
                        SELECT NetworkId, MemberId
                        FROM NetworkMember
                        WHERE MemberId = :UserInfo.getUserId()
                        WITH SECURITY_ENFORCED
                        LIMIT 1
                    ]?.NetworkId;
                }
                return networkId;
            }
            set;
        }

        /**
         * @description This method constructs and returns a request payload for the custom REST API.
         * @return RESTlib_Payload.Request - The constructed request payload containing the custom parameters and binary content.
         */
        public virtual override RESTlib_Payload.Request getRequestPayload() {
            BaseApplicationDocumentPayload.PostRequest postRequest = new BaseApplicationDocumentPayload.PostRequest();
            // Note: When uploading files via a custom REST API, avoid mixing custom parameters and file binary content in the request body.
            // Reason: Apex has a 6MB heap size limitation, and mixing the above will require the use of RestContext.request.requestBody.ToString() during deserialization, which will fail.

            // Extract custom parameters from the request
            postRequest.fileName = RestContext.request.params.get('fileName');
            postRequest.documentType = RestContext.request.params.get('documentType');
            // MIX should send URL encoded comments and in apex it will be auto decoded.
            postRequest.comments = RestContext.request.params.get('comments');
            postRequest.documentChecklistId = RestContext.request.params.get('documentChecklistId');
            postRequest.applicationId = RestContext.request.params.get('applicationId');
            nebula.Logger.info('postRequest ' + postRequest);
            // Get the file content from the request body
            postRequest.binaryContent = RestContext.request.requestBody;
            nebula.Logger.info('postRequest.binaryContent.size ' + postRequest.binaryContent.size());
            return postRequest;
        }

        /**
         * @description set request type
         * @return `Type`
         */
        public override Type getRequestType() {
            return BaseApplicationDocumentPayload.PostRequest.class;
        }

        /**
         * @description set response type
         * @return `Type`
         */
        public override Type getResponseType() {
            return BaseApplicationDocumentPayload.PostResponse.class;
        }

        /**
         * @description  validation rules
         * @param reqObj
         * @throws RESTlib_Ex.InvalidRequestException
         */
        public override void validate(RESTlib_Payload.Request reqObj) {
            BaseApplicationDocumentPayload.PostRequest req = (BaseApplicationDocumentPayload.PostRequest) reqObj;
            /**
             * applicationId cannot be null
             */
            if (String.isBlank(req.applicationId)) {
                throw new RESTlib_Ex.InvalidRequestException('Application reference number cannot be null');
            }
        }

        /**
         * @description create a Content Document based on the payload request
         * @param reqObj      
         * @param responseObj 
         * @return `RESTlib_Payload.Response`
         * @throws RESTlib_Ex.InvalidRequestException
         */
        public override RESTlib_Payload.Response process(RESTlib_Payload.Request reqObj, RESTlib_Payload.Response responseObj) {
            BaseApplicationDocumentPayload.PostRequest req = (BaseApplicationDocumentPayload.PostRequest) reqObj;
            BaseApplicationDocumentPayload.PostResponse resp = (BaseApplicationDocumentPayload.PostResponse) responseObj;

            /**
             * STEP 1 : query the application record and throw an error if not found
             */
            Application__c appRecord;
            List<Application__c> applications = [SELECT Id, Applicant__c FROM Application__c WHERE Name = :req.applicationId WITH SECURITY_ENFORCED LIMIT 1];
            if (applications.isEmpty()) {
                throw new RESTlib_Ex.InvalidRequestException('Application Id does not exist');
            } else {
                appRecord = applications.get(0);
            }
            /**
             * STEP 2 : create a contact document
             */
            Contact_Document__c contactDoc = createContactDocument(req, appRecord);
            Database.insert(contactDoc, AccessLevel.USER_MODE);
            /**
             * STEP 3 : insert a content version and requery to pull the
             * generated contentDocumentId
             */
            ContentVersion contentVer = createContentVersion(req);
            Database.insert(contentVer, AccessLevel.USER_MODE);
            contentVer = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVer.Id WITH SECURITY_ENFORCED LIMIT 1];
            /**
             * STEP 4 : create the content document links for:
             * - Application
             * - Contact
             * - Contact Document
             */
            List<ContentDocumentLink> contentDocLinkList = new List<ContentDocumentLink>();
            ContentDocumentLink appCdLink = createContentDocumentLink(contentVer.ContentDocumentId, appRecord.Id);
            ContentDocumentLink conCdLink = createContentDocumentLink(contentVer.ContentDocumentId, appRecord.Applicant__c);
            ContentDocumentLink contactDocCdLink = createContentDocumentLink(contentVer.ContentDocumentId, contactDoc.Id);
            contentDocLinkList.add(appCdLink);
            contentDocLinkList.add(conCdLink);
            contentDocLinkList.add(contactDocCdLink);
            Database.insert(contentDocLinkList, AccessLevel.USER_MODE);
            Nebula.Logger.info('BaseApplicationDocumentImpl.HandlePost.process Request:'+req);

            /**
             * STEP 5: Update the contact document.
             * This update is necessary after insertion due to a circular reference issue.
             * The content document link requires the contact document to be created first.
             * Once `Submitted__c` and `Post_Submission__c` are updated, the process builder on the contact document will trigger.
             * It will then retrieve the document via the content document link and send it to Callista.
             * Note: `Submitted__c` and `Post_Submission__c` should be set before the content document link is created.
             */
            Contact_Document__c contactDocumentToUpdate = new Contact_Document__c(
                Id = contactDoc.Id,
                Submitted__c = true,
                Post_Submission__c = true);
            Database.update(contactDocumentToUpdate, AccessLevel.USER_MODE);
            Nebula.Logger.info('BaseApplicationDocumentImpl.HandlePost.process Response:'+resp);
            // framework updates the response status
            return resp;
        }

        /**
         * @description Creates a ContentVersion record based on the provided request data and returns it.
         * @param req   The request containing data for creating the ContentVersion.
         * @return `ContentVersion`
         */
        @TestVisible
        protected virtual ContentVersion createContentVersion(BaseApplicationDocumentPayload.PostRequest req) {
            ContentVersion cv = new ContentVersion();
            cv.ContentLocation = 'S';
            cv.VersionData = req.binaryContent;
            cv.Title = req.fileName;
            cv.PathOnClient = req.fileName + '.' + req.fileName.substring(req.fileName.lastIndexOf('.'));
            cv.NetworkId = this.networkId;
            return cv;
        }

        /**
         * @description     creates a contact document record for the application and applicant
         * @param req       Request payload
         * @param appRecord related application record
         * @return `Contact_Document__c`
         */
        @TestVisible
        protected virtual Contact_Document__c createContactDocument(BaseApplicationDocumentPayload.PostRequest req, Application__c appRecord) {
            Contact_Document__c contactDoc = new Contact_Document__c();
            contactDoc.Contact__c = appRecord.Applicant__c;
            contactDoc.Application__c = appRecord.Id;
            contactDoc.Document_Type__c = String.isBlank(req.documentType) ? 'OTHERDCTYP' : req.documentType;
            contactDoc.Document_Checklist__c = req.documentChecklistId;
            contactDoc.Comments__c = req.comments;
            contactDoc.Filename__c = req.fileName;
            contactDoc.Internal_Only__c = false;
            return contactDoc;
        }

        /**
         * @description create a content document link record
         * @param contentDocId content document Id
         * @param relatedId    the parent record id
         * @return `ContentDocumentLink`
         */
        @TestVisible
        protected virtual ContentDocumentLink createContentDocumentLink(Id contentDocId, Id relatedId) {
            ContentDocumentLink cdLink = new ContentDocumentLink();
            cdLink.ContentDocumentId = contentDocId;
            cdLink.LinkedEntityId = relatedId;
            cdLink.ShareType = 'I'; // inferred
            cdLink.Visibility = 'AllUsers';
            return cdLink;
        }
    }
}