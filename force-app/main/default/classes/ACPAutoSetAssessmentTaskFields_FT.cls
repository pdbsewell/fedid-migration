/**
 * @description       : Test Class for ACP_Auto_Set_Assessment_Task_Fields
 * @author            : sravani.naramsetti@monash.edu
 * @group             : 
 * @last modified on  : 31-05-2024
 * @last modified by  : sravani.naramsetti@monash.edu
**/
@isTest(isParallel=true)
public class ACPAutoSetAssessmentTaskFields_FT {
    
    /**
    * @description Update Task_Credit__c on ACP as Required when creditIntention is true
    * @author sravani.naramsetti@monash.edu | 31-05-2024 
    **/
    @isTest
    public static void updateACPTaskCredit_Test(){
        // GIVEN : When there is an ACP with Task_Credit__c not equals Required
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
        
        //WHEN :  creditIntention is true
        Map<String, Object> inputs = new Map<String, Object> {
          'varAppId' => oApplication.id,
          'varCreditIntention' => true
        };
        Flow.Interview flw = new Flow.Interview.ACP_Auto_Set_Assessment_Task_Fields(inputs);
        Test.startTest();
        flw.start();
        Test.stopTest();
        
        //THEN : Task_Credit__c on ACP will be 'Required'
        Application_Course_Preference__c acpRetrieved=[SELECT Id, Task_Credit__c FROM Application_Course_Preference__c WHERE Id=:acp1.Id];
        Assert.areEqual ('Required', acpRetrieved.Task_Credit__c);
    }
}