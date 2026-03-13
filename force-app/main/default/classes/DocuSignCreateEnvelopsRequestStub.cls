/**
 * @description Stub for DocuSignCreateEnvelopsRequest for unit testing purposes
 * @group DocuSign Create Envelop
 */
@isTest(isParallel=true)
public class DocuSignCreateEnvelopsRequestStub implements DocuSignCreateEnvelopsRequest {

    @testVisible
    private String envelopId;

    public DocuSignCreateEnvelopsRequestStub() {
        this.envelopId = 'c8839145-c5c2-48b0-a00e-56e01384076c';
    }

    /**
     * @description Create Envelop method stub
     * Throws an IllegalArgumentException if accountId is blank
     * Does not perform any other action
     */
    public void createEnvelop(String accountId, DocuSignCreateEnvelopsReqBody requestBody) {
        if (String.isBlank(accountId)) {
            throw new IllegalArgumentException('Account Id and request body is required.');
        } else {
            System.debug('Executed DocuSignCreateEnvelopsRequestStub createEnvelop');
        }
    }

    public String getEnvelopId() {
        return this.envelopId;
    }
}