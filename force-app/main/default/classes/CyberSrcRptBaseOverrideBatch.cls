/**
 * @description       : CyberSourceReportBaseOverride to overide the Acend Cybersource Report processing report records
 * @author            : Inderpal Dhanoa
 * @group             : Engage
 * @last modified on  : 2021-10-26
 * @last modified by  : Inderpal Dhanoa
 * Modifications Log 
 * Ver   Date         Author            Modification
 * 1.0   2021-10-26 - Inderpal Dhanoa - Created Class for processing report records 
**/
global virtual inherited sharing class CyberSrcRptBaseOverrideBatch  extends ucinn_ascendv2.ascend_GIFT_CyberSourceReportBaseV2 implements Database.AllowsCallouts{
    global String s_reportName;
    global CyberSrcRptBaseOverrideBatch() { }
    
    /**
     * @description: Reads the report header to determine the ReportName 
     *
     * @param dataList (List<String>): List of report records wth HEADER
     * @author            : Inderpal Dhanoa
     */
    global override void batchConstructor(List<String> dataList) {
        // calculate Reportname based on data list header  
        s_reportName = navigateHeaderForReportName(dataList);
		super.batchConstructor(dataList);
    }
    
    /**
     * @description: Method to parse the records based on the report header  
     *
     * @param dataList (Database.BatchableContext): Database Batchable Std param
     * @param dataList (List<String>): List of report records wthout HEADER
     * @author            : Inderpal Dhanoa
     */
    global override void batchExecute(Database.BatchableContext BC, List<String> csvRow) {
        if (s_reportName == String.valueOf(Label.PaymentBatchSummaryReportName)){
            //logic will process "Payment Summary Batch" report
            PaymentSummaryService.initiateProcessing(csvRow);
        } else {
            // Process the existing default report 
            super.batchExecute(BC, csvRow);
        }
    }

    /**
     * @description: Reads the report header to determine the ReportName 
     *
     * @param dataList (List<String>): List of report records wth HEADER
     * @author            : Inderpal Dhanoa
     */
    private static String navigateHeaderForReportName(List<String> dataList){
        String s_reportName = '';
        String s_header = dataList[0];
        for(String header : s_header.split(',')){
            if(header == String.valueOf(Label.PaymentBatchSummaryReportName)){
                return header;
            }
        }
        return s_reportName;   
    }
}