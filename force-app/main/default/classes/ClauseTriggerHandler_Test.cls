@isTest(isParallel=true)
public with sharing class ClauseTriggerHandler_Test {
    
    @isTest static void test_clause_upsert(){
        APXT_Redlining__Clause__c clause = (APXT_Redlining__Clause__c) TestDataFactory.createSObject(new APXT_Redlining__Clause__c(Selection_Type__c = 'Manual'), true);
        TestDataFactory.createSObject(new Clause_Filtering_Criteria__c(Clause__c = clause.Id), 'TestDataFactorySettings.ClauseFilteringCriteriaForContainsDefaults', true);
        
        Integer count = [select COUNT() FROM Mirror_Clause__c WHERE External_ID__c =: clause.Id];
        System.assert(count == 1, 'Mirror Clause should be in sync');
        
        clause.Name = 'Test 1';
        update clause;
        count = [select COUNT() from Mirror_Clause__c WHERE External_ID__c =: clause.Id AND Name = 'Test 1'];
        System.assert(count == 1, 'Mirror Clause should be in sync');
    }
    @isTest static void test_clause_delete(){
        APXT_Redlining__Clause__c clause = (APXT_Redlining__Clause__c) TestDataFactory.createSObject(new APXT_Redlining__Clause__c(Selection_Type__c = 'Manual'), true);

        delete clause;
        Integer count = [select COUNT() from Mirror_Clause__c WHERE External_ID__c =: clause.Id];
        System.assert(count == 0, 'Mirror Clause should be deleted');
    }
    @isTest static void test_clause_auto(){
        APXT_Redlining__Clause__c clause = (APXT_Redlining__Clause__c) TestDataFactory.createSObject(new APXT_Redlining__Clause__c(), true);
        Integer count = [select COUNT() FROM Mirror_Clause__c WHERE External_ID__c =: clause.Id];
        System.assert(count == 0, 'No mirror Clause for auto clause');
    }
}