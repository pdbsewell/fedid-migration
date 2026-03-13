/**
 * @description       : Test class for OrganisationalUnitServiceBatch Batch Class
 * @author            : Inderpal Dhanoa
 * @group             : Enterprise Engage
 * @revisions
 * 2021-09-17  Inderpal Dhanoa - Added test scenarios for OrganisationalUnitServiceBatch
 * 2024-09-11  Martin Cadman   - Moved to Assert class
 * 
**/
@isTest // (isParallel=true) In parallel Apex tests, DML operations aren't permitted on this type of object: CronJobDetail
public class OrganisationalUnitServiceBatch_Test { 
    
    @testSetup
    static void testSetup() {
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Monash_Organisation').getRecordTypeId();
        Account acc1 = new Account(Name='acc1', Callista_Org_Unit_Code__c='50000250',recordTypeId=recordTypeId);
        insert acc1;
    }
    /**
     * @author                      Inderpal Dhanoa
     * @created                     2021-09-17
     * @description                 Test for retrieving SAP HR Org Units to be synced with CRM
    */
    public class FindRelatedMonashOrgs implements HttpCalloutMock {
    // Implement this interface method
        public HTTPResponse respond(HTTPRequest request) { 
            // Create a fake response
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('[{"id": "50000250","level": "1","name": "MONASH UNIVERSITY","shortName": "MONASH","startDate": "1958-01-01","endDate": "9999-12-31","owner": "00000000","relationshipStart": "2021-08-27","relationshipEnd": "2050-12-31","linkedFacultyPortfolioId": "50025576","linkedFacultyPortfolioDesc": "Monash University 9A"},{"id": "50000251","level": "1","name": "MONASH UNIVERSITY 2","shortName": "MONASH","startDate": "1958-01-01","endDate": "3999-12-31","owner": "00000000","relationshipStart": "2021-08-27","relationshipEnd": "9999-12-31","linkedFacultyPortfolioId": "50025576","linkedFacultyPortfolioDesc": "Monash University 9A"}]');
            response.setStatusCode(200);
            return response; 
        }
    }

    
    /**
     * @author                      Inderpal Dhanoa
     * @created                     2021-09-17
     * @description                 Test for retrieving SAP HR Org Units to be synced with CRM
    */
    @isTest 
	private static void testGetCallout() {
        //Initialize Variables
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        /* GIVEN */
        // The Faculty Accounts are created with diff Account name
        
        /* THEN */
        //Execute the Batch Job to sync the Accounts
        Test.setMock(HttpCalloutMock.class, new FindRelatedMonashOrgs());
        Test.startTest();

        List<Org_Unit__c> l_stagingRecds = [Select Id,Status__c,Org_Id__c,Name from Org_Unit__c];
    
        OrganisationalUnitServiceBatch batchObj = new OrganisationalUnitServiceBatch (); 
        Database.executeBatch(batchObj,2);
        
        Test.stopTest();

        //THEN: Check if the Accounts have been synced
        l_stagingRecds = [Select Id,Status__c,Org_Id__c,Name from Org_Unit__c];
        Assert.areEqual(l_stagingRecds.size(),2);

        List<Job_Control__c> l_jobList = [Select Id, Processing_Status__c from Job_Control__c];
        Assert.areEqual(l_jobList[0].Processing_Status__c,'Target Load Completed');

        List<Account> relAccount = [SELECT Id, Name, Organisation_Unit_Name__c FROM Account WHERE Callista_Org_Unit_Code__c='50000250'];
        Assert.areEqual(relAccount[0].Organisation_Unit_Name__c,'MONASH UNIVERSITY');

	}

    /**
     * @author                      Inderpal Dhanoa
     * @created                     2021-09-17
     * @description                 Test for checking the Schedule with CRM
    */
    @isTest
    public static void testExecuteSchedule() {
        //Initialize Variables
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        //Start Test
        Test.setMock(HttpCalloutMock.class, new FindRelatedMonashOrgs());

        /* GIVEN */
        //Unscheduled Job if it is scheduled / currently running
        List<AsyncApexJob> asyncApexJobList = [SELECT ApexClassId,ApexClass.Name,Id,JobType,Status 
                                               FROM AsyncApexJob WHERE ApexClass.Name = 'OrganisationalUnitServiceBatch' 
                                               AND JobType = 'ScheduledApex'];
        if(asyncApexJobList != null && !asyncApexJobList.isEmpty()) {
            for(AsyncApexJob cron :asyncApexJobList) {
                //Delete the Job in schdule during test context
                System.abortJob(cron.Id);
            }
        }
        //Unscheduled Job if it is scheduled
        List<CronTrigger> cjdList = [SELECT CronJobDetailId,Id,State FROM CronTrigger WHERE CronJobDetail.Name = 'OrganisationalUnitServiceBatch'];
        if(cjdList != null && !cjdList.isEmpty()) {
            for(CronTrigger cjd :cjdList) {
                System.abortJob(cjd.Id);
            }
        }
        /* WHEN */
        // the Scheduled batch Job is executed 
        // call custom schedule method which set default schedule
        Test.startTest();
        OrganisationalUnitServiceBatch jb = new OrganisationalUnitServiceBatch();
        Test.stopTest();

        //THEN: Check the Scheule Job
        String jobId = jb.schedule();
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime, State FROM CronTrigger WHERE Id = :jobId];
        Assert.areEqual(0, ct.TimesTriggered, 'Scheduled Apex job is not scheduled to be run.');
        
    }

}