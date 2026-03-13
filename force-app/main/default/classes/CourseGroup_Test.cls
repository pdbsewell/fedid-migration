/**
* @author Martin Cadman
* @date 14.08.2019
*
* @group Assessment
*
* @description  
*  Test class to drive the course group and course group member process builders(and give coverage) which both re-format their name field.
*
*/

@isTest(isParallel=true)
public class CourseGroup_Test {
    
    @testSetup
    static void testDataSetup() {
        Course__c c = new Course__c (name = 'aCourse', Course_code__c = 'aCourse_1', Version__c = '1');
		insert c;
        
		Course_Group__c cg = new Course_Group__c(name = 'CG Temp Name',COURSE_GROUP__C = 'EQ-A000006', TYPE__C = 'EQUIV-CRS', RESPONSIBLE_ORG_UNIT_CODE__C = '50000568',IS_ACTIVE__C = TRUE);
		insert (cg);

        Course_Group_Member__c cgm = new Course_Group_Member__c(name = 'CGM Temp Name');
        cgm.course__r = new course__c(Course_Code__c = 'aCourse_1');
		cgm.Course_Group__r = new Course_Group__c(Course_Group__c = 'EQ-A000006');
        insert (cgm);
    }
    
    @isTest
    static void courseGroupName() {
		List<Course_Group__c> cg = [select name from Course_Group__c where COURSE_GROUP__C = 'EQ-A000006'];
        system.assert(cg[0].name == 'EQ-A000006','Course Group name not aligned with Course Group field' );
    }

    @isTest
    static void courseGroupMemberName() {
		List<Course_Group_Member__c> cgm = [select name from Course_Group_Member__c where Course_Group__r.COURSE_GROUP__c = 'EQ-A000006'];
		system.assert(cgm[0].name == 'EQ-A000006_aCourse_1', 'Course Group Member name not aligned');
    }
}