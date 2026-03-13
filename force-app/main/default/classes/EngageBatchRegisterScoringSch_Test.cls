/*
 * @author          Matthew Maramot
 * @description     Test class for EngageBatchRegisterScoringSch
 * @history         08/04/2025 - Matthew Maramot - Initial version
*/
@IsTest(isParallel=false) //isParallel DMLOperations on CronJobDetail is not permitted 
public class EngageBatchRegisterScoringSch_Test {
    
    @isTest
    public static void testSchedulingJob() {
        //Create custom setting test record
        Score_Batch_Settings__c scoreSettings = new Score_Batch_Settings__c(Registration_Expiry__c = 12, Registration_Score__c = 20, Registration_Description__c = 'Registered event last 12 months', Premium_Attended_Expiry__c = 36, Premium_Attended_Score__c = 181, Premium_Attended_Description__c = 'Attended Premium Event in Last 3 Years', Attended_Expiry__c = 12,  Attended_Score__c = 51, Attended_Description__c = 'Attended event last 12 months');
        insert scoreSettings;
        
        //GIVEN: We want to schedule the EngageBatchRegisterScoring batch
        EngageBatchRegisterScoringSch scheduler;

        //WHEN: We schedule the batch
        test.startTest();
        scheduler = new EngageBatchRegisterScoringSch();
        String schTime = '0 0 12 * * ?';
        String jobId = System.schedule('Engage Batch Register Scorring',  schTime, scheduler);
        test.stopTest();

        //THEN: It successfully gets scheduled
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime, State FROM CronTrigger WHERE Id = :jobId];
        Assert.areEqual(ct!=null, true, 'The scheduled job could not be found.');
        Assert.areEqual(0, ct.TimesTriggered, 'Scheduled Apex job is not scheduled to be run.');

    }
}