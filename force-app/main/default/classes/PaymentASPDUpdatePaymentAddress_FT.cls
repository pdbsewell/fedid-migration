/**
 * @description       : Test class for Payment: AS : PD Update Payment Address
 * @author            : jackie.ho@monash.edu
 * @group             : 
 * @last modified on  : 30-07-2025
 */

@isTest(isParallel=true)
public with sharing class PaymentASPDUpdatePaymentAddress_FT {
    @testSetup
    // Setup test data
    static void setupTestData() {

        insert new Bypass_Mute_Request__c(Bypass_All_Flows__c=false);

        Contact applicant = StudFirst_TestHelper.createApplicant();
        applicant.MailingPostalCode = '3000';
        applicant.MailingStreet = '123 Main St';
        applicant.MailingCity = 'Clayton';
        applicant.MailingState = 'Victoria';
        applicant.MailingCountry = 'Australia';
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
        payment.Street__c = null;
        payment.Suburb__c = null;
        payment.State__c = null;
        payment.Postcode__c = null;
        insert payment;
    }
    
    @isTest
    // Test Update Payment Address
    static void testUpdatePaymentAddress() {
        Payment__c payment = [SELECT Id, Street__c, Suburb__c, State__c, Postcode__c, Country__c FROM Payment__c ORDER BY createddate DESC LIMIT 1];

        Assert.areEqual(payment.Postcode__c, '3000', 'Postcode should be updated');
        Assert.areEqual(payment.Street__c, '123 Main St', 'Street should be updated');
        Assert.areEqual(payment.Suburb__c, 'Clayton', 'Suburb should be updated');
        Assert.areEqual(payment.State__c, 'Victoria', 'State should be updated');
        Assert.areEqual(payment.Country__c, 'Australia', 'Country should be updated');
    }
}