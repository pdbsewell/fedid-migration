/**
 * @author Trent De Laney
 * @date 6 Jan 2020 at 8:58:00 pm
 * @group Test Class
 * @description Covers the inbound call for the platform event
 * @revision
 *  AUG.08.2025		Sachin Shetty	- Updated assertions to use Assert class methods 
 */
@IsTest (isParallel=true)
public with sharing class IbdAppPaymentEventHandler_Test {
    @IsTest
    public static void testInsertPaymentEvent(){

        // GIVEN : Payment Gateway record s created
        PaymentGateway__c gateway = new PaymentGateway__c();
        gateway.GatewayName__c = 'Western Union';
        gateway.GatewayClass__c = 'Western Union';
        gateway.Name = 'Test Name';
        insert gateway;

        InboundAppPayment__e event = new InboundAppPayment__e();
        event.First_Name__c = 'Test';
        event.Last_Name__c = 'Test';
        event.Email__c = 'test@test.com';
        event.CRM_Reference__c = '111';
        event.Event_Reference__c = '111';
        event.Settlement_Amount__c = 100.00;
        event.Transaction_Id__c = '111';
        event.Transaction_Type__c = 'Test';
        event.Transaction_Source__c = 'Union';

        // WHEN : InboundAppPayment platform event is created
        Test.startTest();
        	Database.SaveResult src = EventBus.publish(event);
        Test.stopTest();

        // THEN : Test that the platform event is created successfully
        Assert.isTrue(src.success, 'Unable to save platform event');
    }
}