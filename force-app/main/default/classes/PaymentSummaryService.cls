/**
 * @description       : PaymentSummaryService to parse report records
 * @author            : Inderpal Dhanoa
 * @group             : Engage
 * @last modified on  : 2021-10-26
 * @last modified by  : Inderpal Dhanoa
 * Modifications Log 
 * Ver   Date         Author            Modification
 * 1.3   2023-01-03 - Inderpal Dhanoa - Added provising considering the Charge Id PENGAGE-2603 
 * 1.2   2022-11-25 - Inderpal Dhanoa - Added provising for fixing Exception Log PENGAGE-2591 
 * 1.1   2022-11-22 - Inderpal Dhanoa - Added provising for registring Pymetn Request date PENGAGE-2577 
 * 1.0   2022-10-26 - Inderpal Dhanoa - Created Class for processing report records 
**/
public with sharing class PaymentSummaryService {

    /**
     * @description: Reads the report header to determine the ReportName 
     *
     * @param dataList (List<String>): List of report records wth HEADER
     * @author            : Inderpal Dhanoa
     */
    public static void initiateProcessing(List<String> csvRow){
        try{
            List<ReportWrapper> settledPayments = parseReport(csvRow);
            processRecords(settledPayments);
        }catch(Exception ex){
            LogUtilityException.LogException(ex);
        }
    }

    /**
     * @description: Reads the report rows and creates a wrapper 
     *
     * @param dataList (List<String>): List of report records wthout HEADER
     * @author            : Inderpal Dhanoa
     */
    public static List<ReportWrapper> parseReport(List<String> csvRow){
        List<ReportWrapper> l_reportsRows = new List<ReportWrapper>();
        ReportWrapper reportRow;
        List<String> columnValues;
        // Incoming format --- RequestID,RequestDate,MerchantID,BatchID,BatchDate,Status,LocalizedRequestDate
        for(Integer i = 0 ; i < csvRow.size() ; i++){
            columnValues = csvRow[i].split(',');
            reportRow = new ReportWrapper();
            for(Integer j = 0 ; j < columnValues.size() ; j++){
                switch on j {
                    when 0 {
                        reportRow.RequestID = columnValues[j];
                    }
                    when 1 {
                        reportRow.RequestDate = columnValues[j];
                    }
                    when 2 {
                        reportRow.MerchantID = columnValues[j];
                    }
                    when 3 {
                        reportRow.BatchID = columnValues[j];
                    }
                    when 4 {
                        reportRow.BatchDate = columnValues[j];        
                    }
                    when 5 {
                        reportRow.Status = columnValues[j];
                    }
                    when 6 {
                        reportRow.LocalizedRequestDate = columnValues[j];
                    }
                }
            }
            l_reportsRows.add(reportRow);
        }
        return l_reportsRows;
    }

    /**
     * @description: Reads the wrapper rows and updates Payment recds, RTV2 recds and Exception Log recds 
     *
     * @param dataList (List<String>): List of report records wthout HEADER
     * @author            : Inderpal Dhanoa
     */
    public static void processRecords(List<ReportWrapper> settledPayments){
        try{
            Map<String, ReportWrapper> m_settledRequests = new Map<String, ReportWrapper>();
            Map<String, ucinn_ascendv2__Payment__c> m_settledPaymentRecords = new Map<String, ucinn_ascendv2__Payment__c>();
            Map<String, ucinn_ascendv2__Review_Transaction_v2__c> m_settledReviewTransactionRecords = new Map<String, ucinn_ascendv2__Review_Transaction_v2__c>();
            ReportWrapper linkedPaymnt, unsettledPaymnt;
            String s_reqId, s_unsettledPaymntDetails;
            for(ReportWrapper settledPayment : settledPayments){
                m_settledRequests.put(settledPayment.RequestID, settledPayment);
            }
    
            // Check if settled payment's transaction Id exist in Payment Object otherwise 
            // Check if settled payment's transaction Id exist in Review Transaction otherswise Log an error
            List<ucinn_ascendv2__Payment__c> l_paymnts =    [SELECT Id , Payment_Settlement_Date__c, Payment_settled__c, ucinn_ascendv2__Charge_Request_ID__c, Batch_Id__c, ucinn_ascendv2__Transaction_ID__c, ucinn_ascendv2__Designation_Detail__r.ucinn_ascendv2__Opportunity__r.StageName,ucinn_ascendv2__Designation_Detail__r.ucinn_ascendv2__Opportunity__r.ucinn_ascendv2__Adjusted_Gift__c  
                                                            FROM ucinn_ascendv2__Payment__c 
                                                            WHERE (ucinn_ascendv2__Transaction_ID__c IN : m_settledRequests.keyset() OR ucinn_ascendv2__Charge_Request_ID__c IN :m_settledRequests.keyset())
                                                            AND Payment_Settlement_Date__c = null
                                                            AND (ucinn_ascendv2__Designation_Detail__r.ucinn_ascendv2__Opportunity__r.StageName != 'Adjusted' OR ucinn_ascendv2__Designation_Detail__r.ucinn_ascendv2__Opportunity__r.ucinn_ascendv2__Adjusted_Gift__c != null)];
            // Update the settled payment info on the payment records 
            for(ucinn_ascendv2__Payment__c paymnt : l_paymnts){ 
                s_reqId = String.isNotBlank(paymnt.ucinn_ascendv2__Transaction_ID__c) ? paymnt.ucinn_ascendv2__Transaction_ID__c : paymnt.ucinn_ascendv2__Charge_Request_ID__c; 
                if(m_settledRequests.containsKey(s_reqId)){
                    linkedPaymnt = m_settledRequests.get(s_reqId);
                    paymnt.Payment_Settlement_Date__c = convertLocalTime(linkedPaymnt.BatchDate);
                    paymnt.Payment_Request_Date__c = convertLocalTime(linkedPaymnt.RequestDate);
                    paymnt.Payment_settled__c = true;
                    paymnt.Batch_Id__c = linkedPaymnt.BatchID;
                    m_settledPaymentRecords.put(s_reqId, paymnt); 
                }else{
                    // Missing Request Id from CYB
                    logUtilityException.addLogEvent('SAP Payments processed ', 'SAP Payment ID not mapped', JSON.serializePretty(s_reqId) , 'PaymentSummaryService Exceptn Logs');
                }                  
            }
    
            // Update the settled payment info on the review transaction records 
            List<ucinn_ascendv2__Review_Transaction_v2__c> l_reviewRecds  = [SELECT Id, Payment_Settlement_Date__c, Payment_settled__c, Batch_Id__c, ucinn_ascendv2__Transaction_ID__c  
                                                                            FROM ucinn_ascendv2__Review_Transaction_v2__c 
                                                                            WHERE ucinn_ascendv2__Transaction_ID__c IN : m_settledRequests.keyset() 
                                                                            AND ucinn_ascendv2__Status__c != 'Posted'
                                                                            AND Payment_Settlement_Date__c = null];
            // Update the settled payment info on the review transaction records 
            for(ucinn_ascendv2__Review_Transaction_v2__c reviewRecd : l_reviewRecds){
                linkedPaymnt = m_settledRequests.get(reviewRecd.ucinn_ascendv2__Transaction_ID__c);
                reviewRecd.Payment_Settlement_Date__c = convertLocalTime(linkedPaymnt.BatchDate);
                reviewRecd.Payment_Request_Date__c = convertLocalTime(linkedPaymnt.RequestDate);
                reviewRecd.Payment_settled__c = true;
                reviewRecd.Batch_Id__c = linkedPaymnt.BatchID; 
                m_settledReviewTransactionRecords.put(reviewRecd.ucinn_ascendv2__Transaction_ID__c, reviewRecd);
            }
    
            // update the payment records
            if(!l_paymnts.isEmpty()){
                Database.SaveResult[] lsr = Database.update(l_paymnts,false);
                for(Integer i=0; i<l_paymnts.size(); i++){
                    for(Database.SaveResult sr : lsr){
                        if(!sr.isSuccess()){
                            // Get the first save result error
                            Database.Error err = sr.getErrors()[0];
                            logUtilityException.addLogEvent('Update on ucinn_ascendv2__Payment__c failed for PaymentStatusBatch processRecords', l_paymnts[i], err, 'PaymentStatusBatch Update Payment');
                        }
                    }
                }
            }

            // update the review transaction records
            if(!l_reviewRecds.isEmpty()){
                Database.SaveResult[] lsr = Database.update(l_reviewRecds,false);
                for(Integer i = 0; i< l_reviewRecds.size(); i++){
                    for(Database.SaveResult sr : lsr){
                        if(!sr.isSuccess()){
                            // Get the first save result error
                            Database.Error err = sr.getErrors()[0];
                            logUtilityException.addLogEvent('Update on ucinn_ascendv2__Review_Transaction_v2__c failed for PaymentStatusBatch processRecords', l_reviewRecds[i], err, 'PaymentStatusBatch Update RTv2');
                        }
                    }
                }
            }
    
            // capture all payments in SAP which are not present on Review Transaction or Payment
            List<String> l_unmappedPayments = new List<String>();
            for(String paymntIdFromSAP : m_settledRequests.keySet()){
                if(!m_settledReviewTransactionRecords.containsKey(paymntIdFromSAP) && !m_settledPaymentRecords.containsKey(paymntIdFromSAP)){
                    unsettledPaymnt = m_settledRequests.get(paymntIdFromSAP);
                    s_unsettledPaymntDetails = 'Request Id : ' + unsettledPaymnt.RequestID + ' BatchID Id : ' + unsettledPaymnt.BatchID + ' Settlement Date : ' + unsettledPaymnt.BatchDate + '\n';
                    l_unmappedPayments.add(s_unsettledPaymntDetails);                    
                }
            }
            if(!l_unmappedPayments.isEmpty()){
                logUtilityException.addLogEvent('SAP Payments processed ', 'SAP Payment ID not mapped', JSON.serializePretty(l_unmappedPayments) , 'PaymentSummaryService Exceptn Logs');
            }
            LogUtilityException.publishAll();
        }catch(Exception ex){
            LogUtilityException.logException(ex,'PaymentSummaryService processRecords');
        }

    }

    /**
     * @description: converts String Date time into Local Datetime datatype 
     *
     * @param s_DateTime (String): String of DateTime
     * @author            : Inderpal Dhanoa
     */
    private static DateTime convertLocalTime(String s_DateTime){
        s_DateTime = s_DateTime.replace('T',' ');
        TimeZone timezne = UserInfo.getTimeZone();
        DateTime dt = Datetime.valueOf(s_DateTime.replace('T',' '));
        return dt.addSeconds((timezne.getOffset(dt)/1000));
    }

    public class ReportWrapper{         
        // RequestID,RequestDate,MerchantID,BatchID,BatchDate,Status,LocalizedRequestDate
        @AuraEnabled
        public String RequestID;
        @AuraEnabled
        public String RequestDate;
        @AuraEnabled
        public String MerchantID;
        @AuraEnabled
        public String BatchID;
        @AuraEnabled
        public String BatchDate;
        @AuraEnabled
        public String Status;
        @AuraEnabled
        public String LocalizedRequestDate;
    }
}