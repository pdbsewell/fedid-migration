/**
 * @author       P.Victoriano
 * @date         05/Nov/2021
 * @description  Reusable Scheduler
 * @revision
 *               05.Nov.21 P.Victoriano - Create Class
 **/
global class UserDeactivateSchd implements Schedulable {
    @TestVisible
    private Boolean hasExecuted = false;
    global void execute(SchedulableContext SC) {
        String className = UserDeactivateBatch.class.getName();
        Integer enqueuedJobs = [SELECT COUNT() FROM AsyncApexJob
                                WHERE JobType = 'BatchApex'
                                                AND Status IN ('Processing','Preparing','Queued')
                                                AND ApexClass.Name =:className];
        //Prevent fro mexecuting if there are pending jobs to execute
        if(enqueuedJobs == 0){
            UserDeactivateBatch bch = new UserDeactivateBatch();
            if(Test.isRunningTest()){
                //Simply Track if this is called
                hasExecuted = true;
            }else{
                Database.executeBatch(bch, 1);
            }
        }
    }

    /**
     * @description createSchedule Creates the CronTrigger for the Schedule
     */
    public static void addSchedule() {
        String className = UserDeactivateBatch.class.getName();
        List<CronTrigger> ctList = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name =: className];
        if (ctList.isEmpty() == true) {
            //Scheduled at 11:59pm
            String sch = '0 59 23 * * ? *';
            String jobID = System.schedule(className, sch, new UserDeactivateSchd());
        }
    }

    /**
     * @description removeSchedule Removes the CronTrigger for the Schedule
     */
    public static void removeSchedule() {
        String className = UserDeactivateBatch.class.getName();
        List<CronTrigger> ctList = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name =: className];
        if (ctList.isEmpty() == false) {
            for (CronTrigger ct:ctList) {
                System.abortJob(ct.Id);
            }
        }
    }
}