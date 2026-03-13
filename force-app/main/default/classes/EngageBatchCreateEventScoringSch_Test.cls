/**
 * @author          Charlie Park - UC Innovation
 * @description     For coverage on the EngageBatchCreateEventScoringSch class.
 * 
 * @revision        07/10/2019 - Charlie Park - Initial version
 */

@IsTest(isParallel=false)
public class EngageBatchCreateEventScoringSch_Test {
    @IsTest
    private static void EngageBatchCreateEventScoringSch()
    {
        test.startTest();
        EngageBatchCreateEventScoringSch scheduler;

        //Can use default query.
        scheduler = new EngageBatchCreateEventScoringSch(10);
        String schTime = '0 0 12 * * ?';
        String jobId = System.schedule('EngageBatchCreateEventScoringSch',  schTime, scheduler);
        test.stopTest();

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime, State FROM CronTrigger WHERE Id = :jobId];
        System.assert(ct!=null, 'The scheduled job could not be found.');
        System.assertEquals(0, ct.TimesTriggered, 'Scheduled Apex job is not scheduled to be run.');
    }

    @IsTest
    private static void EngageBatchCreateEventScoringSchWithoutBatchSize()
    {
        test.startTest();
        EngageBatchCreateEventScoringSch scheduler;

        //Can use default query.
        scheduler = new EngageBatchCreateEventScoringSch();        
        String schTime = '0 0 12 * * ?';
        String jobId = System.schedule('EngageBatchCreateEventScoringSch',  schTime, scheduler);        
        test.stopTest();
        
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime, State FROM CronTrigger WHERE Id = :jobId];
        System.assert(ct!=null, 'The scheduled job could not be found.');
        System.assertEquals(0, ct.TimesTriggered, 'Scheduled Apex job is not scheduled to be run.');
    }
    
}