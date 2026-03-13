/*******************************************************************************
* @author		Davey Yu
* @date         03.OCT.2024        
* @description  test class for ResearchProgramCC
* @revision     
*******************************************************************************/
@isTest(isParallel=false)//Due APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on the user object
public class ResearchProgramCC_Test {
	
    @isTest
    public static void testRetrieveApplicationCoursePreference()
    {
        
        //Create test Course
        User testApplicant = StudFirst_TestHelper.createCommunityUser();
        
        //creaate contact record
        Contact testContact = [SELECT Id FROM Contact WHERE Id =: testApplicant.contactId];
        testContact.Person_ID_unique__c = '12345678SA';
        update testContact;
        
        Application__c testApplication = StudFirst_TestHelper.createApplication(testContact.Id);
        testApplication.Type_of_Study__c ='Graduate Research';
        testApplication.Duration_of_Study__c ='1';
        testApplication.Applicant__c = testContact.Id;
        testApplication.Campus_Location__c = 'Australia';
        insert testApplication;
        
        //Create test Course
        Course__c testCourse = StudFirst_TestHelper.createCourse();
        insert testCourse;

        //Create test Offering
        Course_Offering__c testOffering = StudFirst_TestHelper.createCourseOffering(testCourse);
        testOffering.Start_date__C = Date.today();
        insert testOffering;

        //Create test ACP
        Application_Course_Preference__c testACP = StudFirst_TestHelper.createCoursePreferences(testApplication, testContact, testOffering, testCourse);
        testACP.Preference_Number__c = '1';
        testACP.Graduate_Research_Application_Type__c = 'Admission and Scholarship';
        insert testACP;

        Test.startTest();
        System.runAs(testApplicant){
            Map<String, Object> results = ResearchProgramCC.retrieveApplicationCoursePreference(testApplication.id);
            Application_Course_Preference__c acp2 = (Application_Course_Preference__c) results.get('acp');
            Assert.areEqual(acp2.Id, testACP.Id);
        }
        Test.stopTest();
    }
    
    /**
     * @author      Davey Yu
     * @description Test submitting a research program
     * @revision    03-OCT-2024 - Davey Yu - Created
     * 
     * GIVEN a new student is registered for my.app
     * WHEN student submitted a research program
     * THEN should successfully update the application course preference
     *
     */
    @isTest
    public static void testUpdateApplicationCoursePreference()
    {
        
        //Create test Course
        User testApplicant = StudFirst_TestHelper.createCommunityUser();
        
        //creaate contact record
        Contact testContact = [SELECT Id FROM Contact WHERE Id =: testApplicant.contactId];
        testContact.Person_ID_unique__c = '12345678SA';
        update testContact;
        
        Application__c testApplication = StudFirst_TestHelper.createApplication(testContact.Id);
        testApplication.Type_of_Study__c ='Graduate Research';
        testApplication.Duration_of_Study__c ='1';
        testApplication.Applicant__c = testContact.Id;
        testApplication.Campus_Location__c = 'Australia';
        insert testApplication;
        
        //Create test Course
        Course__c testCourse = StudFirst_TestHelper.createCourse();
        insert testCourse;

        //Create test Offering
        Course_Offering__c testOffering = StudFirst_TestHelper.createCourseOffering(testCourse);
        testOffering.Start_date__C = Date.today();
        insert testOffering;

        //Create test ACP
        Application_Course_Preference__c testACP = StudFirst_TestHelper.createCoursePreferences(testApplication, testContact, testOffering, testCourse);
        testACP.Preference_Number__c = '1';
        testACP.Graduate_Research_Application_Type__c = 'Admission and Scholarship';
        insert testACP;
        

        Test.startTest();
        System.runAs(testApplicant){
            List<String> days = new List<String>();
            days.add('Mon');
            Application_Course_Preference__c acp2 = ResearchProgramCC.updateApplicationCoursePreference(testACP, 'test', 'test', 'test', true, true, 'Both', 'test' ,
                                             '50', true, 'test', true, 'test', 'Part-Time/Casual', days, '7', 'test', 'Yes, I am willing to surrender my stipend/living allowance scholarship');
            Assert.areEqual(acp2.Id, testACP.Id);
        }
        Test.stopTest();
    }

}