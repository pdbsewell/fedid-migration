@isTest
public class ProductsSelector_Test {
    @testSetup static void setup() {
        //add product bundles
        Product2[] bundles = new Product2[0];
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashUniBundleDefaults', false));
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashEnglishBundleDefaults', false));
        insert bundles;
    }
    @isTest
    public static void test_selectors_2(){
        ProductsSelector.getStandardPricebook();
    }
    @isTest
    public static void test_selectors_3(){
        new ProductsSelector(true).selectProductByExternalId(new Set<String>{'BUNUNI'}, Product2.External_ID__c);
        new ProductsSelector().selectProductByExternalId(new Set<String>{'BUNUNI'}, Product2.External_ID__c);
    }
}