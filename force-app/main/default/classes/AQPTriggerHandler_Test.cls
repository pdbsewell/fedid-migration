/**
 * @description Test class for ApplicationQualificationProvidedHandler
 * @author      Sravani Naramsetti
 * @date        JUL.18.2025
 */
@isTest(isParallel=true)
private class AQPTriggerHandler_Test {
	@TestSetup
    static void makeData() {

        TriggerCommon.disableTrigger('Contact');
        TriggerCommon.disableTrigger('Application__c');

        Contact applicant = AssessmentsTestDataFactory.createApplicant();
        insert applicant;

        Application__c application = AssessmentsTestDataFactory.createInternationalApplication('CAID-1239090', applicant.Id);
        application.Status__c='Submitted';
        application.Assessment_Status__c = 'Required';
        insert application;

        TriggerCommon.enableTrigger('Contact');
        TriggerCommon.enableTrigger('Application__c');
    }
    
    /**
    * @description Insert Application Qualification provided, should update Application Status on Contact Qualification
    * @author sravani.naramsetti@monash.edu | 18-07-2025
    * GIVEN An Application, Contact Qualification
    * WHEN the Application  Qualification Provided record is inserted
    * THEN Application Status on Contact Qualification is updated
    **/
    @isTest
    static void updateApplicationStatusOnContQual_Test() {

        // GIVEN: Application has AQP record
        Application__c application = [SELECT Id,Citizenship_Classification__c FROM Application__c WHERE Callista_Application_Id__c = 'CAID-1239090' LIMIT 1][0];
		Contact applicant = [Select id from Contact LIMIT 1];
        //create qualification
        Qualification__c qual = StudFirst_TestHelper.createQualification('custom qual');
        insert qual;
        //create contact qualification
        Contact_Qualification__c cqual = StudFirst_TestHelper.createContactQualification(applicant, qual, 'Secondary Education');
        insert cqual;
        
        Test.startTest();
        //WHEN: application qualification provided is inserted
        Application_Qualification_Provided__c aqp = StudFirst_TestHelper.createAppQualProvided(application.Id, cqual.Id);
        insert aqp;
        Test.stopTest();

        //THEN: Application Status on Contact Qualification is updated
        Contact_Qualification__c cq = [SELECT Id, Application_Status__c FROM Contact_Qualification__c LIMIT 1];
        Assert.areEqual(cq.Application_Status__c, 'Submitted');
    }
}