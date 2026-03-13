/**
 * @Class              : Clause_BS_Update_Clause_Fields_FT.cls
 * @Description        : Test class for for Clause_BS_Update_Clause_Fields before record trigger flow 
 * @Author             : Sachin Shetty
 * @Group              : Test Class
 * @Revision           : 
 * 2025-05-20   Sachin Shetty  Created 
 */
@isTest(isParallel=true)
public class Clause_BS_Update_Clause_Fields_FT {
    
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
    * @description: Tests whether Clause text last update field is updated
    */
    @isTest
    static void testRecordUpdateDesciptionChange() {
        // GIVEN - Clause record is created
        List<APXT_Redlining__Clause__c> clauses = [SELECT Clause_text_last_update__c, APXT_Redlining__Text__c FROM APXT_Redlining__Clause__c WHERE External_Id__c = 'TEST00001'];

        DateTime beforeUpdate = clauses.get(0).Clause_text_last_update__c;
        
        // WHEN - Text field is updated
        clauses[0].APXT_Redlining__Text__c = 'Test 123';
        Test.startTest();
        	update clauses;
        Test.stopTest();
        
        clauses = [SELECT Clause_text_last_update__c FROM APXT_Redlining__Clause__c WHERE External_Id__c = 'TEST00001'];
        DateTime afterUpdate = clauses.get(0).Clause_text_last_update__c;
        
        
        // THEN - Clause text last update field should be updated
        Assert.areNotEqual(beforeUpdate, afterUpdate, 'Clause text last update field should have been updated');
    }
    
    /*
    * @description: Tests whether Clause text last update field is not updated
    */
    @isTest
    static void testRecordUpdateDesciptionNotUpdated() {
        // GIVEN - Clause record is created
        List<APXT_Redlining__Clause__c> clauses = [SELECT Clause_text_last_update__c, Selection_Type__c FROM APXT_Redlining__Clause__c WHERE External_Id__c = 'TEST00001'];

        DateTime beforeUpdate = clauses.get(0).Clause_text_last_update__c;
        
        // WHEN - A field other than Text field is updated
        clauses[0].Selection_Type__c = 'Manual';
        Test.startTest();
        	update clauses;
        Test.stopTest();
        
        clauses = [SELECT Clause_text_last_update__c FROM APXT_Redlining__Clause__c WHERE External_Id__c = 'TEST00001'];
        DateTime afterUpdate = clauses.get(0).Clause_text_last_update__c;
        
        //THEN - Clause text last update field should not be updated
        Assert.areEqual(beforeUpdate, afterUpdate, 'Clause text last update field should not have been updated');
    }
}