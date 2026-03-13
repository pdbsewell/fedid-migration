/**
 * @description       : Test class for Payment: AS : PD Update Payment
 * @author            : jackie.ho@monash.edu
 * @group             : 
 * @last modified on  : 30-07-2025
 */

@isTest(isParallel=true)
public with sharing class PaymentASPDUpdatePayment_FT {
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
        insert courseOffering;

        Payment__c payment = StudFirst_TestHelper.createPayment(courseOffering, applicant, application);
        insert payment;
    }
    
    @isTest
    // Test Update Course Faculty & Type
    static void testUpdateCourseFacultyAndType() {
        Payment__c payment = [SELECT Id, Course_Faculty__c, Course_Type__c FROM Payment__c ORDER BY createddate DESC LIMIT 1];

        Assert.areEqual(payment.Course_Faculty__c, 'Faculty of Education', 'Course Faculty should be updated');
        Assert.areEqual(payment.Course_Type__c, 'Professional Development', 'Course Type should be updated');
    }
}