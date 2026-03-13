/**
 * @description       : Test class for Application_BS_Set_Assessment_Task_Fields Flow
 * @author            : rajesh.punjabi@monash.edu
 * @group             : 
 * @last modified on  : 28-05-2024
 * @last modified by  : rajesh.punjabi@monash.edu
**/
@isTest (isParallel=true)
public class ApplicationBSSetAssessmentTaskFields_FT {
    
    /**
    * @description Insert Event: Add new application.
    * @author rajesh.punjabi@monash.edu | 28-05-2024 
    **/
    @isTest
    private static void insertAssessmentTask_Test(){

        // GIVEN : Create Country and Application (Only GTE Task = required)
        Country_Attribute__c oCountry = new Country_Attribute__c();
        oCountry.Name = 'Iran-test';
        oCountry.GTE_Risk_Rating__c = '3';
        oCountry.Active_Ind__c = true;
        insert oCountry;
        
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
        oApplication.Submission_Location_Country__c = oCountry.Id;
        oApplication.Submission_Progress__c = 'Submit';
        oApplication.Assessment_Status__c = 'Required';
        
        Test.startTest();
        // WHEN : Push application with required status values.
        insert oApplication;
        Test.stopTest();
        
        // THEN : Verify if Task(s) status is required.
        Application__c oApplicationRecord = [SELECT Id, Task_Visa__c, Task_Disability_Check__c, Task_GTE__c, Task_Fee__c FROM Application__c WHERE Callista_Application_Id__c = 'CAID-1239090' LIMIT 1];
        Assert.areEqual (oApplicationRecord.Task_Disability_Check__c, 'Required', 'DSS Task is required for assessor.');
        Assert.areEqual (oApplicationRecord.Task_GTE__c, 'Required', 'GTE Task is required for assessor.');
		Assert.areEqual (oApplicationRecord.Task_Fee__c, 'Required', 'Fee Task is required for assessor.');
		Assert.areEqual (oApplicationRecord.Task_Visa__c, 'Required', 'Visa Task is required for assessor.');
    }
    
    /**
    * @description  Update Event: Update existing application.
    * @author rajesh.punjabi@monash.edu | 28-05-2024 
    **/
    @isTest
    private static void updateAssessmentTask1_Test(){

		// GIVEN : Create and update Country and Application (All GTE Task = required)
        Country_Attribute__c oCountry = new Country_Attribute__c();
        oCountry.Name = 'Iran-test';
        oCountry.GTE_Risk_Rating__c = '3';
        oCountry.Active_Ind__c = true;
        insert oCountry;
        
        Application__c oApplication = new Application__c();
		oApplication.Callista_Application_Id__c = 'CAID-1238080';
        oApplication.Fee_Payment__c = false;
        oApplication.Fee_Waiver_Redeemed__c = 'Test';    
        oApplication.Refused_entry_visa_to_any_country__c = 'Yes';
        oApplication.Breached_visa_condition__c = 'Yes';
        oApplication.Medical_health_prevent_visa__c = 'Yes';
        oApplication.Protection_visa_in_any_country__c = 'Yes';
        oApplication.Convicted_of_crime_offence__c = 'Yes';
        oApplication.HasDisabilities__c = 'Yes';
        oApplication.Submission_Location_Country__c = oCountry.Id;
        insert oApplication; 
        
        oApplication.Submission_Progress__c = 'Submit';
        oApplication.Assessment_Status__c = 'Required';
        
        Test.startTest();
        // WHEN : Update application with required status values.
        update oApplication;
        Test.stopTest();
        
        Application__c oApplicationRecord = [SELECT Id, Task_Visa__c, Task_Disability_Check__c, Task_GTE__c, Task_Fee__c FROM Application__c WHERE Callista_Application_Id__c = 'CAID-1238080' LIMIT 1];
        Assert.areEqual (oApplicationRecord.Task_Disability_Check__c, 'Required', 'DSS Task is required for assessor.');
        Assert.areEqual (oApplicationRecord.Task_GTE__c, 'Required', 'GTE Task is required for assessor.');
		Assert.areEqual (oApplicationRecord.Task_Fee__c, 'Required', 'Fee Task is required for assessor.');
		Assert.areEqual (oApplicationRecord.Task_Visa__c, 'Required', 'Visa Task is required for assessor.');
    }
    
