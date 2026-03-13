/**
 * @description       : Reprocesses Stg Course Fee to that generates cpq / offer required records
 *                       - Products
 *                       - Course Fees
 *                       - Pricebook Entries 
 *                      Based off the following reference data
 *                       - fee category pricebook mapping
 *                       - Org Unit Bundle Mapping
 *                       - Duration Override
 *                      Reusable batch job whenever an org is refreshed
 * @author            : Kristian Vegerano
 * @group             : Batch
 * @last modified on  : 2022-05-16
 * @last modified by  : Kristian Vegerano
 * Modifications Log 
 * Date         Author                  Modification
 * 2022-05-16   Kristian Vegerano       Initial Version
 */
public with sharing class ReprocessStgCourseFeeBatch implements Database.Batchable<sObject>, Schedulable {
    public final String query;
    @TestVisible
    // Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
    private static final String DEFAULT_SCHEDULE = '0 45 1 * * ?'; // at 1:45 am every day

    /**
     * @description Constructor
     */
    public ReprocessStgCourseFeeBatch() {
        query = 'SELECT Id FROM Stg_Course_Fee__c ORDER BY Course_Code__c, Fee_Band_Code_Year__c ASC';
    }

    /**
     * @description Constructor
     */
    public ReprocessStgCourseFeeBatch(String newQuery) {
        if (String.isBlank(newQuery)){
            query = 'SELECT Id FROM Stg_Course_Fee__c ORDER BY Course_Code__c, Fee_Band_Code_Year__c ASC';
        } else {
            query = newQuery;
        }
    }

    /**
     * @description Query all Stg Course Fee records
     * @return query locator with all stg course fee records
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    /**
    * @description Update Stg Course Fee's sync status to resync to restart the process.
    * @param bc 
    * @param scope 
    **/
    public void execute(Database.BatchableContext bc, List<Stg_Course_Fee__c> scope) {
        List<Stg_Course_Fee__c> stgCourseFeeList = new List<Stg_Course_Fee__c>();
        for(Stg_Course_Fee__c stgCourseFee : scope) {
            stgCourseFee.Sync_Status__c = 'RESYNC';
            stgCourseFeeList.add(stgCourseFee);
        }
        if(!stgCourseFeeList.isEmpty()) {
            try {
                Database.SaveResult [] srList = Database.update(stgCourseFeeList, false);
                for (Database.SaveResult sr : srList) {
                    if (!sr.isSuccess()) {
                        LogUtilityException.debug('Error updating Stg Course Fee :: ' + sr.getId());
                    }
                }
            } catch(Exception ex) {
                LogUtilityException.logException(ex);
            }
        }
    }

    /**
    * @description Finish processing, no action.
    * @param bc 
    **/
    public void finish(Database.BatchableContext bc) {
        LogUtilityException.getLimits();
    }

    /**
     * Method implements the Schedulable interface
     * @param  sc as SchedulabeContext
     */
    public void execute(SchedulableContext sc) {
        ReprocessStgCourseFeeBatch batchObj = new ReprocessStgCourseFeeBatch();
        Id batchProcessId = Database.executeBatch(batchObj);
    }

    /**
     * Method to schedule the ReprocessStgCourseFeeBatch with a default cron timing (at 1:00 am everyday)
     */
    public String schedule() {
        String schedule = DEFAULT_SCHEDULE;
        return this.schedule(schedule);
    }
    
    /**
    * Method to schedule the ReprocessStgCourseFeeBatch with a set cron timing
    * @param schedule The schedule as cron String
    */
    public String schedule(String schedule) {
        String jobId;
        String scheduleName = String.valueOf(ReprocessStgCourseFeeBatch.class);
        if (Test.isRunningTest()) {
            scheduleName = 'Testing'+scheduleName;
        }
        List<CronTrigger> ctList = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name =: scheduleName];
        if (ctList.size() <= 0) {
            jobId = System.schedule(scheduleName, schedule, new ReprocessStgCourseFeeBatch());
        }
        return jobId;
    }
    
    /**
    * Method to unschedule the ReprocessStgCourseFeeBatch
    */
    public void unschedule() {
        String scheduleName = String.valueOf(ReprocessStgCourseFeeBatch.class);
        if (Test.isRunningTest()) {
            scheduleName = 'Testing'+scheduleName;
        }
        for ( CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name =: scheduleName] ) {
            System.abortJob(ct.Id);
        }
    }
}