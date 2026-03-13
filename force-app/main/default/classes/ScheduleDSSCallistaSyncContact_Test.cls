/**
 * @author          M. Maramot
 * @description     Test class for ScheduleDSSContactSyncBatch
 * @revision        07/08/2025 - M. Maramot - Initial version
 */
@isTest(isParallel=false) // DML operations aren't permitted for CronJobDetail
public class ScheduleDSSCallistaSyncContact_Test {
    @isTest
    public static void testScheduleBatch()
    {
        // GIVEN: We want to run the batch once a day, MON-FRI
        String cron = '0 0 5 ? * MON-FRI';

        // WHEN: We schedule the batch
        Test.startTest();
        System.schedule('Daily DSS Contact Sync',cron , new ScheduleDSSCallistaSyncContact());
        Test.stopTest();

        //THEN: 
         // Check schedulable is in the job list
        List<AsyncApexJob> jobsScheduled = [SELECT Id, ApexClassID, ApexClass.Name, Status, JobType FROM AsyncApexJob WHERE ApexClass.Name = 'ScheduleDSSCallistaSyncContact' AND JobType = 'ScheduledApex'];
        Assert.areEqual(1,jobsScheduled.size(), 'Expecting one scheduled job');
    }
}