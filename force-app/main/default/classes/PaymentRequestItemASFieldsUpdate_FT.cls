/**
 * @description       : Test class for Payment Request Item: AS : Fields Update Flow.
 * @author            : jackie.ho@monash.edu
 * @group             : 
 * @last modified on  : 10-06-2025
 * @last modified by  : jackie.ho@monash.edu
**/
@isTest(isParallel=true)
public with sharing class PaymentRequestItemASFieldsUpdate_FT {
    private static Account testAccount;
    private static Contact testContact;
    private static Payment_Request__c testPaymentRequest;
    
    @testSetup
    static void setupTestData() {
        // Disable triggers that might interfere with test data setup
        TriggerCommon.disableTrigger('Contact');
        TriggerCommon.disableTrigger('Account');

        // Create test Account
        testAccount = (Account)MonConTestDataFactory.createSObject(new Account(), true);
        
        // Create test Contact
        testContact = (Contact)MonConTestDataFactory.createSObject(
            new Contact(FirstName = 'Test', LastName = 'Contact'), true
        );
        
        // Create test Payment Request
        RecordType prRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Commission' LIMIT 1];
        testPaymentRequest = (Payment_Request__c)MonConTestDataFactory.createSObject(new Payment_Request__c(
            Account__c = testAccount.Id,
            Status__c = 'Draft',
            RecordTypeId = prRT.Id, 
            GST_Inclusive__c = true
        ), true);

        // Re-enable triggers for test execution
        TriggerCommon.enableTrigger('Contact');
        TriggerCommon.enableTrigger('Account');
    }
    
    private static Payment_Request_Item__c createTestPaymentRequestItem(Decimal requestedAmountExGST, Decimal requestedAmountGST, 
                                                                      Decimal payableAmountExGST, Decimal payableAmountGST) {
        return (Payment_Request_Item__c)MonConTestDataFactory.createSObject(new Payment_Request_Item__c(
            Student__c = testContact.Id,
            Payment_Request__c = testPaymentRequest.Id,
            Requested_Amount_Ex_GST__c = requestedAmountExGST,
            Requested_AmountGST__c = requestedAmountGST,
            Payable_Amount_Ex_GST__c = payableAmountExGST,
            Payable_AmountGST__c = payableAmountGST
        ), true);
    }
    
    private static void refreshTestData() {
        testAccount = [SELECT Id FROM Account order by createddate desc LIMIT 1 ];
        testContact = [SELECT Id FROM Contact order by createddate desc LIMIT 1 ];
        testPaymentRequest = [SELECT Id FROM Payment_Request__c order by createddate desc LIMIT 1 ];
    }

    @isTest
    static void testRequestedAmountExGSTModified() {
        // Setup test data
        refreshTestData();
        Payment_Request_Item__c pti = createTestPaymentRequestItem(100, null, null, null);
        
        // When: Update payment request item
        Test.startTest();
        pti.Requested_Amount_Ex_GST__c = 200;
        update pti;
        Test.stopTest();

        // Then: Validate fields
        pti = [SELECT Id, 
            Payable_AmountGST__c, 
            Payable_Amount_Ex_GST__c, 
            Payable_Amount__c,
            Requested_AmountGST__c, 
            Requested_Amount__c 
            FROM Payment_Request_Item__c 
            WHERE Id = :pti.Id
        ];
        Assert.areEqual(20, pti.Payable_AmountGST__c, 'Payable Amount GST not updated');
        Assert.areEqual(200, pti.Payable_Amount_Ex_GST__c, 'Payable Amount Ex GST not updated');
        Assert.areEqual(220, pti.Payable_Amount__c, 'Payable Amount not updated');
        Assert.areEqual(20, pti.Requested_AmountGST__c, 'Requested Amount GST not updated');
        Assert.areEqual(220, pti.Requested_Amount__c, 'Requested Amount not updated');
    }

    @isTest
    static void testRequestedAmountGSTModified() {
        // Setup test data
        refreshTestData();
        Payment_Request_Item__c pti = createTestPaymentRequestItem(200, 10, null, null);
        
        // When: Update payment request item
        Test.startTest();
        pti.Requested_AmountGST__c = 20;
        update pti;
        Test.stopTest();

        // Then: Validate fields
        pti = [SELECT Id,    
            Payable_AmountGST__c, 
            Payable_Amount_Ex_GST__c, 
            Payable_Amount__c,
            Requested_Amount_Ex_GST__c, 
            Requested_Amount__c 
            FROM Payment_Request_Item__c 
            WHERE Id = :pti.Id
        ];
        Assert.areEqual(20, pti.Payable_AmountGST__c, 'Payable Amount GST not updated');
        Assert.areEqual(200, pti.Payable_Amount_Ex_GST__c, 'Payable Amount Ex GST not updated');
        Assert.areEqual(220, pti.Payable_Amount__c, 'Payable Amount not updated');
        Assert.areEqual(200, pti.Requested_Amount_Ex_GST__c, 'Requested Amount Ex GST not updated');
        Assert.areEqual(220, pti.Requested_Amount__c, 'Requested Amount not updated');
    }

    @IsTest
    static void testPayableAmountExGSTModified() {
        // Setup test data
        refreshTestData();
        Payment_Request_Item__c pti = createTestPaymentRequestItem(null, null, 100, null);
        
        // When: Update payment request item
        Test.startTest();
        pti.Payable_Amount_Ex_GST__c = 200;
        update pti;
        Test.stopTest();

        // Then: Validate fields
        pti = [SELECT Id, 
            Payable_AmountGST__c, 
            Payable_Amount_Ex_GST__c, 
            Payable_Amount__c
            FROM Payment_Request_Item__c 
            WHERE Id = :pti.Id
        ];
        Assert.areEqual(20, pti.Payable_AmountGST__c, 'Payable Amount GST not updated');
        Assert.areEqual(200, pti.Payable_Amount_Ex_GST__c, 'Payable Amount Ex GST not updated');
        Assert.areEqual(220, pti.Payable_Amount__c, 'Payable Amount not updated');
    }

    @IsTest
    static void testPayableAmountGSTModified() {
        // Setup test data
        refreshTestData();
        Payment_Request_Item__c pti = createTestPaymentRequestItem(null, null, 100, 10);
        
        // When: Update payment request item
        Test.startTest();
        pti.Payable_AmountGST__c = 20;
        update pti;
        Test.stopTest();

        // Then: Validate fields
        pti = [SELECT Id, 
            Payable_AmountGST__c, 
            Payable_Amount__c
            FROM Payment_Request_Item__c 
            WHERE Id = :pti.Id
        ];
        Assert.areEqual(20, pti.Payable_AmountGST__c, 'Payable Amount GST not updated');
        Assert.areEqual(120, pti.Payable_Amount__c, 'Payable Amount not updated');
    }
}