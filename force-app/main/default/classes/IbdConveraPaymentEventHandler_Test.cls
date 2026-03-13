/**
 * @author Shalini Mendu
 * @date 14/01/2025
 * @group Test Class
 * @description Covers the inbound call trigger for the platform event
 */
@IsTest
public with sharing class IbdConveraPaymentEventHandler_Test {

   /** 
   * @description Test IbdConveraPayment__e insert 
   * by publishing the event
   * @author Shalini Mendu - 30/01/2025
   */
    @IsTest
    public static void testInsertPaymentEvent(){
        PaymentGateway__c gateway = new PaymentGateway__c();
        gateway.GatewayName__c = 'Western Union';
        gateway.GatewayClass__c = 'Western Union';
        gateway.Name = 'Test Name';
        insert gateway;
        //GIVEN - IbdConveraPayment__e is created
        IbdConveraPayment__e event = new IbdConveraPayment__e();
        event.First_Name__c = 'Test';
        event.Last_Name__c = 'Test';
        event.Email__c = 'test@test.com';
        event.CRM_Reference__c = '111';
        event.Event_Reference__c = '111';
        event.Settlement_Amount__c = 100.00;
        event.Transaction_Id__c = '111';
        event.Transaction_Type__c = 'Test';
        event.Transaction_Source__c = 'Union';

        Test.startTest();
            //WHEN - IbdConveraPayment__e is published
            Database.SaveResult src = EventBus.publish(event);
        Test.stopTest();
        //THEN - The event was published successfully
        Assert.isTrue(src.success, 'Unable to save platform event');
    }
}