/**
 * @author      Sachin Shetty
 * @description Scheduler class for DCAStatsAndMarkProcessBatch
 * @group       Schedulable
 * @testclass   DCAStatsAndMarkProcessSchedule_Test.cls
 * @revision    2023-08-01 - Sachin Shetty - Created
 *              
**/
public class DCAStatsAndMarkProcessSchedule implements Schedulable {

    public static final String DEFAULT_SCHEDULE = '0 0 1 * * ?'; 				// at 1 AM every day

    /**
     * Method implements the Schedulable interface
     * @param  sc as SchedulabeContext
     */
	public void execute(SchedulableContext sc) {
		DCAStatsAndMarkProcessBatch batchClass = new DCAStatsAndMarkProcessBatch();
		database.executebatch(batchClass, 1000);
	}    

    /**
     * Method to schedule the DCAStatsAndMarkProcessBatch with a default cron timing (at 1:00 am)
     */
    public String schedule() {
        String schedule = DEFAULT_SCHEDULE;
        return this.schedule(schedule);
    }

    /**
    * Method to schedule the DCAStatsAndMarkProcessSchedule with a set cron timing
    * @param schedule The schedule as cron String
    */
    public String schedule(String schedule) {
        DCAStatsAndMarkProcessSchedule myBatch = new DCAStatsAndMarkProcessSchedule();
        String scheduleName = String.valueOf(DCAStatsAndMarkProcessSchedule.class);
        
        if (Test.isRunningTest()) {
            scheduleName = 'Testing '+scheduleName;
        }
        String jobId = System.schedule(scheduleName, schedule, myBatch);
        return jobId;
    }

    /**
    * Method to unschedule the DCAStatsAndMarkProcessSchedule
    */
    public void unschedule() {
        String scheduleName = String.valueOf(DCAStatsAndMarkProcessSchedule.class);
        if (Test.isRunningTest()) {
            scheduleName = 'Testing '+scheduleName;
        }
        for ( CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name =: scheduleName] ) {
            System.abortJob(ct.Id);
        }
    }
}