@isTest(isParallel=true)
public with sharing class OfferManualClauseService_Test {
    @isTest static void test_manualAssociatedClause(){
        APXT_Redlining__Clause__c clause = (APXT_Redlining__Clause__c) TestDataFactory.createSObject(new APXT_Redlining__Clause__c(), true);
    
        SBQQ.TriggerControl.disable();
        TriggerCommon.disableTrigger('Application_Course_Preference__c');
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        TriggerCommon.disableTrigger('SBQQ__QuoteLine__c');

        Application_Course_Preference__c acp = (Application_Course_Preference__c)TestDataFactory.createSObject(new Application_Course_Preference__c(), true);

        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(),true);

        SBQQ__QuoteLine__c ql = (SBQQ__QuoteLine__c) TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote1.Id, Application_Course_Preference__c = acp.Id), true);     
        ql.SBQQ__RequiredBy__c = ql.Id;

        Associated_Clause__c[] manualClauses = new Associated_Clause__c[]{
             new Associated_Clause__c(
                 Clause__c = clause.Id,
                 ACP__c = acp.Id
             )
         };
         OfferManualClauseService handler = new OfferManualClauseService(manualClauses, quote1, new SBQQ__QuoteLine__c[]{ql}).execute();
         System.assert(handler.managedClausesToLink.isEmpty() == false, 'Should have at least one managed clause to create');
         Boolean result = handler.commitAll();
         System.assert(result == false);
    }    
}