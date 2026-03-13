/**
 * @description       : Test class for Payment: AS : PD Change Application Course Preference Status
 * @author            : jackie.ho@monash.edu
 * @group             : 
 * @last modified on  : 30-07-2025
 */

@isTest(isParallel=true)
public with sharing class PaymentASPDChangeApplicationACPStatus_FT {
    @testSetup
    // Setup test data
    static void setupTestData() {

        insert new Bypass_Mute_Request__c(Bypass_All_Flows__c=false);

        Contact applicant = StudFirst_TestHelper.createApplicant();
        insert applicant;
        
        Application__c application = StudFirst_TestHelper.createApplication(applicant);
        application.Status__c = 'Registered - Not paid';
        insert application;

        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        insert courseOffering;

        Payment__c payment = StudFirst_TestHelper.createPayment(courseOffering, applicant, application);
        payment.Payment_Amount__c = 100;
        insert payment;

        Application_Course_Preference__c ACP =  StudFirst_TestHelper.createCoursePreferences(application, applicant, courseOffering, course);
        ACP.Status__c = 'Registered - Not paid';
        insert ACP;
    }
    
    @isTest
    // Test Update Credit Card Payment
    static void testUpdateCreditCardPayment() {
        Test.startTest();
        Payment__c payment = [SELECT Id, Payment_Status__c, Payment_Type__c, Application_Course_Preference__c, Application__c FROM Payment__c ORDER BY createddate DESC LIMIT 1];
        payment.Payment_Status__c = 'Processed';
        payment.Payment_Type__c = 'Credit Card';
        update payment;
        Test.stopTest();

        Application_Course_Preference__c ACP = [SELECT Id, Status__c FROM Application_Course_Preference__c ORDER BY createddate DESC LIMIT 1];
        Application__c application = [SELECT Id, Status__c FROM Application__c ORDER BY createddate DESC LIMIT 1];

        Assert.areEqual('Registered', ACP.Status__c, 'Application Course Preference Status should be updated');
        Assert.areEqual('Registered', application.Status__c, 'Application Status should be updated');
    }

    @isTest
    // Test Update Invoice Payment
    static void testUpdateInvoicePayment() {
        Test.startTest();
        Payment__c payment = [SELECT Id, Payment_Status__c, Payment_Type__c FROM Payment__c ORDER BY createddate DESC LIMIT 1];
        payment.Payment_Status__c = 'Processed';
        payment.Payment_Type__c = 'Invoice';
        update payment;
        Test.stopTest();

        Application_Course_Preference__c ACP = [SELECT Id, Status__c FROM Application_Course_Preference__c ORDER BY createddate DESC LIMIT 1];
        Application__c application = [SELECT Id, Status__c FROM Application__c ORDER BY createddate DESC LIMIT 1];
        
        Assert.areEqual('Registered', ACP.Status__c, 'Application Course Preference Status should be updated');
        Assert.areEqual('Registered', application.Status__c, 'Application Status should be updated');
    }
}