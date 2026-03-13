/*******************************************************************************
* @author       Russell Cadapan
* @date         30/04/2020
* @description  Managed Package License Scanner Scheduler Test
* @revision     1.0
*******************************************************************************/

@IsTest(IsParallel=false)
private class LicenseScannerScheduler_Test {
    @IsTest
    static void scheduler_test() {

        Test.startTest();
        String jobId = System.schedule('License Monitoring Job',  '00 54 12 8 5 ?', new LicenseScannerScheduler());
        Test.stopTest();
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime, State FROM CronTrigger WHERE Id = :jobId];
        System.assert(ct!=null, 'The scheduled job could not be found.');


    }
}