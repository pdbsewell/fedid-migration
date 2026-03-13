/**
 * @description       : Verify the GTE Risk Rating for Applicantion Qualification.
 * @author            : rajesh.punjabi@monash.edu
 * @group             : 
 * @last modified on  : 03-06-2024
 * @last modified by  : rajesh.punjabi@monash.edu
**/
@isTest (isParallel=true)
Private class ContactQualAUSyncGTERiskRating_FT {
    
    /**
    * @description Validate and Sync GTE Risking Rating for Contact Qualification.
    * @author rajesh.punjabi@monash.edu | 03-06-2024 
    **/
    @isTest
    private static void syncGTERiskRating_Test(){
        
        // GIVEN : Create Country and Application (Only GTE Task = required), Applicant and Contact Qualification
        Country_Attribute__c oCountry = new Country_Attribute__c();
        oCountry.Name = 'Iran-test';
        oCountry.GTE_Risk_Rating__c = '3';
        oCountry.Active_Ind__c = true;
        insert oCountry;

		Contact oApplicant = new Contact(LastName = 'TestApplicant', MailingCountry = 'Malaysia');
        insert oApplicant;
        
        Application__c oApplication = new Application__c();
        oApplication.Callista_Application_Id__c = 'CAID-1239090';
        oApplication.Submission_Location_Country__c = oCountry.Id;
        oApplication.Submission_Progress__c = 'Submit';
        oApplication.Assessment_Status__c = 'Required';
        oApplication.Applicant__c = oApplicant.Id;
        insert oApplication;
        
        Contact_Qualification__c oConQual = new Contact_Qualification__c();
    	oConQual.RecordTypeId = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByDeveloperName().get('English_Test').getRecordTypeId();
        oConQual.Qualification_Country__c = oCountry.Id;
        oConQual.Contact__c = oApplicant.Id;
        
        // WHEN : Create Qualication Record.
        Test.startTest();
        insert oConQual;
        Test.stopTest();
        
        // THEN : Verify if GTE Task status is set to required.
        Application__c oApplicationRecord = [SELECT Id, Task_GTE__c FROM Application__c WHERE Callista_Application_Id__c = 'CAID-1239090' LIMIT 1];
        Assert.areEqual (oApplicationRecord.Task_GTE__c, 'Required', 'GTE Task is required for assessor.');
        
    }
}