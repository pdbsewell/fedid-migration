/**
 * @author      Jasmin Joy Rudio
 * @description Test class for AssociatedClauseSelector class
 * @group       Bulk Data Processing 
 * @revision    22/07/2020 - Jasmin Joy Rudio - Created
 */
@isTest
public with sharing class AssociatedClauseSelector_Test {
    @isTest
    private static void associatedClauseSelector() {
        Test.startTest();
            AssociatedClauseSelector overrideSelector = new AssociatedClauseSelector(false);
            AssociatedClauseSelector selector = new AssociatedClauseSelector();
            List<Associated_Clause__c> selectById = selector.selectById(new Set<Id>());
            List<Associated_Clause__c> selectClausesByParentId = selector.selectClausesByParentId('Offer_Request__c', '');
        Test.stopTest();
        System.assert(selectById.isEmpty(), 'Id set is empty');
        System.assert(selectClausesByParentId.isEmpty(), 'Id set is also empty');
    }
}