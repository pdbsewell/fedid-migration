/**
 * @description Test class for QuoteSigningUrlGenerationQueueable
 */
@isTest(isParallel=true)
public class QuoteSigningUrlGenerationQueueable_Test {

    @isTest
    static void shouldUpdateQuoteStatusWhenGetSigningUrlReqFailed() {

        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        SBQQ.TriggerControl.disable();

        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        insert quote;
        
        Test.startTest();
        QuoteSigningUrlGenerationQueueable signingUrlGenerationQueueable = 
            new QuoteSigningUrlGenerationQueueable(
                quote.Id, 
                new RequestFailedHandlerStub(),
                new SObjectDao(),
                new QuotesSelector()
            );
        System.enqueueJob(signingUrlGenerationQueueable);
        
        Test.stopTest();

        String status = [SELECT Sub_Status__c FROM SBQQ__Quote__c 
            WHERE Id = :quote.Id].Sub_Status__c;
        System.assert('DocuSign error'.equalsIgnoreCase(status), 
            'Expected sub status to be updated when error occurs');
    }

    private class RequestFailedHandlerStub 
            implements OffersDocuSignCreateSignatureHandler {

        public void handle(OffersDocuSignCreateSignReqContext context) {
            throw new DocuSignGetSignUrlReqFailException();
        }
    }

}