/**
 * @description Payload class for Digitary-specific Application Document Content
 * @author      Kai-Fan Hsieh
 * @since       29.07.2024
 */
public inherited sharing class DigitaryApplicationDocContentPayload {
    /**
     * @description request payload of (POST) ApplicationDocumentContentWS for Digitary
     */
    public virtual class PostRequest extends RESTlib_Payload.Request {
        /**
         * @description The original batch Id for the delivery. Can be used to create new document or when issuer update or revoke documents.
         */
        public String issuerDeliveryId { get; set; }
        /**
         * @description The original document Id in the delivery batch. Can be used to create new document or when issuer update or revoke documents.
         */
        public String issuerDocumentId { get; set; }
        /**
         * @description ContentVersion.Id
         */
        public Id contentVersionId { get; set; }
        /**
        * @description Document content type (e.g. application/pdf)
        */
        public String contentType { get; set; }
    }

    /**
     * @description response payload of (GET) ApplicationDocumentWS for Digitary
     */
    public virtual class PostResponse extends RESTlib_Payload.Response {}
}