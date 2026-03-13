/**
 * @description Test class for ApplicationWorkExpProvidedHandler
 * @author      Sravani Naramsetti
 * @date        JUL.30.2025
 */
@isTest(isParallel=true)
private class ApplicationWorkExpProvidedHandler_Test {
	@TestSetup
    static void makeData() {

        TriggerCommon.disableTrigger('Contact');
        TriggerCommon.disableTrigger('Application__c');

        Contact applicant = AssessmentsTestDataFactory.createApplicant();
        insert applicant;

        Application__c application = AssessmentsTestDataFactory.createInternationalApplication('CAID-1239090', applicant.Id);
        application.Assessment_Status__c = 'Required';
        insert application;
        
        Application__c applicationSingleACP = AssessmentsTestDataFactory.createInternationalApplication('CAID-1239098', applicant.Id);
        applicationSingleACP.Assessment_Status__c = 'Required';
        applicationSingleACP.Status__c = 'Submitted';
        insert applicationSingleACP;

        TriggerCommon.enableTrigger('Contact');
        TriggerCommon.enableTrigger('Application__c');
    }
    
    /**
    * @description Insert Application Work Experience provided, should update Application Status on Work Experience
    * @author sravani.naramsetti@monash.edu | 30-07-2025
    * GIVEN An Application, Work Experience
    * WHEN the Application  Work Experience Provided record is inserted
    * THEN Application Status on Work Experience is updated
    **/
    @isTest
    static void updateApplicationStatusOnWorkExp_Test() {

        // GIVEN: Application has AWEP record
        Application__c application = [SELECT Id,Citizenship_Classification__c FROM Application__c WHERE Callista_Application_Id__c = 'CAID-1239090' LIMIT 1][0];
		Contact applicant = [Select id from Contact LIMIT 1];
        //create work experience
        Work_Experience__c workExpRecord = new Work_Experience__c();
        workExpRecord = StudFirst_TestHelper.populateWorkExperienceRecord(workExpRecord);
        workExpRecord.Contact__c = applicant.Id;
        insert workExpRecord;
        
        Test.startTest();
        //WHEN: application work experience is inserted
        Application_Work_Experience_Provided__c aweRecord = new Application_Work_Experience_Provided__c();
        aweRecord.Application__c = application.Id;
        aweRecord.Work_Experience__c = workExpRecord.Id;
        insert aweRecord; 
        Test.stopTest();

        //THEN: Application Status on Contact Qualification is updated
        Work_Experience__c we = [SELECT Id, Application_Status__c FROM Work_Experience__c LIMIT 1];
        Assert.areEqual(we.Application_Status__c, 'Draft');
    }
    
    /**
    * @description Insert Application Work Experience provided, should update Application Status on Work Experience
    * @author sravani.naramsetti@monash.edu | 30-07-2025
    * GIVEN An Application, Work Experience
    * WHEN the Application  Work Experience Provided record is inserted
    * THEN Application Status on Work Experience is updated
    **/
    @isTest
    static void updateApplicationStatusOnWorkExp1_Test() {

        // GIVEN: Application has AWEP record
        Application__c application = [SELECT Id,Citizenship_Classification__c FROM Application__c WHERE Callista_Application_Id__c = 'CAID-1239090' LIMIT 1][0];
		Application__c application1 = [SELECT Id,Citizenship_Classification__c FROM Application__c WHERE Callista_Application_Id__c = 'CAID-1239098' LIMIT 1][0];
		
        Contact applicant = [Select id from Contact LIMIT 1];
        //create work experience
        Work_Experience__c workExpRecord = new Work_Experience__c();
        workExpRecord = StudFirst_TestHelper.populateWorkExperienceRecord(workExpRecord);
        workExpRecord.Contact__c = applicant.Id;
        insert workExpRecord;
        
        
        Test.startTest();
        //WHEN: application work experience is inserted
        Application_Work_Experience_Provided__c aweRecord = new Application_Work_Experience_Provided__c();
        aweRecord.Application__c = application.Id;
        aweRecord.Work_Experience__c = workExpRecord.Id;
        insert aweRecord; 
        Application_Work_Experience_Provided__c aweRecord1 = new Application_Work_Experience_Provided__c();
        aweRecord1.Application__c = application1.Id;
        aweRecord1.Work_Experience__c = workExpRecord.Id;
        insert aweRecord1; 
        Test.stopTest();

        //THEN: Application Status on Contact Qualification is updated
        Work_Experience__c we = [SELECT Id, Application_Status__c FROM Work_Experience__c LIMIT 1];
        Assert.areEqual(we.Application_Status__c, 'Submitted');
    }
    
        /**
    * @description Insert Application Work Experience provided, should update Application Status on Work Experience
    * @author sravani.naramsetti@monash.edu | 30-07-2025
    * GIVEN An Application, Work Experience
    * WHEN the Application  Work Experience Provided record is inserted
    * THEN Application Status on Work Experience is updated
    **/
    @isTest
    static void updateApplicationStatusOnWorkExp2_Test() {

        // GIVEN: Application has AWEP record
        Application__c application = [SELECT Id,Citizenship_Classification__c FROM Application__c WHERE Callista_Application_Id__c = 'CAID-1239090' LIMIT 1][0];
		Application__c application1 = [SELECT Id,Citizenship_Classification__c FROM Application__c WHERE Callista_Application_Id__c = 'CAID-1239098' LIMIT 1][0];
		
        Contact applicant = [Select id from Contact LIMIT 1];
        //create work experience
        Work_Experience__c workExpRecord = new Work_Experience__c();
        workExpRecord = StudFirst_TestHelper.populateWorkExperienceRecord(workExpRecord);
        workExpRecord.Contact__c = applicant.Id;
        insert workExpRecord;
        
        
        Test.startTest();
        //WHEN: application work experience is inserted
        Application_Work_Experience_Provided__c aweRecord = new Application_Work_Experience_Provided__c();
        aweRecord.Application__c = application1.Id;
        aweRecord.Work_Experience__c = workExpRecord.Id;
        insert aweRecord; 
        Application_Work_Experience_Provided__c aweRecord1 = new Application_Work_Experience_Provided__c();
        aweRecord1.Application__c = application.Id;
        aweRecord1.Work_Experience__c = workExpRecord.Id;
        insert aweRecord1; 
        Test.stopTest();

        //THEN: Application Status on Contact Qualification is updated
        Work_Experience__c we = [SELECT Id, Application_Status__c FROM Work_Experience__c LIMIT 1];
        Assert.areEqual(we.Application_Status__c, 'Submitted');
    }
}