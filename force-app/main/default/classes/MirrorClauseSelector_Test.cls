/**
 * @File Name          : MirrorClauseSelector_Test.cls
 * @Description        : Apex test class for Mirror Clause Selector class
 * @Author             : jasmin.rudio@monash.edu
 * @Group              : Offer
 * @Last Modified By   : jasmin.rudio@monash.edu
 * @Last Modified On   : 5/20/2020, 11:27:06 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    5/20/2020   jasmin.rudio@monash.edu     Initial Version
**/
@isTest
private class MirrorClauseSelector_Test {
    @isTest
    private static void mirrorClauseSelector() {
        Test.startTest();
            MirrorClauseSelector overrideSelector = new MirrorClauseSelector(false);
            MirrorClauseSelector selector = new MirrorClauseSelector();
            List<Mirror_Clause__c> selectActiveClauses = selector.selectActiveClauses();
            List<Mirror_Clause__c> selectById = selector.selectById(new Set<Id>());
            System.assertNotEquals(null, selectById, 'Null not expected');
        Test.stopTest();
    }

}