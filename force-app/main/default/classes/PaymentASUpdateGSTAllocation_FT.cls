/**
 * @description       : Test class for Payment: AS : Update GST Allocation
 * @author            : jackie.ho@monash.edu
 * @group             : 
 * @last modified on  : 30-07-2025
 */

@isTest(isParallel=true)
public with sharing class PaymentASUpdateGSTAllocation_FT {
    @testSetup
    // Setup test data
    static void setupTestData() {

        insert new Bypass_Mute_Request__c(Bypass_All_Flows__c=false);

        Contact applicant = StudFirst_TestHelper.createApplicant();
        insert applicant;
        
        Application__c application = StudFirst_TestHelper.createApplication(applicant);
        insert application;

        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        courseOffering.Course_Type__c = 'Professional Development';
        courseOffering.Faculty__c = 'Faculty of Education';
        courseOffering.Apply_GST__c = true;
        insert courseOffering;

        Payment__c payment = StudFirst_TestHelper.createPayment(courseOffering, applicant, application);
        payment.Payment_Amount__c = 100;
        insert payment;
    }
    
    @isTest
    // Test Update GST Allocation
    static void testUpdateGSTAllocation() {
        Payment__c payment = [SELECT Id, GST_Allocation__c FROM Payment__c ORDER BY createddate DESC LIMIT 1];

        Assert.areEqual(payment.GST_Allocation__c, 110, 'GST Allocation should be updated');
    }
}