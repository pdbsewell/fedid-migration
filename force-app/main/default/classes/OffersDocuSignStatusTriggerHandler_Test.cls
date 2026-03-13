/**
 * @description Test class for OffersDocuSignStatusTriggerHandler
 */
@isTest(isParallel=true)
public class OffersDocuSignStatusTriggerHandler_Test {

    private static final String DOCUSIGN_RECIPIENT_COMPLETED_STATUS = 'Completed';

    private static final String ENVELOP_ID_IN_SYSTEM_1 = 'a664b924-ca3a-45ec-8b8a-41241cde87a1';
    private static final String ENVELOP_ID_IN_SYSTEM_2 = 'a664b924-ca3a-45ec-8b8a-41241cde87a2';

    @isTest
    static void shouldNotCreateNotificationWhenEnvelopIsNotSigned() {
        
        dsfs__DocuSign_Status__c envelopStatus = new dsfs__DocuSign_Status__c();
        envelopStatus.dsfs__Envelope_Status__c = 'sent';
        envelopStatus.dsfs__DocuSign_Envelope_ID__c = ENVELOP_ID_IN_SYSTEM_1;


        OffersDocuSignStatusTriggerHandler handler = new OffersDocuSignStatusTriggerHandler();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new QuotesSelectorStub());
        handler.process(envelopStatus);

        handler.execute();

