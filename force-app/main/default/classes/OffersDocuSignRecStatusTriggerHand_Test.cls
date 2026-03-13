/**
 * @description Test class for OffersDocuSignRecStatusTriggerHand
 */
@isTest(isParallel=true)
public class OffersDocuSignRecStatusTriggerHand_Test {
    
    private static final String DOCUSIGN_RECIPIENT_COMPLETED_STATUS = 'Completed';

    private static final String ENVELOP_ID_IN_SYSTEM_1 = 'a664b924-ca3a-45ec-8b8a-41241cde87a1';
    private static final String ENVELOP_ID_IN_SYSTEM_2 = 'a664b924-ca3a-45ec-8b8a-41241cde87a2';


    @isTest
    static void shouldNotCreateNotificationIfSignedEnvelopIdIsNotInSystem() {

        dsfs__DocuSign_Recipient_Status__c recipientStatus = 
            new dsfs__DocuSign_Recipient_Status__c();

        recipientStatus.dsfs__Recipient_Status__c = 
            DOCUSIGN_RECIPIENT_COMPLETED_STATUS;
        recipientStatus.dsfs__Envelope_Id__c = 'dne';
    
        OffersDocuSignRecStatusTriggerHand handler = 
            new OffersDocuSignRecStatusTriggerHand();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new QuotesSelectorStub());
        handler.process(recipientStatus);

        handler.execute();

