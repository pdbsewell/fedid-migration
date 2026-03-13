/**
 * @description :   Test class for Product Rule : BI : Set External ID Flow
 * @author      :   Vinothraja
 * @date        :   08-04-2025
 * @group       :   Platforms
 * @revision
 *   08-04-2025 Vinothraja - EPCP-4551 created test class to test the Product Rule : BI : Set External ID Flow
 */ 
@isTest (isParallel = true)
public with sharing class ProductRuleBISetExternalID_FT {
    /**
     * @description test setting the external id for a product rule
     */
    @isTest
    static void shouldSetExternalId() {
        // Disable Trigger
        TriggerCommon.disableTrigger('SBQQ__ProductRule__c');

        // GIVEN
        // A test Product Rule 
        SBQQ__ProductRule__c testProductRule = new SBQQ__ProductRule__c(Name = 'Test Product Rule', 
                                                                SBQQ__Type__c = 'Validation', 
                                                                SBQQ__Scope__c = 'Quote',
                                                                SBQQ__ConditionsMet__c = 'All',
                                                                SBQQ__EvaluationEvent__c = 'Save',
                                                                SBQQ__ErrorMessage__c = 'Test Error Message');
        // WHEN
        // A Product Rule is created
        Test.startTest();
            insert testProductRule;
        Test.stopTest();

        // THEN
        // Verify that the product rule's external id is set
        List<SBQQ__ProductRule__c> updatedProductRules = [SELECT Id, External_Id__c FROM SBQQ__ProductRule__c WHERE Id = :testProductRule.Id];
        Assert.areEqual(((Id) UserInfo.getOrganizationId()).to15() + '_' + testProductRule.Id, updatedProductRules[0].External_Id__c);

        // Enable Trigger
        TriggerCommon.enableTrigger('SBQQ__ProductRule__c');
    }
}