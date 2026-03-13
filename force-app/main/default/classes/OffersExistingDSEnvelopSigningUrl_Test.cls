/**
 * @description Test class for OffersExistingDSEnvelopSigningUrl
 */
@isTest(isParallel=true)
public class OffersExistingDSEnvelopSigningUrl_Test {

    private static final String SIGNING_URL = 'https://demo.docusign.net/Signing/MTRedeem/v1/12ef24bb-42dd-4810-9077-c5f2eb90befd?slt=eyJ0eXAiOiJNVCIsImFsZyI6IlJTMjU2Iiwia2lkIjoiNjgxODVmZjEtNGU1MS00Y2U5LWFmMWMtNjg5ODEyMjAzMzE3In0.AQUAAAABAAMABwAA0EaFx5PXSAgAgJd-N8iT10gYAAEAAAAAAAAAIQB5AwAAeyJUb2tlbklkIjoiYzMyZjkwZDAtOGYyMy00MzZhLWFlNTctN2Q1MDgxZGRkZjAxIiwiU3ViamVjdCI6bnVsbCwiU3ViamVjdFR5cGUiOm51bGwsIkV4cGlyYXRpb24iOiIyMDIwLTAxLTA3VDIzOjIwOjQzKzAwOjAwIiwiSXNzdWVkQXQiOiIyMDIwLTAxLTA3VDIzOjE1OjQ0LjA0MzQwMTcrMDA6MDAiLCJSZXNvdXJjZUlkIjoiZjY3NDI3NWUtYzkyOS00NDQ3LTkyY2YtYTkyMDc1MGFiZWQ4IiwiTGFiZWwiOm51bGwsIlNpdGVJZCI6bnVsbCwiUmVzb3VyY2VzIjoie1wiRW52ZWxvcGVJZFwiOlwiZjY3NDI3NWUtYzkyOS00NDQ3LTkyY2YtYTkyMDc1MGFiZWQ4XCIsXCJBY3RvclVzZXJJZFwiOlwiMzk2OGQ2YTEtNjg4My00YzIxLWE3N2UtNTcwN2ZjYTE5Yzg3XCIsXCJSZWNpcGllbnRJZFwiOlwiMGMzODNlNmMtNGNhNC00NjdiLTg2YjQtM2I5MTM1YTEyMTE0XCIsXCJGYWtlUXVlcnlTdHJpbmdcIjpcInQ9OGJlNjU1ZWItZDJlYy00ODU3LTkyZDEtYWQ2MjA1NTVmYTgwXCJ9IiwiT0F1dGhTdGF0ZSI6bnVsbCwiVG9rZW5UeXBlIjoxLCJBbGxvd1JlY2lwaWVudFVzZXJzIjpmYWxzZSwiQXVkaWVuY2UiOiIyNWUwOTM5OC0wMzQ0LTQ5MGMtOGU1My0zYWIyY2E1NjI3YmYiLCJTY29wZXMiOm51bGwsIlJlZGlyZWN0VXJpIjoiaHR0cHM6Ly9kZW1vLmRvY3VzaWduLm5ldC9TaWduaW5nL1N0YXJ0SW5TZXNzaW9uLmFzcHgiLCJIYXNoQWxnb3JpdGhtIjowLCJIYXNoU2FsdCI6bnVsbCwiSGFzaFJvdW5kcyI6MCwiVG9rZW5TZWNyZXRIYXNoIjpudWxsLCJUb2tlblN0YXR1cyI6MCwiRXh0ZXJuYWxDbGFpbXNSZXF1ZXN0ZWQiOm51bGwsIlRyYW5zYWN0aW9uSWQiOm51bGwsIlRyYW5zYWN0aW9uRXZlbnRDYWxsYmFja1VybCI6bnVsbCwiSXNTaW5nbGVVc2UiOmZhbHNlfQ.gvOQTZI_98RemIsZukHWJC_6ZIGGsc3Jr6dB6GykLXoFwAkWm192dp7lBRhYgpG9K9wphy4fiNBYrT4S2nXcf-UfonaDPFH1j8AEejRzsg9eQj17n7L1uLZQsN4Y6xT23jmo4W24tfBzWhLnxqnV-s08gE7I543d2jdh_CKXuhOZbJ-V4osD0iAsP0j4RboRET2tPSCPkugoRe_VD6OINl3EdIM4g4vEaA85pnheNqhUxvy25tRRlbLZFWRrrD6LcOYGM2dTWu36kioede-EJsvw3Kb_r047L-aOISzWawh0paMEskfZ8khrG3bneuiLqcHLVu84tPHSGGsK0Ne7sQ';
    private static final Id QUOTE_ID_1 = Id.valueOf('a9L5P000000025NUAQ');
    private static final String ENVELOP_ID_1 = 'abc-123-test';

