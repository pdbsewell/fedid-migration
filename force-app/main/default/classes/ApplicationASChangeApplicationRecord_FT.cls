/**
 * @description       : Test class for Application : AS : Change Application Record flow
 * @author            : rajesh.punjabi@monash.edu
 * @last modified on  : 24-02-2025
 * @last modified by  : rajesh.punjabi@monash.edu
**/
@isTest(isParallel=true)
public with sharing class ApplicationASChangeApplicationRecord_FT {

    /**
     * Sets up test data:
     * - Creates a test Contact (Applicant)
     * - Creates a test Account (Agent)
     * - Inserts an Application__c record
    */
    @testSetup 
    static void setup() {
        Contact testApplicant = new Contact(LastName = 'TestApplicantFlowTest', MailingCountry = 'Malaysia');
        insert testApplicant;  

        Account oAccount = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organization').getRecordTypeId(),
            Name = 'ApplicationASChangeApplicationRecord_FT-1');
        insert oAccount;

        Application__c oApplication = new Application__c(
            Callista_Application_Id__c = 'FPB' + randomNumber(),
            Fee_Payment__c = false,
            Fee_Waiver_Redeemed__c = 'Test',
            Refused_entry_visa_to_any_country__c = 'Yes',
            Breached_visa_condition__c = 'Yes',
            Medical_health_prevent_visa__c = 'Yes',
            Protection_visa_in_any_country__c = 'Yes',
            Convicted_of_crime_offence__c = 'Yes',
            HasDisabilities__c = 'Yes',
            Submission_Progress__c = 'Submit',
            Assessment_Status__c = 'Required',
            Status__c = 'Submission on Hold (Duplicate Contact)',
            Type_of_Study__c = 'Coursework',
            Agent__c = oAccount.Id,
            Agent_Org_Unit_Code__c = 'AgentCode_123',
            Welcome_Email_Sent__c = false,
            Applicant__c = testApplicant.Id);
        insert oApplication;
    }

    /**
     * Test Welcome Email flag is set on record insert
    */
    @isTest
    public static void testSetWelcomeEmailFlagInsertSuccess() {
        
        // GIVEN: A new Application with eligible status and study type
        Application__c oApplication = new Application__c(
            Status__c = 'Sent for Submission',
            Type_of_Study__c = 'Coursework',
            Welcome_Email_Sent__c = false,
            Applicant__c = [SELECT Id FROM Contact WHERE LastName = 'TestApplicantFlowTest' LIMIT 1].Id);

        // WHEN: The record is inserted
        Test.startTest();
            insert oApplication;
        Test.stopTest();

        // THEN: The Welcome_Email_Sent__c flag should be set to true
        Application__c result = [SELECT Welcome_Email_Sent__c FROM Application__c WHERE Id = :oApplication.Id];
        Assert.areEqual(true, result.Welcome_Email_Sent__c, 'Welcome Email Sent should be set to true');
    }

    /**
     * Test Welcome Email flag is not set on insert
    */
    @isTest
    public static void testSetWelcomeEmailFlagInsertFailure1() {
        // GIVEN: A new Application with ineligible status
        Application__c oApplication = new Application__c(
            Status__c = 'Review',
            Type_of_Study__c = 'Coursework',
            Welcome_Email_Sent__c = false,
            Applicant__c = [SELECT Id FROM Contact WHERE LastName = 'TestApplicantFlowTest' LIMIT 1].Id);

        // WHEN: The record is inserted
        Test.startTest();
            insert oApplication;
        Test.stopTest();

        // THEN: The Welcome_Email_Sent__c flag should remain false
        Application__c result = [SELECT Welcome_Email_Sent__c FROM Application__c WHERE Id = :oApplication.Id];
        Assert.areNotEqual(true, result.Welcome_Email_Sent__c, 'Welcome Email Sent should not be set to true');
    }

    /**
     * Test Welcome Email flag is not set on insert
    */
    @isTest
    public static void testSetWelcomeEmailFlagInsertFailure2() {
        // GIVEN: A new Application with ineligible study type
        Application__c oApplication = new Application__c(
            Status__c = 'Sent for Submission',
            Type_of_Study__c = 'Graduate Research',
            Welcome_Email_Sent__c = false,
            Applicant__c = [SELECT Id FROM Contact WHERE LastName = 'TestApplicantFlowTest' LIMIT 1].Id);

        // WHEN: The record is inserted
        Test.startTest();
            insert oApplication;
        Test.stopTest();

        // THEN: The Welcome_Email_Sent__c flag should remain false
        Application__c result = [SELECT Welcome_Email_Sent__c FROM Application__c WHERE Id = :oApplication.Id];
        Assert.areNotEqual(true, result.Welcome_Email_Sent__c, 'Welcome Email Sent should not be set to true');
    }

    /**
     * Test Welcome Email flag is set on update
    */
    @isTest
    public static void testSetWelcomeEmailFlagUpdateSuccess() {
        
        // GIVEN: An existing Application with Welcome_Email_Sent__c = false
        Application__c oApplication = [SELECT Id, Status__c, Welcome_Email_Sent__c FROM Application__c LIMIT 1];
        oApplication.Status__c = 'Sent for Submission';

        // WHEN: The status is updated to 'Sent for Submission'
        Test.startTest();
            update oApplication;
        Test.stopTest();

        // THEN: The Welcome_Email_Sent__c flag should be set to true
        Application__c result = [SELECT Welcome_Email_Sent__c FROM Application__c WHERE Id = :oApplication.Id];
        Assert.areEqual(true, result.Welcome_Email_Sent__c, 'Welcome Email Sent should be set to true');
    }

    /**
     * Test Welcome Email flag is not set in update
    */
    @isTest
    public static void testSetWelcomeEmailFlagUpdateFailure1() {
        
        // GIVEN: An existing Application
        Application__c oApplication = [SELECT Id, Status__c, Welcome_Email_Sent__c FROM Application__c LIMIT 1];
        oApplication.Status__c = 'Review';

        
        // WHEN: The status is updated to an ineligible value
        Test.startTest();
            update oApplication;
        Test.stopTest();

        // THEN: The Welcome_Email_Sent__c flag should remain unchanged (false)
        Application__c result = [SELECT Welcome_Email_Sent__c FROM Application__c WHERE Id = :oApplication.Id];
        Assert.areNotEqual(true, result.Welcome_Email_Sent__c, 'Welcome Email Sent should not be set to true');
    }

    /**
     * Test Agent lookup is set to Null when Agent Org Unit Code is cleared
    */
    @isTest
    public static void testUpdateAgentLookupToNull() {
        
        // GIVEN: An Application with Agent and Agent Org Unit Code populated
        Application__c oApplication = [SELECT Id, Agent__c, Agent_Org_Unit_Code__c FROM Application__c LIMIT 1];
        oApplication.Agent_Org_Unit_Code__c = '';

        // WHEN: The Agent Org Unit Code is cleared
        Test.startTest();
            TriggerCommon.disableTrigger('Application__c');
            update oApplication;
            TriggerCommon.enableTrigger('Application__c');
        Test.stopTest();

        // THEN: The Agent__c field should be set to null
        Application__c result = [SELECT Agent__c FROM Application__c WHERE Id = :oApplication.Id];
        Assert.isNull(result.Agent__c, 'Agent field should be blank');
    }

    /**
     * Test application is deleted when status updated to cancel
    */
    @isTest
    public static void testRequestApplicationCancel() {
        
        // GIVEN: An Application in Draft status
        Application__c oApplication = [SELECT Id, Status__c FROM Application__c LIMIT 1];
        oApplication.Status__c = 'Draft';
        update oApplication;

        
        // WHEN: The status is changed to 'Cancelled'
        oApplication.Status__c = 'Cancelled';

        Test.startTest();
            update oApplication;
        Test.stopTest();

        // THEN: The record should be deleted
        List<Application__c> apps = [SELECT Id FROM Application__c];
        Assert.areEqual(0, apps.size(), 'Application should have been deleted');
    }

    /**
     * @description Helper method to generate a random number for unique test data
     * @return Integer between 0 and 9999
    */
    public static Integer randomNumber() {
        return Integer.valueOf(Math.random() * 9999);
    }
}