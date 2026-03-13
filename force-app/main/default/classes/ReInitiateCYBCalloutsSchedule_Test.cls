/**
 * @description       : Test class for ReInitiateCYBCalloutsSchedule
 * @author            : Inderpal Dhanoa
 * @date              : 2023-01-31
 * @group             : Test
 * @group             : Enterprise
 * @last modified on  : 2023-01-31
 * @last modified by  : Inderpal Dhanoa
**/
@IsTest
public with sharing class ReInitiateCYBCalloutsSchedule_Test {
    /*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         23.Jan.2023
     * @description  Tests regarding to capturing the Schedule Job
    *******************************************************************************/ 
    @isTest
    static void execute_test(){
        // GIVEN a report is to be extracted

        // WHEN the scheduler is scheduled
        test.startTest();
        ReInitiateCYBCalloutsSchedule logScheduledBatch = new ReInitiateCYBCalloutsSchedule('Cybersource','Cybersource_Payment_Summary');
        System.schedule('Test log ScheduledBatch','0 0 23 * * ?', logScheduledBatch);
        test.stopTest();

        // THEN the job should be scheduled for an execution
        System.assert([select id , JobType,CompletedDate from AsyncApexJob where CompletedDate=null].size()>0);
    }
}