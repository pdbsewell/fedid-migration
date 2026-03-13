/**
 * @description Test class for OffersRecipientSignedTriggerHandler
 */
@isTest(isParallel=true)
public class OffersRecipientSignedTriggerHandler_Test {

    private static final String APPLICANT_ROLE = 'APPLICANT';
    private static final String GUARDIAN_ROLE = 'GUARDIAN';

    private static final String SINGLE_APPLICANT_ENVELOP_ID = 
        'A664B924-CA3A-45EC-8B8A-41241CDE87A1';

    private static final String SINGLE_GUARDIAN_ENVELOP_ID = 
        'G664B924-CA3A-45EC-8B8A-41241CDE87A1';

    private static final List<String> TWO_APPLICANTS_ENVELOP_ID = 
        new List<String> {
            'A664B924-CA3A-45EC-8B8A-41241CDE87A1',
            'B664B924-CA3A-45EC-8B8A-41241CDE87A1'
        };

    private static final List<String> TWO_GUARDIANS_ENVELOP_ID = 
        new List<String> {
            'C664B924-CA3A-45EC-8B8A-41241CDE87A1',
            'D664B924-CA3A-45EC-8B8A-41241CDE87A2'
        };

    private static final List<String> ONE_APPLICANT_ONE_GUARDIAN_ENVELOP_ID =
        new List<String> {
            'A664B924-CA3A-45EC-8B8A-41241CDE87A1',
            'B664B924-CA3A-45EC-8B8A-41241CDE87A2'
        };

    private static final List<String> TWO_APPLICANT_TWO_GUARDIAN_ENVELOP_ID =
        new List<String> {
            'A664B924-CA3A-45EC-8B8A-41241CDE87A1',
            'A664B924-CA3A-45EC-8B8A-41241CDE87A2',
            'B664B924-CA3A-45EC-8B8A-41241CDE87A1',
            'B664B924-CA3A-45EC-8B8A-41241CDE87A2'
        };

    private static final List<String> TWO_APPLICANT_ONE_GUARDIAN_ENVELOP_ID =
        new List<String> {
            'A664B924-CA3A-45EC-8B8A-41241CDE87A1',
            'A664B924-CA3A-45EC-8B8A-41241CDE87A2',
            'B664B924-CA3A-45EC-8B8A-41241CDE87A1'
        };

    @isTest
    static void shouldUpdateSignedRecipient1WhenOnlyApplicantSigns() {
        SObjectDaoMock quoteDaoMock = new SObjectDaoMock();
        
        Offers_Recipient_Signed_Event__e applicantSignedEvent = 
            new Offers_Recipient_Signed_Event__e();
        applicantSignedEvent.Envelop_Id__c = SINGLE_APPLICANT_ENVELOP_ID;
        applicantSignedEvent.Recipient_Role__c = APPLICANT_ROLE;

        OffersRecipientSignedTriggerHandler handler = 
            new OffersRecipientSignedTriggerHandler();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new SingleApplicantQuotesSelectorStub());
        handler.quotesDao = quoteDaoMock;
        handler.process(applicantSignedEvent);
        handler.execute();

