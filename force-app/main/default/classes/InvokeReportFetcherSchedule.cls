/**
 * @description       : Class to schedule CyberSource callout
 * @author            : Inderpal Dhanoa
 * @group             : Engage
 * @last modified on  : 2021-10-26
 * @last modified by  : Inderpal Dhanoa
 * Modifications Log 
 * Ver   Date         Author            Modification
 * 1.0   2021-10-26 - Inderpal Dhanoa - Added the call to Invoke Report Fetcher Batch
**/
public with sharing class InvokeReportFetcherSchedule implements Schedulable{
    @testVisible
    private String s_reportDeveloperName;

    public InvokeReportFetcherSchedule(String reportDeveloperName){
        this.s_reportDeveloperName = reportDeveloperName;
    }

    public void execute(SchedulableContext sc) {
        InvokeReportFetcherBatch fetcherBatch = new InvokeReportFetcherBatch(s_reportDeveloperName);
        Database.executeBatch(fetcherBatch);
	} 

}