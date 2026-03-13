/**
 * @author      Kristian Vegerano
 * @description Test class for CourseSpecificDocumentSelector class
 * @group       Test Class
 * @revision    02/08/2021 - Kristian Vegerano - Created
 */
@isTest(isParallel=true) // FIELD_CUSTOM_VALIDATION_EXCEPTION, System.DmlException: Insert failed. First exception on row 0; first error: APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object: SourceMember
public with sharing class CourseSpecificDocumentSelector_Test {
    /**
     * @description Setup test data
     */
    @testSetup 
    static void setup() {
        //Create test Course
        Course__c testCourse = StudFirst_TestHelper.createCourse();
        insert testCourse;

        //Create test Offering
        Course_Offering__c testOffering = StudFirst_TestHelper.createCourseOffering(testCourse);
        insert testOffering;

        //Create test course prerequisite
        List<Course_Specific_Document__c> courseSpecificDocumentList = new List<Course_Specific_Document__c>();
        // add course related prerequisite
        courseSpecificDocumentList.add(new Course_Specific_Document__c(Name = 'Course Prerequisite',
                                                              IsActive__c = true,
                                                              Course__c = testCourse.Id,
                                                              Instruction__c = 'Test Course Instruction'));
        // add faculty related prerequisite
        courseSpecificDocumentList.add(new Course_Specific_Document__c(Name = 'Faculty Prerequisite',
                                                              IsActive__c = true,
                                                              Faculty_Name__c = 'Faculty of Art, Design and Architecture',
                                                              Instruction__c = 'Test Faculty Instruction'));
        insert courseSpecificDocumentList;

    }

    /**
     * @description Test select course prerequisite by Id
     */
    @isTest 
    static void test_SelectById() {
        //Initialize variables
        Set<Id> courseSpecificDocumentIds = new Set<Id>();
        List<Course_Specific_Document__c> courseSpecificDocumentList = new List<Course_Specific_Document__c>();

        //Retrieve existing course prerequisite ids
        for(Course_Specific_Document__c loopCourseSpecificDocument : [SELECT Id FROM Course_Specific_Document__c LIMIT 10]){
            courseSpecificDocumentIds.add(loopCourseSpecificDocument.Id);
        }

        //Start test process
	 	Test.startTest();
            courseSpecificDocumentList.addAll(new CourseSpecificDocumentSelector().selectById(courseSpecificDocumentIds));
	 	Test.stopTest();

        //Start assertion
        System.assertEquals(2, courseSpecificDocumentList.size());
    }

    /**
     * @description Test select course prerequisite by course or faculty
     */
    @isTest 
    static void test_SelectCoursePrerequisiteByCourseOrFaculty() {
        //Initialize variables
        Set<String> courseSpecificDocumentCoursesId = new Set<String>();
        Set<String> courseSpecificDocumentFaculty = new Set<String>();
        List<Course_Specific_Document__c> courseSpecificDocumentList = new List<Course_Specific_Document__c>();

        //Retrieve existing course prerequisite ids
        for(Course_Specific_Document__c loopCourseSpecificDocument : [SELECT Id, Course__c, Course_Code__c, Faculty_Name__c FROM Course_Specific_Document__c LIMIT 10]){
            if(loopCourseSpecificDocument.Course_Code__c != null){
                courseSpecificDocumentCoursesId.add(loopCourseSpecificDocument.Course_Code__c);
            }
            if(loopCourseSpecificDocument.Faculty_Name__c != null){
                courseSpecificDocumentFaculty.add(loopCourseSpecificDocument.Faculty_Name__c);
            }
        }

        //Start test process
	 	Test.startTest();
            courseSpecificDocumentList.addAll(new CourseSpecificDocumentSelector().selectCoursePrerequisiteByCourseOrFaculty(courseSpecificDocumentCoursesId, courseSpecificDocumentFaculty));
	 	Test.stopTest();

        //Start assertion
        System.assertEquals(2, courseSpecificDocumentList.size());
    }

}