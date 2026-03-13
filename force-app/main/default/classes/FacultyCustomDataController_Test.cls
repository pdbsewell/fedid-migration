/**
 * @author Nadula Karunaratna
 * @date 14-01-2020
 * @group Professional Development
 * @description Test class for the Controller class FacultyCustomDataController, which used by visualforce components FacultyCustomData*
*/

@isTest(isParallel=true)
private class FacultyCustomDataController_Test{
    
    Faculty_Custom_Data__mdt myFacultyCustomData1 = new Faculty_Custom_Data__mdt();
    Faculty_Custom_Data__mdt myFacultyCustomData2 = new Faculty_Custom_Data__mdt();

    @isTest static void testGetFacultyData(){

        FacultyCustomDataController fcdc = new FacultyCustomDataController();
        
        //Positive test

        //Start test
        fcdc.facultyName = 'Faculty of Education';
        Faculty_Custom_Data__mdt myFacultyCustomData1 = fcdc.getFacultyData();        

        //Set response for assertion
        String testValue1 = '+61 3 9905 2700';
        
        //Test response
        System.assertEquals(testValue1, myFacultyCustomData1.Faculty_Phone__c, 'Value Failed testValue');

        //Negative test
        
        //Start test
        fcdc.facultyName = null;
        Faculty_Custom_Data__mdt myFacultyCustomData2 = fcdc.getFacultyData(); 

		//Test response
        System.assertEquals(null, myFacultyCustomData2, 'Value Failed testValue');

    }

    
}