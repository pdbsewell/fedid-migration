/**
* @author Vineeth Batreddy
* @date 2017
* @group Professional Development
* @description Test class for CourseLookupController
* @revision Nadula karunaratna | 14-02-2020 | Refactored test class by seperating test methods, adding System.assertEquals and added a new test method testRetrieveFacultyData.
*/
@isTest(isParallel=true)
private class CourseLookupController_Test {
	
    @isTest static void testGetCourseOffering() {        
       	Course__c course = PDTestHelper.createCourse();
       	Course_Offering__c co = PDTestHelper.createCourseOffering();
       	co.Course__c = course.Id;
       	update co;		
		String courseName = course.Name;
        String courseFaculty = course.Managing_Faculty__c;
        System.DEBUG('courseName='+courseName);        
        
        Test.startTest();
       	//Positive test
        List<Course_Offering__c> courseOfferingsTrue = CourseLookupController.getCourseOffering(courseName);
        //Negative test
        List<Course_Offering__c> courseOfferingsFalse = CourseLookupController.getCourseOffering('courseNameTestText');
        Test.stopTest();       
	}

	@isTest static void testGetCourseDetails() {        
       	Course__c course = PDTestHelper.createCourse();
       	Course_Offering__c co = PDTestHelper.createCourseOffering();
       	co.Course__c = course.Id;
       	update co;		
		String courseName = course.Name;
        Test.startTest();
        //Positive test
       	Course__c courseDetailsTrue = CourseLookupController.getCourseDetails(courseName);
        //Negative test
        Course__c courseDetailsFalse = CourseLookupController.getCourseDetails('courseNameTestText');
        Test.stopTest();
        System.assertEquals(courseName, courseDetailsTrue.Name);  
        System.assert(courseDetailsFalse == null);
	}    
    
	@isTest static void testRetrieveFacultyEmail(){        
       	Course__c course = PDTestHelper.createCourse();	
		String courseName = course.Name; 
       	
        Test.startTest(); 
        //Positive test
        String facultyEmailTrue = CourseLookupController.retrieveFacultyEmail(courseName);        
        //Negative test
        String facultyEmailFalse = CourseLookupController.retrieveFacultyEmail('courseNameTestText');
        Test.stopTest();
        
        System.assert(facultyEmailTrue != null);
        System.assert(facultyEmailFalse == null);
    }

	@isTest static void testRetrieveFacultyData(){        
       	Course__c course = PDTestHelper.createCourse();	
		String courseName = course.Name;
        String courseFaculty = course.Managing_Faculty__c;
       	
        Test.startTest();
        //Positive test
        List<Faculty_Custom_Data__mdt> facultyDataTrue = CourseLookupController.retrieveFacultyData(courseName);
        //Negative test
        List<Faculty_Custom_Data__mdt> facultyDataFalse = CourseLookupController.retrieveFacultyData('courseNameTestText');
        Test.stopTest();        
        System.assertEquals(courseFaculty, facultyDataTrue[0].Managing_Faculty__c);  
        System.assert(facultyDataFalse == null);
    }
}