/**
 * @description       : Test class for Summary Variable: AI : Update External ID Flow.
 * @author            : jackie.ho@monash.edu
 * @group             : 
 * @last modified on  : 10-06-2025
 * @last modified by  : jackie.ho@monash.edu
**/
@isTest(isParallel=true)
public with sharing class SummaryVariableAIUpdateExternalId_FT {
    @isTest
    static void testUpdateExternalId() {
        // Given: Create a summary variable
        SBQQ__SummaryVariable__c sv = new SBQQ__SummaryVariable__c();
        sv.Name = 'Test Summary Variable';
        
        // When: Insert summary variable
        test.startTest();
        insert sv;
        test.stopTest();

        // Then: Validate external ID
        sv = [SELECT Id, External_Id__c FROM SBQQ__SummaryVariable__c WHERE Id = :sv.Id];
        Assert.areNotEqual(sv.External_Id__c, null, 'External ID not set');
    }
}