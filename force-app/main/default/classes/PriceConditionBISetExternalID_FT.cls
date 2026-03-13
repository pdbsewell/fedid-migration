/**
 * @description      : Test class for Price Condition : BI : Set External ID Flow
 * @author           : Vinothraja
 * @date             : 07-04-2025
 * @group            : Platforms
 * @revision:
 *  07-04-2025      Vinothraja    - EPCP-4549  created test class to test the Price Condition : BI : Set External ID Flow
 */ 
@isTest (isParallel = true)
public with sharing class PriceConditionBISetExternalID_FT {
    /**
     * @description test setting the external id for a price condition
     */
    @isTest
    static void shouldSetExternalId() {
        // Disable Trigger
        TriggerCommon.disableTrigger('SBQQ__PriceRule__c');
        TriggerCommon.disableTrigger('SBQQ__PriceCondition__c');

        // GIVEN
        // A test Price Rule
        SBQQ__PriceRule__c testPriceRule = new SBQQ__PriceRule__c(Name = 'Test Price Rule');
        insert testPriceRule;
        // A test Price Condition 
        SBQQ__PriceCondition__c testPriceCondition = new SBQQ__PriceCondition__c(
                                                            SBQQ__Rule__c = testPriceRule.Id,
                                                            SBQQ__TestedFormula__c = 'Some Formula');

        // WHEN
        // A Price Condition is created
        Test.startTest();
            insert testPriceCondition;
        Test.stopTest();

        // THEN
        // Verify that the price condition's external id is set
        List<SBQQ__PriceCondition__c> updatedPriceConditions = [SELECT Id, External_Id__c FROM SBQQ__PriceCondition__c WHERE Id = :testPriceCondition.Id];
        Assert.areEqual(((Id) UserInfo.getOrganizationId()).to15() + '_' + testPriceCondition.Id, updatedPriceConditions[0].External_Id__c);

        // Enable Trigger
        TriggerCommon.enableTrigger('SBQQ__PriceCondition__c');
        TriggerCommon.enableTrigger('SBQQ__PriceRule__c');
    }
}