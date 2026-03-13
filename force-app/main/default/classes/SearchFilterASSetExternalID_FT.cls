/**
 * @description : Test class for Search_Filter_AS_Set_External_ID Flow
 * @author      : Vinothraja
 * @date        : 02-06-2025
 * @group       : Platforms
 * @revision    :
 *  02-06-2025      Vinothraja    - EPCP-4552  created test class to test the Search Filter : AS : Set External ID Flow
 */ 
@isTest (isParallel = true)
public with sharing class SearchFilterASSetExternalID_FT {
    /*
    * Test method to verify if the external id is populated correctly
    */
    @isTest
    private static void shouldSetExternalId() {
        // WHEN
        // A Search Filter is created
        SBQQ__SearchFilter__c searchFilter = new SBQQ__SearchFilter__c (SBQQ__TargetObject__c = 'Product', SBQQ__TargetField__c = 'Name', SBQQ__Operator__c = 'equals', SBQQ__DisplayOrder__c = 1);
        Test.startTest();
            insert searchFilter;
        Test.stopTest();

        // THEN
        // Verify that the price action's external id is set
        searchFilter = [SELECT Id, External_Id__c FROM SBQQ__SearchFilter__c WHERE Id = :searchFilter.Id LIMIT 1];
        Assert.areEqual(((Id) UserInfo.getOrganizationId()).to15() + '_' + searchFilter.Id, searchFilter.External_Id__c);
    }
}