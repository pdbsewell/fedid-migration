/*******************************************************************************
* @author		Vishal Gupta
* @date         14/10/2024    
* @description  Test Class for GRSendApplicationToCallistaQueuable Class
* @revision     14/10/2024 - Initial Version
*******************************************************************************/
@isTest(isParallel = true)
public class GRSendApplicationToCallistaQueuable_Test {

    @TestSetup
    static void makeData() {
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];
        //create Academic Org unit account
        Account testAcademicOrg = new Account(Name = 'test Academic Org unit', Callista_Org_Unit_Code__c='TEST123');
        insert testAcademicOrg;
        //create faculty account
        Account testFaculty = new Account(Name = 'test faculty', Callista_Org_Unit_Code__c='TEST12398', Monash_AM_Start_Date__c=Date.Today(), RecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'Account' AND Name = 'Faculty'][0].Id);
        insert testFaculty;

        //create application
        Application__c app = StudFirst_TestHelper.createApplication(c.Id);
        app.Type_Of_Study__c = 'Graduate Research';
        insert app;
    }
    /**
     * @author          Vishal Gupta
     * @description     triggering the GRSendApplicationToCallistaQueuable job when Application's GR_Callista_Document_Submission_Date__c is updated
     * @revision        14/10/2024 - Initial Version
     */
    @isTest static void testGRApplicationQueuable() {
        Test.startTest();
        GRSendApplicationToCallistaAPIMock mock = new GRSendApplicationToCallistaAPIMock();
        mock.responseCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);

        //Given, there is an application exists submitted from my.app
        Application__c app = [SELECT Id, Agent__c, GR_Callista_Document_Submission_Date__c FROM Application__c LIMIT 1];
        app.GR_Callista_Document_Submission_Date__c = Datetime.now();

        //When, the application's GR_Callista_Document_Submission_Date__c is updated
        update app;
        Test.stopTest();
        Boolean jobEnqueued = false;
        //Then, it should queue the GRSendApplicationToCallistaQueuable job
        Id batchClassId = [SELECT Id FROM ApexClass WHERE Name = 'GRSendApplicationToCallistaQueuable'].Id;
        for (AsyncApexJob job : [SELECT Id, ApexClassId FROM AsyncApexJob]) {
            if (job.ApexClassId == batchClassId) {
                jobEnqueued = true;
                break;
            }
        }
        Assert.areEqual(true, jobEnqueued, 'GRSendApplicationToCallistaQueuable job should be enqueued');
    }
    
}