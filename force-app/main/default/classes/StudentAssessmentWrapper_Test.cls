/**
 * @description Test class for StudentAssessmentWrapper wrapper class
 * @revision
 * 		2025-17-08 - Sachin Shetty	- 	Created
 */
@IsTest(isParallel=true)
public class StudentAssessmentWrapper_Test {
    @IsTest
    static void testStudentAssessmentWrapper_GivenWhenThen() {
        // GIVEN - A default constructor instance
        StudentAssessmentWrapper defaultWrapper = new StudentAssessmentWrapper();

        // WHEN - Assigning values manually
        defaultWrapper.id = 'A001';
        defaultWrapper.cmid = 'CM101';
        defaultWrapper.unitOfferingId = 'UO202';
        defaultWrapper.type = 'Assignment';
        defaultWrapper.name = 'Math Assignment 1';
        defaultWrapper.dueDate = '2025-08-20';
        defaultWrapper.cutoffDate = '2025-08-22';
        defaultWrapper.description = 'First assessment in math';
        defaultWrapper.submissionStartDate = '2025-08-15';

        // THEN - All manually assigned values should be correct
        Assert.areEqual('A001', defaultWrapper.id);
        Assert.areEqual('CM101', defaultWrapper.cmid);
        Assert.areEqual('UO202', defaultWrapper.unitOfferingId);
        Assert.areEqual('Assignment', defaultWrapper.type);
        Assert.areEqual('Math Assignment 1', defaultWrapper.name);
        Assert.areEqual('2025-08-20', defaultWrapper.dueDate);
        Assert.areEqual('2025-08-22', defaultWrapper.cutoffDate);
        Assert.areEqual('First assessment in math', defaultWrapper.description);
        Assert.areEqual('2025-08-15', defaultWrapper.submissionStartDate);
    }
}