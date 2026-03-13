/**
* @author Jasmin Joy Rudio
* @description Apex test class for ClausesSelector class
* @group SF Offers
*
**/
@isTest
private class ClausesSelector_Test {

    private static testMethod void selectAllWithCriteriaBySelectionType() {
        APXT_Redlining__Clause__c clause1 = (APXT_Redlining__Clause__c)TestDataFactory.createSObject(
                                            new APXT_Redlining__Clause__c(
                                                External_Id__c='12345',
                                                APXT_Redlining__Text__c='test course code match',
                                                Location_in_Offer__c='Course notes',
                                                Selection_Type__c = 'Auto'),
                                            true);
        Test.startTest();
            ClausesSelector overrideSelector = new ClausesSelector(false);
            ClausesSelector selector = new ClausesSelector();
            List<APXT_Redlining__Clause__c> clauses = selector.selectById(new Set<Id>{clause1.Id});
            List<APXT_Redlining__Clause__c> autoClauses = selector.selectAllWithCriteriaBySelectionType('Auto');
        Test.stopTest();
        
        System.assert(clauses.size() > 0);
        System.assert(autoClauses.size() > 0);
    }

}