/**
 * @description       : Class to be invoked from InvokeReportFetcherSchedule
 * @author            : Inderpal Dhanoa
 * @group             : Engage
 * @last modified on  : 2021-10-26
 * @last modified by  : Inderpal Dhanoa
 * Modifications Log 
 * Ver   Date         Author            Modification
 * 1.0   2021-10-26 - Inderpal Dhanoa - created Batch class for CyberSource callout
**/
public with sharing class InvokeReportFetcherBatch implements Database.Batchable<SObject>, Database.AllowsCallouts{

    private String s_reportDeveloperName;

    public InvokeReportFetcherBatch(String reportDeveloperName){
        this.s_reportDeveloperName = reportDeveloperName;
    }
    public List<Sobject> start(Database.BatchableContext bc) { 
        return [SELECT Id from Account where Name = 'NOID' limit 5];
    }

    public void execute(Database.BatchableContext bc, List<Sobject> settledPayments) {

    }

	/**
     * @description: Reads the custom metadata recd and initiates the CyberSource callout 
     *
     * @param bc (Database.BatchableContext): Batchable Context variable
     * @author            : Inderpal Dhanoa
     */
    public void finish(Database.BatchableContext bc) {
        ucinn_ascendv2__Gift_Processing_External_Pymnt_Gateways__mdt CMT_RECORD = [SELECT Id,Label, ucinn_ascendv2__Automated_Payment_Retry_Maximum__c,
                                                                                    ucinn_ascendv2__Automated_Payment_Retry_Weekdays__c,
                                                                                    ucinn_ascendv2__Credit_Card_Obfuscation__c,
                                                                                    ucinn_ascendv2__Currency_Code__c,
                                                                                    ucinn_ascendv2__Currency_Decimal_Places__c,
                                                                                    ucinn_ascendv2__Daily_Report_Name__c,
                                                                                    ucinn_ascendv2__Email_Reporting__c,
                                                                                    ucinn_ascendv2__Email_Reporting_CC_Recipients__c,
                                                                                    ucinn_ascendv2__Email_Reporting_Primary_Recipient__c,
                                                                                    ucinn_ascendv2__Email_Reporting_ReplyTo_Address__c,
                                                                                    ucinn_ascendv2__Environment_Key__c,
                                                                                    ucinn_ascendv2__Gateway_Named_Credential_Name__c,
                                                                                    ucinn_ascendv2__Is_Preferred_Gateway__c,
                                                                                    ucinn_ascendv2__Is_Retrieve_Orphan_Payments_V2_Enabled__c,
                                                                                    ucinn_ascendv2__Merchant_Defined_Data_Field_Index__c,
                                                                                    ucinn_ascendv2__Merchant_ID__c,
                                                                                    ucinn_ascendv2__Number_Of_Previous_Failure_Retries__c,
                                                                                    ucinn_ascendv2__Payment_Gateway__c,
                                                                                    ucinn_ascendv2__Report_Batch_Hour_Differential__c,
                                                                                    ucinn_ascendv2__Reporting_Batch_Size__c,
                                                                                    ucinn_ascendv2__Reporting_Named_Credential_Name__c,
                                                                                    ucinn_ascendv2__Retry_Failed_Report_Retrieval__c,
                                                                                    ucinn_ascendv2__Review_Transaction_Record_Type__c,
                                                                                    ucinn_ascendv2__Review_Transaction_Record_Type_Namespace__c,
                                                                                    ucinn_ascendv2__Review_Transaction_Record_Type_Prefix__c,
                                                                                    ucinn_ascendv2__Update_Payment_Summary_Batch_Size__c,
                                                                                    ucinn_ascendv2__Use_Reporting_V2__c,
                                                                                    ucinn_ascendv2__WSDL_Version__c
                                                                                    FROM ucinn_ascendv2__Gift_Processing_External_Pymnt_Gateways__mdt  WHERE DeveloperName = :s_reportDeveloperName];
        ucinn_ascendv2.ascend_GIFT_CyberSourceReportFetcher.setCustomMetadataType(CMT_RECORD);
        ucinn_ascendv2.ascend_GIFT_CyberSourceReportFetcher.runReportFetcher();
    }
}