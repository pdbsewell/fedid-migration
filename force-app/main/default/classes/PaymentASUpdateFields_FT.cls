/**
 * @description       : Merged test class for Payment related functionality
 * @author            : jackie.ho@monash.edu
 * @group             : 
 * @last modified on  : 31-07-2025
 * @last modified by  : Jackie Ho
 * @version           : 1.0
 */
@isTest(isParallel=true)
public with sharing class PaymentASUpdateFields_FT {
    @testSetup
    static void setupTestData() {
        // GIVEN: Common setup for all test methods
        insert new Bypass_Mute_Request__c(Bypass_All_Flows__c=false);

        // GIVEN: Create and insert test applicant with address details
        Contact applicant = StudFirst_TestHelper.createApplicant();
        applicant.MailingPostalCode = '3000';
        applicant.MailingStreet = '123 Main St';
        applicant.MailingCity = 'Clayton';
        applicant.MailingState = 'Victoria';
        applicant.MailingCountry = 'Australia';
        insert applicant;
        
        // GIVEN: Create and insert application
        Application__c application = StudFirst_TestHelper.createApplication(applicant);
        application.Status__c = 'Registered - Not paid';
        insert application;

        // GIVEN: Create and insert course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        // Create and insert course offering with GST and faculty details
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        courseOffering.Course_Type__c = 'Professional Development';
        courseOffering.Faculty__c = 'Faculty of Education';
        courseOffering.Apply_GST__c = true;
        insert courseOffering;

        // GIVEN: Create and insert application course preference
        Application_Course_Preference__c ACP = StudFirst_TestHelper.createCoursePreferences(application, applicant, courseOffering, course);
        insert ACP;

        // GIVEN: Create and insert payment with initial values
        Payment__c payment = StudFirst_TestHelper.createPayment(courseOffering, applicant, application);
        payment.Payment_Amount__c = 100;
        payment.Street__c = null;
        payment.Suburb__c = null;
        payment.State__c = null;
        payment.Postcode__c = null;
        payment.Application_Course_Preference__c = ACP.Id;
        insert payment;
    }
    
    /**
     * @description Test method for updating credit card payment and verifying ACP status update
     */
    @isTest
    static void testUpdateCreditCardPayment() {
        // WHEN: Update credit card payment
        Test.startTest();
        Payment__c payment = [SELECT Id, Payment_Status__c, Payment_Type__c, Application_Course_Preference__c, Application__c 
                             FROM Payment__c 
                             ORDER BY createddate DESC 
                             LIMIT 1];
        Application_Course_Preference__c ACP = [SELECT Id, Status__c 
                                                FROM Application_Course_Preference__c 
                                                WHERE Application__c = :payment.Application__c 
                                                LIMIT 1];
        ACP.Status__c = 'Registered - Not paid';
        update ACP;
        payment.Payment_Status__c = 'Processed';
        payment.Payment_Type__c = 'Credit_Card';
        update payment;
        Test.stopTest();

        ACP = [SELECT Id, Status__c 
               FROM Application_Course_Preference__c 
               WHERE Application__c = :payment.Application__c 
               LIMIT 1];
        Application__c application = [SELECT Id, Status__c FROM Application__c WHERE Id = :payment.Application__c];
        
        // THEN: Verify results
        Assert.areEqual('Registered', application.Status__c, 'Application Status should be updated');
        Assert.areEqual('Registered', ACP.Status__c, 'Application Course Preference Status should be updated');
    }

    /**
     * @description Test method for updating invoice payment and verifying ACP status update
     */
    @isTest
    static void testUpdateInvoicePayment() {
        // WHEN: Update invoice payment
        Test.startTest();
        Payment__c payment = [SELECT Id, Payment_Status__c, Payment_Type__c, Application_Course_Preference__c, Application__c 
                             FROM Payment__c 
                             ORDER BY createddate DESC 
                             LIMIT 1];
        Application_Course_Preference__c ACP = [SELECT Id, Status__c 
                                                FROM Application_Course_Preference__c 
                                                WHERE Id = :payment.Application_Course_Preference__c];
        ACP.Status__c = 'Registered - Invoice not processed';
        update ACP;
        payment.Payment_Status__c = 'Processed';
        payment.Payment_Type__c = 'Invoice';
        update payment;
        Test.stopTest();

        ACP = [SELECT Id, Status__c 
               FROM Application_Course_Preference__c 
               WHERE Id = :payment.Application_Course_Preference__c];
        Application__c application = [SELECT Id, Status__c 
                                     FROM Application__c 
                                     WHERE Id = :payment.Application__c];
        
        // THEN: Verify results
        Assert.areEqual('Registered', application.Status__c, 'Application Status should be updated');
        Assert.areEqual('Registered - Invoiced', ACP.Status__c, 'Application Course Preference Status should be updated');
    }

    /**
     * @description Test method for verifying course faculty and type are correctly set on payment
     */
    @isTest
    static void testUpdateCourseFacultyAndType() {
        // WHEN: Update course faculty and type
        Payment__c payment = [SELECT Id, Course_Faculty__c, Course_Type__c 
                             FROM Payment__c 
                             ORDER BY createddate DESC 
                             LIMIT 1];

        // THEN: Verify results
        Assert.areEqual('Faculty of Education', payment.Course_Faculty__c, 'Course Faculty should be updated');
        Assert.areEqual('Professional Development', payment.Course_Type__c, 'Course Type should be updated');
    }

    /**
     * @description Test method for verifying GST allocation calculation
     */
    @isTest
    static void testUpdateGSTAllocation() {
        // WHEN: Update GST allocation
        Payment__c payment = [SELECT Id, GST_Allocation__c 
                             FROM Payment__c 
                             ORDER BY createddate DESC 
                             LIMIT 1];

        // THEN: Verify results
        Assert.areEqual(9, payment.GST_Allocation__c, 'GST Allocation should be updated to include 10% GST');
    }

    /**
     * @description Test method for verifying payment address is correctly populated from contact
     */
    @isTest
    static void testUpdatePaymentAddress() {
        // WHEN: Update payment address
        Payment__c payment = [SELECT Id, Street__c, Suburb__c, State__c, Postcode__c, Country__c 
                             FROM Payment__c 
                             ORDER BY createddate DESC 
                             LIMIT 1];

        // THEN: Verify results
        Assert.areEqual('3000', payment.Postcode__c, 'Postcode should be updated');
        Assert.areEqual('123 Main St', payment.Street__c, 'Street should be updated');
        Assert.areEqual('Clayton', payment.Suburb__c, 'Suburb should be updated');
        Assert.areEqual('Victoria', payment.State__c, 'State should be updated');
        Assert.areEqual('Australia', payment.Country__c, 'Country should be updated');
    }
}