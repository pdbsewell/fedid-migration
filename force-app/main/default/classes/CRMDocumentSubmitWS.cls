@RestResource(urlMapping='/v1/CRMDocumentSubmit/*')
/*******************************************************************************
 * @author       Shalini mendu
 * @date         18 June 2019
 * @description  Webservice exposed at CRM's end for Agent portal to call it with the required payload
 * @revision  23 Oct 2019 - SFTN-384-Documents are not getting sent from AP to CRM and not to Callista(Changing the request parameters
 * from record ID's to auto numbers for security reasons.)
 * 27 Jul 2023   Ken McGuire    SFTG-3360 Enhanced the request to accept Document Checklist IDs
 * 03 Aug 2023   Vinothraja     SFTG-3449 Added NetworkId while creating ContentVersion, as files will be uploaded by Portal user
 *******************************************************************************/
global without sharing class CRMDocumentSubmitWS {
    private static final String CONTENT_LOCATION_S = 'S';
    private static final String DOCUMENT_TYPE_OTHER = 'OTHERDCTYP';
    private static final String SHARE_TYPE_INFERRED = 'I';
    private static final String VISIBILITY_ALL_USERS = 'AllUsers';
    private static final String ERROR = 'Error';
    private static final String SUCCESS = 'Success';
    global static Id applicationId, contactId  = null;
    
    /**
     * @description Handles the HTTP POST request and performs the main operations of the web service.
     * @return ObdDocumentPayload.ObdDocumentPayloadResponse The final response status after performing all operations.
     */
    @HttpPost
    global  static ObdDocumentPayload.ObdDocumentPayloadResponse postMessage() {
        RestRequest request = RestContext.request;
        ObdDocumentPayload.ObdDocumentPayloadResponse resp = new ObdDocumentPayload.ObdDocumentPayloadResponse();
        ObdDocumentPayload.ObdDocumentPayloadRequest req;
        Id applicationId, contactId;

        try {
            req = (ObdDocumentPayload.ObdDocumentPayloadRequest) JSON.deserialize(request.requestBody.toString(), ObdDocumentPayload.ObdDocumentPayloadRequest.class);
            Application__c application = getApplication(req.applicationId);
            if (application == null) {
                return setResponseError(resp, 'Cannot find Application matching '+req.applicationId);
            }

            contactId = application.Applicant__c;
            if (contactId == null) {
                return setResponseError(resp, 'No applicant for Application matching ' + req.applicationId);
            }

            applicationId = application.Id;
            Id documentChecklistId = req.documentChecklistId;
            String documentType = req.documentType;
            ContentVersion cv = createContentVersion(req);
            ContentDocumentLink conDocLink = createContactDocumentLink(cv, req, applicationId, contactId, documentChecklistId,documentType);
            resp.status = SUCCESS;
            resp.error ='';
        }
        
        catch(Exception ee) {
            ExLog.add('CRMDocumentSubmitWS', 'CRM Document Submit WebService', 'CRMDocumentSubmitWS.postMessage', ee, applicationId);
            System.debug('CRMDocumentSubmitWS postMessage error for Application Id:'+applicationId+'::'+ee);
            resp.status = ERROR;
            resp.error = ee.getMessage();
        }
        
        return resp;
    }
    
    /**
     * @description Retrieves the application based on the provided applicationId.
     * @param applicationId The ID of the application to be retrieved.
     * @return Application__c The Application__c object if found, otherwise returns null.
     */
    private static Application__c getApplication(String applicationId) {
        List<Application__c> appList =[SELECT Id, Applicant__c FROM Application__c WHERE Name = :applicationId];
        return (appList.size() > 0) ? appList[0] : null;
    }
    
    /**
     * @description Sets the status and error message of the provided response object.
     * @param resp The response object to be updated.
     * @param message The error message to be set.
     * @return ObdDocumentPayload.ObdDocumentPayloadResponse The updated response object.
     */
    private static ObdDocumentPayload.ObdDocumentPayloadResponse setResponseError(ObdDocumentPayload.ObdDocumentPayloadResponse resp, String message) {
        resp.status = 'Error';
        resp.error = message;
        return resp;
    }

    /**
     * @description Creates a ContentVersion record based on the provided request data and returns it.
     * @param req The request containing data for creating the ContentVersion.
     * @return ContentVersion The created ContentVersion object.
     */
    private static ContentVersion createContentVersion(ObdDocumentPayload.ObdDocumentPayloadRequest req) {
        // SFTG-3449 Added Network Id
        // NetworkId mandatory when files are uploaded by a Portal user
        // Earlier class was invoked by MiX user, under Integration Profile
        Id networkId = [SELECT NetworkId, MemberId 
                        	FROM NetworkMember
                            WHERE MemberId = :UserInfo.getUserId() LIMIT 1]?.NetworkId;
        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = CONTENT_LOCATION_S;
        cv.VersionData = EncodingUtil.base64Decode(req.binaryString);
        cv.Title = req.fileName;
        cv.PathOnClient = req.fileName + '.' + req.fileName.substring(req.fileName.lastIndexOf('.'));
        cv.NetworkId = networkId;
        insert cv;
        return cv;
    }
    
    /**
     * @description Creates a Contact_Document__c record.
     * @param cv The ContentVersion object to be associated with the application, contact and document.
     * @param req The request containing data for creating the Contact_Document__c and ContentDocumentLink record.
     * @param applicationId The ID of the application to be linked to the document.
     * @param contactId The ID of the contact to be linked to the document.
     * @return ContentDocumentLink The created ContentDocumentLink object for the Contact_Document__c record.
     */
    private static ContentDocumentLink createContactDocumentLink(ContentVersion cv, ObdDocumentPayload.ObdDocumentPayloadRequest req, Id applicationId, Id contactId,Id documentChecklistId, string documentType) {
        Contact_Document__c conDoc = createContactDocument(req , applicationId, contactId, documentChecklistId,documentType);
        ContentVersion cvRes = [select ContentDocumentId from ContentVersion where Id= :cv.Id];
        ContentDocumentLink appLink = createLinkFile(cvRes.ContentDocumentId , contactId);
        ContentDocumentLink contactLink = createLinkFile(cvRes.ContentDocumentId , applicationId);
        ContentDocumentLink contactDocumentLink = createLinkFile(cvRes.ContentDocumentId , conDoc.Id);
        Database.insert(new List<ContentDocumentLink>{appLink, contactLink,contactDocumentLink } , false);

        Contact_Document__c retConDoc = [SELECT Submitted__c,Post_Submission__c FROM Contact_Document__c WHERE ID =:conDoc.Id];
        retConDoc.Submitted__c = true;
        retConDoc.Post_Submission__c = true;
        update retConDoc;

        return contactDocumentLink;
    }
    
    /**
     * @description Creates a Contact_Document__c record based on the provided request data.
     * @param req The request containing data for creating the Contact_Document__c.
     * @param applicationId The ID of the application to be associated with the document.
     * @param contactId The ID of the contact to be associated with the document.
     * @return Contact_Document__c The created Contact_Document__c object.
     */
    private static Contact_Document__c createContactDocument(ObdDocumentPayload.ObdDocumentPayloadRequest req, Id applicationId, Id contactId, Id documentChecklistId, String documentType) {
        Contact_Document__c conDoc = new Contact_Document__c();
        conDoc.Contact__c = contactId;
        conDoc.Document_Type__c = String.isEmpty(documentType) ?  DOCUMENT_TYPE_OTHER : documentType;
        conDoc.Document_Checklist__c = documentChecklistId;     
        conDoc.Comments__c = req.comments;
        conDoc.Filename__c = req.fileName;
        conDoc.Application__c = applicationId;
        conDoc.Internal_Only__c = false;
        insert conDoc;
        return conDoc;
    }

    /**
     * @description Creates a ContentDocumentLink record to associate the document with a related entity and returns it.
     * @param contentDocId The ID of the content document to be linked.
     * @param relatedId The ID of the related entity (either an application, contact, or Contact_Document__c record).
     * @return ContentDocumentLink The created ContentDocumentLink object.
     */
    private static ContentDocumentLink createLinkFile(Id contentDocId, Id relatedId) {
        ContentDocumentLink cdLink = new ContentDocumentLink();
        cdLink.ContentDocumentId = contentDocId;
        cdLink.LinkedEntityId = relatedId;
        cdLink.ShareType = SHARE_TYPE_INFERRED;
        cdLink.Visibility = VISIBILITY_ALL_USERS;
        return cdLink;
    }
}