/**
 * @description Test class for OffersEnvelopSignedEventTrigHandler
 */
@isTest(isParallel=true)
public class OffersEnvelopSignedEventTrigHandler_Test {

    private static final String QUOTE_SIGNED_STATUS = 'Signed';

    private static final String ENVELOP_ID_IN_SYSTEM_1 = 'a664b924-ca3a-45ec-8b8a-41241cde87a1';
    private static final String ENVELOP_ID_IN_SYSTEM_2 = 'a664b924-ca3a-45ec-8b8a-41241cde87a2';

    @isTest
    static void shouldUpdateQuoteStatus() {
        SObjectDaoMock quoteDaoMock = new SObjectDaoMock();
        Offers_Envelop_Signed_Event__e signedEvent = new Offers_Envelop_Signed_Event__e();
        signedEvent.Envelop_Id__c = ENVELOP_ID_IN_SYSTEM_1;

        OffersEnvelopSignedEventTrigHandler handler = new OffersEnvelopSignedEventTrigHandler();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new SingleQuotesSelectorStub());
        handler.quoteDao = quoteDaoMock;
        handler.process(signedEvent);

        handler.execute();

        System.assertEquals(QUOTE_SIGNED_STATUS, 
            quoteDaoMock.recordsUpdated[0].get('SBQQ__Status__c'), 
            'Expected status to be updated to Signed.');
    }

    @isTest
    static void shouldUpdateTwoQuoteStatuses() {
        SObjectDaoMock quoteDaoMock = new SObjectDaoMock();
        Offers_Envelop_Signed_Event__e signedEvent1 = new Offers_Envelop_Signed_Event__e();
        signedEvent1.Envelop_Id__c = ENVELOP_ID_IN_SYSTEM_1;

        Offers_Envelop_Signed_Event__e signedEvent2 = new Offers_Envelop_Signed_Event__e();
        signedEvent2.Envelop_Id__c = ENVELOP_ID_IN_SYSTEM_2;

        OffersEnvelopSignedEventTrigHandler handler = new OffersEnvelopSignedEventTrigHandler();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new TwoQuotesSelectorStub());
        handler.quoteDao = quoteDaoMock;

        handler.process(signedEvent1);
        handler.process(signedEvent2);

        handler.execute();

        System.assertEquals(QUOTE_SIGNED_STATUS, 
            quoteDaoMock.recordsUpdated[0].get('SBQQ__Status__c'), 
            'Expected status to be updated to Signed.');
        System.assertEquals(QUOTE_SIGNED_STATUS, 
            quoteDaoMock.recordsUpdated[1].get('SBQQ__Status__c'), 
            'Expected status to be updated to Signed.');
    }

    private class SingleQuotesSelectorStub implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            // assumes method called is selectQuotesByPrimaryDocuSignEnvelopId
            SBQQ__Quote__c quote = new SBQQ__Quote__c(Sub_Status__c = 'Published');
            return new List<SBQQ__Quote__c>{quote};
        }
    }

    private class TwoQuotesSelectorStub implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            // assumes method called is selectQuotesByPrimaryDocuSignEnvelopId
            SBQQ__Quote__c quote1 = new SBQQ__Quote__c(Sub_Status__c = 'Published');
            SBQQ__Quote__c quote2 = new SBQQ__Quote__c(Sub_Status__c = 'Published');

            return new List<SBQQ__Quote__c>{quote1, quote2};
        }
    }

}