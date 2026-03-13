@isTest(isParallel=true)
private class PORTAL_UCIN_CreateDocLinkSchCC_Test {
    @isTest(SeeAllData=false) 
    static void testSetAssetBatchSchedule() {
        string scheduleTime = '0 0 0 * * ?';
        string jobId = System.schedule('TEST PORTAL_UCIN_CreateDocLinkScheduler', scheduleTime, new PORTAL_UCIN_CreateDocLinkScheduler());
        DateTime nextFire = DateTime.newInstanceGmt(System.today().addDays(1), Time.newInstance(0,0,0,0));
        
        //track scheduled trigger with CronTrigger
        CronTrigger ct = [SELECT id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        
        System.assertEquals(scheduleTime, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals(string.valueOfGmt(nextFire), string.valueOf(ct.NextFireTime));
    }
}