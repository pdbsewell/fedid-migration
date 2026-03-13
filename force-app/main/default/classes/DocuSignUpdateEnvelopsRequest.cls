/**
 * @description Interface to interact with DocuSign to update
 * a DocuSign envelop.
 * @group DocuSign Update Envelop
 */
public interface DocuSignUpdateEnvelopsRequest {

    /**
     * @description Update DocuSign Envelop
     * @param accountId The DocuSign accountId
     * @param envelopId The envelop id for the envelop to be updated
     * @param requestBody Request Body for the envelop to be updated to
     */
    void updateEnvelop(String accountId, String envelopId, 
        DocuSignUpdateEnvelopsReqBody requestBody);

}