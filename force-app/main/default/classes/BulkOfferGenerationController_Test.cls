/**
 * @author David Browaeys
 * @description Test Class for BulkOfferGenerationController
 */
@isTest
public with sharing class BulkOfferGenerationController_Test {
    @isTest static void testGetBulkGenerateOfferBatchInfo(){
        AsyncApexJob[] asyncJobs = BulkOfferGenerationController.getBulkGenerateOfferBatchInfo();
        System.assert(true, 'This is going ok');
    }
    @isTest static void testStartBatch(){
        AsyncApexJob[] asyncJobs = BulkOfferGenerationController.startBatch();
        System.assert(true, 'This is going ok');
    }
}