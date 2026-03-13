/**
 * @description Test class for OffersDocuSignEnvelopExpiry
 */
@isTest(isParallel=true)
public class OffersDocuSignEnvelopExpiry_Test {

    @isTest
    static void shouldExpireOnValidData() {
        OffersDocuSignEnvelopExpiry envelopExpiry = 
        new OffersDocuSignEnvelopExpiry(
            new DocuSignUpdateEnvelopsRequestStub()
        );

        envelopExpiry.expire('23d956cc-3a5f-455b-8621-e8e62c838dfb');
        System.assert(true, 'Expected no errors with envelop id provided');
    }

    @isTest
    static void shouldThrowIllegalArgumentExceptionWhenEnvelopIdIsMissing() {

        OffersDocuSignEnvelopExpiry envelopExpiry = 
            new OffersDocuSignEnvelopExpiry(
                new DocuSignUpdateEnvelopsRequestStub()
            );
        
        try {
            envelopExpiry.expire('');
            System.assert(false, 'Expected exception due to blank envelop id');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected IllegalArgumentException');
        } catch (Exception e) {
            System.assert(false, 'Expected IllegalArgumentException');
        }
    }

    private class DocuSignUpdateEnvelopsRequestStub 
            implements DocuSignUpdateEnvelopsRequest {

        public void updateEnvelop(String accountId, String envelopId, 
                DocuSignUpdateEnvelopsReqBody requestBody) {
            System.debug('updated envelop');
        }

    }

}