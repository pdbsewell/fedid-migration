/**
 * @description       : Test class for Product : BI : Set External ID Flow
 * @author            : Vinothraja
 * @date              : 01-04-2025
 * @group             : Platforms
 * @revision          :
 *  01-04-2025      Vinothraja    - EPCP-4551  created test class to test the Product : BI : Set External ID Flow
 */ 
@isTest (isParallel = true)
public with sharing class ProductBISetExternalID_FT {

    /**
     * @description test setting the external id for a product bundle
     */
    @isTest
    static void shouldSetExternalId() {
        // Disable Trigger
        TriggerCommon.disableTrigger('Product2');

        // GIVEN
        // A test Product 
        Product2 testProduct = new Product2(Name = 'Test Product');

        // WHEN
        // A Product is created
        Test.startTest();
            insert testProduct;
        Test.stopTest();

        // THEN
        // Verify that the product's external id is set
        List<Product2> updatedProducts = [SELECT Id, External_Id__c FROM Product2 WHERE Id = :testProduct.Id];
        Assert.areEqual(((Id) UserInfo.getOrganizationId()).to15() + '_' + testProduct.Id, updatedProducts[0].External_Id__c);

        // Enable Trigger
        TriggerCommon.enableTrigger('Product2');
    }
}