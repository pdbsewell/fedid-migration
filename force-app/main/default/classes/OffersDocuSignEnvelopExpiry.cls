/**
 * @description Expires DocuSign Envelops for Offers
 * @group Offer DocuSign Expiry
 */
public inherited sharing class OffersDocuSignEnvelopExpiry 
        implements DocuSignEnvelopExpiry {

    private DocuSignUpdateEnvelopsRequest docuSignUpdateEnvelopsRequest;

    /**
     * @description Constructor for setting dependencies
     * @param docuSignUpdateEnvelopsRequest Implementation of 
     * docuSignUpdateEnvelopsRequest used for updating the envelop
     */
    public OffersDocuSignEnvelopExpiry(
            DocuSignUpdateEnvelopsRequest docuSignUpdateEnvelopsRequest) {
        this.docuSignUpdateEnvelopsRequest = docuSignUpdateEnvelopsRequest;
    }
    
    /**
     * @description Expires the Envelop immediately by making the envelop void 
     * Throws an IllegalArgumentException if envelop Id is missing
     * @param envelopId The envelop Id for the envelop that should expire
     */
    public void expire(String envelopId){

        if (String.isBlank(envelopId)) {
            throw new IllegalArgumentException(
                'envelop Id is missing and is required for expire');
        }

        DocuSignAuthProviderSetting authSetting = new DocuSignAuthProviderSetting();
        String accountId = authSetting.getAccountId();

        DocuSignUpdateEnvelopsReqBody requestBody = new DocuSignUpdateEnvelopsReqBody();
        requestBody.status = 'voided';
        requestBody.voidedReason = 'Offer expired';

        this.docuSignUpdateEnvelopsRequest.updateEnvelop(accountId, envelopId, 
            requestBody);
    }
}