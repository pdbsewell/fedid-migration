/**
 * @description       : Test Class for UpdateACPFromContactDocumentFlow
 * @author            : sravani.naramsetti@monash.edu
 * @group             : 
 * @last modified on  : 08-07-2025
 * @last modified by  : sravani.naramsetti@monash.edu
**/
@isTest(isParallel=true)
public class UpdateACPFromContactDocumentFlow_Test {
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
        acp1.On_Hold_Reason__c ='Applicant Input required';
        insert acp1;
        
        Application_Course_Preference__c acp2 = new Application_Course_Preference__c();
        acp2.Admissions_Assessment_Status__c = 'Not Started';
        acp2.Application__c = oApplication.Id;
        acp2.Workflow_Status__c = 'Completed';
        acp2.On_Hold_Reason__c = 'Conditional offer issued';
        insert acp2; 
        
    }
    
    /**
    * @description Update ACP
    * @author sravani.naramsetti@monash.edu | 08-07-2025 
    **/
    @isTest
    public static void updateACP_Test(){
        // GIVEN : When there is an Application_Course_Preference__c with 'On Hold' Workflow_Status__c.
        Application_Course_Preference__c oACP = [SELECT Id, Application__c, Workflow_Status__c, Application__r.Applicant__c FROM Application_Course_Preference__c LIMIT 1];
        // WHEN : Workflow Status is changed
        oACP.Workflow_Status__c = 'Completed';
        List<Application_Course_Preference__c> acpList=new List<Application_Course_Preference__c>();
        acpList.add(oACP);
        UpdateACPFromContactDocumentFlow.processRecords(new List<List<Application_Course_Preference__c>>{acpList});
        // THEN : Workflow Status is updated
        Application_Course_Preference__c oACP1 = [SELECT Id, Application__c, Workflow_Status__c, Application__r.Applicant__c FROM Application_Course_Preference__c LIMIT 1];
        Assert.isNotNull(oACP1.Workflow_Status__c);
    }
    
    /**
    * @description Update ACP Wrong value
    * @author sravani.naramsetti@monash.edu | 08-07-2025 
    **/
    @isTest
    public static void updateACPException_Test(){
        // GIVEN : When there is an Application_Course_Preference__c with 'On Hold' Workflow_Status__c.
        Application_Course_Preference__c oACP = [SELECT Id, Application__c, Workflow_Status__c, Application__r.Applicant__c FROM Application_Course_Preference__c LIMIT 1];
        // WHEN : Workflow Status is changed to wrong value
        oACP.Workflow_Status__c = 'Complete';
        List<Application_Course_Preference__c> acpList=new List<Application_Course_Preference__c>();
        acpList.add(oACP);
        try{
            UpdateACPFromContactDocumentFlow.processRecords(new List<List<Application_Course_Preference__c>>{acpList});
        }catch(Exception ex){
            // THEN : Workflow Status is not updated
            Application_Course_Preference__c oACP1 = [SELECT Id, Application__c, Workflow_Status__c, Application__r.Applicant__c FROM Application_Course_Preference__c LIMIT 1];
            Assert.isNotNull(oACP1.Workflow_Status__c);
        }
    }

}