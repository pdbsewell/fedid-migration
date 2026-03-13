/**
 * @description     Test class specific to AgencyPaymentRequestServices class
 * 
 * @author          K. Vegerano
 * @date            02/09/2020
 * 
 * @revision
 * 
 *      02/09/2020 - K Vegerano - created
 */
@isTest(isParallel=true)
public with sharing class AgencyPaymentRequestServices_Test {
    /**
     * Set up Data
     */
    @testSetup static void setupData(){
    }

    static testMethod void test_AgencyUniqueInvoiceNumber_Insert_Success() {
        //Create agency record
        Account testAgency = new Account(Name = 'TestAgency');
        insert testAgency;

        //start tests
        Test.startTest();
        insert new Payment_Request__c(Account__c = testAgency.Id, Invoice_No__c = '12345678');
        Test.stopTest();

        //assert results
        System.assertEquals(1, [SELECT Id FROM Payment_Request__c].size());
    }

    static testMethod void test_AgencyUniqueInvoiceNumber_Insert_Validated() {
        //Create agency record
        Account testAgency = new Account(Name = 'TestAgency');
        insert testAgency;
        //Create initial payment request
        insert new Payment_Request__c(Account__c = testAgency.Id, Invoice_No__c = '12345678');

        //start tests
        Test.startTest();
        try{
            insert new Payment_Request__c(Account__c = testAgency.Id, Invoice_No__c = '12345678');
        }catch(Exception ex){
            System.assertEquals('Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, Invoice Number for the agency already exist.: []', ex.getMessage());            
        }
        Test.stopTest();

        //assert results
        System.assertEquals(1, [SELECT Id FROM Payment_Request__c].size());
    }

    static testMethod void test_AgencyUniqueInvoiceNumber_Update_Success() {
        //Create agency record
        Account testAgency = new Account(Name = 'TestAgency');
        insert testAgency;
        //Create initial payment request
        Payment_Request__c testPaymentRequest = new Payment_Request__c(Account__c = testAgency.Id, Invoice_No__c = '12345678');
        insert testPaymentRequest;
        //Create initial payment request
        Payment_Request__c testUpdatePaymentRequest = new Payment_Request__c(Account__c = testAgency.Id, Invoice_No__c = '23456789');
        insert testUpdatePaymentRequest;

        //start tests
        Test.startTest();
        testUpdatePaymentRequest.Invoice_No__c = '13456789';
        update testUpdatePaymentRequest;
        Test.stopTest();

        //assert results
        System.assertEquals(2, [SELECT Id FROM Payment_Request__c].size());
    }

    static testMethod void test_AgencyUniqueInvoiceNumber_Update_Validated() {
        //Create agency record
        Account testAgency = new Account(Name = 'TestAgency');
        insert testAgency;
        //Create initial payment request
        Payment_Request__c testPaymentRequest = new Payment_Request__c(Account__c = testAgency.Id, Invoice_No__c = '12345678');
        insert testPaymentRequest;
        //Create initial payment request
        Payment_Request__c testUpdatePaymentRequest = new Payment_Request__c(Account__c = testAgency.Id, Invoice_No__c = '23456789');
        insert testUpdatePaymentRequest;

        //start tests
        Test.startTest();
        try{
            testUpdatePaymentRequest.Invoice_No__c = '12345678';
            update testUpdatePaymentRequest;
        }catch(Exception ex){
            System.assertEquals('Update failed. First exception on row 0 with id ' + testUpdatePaymentRequest.Id + '; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, Invoice Number for the agency already exist.: []', ex.getMessage());            
        }        
        Test.stopTest();

        //assert results
        System.assertEquals(2, [SELECT Id FROM Payment_Request__c].size());
    }

    static testMethod void test_SetSubmissionDate() {
        //Create agency record
        Account testAgency = new Account(Name = 'TestAgency');
        insert testAgency;
        //Create initial payment request
        Payment_Request__c testPaymentRequest = new Payment_Request__c(Account__c = testAgency.Id, Invoice_No__c = '12345678', Status__c = 'Draft');
        insert testPaymentRequest;

        //start tests
        Test.startTest();
        testPaymentRequest.Status__c = 'Submitted to SAP';
        update testPaymentRequest;
        Test.stopTest();

        //assert results
        System.assertNotEquals(null, [SELECT Id, Submission_Date__c FROM Payment_Request__c LIMIT 1][0].Submission_Date__c);
    }
}