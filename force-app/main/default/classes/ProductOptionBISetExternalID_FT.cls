/**
 * @description :   Test class for Product Option : BI : Set External ID Flow
 * @author      :   Vinothraja
 * @date        :   08-04-2025
 * @group       :   Platforms
 * @revision
 *   08-04-2025 Vinothraja - EPCP-4551 created test class to test the Product Option : BI : Set External ID Flow
 */ 
@isTest (isParallel = true)
public with sharing class ProductOptionBISetExternalID_FT {
    /**
     * @description test setting the external id for a product option
     */
    @isTest
    static void shouldSetExternalId() {
        // Disable Trigger
        TriggerCommon.disableTrigger('Product2');
        TriggerCommon.disableTrigger('SBQQ__ProductOption__c');

        // GIVEN
        // Product
        Product2 product = (Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashUniBundleDefaults', false);
        Product2 optionalProduct = (Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashEnglishBundleDefaults', false);
        insert new List<Product2>{product, optionalProduct};

        // A test Product Option 
        SBQQ__ProductOption__c testProductOption = new SBQQ__ProductOption__c(SBQQ__ConfiguredSKU__c = product.Id, 
                                                                        SBQQ__OptionalSKU__c = optionalProduct.Id,
                                                                        SBQQ__Number__c = 1);

        // WHEN
        // A Product Option is created
        Test.startTest();
            insert testProductOption;
        Test.stopTest();

        // THEN
        // Verify that the product option's external id is set
        List<SBQQ__ProductOption__c> updatedProductOptions = [SELECT Id, External_Id__c FROM SBQQ__ProductOption__c WHERE Id = :testProductOption.Id];
        Assert.areEqual(((Id) UserInfo.getOrganizationId()).to15() + '_' + testProductOption.Id, updatedProductOptions[0].External_Id__c);

        // Enable Trigger
        TriggerCommon.enableTrigger('SBQQ__ProductOption__c');
        TriggerCommon.enableTrigger('Product2');
    }
}