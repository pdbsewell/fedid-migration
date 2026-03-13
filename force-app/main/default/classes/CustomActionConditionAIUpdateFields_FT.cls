/**
 * @description     :   Test class for Custom Action Condition : AI : Update Fields flow
 * @author          :   Sachin Shetty
 * @date            :   22-05-2025
 * @group           :   Platforms
 * @revision
 *  22-05-2025      Sachin Shetty    - EPCP-4518  created test class to test the Custom Action Condition : AI : Update Fields Flow
 */ 
@isTest (isParallel = true)
public class CustomActionConditionAIUpdateFields_FT {
	/**
     * @description test setting the external id for a Custom Action Condition
     */
    @isTest
    static void shouldSetExternalId() {
        // GIVEN
        // A test Custom Action 
        SBQQ__CustomAction__c testCustomAction = new SBQQ__CustomAction__c(Name = 'Test Custom Action',
        													SBQQ__DisplayOrder__c = 1);  
        insert testCustomAction;
        
        // A test Custom Action Condition        
        SBQQ__CustomActionCondition__c testCustomActionCondition = new SBQQ__CustomActionCondition__c(
            												SBQQ__CustomAction__c = testCustomAction.Id);

        // WHEN
        // A Custom Action Condition is created
        Test.startTest();
            insert testCustomActionCondition;
        Test.stopTest();

        // THEN
        // Verify that the Custom Action Condition's external id is set
        List<SBQQ__CustomActionCondition__c> updatedCustomActionConditions = [SELECT Id, External_Id__c FROM SBQQ__CustomActionCondition__c WHERE Id = :testCustomActionCondition.Id];
        Assert.areEqual(((Id) UserInfo.getOrganizationId()).to15() + '_' + testCustomActionCondition.Id, updatedCustomActionConditions.get(0).External_Id__c, 'External Id not set');
    }
    
	/**
     * @description test setting the external id for a Custom Action Condition
     */
    @isTest
    static void shouldNotSetExternalId() {
        // GIVEN
        // A test Custom Action 
        SBQQ__CustomAction__c testCustomAction = new SBQQ__CustomAction__c(Name = 'Test Custom Action',
        													SBQQ__DisplayOrder__c = 1);  
        insert testCustomAction;
        
        // A test Custom Action Condition        
        SBQQ__CustomActionCondition__c testCustomActionCondition = new SBQQ__CustomActionCondition__c(
            												SBQQ__CustomAction__c = testCustomAction.Id,
        													External_Id__c = 'Test External Id');

        // WHEN
        // A Custom Action Condition is created
        Test.startTest();
            insert testCustomActionCondition;
        Test.stopTest();

        // THEN
        // Verify that the Custom Action Condition's external id is set
        List<SBQQ__CustomActionCondition__c> updatedCustomActionConditions = [SELECT Id, External_Id__c FROM SBQQ__CustomActionCondition__c WHERE Id = :testCustomActionCondition.Id];
        Assert.areNotEqual(((Id) UserInfo.getOrganizationId()).to15() + '_' + testCustomActionCondition.Id, updatedCustomActionConditions.get(0).External_Id__c, 'External Id should not have set');
    }
}