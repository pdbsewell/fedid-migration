/**
 * @author      Vishal Gupta
 * @description test class for MyAppApplicationAuthenticator
 * @group       My App Community Services
 * @created on  28/03/2025
 */
 //APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object: User
@isTest(isParallel=false)
private class MyAppApplicationAuthenticator_Test {
    @isTest
    /**
     * @author      vishal gupta
     * @description Tests the authentication if the record is related to logged in user
     *
     * GIVEN there are existing application for Graduate Research
     * WHEN the logged in user tries to update the application under the logged in user
     * THEN system should authenticate the applicant record against the logged in user
     */
    public static void testApplicationAuthentication()
    {
        // create community user        
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];
        Test.startTest();
        System.runAs(applicant) {
            
            Application__c app = StudFirst_TestHelper.createApplication(c.Id);
            app.Applicant__c = c.Id;
            app.Type_Of_Study__c = 'Graduate Research';
            insert app;

            MyAppApplicationAuthenticator obj = new MyAppApplicationAuthenticator(app);
            Assert.areEqual(obj.isRecordRelatedToCurrentUser(), true);
        }
        Application__c app = [SELECT Applicant__c FROM Application__c LIMIT 1];
        MyAppApplicationAuthenticator obj = new MyAppApplicationAuthenticator(app);
        Assert.areEqual(obj.isRecordRelatedToCurrentUser(), false);

        Test.stopTest();
    }
}