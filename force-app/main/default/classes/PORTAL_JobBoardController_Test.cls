@isTest(isParallel=true)
public class PORTAL_JobBoardController_Test {
       
    static public Contact con;
    static public User communityUser;
    static public Job__c job;
    
    static void setupData() {

        Id profileId = [select id from profile where name = :UserServices.CUSTOMER_COMMUNITY_PROFILE_COMMON].id;
        Account acct = new Account(name = 'ACME Co') ;
        insert acct;

        con = new Contact(LastName = 'Test_Contact',
                          AccountId = acct.Id,
                          Email = 'testCommunityUsermig123@test.com');
        insert con;

        communityUser = new User(alias = 'comUser',
                                 email = 'testCommunityUsermig123@test.com',
                                 emailencodingkey='UTF-8',
                                 lastname = 'Batman',
                                 languagelocalekey='en_US',
                                 localesidkey='en_US',
                                 profileid = profileId,
                                 IsActive = true,
                                 ContactId = con.Id,
                                 timezonesidkey='America/Los_Angeles',
                                 username = 'testCommunityUsermig123@test.com');
        insert communityUser;
        
        System.debug('communityUser: ' + communityUser.Id);
        System.debug('communityUser.ContactId: ' + communityUser.ContactId);
        
		job = new Job__c();
        job.Position_Type__c = 'Full Time Experienced';
        job.Expiration_Date__c = Date.today().addDays(1);
        job.Work_Hours_Per_Week__c = 40;
        job.Description__c = 'Produce technical design for custom development and systems integration requirements.';
		job.Class_Level_Degree_Level__c = 'Bachelors';
        job.Qualification__c = 'Minimum of Bachelor’s degree in Computer Science.';
        job.Location__c = 'Irvine, CA';
        job.Recruiting_Company__c = 'UC Innovation';
        job.Approximate_Salary__c = 140000.00;
        job.Name = 'Salesforce Technical Architect';
        job.Desired_Majors__c = 'Computer Science';
 
        PORTAL_JobBoardController.SERVER_createJobRecord(job);
    }
        
    static testMethod void applyToJob() {
        setupData();
        
        PORTAL_JobBoardController.SERVER_queryOpenJobs();
        PORTAL_JobBoardController.SERVER_queryPostedJobs();
        
        Map<string, object> filterCriteria = new Map<string, object>();
        
        filterCriteria.put('classDegreeLevel', 'All Levels');
        filterCriteria.put('keyWord', 'Salesforce');
        filterCriteria.put('locationKeyWord', 'Irvine');
        filterCriteria.put('positionType', 'All Position Type');
        filterCriteria.put('salaryLowerBound', 0);
        filterCriteria.put('salaryUpperBound', 150000);
        
		PORTAL_JobBoardController.SERVER_queryPostedJobsWithFilter(filterCriteria);

        ContentVersion contentVersion = new ContentVersion(
          Title = 'Software Engineer',
          PathOnClient = 'resume.pdf',
          VersionData = Blob.valueOf('Test Content'),
          IsMajorVersion = true
        );
        
        insert contentVersion;  
        
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
        //create ContentDocumentLink  record 
        ContentDocumentLink cdl = New ContentDocumentLink();
        
        cdl.LinkedEntityId = job.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;

        PORTAL_JobBoardController.SERVER_queryAppliedJobs();
        
        PORTAL_JobBoardController.SERVER_queryJobApplicants(job.Id);
    }
    
    static testMethod void noApplyToJob() {
        setupData();
        
        PORTAL_JobBoardController.SERVER_queryOpenJobs();
        PORTAL_JobBoardController.SERVER_queryPostedJobs();
        
        Map<string, object> filterCriteria = new Map<string, object>();
        
        filterCriteria.put('classDegreeLevel', 'All Levels');
        filterCriteria.put('keyWord', 'Salesforce');
        filterCriteria.put('locationKeyWord', 'Irvine');
        filterCriteria.put('positionType', 'All Position Type');
        filterCriteria.put('salaryLowerBound', 0);
        filterCriteria.put('salaryUpperBound', 150000);
        
		PORTAL_JobBoardController.SERVER_queryPostedJobsWithFilter(filterCriteria);

        PORTAL_JobBoardController.SERVER_queryAppliedJobs();
        
        PORTAL_JobBoardController.SERVER_queryJobApplicants(job.Id);
        
        PORTAL_JobBoardController.SERVER_deleteJobRecord(job.Id);
    }    

}