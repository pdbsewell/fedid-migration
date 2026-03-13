/**
 * @Class              : Course_Offering_AS_Field_Updates_FT.cls
 * @Description        : Test class for for Course_Offering_AS_Course_Offering_Field_Updates after record trigger flow 
 * @Author             : Sachin Shetty
 * @Group              : Test Class
 * @Revision           : 
 * 2025-04-08   Sachin Shetty  Created 
 */
@isTest(isParallel=true)
public class Course_Offering_AS_Field_Updates_FT {

    @testSetup
    static void testDataSetup() {        
        // create community user
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        // create application
        Application__c application = StudFirst_TestHelper.createApplication(c.Id);
        insert application;

        // Course
        Course__c course = StudFirst_TestHelper.createCourse();
        course.Type__c = 'Professional Development';
        insert course;
        
        // venue
        Venue__c venue = new Venue__c();
        venue.Name = 'Test venue';
        venue.Legacy_Venue_ID__c = '1';
        venue.Minimum_Capacity__c = 1;
        venue.Maximum_Capacity__c = 5;
        venue.Course_Type__c = 'Short Course';
        venue.Managing_Faculty__c = 'Faculty of Education';  
        insert venue;
        
        // offering
        Course_Offering__c offering = StudFirst_TestHelper.createCourseOffering(course);
        offering.Venue__c = venue.Id;
        insert offering;

        // create ACP
        Application_Course_Preference__c acp = StudFirst_TestHelper.createCoursePreferences(application, c, offering, course);
        insert acp;
    }
    
    /*
    * @description: Tests whether cancelled postponed date is updated
    */
    @isTest
    static void cancelledPostponedDate() {
        // GIVEN : A Course Offering
        List<Course_Offering__c> courseOffering = [SELECT Id, Course_Code__c,Status__c FROM Course_Offering__c];
        String cc = courseOffering.get(0).Course_Code__c;
        
        // WHEN : Course Offering status is updated to Cancelled
        Test.startTest();
            courseOffering.get(0).Status__c = 'Cancelled';
            update courseOffering;
        Test.stopTest();
        courseOffering = [SELECT Date_Cancelled_Postponed__c FROM Course_Offering__c WHERE Course_Code__c = :cc];

        //THEN : Course Offering name should be updated
		Assert.areEqual(System.Today(), courseOffering.get(0).Date_Cancelled_Postponed__c, 'Course Offering status should be Cancelled');
    }
    
    /*
    * @description: Tests whether Course Offering status is updated
    */
    @isTest
    static void maximumCapacityReached() {
        // GIVEN : A Course Offering
        List<Course_Offering__c> courseOffering = [SELECT Id, Course_Code__c,Status__c FROM Course_Offering__c];
        String cc = courseOffering.get(0).Course_Code__c;
        
        // WHEN : Course Offering registration count is updated to more tham venue maximum capacity
        Test.startTest();
        	courseOffering.get(0).Status__c = 'Available';
            courseOffering.get(0).Registration_Count__c = 6;
            update courseOffering;
        Test.stopTest();
        courseOffering = [SELECT Status__c FROM Course_Offering__c WHERE Course_Code__c = :cc];

        //THEN : Course Offering status should be updated to Full
		Assert.areEqual('Full', courseOffering.get(0).Status__c, 'Course Offering status should be Full');
    }
    
    /*
    * @description: Tests whether Course Offering Course Type and Faculty fields are updated
    */
    @isTest
    static void updateShortCourseFields() {
        // GIVEN : A Course Offering
        Course__c pdCourse = new Course__c();
        pdCourse.Name = '22334';
        pdCourse.Type__c = 'Short_Course';
        pdCourse.Managing_Faculty__c = 'Faculty of Arts';
        insert pdCourse;
        
        // WHEN : New Course Offering is created
        Test.startTest();
            Course_Offering__c offering2 = StudFirst_TestHelper.createCourseOffering(pdCourse);
            offering2.Course_Code__c = 'E22334';
            insert offering2;
        Test.stopTest();
        
        List<Course_Offering__c> offerings = [SELECT Course_Type__c, Faculty__c FROM Course_Offering__c WHERE Course_Code__c = 'E22334'];

        //THEN : Course Offering course type and faculty should be updated
		Assert.areEqual('Professional Development', offerings.get(0).Course_Type__c, 'Course Offering course type should be Professional Development');
        Assert.areEqual('Faculty of Arts', offerings.get(0).Faculty__c, 'Course Offering course type should be Faculty of Arts');
    }
    
