/**
 * @Class              : Course_Group_Member_AS_Update_Fields_FT.cls
 * @Description        : Test class for for Course_Group_Member_AS_Update_Course_Group_Member_Fields after record trigger flow 
 * @Author             : Sachin Shetty
 * @Group              : Test Class
 * @Revision           : 
 * 2025-03-21   Sachin Shetty  Created 
 */
@isTest(isParallel=true)
public class Course_Group_Member_AS_Update_Fields_FT {

    @testSetup
    static void testDataSetup() {
        Course__c course = new Course__c (name = 'aCourse', Course_code__c = 'aCourse_100', Version__c = '1');
		insert course;
        
		Course_Group__c courseGroup = new Course_Group__c(name = 'CG Name',COURSE_GROUP__C = 'EQ-A000100', TYPE__C = 'EQUIV-CRS', RESPONSIBLE_ORG_UNIT_CODE__C = '50000100',IS_ACTIVE__C = TRUE);
		insert (courseGroup);

        Course_Group_Member__c courseGroupMember = new Course_Group_Member__c (
                                                        name = 'CGM Name',
                                                        Course__c = course.Id,
                                                        Course_Group__c = courseGroup.Id
                                                    );

        insert (courseGroupMember);
    }

    /*
    * @description: Tests whether Course Group Member name is updated
    */
    @isTest
    static void courseGroupMemberNameUpdate() {
        // GIVEN/WHEN - A Course Group Member is created
		List<Course_Group_Member__c> courseGroupMember = [SELECT Name FROM Course_Group_Member__c WHERE Course_Group__r.COURSE_GROUP__c = 'EQ-A000100'];

        //THEN - Course Group Member name should be updated
		Assert.areEqual('EQ-A000100_aCourse_1', courseGroupMember[0].name, 'Course Group Member name not aligned');
    }
}