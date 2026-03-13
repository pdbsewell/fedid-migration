/**
 * @description     :   Test class for Product Action : BI : Set External ID Flow
 * @author          :   Vinothraja
 * @date            :   08-04-2025
 * @group           :   Platforms
 * @revision
 *  08-04-2025      Vinothraja    - EPCP-4551  created test class to test the Product : BI : Set External ID Flow
 */ 
@isTest (isParallel = true)
public with sharing class ProductActionBISetExternalID_FT {
    /**
     * @description test setting the external id for a product action
     */
    @isTest
    static void shouldSetExternalId() {
        // Disable Trigger
        TriggerCommon.disableTrigger('SBQQ__ProductAction__c');
        TriggerCommon.disableTrigger('SBQQ__ProductRule__c');

        // GIVEN
        // A test Product Rule 
        SBQQ__ProductRule__c testProductRule = new SBQQ__ProductRule__c(Name = 'Test Product Rule', 
                                                                SBQQ__Type__c = 'Validation', 
                                                                SBQQ__Scope__c = 'Quote',
                                                                SBQQ__ConditionsMet__c = 'All',
                                                                SBQQ__EvaluationEvent__c = 'Save',
                                                                SBQQ__ErrorMessage__c = 'Test Error Message');
        insert testProductRule;
        // A test Product Action 
        SBQQ__ProductAction__c testProductAction = new SBQQ__ProductAction__c(SBQQ__Rule__c = testProductRule.Id);

        // WHEN
        // A Product Action is created
        Test.startTest();
            insert testProductAction;
        Test.stopTest();

        // THEN
        // Verify that the product action's external id is set
        List<SBQQ__ProductAction__c> updatedProductActions = [SELECT Id, External_Id__c FROM SBQQ__ProductAction__c WHERE Id = :testProductAction.Id];
        Assert.areEqual(((Id) UserInfo.getOrganizationId()).to15() + '_' + testProductAction.Id, updatedProductActions[0].External_Id__c);

        // Enable Trigger
        TriggerCommon.enableTrigger('SBQQ__ProductRule__c');
        TriggerCommon.enableTrigger('SBQQ__ProductAction__c');
    }
}