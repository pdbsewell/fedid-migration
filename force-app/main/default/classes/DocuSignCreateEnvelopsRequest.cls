/**
 * @description Interface to interact with DocuSign to create
 * a DocuSign envelop.
 * @group DocuSign Create Envelop
 */
public interface DocuSignCreateEnvelopsRequest {

    /**
     * @description Method to invoke an action DocuSign to create an Envelop
     * @param accountId The DocuSign account Id
     * @param requestBody The request body payload to the sent to DocuSign
     * to create the envelop
     */
    void createEnvelop(String accountId, DocuSignCreateEnvelopsReqBody requestBody);
    
    /**
     * @description Returns the DocuSign envelop Id for the envelop created
     */
    String getEnvelopId();
}