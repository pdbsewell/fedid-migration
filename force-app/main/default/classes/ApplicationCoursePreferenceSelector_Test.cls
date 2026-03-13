/*******************************************************************************
* @author		Vishal Gupta
* @date         14/10/2024    
* @description  Test Class for ApplicationCoursePreferenceSelector Class
* @revision     14/10/2024 - Initial Version
*******************************************************************************/
@isTest(isParallel = true)
public class ApplicationCoursePreferenceSelector_Test {

    @TestSetup
    static void makeData() {
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];
        //create Academic Org unit account
        Account testAcademicOrg = new Account(Name = 'test Academic Org unit', Callista_Org_Unit_Code__c='TEST123');
        insert testAcademicOrg;
        //create faculty account
        Account testFaculty = new Account(Name = 'test faculty', Callista_Org_Unit_Code__c='TEST12398', Monash_AM_Start_Date__c=Date.Today(), RecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'Account' AND Name = 'Faculty'][0].Id);
        insert testFaculty;

        //create application
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        app.Type_Of_Study__c = 'Graduate Research';
        app.Callista_Applicant_Id__c = '3434343';
        insert app;
        // Create Course
        Course__c course = StudFirst_TestHelper.createCourse();
        course.Faculty__c = testFaculty.Id;
        insert course;

        // Creare Course Offering
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        insert courseOffering;

        //create Application_Course_Preference__c
        Application_Course_Preference__c coursePreference = StudFirst_TestHelper.createCoursePreferences(app, c, courseOffering, course);
        coursePreference.Academic_Org_Unit__c = testAcademicOrg.Id;
        coursePreference.Employment_Days__c = 'Mon;Tue';
        coursePreference.Employment_Hours__c = 20;
        coursePreference.GradRes_Callista_Id__c = '54356546';
        insert coursePreference;
    }
    /**
     * @author          Vishal Gupta
     * @description     selecting the application course preference  
     * @revision        14/10/2024 - Initial Version
     */
    @isTest static void testApplicationCourseSelector() {
        Test.startTest();
        //given, there is an application exists submitted form my.app
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        //when, we query the application course preference related to the application
        List<Application_Course_Preference__c> lstACP = new ApplicationCoursePreferenceSelector().selectByApplicationIdWithParentDetails(new Set<Id>{app.Id});
        //then, it should return the data accordingley
        Assert.areEqual(1, lstACP.size(), 'acp query should return the records');
        Test.stopTest();
    }
    /**
     * @author          Vishal Gupta
     * @description     selecting the application course preference  
     * @revision        14/1/2025 - Initial Version
     */
    @isTest static void testApplicationCourseSelectorByApplicantId() {
        Test.startTest();
        //given, there is an ACP exists submitted from my.app which is already submitted to callista and has the HDR application number
        Application_Course_Preference__c acp = [SELECT GradRes_Callista_Id__c FROM Application_Course_Preference__c LIMIT 1];
        //when, we query the application course preference related to the applicant and HDR application number
        List<Application_Course_Preference__c> lstACP = new ApplicationCoursePreferenceSelector().selectByApplicantIdWithCalendarDetails(new Set<String>{'3434343'}, new Set<String>{acp.GradRes_Callista_Id__c});
        //then, it should return the data accordingley
        Assert.areEqual(1, lstACP.size(), 'acp query should return the records');
        Test.stopTest();
    }
}