    /**
    * @description Update application with GTE Risk Rating 1
    * @author rajesh.punjabi@monash.edu | 28-05-2024 
    **/
    @isTest
    private static void updateAssessmentTask2_Test(){
		
        // GIVEN : Create Country and Application (All Task = not required)
        Country_Attribute__c oCountry = new Country_Attribute__c();
        oCountry.Name = 'Iran-test';
        oCountry.GTE_Risk_Rating__c = '1';
        oCountry.Active_Ind__c = true;
        insert oCountry;
        
        Application__c oApplication = new Application__c();
		oApplication.Callista_Application_Id__c = 'CAID-1238081';
        oApplication.Fee_Payment__c = true;
        oApplication.Refused_entry_visa_to_any_country__c = 'No';
        oApplication.Breached_visa_condition__c = 'No';
        oApplication.Medical_health_prevent_visa__c = 'No';
        oApplication.Protection_visa_in_any_country__c = 'No';
        oApplication.Convicted_of_crime_offence__c = 'No';
        oApplication.HasDisabilities__c = 'No';
        oApplication.Submission_Location_Country__c = oCountry.Id;
        insert oApplication; 
        
        oApplication.Submission_Progress__c = 'Submit';
        oApplication.Assessment_Status__c = 'Required';
        
        Test.startTest();
        // WHEN : Update application with required status values.
        update oApplication;
        Test.stopTest();
        
        // THEN : Verify if Task(s) status is required.
        Application__c oApplicationRecord = [SELECT Id, Task_Visa__c, Task_Disability_Check__c, Task_GTE__c, Task_Fee__c FROM Application__c WHERE Callista_Application_Id__c = 'CAID-1238081' LIMIT 1];
        Assert.areEqual (oApplicationRecord.Task_Disability_Check__c, 'Not Required', 'DSS Task is required for assessor.');
        Assert.areEqual (oApplicationRecord.Task_GTE__c, 'Not Required', 'GTE Task is required for assessor.');
		Assert.areEqual (oApplicationRecord.Task_Fee__c, 'Not Required', 'Fee Task is required for assessor.');
		Assert.areEqual (oApplicationRecord.Task_Visa__c, 'Not Required', 'Visa Task is not required for assessor.');
    }
    
    /**
    * @description Update Application with GTE Risk Rating 3
    * @author rajesh.punjabi@monash.edu | 28-05-2024 
    **/
    @isTest
    private static void updateAssessmentTask3_Test(){
		
        // GIVEN : Create Country and Application (Only GTE Task = not required)
        Country_Attribute__c oCountry = new Country_Attribute__c();
        oCountry.Name = 'Iran-test';
        oCountry.GTE_Risk_Rating__c = '3';
        oCountry.Active_Ind__c = true;
        insert oCountry;
        
        Application__c oApplication = new Application__c();
		oApplication.Callista_Application_Id__c = 'CAID-1238080';
        oApplication.Fee_Payment__c = true;
        oApplication.Refused_entry_visa_to_any_country__c = 'No';
        oApplication.Breached_visa_condition__c = 'No';
        oApplication.Medical_health_prevent_visa__c = 'No';
        oApplication.Protection_visa_in_any_country__c = 'No';
        oApplication.Convicted_of_crime_offence__c = 'No';
        oApplication.HasDisabilities__c = 'No';
        oApplication.Submission_Location_Country__c = oCountry.Id;
        insert oApplication; 
        
        oApplication.Submission_Progress__c = 'Submit';
        oApplication.Assessment_Status__c = 'Required';
        
        Test.startTest();
        // WHEN : Update application with required status values.
        update oApplication;
        Test.stopTest();
        
        // THEN : Verify if Task(s) status is required.
        Application__c oApplicationRecord = [SELECT Id, Task_Visa__c, Task_Disability_Check__c, Task_GTE__c, Task_Fee__c FROM Application__c WHERE Callista_Application_Id__c = 'CAID-1238080' LIMIT 1];
        Assert.areEqual (oApplicationRecord.Task_Disability_Check__c, 'Not Required', 'DSS Task is not required for assessor.');
        Assert.areEqual (oApplicationRecord.Task_GTE__c, 'Required', 'DSS Task is required for assessor.');
       	Assert.areEqual (oApplicationRecord.Task_Fee__c, 'Not Required', 'Fee Task is required for assessor.');
		Assert.areEqual (oApplicationRecord.Task_Visa__c, 'Not Required', 'Visa Task is not required for assessor.');
    }
}