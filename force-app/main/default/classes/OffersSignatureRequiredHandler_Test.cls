/**
 * @description Test class for OffersSignatureRequiredHandler
 */
@isTest(isParallel=true)
public class OffersSignatureRequiredHandler_Test {
    
    private static final String QUOTE_PUBLISHED_STATUS = 'Published';
    private static final String QUOTE_EXPIRED_STATUS = 'Expired';


    /**
     * @description Tests the positive scenario where the quote meets the conditions 
     * to be signed
     */
    @isTest
    static void shouldRequireSignature() {
        OffersDocuSignCreateSignReqContext context = new OffersDocuSignCreateSignReqContext();

        OffersSignatureRequiredHandler signRequiredHandler = new OffersSignatureRequiredHandler();
        signRequiredHandler.quotesSelector = 
            (QuotesSelector)Test.createStub(QuotesSelector.class, 
            new QuotesSelectorPublishedAcknowledgedStub());
        signRequiredHandler.nextHandler = new OffersDocuSignCreateSignatureHandlerStub();
        signRequiredHandler.handle(context);
        System.assertEquals(true, signRequiredHandler.isSignatureRequired, 
            'Expected true as Signature should be required for Published Status and Acknowledged');
    }


    @isTest
    static void shouldNotRequireSignatureAsNotAcknowledged() {
        OffersDocuSignCreateSignReqContext context = new OffersDocuSignCreateSignReqContext();

        OffersSignatureRequiredHandler signRequiredHandler = new OffersSignatureRequiredHandler();
        signRequiredHandler.quotesSelector = (QuotesSelector)Test.createStub(QuotesSelector.class, new QuotesSelectorPublishedNotAcknowledgedStub());
        signRequiredHandler.handle(context);
        System.assertEquals(false, signRequiredHandler.isSignatureRequired, 
            'Not expecting signature required as there is no acknowledgement');
    }


    @isTest
    static void shouldNotRequireSignatureAsStatusIsNotPublished() {
        OffersDocuSignCreateSignReqContext context = new OffersDocuSignCreateSignReqContext();

        OffersSignatureRequiredHandler signRequiredHandler = new OffersSignatureRequiredHandler();
        signRequiredHandler.quotesSelector = (QuotesSelector)Test.createStub(
            QuotesSelector.class, new QuotesSelectorExpiredAcknowledgedStub());
        signRequiredHandler.handle(context);
        System.assertEquals(false, signRequiredHandler.isSignatureRequired, 
            'Not expecting signature required as Status is Expired');
    }

    /**
     * @description Tests scenario where substatus is not populated
     */
    @isTest
    static void shouldNotRequireSignatureAsNotPublishedAndNotAcknowledged() {
        OffersDocuSignCreateSignReqContext context = new OffersDocuSignCreateSignReqContext();

        OffersSignatureRequiredHandler signRequiredHandler = new OffersSignatureRequiredHandler();
        signRequiredHandler.quotesSelector = (QuotesSelector)Test.createStub(
            QuotesSelector.class, new QuotesSelectorExpiredNotAcknowledgedStub());
        signRequiredHandler.handle(context);
        System.assertEquals(false, signRequiredHandler.isSignatureRequired, 
        'Not expecting signature required as not published and not acknowledged');
    }

    
    private class QuotesSelectorPublishedAcknowledgedStub implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, 
                List<String> listOfParamNames, List<Object> listOfArgs) {
            SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Status__c = QUOTE_PUBLISHED_STATUS, 
                Acknowledged_by_applicant__c = true
            );
            return new List<SBQQ__Quote__c>{quote};
        }
    }

    private class QuotesSelectorPublishedNotAcknowledgedStub implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, 
                List<String> listOfParamNames, List<Object> listOfArgs) {
            SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Status__c = QUOTE_PUBLISHED_STATUS, 
                Acknowledged_by_applicant__c = false
            );
            return new List<SBQQ__Quote__c>{quote};
        }
    }

    private class QuotesSelectorExpiredAcknowledgedStub implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, 
                List<String> listOfParamNames, List<Object> listOfArgs) {
            SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Status__c = QUOTE_EXPIRED_STATUS, 
                Acknowledged_by_applicant__c = true
            );
            return new List<SBQQ__Quote__c>{quote};
        }
    }

    private class QuotesSelectorExpiredNotAcknowledgedStub implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, 
                List<String> listOfParamNames, List<Object> listOfArgs) {
            SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Status__c = QUOTE_EXPIRED_STATUS, 
                Acknowledged_by_applicant__c = false
            );
            return new List<SBQQ__Quote__c>{quote};
        }
    }

}