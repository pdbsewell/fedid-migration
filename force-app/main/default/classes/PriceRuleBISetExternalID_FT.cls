/**
* @description       : Test class for Price Rule : BI : Set External ID Flow
* @author            : Vinothraja
* @date              : 07-04-2025
* @group             : Platforms
* @revision          :
*  07-04-2025      Vinothraja    - EPCP-4549  created test class to test the Price Rule : BI : Set External ID Flow
*/
@isTest (isParallel = true)
public with sharing class PriceRuleBISetExternalID_FT {

     /**
      * @description test setting the external id for a price rule
    */       
    @isTest
    static void shouldSetExternalId() {
        // Disable Trigger
        TriggerCommon.disableTrigger('SBQQ__PriceRule__c');
        
        // GIVEN
        // A test Price Rule 
        SBQQ__PriceRule__c testPriceRule = new SBQQ__PriceRule__c(Name = 'Test Price Rule');

        // WHEN
        // A Price Rule is created
        Test.startTest();
            insert testPriceRule;
        Test.stopTest();

        // THEN
        // Verify that the price rule's external id is set
        List<SBQQ__PriceRule__c> updatedPriceRules = [SELECT Id, External_Id__c FROM SBQQ__PriceRule__c WHERE Id = :testPriceRule.Id];
        Assert.areEqual(((Id) UserInfo.getOrganizationId()).to15() + '_' + testPriceRule.Id, updatedPriceRules[0].External_Id__c);

        // Enable Trigger
        TriggerCommon.enableTrigger('PriceRule');
    }
}