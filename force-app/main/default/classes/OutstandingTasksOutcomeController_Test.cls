/**
* @description Test class for OutstandingTasksOutcomeController
* @author      Sravani Naramsetti
* @date        10/02/2025
* @group       Admissions
*/
@isTest(isParallel=true)
public class OutstandingTasksOutcomeController_Test {
	@testsetup
    public static void setup() {
		//create contact
        contact applicant = StudFirst_TestHelper.createApplicant();
        insert applicant;
        //create country
        Country_Attribute__c country =  new Country_Attribute__c();
        country.Country__c = 'India';
        country.GTE_Risk_Rating__c = '2';
        insert country;        
		//create application
        Application__c app = StudFirst_TestHelper.createInternationalApplication(applicant, country);
        app.HasDisabilities__c = 'Yes';
        app.Residency_Status__c = 'INTRNTNL';
        app.Existing_Aus_disability_support__c = 'No';
        app.Campus_Location__c = 'Australia';
        app.Submission_Location_Country__c = country.Id;
        insert app;
        //create course
        Course__c Course = StudFirst_TestHelper.createCourse();
        course.Course_Description__c = 'Master of Advanced Manufacturing Technology';
        insert Course;
        //create course offering
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        insert courseOffering;
        //create application course preference
        Application_Course_Preference__c coursePref = StudFirst_TestHelper.createCoursePreferences(app, applicant, courseOffering, course);
        coursePref.Preference_Number__c = '1';
        insert new List<Application_Course_Preference__c>{coursePref};
    }
    
    @isTest
    public static void WETaskExists() {
        //GIVEN: a ACP under Assessment
        Application_Course_Preference__c acp = [Select Id from Application_Course_Preference__c LIMIT 1];
        // Create Task for ACP
        RecordType taskrecType=[Select id from RecordType where SObjectType='Task' AND DeveloperName = 'Admissions'];
        Task tsk=new Task();
        tsk.Status ='In progress';
        tsk.RecordTypeId=taskrecType.Id;
        tsk.WhatId=acp.Id;
        tsk.Type='Work Experience';
        insert tsk;
        Test.startTest();
        //WHEN: 'Offer/Conditional Offer' made and has Active 'Work Experience' task on ACP
        List<OutstandingTasksOutcomeController.ValidationResponse> resp=OutstandingTasksOutcomeController.outstandingTasksOutcomeCheck(new List<Id>{acp.Id});
        //THEN: isBlocked is false
        Assert.areEqual(resp[0].isBlocked,false);
        Test.stopTest();
    }
    
    @isTest
    public static void GSTaskExists() {
        //GIVEN: a ACP under Assessment
        Application_Course_Preference__c acp = [Select Id from Application_Course_Preference__c LIMIT 1];
        // Create Task for ACP
        RecordType taskrecType=[Select id from RecordType where SObjectType='Task' AND DeveloperName = 'Admissions'];
        Task tsk=new Task();
        tsk.Status ='In progress';
        tsk.RecordTypeId=taskrecType.Id;
        tsk.WhatId=acp.Id;
        tsk.Type='Genuine Student';
        insert tsk;
        Test.startTest();
        //WHEN: 'Offer/Conditional Offer' made and has Active 'Genuine Student' task on ACP
        List<OutstandingTasksOutcomeController.ValidationResponse> resp=OutstandingTasksOutcomeController.outstandingTasksOutcomeCheck(new List<Id>{acp.Id});
        //THEN: isBlocked is true
        Assert.areEqual(resp[0].isBlocked,true);
        Test.stopTest();
    }
    
    @isTest
    public static void DSSTaskExists() {
        //GIVEN: a ACP under Assessment
        Application_Course_Preference__c acp = [Select Id from Application_Course_Preference__c LIMIT 1];
        // Create Task for ACP
        RecordType taskrecType=[Select id from RecordType where SObjectType='Task' AND DeveloperName = 'Admissions'];
        Task tsk=new Task();
        tsk.Status ='In progress';
        tsk.RecordTypeId=taskrecType.Id;
        tsk.WhatId=acp.Id;
        tsk.Type='Disability Support Service';
        insert tsk;
        Test.startTest();
        //WHEN: 'Offer/Conditional Offer' made and has Active 'DSS' task on ACP
        List<OutstandingTasksOutcomeController.ValidationResponse> resp=OutstandingTasksOutcomeController.outstandingTasksOutcomeCheck(new List<Id>{acp.Id});
        //THEN: isBlocked is true
        Assert.areEqual(resp[0].isBlocked,true);
        Test.stopTest();
    }
    
    @isTest
    public static void NGATaskExists() {
        //GIVEN: a ACP under Assessment
        Application_Course_Preference__c acp = [Select Id from Application_Course_Preference__c LIMIT 1];
        // Create Task for ACP
        RecordType taskrecType=[Select id from RecordType where SObjectType='Task' AND DeveloperName = 'Admissions'];
        Task tsk=new Task();
        tsk.Status ='In progress';
        tsk.RecordTypeId=taskrecType.Id;
        tsk.WhatId=acp.Id;
        tsk.Type='Non-guideline assessment';
        insert tsk;
        Test.startTest();
        //WHEN: 'Offer/Conditional Offer' made and has Active 'Non-guideline assessment' task on ACP
        List<OutstandingTasksOutcomeController.ValidationResponse> resp=OutstandingTasksOutcomeController.outstandingTasksOutcomeCheck(new List<Id>{acp.Id});
        //THEN: hasOutstandingTask is true
        Assert.areEqual(resp[0].hasOutstandingTask,true);
        Test.stopTest();
    }
    
    @isTest
    public static void GSAndWETaskExists() {
        //GIVEN: a ACP under Assessment
        Application_Course_Preference__c acp = [Select Id from Application_Course_Preference__c LIMIT 1];
        // Create Task for ACP
        RecordType taskrecType=[Select id from RecordType where SObjectType='Task' AND DeveloperName = 'Admissions'];
        Task tsk=new Task();
        tsk.Status ='In progress';
        tsk.RecordTypeId=taskrecType.Id;
        tsk.WhatId=acp.Id;
        tsk.Type='Genuine Student';
        insert tsk;
        Task tsk1=new Task();
        tsk1.Status ='In progress';
        tsk1.RecordTypeId=taskrecType.Id;
        tsk1.WhatId=acp.Id;
        tsk1.Type='Work Experience';
        insert tsk1;
        Test.startTest();
        //WHEN: 'Offer/Conditional Offer' made and has Active 'GS', 'WE' task on ACP
        List<OutstandingTasksOutcomeController.ValidationResponse> resp=OutstandingTasksOutcomeController.outstandingTasksOutcomeCheck(new List<Id>{acp.Id});
        //THEN: hasOutstandingTask is true, isBlocked is true
        Assert.areEqual(resp[0].hasOutstandingTask,true);
        Assert.areEqual(resp[0].isBlocked,true);
        Test.stopTest();
    }
}