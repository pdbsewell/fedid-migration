/**
 * @Class              : Course_Master_BS_Update_Fields_FT.cls
 * @Description        : Test class for for Course_Master_BS_Update_Course_Master_Fields before record trigger flow 
 * @Author             : Sachin Shetty
 * @Group              : Test Class
 * @Revision           : 
 * 2025-03-21   Sachin Shetty  Created 
 */
@isTest(isParallel=true)
public class Course_Master_BS_Update_Fields_FT {

    @testSetup
    static void testDataSetup() {
        Course_Master__c courseMaster = new Course_Master__c (name = 'Test Course Master', Course_Code__c = 'aCourse_100');
		insert courseMaster;
    }

    /*
    * @description: Tests whether Course Master name is updated
    */
    @isTest
    static void courseGroupMasterNameUpdate() {
        // GIVEN/WHEN - A Course Master is created
		List<Course_Master__c> courseMaster = [SELECT Name FROM Course_Master__c WHERE Course_Code__c = 'aCourse_100'];

        //THEN - Course Master name should be updated
		Assert.areEqual('aCourse_100', courseMaster[0].name, 'Course Master name not aligned');
    }
}