        // platform events consume dml statements, using this to infer if 
        // the platform event has been created
        System.assertEquals(0, Limits.getDMLStatements(), 
            'Expected no platform event to be created as it did not meet condition');
    }

    @isTest
    static void shouldNotCreateNotificationWhenEnvelopIsSignedButNotInSystem() {
        
        dsfs__DocuSign_Status__c envelopStatus = new dsfs__DocuSign_Status__c();
        envelopStatus.dsfs__Envelope_Status__c = DOCUSIGN_RECIPIENT_COMPLETED_STATUS;
        envelopStatus.dsfs__DocuSign_Envelope_ID__c = 'DNE';

        OffersDocuSignStatusTriggerHandler handler = new OffersDocuSignStatusTriggerHandler();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new QuotesSelectorStub());
        handler.process(envelopStatus);

        handler.execute();

        // platform events consume dml statements, using this to infer if 
        // the platform event has been created
        System.assertEquals(0, Limits.getDMLStatements(), 
            'Expected no platform event to be created as it did not meet condition');
    }

    @isTest
    static void shouldNotCreateNotificationWhenEnvelopIsSignedAndNotInSystem() {
        
        dsfs__DocuSign_Status__c envelopStatus = new dsfs__DocuSign_Status__c();
        envelopStatus.dsfs__Envelope_Status__c = 'sent';
        envelopStatus.dsfs__DocuSign_Envelope_ID__c = 'DNE';

        OffersDocuSignStatusTriggerHandler handler = new OffersDocuSignStatusTriggerHandler();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new QuotesSelectorStub());
        handler.process(envelopStatus);

        handler.execute();

        // platform events consume dml statements, using this to infer if 
        // the platform event has been created
        System.assertEquals(0, Limits.getDMLStatements(), 
            'Expected no platform event to be created as it did not meet condition');
    }

    @isTest
    static void shouldNotCreateNotificationWhenTwoEnvelopsIsNotSigned() {
        
        dsfs__DocuSign_Status__c envelop1Status = new dsfs__DocuSign_Status__c();
        envelop1Status.dsfs__Envelope_Status__c = 'sent';
        envelop1Status.dsfs__DocuSign_Envelope_ID__c = ENVELOP_ID_IN_SYSTEM_1;

        dsfs__DocuSign_Status__c envelop2Status = new dsfs__DocuSign_Status__c();
        envelop2Status.dsfs__Envelope_Status__c = 'sent';
        envelop2Status.dsfs__DocuSign_Envelope_ID__c = ENVELOP_ID_IN_SYSTEM_2;


        OffersDocuSignStatusTriggerHandler handler = new OffersDocuSignStatusTriggerHandler();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new QuotesSelectorStub());
        handler.process(envelop1Status);
        handler.process(envelop2Status);

        handler.execute();

        // platform events consume dml statements, using this to infer if 
        // the platform event has been created
        System.assertEquals(0, Limits.getDMLStatements(), 
            'Expected no platform event to be created as it did not meet condition');
    }

    @isTest
    static void shouldNotCreateNotificationWhenTwoEnvelopsIsSignedButNotInSystem() {
        
        dsfs__DocuSign_Status__c envelop1Status = new dsfs__DocuSign_Status__c();
        envelop1Status.dsfs__Envelope_Status__c = DOCUSIGN_RECIPIENT_COMPLETED_STATUS;
        envelop1Status.dsfs__DocuSign_Envelope_ID__c = 'DNE1';

        dsfs__DocuSign_Status__c envelop2Status = new dsfs__DocuSign_Status__c();
        envelop2Status.dsfs__Envelope_Status__c = DOCUSIGN_RECIPIENT_COMPLETED_STATUS;
        envelop2Status.dsfs__DocuSign_Envelope_ID__c = 'DNE2';


        OffersDocuSignStatusTriggerHandler handler = new OffersDocuSignStatusTriggerHandler();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new QuotesSelectorStub());
        handler.process(envelop1Status);
        handler.process(envelop2Status);

        handler.execute();

        // platform events consume dml statements, using this to infer if 
        // the platform event has been created
        System.assertEquals(0, Limits.getDMLStatements(), 
            'Expected no platform event to be created as it did not meet condition');
    }

    @isTest
    static void shouldCreateNotificationWhenEnvelopIsSignedAndExistsInSystem() {
        
        dsfs__DocuSign_Status__c envelopStatus = new dsfs__DocuSign_Status__c();
        envelopStatus.dsfs__Envelope_Status__c = DOCUSIGN_RECIPIENT_COMPLETED_STATUS;
        envelopStatus.dsfs__DocuSign_Envelope_ID__c = ENVELOP_ID_IN_SYSTEM_1;

        OffersDocuSignStatusTriggerHandler handler = new OffersDocuSignStatusTriggerHandler();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new QuotesSelectorStub());
        handler.process(envelopStatus);

        handler.execute();

        // platform events consume dml statements, using this to infer if 
        // the platform event has been created
        System.assertEquals(1, Limits.getDMLStatements(), 
            'Expected 1 platform event to be created as it did meet condition');
    }

    @isTest
    static void shouldCreateNotificationWhenTwoEnvelopIsSignedAndExistsInSystem() {
        
        dsfs__DocuSign_Status__c envelop1Status = new dsfs__DocuSign_Status__c();
        envelop1Status.dsfs__Envelope_Status__c = DOCUSIGN_RECIPIENT_COMPLETED_STATUS;
        envelop1Status.dsfs__DocuSign_Envelope_ID__c = ENVELOP_ID_IN_SYSTEM_1;

        dsfs__DocuSign_Status__c envelop2Status = new dsfs__DocuSign_Status__c();
        envelop2Status.dsfs__Envelope_Status__c = DOCUSIGN_RECIPIENT_COMPLETED_STATUS;
        envelop2Status.dsfs__DocuSign_Envelope_ID__c = ENVELOP_ID_IN_SYSTEM_2;

        OffersDocuSignStatusTriggerHandler handler = new OffersDocuSignStatusTriggerHandler();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new QuotesSelectorStub());
        handler.process(envelop1Status);
        handler.process(envelop2Status);

        handler.execute();

        // platform events consume dml statements, using this to infer if 
        // the platform event has been created
        System.assertEquals(2, Limits.getDMLRows(), 
            'Expected 2 platform event rows to be created as it did meet condition');
    }

    @isTest
    static void shouldCreateNotificationWhenOneEnvelopOfTwoIsSignedAndExistsInSystem() {
        
        dsfs__DocuSign_Status__c envelop1Status = new dsfs__DocuSign_Status__c();
        envelop1Status.dsfs__Envelope_Status__c = DOCUSIGN_RECIPIENT_COMPLETED_STATUS;
        envelop1Status.dsfs__DocuSign_Envelope_ID__c = ENVELOP_ID_IN_SYSTEM_1;

        dsfs__DocuSign_Status__c envelop2Status = new dsfs__DocuSign_Status__c();
        envelop2Status.dsfs__Envelope_Status__c = 'sent';
        envelop2Status.dsfs__DocuSign_Envelope_ID__c = ENVELOP_ID_IN_SYSTEM_2;

        OffersDocuSignStatusTriggerHandler handler = new OffersDocuSignStatusTriggerHandler();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new QuotesSelectorStub());
        handler.process(envelop1Status);
        handler.process(envelop2Status);

        handler.execute();

        // platform events consume dml statements, using this to infer if 
        // the platform event has been created
        System.assertEquals(1, Limits.getDMLRows(), 
            'Expected 1 platform event rows to be created as only 1 of 2 met the condition');
    }

    private class QuotesSelectorStub implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            
            // assumes method selectQuotesByPrimaryDocuSignEnvelopIdWithEnvelopId
            Map<String, SBQQ__Quote__c> associatedQuotes = 
                new Map<String, SBQQ__Quote__c>();

            SBQQ__Quote__c quote1 = new SBQQ__Quote__c();
            SBQQ__Quote__c quote2 = new SBQQ__Quote__c();
            SBQQ__Quote__c quote3 = new SBQQ__Quote__c();
            SBQQ__Quote__c quote4 = new SBQQ__Quote__c();

            associatedQuotes.put('z664b924-ca3a-45ec-8b8a-41241cde87a1', quote1);
            associatedQuotes.put('z664b924-ca3a-45ec-8b8a-41241cde87a2', quote2);
            associatedQuotes.put(ENVELOP_ID_IN_SYSTEM_1, quote3);
            associatedQuotes.put(ENVELOP_ID_IN_SYSTEM_2, quote4);

            return associatedQuotes;
        }
    }

}