/**
 * @author      J.Mapanao
 * @description Sibling test class for AssessmentServicesConstants.cls
 * @revision    27.NOV.19 - J.Mapanao 		- Created
 * 				17.AUG.25 - Sachin Shetty	- Formatting
 */
@isTest(isParallel=true)
private class AssessmentServicesConstants_Test {
    @IsTest
    static void testBehavior() {
        AssessmentServicesConstants parentConstants = new AssessmentServicesConstants();
        Assert.isNotNull(parentConstants);
    }
    
    @IsTest
    static void testConstantsCoverage() {
        // GIVEN - an instance of the constants class
        AssessmentServicesConstants constants;
        
        // WHEN - instantiate the class (even though all members are static)
        constants = new AssessmentServicesConstants();
        
        // THEN - assert that the instance is not null
        Assert.isNotNull(constants, 'The AssessmentServicesConstants instance should be created');

        // THEN - access a few constants to cover them
        Assert.areEqual('Required', AssessmentServicesConstants.APP_ASSESSMENT_TASK_STATUS_REQUIRED);
        Assert.areEqual('In Progress', AssessmentServicesConstants.APP_ASSESSMENT_TASK_STATUS_INPROGRESS);
        Assert.areEqual('Waiting for docs', AssessmentServicesConstants.APP_ASSESSMENT_TASK_STATUS_WFORDOCS);
        Assert.areEqual('Completed', AssessmentServicesConstants.APP_ASSESSMENT_TASK_STATUS_COMPLETED);
        Assert.areEqual('Document QA Check', AssessmentServicesConstants.ASSESSMENT_PROCESS_DOCQACHECK);
        Assert.areEqual('Visa Check', AssessmentServicesConstants.ASSESSMENT_PROCESS_VISACHECK);
        Assert.areEqual('OTHERDCTYP', AssessmentServicesConstants.CONDOC_DOC_TYPE_OTHER);
        Assert.areEqual('Not Required', AssessmentServicesConstants.APP_CHECKLIST_STATUS_NOTREQUIRED);
        Assert.areEqual('In Progress', AssessmentServicesConstants.APP_COURSE_PREF_TASK_ASSESSMENT_INPROGRESS);
        Assert.areEqual('Email Received', AssessmentServicesConstants.EMAIL_RECEIVED);
    }
}