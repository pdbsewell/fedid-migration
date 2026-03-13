/**
 * @Class              : Clause_BS_Update_Clause_Fields_FT.cls
 * @Description        : Test class for for Clause_BS_Update_Clause_Fields before record trigger flow 
 * @Author             : Sachin Shetty
 * @Group              : Test Class
 * @Revision           : 
 * 2025-05-20   Sachin Shetty  Created 
 */
@isTest(isParallel=true)
public class Clause_FC_AS_Update_Clause_Fields_FT {
    
    @testSetup
    static void testDataSetup() {        
        APXT_Redlining__Clause__c clause =  new APXT_Redlining__Clause__c(
            											Name = 'TEST00001',
                                                        Selection_Type__c = 'Auto',
                                                        Active__c = true,
                                                        APXT_Redlining__Text_Rich__c = 'test',
                                                        External_Id__c = 'TEST00001',
                                                        Location_in_Offer__c = 'Course notes' );
        insert clause;
    }

    /*
    * @description: Tests whether Clause Filtering Criteria last update field on the Clause record is updated
    */
    @isTest
    static void testClauseFilteringCriteriaLastUpdatePopulated() {
        // GIVEN - Clause record is created
        List<APXT_Redlining__Clause__c> clauses = [SELECT Id FROM APXT_Redlining__Clause__c WHERE External_Id__c = 'TEST00001'];
        
        // WHEN - Clause Filtering Criteria reord is created
        Clause_Filtering_Criteria__c clauseFilteringCriteria = new Clause_Filtering_Criteria__c(
            															Clause__c = clauses.get(0).Id,
            															Active__c = true,
                                                                        Field__c = 'Application_Course_Preference__r.Course_Code__c',
                                                                        Operator__c = 'contains',
                                                                        Filtered_Value__c = 'MARK1234',
                                                                        Object_Type__c = 'SBQQ__QuoteLine__c'
        															);
        Test.startTest();
        	insert clauseFilteringCriteria;
        Test.stopTest();
        
        clauses = [SELECT Clause_filtering_criteria_last_update__c FROM APXT_Redlining__Clause__c WHERE External_Id__c = 'TEST00001'];

        //THEN - Clause Filtering Criteria Last Update field on the Clause record is populated with current date/time
        Assert.isNotNull(clauses.get(0).Clause_filtering_criteria_last_update__c, 'Clause filtering criteria last update field should have been populated');
    }
}