@isTest(isParallel=true)
public with sharing class QuoteCreationCallback_Test {
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
        QuoteCreationCallback handler = new QuoteCreationCallback(); 
        handler.callback(JSON.serialize(quote));
        handler.results = null;
        handler.handleValidateResponse();
        Test.stopTest();
        System.assert(handler.quoteModel.record.Sub_Status__c == 'Pricing Completed', 'Quote is successfull');
    }

    @isTest
    private static void test_business_error(){
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
        QuoteCreationCallback handler = new QuoteCreationCallback(); 
        handler.callback(JSON.serialize(quote));
        handler.results = new String[]{'CPQ Business Error.'};
        handler.handleValidateResponse();
        Test.stopTest();
        System.assert(handler.quoteModel.record.Sub_Status__c == 'Offer creation/update error', 'Business error was identified');
    }
    @isTest
    private static void test_serialize_error(){
        Test.startTest();
        QuoteCreationCallback handler = new QuoteCreationCallback();
        handler.callback('hello world');
        Test.stopTest();
        System.assert(handler.quoteModel == null,'no quote as bad json');
    }
}