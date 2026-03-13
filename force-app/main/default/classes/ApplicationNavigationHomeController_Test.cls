/**
 * @author Trent De Laney
 * @date 21 Feb 2019 at 3:35:29 pm
 * @group Test Class
 * @description Defines the test class functionality for Application Home Controller
 */
@isTest(isParallel=true)
private class ApplicationNavigationHomeController_Test {

    @IsTest
    static void test_CreateApplication() {
        User u = StudFirst_TestHelper.createCommunityUser();

        List<Contact> contacts = [
                SELECT Id
                FROM Contact
                WHERE Id = :u.ContactId
        ];

        if(contacts.size() > 0){
            Work_Experience__c work = StudFirst_TestHelper.createWorkExperience(contacts[0]);
            insert work;
        }

        System.runAs(u) {
            String value = ApplicationNavigationHomeController.CreateApplication();
            System.assertNotEquals(value, null);
        }
    }

    @IsTest
    static void test_HasDrafts() {
        User u = StudFirst_TestHelper.createCommunityUser();

        System.runAs(u) {
            Boolean result = ApplicationNavigationHomeController.HasDrafts();
            System.assertEquals(result, false);

            Application__c app = StudFirst_TestHelper.createApplication(u.ContactId);
            insert app;

            result = ApplicationNavigationHomeController.HasDrafts();
            System.assertEquals(result, true);
        }
    }

    @IsTest
    static void test_EditApplication() {
        User u = StudFirst_TestHelper.createCommunityUser();

        Application__c app = StudFirst_TestHelper.createApplication(u.ContactId);
        insert app;

        System.runAs(u) {
            String result = ApplicationNavigationHomeController.EditApplication();
            System.assertNotEquals(null, result);
        }

    }
}