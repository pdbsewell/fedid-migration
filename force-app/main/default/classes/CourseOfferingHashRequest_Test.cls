/**
 * @description       : 
 * @author            : Ben Greenland
 * @group             : 
 * @last modified on  : 2024-07-11
 * @last modified by  : Ben Greenland
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2024-07-11   Ben Greenland   Initial Version
**/
@IsTest
public class CourseOfferingHashRequest_Test {

//class doesn't have any methods
@IsTest
static void testCourseOfferingHashRequest(){
        CourseOfferingHashRequest cohr = new CourseOfferingHashRequest();
        cohr.strId = 'xyz';
        cohr.strMixUniqueId = '123';
        Test.startTest();
        System.assertEquals('xyz', cohr.getStrId(), 'CourseOfferingHashRequest id has an error');
        System.assertEquals('123', cohr.getStrMixUniqueId(), 'CourseOfferingHashRequest strMixUniqueId has an error');
        Test.stopTest();
        
    }
}