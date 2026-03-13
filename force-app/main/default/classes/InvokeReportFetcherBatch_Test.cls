/**
 * @description       : Test class for InvokeReportFetcherBatch
 * @author            : Inderpal Dhanoa
 * @group             : Engage
 * @last modified on  : 2022-10-26
 * @last modified by  : Inderpal Dhanoa
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2022-10-26 - Inderpal Dhanoa - Added test for SyncHierarchyLevel from Account to Account
**/
@isTest// (isParallel=true)Insert failed. First exception on row 0; first error: CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY, SBQQ.OpportunityBefore: execution of BeforeInsert caused by:
public class InvokeReportFetcherBatch_Test {

    /*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         26.Oct.2022
     * @description  Tests regarding to capturing the Batch Job
    *******************************************************************************/ 
	@isTest 
    static void testInvokeReportFetcherBatch() {

        /* GIVEN */
        // WHEN : we schedule the Batch to run for a Report 

        test.startTest();
        InvokeReportFetcherBatch fetcherBatch = new InvokeReportFetcherBatch('Cybersource_Payment_Summary');
        Id batchId = Database.executeBatch(fetcherBatch);
        test.stopTest();

        // THEN : The Batch job should be scheduled 
        AsyncApexJob batchJob = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors FROM AsyncApexJob WHERE ID = :batchId];
        System.assertEquals(true, batchJob!=null, 'Asynchronous Apex job was not created.');
        System.assertEquals(0, batchJob.NumberOfErrors, 'Asynchronous Apex job executed with errors');

    }
}