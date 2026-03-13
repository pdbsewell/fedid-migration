/**
 * @author          M. Maramot
 * @description     Test class for ScheduleDSSCallistaSyncBatch
 * @revision        07/08/2025 - M. Maramot - Initial version
 */
@isTest(isParallel=false) // DML operations aren't permitted for CronJobDetail
public class ScheduleDSSCallistaSyncBatch_Test {
    @isTest
    public static void testSchedulableTest()
    {
        // GIVEN: We want to run DSSCallistaSyncBatch once a day, MON-FRI
        String cron = '0 0 5 ? * MON-FRI';

        // WHEN: We schedule the batch
        Test.startTest();
        System.schedule('Daily DSS Contact Sync',cron , new ScheduleDSSCallistaSyncBatch());
        Test.stopTest();

        //THEN: 
        Assert.isFalse([Select Id from AsyncApexJob where CompletedDate=null].isEmpty(), 'Expected AsyncApexJob');
    }
}