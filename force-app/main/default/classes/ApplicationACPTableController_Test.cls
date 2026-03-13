/**
 * Created by trentdelaney on 11/9/18.
 */

@isTest(isParallel=true)
private class ApplicationACPTableController_Test {

    @IsTest
    static void test_GetApplicationsWithACP()
    {
        User u = StudFirst_TestHelper.createCommunityUser();

        Contact c = [SELECT Id FROM Contact WHERE Id = :u.ContactId];

        Application__c app = StudFirst_TestHelper.createApplication(u.ContactId);
        insert app;


        System.runAs(u)
        {
            Course__c crs = StudFirst_TestHelper.createCourse();
            insert crs;

            Course_Offering__c off = StudFirst_TestHelper.createCourseOffering(crs);
            insert off;

            Application_Course_Preference__c acp = StudFirst_TestHelper.createCoursePreferences(app, c, off, crs);
            insert acp;

            String result = ApplicationACPTableController.GetApplicationsWithACP(false);
            System.assertNotEquals(null, result);

            result = ApplicationACPTableController.GetApplicationsWithACP(true);
            System.assertNotEquals(null, result);
        }
    }

    @IsTest
    static void test_EditApplication()
    {
        User u = StudFirst_TestHelper.createCommunityUser();

        Application__c app = StudFirst_TestHelper.createApplication(u.ContactId);
        insert app;

        System.runAs(u)
        {
            String result = ApplicationACPTableController.EditApplication();
            System.assertNotEquals(null, result);
        }

    }
    
    @IsTest
    static void test_RemoveApplication() {
        User u = StudFirst_TestHelper.createCommunityUser();

        System.runAs(u) {
            String value = ApplicationNavigationHomeController.CreateApplication();
            System.assertNotEquals(value, null);


            Boolean result = ApplicationACPTableController.RemoveApplication();
            System.assert(result, true);
        }
    }

}