/**
 * @description Test class for OffersGenerateGetSigningUrlHandler
 */
@isTest(isParallel=true)
public class OffersGenerateGetSigningUrlHandler_Test {

    private enum QuoteSelectorScenario {
        NO_QUOTE_RETURNED,
        VALID_QUOTE
    }

    @isTest
    static void shouldThrowQueryExceptionIfQuoteIsNotFound() {

        OffersDocuSignCreateSignReqContext context = new OffersDocuSignCreateSignReqContext();

        OffersGenerateGetSigningUrlHandler offersGenerateGetSigningUrlHandler = new OffersGenerateGetSigningUrlHandler();
        offersGenerateGetSigningUrlHandler.quoteDao = new SObjectDaoMock();
        offersGenerateGetSigningUrlHandler.quotesSelector = 
                (QuotesSelector) Test.createStub(QuotesSelector.class, 
                new QuotesSelectorStub(QuoteSelectorScenario.NO_QUOTE_RETURNED));

        try {
            offersGenerateGetSigningUrlHandler.handle(context);
            System.assert(false, 'Expected QueryException as there is no quote');
        } catch (QueryException e) {
            System.assert(true, 'Expected QueryException as there is no quote');
        } catch (Exception e) {
            System.assert(false, 
                'Expected QueryException instead of Exception as there is no quote');
        }
    }
    
    @isTest
    static void shouldUpdateQuoteEnvelopIdOnSigningUrlSuccess() {
        String envelopId = 'e1420cb6-7172-4e39-acca-45888ad4e461';
        
        SObjectDaoMock SObjectDaoMock = new SObjectDaoMock();

        OffersDocuSignCreateSignReqContext context = 
            new OffersDocuSignCreateSignReqContext();

        context.setEnvelopId(envelopId);
        
        OffersDocuSignCreateSignReqContext.Signer applicantSigner = 
            new OffersDocuSignCreateSignReqContext.Signer('Summer Smith', 'test@test.com');
        applicantSigner.setUserId('98t45893tuhidf');
        context.setApplicantSigner(applicantSigner);

        OffersGenerateGetSigningUrlHandler offersGenerateGetSigningUrlHandler = 
            new OffersGenerateGetSigningUrlHandler();
        
        offersGenerateGetSigningUrlHandler.quoteDao = SObjectDaoMock;
        
        offersGenerateGetSigningUrlHandler.quotesSelector = 
            (QuotesSelector) Test.createStub(QuotesSelector.class, 
            new QuotesSelectorStub(QuoteSelectorScenario.VALID_QUOTE));
        
        offersGenerateGetSigningUrlHandler.docuSignGetSigningUrlRequest = 
            new DocuSignGetSigningUrlSuccessRequestStub();

        offersGenerateGetSigningUrlHandler.handle(context);

        System.assertEquals(envelopId, 
            SObjectDaoMock.recordsUpdated[0].get('Primary_DocuSign_Envelop_Id__c'), 
            'Expected envelop Id to be updated with envelop Id from context');
    }

    @isTest
    static void shouldUpdateQuoteSubStatusOnSigningUrlSuccess() {
        SObjectDaoMock SObjectDaoMock = new SObjectDaoMock();

        OffersDocuSignCreateSignReqContext context = 
            new OffersDocuSignCreateSignReqContext();
        
        OffersDocuSignCreateSignReqContext.Signer applicantSigner = 
            new OffersDocuSignCreateSignReqContext.Signer('Summer Smith', 'test@test.com');
        applicantSigner.setUserId('98t45893tuhidf');
        context.setApplicantSigner(applicantSigner);

        OffersGenerateGetSigningUrlHandler offersGenerateGetSigningUrlHandler = 
            new OffersGenerateGetSigningUrlHandler();
        
        offersGenerateGetSigningUrlHandler.quoteDao = SObjectDaoMock;
        
        offersGenerateGetSigningUrlHandler.quotesSelector = 
            (QuotesSelector) Test.createStub(QuotesSelector.class, 
            new QuotesSelectorStub(QuoteSelectorScenario.VALID_QUOTE));
        
        offersGenerateGetSigningUrlHandler.docuSignGetSigningUrlRequest = 
            new DocuSignGetSigningUrlSuccessRequestStub();

        offersGenerateGetSigningUrlHandler.handle(context);

        System.assertEquals('Pending signature in Docusign', 
            SObjectDaoMock.recordsUpdated[0].get('Sub_Status__c'), 
            'Expected quote sub status to be updated to "Pending signature in Docusign"');
    }

