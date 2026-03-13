/*******************************************************************************
* @author       Nitin Khandelwal
* @date         9.April.2018        
* @description  Test Class for job Trigger Handler class
* @revision     
*******************************************************************************/
@isTest(isParallel=true)
private class JobTriggerHandler_Test {
    private static testMethod void testcase() {
        Course__c course1 = new Course__C();
        course1.Course_Code__c = 'testabc';
        course1.Name = 'testabc';
        Database.insert(course1,false);
        Job_Control__c job_Control_2 = new Job_Control__c(
            Job_Code__c = 'test15',
            Processing_Status__c = 'CRM Ready to Proces',
            Process_Name__c = 'Course',
            Type__c = 'Course-Published'
        );
        Database.insert(job_Control_2, false);
        Stg_Course__c staging_Course_1 = new Stg_Course__c(
            Job_Code__c = job_Control_2.Job_Code__c,
            Record_Status__c = '',
            Specialisation_Code__c = 'testabcxyz',
            Course_Code__c = 'testabc',
            Name = 'testabc',
            Course_Type__c = job_Control_2.Type__c
        );
        Test.startTest();
        Database.insert(staging_Course_1, false);
        job_Control_2.Processing_Status__c = 'CRM Ready to Process';
        Database.SaveResult srList8 = Database.update(job_Control_2, false);
        test.stopTest();
        System.Assert(job_Control_2.Id != null, 'Successful');
        System.Assert(staging_course_1.Id != null, 'Successful');
    }
    private static testMethod void testcase1() {
        Course__c course1 = new Course__C();
        course1.Course_Code__c = 'testabc';
        course1.Name = 'testabc';
        database.insert(course1,false);
        Job_Control__c job_Control_2 = new Job_Control__c(
            Job_Code__c = 'test15',
            Processing_Status__c = 'CRM Ready to Proces',
            Process_Name__c = 'Course',
            Type__c = 'Course-Published'
        );
        Database.insert(job_Control_2, false);
        Stg_Course__c staging_Course_1 = new Stg_Course__c(
            Job_Code__c = 'test15',
            Record_Status__c = '',
            Specialisation_Code__c = 'testabcxyz',
            Course_Code__c = 'testabcxyz',
            Name = 'testabc',
            Course_Type__c = 'Course-Published'
        );
        Test.startTest();
        Database.insert(staging_Course_1, false);
        job_Control_2.Processing_Status__c = 'CRM Ready to Process';
        Database.SaveResult srList8 = Database.update(job_Control_2, false);
        Test.stopTest();
        System.Assert(job_Control_2.Id != null, 'Successful');
        System.Assert(staging_course_1.Id != null, 'Successful');
    }
    private static testMethod void testcase2() {
        Course__c course1 = new Course__C();
        course1.Course_Code__c = 'testabc';
        course1.Name = 'testabc';
        database.insert(course1,false);
        
        Job_Control__c job_Control_2 = new Job_Control__c(
            Job_Code__c = 'test15',
            Processing_Status__c = 'CRM Ready to Proces',
            Process_Name__c = 'Course',
            Type__c = 'Course-Published'
        );
        Database.insert(job_Control_2, false);
        Stg_Course__c staging_Course_1 = new Stg_Course__c(
            Job_Code__c = job_Control_2.Job_Code__c,
            Record_Status__c = '',
            Specialisation_Code__c = 'testabcxyz',
            Course_Code__c = 'testabc',
            Name = 'testabc',
            Course_Type__c = job_Control_2.Type__c
        );
        Test.startTest();
        Database.insert(staging_Course_1, false);
        job_Control_2.Processing_Status__c = 'CRM Ready to Process';
        job_Control_2.Number_of_Records_Processed__c = 1 ;
        Database.SaveResult srList8 = Database.update(job_Control_2, false);
        Test.stopTest();
        System.Assert(job_Control_2.Id != null, 'Successful');
        System.Assert(staging_course_1.Id != null, 'Successful');
    }

    /*
     * description  Test method to handle Calendar_Dates for target object
     * revision     18.DEC.2019 - J.Mapanao - Initial Created
     */
    static testMethod void testcase3() {
        Course__c course1 = new Course__C();
        course1.Course_Code__c = 'testabc';
        course1.Name = 'testabc';
        database.insert(course1,false);
        
        Job_Control__c test_JobControl = new Job_Control__c(
            Job_Code__c = 'TestJobCode',
            Processing_Status__c = 'CRM Ready to Proces',
            Process_Name__c = 'Course'
        );
        Database.insert(test_JobControl, false);
        Stg_Course__c test_StagingCourse = new Stg_Course__c(
            Job_Code__c = test_JobControl.Job_Code__c,
            Record_Status__c = '',
            Specialisation_Code__c = 'testabcxyz',
            Course_Code__c = 'testabc',
            Name = 'testabc',
            Course_Type__c = test_JobControl.Type__c
        );
        Test.startTest();
        Database.insert(test_StagingCourse, false);
        test_JobControl.Processing_Status__c = 'CRM Ready to Process';
        test_JobControl.Number_of_Records_Processed__c = 1;
        test_JobControl.Process_Name__c = 'Calendar_Dates';
        Database.SaveResult srList8 = Database.update(test_JobControl, false);
        Test.stopTest();
        Job_Control__c res_JobControl = [SELECT Id, Process_Name__c FROM Job_Control__c WHERE Id =: test_JobControl.Id];
        System.assertEquals('Calendar_Dates', res_JobControl.Process_Name__c, 'ERROR: Job Control Process Name is not Calendar_Dates');
    }

