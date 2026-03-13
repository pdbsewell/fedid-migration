/*
 * @author          Shalini Mendu
 * @date			23/03/2020
 * @group			Test
 * @description     Test of scheduler class
 * @revision         
 *                  23/03/2020 - Stefan Scheit - Replaced (unnecessary) exception log record entry with a standard debug method
 * 					08/05/2019 - Shalini Mendu - Initial version	
 */
@isTest(isParallel=false)
public class PurgeRecordsSchd_Test {
    @isTest
    public static void testPurgeRecs() {
        Test.startTest();
        String jobId = System.schedule('One Time Pr',  '00 54 12 8 5 ?', new PurgeRecordsSchd());
        Test.stopTest();
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime, State FROM CronTrigger WHERE Id = :jobId];
        Assert.isTrue(ct!=null, 'The scheduled job could not be found.');
        Assert.areEqual(0, ct.TimesTriggered, 'Scheduled Apex job is not scheduled to be run.');
    }
}