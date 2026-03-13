/**
 * @author       : Sachin Shetty
 * @date         : 17-08-2025
 * @group        : Test Class
 * @description  : Test Class for MoodleAssignmentWrapper
 * @revision
 * 		17-08-2025	Sachin Shetty	Created
**/
@IsTest(isParallel=true)
public with sharing class MoodleAssignmentWrapper_Test {

    @IsTest
    static void test_NewDueDateAssignment() {
        // GIVEN a MoodleAssignmentWrapper instance
        MoodleAssignmentWrapper wrapper = new MoodleAssignmentWrapper();

        // WHEN a new due date is assigned
        Datetime expectedDate = Datetime.now().addDays(5);
        wrapper.newDueDate = expectedDate;

        // THEN the stored due date matches the expected value
        Assert.areEqual(expectedDate, wrapper.newDueDate, 
            'The newDueDate should match the value that was set.');
    }
}