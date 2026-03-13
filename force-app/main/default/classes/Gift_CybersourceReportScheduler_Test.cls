/**
 * @author          Shalini Mendu
 * @description     Test coverage for class Gift_CybersourceReportScheduler
 **/
@isTest//(isParallel=true) In parallel Apex tests, DML operations aren't permitted on this type of object: CronJobDetail
private class Gift_CybersourceReportScheduler_Test {
    @isTest(SeeAllData=false)
    static void testSetAssetBatchSchedule() {
        string scheduleTime = '0 0 0 * * ?';
        string jobId = System.schedule('TEST Gift_CybersourceReportScheduler', scheduleTime, new Gift_CybersourceReportScheduler());
        DateTime nextFire = DateTime.newInstanceGmt(System.today().addDays(1), Time.newInstance(0,0,0,0));

        Test.startTest();

        Gift_CybersourceReportScheduler bc = new Gift_CybersourceReportScheduler();
        Database.executeBatch(bc);

        Test.stopTest();

        //track scheduled trigger with CronTrigger
        CronTrigger ct = [SELECT id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];

        System.assertEquals(scheduleTime, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals(string.valueOfGmt(nextFire), string.valueOf(ct.NextFireTime));
    }
}