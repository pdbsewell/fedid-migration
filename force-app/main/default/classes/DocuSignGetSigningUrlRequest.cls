/**
 * @description Interface for Docusign Get Signing URL Request
 * @group DocuSign Signing URL
 */
public interface DocuSignGetSigningUrlRequest {

    /**
     * @description Returns the DocuSign signing URL
     * @param docuSignAccountId The DocuSign Account Id
     * @param envelopId The envelopId associated to the Signing request.
     * @param requestBody The request body of the request with the details
     * of the signing request
     */
    String getSigningUrl(String docuSignAccountId, String envelopId, DocuSignGetSigningUrlRequestBody requestBody);
    
}