    /*
     * description  Test method to handle Calendar for target object
     * revision     18.DEC.2019 - J.Mapanao - Initial Created
     */
    static testMethod void testcase4() {
        Course__c course1 = new Course__C();
        course1.Course_Code__c = 'testabc';
        course1.Name = 'testabc';
        database.insert(course1,false);
        
        Job_Control__c test_JobControl = new Job_Control__c(
            Job_Code__c = 'TestJobCode',
            Processing_Status__c = 'CRM Ready to Proces',
            Process_Name__c = 'Course'
        );
        Database.insert(test_JobControl, false);
        Stg_Course__c test_StagingCourse = new Stg_Course__c(
            Job_Code__c = test_JobControl.Job_Code__c,
            Record_Status__c = '',
            Specialisation_Code__c = 'testabcxyz',
            Course_Code__c = 'testabc',
            Name = 'testabc',
            Course_Type__c = test_JobControl.Type__c
        );
        Test.startTest();
        Database.insert(test_StagingCourse, false);
        test_JobControl.Processing_Status__c = 'CRM Ready to Process';
        test_JobControl.Number_of_Records_Processed__c = 1;
        test_JobControl.Process_Name__c = 'Calendar';
        Database.SaveResult srList8 = Database.update(test_JobControl, false);
        Test.stopTest();
        Job_Control__c res_JobControl = [SELECT Id, Process_Name__c FROM Job_Control__c WHERE Id =: test_JobControl.Id];
        System.assertEquals('Calendar', res_JobControl.Process_Name__c, 'ERROR: Job Control Process Name is not Calendar');
    }

    /*
     * description  Test method to handle CRICOS_Code for target object
     * revision     18.DEC.2019 - J.Mapanao - Initial Created
     */
    static testMethod void testcase5() {
        Course__c course1 = new Course__C();
        course1.Course_Code__c = 'testabc';
        course1.Name = 'testabc';
        database.insert(course1,false);
        
        Job_Control__c test_JobControl = new Job_Control__c(
            Job_Code__c = 'TestJobCode',
            Processing_Status__c = 'CRM Ready to Proces',
            Process_Name__c = 'Course'
        );
        Database.insert(test_JobControl, false);
        Stg_Course__c test_StagingCourse = new Stg_Course__c(
            Job_Code__c = test_JobControl.Job_Code__c,
            Record_Status__c = '',
            Specialisation_Code__c = 'testabcxyz',
            Course_Code__c = 'testabc',
            Name = 'testabc',
            Course_Type__c = test_JobControl.Type__c
        );
        Test.startTest();
        Database.insert(test_StagingCourse, false);
        test_JobControl.Processing_Status__c = 'CRM Ready to Process';
        test_JobControl.Number_of_Records_Processed__c = 1;
        test_JobControl.Process_Name__c = 'CRICOS_Code';
        Database.SaveResult srList8 = Database.update(test_JobControl, false);
        Test.stopTest();
        Job_Control__c res_JobControl = [SELECT Id, Process_Name__c FROM Job_Control__c WHERE Id =: test_JobControl.Id];
        System.assertEquals('CRICOS_Code', res_JobControl.Process_Name__c, 'ERROR: Job Control Process Name is not CRICOS_Code');
    }

    /*
     * description  Test method to handle incorrect target object
     * revision     18.DEC.2019 - J.Mapanao - Initial Created
     */
    static testMethod void testcase6() {
        Course__c course1 = new Course__C();
        course1.Course_Code__c = 'testabc';
        course1.Name = 'testabc';
        database.insert(course1,false);
        
        Job_Control__c test_JobControl = new Job_Control__c(
            Job_Code__c = 'TestJobCode',
            Processing_Status__c = 'CRM Ready to Proces',
            Process_Name__c = 'Course'
        );
        Database.insert(test_JobControl, false);
        Stg_Course__c test_StagingCourse = new Stg_Course__c(
            Job_Code__c = test_JobControl.Job_Code__c,
            Record_Status__c = '',
            Specialisation_Code__c = 'testabcxyz',
            Course_Code__c = 'testabc',
            Name = 'testabc',
            Course_Type__c = test_JobControl.Type__c
        );
        Test.startTest();
        Database.insert(test_StagingCourse, false);
        test_JobControl.Processing_Status__c = 'CRM Ready to Process';
        test_JobControl.Number_of_Records_Processed__c = 1;
        test_JobControl.Process_Name__c = 'ExceptionObject';
        Database.SaveResult srList8 = Database.update(test_JobControl, false);
        Test.stopTest();
        Job_Control__c res_JobControl = [SELECT Id, Process_Name__c FROM Job_Control__c WHERE Id =: test_JobControl.Id];
        System.assertNotEquals(null, res_JobControl.Id, 'ERROR: Job Control Id is null');
    }
}