/**
 * @description Test class for GenUnder18OffersDocuSignEnvelopReq
 */
@isTest(isParallel=true)
public class GenUnder18OffersDocuSignEnvelopReq_Test {
    
    private enum QuoteSelectorScenario {PRIMARY_DOCUMENT_DOES_NOT_EXIST, PRIMARY_DOCUMENT_EXISTS, QUOTE_DOES_NOT_EXIST}
    
    @testSetup
    static void makeData(){
        Offer_Setting__c setting = new Offer_Setting__c();
        setting.Guardian_Sign_Contact_Us_Email_Address__c = 'test@test.com';
        insert setting;
    }

    @isTest
    static void shouldThrowQueryExceptionIfNoQuoteIsFound() {
        OffersDocuSignCreateSignReqContext context = new OffersDocuSignCreateSignReqContext();
        try {
            GenUnder18OffersDocuSignEnvelopReq req = new GenUnder18OffersDocuSignEnvelopReq();
            req.quotesSelector =  (QuotesSelector)Test.createStub(QuotesSelector.class, new QuotesSelectorStub(QuoteSelectorScenario.QUOTE_DOES_NOT_EXIST));
            req.handle(context);
            System.assert(false, 'Expected an exception due to non-existent quote.');
        } catch (QueryException e) {
            System.assert(true, 'Expected a query exception as quote was not found');
        } catch (Exception e) {
            System.assert(false, 'Expected a query exception instead of Exception.');
        }
    }

    @isTest
    static void shouldThrowQueryExceptionIfPrimaryDocumentIsMissing() {
        OffersDocuSignCreateSignReqContext context = new OffersDocuSignCreateSignReqContext();
        try {
            GenUnder18OffersDocuSignEnvelopReq req = new GenUnder18OffersDocuSignEnvelopReq();
            req.quotesSelector = (QuotesSelector)Test.createStub(QuotesSelector.class, new QuotesSelectorStub(QuoteSelectorScenario.PRIMARY_DOCUMENT_DOES_NOT_EXIST));
            req.handle(context);
            System.assert(false, 'Expected QueryException due to no primary document');
        } catch (QueryException e) {
            System.assert(true, 'Expected QueryException due to no primary document');
        } catch (Exception e) {
            System.assert(false, 'Expected QueryException instead of Exception');
        }
    }

    @isTest
    static void shouldEncodeDocumentInBase64() {
        OffersDocuSignCreateSignReqContext.Signer applicant = new OffersDocuSignCreateSignReqContext.Signer('Morty Smith', 'morty@test.com');
        OffersDocuSignCreateSignReqContext.Signer guardian = new OffersDocuSignCreateSignReqContext.Signer('Beth Smith', 'beth@test.com');

        OffersDocuSignCreateSignReqContext context = new OffersDocuSignCreateSignReqContext();
        context.setApplicantSigner(applicant);
        context.setGuardianSigner(guardian);

        try {
            GenUnder18OffersDocuSignEnvelopReq req = new GenUnder18OffersDocuSignEnvelopReq();
            req.quotesSelector =  (QuotesSelector)Test.createStub(QuotesSelector.class, new QuotesSelectorStub(QuoteSelectorScenario.PRIMARY_DOCUMENT_EXISTS));
            req.contentVersionSelector = (ContentVersionSelector)Test.createStub(ContentVersionSelector.class, new ContentVersionSelectorStub());
            req.docuSignCreateEnvelopsRequest = new DocuSignCreateEnvelopsRequestStub();
            req.nextHandler = new OffersDocuSignCreateSignatureHandlerStub();
            req.handle(context);
            System.assert(true, 'Did not expect an exception as content has been provided.');
        } catch(Exception e) {
            System.assert(false, 'Did not expect an exception as content has been provided. Exception: ' + e.getMessage() + ', Line number: ' + e.getLineNumber());
        }
    }
    
    private class QuotesSelectorStub implements System.StubProvider {

        public QuoteSelectorScenario scenario;

        public QuotesSelectorStub(QuoteSelectorScenario scenario) {
            this.scenario = scenario;
        }

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
            Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
            List<Object> listOfArgs) {

            /**
             * JSON Sobject deserialization is used to avoid dml operations with creating a quote that relates to a contact
             * The alternative would be to insert a contact and then insert a quote which would 
             * require a lot of work and slow down the unit test methods
             */
            switch on scenario {
                when PRIMARY_DOCUMENT_DOES_NOT_EXIST {
                    SBQQ__Quote__c quoteWithOutPrimaryDocument = new SBQQ__Quote__c();
                    return new List<SBQQ__Quote__c>{quoteWithOutPrimaryDocument};
                }
                when PRIMARY_DOCUMENT_EXISTS {
                    String quoteWithPrimaryDocumentJson = 
                        '{"attributes":{"type":"SBQQ__Quote__c"}, "Name":"Q-99999", "Primary_Document__c": "0685P0000001NeNQAU", "Calculated_Expiry_Date__c":"2020-06-18"}';
                    SBQQ__Quote__c quoteWithPrimaryDocument = 
                        (SBQQ__Quote__c) JSON.deserialize(quoteWithPrimaryDocumentJson, 
                        SBQQ__Quote__c.class);
                    return new List<SBQQ__Quote__c>{quoteWithPrimaryDocument};
                }
                when QUOTE_DOES_NOT_EXIST {
                    return new List<SBQQ__Quote__c>();
                }
            }
            return null;
        }
    }

}