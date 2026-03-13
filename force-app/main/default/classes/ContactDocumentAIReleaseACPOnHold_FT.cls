/**
 * @description       : Test Class for Contact_Document_AI_Release_ACP_On_Hold
 * @author            : sravani.naramsetti@monash.edu
 * @group             : 
 * @last modified on  : 28-05-2024
 * @last modified by  : sravani.naramsetti@monash.edu
**/
@isTest(isParallel=true)
public class ContactDocumentAIReleaseACPOnHold_FT {
    
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
    * @description Insert Event: Add new Contact Document.
    * @author sravani.naramsetti@monash.edu | 28-05-2024 
    **/
    @isTest
    public static void insertContactDocument_Test(){
        // GIVEN : When there is an Application_Course_Preference__c with 'On Hold' Workflow_Status__c.
        Application_Course_Preference__c oACP = [SELECT Id, Application__c, Application__r.Applicant__c FROM Application_Course_Preference__c LIMIT 1];
        
        // Create Contact Document for application
        Contact_Document__c contactDocument = new Contact_Document__c(
            Application__c = oACP.Application__c,
            Document_Type__c = 'OTHERDCTYP',
            Contact__c=oACP.Application__r.Applicant__c
        );
        
        Test.startTest();
        //WHEN : Contact Document against ACP's application is uploaded
        insert contactDocument;
        Test.stopTest();
        
        //THEN : Check for Released flag and Release reason on ACP
        Application_Course_Preference__c acpRetrieved=[Select id, Workflow_Status__c, Release_Reason__c from Application_Course_Preference__c where id=: oACP.id];
        Assert.areEqual ('Released', acpRetrieved.Workflow_Status__c);
        Assert.areEqual ('New document attached to application.', acpRetrieved.Release_Reason__c);
        
    }
    
    /**
    * @description Insert Event: Add new Contact Document.
    * @author sravani.naramsetti@monash.edu | 28-05-2024 
    **/
    @isTest
    public static void insertContactDocumentCompleted_Test(){
        // GIVEN : When there is an Application_Course_Preference__c with 'Completed' Workflow_Status__c.
        Application_Course_Preference__c oACP = [SELECT Id, Application__c, Application__r.Applicant__c FROM Application_Course_Preference__c WHERE On_Hold_Reason__c = 'Applicant Input required' LIMIT 1];
        oACP.Workflow_Status__c = 'Completed';
        update oACP;
        
        // Create Contact Document for application
        Contact_Document__c contactDocument = new Contact_Document__c(
            Application__c = oACP.Application__c,
            Document_Type__c = 'OTHERDCTYP',
            Contact__c=oACP.Application__r.Applicant__c
        );
        
        Test.startTest();
        //WHEN : Contact Document against ACP's application is uploaded
        insert contactDocument;
        Test.stopTest();
        
        //THEN : Check for Released flag and Release reason on ACP
        Application_Course_Preference__c acpRetrieved=[Select id, Workflow_Status__c, Release_Reason__c from Application_Course_Preference__c where id=: oACP.id];
        Application_Course_Preference__c acpRetrieved1=[Select id, Workflow_Status__c from Application_Course_Preference__c where On_Hold_Reason__c = 'Conditional offer issued'];
        Assert.areEqual ('Released', acpRetrieved.Workflow_Status__c);
        Assert.areEqual ('Completed', acpRetrieved1.Workflow_Status__c);
        Assert.areEqual ('New document attached to application.', acpRetrieved.Release_Reason__c);
        
    }
}