/**
 * @description     :   Test class for Product Feature : BI : Set External ID Flow
 * @author          :   Vinothraja
 * @date            :   08-04-2025
 * @group           :   Platforms
 * @revision
 *  08-04-2025 Vinothraja - EPCP-4551 created test class to test the Product Feature : BI : Set External ID Flow
 */ 
@isTest (isParallel = true)
public with sharing class ProductFeatureBISetExternalID_FT {
    @isTest
    static void shouldSetExternalId() {
        // Disable Trigger
        TriggerCommon.disableTrigger('Product2');
        TriggerCommon.disableTrigger('SBQQ__ProductFeature__c');

        // GIVEN
        // Product
        Product2 product = (Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashUniBundleDefaults', true);

        // A test Product Feature 
        SBQQ__ProductFeature__c testProductFeature = new SBQQ__ProductFeature__c(Name = 'Test Product Feature', 
                                                                            SBQQ__ConfiguredSKU__c = product.Id,
                                                                            SBQQ__Number__c = 1,
                                                                            SBQQ__MinOptionCount__c = 1);

        // WHEN
        // A Product Feature is created
        Test.startTest();
            insert testProductFeature;
        Test.stopTest();

        // THEN
        // Verify that the product feature's external id is set
        List<SBQQ__ProductFeature__c> updatedProductFeatures = [SELECT Id, External_Id__c FROM SBQQ__ProductFeature__c WHERE Id = :testProductFeature.Id];
        Assert.areEqual(((Id) UserInfo.getOrganizationId()).to15() + '_' + testProductFeature.Id, updatedProductFeatures[0].External_Id__c);

        // Enable Trigger
        TriggerCommon.enableTrigger('SBQQ__ProductFeature__c');
        TriggerCommon.enableTrigger('Product2');
    }
}