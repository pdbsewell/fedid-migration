/**
 * Created by trentdelaney on 3/9/18.
 */

@isTest(isParallel=true)
private class ApplicationPathController_Test {

    TestMethod
    static void test_GetInitLoad()
    {

        User CommuUsr = StudFirst_TestHelper.createCommunityUser();

        Schema.DescribeFieldResult fieldResult = Application__c.Submission_Progress__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        Application__c app = StudFirst_TestHelper.createApplication(CommuUsr.ContactId);
        app.Submission_Progress__c = ple[0].getValue();
        insert app;
        Id appId = app.Id;

        Test.startTest();
        String state = ple[1].getValue();
        Map<String, Object> mapResults = ApplicationPathController.GetInitLoad(appId, state);

        Application__c appResult = [SELECT Id, Submission_Progress__c FROM Application__c WHERE Id =: appId];
        System.assertEquals(appResult.Submission_Progress__c, state, 'Application submission Progress should be updated, found ' + appResult.Submission_Progress__c );

        Test.stopTest();
    }

    @IsTest
    static void test_GetCurrentStatus()
    {
        User u = StudFirst_TestHelper.createCommunityUser();

        Application__c app = StudFirst_TestHelper.createApplication(u.ContactId);
        app.Submission_Progress__c = 'Declaration';
        insert app;

        System.runAs(u){
            String status = ApplicationPathController.GetCurrentStatus(app.Id);
            System.assertEquals('Declaration', status);

            status = ApplicationPathController.GetCurrentStatus('BadId');
            System.assertEquals(status, 'ERROR');

            status = ApplicationPathController.GetCurrentStatus(null);
            System.assertEquals(status, 'ERROR');
        }
    }

    @IsTest
    static void test_GetPicklist()
    {
        String[] values = ApplicationPathController.GetPicklist();
        System.assert(values.size() > 0);
    }

}