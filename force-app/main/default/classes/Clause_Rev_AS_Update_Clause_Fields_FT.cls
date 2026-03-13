/**
 * @Class              : Clause_Rev_AS_Update_Clause_Fields_FT.cls
 * @Description        : Test class for for Clause_Revision_AS_Update_Clause_Fields before record trigger flow 
 * @Author             : Sachin Shetty
 * @Group              : Test Class
 * @Revision           : 
 * 2025-05-20   Sachin Shetty  Created 
 */
@isTest(isParallel=true)
public class Clause_Rev_AS_Update_Clause_Fields_FT {
    
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
    * @description: Tests whether Clause version last update field on the Clause record is updated
    */
    @isTest
    static void testClauseVersionLastUpdateUpdated() {
        // GIVEN - Clause record is created
        List<APXT_Redlining__Clause__c> clauses = [SELECT Id, APXT_Redlining__Text__c, Clause_version_last_update__c FROM APXT_Redlining__Clause__c WHERE External_Id__c = 'TEST00001'];
        DateTime beforeUpdate = clauses.get(0).Clause_version_last_update__c;
        
        // WHEN - Clause Revision is updated from the parent
        clauses[0].APXT_Redlining__Text__c = 'test 123';
        DateTime start = System.Now();
        while(System.Now().getTime()< start.getTime()+500){} //Delay
        Test.startTest();
        	update clauses;
        Test.stopTest();
        
        clauses = [SELECT Id, Clause_version_last_update__c FROM APXT_Redlining__Clause__c WHERE External_Id__c = 'TEST00001'];
        DateTime afterUpdate = clauses.get(0).Clause_version_last_update__c;
        	
        //THEN - Clause Version Last Update field on the Clause record is updated with current date/time
        Assert.areNotEqual(beforeUpdate, afterUpdate, 'Clause version last update field should have been updated');
    }
}