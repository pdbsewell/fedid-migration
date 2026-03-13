/**
 * @description       : Test Class for Task_AU_Sync_Task_Status_with_Application_and_ACP
 * @author            : sravani.naramsetti@monash.edu
 * @group             : 
 * @last modified on  : 14-01-2025
 * @last modified by  : rajesh.punjabi@monash.edu
**/
@isTest(isParallel=true)
public class TaskAUSyncTaskStatuswithAppandACP_FT {
    
    /**
    * @description Update Event: Update existing Task of GTE type status to Completed.
    * @author sravani.naramsetti@monash.edu | 29-05-2024 
    **/
    @isTest
    public static void updateTaskCompleted_Test(){
        // GIVEN : When there is an Application_Course_Preference__c with 'On Hold' Workflow_Status__c and Task In progress.
        Contact testApplicant = new Contact(LastName = 'TestApplicant', MailingCountry = 'Malaysia');
        insert testApplicant;
        
        Application__c oApplication = new Application__c();
        oApplication.Callista_Application_Id__c = 'CAID-1239090';
        oApplication.Fee_Payment__c = false;
        oApplication.Fee_Waiver_Redeemed__c = 'Test';    
        oApplication.Refused_entry_visa_to_any_country__c = 'Yes';
        oApplication.Breached_visa_condition__c = 'Yes';
        oApplication.Medical_health_prevent_visa__c = 'Yes';
        oApplication.Protection_visa_in_any_country__c = 'Yes';
        oApplication.Convicted_of_crime_offence__c = 'Yes';
        oApplication.HasDisabilities__c = 'Yes';
        oApplication.Submission_Progress__c = 'Submit';
        oApplication.Assessment_Status__c = 'Required';
        oApplication.Applicant__c = testApplicant.Id;
        insert oApplication;
        
        Application_Course_Preference__c acp1 = new Application_Course_Preference__c();
        acp1.Admissions_Assessment_Status__c = 'Not Started';
        acp1.Application__c = oApplication.Id;
        acp1.Workflow_Status__c = 'On Hold';
        acp1.On_Hold_Reason__c ='Credit Assessment required';
        insert acp1;
        
        // Create Task for ACP
        RecordType taskrecType=[Select id from RecordType where SObjectType='Task' AND DeveloperName = 'Admissions'];
        Task tsk=new Task();
        tsk.Status ='In progress';
        tsk.RecordTypeId=taskrecType.Id;
        tsk.WhatId=acp1.Id;
        tsk.Type='Genuine Temporary Entrant';
        insert tsk;
        
        Test.startTest();
        //WHEN :  Task is completed
        tsk.Status='Completed';
        tsk.Task_Outcome_Status__c ='Approved';
        update tsk;
        Test.stopTest();
        
        //THEN : Check for Released flag and Release reason on ACP
        Application_Course_Preference__c acpRetrieved=[Select id, Workflow_Status__c, Release_Reason__c from Application_Course_Preference__c where id=: acp1.id];
        Assert.areEqual ('Released', acpRetrieved.Workflow_Status__c);
        Assert.areEqual ('Genuine Temporary Entrant is Completed', acpRetrieved.Release_Reason__c);
        
    }
    
