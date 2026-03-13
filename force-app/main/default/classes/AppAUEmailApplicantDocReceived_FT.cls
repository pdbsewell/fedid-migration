/**
 * @description Covers the AppAUEmailApplicantDocReceived flow
 * @author      Kai-Fan Hsieh
 * @since       02/10/2024
 */
@IsTest(isParallel=true)
private class AppAUEmailApplicantDocReceived_FT {
    /**
     * @description Sets up test data including a Contact, Application, and Document Checklist for testing.
     */
    @TestSetup
    private static void setupData() {
        // Create a new Contact for testing
        Contact testContact = StudFirst_TestHelper.createApplicant();
        testContact.Citizenship__c = MyApplicationUtilities.DOMESTIC;
        testContact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Non_Student').getRecordTypeId();
        Date dtToday = Date.today();
        testContact.Birthdate = dtToday.addYears(-20);
        insert testContact;

        // Create application for contact
        Application__c testApplication = StudFirst_TestHelper.createApplication(testContact.Id);
        testApplication.Fee_Payment__c = true;
        insert testApplication;
    }

    /**
     * @description Tests the flow when Application__c.Last_Verified_Document_Received_Date__c is changed and populated
     */
    @IsTest
    private static void testLastVerifiedDocumentReceivedDateChanged() {
        // Given: Get application
        List<Application__c> applications = [SELECT Id FROM Application__c];
        for (Application__c application : applications) {
            application.Last_Verified_Document_Received_Date__c = System.now();
        }
        // When: Set Last_Verified_Document_Received_Date__c to current datetime
        Test.startTest();
        update applications;
        Test.stopTest();

        // Then: Email notification should be sent to applicant
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        List<Task> emailTasks = [SELECT Id FROM Task WHERE WhoId =: testContact.Id AND TaskSubtype = 'Email'];
        Assert.areEqual(1, emailTasks.size(), 'Expected email notification to be sent to applicant');

    }

    /**
     * @description Tests the flow when Application__c.Last_Verified_Document_Received_Date__c is changed to null
     */
    @IsTest
    private static void testLastVerifiedDocumentReceivedDateChangedToNull() {
        // Given: Set init state - Last_Verified_Document_Received_Date__c to not null
        List<Application__c> applications = [SELECT Id FROM Application__c];
        for (Application__c application : applications) {
            application.Last_Verified_Document_Received_Date__c = System.now();
        }
        Bypass_Mute_Request__c customSetting = Bypass_Mute_Request__c.getInstance();
        customSetting.Bypass_All_Flows__c = true;
        upsert customSetting;
        update applications;
        customSetting.Bypass_All_Flows__c = false;
        upsert customSetting;

        // When: Set Last_Verified_Document_Received_Date__c to null
        Test.startTest();
        for (Application__c application : applications) {
            application.Last_Verified_Document_Received_Date__c = null;
        }
        update applications;
        Test.stopTest();

        // Then: Email notification should be sent to applicant
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        List<Task> emailTasks = [SELECT Id FROM Task WHERE WhoId =: testContact.Id AND TaskSubtype = 'Email'];
        Assert.areEqual(0, emailTasks.size(), 'Expected no email notification to be sent to applicant');
    }

    /**
     * @description Tests the flow when Application__c.Last_Verified_Document_Received_Date__c is not changed but populated
     */
    @IsTest
    private static void testLastVerifiedDocumentReceivedDateNotChanged() {
        // Given: Set init state - Last_Verified_Document_Received_Date__c to not null
        List<Application__c> applications = [SELECT Id FROM Application__c];
        for (Application__c application : applications) {
            application.Last_Verified_Document_Received_Date__c = System.now();
        }
        Bypass_Mute_Request__c customSetting = Bypass_Mute_Request__c.getInstance();
        customSetting.Bypass_All_Flows__c = true;
        upsert customSetting;
        update applications;
        customSetting.Bypass_All_Flows__c = false;
        upsert customSetting;

        // When: Update applications but keep Last_Verified_Document_Received_Date__c unchanged
        Test.startTest();
        for (Application__c application : applications) {
            application.Submission_Progress__c = 'Documents';
        }
        update applications;
        Test.stopTest();

        // Then: Email notification should be sent to applicant
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        List<Task> emailTasks = [SELECT Id FROM Task WHERE WhoId =: testContact.Id AND TaskSubtype = 'Email'];
        Assert.areEqual(0, emailTasks.size(), 'Expected no email notification to be sent to applicant');
    }
}