    @isTest
    static void shouldSaveDocuSignSigningUrlOnSigningUrlSuccess() {
        SObjectDaoMock SObjectDaoMock = new SObjectDaoMock();

        OffersDocuSignCreateSignReqContext context = 
            new OffersDocuSignCreateSignReqContext();
        
        OffersDocuSignCreateSignReqContext.Signer applicantSigner = 
            new OffersDocuSignCreateSignReqContext.Signer('Summer Smith', 'test@test.com');
        applicantSigner.setUserId('98t45893tuhidf');
        context.setApplicantSigner(applicantSigner);

        OffersGenerateGetSigningUrlHandler offersGenerateGetSigningUrlHandler = 
            new OffersGenerateGetSigningUrlHandler();
        
        offersGenerateGetSigningUrlHandler.quoteDao = SObjectDaoMock;
       
        offersGenerateGetSigningUrlHandler.quotesSelector = 
            (QuotesSelector) Test.createStub(QuotesSelector.class, 
            new QuotesSelectorStub(QuoteSelectorScenario.VALID_QUOTE));
        
        offersGenerateGetSigningUrlHandler.docuSignGetSigningUrlRequest = 
            new DocuSignGetSigningUrlSuccessRequestStub();

        offersGenerateGetSigningUrlHandler.handle(context);

        System.assertNotEquals(null, 
            SObjectDaoMock.recordsUpdated[0].get('DocuSign_Signing_URL__c'), 
            'Expected DocuSign signing url to be updated on quote as the response was successful');
    }

    @isTest
    static void shouldSaveDocuSignSigningUrlCreatedOnSigningUrlSuccess() {
        SObjectDaoMock SObjectDaoMock = new SObjectDaoMock();

        OffersDocuSignCreateSignReqContext context = 
            new OffersDocuSignCreateSignReqContext();
        
        OffersDocuSignCreateSignReqContext.Signer applicantSigner = 
            new OffersDocuSignCreateSignReqContext.Signer('Summer Smith', 'test@test.com');
        applicantSigner.setUserId('98t45893tuhidf');
        context.setApplicantSigner(applicantSigner);

        OffersGenerateGetSigningUrlHandler offersGenerateGetSigningUrlHandler = 
            new OffersGenerateGetSigningUrlHandler();
        
        offersGenerateGetSigningUrlHandler.quoteDao = SObjectDaoMock;
       
        offersGenerateGetSigningUrlHandler.quotesSelector = 
            (QuotesSelector) Test.createStub(QuotesSelector.class, 
            new QuotesSelectorStub(QuoteSelectorScenario.VALID_QUOTE));
        
        offersGenerateGetSigningUrlHandler.docuSignGetSigningUrlRequest = 
            new DocuSignGetSigningUrlSuccessRequestStub();

        offersGenerateGetSigningUrlHandler.handle(context);

        System.assertNotEquals(null, 
            SObjectDaoMock.recordsUpdated[0].get('DocuSign_Signing_URL_Created__c'), 
            'Expected DocuSign signing url created to be updated on quote as the response was successful');
    }

    private class QuotesSelectorStub implements System.StubProvider {

        private QuoteSelectorScenario scenario;

