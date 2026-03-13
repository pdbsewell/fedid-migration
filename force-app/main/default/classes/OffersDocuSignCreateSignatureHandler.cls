/**
 * @description Handler for implementing the DocuSign 
 * signing process
 * Implementation of the chain of responsibility pattern.
 * Offers DocuSign Signature
 */
public interface OffersDocuSignCreateSignatureHandler {

    /**
     * @description Handler method for handling requests
     */
    void handle(OffersDocuSignCreateSignReqContext context);
}