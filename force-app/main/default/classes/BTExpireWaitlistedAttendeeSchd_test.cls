/**
* @author Ibrahim Rumi
* @date 12-07-2021
* @description Sibling test class for BTExpireWaitlistedAttendeeSchd
**/
@isTest
public class BTExpireWaitlistedAttendeeSchd_test {

    @testSetup
    static void setup(){
        //create blackthorn event settings to set batch size
        conference360__Blackthorn_Events_Settings__c settings = new conference360__Blackthorn_Events_Settings__c();
        settings.Expire_Waitlist_Attendee_Batch_size__c = 50;
        insert settings;
    }
    
     /**
     * @description test if the ExpireWaitlistedAttendee class is scheduled
     */
    @isTest
    static void testExpireWaitlistedAttendeeScheduler(){
        String CRON_EXP = '0 0 0 15 3 ? ';
        BTExpireWaitlistedAttendeeSchd btExpireAttendeescheduler = new BTExpireWaitlistedAttendeeSchd();
        Test.startTest();
        System.assertEquals(50, btExpireAttendeescheduler.batchsize, 'batch size is not retrieved from the custom setting');
        // Schedule the test job
        String btexpireAttendeeJobid = System.schedule('btexpireAttSchApexTest',
            CRON_EXP,
            btExpireAttendeescheduler);
        //verify schedule job has not run
        Test.stopTest();
        
        // Check schedulable is in the job list
		List<AsyncApexJob> jobsScheduled = [select Id, ApexClassID, ApexClass.Name, Status, JobType from AsyncApexJob where JobType = 'ScheduledApex'];
		System.assertEquals(1, jobsScheduled.size(), 'expecting one scheduled job');
		System.assertEquals('BTExpireWaitlistedAttendeeSchd', jobsScheduled[0].ApexClass.Name, 'expecting specific scheduled job');
    }
    
    /**
     * @description test if the ExpireWaitlistedAttendee batch size is overwritten from the constructor
     */
    @isTest
    static void testExpireWaitlistWithModifiedBatchSize(){
        BTExpireWaitlistedAttendeeSchd btExpireAttendeescheduler = new BTExpireWaitlistedAttendeeSchd(5);
		System.assertEquals(5, btExpireAttendeescheduler.batchsize, 'batch size is not overwritten');
    }
    
}