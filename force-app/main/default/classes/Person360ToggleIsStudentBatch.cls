/**
 * @description       : Handles the toggling of Contact.Is_Student__c field from true to false
 *                      Get all Course Attempt where "Course_Requirements_Completion_Date__c" > (today - transition period) AND Contact__r.Is_Student__c = true
 *                      Then mark the Contact__r.Is_Student__c to false, but there may be other course attempts that still qualify them as a student
 *
 *                      Set "Is Student" to true when the Contact has an ANY active course attempt with:
 *                       - a status of "enrolled" OR "intermit" - Student is active
 *                       - a status of "inactive" (and at least 1 active or completed unit attempt) - Student that has (only) paused their studies (and has commenced units in the past)
 *                       - a status is "completed" AND the "Course_Requirements_Completion_Date" > (today - transition period) - Student recently completed their studies
 *                      Set "is Student" to false, when:
 *                       - Course attempt status changes and the above is not met anymore
 *                       - Completed course attempts with "Course_Requirements_Completion_Date" > (today - transition period)
 * @author            : Stefan Scheit
 * @group             : Batch
 * @last modified on  : 2021-11-11
 * @last modified by  : Stefan Scheit
 * Modifications Log 
 * Date         Author          Modification
 * 2020-05-25   JM Mapanao      Initial Version
 * 2020-12-12   M Cadman        Updated class name for togggle is student logic
 * 2021-11-11   Stefan Scheit   EPCP-1815: Changed query for batch to incorporate criteria for the 'is student' (re)calcuation directly into SOQL to reduce number of platform events created
**/
public without sharing class Person360ToggleIsStudentBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    @TestVisible
    // Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
    private static final String DEFAULT_SCHEDULE = '0 45 1 * * ?'; // at 1:45 am every day

    /* Flag to run batch class in two operation modes based on value:
     - if true: evaluate toggling an active student off (from is_student__c = true -> false)
     - if false: evaluate toggling an inactive student on (from is_student__c = false -> true)
    */
    private boolean studentMode = true;

    // public constructor to run batch in standard (student) mode (with instance variable studentMode = true)
    public Person360ToggleIsStudentBatch() {
        this.studentMode = true;
    }

    // private constructor to run batch in 2nd/non-student mode (with instance variable studentMode = false)
    @TestVisible
    private Person360ToggleIsStudentBatch(boolean studentMode) {
        this.studentMode = studentMode;
    }

    /**
     * @description Query all contacts marked as either student (or not) based on 'studentMode' flag/mode.
     * @return query locator with either contacts marked as student (that should not be), or contacts marked as non-student (but should be)
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Database.QueryLocator queryLoc = null;
      
        if (this.studentMode) {
            // evaluate contact for 'is student' = true, but they shoud not be (anymore)
            queryLoc = Database.getQueryLocator([
                SELECT Id FROM Contact WHERE 
                    // marked as student, but there are not any course attempts that qualifies them
                    Is_Student__c = true AND Id NOT IN
                    (
                        SELECT Contact__c FROM Course_Attempt__c WHERE
                            deleted_in_source__c = false
                            AND (
                                Course_Attempt_Status__c IN ('Enrolled', 'Intermit')
                                OR (Course_Attempt_Status__c = 'Inactive' AND (Number_of_Active_Unit_Attempts__c > 0 OR Number_of_Completed_Unit_Attempt__c > 0))
                                OR (Course_Attempt_Status__c = 'Completed' AND Course_Requirements_Completion_Date__c > :CourseAttemptServices.IS_STUDENT_TRANSITION_DATE)
                            )
                    )
            ]);
        } else {
            // evaluate contact for 'is student' = false, but they shoud be (again)
            queryLoc = Database.getQueryLocator([
                SELECT Id FROM Contact WHERE
                    // not marked as student, but there is at least one course attempt that qualifies them
                    Is_Student__c = false AND Id IN 
                    (
                        SELECT Contact__c FROM Course_Attempt__c WHERE
                                deleted_in_source__c = false
                                AND (
                                    Course_Attempt_Status__c IN ('Enrolled', 'Intermit')
                                    OR (Course_Attempt_Status__c = 'Inactive' AND (Number_of_Active_Unit_Attempts__c > 0 OR Number_of_Completed_Unit_Attempt__c > 0))
                                    OR (Course_Attempt_Status__c = 'Completed' AND Course_Requirements_Completion_Date__c > :CourseAttemptServices.IS_STUDENT_TRANSITION_DATE)
                                )
                    )
            ]);
        }
        return queryLoc;
    }

    /**
    * @description Create a platform event for each contact record of the scope.
    * @param bc 
    * @param scope 
    **/
    public void execute(Database.BatchableContext bc, List<Contact> scope) {
        Set<Id> contactIdSet = new Set<Id>();
        for(Contact c : scope) {
            contactIdSet.add(c.Id);
        }
        //System.debug(LoggingLevel.FINEST, 'Contact ids for which the is student flag will be recalculated: '+contactIdSet);
        // create platform events for each contact id
        if(!contactIdSet.isEmpty()) {
            try {
                new CourseAttemptChangeEventService.EvaluateIsStudent().publishEvents(contactIdSet);
            } catch(Exception ex) {
                LogUtilityException.logException(ex);
            }
        }
    }

    /**
    * @description Finish processing, no action.
    * @param bc 
    **/
    public void finish(Database.BatchableContext bc) {
        if (this.studentMode) {
            // if batch was run for isCurrentStudent = true, run again for value of false
            Person360ToggleIsStudentBatch nonStudentBatch = new Person360ToggleIsStudentBatch(false);
            // chain 2nd batch
            Database.executeBatch(nonStudentBatch);
        }
        LogUtilityException.getLimits();
    }

    /**
     * Method implements the Schedulable interface
     * @param  sc as SchedulabeContext
     */
    public void execute(SchedulableContext sc) {
        Person360ToggleIsStudentBatch batchObj = new Person360ToggleIsStudentBatch();
        Id batchProcessId = Database.executeBatch(batchObj);
    }

    /**
     * Method to schedule the Person360ToggleIsStudentBatch with a default cron timing (at 1:00 am everyday)
     */
    public String schedule() {
        String schedule = DEFAULT_SCHEDULE;
        return this.schedule(schedule);
    }
    
    /**
    * Method to schedule the Person360ToggleIsStudentBatch with a set cron timing
    * @param schedule The schedule as cron String
    */
    public String schedule(String schedule) {
        String jobId;
        String scheduleName = String.valueOf(Person360ToggleIsStudentBatch.class);
        if (Test.isRunningTest()) {
            scheduleName = 'Testing'+scheduleName;
        }
        List<CronTrigger> ctList = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name =: scheduleName];
        if (ctList.size() <= 0) {
            jobId = System.schedule(scheduleName, schedule, new Person360ToggleIsStudentBatch());
        }
        return jobId;
    }
    
    /**
    * Method to unschedule the Person360ToggleIsStudentBatch
    */
    public void unschedule() {
        String scheduleName = String.valueOf(Person360ToggleIsStudentBatch.class);
        if (Test.isRunningTest()) {
            scheduleName = 'Testing'+scheduleName;
        }
        for ( CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name =: scheduleName] ) {
            System.abortJob(ct.Id);
        }
    }
}