    @isTest
    static void shouldGenerateSigningUrlForQuoteId() {
        
        QuotesSelector quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new SingleQuoteReturnedQuotesSelectorStub());

        OffersExistingDSEnvelopSigningUrl offersExistingDSEnvelopSigningUrl = 
            new OffersExistingDSEnvelopSigningUrl(quotesSelector, 
            new DocuSignGetSigningUrlRequestStub());

        String result = offersExistingDSEnvelopSigningUrl.getSigningUrl(QUOTE_ID_1);

        System.assertEquals(SIGNING_URL, result, 
            'Expected signing URL generated to match');
    }

    @isTest
    static void shouldThrowIllegalArgumentExceptionWhenQuoteIsMissingEnvelopId() {
        QuotesSelector quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, new SingleQuoteMissingEnvelopIdQuotesSelectorStub());

        OffersExistingDSEnvelopSigningUrl offersExistingDSEnvelopSigningUrl = 
            new OffersExistingDSEnvelopSigningUrl(quotesSelector, 
            new DocuSignGetSigningUrlRequestStub());

        try {
            offersExistingDSEnvelopSigningUrl.getSigningUrl(QUOTE_ID_1);
            System.assert(false, 'Expected IllegalArgumentException as Envelop ' 
            + 'Id is missing on Quote');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected IllegalArgumentException as Envelop ' 
            + 'Id is missing on Quote');
        } catch (Exception e) {
            System.assert(false, 'Expected IllegalArgumentException instead of Exception');
        }
    }

    private class SingleQuoteReturnedQuotesSelectorStub implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            
            // return single quote, assumes selectQuoteById is called
            String quoteJson = 
                '{"attributes":{"type":"SBQQ__Quote__c"},"Id": "' + QUOTE_ID_1 
                + '", "Primary_DocuSign_Envelop_Id__c": "' + ENVELOP_ID_1 
                + '", "Email__c":"test@test.com","Contact_Firstname__c":"Kenny","Contact_Lastname__c":"McCormick","SBQQ__PrimaryContact__r":{"attributes":{"type":"Contact"},"Last_Name__c":"McCormick","First_Name__c":"Kenny","Is_Mononymous_Name__c":false,"Under_18__c":false}}';
            SBQQ__Quote__c quote = 
                (SBQQ__Quote__c) JSON.deserialize(quoteJson, 
                SBQQ__Quote__c.class);
            return new List<SBQQ__Quote__c>{quote};
        }

    }

    private class SingleQuoteMissingEnvelopIdQuotesSelectorStub implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            
            // return single quote, assumes selectQuoteById is called
            String quoteJson = 
                '{"attributes":{"type":"SBQQ__Quote__c"},"Id": "' + QUOTE_ID_1 
                + '", "Primary_DocuSign_Envelop_Id__c": "' + '' 
                + '", "Email__c":"test@test.com","Contact_Firstname__c":"Kenny","Contact_Lastname__c":"McCormick","SBQQ__PrimaryContact__r":{"attributes":{"type":"Contact"},"Last_Name__c":"McCormick","First_Name__c":"Kenny","Is_Mononymous_Name__c":false,"Under_18__c":false}}';
            SBQQ__Quote__c quote = 
                (SBQQ__Quote__c) JSON.deserialize(quoteJson, 
                SBQQ__Quote__c.class);
            return new List<SBQQ__Quote__c>{quote};
        }

    }

    public class DocuSignGetSigningUrlRequestStub implements DocuSignGetSigningUrlRequest {
        
        public String getSigningUrl(String docuSignAccountId, String envelopId, 
                DocuSignGetSigningUrlRequestBody requestBody) {
            return SIGNING_URL;
        }

    }
}