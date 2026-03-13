/**
 * @description       : Test class for CyberSrcRptBaseOverrideBatch
 * @author            : Inderpal Dhanoa
 * @group             : Engage
 * @last modified on  : 2022-10-26
 * @last modified by  : Inderpal Dhanoa
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2022-10-26 - Inderpal Dhanoa - Added test for CyberSrcRptBaseOverrideBatch test
**/
@isTest //(isParallel=true)
public class CyberSrcRptBaseOverrideBatch_Test {
    
    /*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         26.Oct.2022
     * @description  Tests regarding to capturing the Schedule Job
    *******************************************************************************/ 
    @isTest
    static void batch_test(){
        List<String> csvRow = new List<String>();
        csvRow.add('monasherda,PaymentBatchSummary,PaymentBatchDetail,1.10,2022-10-23T13:00:00Z to 2022-10-24T13:00:00Z,,');
        csvRow.add('RequestID,RequestDate,MerchantID,BatchID,BatchDate,Status,LocalizedRequestDate');
        csvRow.add('6655040243216368003008,2022-10-23T11:44:16Z,monasherda,20342026,2022-10-24T07:11:26Z,BATCHED,2022-10-23T22:44:16+11:00');
        csvRow.add('6655040243216368003009,2022-10-23T11:44:38Z,monasherda,20342026,2022-10-24T07:11:26Z,BATCHED,2022-10-23T22:44:38+11:00');
        csvRow.add('6665254793266190204002,2022-10-23T11:44:39Z,monasherda,20342026,2022-10-24T07:11:26Z,BATCHED,2022-10-23T22:44:39+11:00');
        Database.BatchableContext BC;
        // GIVEN a report is to be extracted

        // WHEN the scheduler is scheduled
        Test.startTest();
        CyberSrcRptBaseOverrideBatch obj = new CyberSrcRptBaseOverrideBatch();
        obj.batchConstructor(csvRow);
        obj.batchExecute(BC, csvRow);
        Test.stopTest();

        // THEN the report name should match with the passed parameter
        system.assertEquals(String.valueOf(Label.PaymentBatchSummaryReportName), obj.s_reportName);
    }
}