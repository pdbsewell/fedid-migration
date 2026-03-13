/**
 * @description       : Test class for Person360ToggleIsStudentBatch.cls
 * @author            : JM Mapanao
 * @group             : Test
 * @last modified on  : 2021-11-11
 * @last modified by  : Stefan Scheit
 * Modifications Log 
 * Date         Author          Modification
 * 2020-05-25   JM Mapanao      Initial Version
 * 2020-08-02   Stefan Scheit   Updated test method test_ToggleIsStudentContactBatch_Execute() to validate > 1 contact with mixed outcomes for is student flag
 * 2021-11-11   Stefan Scheit   Add test cases for transitions from student -> no student & no student -> student
**/
@isTest(isParallel=false) // due to schedule evaluations
private class Person360ToggleIsStudentBatch_Test {

    /**
     * Test Scenario:
     * Contact.Is_Student__c should be false when transition period has passed, ie. Course_Attempt__c.Course_Requirements_Completion_Date__c + transition period > today
     */
    @isTest
    static void transitionStudentFlagFromTrueToFalse() {
        
        // GIVEN: a contact marked as current student
        String testLastname = 'Lastname ' + String.valueOf(System.now());
        Contact contactTest = new Contact(Firstname='Student', Lastname=testLastname, Is_Student__c=true);
        Course__c courseTest = new Course__c(name='test', type__c='Course-All', Sub_Level__c='77');
        Database.insert(new List<sObject>{contactTest, courseTest});
        
        // GIVEN: Completed course attempt has a completion date older than the transition date/period
        Course_Attempt__c couresAttemptStudentNo = new Course_Attempt__c();
        couresAttemptStudentNo.Contact__c = contactTest.Id;
        couresAttemptStudentNo.Course__c = courseTest.Id;
        couresAttemptStudentNo.Course_Attempt_Status__c = 'Completed';
        couresAttemptStudentNo.Course_Requirements_Completion_Date__c = CourseAttemptServices.IS_STUDENT_TRANSITION_DATE.addDays(-1); // this should mark the contact as is_student = false
        // disable trigger, do not enable change data capture events
        TriggerCommon.disableTrigger('Course_Attempt__c'); // Test.enableChangeDataCapture();
        Database.insert(new List<Course_Attempt__c>{couresAttemptStudentNo});
        
        // WHEN: the batch is run to re-evaluate the 'is student' flag (on Contact)
        Test.startTest();
        Database.executeBatch(new Person360ToggleIsStudentBatch());
        Test.stopTest();

        // THEN: the student flags are set as expected
        Contact verifyContact = [SELECT Id, Is_Student__c FROM Contact WHERE Id = :contactTest.Id LIMIT 1];
        System.assertEquals(false, verifyContact.Is_Student__c, 'The Contact.Is_Student__c field is not set to \'false\' as expected.');
    }

    /**
     * Test Scenario:
     * Contact.Is_Student__c should be true when transition period has not passed (yet), ie. Course_Attempt__c.Course_Requirements_Completion_Date__c + transition period <= today
     */
    @isTest
    static void transitionStudentFlagFromFalseToTrue() {
        
        // GIVEN: a contact marked as current student
        String testLastname = 'Lastname ' + String.valueOf(System.now());
        Contact contactTest = new Contact(Firstname='Student', Lastname=testLastname, Is_Student__c=true);
        Course__c courseTest = new Course__c(name='test', type__c='Course-All', Sub_Level__c='77');
        Database.insert(new List<sObject>{contactTest, courseTest});
        
        // GIVEN: Completed course attempt has a completion date within the transition period
        Course_Attempt__c couresAttemptStudentYes = new Course_Attempt__c();
        couresAttemptStudentYes.Contact__c = contactTest.Id;
        couresAttemptStudentYes.Course__c = courseTest.Id;
        couresAttemptStudentYes.Course_Attempt_Status__c = 'Completed';
        couresAttemptStudentYes.Course_Requirements_Completion_Date__c = CourseAttemptServices.IS_STUDENT_TRANSITION_DATE.addDays(1); // this should mark the contact as is_student = true
        // disable trigger, do not enable change data capture events
        TriggerCommon.disableTrigger('Course_Attempt__c'); // Test.enableChangeDataCapture();
        Database.insert(new List<Course_Attempt__c>{couresAttemptStudentYes});
        
        // WHEN: the batch is run to re-evaluate the 'is student' flag (on Contact)
        Test.startTest();
        Database.executeBatch(new Person360ToggleIsStudentBatch());
        Test.stopTest();

        // THEN: the student flags are set as expected
        Contact verifyContact = [SELECT Id, Is_Student__c FROM Contact WHERE Id = :contactTest.Id LIMIT 1];
        System.assertEquals(true, verifyContact.Is_Student__c, 'The Contact.Is_Student__c field is not set to \'true\' as expected.');
    }

