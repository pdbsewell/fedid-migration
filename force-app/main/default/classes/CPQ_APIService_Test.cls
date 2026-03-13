@isTest
public with sharing class CPQ_APIService_Test {
    @isTest
    static void test_quote_save(){
        SBQQ__Quote__c q = new SBQQ__Quote__c(
                SBQQ__PricebookId__c = Test.getStandardPricebookId(),
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
        CPQ_APIService.save(quote);
        Test.stopTest();
    }
    @isTest
    static void test_quote_load(){
        SBQQ__Quote__c q = new SBQQ__Quote__c(
                SBQQ__PricebookId__c = Test.getStandardPricebookId(),
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
        CPQ_APIService.load(CPQ_APIService.QUOTE_VALIDATOR, null, quote);
        Test.stopTest();
    }
    @isTest
    static void test_addproduct(){
        Product2 product = (Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashUniBundleDefaults', true);

        PricebookEntry pbe1 = (PricebookEntry)TestDataFactory.createSObject(new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = product.id),true);
        
        SBQQ__Quote__c q = new SBQQ__Quote__c(
                SBQQ__PricebookId__c = Test.getStandardPricebookId(),
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
        CPQ_ApiDataModels.ProductModel pm = CPQ_APIService.loadProduct(product.Id,Test.getStandardPricebookId(),'AUD');
        quote = CPQ_APIService.addProducts(quote, new List<CPQ_ApiDataModels.ProductModel>{pm});
        CPQ_APIService.validate(quote);
        Test.stopTest();
    }
    @isTest
    static void test_calculate(){
        CPQ_APIService.calculate(new CPQ_ApiDataModels.QuoteModel(), TestCallback.class.toString());
    }

    public class TestCallback implements SBQQ.CalculateCallback{
        private CPQ_ApiDataModels.QuoteModel quoteModel;
        public void callback(String quoteJSON){
            System.debug(quoteJSON);
        }
    }
}