        System.assertEquals('Signed Recipient 1', 
            quoteDaoMock.recordsUpdated[0].get('Recipient_Signature_Status__c'), 
            'Expected sub status to be updated to Signed Recipient 1');
    }

    @isTest
    static void shouldUpdateSignedRecipient2WhenOnlyGuardianSigns() {
        SObjectDaoMock quoteDaoMock = new SObjectDaoMock();
        
        Offers_Recipient_Signed_Event__e guardianSignedEvent = 
            new Offers_Recipient_Signed_Event__e();
        guardianSignedEvent.Envelop_Id__c = SINGLE_GUARDIAN_ENVELOP_ID;
        guardianSignedEvent.Recipient_Role__c = GUARDIAN_ROLE;

        OffersRecipientSignedTriggerHandler handler = 
            new OffersRecipientSignedTriggerHandler();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new SingleGuardianQuotesSelectorStub());
        handler.quotesDao = quoteDaoMock;
        handler.process(guardianSignedEvent);
        handler.execute();

        System.assertEquals('Signed Recipient 2', 
            quoteDaoMock.recordsUpdated[0].get('Recipient_Signature_Status__c'), 
            'Expected sub status to be updated to Signed Recipient 2');
    }

    
    @isTest
    static void shouldUpdateSignedRecipient1WhenTwoApplicantSigns() {
        SObjectDaoMock quoteDaoMock = new SObjectDaoMock();
        
        Offers_Recipient_Signed_Event__e applicant1SignedEvent = 
            new Offers_Recipient_Signed_Event__e();
        applicant1SignedEvent.Envelop_Id__c = TWO_APPLICANTS_ENVELOP_ID[0];
        applicant1SignedEvent.Recipient_Role__c = APPLICANT_ROLE;

        Offers_Recipient_Signed_Event__e applicant2SignedEvent = 
            new Offers_Recipient_Signed_Event__e();
        applicant2SignedEvent.Envelop_Id__c = TWO_APPLICANTS_ENVELOP_ID[1];
        applicant2SignedEvent.Recipient_Role__c = APPLICANT_ROLE;


        OffersRecipientSignedTriggerHandler handler = 
            new OffersRecipientSignedTriggerHandler();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new TwoApplicantsQuotesSelectorStub());
        handler.quotesDao = quoteDaoMock;
        handler.process(applicant1SignedEvent);
        handler.process(applicant2SignedEvent);
        handler.execute();

        System.assertEquals('Signed Recipient 1', 
            quoteDaoMock.recordsUpdated[0].get('Recipient_Signature_Status__c'), 
            'Expected sub status to be updated to Signed Recipient 1');
        System.assertEquals('Signed Recipient 1', 
            quoteDaoMock.recordsUpdated[1].get('Recipient_Signature_Status__c'), 
            'Expected sub status to be updated to Signed Recipient 1');
    }

    @isTest
    static void shouldUpdateSignedRecipient2WhenTwoGuardiansSigns() {
        SObjectDaoMock quoteDaoMock = new SObjectDaoMock();
        
        Offers_Recipient_Signed_Event__e guardian1SignedEvent = 
            new Offers_Recipient_Signed_Event__e();
        guardian1SignedEvent.Envelop_Id__c = TWO_GUARDIANS_ENVELOP_ID[0];
        guardian1SignedEvent.Recipient_Role__c = GUARDIAN_ROLE;

        Offers_Recipient_Signed_Event__e guardian2SignedEvent = 
            new Offers_Recipient_Signed_Event__e();
        guardian2SignedEvent.Envelop_Id__c = TWO_GUARDIANS_ENVELOP_ID[1];
        guardian2SignedEvent.Recipient_Role__c = GUARDIAN_ROLE;


        OffersRecipientSignedTriggerHandler handler = 
            new OffersRecipientSignedTriggerHandler();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new TwoGuardiansQuotesSelectorStub());
        handler.quotesDao = quoteDaoMock;
        handler.process(guardian1SignedEvent);
        handler.process(guardian2SignedEvent);
        handler.execute();

        System.assertEquals('Signed Recipient 2', 
            quoteDaoMock.recordsUpdated[0].get('Recipient_Signature_Status__c'), 
            'Expected sub status to be updated to Signed Recipient 2');
        System.assertEquals('Signed Recipient 2', 
            quoteDaoMock.recordsUpdated[1].get('Recipient_Signature_Status__c'), 
            'Expected sub status to be updated to Signed Recipient 2');
    }
    
    @isTest
    static void shouldUpdateSignedRecipientWhenOneApplicantAndOneGuardianSigns() {
        SObjectDaoMock quoteDaoMock = new SObjectDaoMock();
        
        Offers_Recipient_Signed_Event__e guardianSignedEvent = 
            new Offers_Recipient_Signed_Event__e();
        guardianSignedEvent.Envelop_Id__c = ONE_APPLICANT_ONE_GUARDIAN_ENVELOP_ID[0];
        guardianSignedEvent.Recipient_Role__c = GUARDIAN_ROLE;

        Offers_Recipient_Signed_Event__e applicantSignedEvent = 
            new Offers_Recipient_Signed_Event__e();
        applicantSignedEvent.Envelop_Id__c = ONE_APPLICANT_ONE_GUARDIAN_ENVELOP_ID[1];
        applicantSignedEvent.Recipient_Role__c = APPLICANT_ROLE;


        OffersRecipientSignedTriggerHandler handler = 
            new OffersRecipientSignedTriggerHandler();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new OneApplicantOneGuardianQuotesSelectorStub());
        handler.quotesDao = quoteDaoMock;
        handler.process(guardianSignedEvent);
        handler.process(applicantSignedEvent);
        handler.execute();

        System.assertEquals('Signed Recipient 2', 
            quoteDaoMock.recordsUpdated[0].get('Recipient_Signature_Status__c'), 
            'Expected sub status to be updated to Signed Recipient 2');
        System.assertEquals('Signed Recipient 1', 
            quoteDaoMock.recordsUpdated[1].get('Recipient_Signature_Status__c'), 
            'Expected sub status to be updated to Signed Recipient 1');
    }

    @isTest
    static void shouldUpdateSignedRecipientWhenTwoApplicantAndTwoGuardianSigns() {
        SObjectDaoMock quoteDaoMock = new SObjectDaoMock();
        
        Offers_Recipient_Signed_Event__e guardian1SignedEvent = 
            new Offers_Recipient_Signed_Event__e();
        guardian1SignedEvent.Envelop_Id__c = TWO_APPLICANT_TWO_GUARDIAN_ENVELOP_ID[2];
        guardian1SignedEvent.Recipient_Role__c = GUARDIAN_ROLE;

        Offers_Recipient_Signed_Event__e guardian2SignedEvent = 
            new Offers_Recipient_Signed_Event__e();
        guardian2SignedEvent.Envelop_Id__c = TWO_APPLICANT_TWO_GUARDIAN_ENVELOP_ID[3];
        guardian2SignedEvent.Recipient_Role__c = GUARDIAN_ROLE;

        Offers_Recipient_Signed_Event__e applicant1SignedEvent = 
            new Offers_Recipient_Signed_Event__e();
        applicant1SignedEvent.Envelop_Id__c = TWO_APPLICANT_TWO_GUARDIAN_ENVELOP_ID[0];
        applicant1SignedEvent.Recipient_Role__c = APPLICANT_ROLE;

        Offers_Recipient_Signed_Event__e applicant2SignedEvent = 
            new Offers_Recipient_Signed_Event__e();
        applicant2SignedEvent.Envelop_Id__c = TWO_APPLICANT_TWO_GUARDIAN_ENVELOP_ID[1];
        applicant2SignedEvent.Recipient_Role__c = APPLICANT_ROLE;


        OffersRecipientSignedTriggerHandler handler = 
            new OffersRecipientSignedTriggerHandler();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new TwoApplicantTwoGuardianQuotesSelectorStub());
        handler.quotesDao = quoteDaoMock;

        handler.process(guardian1SignedEvent);
        handler.process(applicant1SignedEvent);
        handler.process(guardian2SignedEvent);
        handler.process(applicant2SignedEvent);


        handler.execute();

        Integer numberOfQuotesWithSubstatusSignedRecipient1 = 0;
        Integer numberOfQuotesWithSubstatusSignedRecipient2 = 0;
        
        for (SBQQ__Quote__c quote : (SBQQ__Quote__c[]) quoteDaoMock.recordsUpdated) {
            if ('Signed Recipient 1'.equals(quote.Recipient_Signature_Status__c)) {
                numberOfQuotesWithSubstatusSignedRecipient1 += 1;
            } else if ('Signed Recipient 2'.equals(quote.Recipient_Signature_Status__c)) {
                numberOfQuotesWithSubstatusSignedRecipient2 += 1;
            }
        }

        System.assertEquals(2, numberOfQuotesWithSubstatusSignedRecipient1,
            'Expected 2 quotes with Signed Recipient 1');
        System.assertEquals(2, numberOfQuotesWithSubstatusSignedRecipient2,
            'Expected 2 quotes with Signed Recipient 2');
    }

    @isTest
    static void shouldUpdateSignedRecipientWhenTwoApplicantAndOneGuardianSigns() {
        SObjectDaoMock quoteDaoMock = new SObjectDaoMock();
        
        Offers_Recipient_Signed_Event__e guardian1SignedEvent = 
            new Offers_Recipient_Signed_Event__e();
        guardian1SignedEvent.Envelop_Id__c = TWO_APPLICANT_TWO_GUARDIAN_ENVELOP_ID[2];
        guardian1SignedEvent.Recipient_Role__c = GUARDIAN_ROLE;

        Offers_Recipient_Signed_Event__e applicant1SignedEvent = 
            new Offers_Recipient_Signed_Event__e();
        applicant1SignedEvent.Envelop_Id__c = TWO_APPLICANT_TWO_GUARDIAN_ENVELOP_ID[0];
        applicant1SignedEvent.Recipient_Role__c = APPLICANT_ROLE;

        Offers_Recipient_Signed_Event__e applicant2SignedEvent = 
            new Offers_Recipient_Signed_Event__e();
        applicant2SignedEvent.Envelop_Id__c = TWO_APPLICANT_TWO_GUARDIAN_ENVELOP_ID[1];
        applicant2SignedEvent.Recipient_Role__c = APPLICANT_ROLE;


        OffersRecipientSignedTriggerHandler handler = 
            new OffersRecipientSignedTriggerHandler();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new TwoApplicantTwoGuardianQuotesSelectorStub());
        handler.quotesDao = quoteDaoMock;

        handler.process(applicant1SignedEvent);
        handler.process(guardian1SignedEvent);
        handler.process(applicant2SignedEvent);


        handler.execute();

        Integer numberOfQuotesWithSubstatusSignedRecipient1 = 0;
        Integer numberOfQuotesWithSubstatusSignedRecipient2 = 0;
        
        for (SBQQ__Quote__c quote : (SBQQ__Quote__c[]) quoteDaoMock.recordsUpdated) {
            if ('Signed Recipient 1'.equals(quote.Recipient_Signature_Status__c)) {
                numberOfQuotesWithSubstatusSignedRecipient1 += 1;
            } else if ('Signed Recipient 2'.equals(quote.Recipient_Signature_Status__c)) {
                numberOfQuotesWithSubstatusSignedRecipient2 += 1;
            }
        }

        System.assertEquals(2, numberOfQuotesWithSubstatusSignedRecipient1,
            'Expected 2 quotes with Signed Recipient 1');
        System.assertEquals(1, numberOfQuotesWithSubstatusSignedRecipient2,
            'Expected 1 quote with Signed Recipient 2');
    }


    private class SingleApplicantQuotesSelectorStub implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            
            // assumes method selectQuotesByPrimaryDocuSignEnvelopIdWithEnvelopId
            SBQQ__Quote__c quote = new SBQQ__Quote__c();
            Map<String, SBQQ__Quote__c> associatedQuotes = 
                new Map<String, SBQQ__Quote__c>();
            associatedQuotes.put(SINGLE_APPLICANT_ENVELOP_ID, quote);

            return associatedQuotes;
        }
    }


    private class TwoApplicantsQuotesSelectorStub implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            
            // assumes method selectQuotesByPrimaryDocuSignEnvelopIdWithEnvelopId
            Map<String, SBQQ__Quote__c> associatedQuotes = 
                new Map<String, SBQQ__Quote__c>();
            
            SBQQ__Quote__c quote1 = new SBQQ__Quote__c();

            associatedQuotes.put(TWO_APPLICANTS_ENVELOP_ID[0], quote1);

            SBQQ__Quote__c quote2 = new SBQQ__Quote__c();

            associatedQuotes.put(TWO_APPLICANTS_ENVELOP_ID[1], quote2);

            return associatedQuotes;
        }
    }

    private class SingleGuardianQuotesSelectorStub implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            
            // assumes method selectQuotesByPrimaryDocuSignEnvelopIdWithEnvelopId
            SBQQ__Quote__c quote = new SBQQ__Quote__c();
            Map<String, SBQQ__Quote__c> associatedQuotes = 
                new Map<String, SBQQ__Quote__c>();
            associatedQuotes.put(SINGLE_GUARDIAN_ENVELOP_ID, quote);

            return associatedQuotes;
        }
    }

    private class TwoGuardiansQuotesSelectorStub implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            
            // assumes method selectQuotesByPrimaryDocuSignEnvelopIdWithEnvelopId
            Map<String, SBQQ__Quote__c> associatedQuotes = 
                new Map<String, SBQQ__Quote__c>();
            
            SBQQ__Quote__c quote1 = new SBQQ__Quote__c();

            associatedQuotes.put(TWO_GUARDIANS_ENVELOP_ID[0], quote1);

            SBQQ__Quote__c quote2 = new SBQQ__Quote__c();

            associatedQuotes.put(TWO_GUARDIANS_ENVELOP_ID[1], quote2);

            return associatedQuotes;
        }
    }

    private class OneApplicantOneGuardianQuotesSelectorStub implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            
            // assumes method selectQuotesByPrimaryDocuSignEnvelopIdWithEnvelopId
            Map<String, SBQQ__Quote__c> associatedQuotes = 
                new Map<String, SBQQ__Quote__c>();
            
            SBQQ__Quote__c quote1 = new SBQQ__Quote__c();

            associatedQuotes.put(ONE_APPLICANT_ONE_GUARDIAN_ENVELOP_ID[0], quote1);

            SBQQ__Quote__c quote2 = new SBQQ__Quote__c();

            associatedQuotes.put(ONE_APPLICANT_ONE_GUARDIAN_ENVELOP_ID[1], quote2);

            return associatedQuotes;
        }
    }

    private class TwoApplicantTwoGuardianQuotesSelectorStub implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            
            // assumes method selectQuotesByPrimaryDocuSignEnvelopIdWithEnvelopId
            Map<String, SBQQ__Quote__c> associatedQuotes = 
                new Map<String, SBQQ__Quote__c>();
            
            SBQQ__Quote__c quote1 = new SBQQ__Quote__c();

            associatedQuotes.put(TWO_APPLICANT_TWO_GUARDIAN_ENVELOP_ID[0], quote1);

            SBQQ__Quote__c quote2 = new SBQQ__Quote__c();

            associatedQuotes.put(TWO_APPLICANT_TWO_GUARDIAN_ENVELOP_ID[1], quote2);

            SBQQ__Quote__c quote3 = new SBQQ__Quote__c();

            associatedQuotes.put(TWO_APPLICANT_TWO_GUARDIAN_ENVELOP_ID[2], quote3);

            SBQQ__Quote__c quote4 = new SBQQ__Quote__c();

            associatedQuotes.put(TWO_APPLICANT_TWO_GUARDIAN_ENVELOP_ID[3], quote4);

            return associatedQuotes;
        }
    }

    private class TwoApplicantOneGuardianQuotesSelectorStub implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            
            // assumes method selectQuotesByPrimaryDocuSignEnvelopIdWithEnvelopId
            Map<String, SBQQ__Quote__c> associatedQuotes = 
                new Map<String, SBQQ__Quote__c>();
            
            SBQQ__Quote__c quote1 = new SBQQ__Quote__c();

            associatedQuotes.put(TWO_APPLICANT_ONE_GUARDIAN_ENVELOP_ID[0], quote1);

            SBQQ__Quote__c quote2 = new SBQQ__Quote__c();

            associatedQuotes.put(TWO_APPLICANT_ONE_GUARDIAN_ENVELOP_ID[1], quote2);

            SBQQ__Quote__c quote3 = new SBQQ__Quote__c();

            associatedQuotes.put(TWO_APPLICANT_ONE_GUARDIAN_ENVELOP_ID[2], quote3);

            return associatedQuotes;
        }
    }
}