/**
 * @author Trent De Laney
 * @date 18 Mar 2019 at 11:07:46 am
 * @group Test Class
 * @description Covers the class Under 18 Controller
 */
@isTest(isParallel=true)
private class Under18Controller_Test {

    @IsTest
    public static void testGetApplicationFields() {
        //Create a Contact
        Contact c = StudFirst_TestHelper.createApplicant();
        insert c;
        //Create an Application
        Application__c app = StudFirst_TestHelper.createApplication(c);

        app.Guardian_Full_Name__c = 'Test Guardian Name';
        app.Guardian_Phone_Number__c = '0422222222';
        app.Guardian_Email_Address__c = 'test@test.com';
        app.Guardian_Relationship__c = 'Father';

        app.Residency_Status__c = 'INT-TEP';
        app.Campus_Location__c = 'Australia';
        insert app;

        Map<String, Object> result = Under18Controller.getApplicationFields(app.Id);

        Application__c returnedApp = (Application__c) result.get('Application');
        Boolean international = (Boolean) result.get('International');

        System.assertEquals(app.Guardian_Full_Name__c, returnedApp.Guardian_Full_Name__c);
        System.assertEquals(app.Guardian_Phone_Number__c, returnedApp.Guardian_Phone_Number__c);
        System.assertEquals(app.Guardian_Relationship__c, returnedApp.Guardian_Relationship__c);
        System.assertEquals(app.Guardian_Email_Address__c, returnedApp.Guardian_Email_Address__c);
        System.assertEquals(true, international);
    }

    @IsTest
    public static void testSaveApplication() {
        Contact c = StudFirst_TestHelper.createApplicant();
        insert c;

        Application__c app = StudFirst_TestHelper.createApplication(c);
        insert app;

        app.Guardian_Full_Name__c = 'Test Guardian Name';
        app.Guardian_Phone_Number__c = '0422222222';
        app.Guardian_Email_Address__c = 'test@test.com';
        app.Guardian_Relationship__c = 'Father';

        Under18Controller.saveApplication(app);

        Application__c savedApp = [
                SELECT Id, Guardian_Email_Address__c
                FROM Application__c
                WHERE Id = :app.Id
        ];

        System.assertEquals(savedApp.Guardian_Email_Address__c, app.Guardian_Email_Address__c);
    }
}