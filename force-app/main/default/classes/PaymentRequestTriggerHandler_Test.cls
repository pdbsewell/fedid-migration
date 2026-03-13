/**
 * @author 		Sachin Shetty
 * @date 		AUG.05.2025
 * @description Test class for PaymentRequestTrigger trigger
 * @group       Apex Class
 * @revision
 *  			AUG.05.2025		Sachin Shetty	- Created
 */
@isTest (isParallel=true)
public class PaymentRequestTriggerHandler_Test {
    
    @testSetup static void createTestData() {
        TriggerCommon.disableTrigger('Course__c');
        TriggerCommon.disableTrigger('Account');
        TriggerCommon.disableTrigger('Contact');
        TriggerCommon.disableTrigger('Application__c');
        
        Course__c course = PDTestHelper.createCourse();
        Course_Offering__c co = PDTestHelper.createCourseOffering();    
        co.Course__c = course.Id;
        update co;
        Contact contact = PDTestHelper.createContact();
        Case enquiry = PDTestHelper.createEnquiry();
        Application__c application = PDTestHelper.createApplication(contact, enquiry);
        PDTestHelper.createMagentoSettings();
        Payment__c payment = PDTestHelper.createPayment(co, contact, application);
        ChargentOrders__ChargentOrder__c chOrder = PDTestHelper.createChargentOrder(payment);
        
        TriggerCommon.enableTrigger('Application__c');
        TriggerCommon.enableTrigger('Contact');
        TriggerCommon.enableTrigger('Account');        
        TriggerCommon.enableTrigger('Course__c');
    }
            
    @isTest
    static void testPaymentRequestUpdateToPaid() {
        
        // GIVEN : Test data for payment are created
		ChargentOrders__ChargentOrder__c chOrder = [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1];
        ChargentOrders__Payment_Request__c paymentRequest = PDTestHelper.createPaymentRequest(chOrder);
        
        // WHEN : The payment request - Status is set to 'Paid'
        Test.startTest();
        
            // Update to paid status to trigger the automation
            paymentRequest.ChargentOrders__Status__c = 'Paid';
            update paymentRequest;
            
        Test.stopTest();
        
        // THEN : Check that the fields on payment record as set to reflect proper status
        Payment__c payment = [SELECT Payment_Date__c, Credit_Card_Expiry_Month__c, Payment_Status__c, Send_Receipt__c FROM Payment__c LIMIT 1];
        Assert.areEqual('Processed', payment.Payment_Status__c, 'Payment status should be Processed');
        Assert.isTrue(payment.Send_Receipt__c, 'Payment send receipt should be set to True');
    }
    
    @isTest
    static void testPaymentRequestUpdateToNonPaid() {
        
        // GIVEN : Test data for payment are created
        ChargentOrders__ChargentOrder__c chOrder = [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1];
        ChargentOrders__Payment_Request__c paymentRequest = PDTestHelper.createPaymentRequest(chOrder);
        
        // WHEN : The payment request - Status is set to 'Failed'
        Test.startTest();
        
            // Update to paid status to trigger the automation
            paymentRequest.ChargentOrders__Status__c = 'Failed';
            update paymentRequest;
            
        Test.stopTest();
        
        // THEN : Check that the fields on payment record as set to reflect proper status
        Payment__c payment = [SELECT Payment_Status__c, Send_Receipt__c FROM Payment__c LIMIT 1];
        Assert.areEqual('Not Processed', payment.Payment_Status__c, 'Payment status should be Processed');
        Assert.isFalse(payment.Send_Receipt__c, 'Payment send receipt should be set to False');
    }
}