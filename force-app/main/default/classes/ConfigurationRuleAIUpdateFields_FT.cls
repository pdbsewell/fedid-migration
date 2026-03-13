/**
 * @description     :   Test class for Configuration Rule : AI : Update Fields flow
 * @author          :   Sachin Shetty
 * @date            :   22-05-2025
 * @group           :   Platforms
 * @revision
 *  22-05-2025      Sachin Shetty    - EPCP-4492  created test class to test the Configuration Rule : AI : Update Fields Flow
 */ 
@isTest (isParallel = true)
public class ConfigurationRuleAIUpdateFields_FT {
	/**
     * @description test setting the external id for a product action
     */
    @isTest
    static void shouldSetExternalId() {
        // Disable Trigger
        TriggerCommon.disableTrigger('SBQQ__ConfigurationRule__c');
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
        // A test Configuration Rule 
        SBQQ__ConfigurationRule__c testConfigurationRule = new SBQQ__ConfigurationRule__c(SBQQ__ProductRule__c = testProductRule.Id);

        // WHEN
        // A Configuration Rule is created
        Test.startTest();
            insert testConfigurationRule;
        Test.stopTest();

        // THEN
        // Verify that the Configuration Rule's external id is set
        List<SBQQ__ConfigurationRule__c> updatedConfigurationRules = [SELECT Id, External_Id__c FROM SBQQ__ConfigurationRule__c WHERE Id = :testConfigurationRule.Id];
        Assert.areEqual(((Id) UserInfo.getOrganizationId()).to15() + '_' + testConfigurationRule.Id, updatedConfigurationRules[0].External_Id__c, 'External Id not set');

        // Enable Trigger
        TriggerCommon.enableTrigger('SBQQ__ProductRule__c');
        TriggerCommon.enableTrigger('SBQQ__ConfigurationRule__c');
    }
}