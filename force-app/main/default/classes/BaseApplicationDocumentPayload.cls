/**
 * @description Payload class for (generic) Base Application Documents
 * @author      Nick Guia
 * @since       MAY.20.2024
 */
public inherited sharing class BaseApplicationDocumentPayload {
    /**
     * @description Request payload for posting a new document to the base application.
     *              This includes details like application ID, document checklist ID,
     *              document type, file name, binary content, and any additional comments.
     * @author      Nick Guia
     * @since       MAY.20.2024
     */
    public virtual class PostRequest extends RESTlib_Payload.Request {
        /**
         * @description Application Name
         */
        public String applicationId {get; set;}
        /**
         * @description Document Checklist Id
         */
        public String documentChecklistId {get; set;}
        /**
         * @description Contact_Document__c.Document_Type__c
         */
        public String documentType {get; set;}
        /**
         * @description Contact_Document__c.Filename__c
         */
        public String fileName {get; set;}
        /**
         * @description ContentVersion.VersionData
         */
        public Blob binaryContent {get; set;}
        /**
         * @description Contact_Document__c.Comments__c
         */
        public String comments {get; set;}
    }

    /**
     * @description Response payload for posting a new document to the base application document implementation.
     *              This class serves as a placeholder for any future response fields or processing related to the document submission.
     * @author      Nick Guia
     * @since       MAY.20.2024
     */
    public virtual class PostResponse extends RESTlib_Payload.Response {
    }
}