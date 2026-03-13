/**
 * @author      Jasmin Joy Rudio
 * @description Test class for BulkDataProcessingSelector class
 * @group       Bulk Data Processing 
 * @revision    13/07/2020 - Jasmin Joy Rudio - Created
 */
@isTest
public with sharing class BulkDataProcessingSelector_Test {
    @isTest
    private static void bdpSelector() {
        Test.startTest();
            BulkDataProcessingSelector overrideSelector = new BulkDataProcessingSelector(false);
            BulkDataProcessingSelector selector = new BulkDataProcessingSelector();
            List<Bulk_Data_Processing__c> selectById = selector.selectById(new Set<Id>());
            List<Bulk_Data_Processing__c> selectByIdOrderByCourseCode = selector.selectByIdOrderByCourseCode(new Set<Id>());
            List<Bulk_Data_Processing__c> selectByIdWithACPDetails = selector.selectByIdWithACPDetails(new Set<Id>());
            Database.QueryLocator selectGenerateOffers = selector.selectGenerateOffers();
        Test.stopTest();
        System.assert(selectById.isEmpty(), 'Id set is empty');
        System.assert(selectByIdOrderByCourseCode.isEmpty(), 'Id set is also empty');
        System.assert(selectGenerateOffers != null);
    }
}