        public QuotesSelectorStub(QuoteSelectorScenario scenario) {
            this.scenario = scenario;
        }

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
            Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
            List<Object> listOfArgs) {

            switch on scenario {
                when NO_QUOTE_RETURNED {
                    return new List<SBQQ__Quote__c>();
                }
                when VALID_QUOTE {
                    SBQQ__Quote__c validQuote = new SBQQ__Quote__c();
                    validQuote.SBQQ__Status__c = 'Published';
                    validQuote.Sub_Status__c = 'Doc generated for signing';
                    return new List<SBQQ__Quote__c>{validQuote};
                }
            }
            return null;
        }
    }

    private class DocuSignGetSigningUrlSuccessRequestStub implements DocuSignGetSigningUrlRequest {
        
        String docuSignGeneratedUrl = 'https://demo.docusign.net/Signing/MTRedeem/v1/12ef24bb-42dd-4810-9077-c5f2eb90befd?slt=eyJ0eXAiOiJNVCIsImFsZyI6IlJTMjU2Iiwia2lkIjoiNjgxODVmZjEtNGU1MS00Y2U5LWFmMWMtNjg5ODEyMjAzMzE3In0.AQUAAAABAAMABwAA0EaFx5PXSAgAgJd-N8iT10gYAAEAAAAAAAAAIQB5AwAAeyJUb2tlbklkIjoiYzMyZjkwZDAtOGYyMy00MzZhLWFlNTctN2Q1MDgxZGRkZjAxIiwiU3ViamVjdCI6bnVsbCwiU3ViamVjdFR5cGUiOm51bGwsIkV4cGlyYXRpb24iOiIyMDIwLTAxLTA3VDIzOjIwOjQzKzAwOjAwIiwiSXNzdWVkQXQiOiIyMDIwLTAxLTA3VDIzOjE1OjQ0LjA0MzQwMTcrMDA6MDAiLCJSZXNvdXJjZUlkIjoiZjY3NDI3NWUtYzkyOS00NDQ3LTkyY2YtYTkyMDc1MGFiZWQ4IiwiTGFiZWwiOm51bGwsIlNpdGVJZCI6bnVsbCwiUmVzb3VyY2VzIjoie1wiRW52ZWxvcGVJZFwiOlwiZjY3NDI3NWUtYzkyOS00NDQ3LTkyY2YtYTkyMDc1MGFiZWQ4XCIsXCJBY3RvclVzZXJJZFwiOlwiMzk2OGQ2YTEtNjg4My00YzIxLWE3N2UtNTcwN2ZjYTE5Yzg3XCIsXCJSZWNpcGllbnRJZFwiOlwiMGMzODNlNmMtNGNhNC00NjdiLTg2YjQtM2I5MTM1YTEyMTE0XCIsXCJGYWtlUXVlcnlTdHJpbmdcIjpcInQ9OGJlNjU1ZWItZDJlYy00ODU3LTkyZDEtYWQ2MjA1NTVmYTgwXCJ9IiwiT0F1dGhTdGF0ZSI6bnVsbCwiVG9rZW5UeXBlIjoxLCJBbGxvd1JlY2lwaWVudFVzZXJzIjpmYWxzZSwiQXVkaWVuY2UiOiIyNWUwOTM5OC0wMzQ0LTQ5MGMtOGU1My0zYWIyY2E1NjI3YmYiLCJTY29wZXMiOm51bGwsIlJlZGlyZWN0VXJpIjoiaHR0cHM6Ly9kZW1vLmRvY3VzaWduLm5ldC9TaWduaW5nL1N0YXJ0SW5TZXNzaW9uLmFzcHgiLCJIYXNoQWxnb3JpdGhtIjowLCJIYXNoU2FsdCI6bnVsbCwiSGFzaFJvdW5kcyI6MCwiVG9rZW5TZWNyZXRIYXNoIjpudWxsLCJUb2tlblN0YXR1cyI6MCwiRXh0ZXJuYWxDbGFpbXNSZXF1ZXN0ZWQiOm51bGwsIlRyYW5zYWN0aW9uSWQiOm51bGwsIlRyYW5zYWN0aW9uRXZlbnRDYWxsYmFja1VybCI6bnVsbCwiSXNTaW5nbGVVc2UiOmZhbHNlfQ.gvOQTZI_98RemIsZukHWJC_6ZIGGsc3Jr6dB6GykLXoFwAkWm192dp7lBRhYgpG9K9wphy4fiNBYrT4S2nXcf-UfonaDPFH1j8AEejRzsg9eQj17n7L1uLZQsN4Y6xT23jmo4W24tfBzWhLnxqnV-s08gE7I543d2jdh_CKXuhOZbJ-V4osD0iAsP0j4RboRET2tPSCPkugoRe_VD6OINl3EdIM4g4vEaA85pnheNqhUxvy25tRRlbLZFWRrrD6LcOYGM2dTWu36kioede-EJsvw3Kb_r047L-aOISzWawh0paMEskfZ8khrG3bneuiLqcHLVu84tPHSGGsK0Ne7sQ';

        public String getSigningUrl(String docuSignAccountId, 
                String envelopId, 
                DocuSignGetSigningUrlRequestBody requestBody) {
            return docuSignGeneratedUrl;
        }

    }

    private class DocuSignGetSigningUrlRequestUnauthorizedAccessExceptionStub implements DocuSignGetSigningUrlRequest {
        public String getSigningUrl(String docuSignAccountId, String envelopId, DocuSignGetSigningUrlRequestBody requestBody) {
            throw new DocuSignUnauthorizedAccessException();
        }
    }

    private class DocuSignGetSigningUrlReqFailedRequestStub implements DocuSignGetSigningUrlRequest {
        public String getSigningUrl(String docuSignAccountId, String envelopId, DocuSignGetSigningUrlRequestBody requestBody) {
            throw new DocuSignGetSignUrlReqFailException();
        }
    }
}