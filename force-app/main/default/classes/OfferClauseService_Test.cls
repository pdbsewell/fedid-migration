@isTest
public with sharing class OfferClauseService_Test {
    @testSetup static void setup() {
        APXT_Redlining__Clause__c clause = (APXT_Redlining__Clause__c) TestDataFactory.createSObject(new APXT_Redlining__Clause__c(), true);
        TestDataFactory.createSObject(new Clause_Filtering_Criteria__c(Clause__c = clause.Id), 'TestDataFactorySettings.ClauseFilteringCriteriaForContainsDefaults', true);

        SBQQ.TriggerControl.disable();
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        TriggerCommon.disableTrigger('SBQQ__QuoteLine__c');
        QuoteTriggerHandler.lockUserCreation = true;
        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(),true);
        
        TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote1.Id), true);
        SBQQ__QuoteLine__c line = (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.Id, Expiry_Date__c = Date.today().addDays(15)), true);
    }
    @isTest 
    private static void test_execute(){
        SBQQ__Quote__c quote1 = [SELECT Id FROM SBQQ__Quote__c];
        SBQQ__QuoteLine__c[] quoteLines = new QuoteLinesSelector().selectByIdWithQuoteLines(new Set<Id>{quote1.Id});
        OfferClauseService handler = new OfferClauseService(quoteLines);
        handler.execute();
    }
    @isTest 
    private static void test_error(){
        SBQQ__Quote__c quote1 = [SELECT Id FROM SBQQ__Quote__c];
        SBQQ__QuoteLine__c[] quoteLines = new QuoteLinesSelector().selectByIdWithQuoteLines(new Set<Id>{quote1.Id});
        OfferClauseService handler = new OfferClauseService(quoteLines);
        handler.sendQuoteToTechError(quoteLines[0],'Hello World Error');
        handler.commitAll();
    }
    @isTest     
    private static void test_evaluateClause(){
        APXT_Redlining__Clause__c clause = [SELECT Id, Object_Level__c, Clause_Review_Required__c, Always_Display__c, APXT_Redlining__Text__c, APXT_Redlining__Latest_Revision__c, (SELECT Field__c, Filtered_Value__c, Object_Type__c, Operator__c from Filtering_Criteria__r) FROM APXT_Redlining__Clause__c LIMIT 1];
        SBQQ__Quote__c quote1 = [SELECT Id FROM SBQQ__Quote__c];
        SBQQ__QuoteLine__c[] quoteLines = new QuoteLinesSelector().selectByIdWithQuoteLines(new Set<Id>{quote1.Id});
        OfferClauseService handler = new OfferClauseService(quoteLines);
        handler.evaluateClause(clause,quoteLines[0]);
        clause.Always_Display__c = true;
        handler.evaluateClause(clause,quoteLines[0]);
        handler.evaluateClauseCriteria(clause.Filtering_Criteria__r,quoteLines[0]);
        
		clause.Filtering_Criteria__r[0].Id = null;
        System.assert(handler.evaluateClauseCriteria(clause.Filtering_Criteria__r,quoteLines[0]) == false,'this shoudl cause a exception and return false');
    }
}