/**
* @author Ryan Wilson
* @date  30.Jan.2017
* @group Test Class
* @description  Test Class for the batch class EnquiryAgeCalculationBatch
* @revision     20/01/2020 - Created. <br/>
*/

@isTest(isParallel=false) // cannot execute in parallel due to cronjobdetail object
private class CalabrioCallUpdatesSC_Test {
    @IsTest
    static void testBehavior() {
        String cronExpr = '0 0 0 15 6 ?';

        Test.startTest();
        // Schedule the test job
        String jobId = System.schedule('CalabrioCallUpdatesSC_Test', cronExpr, new CalabrioCallUpdatesSC());
        Test.stopTest();

        // Check schedulable is in the job list
        List<AsyncApexJob> jobsScheduled = [select Id, ApexClassID, ApexClass.Name, Status, JobType from AsyncApexJob where JobType = 'ScheduledApex'];
        System.assertEquals(1, jobsScheduled.size(), 'expecting one scheduled job');
        System.assertEquals('CalabrioCallUpdatesSC', jobsScheduled[0].ApexClass.Name, 'expecting specific scheduled job');
    }
}