        // platform events consume dml statements, using this to infer if 
        // the platform event has been created
        System.assertEquals(0, Limits.getDMLStatements(), 
            'Expected no platform event to be created as no envelop id associated to a quote');
    }

    @isTest
    static void shouldNotCreateNotificationIfUnsignedEnvelopIdIsInSystem() {

        dsfs__DocuSign_Recipient_Status__c recipientStatus = 
            new dsfs__DocuSign_Recipient_Status__c();

        recipientStatus.dsfs__Recipient_Status__c = 'Sent';
    
        // upper case to simulate real data from DocuSign
        recipientStatus.dsfs__Envelope_Id__c = ENVELOP_ID_IN_SYSTEM_1.toUpperCase();
    
        OffersDocuSignRecStatusTriggerHand handler = 
            new OffersDocuSignRecStatusTriggerHand();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new QuotesSelectorStub());
        handler.process(recipientStatus);

        handler.execute();

        // platform events consume dml statements, using this to infer if 
        // the platform event has been created
        System.assertEquals(0, Limits.getDMLStatements(), 
            'Expected no platform event to be created as no envelop id associated to a quote');
    }

    @isTest
    static void shouldNotCreateNotificationIfUnsignedEnvelopIdIsNotInSystem() {

        dsfs__DocuSign_Recipient_Status__c recipientStatus = 
            new dsfs__DocuSign_Recipient_Status__c();

        recipientStatus.dsfs__Recipient_Status__c = 'Sent';
        recipientStatus.dsfs__Envelope_Id__c = 'DNE';
    
        OffersDocuSignRecStatusTriggerHand handler = 
            new OffersDocuSignRecStatusTriggerHand();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new QuotesSelectorStub());
        handler.process(recipientStatus);

        handler.execute();

        // platform events consume dml statements, using this to infer if 
        // the platform event has been created
        System.assertEquals(0, Limits.getDMLStatements(), 
            'Expected no platform event to be created envelop is not signed and envelop id is not in system');
    }

    @isTest
    static void shouldNotCreateNotificationIfTwoUnsignedEnvelopIdIsNotInSystem() {

        dsfs__DocuSign_Recipient_Status__c recipient1Status = 
            new dsfs__DocuSign_Recipient_Status__c();

        recipient1Status.dsfs__Recipient_Status__c = 'Sent';
        recipient1Status.dsfs__Envelope_Id__c = 'DNE';

        dsfs__DocuSign_Recipient_Status__c recipient2Status = 
            new dsfs__DocuSign_Recipient_Status__c();

        recipient2Status.dsfs__Recipient_Status__c = 'Sent';
        recipient2Status.dsfs__Envelope_Id__c = 'DNE2';
    
        OffersDocuSignRecStatusTriggerHand handler = 
            new OffersDocuSignRecStatusTriggerHand();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new QuotesSelectorStub());
        handler.process(recipient1Status);
        handler.process(recipient2Status);

        handler.execute();

        // platform events consume dml statements, using this to infer if 
        // the platform event has been created
        System.assertEquals(0, Limits.getDMLStatements(), 
            'Expected no platform event to be created as both recipients did not meet condition');
    }

    @isTest
    static void shouldNotCreateNotifyIfUnsignedEnvelopIdIsNotInSystemAndSignedEnvelopNotInSystem() {

        dsfs__DocuSign_Recipient_Status__c recipient1Status = 
            new dsfs__DocuSign_Recipient_Status__c();

        recipient1Status.dsfs__Recipient_Status__c = 'Sent';
        recipient1Status.dsfs__Envelope_Id__c = 'DNE';

        dsfs__DocuSign_Recipient_Status__c recipient2Status = 
            new dsfs__DocuSign_Recipient_Status__c();

        recipient2Status.dsfs__Recipient_Status__c = 
            DOCUSIGN_RECIPIENT_COMPLETED_STATUS;
        recipient2Status.dsfs__Envelope_Id__c = 'DNE2';
    
        OffersDocuSignRecStatusTriggerHand handler = 
            new OffersDocuSignRecStatusTriggerHand();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new QuotesSelectorStub());
        handler.process(recipient1Status);
        handler.process(recipient2Status);

        handler.execute();

        // platform events consume dml statements, using this to infer if 
        // the platform event has been created
        System.assertEquals(0, Limits.getDMLStatements(), 
            'Expected no platform event to be created as both recipients did not meet condition');
    }

    @isTest 
    static void shouldCreateNotificationIfApplicantSignedEnvelopIsInSystem() {
        dsfs__DocuSign_Recipient_Status__c recipientStatus = 
            new dsfs__DocuSign_Recipient_Status__c();

        recipientStatus.dsfs__Recipient_Status__c = 
            DOCUSIGN_RECIPIENT_COMPLETED_STATUS;
        recipientStatus.dsfs__DocuSign_Routing_Order__c = 1;

        // upper case to simulate real data from DocuSign
        recipientStatus.dsfs__Envelope_Id__c = ENVELOP_ID_IN_SYSTEM_1.toUpperCase();
    
        OffersDocuSignRecStatusTriggerHand handler = 
            new OffersDocuSignRecStatusTriggerHand();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new QuotesSelectorStub());
        handler.process(recipientStatus);

        handler.execute();

        // platform events consume dml statements, using this to infer if 
        // the platform event has been created
        System.assertEquals(1, Limits.getDMLStatements(), 
            'Expected 1 platform event to be created as the signed envelop id associated to a quote');
    }

    @isTest 
    static void shouldCreateNotificationIfTwoApplicantsSignedEnvelopIsInSystem() {
        dsfs__DocuSign_Recipient_Status__c recipient1Status = 
            new dsfs__DocuSign_Recipient_Status__c();

        recipient1Status.dsfs__Recipient_Status__c = 
            DOCUSIGN_RECIPIENT_COMPLETED_STATUS;
        recipient1Status.dsfs__DocuSign_Routing_Order__c = 1;

        // upper case to simulate real data from DocuSign
        recipient1Status.dsfs__Envelope_Id__c = ENVELOP_ID_IN_SYSTEM_1.toUpperCase();
    
        dsfs__DocuSign_Recipient_Status__c recipient2Status = 
            new dsfs__DocuSign_Recipient_Status__c();

        recipient2Status.dsfs__Recipient_Status__c = 
            DOCUSIGN_RECIPIENT_COMPLETED_STATUS;
        recipient2Status.dsfs__DocuSign_Routing_Order__c = 1;

        // upper case to simulate real data from DocuSign
        recipient2Status.dsfs__Envelope_Id__c = ENVELOP_ID_IN_SYSTEM_2.toUpperCase();
    

        OffersDocuSignRecStatusTriggerHand handler = 
            new OffersDocuSignRecStatusTriggerHand();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new QuotesSelectorStub());
        handler.process(recipient1Status);
        handler.process(recipient2Status);
        handler.execute();

        // platform events consume dml statements, using this to infer if 
        // the platform event has been created
        System.assertEquals(2, Limits.getDMLRows(), 
            'Expected 2 platform event to be created as two meet the condition');
    }

    @isTest 
    static void shouldCreateNotificationIfGuardianSignedEnvelopIsInSystem() {
        dsfs__DocuSign_Recipient_Status__c recipientStatus = 
            new dsfs__DocuSign_Recipient_Status__c();

        recipientStatus.dsfs__Recipient_Status__c = 
            DOCUSIGN_RECIPIENT_COMPLETED_STATUS;
        recipientStatus.dsfs__DocuSign_Routing_Order__c = 2;

        // upper case to simulate real data from DocuSign
        recipientStatus.dsfs__Envelope_Id__c = ENVELOP_ID_IN_SYSTEM_1.toUpperCase();
    
        OffersDocuSignRecStatusTriggerHand handler = 
            new OffersDocuSignRecStatusTriggerHand();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new QuotesSelectorStub());
        handler.process(recipientStatus);

        handler.execute();

        // platform events consume dml statements, using this to infer if 
        // the platform event has been created
        System.assertEquals(1, Limits.getDMLStatements(), 
            'Expected 1 platform event to be created as the signed envelop id associated to a quote');
    }

    @isTest 
    static void shouldCreateNotificationIfTwoGuardiansSignedEnvelopIsInSystem() {
        dsfs__DocuSign_Recipient_Status__c recipient1Status = 
            new dsfs__DocuSign_Recipient_Status__c();

        recipient1Status.dsfs__Recipient_Status__c = 
            DOCUSIGN_RECIPIENT_COMPLETED_STATUS;
        recipient1Status.dsfs__DocuSign_Routing_Order__c = 2;

        // upper case to simulate real data from DocuSign
        recipient1Status.dsfs__Envelope_Id__c = ENVELOP_ID_IN_SYSTEM_1.toUpperCase();
    
        dsfs__DocuSign_Recipient_Status__c recipient2Status = 
            new dsfs__DocuSign_Recipient_Status__c();

        recipient2Status.dsfs__Recipient_Status__c = 
            DOCUSIGN_RECIPIENT_COMPLETED_STATUS;
        recipient2Status.dsfs__DocuSign_Routing_Order__c = 2;

        // upper case to simulate real data from DocuSign
        recipient2Status.dsfs__Envelope_Id__c = ENVELOP_ID_IN_SYSTEM_2.toUpperCase();
    

        OffersDocuSignRecStatusTriggerHand handler = 
            new OffersDocuSignRecStatusTriggerHand();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new QuotesSelectorStub());
        handler.process(recipient1Status);
        handler.process(recipient2Status);
        handler.execute();

        // platform events consume dml statements, using this to infer if 
        // the platform event has been created
        System.assertEquals(2, Limits.getDMLRows(), 
            'Expected 2 platform event rows to be created as two meet the condition');
    }

    @isTest 
    static void shouldCreateNotificationIfOneApplicantAndOneGuardiansSignedEnvelopIsInSystem() {
        dsfs__DocuSign_Recipient_Status__c recipient1Status = 
            new dsfs__DocuSign_Recipient_Status__c();

        recipient1Status.dsfs__Recipient_Status__c = 
            DOCUSIGN_RECIPIENT_COMPLETED_STATUS;
        recipient1Status.dsfs__DocuSign_Routing_Order__c = 1;

        // upper case to simulate real data from DocuSign
        recipient1Status.dsfs__Envelope_Id__c = ENVELOP_ID_IN_SYSTEM_1.toUpperCase();
    
        dsfs__DocuSign_Recipient_Status__c recipient2Status = 
            new dsfs__DocuSign_Recipient_Status__c();

        recipient2Status.dsfs__Recipient_Status__c = 
            DOCUSIGN_RECIPIENT_COMPLETED_STATUS;
        recipient2Status.dsfs__DocuSign_Routing_Order__c = 2;

        // upper case to simulate real data from DocuSign
        recipient2Status.dsfs__Envelope_Id__c = ENVELOP_ID_IN_SYSTEM_2.toUpperCase();
    

        OffersDocuSignRecStatusTriggerHand handler = 
            new OffersDocuSignRecStatusTriggerHand();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new QuotesSelectorStub());
        handler.process(recipient1Status);
        handler.process(recipient2Status);
        handler.execute();

        // platform events consume dml statements, using this to infer if 
        // the platform event has been created
        System.assertEquals(2, Limits.getDMLRows(), 
            'Expected 2 platform event rows to be created as two meet the condition');
    }

    
    @isTest 
    static void shouldCreateOneNotificationIfOnlyOneApplicantOfTwoMeetsCondition() {
        dsfs__DocuSign_Recipient_Status__c recipient1Status = 
            new dsfs__DocuSign_Recipient_Status__c();

        recipient1Status.dsfs__Recipient_Status__c = 'sent';
        recipient1Status.dsfs__DocuSign_Routing_Order__c = 1;

        // upper case to simulate real data from DocuSign
        recipient1Status.dsfs__Envelope_Id__c = ENVELOP_ID_IN_SYSTEM_1.toUpperCase();
    
        dsfs__DocuSign_Recipient_Status__c recipient2Status = 
            new dsfs__DocuSign_Recipient_Status__c();

        recipient2Status.dsfs__Recipient_Status__c = 
            DOCUSIGN_RECIPIENT_COMPLETED_STATUS;
        recipient2Status.dsfs__DocuSign_Routing_Order__c = 1;

        // upper case to simulate real data from DocuSign
        recipient2Status.dsfs__Envelope_Id__c = ENVELOP_ID_IN_SYSTEM_2.toUpperCase();
    

        OffersDocuSignRecStatusTriggerHand handler = 
            new OffersDocuSignRecStatusTriggerHand();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new QuotesSelectorStub());
        handler.process(recipient1Status);
        handler.process(recipient2Status);
        handler.execute();

        // platform events consume dml statements, using this to infer if 
        // the platform event has been created
        System.assertEquals(1, Limits.getDMLRows(), 
            'Expected 1 platform event row to be created as only 1 of 2 meet the condition');
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