    /*
    * @description: Tests whether Course Offering - Registration Close Date is updated
    */
    @isTest
    static void updateRegistrationCloseDate() {
        // GIVEN/WHEN - A Course Offering
        Date todayDate = System.today();
        Course__c pdCourse = new Course__c();
        pdCourse.Name = '22334';
        pdCourse.Type__c = 'Short_Course';
        insert pdCourse;
        
        // WHEN : New Course Offering is created
        Test.startTest();
            Course_Offering__c offering2 = StudFirst_TestHelper.createCourseOffering(pdCourse);
            offering2.Course_Code__c = 'E22334';
            offering2.Start_Date__c = todayDate;
            insert offering2;
        Test.stopTest();
        
        List<Course_Offering__c> offerings = [SELECT Registration_Close_Date__c FROM Course_Offering__c WHERE Course_Code__c = 'E22334'];

        Date registrationCloseDate = todayDate.addDays(-1);
        
        //THEN - Course Offering - Registration Close Date should be updated
		Assert.areEqual(registrationCloseDate, offerings.get(0).Registration_Close_Date__c, 'Course Offering registration close date not set');
    }
    
    /*
    * @description: Tests whether ACP - Course Confirmed is updated
    */
    @isTest
    static void updateACPToConfirmed() {
        // GIVEN/WHEN - A Course Offering
        Course__c course = [SELECT Id, Type__c FROM Course__c LIMIT 1];
        course.Type__c = 'Short_Course';
        update course;
        
        Application_Course_Preference__c acp = [SELECT Id, Status__c, Course_Offering__c FROM Application_Course_Preference__c LIMIT 1];
        acp.Status__c = 'Registered';
        update acp;
        String acpId = acp.Id;
        String coId = acp.Course_Offering__c;
        
        // WHEN : New Course Offering is updated
        Test.startTest();
            Course_Offering__c offering = [SELECT Id, Confirmed__c, Status__c FROM Course_Offering__c WHERE Id = :coId];
            offering.Confirmed__c = true;
            offering.Status__c = 'Available';
            update offering;    
        Test.stopTest();
             
        acp = [SELECT Course_Confirmed__c FROM Application_Course_Preference__c WHERE Id = :acpId];
        
        //THEN - ACP - Course Confirmed should be updated
		Assert.isTrue(acp.Course_Confirmed__c, 'ACP Course Confirmed should be True');
    }
    
    /*
    * @description: Tests whether ACP - Status is updated
    */
    @isTest
    static void updateACPToCancelled() {
        // GIVEN - A Course Offering and Short Course course
        Course__c course = [SELECT Id, Type__c FROM Course__c LIMIT 1];
        course.Type__c = 'Short_Course';
        update course;
        
        Application_Course_Preference__c acp = [SELECT Id, Status__c, Course_Offering__c FROM Application_Course_Preference__c LIMIT 1];
        acp.Status__c = 'Registered';
        update acp;
        String acpId = acp.Id;
        String coId = acp.Course_Offering__c;

        // WHEN : Course Offering is updated
        Test.startTest();        
            Course_Offering__c offering = [SELECT Id, Confirmed__c, Status__c FROM Course_Offering__c WHERE Id = :coId];
            offering.Confirmed__c = false;
            offering.Status__c = 'Cancelled';
        	offering.Reason_for_Cancellation__c = 'Cancelled Reason';
            update offering;     
        Test.stopTest();
              
        acp = [SELECT Status__c FROM Application_Course_Preference__c WHERE Id = :acpId];
        
        //THEN - ACP status should be updated to Cancelled
		Assert.areEqual('Cancelled', acp.Status__c, 'ACP status should be Cancelled');
    }    
}