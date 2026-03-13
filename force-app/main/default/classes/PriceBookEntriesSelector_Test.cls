@isTest
public class PriceBookEntriesSelector_Test {
    @testSetup static void setup() {
        //update std price book
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            External_ID__c = 'STD'
        );
        update standardPricebook;
        //add product bundles
        Product2[] bundles = new Product2[0];
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashUniBundleDefaults', false));
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashEnglishBundleDefaults', false));
        insert bundles;
        //create international pricebook "AU_INT"
        Pricebook2 pricebook = (Pricebook2)TestDataFactory.createSObject(new Pricebook2(), true);

        PricebookEntry[] prices = new PricebookEntry[0];
        prices.add((PricebookEntry)TestDataFactory.createSObject(new PricebookEntry(Product2Id = bundles[0].Id, Pricebook2Id = standardPricebook.Id), false));
        prices.add((PricebookEntry)TestDataFactory.createSObject(new PricebookEntry(Product2Id = bundles[1].Id, Pricebook2Id = standardPricebook.Id), false));
        insert prices;

        prices.clear();
        prices.add((PricebookEntry)TestDataFactory.createSObject(new PricebookEntry(Product2Id = bundles[0].Id, Pricebook2Id = pricebook.Id), false));
        prices.add((PricebookEntry)TestDataFactory.createSObject(new PricebookEntry(Product2Id = bundles[1].Id, Pricebook2Id = pricebook.Id), false));
        insert prices;
    }
    @isTest
    public static void test_selectActiveGrantsAndScholarships(){
        System.assert(new PriceBookEntriesSelector().selectById(new Set<Id>{}) != null, 'Run successfully');
    }
    @isTest
    public static void test_selectPricebookEntriesByExternalId(){
        System.assert(new PriceBookEntriesSelector().selectPricebookEntriesByExternalId(new Set<String>{'BUNUNI'}) != null, 'Run successfully');
    }
    @isTest
    public static void test_selectById(){
        System.assert(new PriceBookEntriesSelector().selectById(new Set<Id>{}) != null, 'Run successfully');
    }
    @isTest
    static void test_selectPricebook2ByExtid(){
        System.assert(new PriceBookEntriesSelector().selectPricebook2ByExtid('AU_INT') != null, 'Run successfully');
    }
    @isTest
    static void test_selectByProductId(){
        Set<String> productIds = new Set<String>();
        for (Product2 p : [SELECT Id, External_ID__c FROM Product2 LIMIT 10]){
            productIds.add(p.Id);
        }
        System.assert(new PriceBookEntriesSelector().selectByProductId(Test.getStandardPricebookId(),productIds) != null, 'Run successfully');
    }
    @isTest
    static void test_selectByProduct2ExternalId(){
        Set<String> productIds = new Set<String>();
        for (Product2 p : [SELECT Id, External_ID__c FROM Product2 LIMIT 10]){
            productIds.add(p.External_ID__c);
        }
        System.assert(new PriceBookEntriesSelector().selectByProduct2ExternalId(Test.getStandardPricebookId(),productIds) != null, 'Run successfully');
    }
    
}