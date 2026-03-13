/**
 * @author      Kristian Vegerano
 * @description Test class for CourseOfferingCC class
 * @group       Test Class
 * @revision    16/09/2019 - Kristian Vegerano - Created
 */
@isTest(isParallel=true)
public with sharing class CourseOfferingCC_Test {
    /**
     * @description Setup test data
     */
    @testSetup 
    static void setup() {
        //Create community user
        User testApplicant = StudFirst_TestHelper.createCommunityUser();
        Contact testContact = [SELECT Id FROM Contact WHERE Id =: testApplicant.contactId];

        //Create test Create application
        Application__c testApplication = StudFirst_TestHelper.createApplication(testContact.Id);
        insert testApplication;

        //Create test Course
        Course__c testCourse = StudFirst_TestHelper.createCourse();
        insert testCourse;

        //Create test Offering
        Course_Offering__c testOffering = StudFirst_TestHelper.createCourseOffering(testCourse);
        insert testOffering;

        //Create test ACP
        Application_Course_Preference__c testACP = StudFirst_TestHelper.createCoursePreferences(testApplication, testContact, testOffering, testCourse);
        insert testACP;

        //Submit the application
        testApplication.Status__c = 'Submitted';
        testApplication.Residency_Status__c = 'DOM-AUS';
        update testApplication;

        //Added list of values reference records
        List<List_of_Values__c> lstOfValues = new List<List_of_Values__c>();
        List_of_Values__c lov1 = new List_of_Values__c();
            lov1.Value__c = 'PENDING';
            lov1.Type__c =    'ADM_DOC_STATUS';
            lov1.System_Code_Description__c = 'DOCUMENTARY EVIDENCE NOT YET ASSESSED';
            lov1.System_Code__c = 'PENDING';
        lstOfValues.add(lov1);
        List_of_Values__c lov2 = new List_of_Values__c();
            lov2.Value__c = 'NOT-APPLIC';
            lov2.Type__c =    '  ADM_OFFER_DFRMNT_STATUS';
            lov2.System_Code_Description__c = 'DEFERRAL OF ADMISSION NOT ALLOWED';
            lov2.System_Code__c = 'NOT-APPLIC';
        lstOfValues.add(lov2);
        List_of_Values__c lov5 = new List_of_Values__c();
        	lov5.Value__c = 'NOT-APPLIC';
            lov5.Type__c =    'ADM_OFFER_RESP_STATUS';
            lov5.System_Code_Description__c = 'RESPONSE TO OFFER NOT REQUIRED';
            lov5.System_Code__c = '  NOT-APPLIC';
            lov5.Government_Code__c = '6';
            lov5.Description__c = 'Applicant is not required to respond';
        lstOfValues.add(lov5);
        List_of_Values__c lov6 = new List_of_Values__c();
            lov6.Value__c = 'NOT-APPLIC';
            lov6.Type__c =    'ADM_CNDTNL_OFFER_STATUS';
            lov6.System_Code_Description__c = 'NO CONDITIONS ATTACHED TO OFFER';
            lov6.System_Code__c = 'NOT-APPLIC';
        lstOfValues.add(lov6);
        List_of_Values__c lov3 = new List_of_Values__c();
            lov3.Value__c = 'PENDING';
            lov3.Type__c =    'ADM_ENTRY_QUAL_STATUS';
            lov3.System_Code_Description__c = 'ENTRY QUALIFICATIONS YET TO BE DETERMINED';
            lov3.System_Code__c = 'PENDING';
        lstOfValues.add(lov3);
        List_of_Values__c lov4 = new List_of_Values__c();
            lov4.Value__c = 'AP-PROGRES';
            lov4.Type__c =    'ADM_OUTCOME_STATUS';
            lov4.System_Code_Description__c = 'APPLICATION UNDER CONSIDERATION';
            lov4.System_Code__c = 'AP-PROGRES';
        lstOfValues.add(lov4);
        insert lstOfValues;
    }

    /**
     * @description Test seedComponent method
     */
    @isTest 
    static void test_SeedComponent() {
        //Initialize variables
        Map<String, List<String>> componentResults;

        //Start test process
	 	Test.startTest();
            componentResults = CourseOfferingCC.seedComponent();
	 	Test.stopTest();

        //Start assertion
        System.assertNotEquals(componentResults, null);
    }

    /**
     * @description Test searchCourseOffering method
     */
    @isTest 
    static void test_SearchCourseOffering() {
        //Initialize variables
        List<Course_Offering__c> listCourseOffering;

        //Prepare search details
        CourseOfferingCC.SearchCriteria testSearch = new CourseOfferingCC.SearchCriteria();
        testSearch.courseCode = '';
        testSearch.courseName = '12345';
        testSearch.intakePeriod = '';
        testSearch.attendanceMode = '';
        testSearch.location = '';

        //Start test process
	 	Test.startTest();
            listCourseOffering = CourseOfferingCC.searchCourseOffering(JSON.serialize(testSearch));
	 	Test.stopTest();

        //Start assertion
        System.assertNotEquals(listCourseOffering, null);
    }

    /**
     * @description Test getApplicationACPs method
     */
    @isTest 
    static void test_GetApplicationACPs() {
        //Initialize variables
        List<Application_Course_Preference__c> listApplicationCoursePreferences;

        //Retrieve test ACP
        Application_Course_Preference__c testACP = [SELECT Id FROM Application_Course_Preference__c LIMIT 1];

        //Start test process
	 	Test.startTest();
            listApplicationCoursePreferences = CourseOfferingCC.getApplicationACPs(testACP.Id);
	 	Test.stopTest();

        //Start assertion
        System.assertNotEquals(listApplicationCoursePreferences, null);
    }

    /**
     * @description Test addACPs method for domestic applications
     */
    @isTest 
    static void test_AddACPsOnDomesticApplication() {
        //Initialize variables
        List<String> courseOfferingIds = new List<String>();

        //Retrieve test queries
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        Course_Offering__c testCourseOffering = [SELECT Id FROM Course_Offering__c LIMIT 1];

        //Retrieve test ACP
        Application_Course_Preference__c testACP = [SELECT Id FROM Application_Course_Preference__c LIMIT 1];
        delete testACP;

        //Start test process
	    Test.startTest();
            //Add test course offering id
            courseOfferingIds.add(testCourseOffering.Id);
            //Test running adding application course preferences
            CourseOfferingCC.addACPs(testApplication.Id, JSON.serialize(courseOfferingIds));
	 	Test.stopTest();

        //Start assertion
        System.assertEquals([SELECT Id FROM Application_Course_Preference__c].size(), 1);
    }

    /**
     * @description Test addACPs method for international applications
     */
    @isTest 
    static void test_AddACPsOnInternationalApplication() {
        //Initialize variables
        List<String> courseOfferingIds = new List<String>();

        //Retrieve test queries
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        testApplication.Residency_Status__c = 'INTRNTNL';
        update testApplication;
        
        Course_Offering__c testCourseOffering = [SELECT Id FROM Course_Offering__c LIMIT 1];

        //Retrieve test ACP
        Application_Course_Preference__c testACP = [SELECT Id FROM Application_Course_Preference__c LIMIT 1];
        delete testACP;

        //Start test process
	    Test.startTest();
            //Add test course offering id
            courseOfferingIds.add(testCourseOffering.Id);
            //Test running adding application course preferences
            CourseOfferingCC.addACPs(testApplication.Id, JSON.serialize(courseOfferingIds));
	 	Test.stopTest();

        //Start assertion
        System.assertEquals([SELECT Id FROM Application_Course_Preference__c].size(), 1);
    }
}