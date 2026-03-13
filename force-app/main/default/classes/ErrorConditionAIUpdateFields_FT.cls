/**
 * @description     :   Test class for Error Condition : AI : Update Fields flow
 * @author          :   Sachin Shetty
 * @date            :   22-05-2025
 * @group           :   Platforms
 * @revision
 *  22-05-2025      Sachin Shetty    - EPCP-4546  created test class to test the Error Condition : AI : Update Fields Flow
 */ 
@isTest (isParallel = true)
public class ErrorConditionAIUpdateFields_FT {
	/**
     * @description test setting the external id for an Error Condition
     */
    @isTest
    static void shouldSetExternalId() {
        // Disable Trigger
        TriggerCommon.disableTrigger('SBQQ__ProductRule__c');

        // GIVEN
        // A test Product Rule 
        SBQQ__ProductRule__c testProductRule = new SBQQ__ProductRule__c(Name = 'Test Product Rule', 
                                                                SBQQ__Type__c = 'Validation', 
                                                                SBQQ__Scope__c = 'Product',
                                                                SBQQ__ConditionsMet__c = 'All',
                                                                SBQQ__EvaluationEvent__c = 'Save',
                                                                SBQQ__ErrorMessage__c = 'Test Error Message');
        insert testProductRule;
        // A test Erorr Condition        
        SBQQ__ErrorCondition__c testErrorConditionRule = new SBQQ__ErrorCondition__c(
            												SBQQ__Rule__c = testProductRule.Id,
        													SBQQ__TestedField__c = 'Unit Price');        

        // WHEN
        // A Configuration Rule is created
        Test.startTest();
            insert testErrorConditionRule;
        Test.stopTest();

        // THEN
        // Verify that the Configuration Rule's external id is set
        List<SBQQ__ErrorCondition__c> updatedErrorConditionRules = [SELECT Id, External_Id__c FROM SBQQ__ErrorCondition__c WHERE Id = :testErrorConditionRule.Id];
        Assert.areEqual(((Id) UserInfo.getOrganizationId()).to15() + '_' + testErrorConditionRule.Id, updatedErrorConditionRules[0].External_Id__c, 'External Id not set');

        // Enable Trigger
        TriggerCommon.enableTrigger('SBQQ__ProductRule__c');
    }
}