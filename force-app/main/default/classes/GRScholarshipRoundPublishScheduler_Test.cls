/*******************************************************************************
* @author		Vishal Gupta
* @date         12/06/2025    
* @description  Test Class for GRScholarshipRoundPublishScheduler Class
* @revision     12/06/2025 - Initial Version
*******************************************************************************/
@isTest(isParallel=false)//In parallel Apex tests, DML operations aren't permitted on this type of object: CronJobDetail
public class GRScholarshipRoundPublishScheduler_Test {

    @TestSetup
    static void makeData() {
        //creating calendar record
        Calendar__c cal = new Calendar__c();
        cal.Calendar_Code__c = '1111_1111';
        cal.type__c = 'ADM-RES1';
        cal.name = 'ADM_2025_ADM-RES1';
        cal.Sequence_Number__c = 1111;
        cal.Sequence_Number_Year__c = 1111;
        cal.Inter_schol_round_publish_in_progress__c = true;
        cal.Published_Date_for_Inter_ScholarRound__c = Date.Today();
        insert cal;
    }

    /**
     * @author          Vishal Gupta
     * @description     Publish the Scholarship Round for the selected calendar
     * @revision        30/5/2025 - Initial Version
     */
     @isTest static void testPublishScholarshipRoundScheduleDomestic() {

        Test.startTest();
        //Given, there is a Calendar round ready to be picked up
        // Schedule the job 1 minute in the future
        String cron = '0 0 0 1 1 ? 2099'; // Future date to avoid timing conflicts
        //When, We try to publish the scholarship calendar
        System.schedule('Test_Scheduler_Job', cron, new GRScholarshipRoundPublishScheduler());

        Test.stopTest();

        // Validate that the job was scheduled
        List<CronTrigger> jobs = [
            SELECT Id
            FROM CronTrigger
            WHERE CronJobDetail.Name = 'Test_Scheduler_Job'
        ];
        //Then, it should see the scheduled job in the system
        Assert.areEqual(1, jobs.size(), 'Scheduled job was found');
    }

    /**
     * @author          Vishal Gupta
     * @description     Publish the Scholarship Round for the selected calendar
     * @revision        30/5/2025 - Initial Version
     */
     @isTest static void testPublishScholarshipRoundScheduleInternational() {
        Calendar__c cal = [SELECT Domes_schol_round_publish_in_progress__c, Inter_schol_round_publish_in_progress__c, Published_Date_for_Domes_ScholarRound__c FROM Calendar__c LIMIT 1];
        cal.Domes_schol_round_publish_in_progress__c = true;
        cal.Inter_schol_round_publish_in_progress__c = false;
        cal.Published_Date_for_Domes_ScholarRound__c = Date.Today();
        update cal;
        Test.startTest();
        //Given, there is a Calendar round ready to be picked up
        // Schedule the job 1 minute in the future
        String cron = '0 0 0 1 1 ? 2099'; // Future date to avoid timing conflicts
        //When, We try to publish the scholarship calendar
        System.schedule('Test_Scheduler_Job', cron, new GRScholarshipRoundPublishScheduler());

        Test.stopTest();

        // Validate that the job was scheduled
        List<CronTrigger> jobs = [
            SELECT Id
            FROM CronTrigger
            WHERE CronJobDetail.Name = 'Test_Scheduler_Job'
        ];
        //Then, it should see the scheduled job in the system
        Assert.areEqual(1, jobs.size(), 'Scheduled job was found');
    }

    /**
     * @author          Vishal Gupta
     * @description     Publish the Scholarship Round for the selected calendar
     * @revision        30/5/2025 - Initial Version
     */
     @isTest static void testPublishScholarshipRoundScheduleBothRound() {
        Calendar__c cal = [SELECT Domes_schol_round_publish_in_progress__c, Inter_schol_round_publish_in_progress__c, Published_Date_for_Inter_ScholarRound__c, Published_Date_for_Domes_ScholarRound__c FROM Calendar__c LIMIT 1];
        cal.Domes_schol_round_publish_in_progress__c = true;
        cal.Inter_schol_round_publish_in_progress__c = true;
        cal.Published_Date_for_Domes_ScholarRound__c = Date.Today();
        cal.Published_Date_for_Inter_ScholarRound__c = Date.Today();
        update cal;
        Test.startTest();
        //Given, there is a Calendar round ready to be picked up
        // Schedule the job 1 minute in the future
        String cron = '0 0 0 1 1 ? 2099'; // Future date to avoid timing conflicts
        //When, We try to publish the scholarship calendar
        System.schedule('Test_Scheduler_Job', cron, new GRScholarshipRoundPublishScheduler());

        Test.stopTest();

        // Validate that the job was scheduled
        List<CronTrigger> jobs = [
            SELECT Id
            FROM CronTrigger
            WHERE CronJobDetail.Name = 'Test_Scheduler_Job'
        ];
        //Then, it should see the scheduled job in the system
        Assert.areEqual(1, jobs.size(), 'Scheduled job was found');
    }
}