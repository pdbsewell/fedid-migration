//APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object: User
@isTest(isParallel=false)
public class appAddWorkExperienceCC_Test {

    private static String getDefaultCountry()
    {
        Country_Attribute__c country = new Country_Attribute__c();
        country.Country__c = 'Australia';
        insert country;

        return country.Id;
    }

    TestMethod
    public static void test_getInitLoad()
    {
        // create community user
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        insert app;

        // create a country object for code coverage
        getDefaultCountry();

        Test.startTest();
        System.runAs(applicant) {

            Map<String, Object> mapResults = appAddWorkExperienceCC.getInitLoad(app.Id);
            User userResult = (User) mapResults.get(appAddWorkExperienceCC.FIELD_USER);
            System.assertEquals(applicant.Id, userResult.Id, 'Applicant should have been returned');

        }

        Test.stopTest();
    }

    TestMethod
    public static void test_saveRetrieveWorkExperience()
    {
        // create community user
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];


        // create applications
        List<Application__c> apps = new List<Application__c>();
        Application__c appPrevious = StudFirst_TestHelper.createApplication(c.Id);
        apps.add(appPrevious);

        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        apps.add(app);
        insert apps;


        // create a work experience for the previous application
        Work_Experience__c wexp = StudFirst_TestHelper.createWorkExperience(c);
        insert wexp;
        Application_Work_Experience_Provided__c awp = StudFirst_TestHelper.createAppWorkExpProvided(appPrevious.Id, wexp.Id);
        insert awp;

        Test.startTest();
        System.runAs(applicant) {

            Work_Experience__c workExp = new Work_Experience__c();
            //workExp.Contact__c = c.Id;
            workExp.Country__c = getDefaultCountry();
            workExp.Position__c = 'Janitor';
            workExp.Employer_Name__c = 'Monash';
            workExp.Start_Date__c = Date.today();

            Map<String, Object> mapResults = appAddWorkExperienceCC.saveWorkExperience(app.Id, workExp);
            String saveStatus = (String) mapResults.get(appAddWorkExperienceCC.FIELD_SAVE_STATUS);
            System.assertEquals(appAddWorkExperienceCC.SUCCESS, saveStatus, 'Insert should succeed');

            Map<String, Object> mapUpdate = appAddWorkExperienceCC.saveWorkExperience(app.Id, workExp);
            String updateStatus = (String) mapUpdate.get(appAddWorkExperienceCC.FIELD_SAVE_STATUS);
            System.assertEquals(appAddWorkExperienceCC.SUCCESS, updateStatus, 'Update should succeed');


            Map<String, Object> mapRetrieve = appAddWorkExperienceCC.retrieveWorkExpForEdit(workExp.Id);
            List<Work_Experience__c> listWorkExps = (List<Work_Experience__c>) mapResults.get(appAddWorkExperienceCC.FIELD_WORK_EXPERIENCES);
            System.assertEquals(1, listWorkExps.size(), '1 result should be retrieved');

        }

        Test.stopTest();
    }

    TestMethod
    public static void test_saveWorkExperienceErrors()
    {
        // create community user
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        insert app;

        Test.startTest();
        System.runAs(applicant) {

            Map<String, Object> mapNull = appAddWorkExperienceCC.saveWorkExperience(app.Id, null);
            String nullStatus = (String) mapNull.get(appAddWorkExperienceCC.FIELD_SAVE_STATUS);
            System.assertEquals(appAddWorkExperienceCC.FAILED, nullStatus, 'null object should fail');


            Work_Experience__c workExp = new Work_Experience__c();
            Map<String, Object> mapResults = appAddWorkExperienceCC.saveWorkExperience(app.Id, workExp);
            String saveStatus = (String) mapResults.get(appAddWorkExperienceCC.FIELD_SAVE_STATUS);
            System.assertEquals(appAddWorkExperienceCC.FAILED, saveStatus, 'Validation should fail');

            List<String> listErrors = (List<String>) mapResults.get(appAddWorkExperienceCC.FIELD_ERRORS);
            System.assertNotEquals(0, listErrors.size(), 'There should be save errors');


        }

        Test.stopTest();
    }


    TestMethod
    public static void test_deleteWorkExperience() {
        // create community user
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id = :applicant.contactId];

        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        insert app;

        Test.startTest();
        System.runAs(applicant) {

            Work_Experience__c workExp = new Work_Experience__c();
            workExp.Country__c = getDefaultCountry();
            workExp.Position__c = 'Janitor';
            workExp.Employer_Name__c = 'Monash';
            workExp.Start_Date__c = Date.today();

            Map<String, Object> mapResults = appAddWorkExperienceCC.saveWorkExperience(app.Id, workExp);
            String saveStatus = (String) mapResults.get(appAddWorkExperienceCC.FIELD_SAVE_STATUS);
            System.assertEquals(appAddWorkExperienceCC.SUCCESS, saveStatus, 'Insert should succeed');

            Map<String, Object> mapDelete = appAddWorkExperienceCC.deleteWorkExp(c.Id, app.Id);
            String delStatus = (String) mapDelete.get(appAddWorkExperienceCC.FIELD_DELETE_STATUS);
            System.assertEquals(appAddWorkExperienceCC.FAILED, delStatus, 'Delete should fail on bad Id');

            mapDelete = appAddWorkExperienceCC.deleteWorkExp(workExp.Id, app.Id);
            delStatus = (String) mapDelete.get(appAddWorkExperienceCC.FIELD_DELETE_STATUS);
            System.assertEquals(appAddWorkExperienceCC.SUCCESS, delStatus, 'Delete should succeed');
        }
        Test.stopTest();
    }



}