    /**
    * @description Update Event: Update existing Task of Credit Assessment type status to In progress.
    * @author sravani.naramsetti@monash.edu | 29-05-2024 
    **/
    @isTest
    public static void updateTaskStatus_Test(){
        // GIVEN : When there is an Application_Course_Preference__c with 'In Progress' Workflow_Status__c and Task Not Started.
        Contact testApplicant = new Contact(LastName = 'TestApplicant', MailingCountry = 'Malaysia');
        insert testApplicant;
        
        Application__c oApplication = new Application__c();
        oApplication.Callista_Application_Id__c = 'CAID-1239090';
        oApplication.Fee_Payment__c = false;
        oApplication.Fee_Waiver_Redeemed__c = 'Test';    
        oApplication.Refused_entry_visa_to_any_country__c = 'Yes';
        oApplication.Breached_visa_condition__c = 'Yes';
        oApplication.Medical_health_prevent_visa__c = 'Yes';
        oApplication.Protection_visa_in_any_country__c = 'Yes';
        oApplication.Convicted_of_crime_offence__c = 'Yes';
        oApplication.HasDisabilities__c = 'Yes';
        oApplication.Submission_Progress__c = 'Submit';
        oApplication.Assessment_Status__c = 'Required';
        oApplication.Applicant__c = testApplicant.Id;
        insert oApplication;
        
        Application_Course_Preference__c acp1 = new Application_Course_Preference__c();
        acp1.Admissions_Assessment_Status__c = 'Not Started';
        acp1.Application__c = oApplication.Id;
        acp1.Workflow_Status__c = 'In Progress';
        insert acp1;
        
        // Create Task for ACP
        RecordType taskrecType=[Select id from RecordType where SObjectType='Task' AND DeveloperName = 'Admissions'];
        Task tsk=new Task();
        tsk.Status ='Not Started';
        tsk.RecordTypeId=taskrecType.Id;
        tsk.WhatId=acp1.Id;
        tsk.Type='Credit Assessment';
        insert tsk;
        
        Test.startTest();
        //WHEN :  Task status is updated to In progress
        tsk.Status='In progress';
        update tsk;
        Test.stopTest();
        
        //THEN : Check for Released flag and Release reason on ACP
        Application_Course_Preference__c acpRetrieved=[Select id, Task_Credit__c from Application_Course_Preference__c where id=: acp1.id];
        Assert.areEqual ('In Progress', acpRetrieved.Task_Credit__c);
    }

    /**
    * @description Update Event: Update release flag, when task status = Awaiting CA Feedback
    * @author rajesh.punjabi@monash.edu | 13-01-2025 
    **/
    @isTest
    public static void updateTaskStatusAwaitingCAFeedback_Test(){
        // GIVEN : When  Application_Course_Preference__c Assessment Status changed to  'Awaiting CA Feedback', 
        // update status to inprogress and set release falg to true.
        Contact testApplicant = new Contact(LastName = 'TestApplicant', MailingCountry = 'Malaysia');
        insert testApplicant;
        
        Application__c oApplication = new Application__c();
        oApplication.Callista_Application_Id__c = 'CAID-1239090';
        oApplication.Fee_Payment__c = false;
        oApplication.Fee_Waiver_Redeemed__c = 'Test';    
        oApplication.Refused_entry_visa_to_any_country__c = 'Yes';
        oApplication.Breached_visa_condition__c = 'Yes';
        oApplication.Medical_health_prevent_visa__c = 'Yes';
        oApplication.Protection_visa_in_any_country__c = 'Yes';
        oApplication.Convicted_of_crime_offence__c = 'Yes';
        oApplication.HasDisabilities__c = 'Yes';
        oApplication.Submission_Progress__c = 'Submit';
        oApplication.Assessment_Status__c = 'Required';
        oApplication.Applicant__c = testApplicant.Id;
        insert oApplication;
        
        Application_Course_Preference__c oACP = new Application_Course_Preference__c();
        oACP.Admissions_Assessment_Status__c = 'Not Started';
        oACP.Application__c = oApplication.Id;
        oACP.Workflow_Status__c = 'On Hold';
        oACP.On_Hold_Reason__c = 'Applicant Input required';
        oACP.Release_Reason__c = '';
        insert oACP;
        
        // Create Task for ACP
        Task oTask = new Task();
        oTask.Status = 'Not Started';
        oTask.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Admissions').getRecordTypeId();
        oTask.WhatId = oACP.Id;
        oTask.Type = 'Credit Assessment';
        insert oTask;
        
        Test.startTest();
        //WHEN :  Task status is updated to Awaiting CA Feedback
        oTask.Status = 'Awaiting CA Feedback';
        update oTask;
        Test.stopTest();
        
        //THEN : Check for Released flag
        Application_Course_Preference__c acpRetrieved = [SELECT Id, Workflow_Status__c FROM Application_Course_Preference__c WHERE Id=: oACP.Id];
        Assert.areEqual ('Released', acpRetrieved.Workflow_Status__c);   
    }
}