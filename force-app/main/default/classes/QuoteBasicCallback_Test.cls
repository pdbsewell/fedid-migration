@isTest(isParallel=true)
public with sharing class QuoteBasicCallback_Test {
    @isTest
    private static void test_success(){
        SBQQ__Quote__c q = new SBQQ__Quote__c(
            SBQQ__EndDate__c = Date.today().addMonths(2),
            SBQQ__StartDate__c = Date.today().addMonths(1),
            SBQQ__Type__c = 'Quote',
            Expiry_Status__c = 'Active Offer',
            Product_Status__c = 'Active Products',
            SBQQ__Status__c = 'New',
            Sub_Status__c = 'In Progress',
            Category__c = 'ISCA Deposit',
            Product_Search_Filter__c = 'Offer'
        );
        SBQQ.TriggerControl.disable();
        insert q;
        SBQQ.TriggerControl.enable();

        CPQ_ApiDataModels.QuoteModel quote = CPQ_APIService.getQuote(q.Id);
        
        Test.startTest();
        QuoteBasicCallback handler = new QuoteBasicCallback();
        handler.callback(JSON.serialize(quote));
        Test.stopTest();
        System.assert(handler.quoteModel != null, 'Quote is successful.');
    }
    @isTest
    private static void test_serialize_error(){
        Test.startTest();
        QuoteBasicCallback handler = new QuoteBasicCallback();
        handler.callback(null);
        Test.stopTest();
        System.assert(handler.quoteModel == null, 'Quote is failing.');
    }
}