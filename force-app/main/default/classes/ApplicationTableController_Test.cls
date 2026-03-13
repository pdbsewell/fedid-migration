/**
 * Created by trentdelaney on 3/9/18.
 */
@isTest(isParallel=true)
private class ApplicationTableController_Test {

    @IsTest
    static void test_RemoveApplication() {
        Contact c = StudFirst_TestHelper.createApplicant();
        insert c;

        Application__c app = StudFirst_TestHelper.createApplication(c);
        insert app;

        Boolean result = ApplicationTableController.RemoveApplication(app.Id);
        System.assertEquals(result, true);

        result = ApplicationTableController.RemoveApplication('badId');
        System.assertEquals(result, false);

        result = ApplicationTableController.RemoveApplication(null);
        System.assertEquals(result, false);
    }

    @IsTest
    static void test_RemoveAcp() {
        Contact c = StudFirst_TestHelper.createApplicant();
        insert c;

        Application__c app = StudFirst_TestHelper.createApplication(c);
        insert app;

        Course__c crs = StudFirst_TestHelper.createCourse();
        insert crs;

        Course_Offering__c off = StudFirst_TestHelper.createCourseOffering(crs);
        insert off;

        Application_Course_Preference__c acp = StudFirst_TestHelper.createCoursePreferences(app, c, off, crs);
        insert acp;

        Boolean result = ApplicationTableController.RemoveAcp(acp.Id);
        System.assertEquals(result, true);

        result = ApplicationTableController.RemoveAcp(null);
        System.assertEquals(result, false);

        result = ApplicationTableController.RemoveAcp('BadId');
        System.assertEquals(result, false);
    }

    @IsTest
    static void test_GetAppIdByAcp() {
        Contact c = StudFirst_TestHelper.createApplicant();
        insert c;

        Application__c app = StudFirst_TestHelper.createApplication(c);
        insert app;

        Course__c crs = StudFirst_TestHelper.createCourse();
        insert crs;

        Course_Offering__c off = StudFirst_TestHelper.createCourseOffering(crs);
        insert off;

        Application_Course_Preference__c acp = StudFirst_TestHelper.createCoursePreferences(app, c, off, crs);
        insert acp;

        String result = ApplicationTableController.GetAppIdByAcp(acp.Id);
        System.assertEquals(result, app.Id);

        result = ApplicationTableController.GetAppIdByAcp(null);
        System.assertEquals(result, 'ERROR');

        result = ApplicationTableController.GetAppIdByAcp('BadId');
        System.assertEquals(result, 'ERROR');
    }

    @IsTest
    static void test_GetAppByAcp()
    {

    }

    @IsTest
    static void test_getRecords()
    {
        Contact c = StudFirst_TestHelper.createApplicant();
        insert c;

        Application__c app = StudFirst_TestHelper.createApplication(c);
        insert app;

        Course__c crs = StudFirst_TestHelper.createCourse();
        insert crs;

        Course_Offering__c off = StudFirst_TestHelper.createCourseOffering(crs);
        insert off;

        Application_Course_Preference__c acp = StudFirst_TestHelper.createCoursePreferences(app, c, off, crs);
        insert acp;

        ApplicationTableController.DataTableResponse objects = ApplicationTableController.getRecords('Application_Course_Preference__c', 'myApp_Lightning_Table', '');
        System.assert(objects.lstDataTableColumns.size() > 0);
        System.assert(objects.lstDataTableData.size() > 0);
    }

}