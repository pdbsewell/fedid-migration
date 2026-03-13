/**
 * @description       : Test class for Option Constraint: AI : Set External ID Flow.
 * @author            : jackie.ho@monash.edu
 * @group             : 
 * @last modified on  : 09-06-2025
 * @last modified by  : jackie.ho@monash.edu
**/
@isTest(isParallel=true)
public with sharing class OptionConstraintAISetExternalId_FT {
    @isTest
    static void testSetExternalId() {
        // Given: Create Product Option & Option Constraint
        SBQQ__ProductOption__c prodOption = new SBQQ__ProductOption__c();
        prodOption.SBQQ__Number__c = 1234.00;
        insert prodOption;
        
        SBQQ__OptionConstraint__c optionConstraint = new SBQQ__OptionConstraint__c();
        optionConstraint.SBQQ__ConstrainedOption__c = prodOption.Id;
        
        // When: Insert Option Constraint
        test.startTest();
        insert optionConstraint;
        test.stopTest();

        // Then: Validate External ID
        optionConstraint = [SELECT Id, External_ID__c FROM SBQQ__OptionConstraint__c WHERE Id = :optionConstraint.Id];
        Assert.areNotEqual(optionConstraint.External_ID__c, null, 'External ID not set');
    }
}