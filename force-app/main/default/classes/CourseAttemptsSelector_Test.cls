/**
 * @author David Browaeys
 * @description Selector class for Course Attempt object. 
 */
@isTest(isParallel=true)
public with sharing class CourseAttemptsSelector_Test {
    @isTest static void testSelectById(){
        new CourseAttemptsSelector().selectById(new Set<ID>());
        System.assert(true, 'Query compile properly');
    }
    @isTest static void testSelectActiveByContactIdAndCourseCode(){
        new CourseAttemptsSelector().getSObjectType();
        new CourseAttemptsSelector(false).selectActiveByContactIdAndCourseCode(null, null);
        System.assert(true, 'Query compile properly');
    }
}