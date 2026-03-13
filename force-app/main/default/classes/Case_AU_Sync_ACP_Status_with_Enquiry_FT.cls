/**
 * @description       : ACP Sync with Enquiry. Test class for Case_AU_Sync_ACP_Status_with_Enquiry.
 * @author            : rajesh.punjabi@monash.edu
 * @group             : 
 * @last modified on  : 26-11-2024
 * @last modified by  : rajesh.punjabi@monash.edu
**/
@isTest (isParallel=true)
public with sharing class Case_AU_Sync_ACP_Status_with_Enquiry_FT {

    @testSetup
    public static void setup() {
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
        acp1.On_Hold_Reason__c = 'Applicant Input required';
        insert acp1;
        
        Application_Course_Preference__c acp2 = new Application_Course_Preference__c();
        acp2.Admissions_Assessment_Status__c = 'Not Started';
        acp2.Application__c = oApplication.Id;
        acp2.Workflow_Status__c = 'Completed';
        acp2.On_Hold_Reason__c = 'Conditional offer issued';
        insert acp2;
    }
    
    @isTest
    public static void linkEnquiryWithACP_Test(){
        // GIVEN : Get ACP
        Application_Course_Preference__c oACP = [SELECT Id FROM Application_Course_Preference__c LIMIT 1];
        
        Case oCase = new Case();
        oCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Admissions').getRecordTypeId();
        oCase.Incoming_Email__c = false;
        insert oCase;

        //WHEN :  Update Incoming Flag = true
        Test.startTest();
        oCase.Application_Course_Preference__c = oACP.Id;
        update oCase;
        Test.stopTest();
        
        //THEN : Check if Status = Released. 
        Application_Course_Preference__c acpRetrieved=[SELECT Id, Workflow_Status__c FROM Application_Course_Preference__c WHERE Id=:oACP.Id];
        Assert.areEqual ('Released', acpRetrieved.Workflow_Status__c);
    }

    @isTest
    public static void updateIncomingFlag_Test(){
         // GIVEN : Get ACP.
        Application_Course_Preference__c oACP = [SELECT Id FROM Application_Course_Preference__c LIMIT 1];
        
        Case oCase = new Case();
        oCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Admissions').getRecordTypeId();
        oCase.Incoming_Email__c = false;
        oCase.Application_Course_Preference__c = oACP.Id;
        insert oCase;

        //WHEN :  Link enquiry to ACP
        Test.startTest();
        oCase.Incoming_Email__c = true;
        update oCase;
        Test.stopTest();
        
        //THEN : Check if Status = Released.
        Application_Course_Preference__c acpRetrieved=[SELECT Id, Workflow_Status__c FROM Application_Course_Preference__c WHERE Id=:oACP.Id];
        Assert.areEqual ('Released', acpRetrieved.Workflow_Status__c);
    }
    
    @isTest
    public static void updateIncomingFlagCompleted_Test(){
         // GIVEN : Get ACP.
        Application_Course_Preference__c oACP = [SELECT Id FROM Application_Course_Preference__c WHERE On_Hold_Reason__c = 'Applicant Input required' LIMIT 1];
        
        Case oCase = new Case();
        oCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Admissions').getRecordTypeId();
        oCase.Incoming_Email__c = false;
        oCase.Application_Course_Preference__c = oACP.Id;
        insert oCase;
        
        oACP.Workflow_Status__c = 'Completed';
        update oACP;

        //WHEN :  Link enquiry to ACP
        Test.startTest();
        oCase.Incoming_Email__c = true;
        update oCase;
        Test.stopTest();
        
        //THEN : Check if Status = Released.
        Application_Course_Preference__c acpRetrieved=[SELECT Id, Workflow_Status__c, OwnerId FROM Application_Course_Preference__c WHERE Id=:oACP.Id];
        Group grp = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'CENTRAL_ADMISSIONS_MUDocs'];
        Assert.areEqual ('Released', acpRetrieved.Workflow_Status__c);
        Assert.areEqual ('CENTRAL_ADMISSIONS_MUDocs', grp.DeveloperName);
    }
}