    /**
     * Test Scenario:
     * Contact.Is_Student__c should be false when Course_Attempt__c.Course_Requirements_Completion_Date__c + transition period < Date.today()
     * Contact.Is_Student__c should be true when Course_Attempt__c.Course_Requirements_Completion_Date__c + transition period >= Date.today()
     */
    @isTest
    static void test_ToggleIsStudentContactBatch_Execute() {
        
        // GIVEN: a contact marked as current student
        String testLastname = 'Lastname ' + String.valueOf(System.now());
        Contact contactStudentYes = new Contact(Firstname='Student', Lastname=testLastname, Is_Student__c=true);
        Contact contactStudentNo = new Contact(Firstname='NonStudent', Lastname=testLastname, Is_Student__c=true);
        Database.insert(new List<Contact>{contactStudentYes, contactStudentNo});
        
        // GIVEN: a course (the course attempt is linked to) exists 
        Course__c coursetest = new Course__c(name='test', type__c='Course-All', Sub_Level__c='77');
        insert coursetest;
		
        // GIVEN: Completed course attempts are linked to the contacts (with a completion date in the past)
        Course_Attempt__c couresAttemptStudentYes = new Course_Attempt__c();
        couresAttemptStudentYes.Contact__c = contactStudentYes.Id;
        couresAttemptStudentYes.Course__c = coursetest.Id;
        couresAttemptStudentYes.Course_Attempt_Status__c = 'Completed';
        couresAttemptStudentYes.Course_Requirements_Completion_Date__c = CourseAttemptServices.IS_STUDENT_TRANSITION_DATE.addDays(1); // this should mark the contact as is_student = true
        Course_Attempt__c couresAttemptStudentNo = new Course_Attempt__c();
        couresAttemptStudentNo.Contact__c = contactStudentNo.Id;
        couresAttemptStudentNo.Course__c = coursetest.Id;
        couresAttemptStudentNo.Course_Attempt_Status__c = 'Completed';
        couresAttemptStudentNo.Course_Requirements_Completion_Date__c = CourseAttemptServices.IS_STUDENT_TRANSITION_DATE.addDays(-1); // this should mark the contact as is_student = false
        // disable trigger, do not enable change data capture events
        TriggerCommon.disableTrigger('Course_Attempt__c'); // Test.enableChangeDataCapture();
        Database.insert(new List<Course_Attempt__c>{couresAttemptStudentYes, couresAttemptStudentNo});
        
        // WHEN: the batch is run to re-evaluate the 'is student' flag (on Contact)
        Test.startTest();
        Database.executeBatch(new Person360ToggleIsStudentBatch());
        Test.stopTest();

        // THEN: the student flags are set as expected
        Contact verifyContact = [SELECT Id, Is_Student__c FROM Contact WHERE Id = :contactStudentYes.Id LIMIT 1];
        System.assertEquals(true, verifyContact.Is_Student__c, 'The Contact.Is_Student__c field is not set to \'true\' as expected.');
        verifyContact = [SELECT Id, Is_Student__c FROM Contact WHERE Id = :contactStudentNo.Id LIMIT 1];
        System.assertEquals(false, verifyContact.Is_Student__c, 'The Contact.Is_Student__c field is not set to \'false\' as expected.');
    }

    @isTest
    static void testPerson360ToggleIsStudentBatch_ScheduleAndUnSchedule() {
        Exception testException = null;
        // GIVEN: batch job is defined 
        Person360ToggleIsStudentBatch myBatch = new Person360ToggleIsStudentBatch();
        Test.StartTest();
        // WHEN: job is scheduled
        try{
            myBatch.schedule();
        } catch (Exception exc) {
            testException = exc;
        }
        // THEN: no exception is expected
        System.assert(null==testException, 'An exception occured when scheduling the batch job.');
        
        // WHEN: job is unscheduled
        try{
            myBatch.unschedule();
        } catch (Exception exc) {
            testException = exc;
        }
        // THEN: 
        System.assert(null==testException, 'An exception occured when unscheduling the batch job.');
        Test.stopTest();
    }
}