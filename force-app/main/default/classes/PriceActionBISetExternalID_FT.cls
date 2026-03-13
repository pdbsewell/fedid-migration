/**
 * @description : Test class for Price Action : BI : Set External ID Flow
 * @author      : Vinothraja
 * @date        : 07-04-2025
 * @group       : Platforms
 * @revision    :
 *  07-04-2025      Vinothraja    - EPCP-4549  created test class to test the Price Action : BI : Set External ID Flow
 */ 
@isTest (isParallel = true)
public with sharing class PriceActionBISetExternalID_FT {
    /**
     * @description test setting the external id for a price action
     */       
    @isTest
    static void shouldSetExternalId() {
        // Disable Trigger
        TriggerCommon.disableTrigger('SBQQ__PriceAction__c');
        TriggerCommon.disableTrigger('SBQQ__PriceRule__c');
        
        // GIVEN
        // A test Price Rule 
        SBQQ__PriceRule__c testPriceRule = new SBQQ__PriceRule__c(Name = 'Test Price Rule');
        insert testPriceRule;
        // A test Price Action 
        SBQQ__PriceAction__c testPriceAction = new SBQQ__PriceAction__c(SBQQ__Rule__c = testPriceRule.Id);

        // WHEN
        // A Price Action is created
        Test.startTest();
            insert testPriceAction;
        Test.stopTest();

        // THEN
        // Verify that the price action's external id is set
        List<SBQQ__PriceAction__c> updatedPriceActions = [SELECT Id, External_Id__c FROM SBQQ__PriceAction__c WHERE Id = :testPriceAction.Id];
        Assert.areEqual(((Id) UserInfo.getOrganizationId()).to15() + '_' + testPriceAction.Id, updatedPriceActions[0].External_Id__c);

        // Enable Trigger
        TriggerCommon.enableTrigger('SBQQ__PriceRule__c');
        TriggerCommon.enableTrigger('PriceAction');
    }
}