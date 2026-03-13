/**
 * @description       : Test class for Payment Request: AS : Calculate GST Flow.
 * @author            : jackie.ho@monash.edu
 * @group             : 
 * @last modified on  : 28-05-2025
 * @last modified by  : jackie.ho@monash.edu
**/
@isTest(isParallel=true)
private with sharing class PaymentRequestASCalculateGST_FT {

    @isTest
    static void NewRecord_Test() {

        // Given: Create Account & Payment Request
        Account acc = (Account)MonConTestDataFactory.createSObject(new Account(), true);
        Payment_Request__c pr = new Payment_Request__c(
            Account__c = acc.Id,
            Status__c = 'Draft',
            RecordTypeId = '0124a0000004M1BAAU', 
            Requested_Amount_Ex_GST__c = 1000,
            GST_Inclusive__c = true
        );

        // When: Insert Payment Request
        Test.startTest();
        insert pr;
        Test.stopTest();

        // Then: Validate Request Amount & Request Amount GST
        pr = [SELECT Id, Requested_Amount__c, Requested_Amount_GST__c 
            FROM Payment_Request__c 
            WHERE Id = :pr.Id
        ];
        
        Assert.areNotEqual(pr.Requested_Amount__c, 0, 'Requested Amount field is not updated');
        Assert.areNotEqual(pr.Requested_Amount_GST__c, 0, 'Requested Amount GST field is not updated');
    }

    @isTest
    static void RequestAmountGSTOveride_Test() {

        // Given: Create Account & Payment Request
        Account acc = (Account)MonConTestDataFactory.createSObject(new Account(), true);
        Payment_Request__c pr = new Payment_Request__c(
            Account__c = acc.Id,
            Requested_Amount__c = 1000,
            Requested_Amount_GST__c = 100,
            Requested_Amount_Ex_GST__c = 900,
            Status__c = 'Draft',
            RecordTypeId = '0124a0000004M1BAAU', 
            GST_Inclusive__c = true
        );
        
        // When: Insert & Update Request Amount GST
        insert pr;
        Test.startTest();
        pr.Requested_Amount_GST__c = 200;
        update pr;
        Test.stopTest();

        // Then: Validate Request Amount & Request Amount GST
        pr = [SELECT Id, Requested_Amount__c, Requested_Amount_GST__c 
            FROM Payment_Request__c 
            WHERE Id = :pr.Id
        ];
        Assert.areNotEqual(pr.Requested_Amount__c, 1000, 'Requested Amount field is not updated');
    }

    @isTest 
    static void RequestAmountExGSTOveride_Test() {

        // Given: Create Account & Payment Request
        Account acc = (Account)MonConTestDataFactory.createSObject(new Account(), true);
        Payment_Request__c pr = new Payment_Request__c(
            Account__c = acc.Id,
            Status__c = 'Draft',
            RecordTypeId = '0124a0000004M1BAAU', 
            Requested_Amount_Ex_GST__c = 900,
            Requested_Amount__c = 1000,
            Requested_Amount_GST__c = 100,
            GST_Inclusive__c = true
        );

        // When: Insert & Update Request Amount Ex GST
        insert pr;
        Test.startTest();
        pr.Requested_Amount_Ex_GST__c = 2000;
        update pr;
        Test.stopTest();

        // Then: Validate Request Amount & Request Amount GST
        pr = [SELECT Id, Requested_Amount__c, Requested_Amount_GST__c 
            FROM Payment_Request__c 
            WHERE Id = :pr.Id
        ];
        Assert.areNotEqual(pr.Requested_Amount__c, 1000, 'Requested Amount field is not updated');
        Assert.areNotEqual(pr.Requested_Amount_GST__c, 100, 'Requested Amount GST field is not updated');
    }
}