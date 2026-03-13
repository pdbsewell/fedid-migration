/**
 * @description       : Class to set the retry flag on Automated process Logs for CYB callouts to be re-initiated
 * @author            : Inderpal Dhanoa
 * @group             : Engage
 * @last modified on  : 2023-01-23
 * @last modified by  : Inderpal Dhanoa
 * Modifications Log 
 * Ver   Date         Author            Modification
 * 1.0   2023-01-23 - Inderpal Dhanoa - Initial Version
**/
public without sharing class ReInitiateFailedCybersourceCallouts {

    /**
     * @description: Reads the Automated Logs for CYB reports that had failed in the past and then succeded in retries, 
     * post that search for the dependent CYB report for that date and enable the retry flag 
     *
     * @param s_failedExternalGatewayAccount (String): Name of the failed CYB report Label
     * @param s_dependentExternalGatewayAccount (String): Name of the dependent CYB report that is to be reinitiated
     * @author            : Inderpal Dhanoa
     */
    public void setRetriesOnAutomatedLogs(String s_failedExternalGatewayAccount, String s_dependentExternalGatewayAccount){
        Integer i_maxPreviousDaysRetries;
        DateTime dt_maxPrevDateTime;
        Date d_reportDate, d_today = date.today();
        Set<Date> s_retryDates = new Set<date>();
        Boolean b_setUnsetRetryFlag;
        List<ucinn_ascendv2__Automated_Process_Log__c> l_pastAutomatedLogs;
        List<ucinn_ascendv2__Automated_Process_Log__c> l_updateAutomatedLogs = new List<ucinn_ascendv2__Automated_Process_Log__c>();
        try{
            List<ucinn_ascendv2__Gift_Processing_External_Pymnt_Gateways__mdt> linkedGateway = [SELECT Id,ucinn_ascendv2__Number_Of_Previous_Failure_Retries__c 
                                                                                            FROM ucinn_ascendv2__Gift_Processing_External_Pymnt_Gateways__mdt
                                                                                            WHERE Label = :s_failedExternalGatewayAccount];
            if(!linkedGateway.isEmpty()){
                if(linkedGateway[0].ucinn_ascendv2__Number_Of_Previous_Failure_Retries__c == null){
                    dt_maxPrevDateTime = d_today.addDays(-5);
                }else{
                    i_maxPreviousDaysRetries = Integer.valueOf(linkedGateway[0].ucinn_ascendv2__Number_Of_Previous_Failure_Retries__c);
                    dt_maxPrevDateTime = d_today.addDays(-i_maxPreviousDaysRetries);
                }
                
                
                // Check if any job has failed in the past and then has succeded in subsequent retries
                l_pastAutomatedLogs = [SELECT Id, CreatedDate, Name, ucinn_ascendv2__Result__c, ucinn_ascendv2__Retry_on_Success__c, ucinn_ascendv2__Report_Date__c,ucinn_ascendv2__External_Payment_Gateway_Account__c 
                                        FROM ucinn_ascendv2__Automated_Process_Log__c
                                        WHERE (ucinn_ascendv2__External_Payment_Gateway_Account__c = :s_failedExternalGatewayAccount OR ucinn_ascendv2__External_Payment_Gateway_Account__c = :s_dependentExternalGatewayAccount)
                                        AND CreatedDate > :dt_maxPrevDateTime
                                        ORDER By CreatedDate ASC];
                // Retry and get all the dates when Jobs failed but were successful on retries
                for(ucinn_ascendv2__Automated_Process_Log__c pastLog : l_pastAutomatedLogs){
                    if(pastLog.ucinn_ascendv2__External_Payment_Gateway_Account__c == s_failedExternalGatewayAccount  
                        && pastLog.ucinn_ascendv2__Result__c == 'Failure' && validateRerun(pastLog.ucinn_ascendv2__Report_Date__c, pastLog.CreatedDate, l_pastAutomatedLogs, s_failedExternalGatewayAccount, s_dependentExternalGatewayAccount)){
                        s_retryDates.add(pastLog.ucinn_ascendv2__Report_Date__c);
                    }
                }
                // Update the entries of the dependent job and set them for retrys
                for(ucinn_ascendv2__Automated_Process_Log__c pastLog : l_pastAutomatedLogs){
                    if(pastLog.ucinn_ascendv2__External_Payment_Gateway_Account__c == s_dependentExternalGatewayAccount && pastLog.ucinn_ascendv2__Result__c == 'Success' && s_retryDates.contains(pastLog.ucinn_ascendv2__Report_Date__c)){
                        // if the dependent job has failed in the ste the retry to true, if the retry Job has already executed then set the Flag to false as no more retries are needed
                        b_setUnsetRetryFlag = pastLog.ucinn_ascendv2__Retry_on_Success__c ? false : true;
                        l_updateAutomatedLogs.add(new ucinn_ascendv2__Automated_Process_Log__c(Id = pastLog.Id, ucinn_ascendv2__Retry_on_Success__c = b_setUnsetRetryFlag));
                        s_retryDates.remove(pastLog.ucinn_ascendv2__Report_Date__c);
                    }
                }
                if(!l_updateAutomatedLogs.isEmpty()){
                    update l_updateAutomatedLogs;
                }
            }
        }catch(Exception ex){
            logUtilityException.addLogEvent('setRetriesOnAutomatedLogs', 'setRetriesOnAutomatedLogs', JSON.serializePretty(l_pastAutomatedLogs) , 'SetRetriesOnAutomatedLogs Exceptn Logs');
        }        
    }   

    /**
     * @description: Reads the Automated Logs for CYB reports that had failed in the past and then succeded in retries
     *
     * @param d_reportDate (Date): Date of the failed CYB report Label
     * @param failedReportCreatedDate (DateTime): DateTime of the created Date of the failed CYB report
     * @param l_pastAutomatedLogs (List<ucinn_ascendv2__Automated_Process_Log__c>) List of the AutomatedProcess Logs
     * @author            : Inderpal Dhanoa
     */
    public Boolean validateRerun(Date d_reportDate, DateTime failedReportCreatedDate, List<ucinn_ascendv2__Automated_Process_Log__c> l_pastAutomatedLogs, String s_failedExternalGatewayAccount, String s_dependentExternalGatewayAccount){
        // Check if the same day's depenedent report failed, then Ascend OOB behaviour will trigger the retry
        for(ucinn_ascendv2__Automated_Process_Log__c pastLog : l_pastAutomatedLogs){
            if(pastLog.ucinn_ascendv2__Result__c == 'Failure' && pastLog.ucinn_ascendv2__Report_Date__c == d_reportDate && pastLog.ucinn_ascendv2__External_Payment_Gateway_Account__c == s_dependentExternalGatewayAccount){
                return false;
            }
        }
        // If Dependent Report on that day has successfully processed then check if the Failed report has RE-processed successfully
        for(ucinn_ascendv2__Automated_Process_Log__c pastLog : l_pastAutomatedLogs){
            if(pastLog.ucinn_ascendv2__Result__c == 'Success' && pastLog.ucinn_ascendv2__Report_Date__c == d_reportDate && 
                pastLog.CreatedDate >= failedReportCreatedDate && pastLog.ucinn_ascendv2__External_Payment_Gateway_Account__c == s_failedExternalGatewayAccount){
                return true;
            }
        }
        return false;
    }
}