/**
 * @description Payload class for Digitary-specific Application Documents
 * @author      Nick Guia
 * @since       MAY.20.2024
 * @revision    JUL.29.2024 - Kai-Fan Hsieh - Added the documents variable to PostRequest class
 */
public inherited sharing class DigitaryApplicationDocumentPayload {

    /**
     * @description request payload of (POST) ApplicationDocumentWS for Digitary
     */
    public virtual class PostRequest extends RESTlib_Payload.Request {
        /**
         * @description Can be found in the Digitary deliver metadata payload. Possible values are “Digitary Wallet” and “CSSD” at this stage
         */
        public String channel { get; set; }
        /**
         * @description The name of document owner
         */
        public String issuerDocumentOwnerName { get; set; }
        /**
         * @description The email address of document owner
         */
        public String issuerDocumentOwnerEmail { get; set; }
        /**
         * @description The ID for the issuer's delivery. Can be used to create new document or when issuer update or revoke documents.
         */
        public String issuerDeliveryId { get; set; }
        /**
         * @description List of documents associated with the request
         */
        public List<Document> documents { get; set; }
        /**
         * @description A collection of parameters associated with the request. MIX maps only to the parameters node,
         * providing flexibility since the key-value pairs within the child nodes may change later.
         * Consequently, there will be no transformation of the property names within the child nodes.
         * These names must remain consistent with the original payload from Digitary.
         */
        public Parameters parameters { get; set; }
    }

    /**
     * @description request payload of (PATCH) ApplicationDocumentWS for Digitary
     */
    public virtual class PatchRequest extends RESTlib_Payload.Request {
        /**
         * @description The ID for the issuer's delivery. Can be used to create new document or when issuer update or revoke documents.
         */
        public String issuerDeliveryId { get; set; }
        /**
         * @description List of documents associated with the request
         */
        public List<Document> documents { get; set; }
    }

    /**
     * @description Inner class representing individual documents in the request payload
     */
    public class Document {
        /**
         * @description The original document Id in the delivery batch. Can be used to create new document or when issuer update or revoke documents.
         */
        public String issuerDocumentId { get; set; }
        /**
         * @description Document issuer name. e.g. University of Sydney
         */
        public String issuerName { get; set; }
        /**
         * @description Issuer document type which can be different to the document type in Salesforce. e.g. Transcript
         */
        public String issuerDocumentType { get; set; }
        /**
         * @description Date the original document was created which may be different from the date it was created in Salesforce
         */
        public Date issuerDate { get; set; }
    }

    /**
      * @description A collection of parameters associated with the request. MIX maps only to the parameters node,
      * providing flexibility since the key-value pairs within the child nodes may change later.
      * Consequently, there will be no transformation of the property names within the child nodes.
      * These names must remain consistent with the original payload from Digitary.
      */
    public class Parameters {
        /**
         * @description this can be an Application.Name or a DocumentChecklist.Id.
         * The name must remain consistent with the original payload from Digitary so we ignore PMD.PropertyNamingConventions.
         */
        @SuppressWarnings('PMD.PropertyNamingConventions')
        public String monash_reference_id { get; set; }
    }


    /**
     * @description response payload of (POST) ApplicationDocumentWS for Digitary
     */
    public virtual class PostResponse extends RESTlib_Payload.Response {}

    /**
     * @description response payload of (PATCH) ApplicationDocumentWS for Digitary
     */
    public virtual class PatchResponse extends RESTlib_Payload.Response {}
}