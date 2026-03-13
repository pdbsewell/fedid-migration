/**
 * @description Interface for expiring the DocuSign Envelop
 * @group DocuSign
 */
public interface DocuSignEnvelopExpiry {

    /**
     * @description Expires the Envelop
     * @param envelopId The envelop Id for the envelop that should expire
     */
    void expire(String envelopId);
}