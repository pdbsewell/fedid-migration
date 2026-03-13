/**
 * @author David Browaeys
 * @description This controller is use for bulk data offer gen cmp and allow to manage BulkGenerateOfferBatch. 
 * @group Bulk Data Processing
 */
public with sharing class BulkOfferGenerationController {
    /**
     * @description get the last 10 async apex job for BulkGenerateOfferBatch. 
     * @return   return list of async jobs
     */
    @AuraEnabled
    public static AsyncApexJob[] getBulkGenerateOfferBatchInfo(){
        return [SELECT  Id, CreatedDate, CreatedById, JobType, ApexClassId, ApexClass.Name, Status, JobItemsProcessed, 
                        TotalJobItems, NumberOfErrors, CompletedDate, MethodName, ExtendedStatus, ParentJobId, LastProcessed, LastProcessedOffset 
                FROM AsyncApexJob 
                WHERE ApexClass.Name = 'BulkGenerateOfferBatch' 
                ORDER BY CreatedDate DESC LIMIT 10];
    }
    /**
     * @description start BulkGenerateOfferBatch
     * @return   return list of async jobs
     */
    @AuraEnabled
    public static AsyncApexJob[] startBatch(){
        Database.executeBatch(new BulkGenerateOfferBatch(),1);
        return getBulkGenerateOfferBatchInfo();
    }
}