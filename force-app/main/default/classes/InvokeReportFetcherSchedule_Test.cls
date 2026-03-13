/**
 * @description       : Test class for InvokeReportFetcherSchedule
 * @author            : Inderpal Dhanoa
 * @group             : Engage
 * @last modified on  : 2021-10-26
 * @last modified by  : Inderpal Dhanoa
 * Modifications Log 
 * Ver   Date         Author            Modification
 * 1.0   2021-10-26 - Inderpal Dhanoa - Added test for checking schedule
**/
@isTest// (isParallel=true)  In parallel Apex tests, DML operations aren't permitted on this type of object: CronJobDetail
public class InvokeReportFetcherSchedule_Test {

    /*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         26.Oct.2022
     * @description  Tests regarding to capturing the Schedule Job
    *******************************************************************************/ 
    @isTest
    static void execute_test(){
        // GIVEN a report is to be extracted

        // WHEN the scheduler is scheduled
        Test.startTest();
        InvokeReportFetcherSchedule archiveScheduledBatch = new InvokeReportFetcherSchedule('Cybersource_Payment_Summary');
        System.schedule('Test report fetcher','0 0 23 * * ?', archiveScheduledBatch);
        Test.stopTest();

        // THEN the job should be scheduled for an execution
        System.assert([select id , JobType,CompletedDate from AsyncApexJob where CompletedDate=null].size()>0);
    }
}