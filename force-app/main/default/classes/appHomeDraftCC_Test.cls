@isTest(isParallel=true)
public class appHomeDraftCC_Test {

    TestMethod
    private static void test_noDrafts()
    {
        // create community user
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        // create application
        Application__c application = StudFirst_TestHelper.createApplication(c.Id);
        insert application;

        // Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        // offering
        Course_Offering__c offering = StudFirst_TestHelper.createCourseOffering(course);
        insert offering;

        // create ACP
        Application_Course_Preference__c acp = StudFirst_TestHelper.createCoursePreferences(application, c, offering, course);
        insert acp;

        // submit the application
        application.Status__c = 'Submitted';
        update application;

        Test.startTest();
        System.runAs(applicant)
        {
            Map<String, Object> mapResults = appHomeDraftCC.getInitLoadDrafts();
            System.assertNotEquals(null, mapResults, 'Results should not be null');
            Application__c appResult = (Application__c) mapResults.get(appHomeDraftCC.FIELD_APPLICATION);
            System.assertEquals(null, appResult, 'There should be no draft applications');
        }
    }


    TestMethod
    private static void test_getInitLoadDrafts()
    {
        // create community user
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        // create application
        Application__c application = StudFirst_TestHelper.createApplication(c.Id);
        insert application;

        // Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        // offering
        Course_Offering__c offering = StudFirst_TestHelper.createCourseOffering(course);
        insert offering;

        // create ACP
        Application_Course_Preference__c acp = StudFirst_TestHelper.createCoursePreferences(application, c, offering, course);
        insert acp;

        // submit the application
        application.Status__c = 'Draft';
        update application;

        Test.startTest();
        System.runAs(applicant)
        {
            Map<String, Object> mapResults = appHomeDraftCC.getInitLoadDrafts();
            System.assertNotEquals(null, mapResults, 'Results should not be null');
            Application__c appResult = (Application__c) mapResults.get(appHomeDraftCC.FIELD_APPLICATION);
            System.assertEquals(application.Id, appResult.Id, 'Application should be returned');
        }
    }

    TestMethod
    private static void test_cancelApplication()
    {
        // create community user
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        Test.startTest();
        System.runAs(applicant)
        {

            // create application
            Application__c application = StudFirst_TestHelper.createApplication(c.Id);
            insert application;

            // Course
            Course__c course = StudFirst_TestHelper.createCourse();
            insert course;

            // offering
            Course_Offering__c offering = StudFirst_TestHelper.createCourseOffering(course);
            insert offering;

            // create ACP
            Application_Course_Preference__c acp = StudFirst_TestHelper.createCoursePreferences(application, c, offering, course);
            insert acp;

            // submit the application
            application.Status__c = 'Draft';
            update application;

            Map<String, Object> mapResults = appHomeDraftCC.cancelApplication(application);
            System.assertNotEquals(null, mapResults, 'Results should not be null');
            Application__c appResult = (Application__c) mapResults.get(appHomeDraftCC.FIELD_APPLICATION);
            System.assertEquals(null, appResult, 'There should be no draft applications');
        }
    }

}