/**
* @author          Nitin Khandelwal
* @date            11/June/2018
* @description     Test class for JobTriggerHandlerCourseHelper
* @revision        -
*/

@isTest(isParallel=true)
public class JobTriggerHandlerCourseHelper_Test {
    private static final Integer SETUP_RECORD_COUNT = 500;
    
    @testSetup
    static void testSetup() {
        
        // Create a job control for the test
        Job_Control__c jobControlObj = new Job_Control__c();
        jobControlObj.Job_Code__c = 'JobCode0001';
        jobControlObj.Number_of_Records_Processed__c = 0;
        jobControlObj.Number_of_Records_to_Process__c = 0;
        jobControlObj.Process_Name__c = 'Course';
        jobControlObj.Processing_Status__c = 'Staging Load Started';
        jobControlObj.Type__c = 'Course-Published';
        
        //Test if it the job control record gets created
        try {
            insert jobControlObj;
            List<Job_Control__c> jobControlObjs = [SELECT Id FROM Job_Control__c];
            System.assertEquals(1, jobControlObjs.size(), 'The job control record was not inserted.');
        } catch (Exception exc) {
            System.assert(exc!=null, 'Job control record could not be inserted as part of the testSetup.');
        }
        List<Stg_Course__c> stagingCourse = new List<Stg_Course__c>();
        for (Integer i = 0; i < SETUP_RECORD_COUNT; i++) {
            Stg_Course__c courseTempObj = new Stg_Course__c();
            courseTempObj.Course_Code__c = 'Course-' + i + 'xyz' + i;
            courseTempObj.name = 'Course-' + i;
            courseTempObj.Job_Code__c = 'JobCode0001';
            courseTempObj.Record_Status__c = '';
            courseTempObj.Specialisation_Code__c = 'Course-' + i + 'xyz' + i;
            courseTempObj.Title__c = 'Masters of Something';
            courseTempObj.Course_Type__c = jobControlObj.Type__c;
            stagingCourse.add(courseTempObj);
        }
        
        //Test if they are being created
        try {
            insert stagingCourse;
            stagingCourse = [SELECT Id FROM Stg_Course__c];
            System.assertEquals(SETUP_RECORD_COUNT, stagingCourse.size(), 'Number of courses does not match the expected number');
        } catch (Exception exc) {
            System.assert(exc!=null, 'Courses could not be inserted as part of testSetup.');
        }
        // Create a Course  obj record to test update of course
        Course__c course1Obj = new Course__c();
        course1Obj.Course_Code__c = 'Course-1xyz1';
        course1Obj.Name = 'Course-1';
        course1Obj.Title__c = 'Masters of Something2';
        insert course1Obj;
        //Test if it the job control run and gets updated
        try {
            jobControlObj.Processing_Status__c = 'CRM Ready to Process';
            update jobControlObj;
            jobControlObj = [SELECT Id, Processing_Status__c FROM Job_Control__c];
            System.assertEquals(jobControlObj.Processing_Status__c, 'Target Load Completed' , 'The job control did not get updated.');
        } catch (Exception exc) {
            System.assert(exc!=null, 'Job control did not get update.');
        }
    }
    
    @isTest
    static void ifCourseGetCreated(){
        List<Course__c> courseObj = [select id from Course__c];
        system.assertEquals((SETUP_RECORD_COUNT * 2), courseObj.size(), 'Wrong number of calendar dates are created');
        
        courseObj = [select Course_Code__c,Specialisation_Code__c,name from  Course__c
                     Where Course_Code__c = 'Course-1'];
        system.assertEquals('Course-1', courseObj[0].Course_Code__c, 'The field content is not filled correctly');
        system.assertEquals('Course-1', courseObj[0].Name, 'The field content is not filled correctly');
        List<Course__c> listOfCourses = [select id from Course__c];
        
    }
    @isTest
    static void ifCourseGetUpdated(){
        List<Course__c> courseObj = [select id,title__c from Course__c where course_code__c = 'Course-1xyz1'];
        System.assertEquals(1, courseObj.size(), 'The course record was not updated.');
        System.assertEquals('Masters of Something', courseObj[0].Title__c, 'The course record was not updated correctly.');
        
    }
}