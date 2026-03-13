/**
 * @description :   Test class for Product Fee : BI : Set External ID Flow
 * @author      :   Vinothraja
 * @date        :   08-04-2025
 * @group       :   Platforms
 * @revision
 *   08-04-2025 Vinothraja - EPCP-4551 created test class to test the Product Fee : BI : Set External ID Flow
 */ 
@isTest (isParallel = true)
public with sharing class ProductFeeBISetExternalID_FT {
    /**
     * @description test setting the external id for a product fee
     */
    @isTest
    static void shouldSetExternalId() {
        // Disable Trigger
        TriggerCommon.disableTrigger('Product_Fee__c');

        // GIVEN
        // A test Product Fee 
        Product_Fee__c testProductFee = new Product_Fee__c(Period_Cover__c = 12, Prov_Amount__c = 1000);

        // WHEN
        // A Product Fee is created
        Test.startTest();
            insert testProductFee;
        Test.stopTest();

        // THEN
        // Verify that the product fee's external id is set
        List<Product_Fee__c> updatedProductFees = [SELECT Id, Migration_Id__c FROM Product_Fee__c WHERE Id = :testProductFee.Id];
        Assert.areEqual(((Id) UserInfo.getOrganizationId()).to15() + '_' + testProductFee.Id, updatedProductFees[0].Migration_Id__c);

        // Enable Trigger
        TriggerCommon.enableTrigger('Product_Fee__c');
    }
}