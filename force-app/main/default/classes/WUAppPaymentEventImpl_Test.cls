/**
 * @author Shalini Mendu
 * @date 10 Jan 2020
 * @group Test Class
 * @description Test class to cover the WUAppPaymentEventImpl class 
 * @revision    21.Jul.2025 M.Domingo: Changed the exception and debugging to Nebula logger framework
 */
@isTest
public with sharing class WUAppPaymentEventImpl_Test {

    @testSetup
    static void setUpData() {
        Contact c = StudFirst_TestHelper.createApplicant();
        c.Person_ID_unique__c = '1111111';
        insert c;
        Application__c app = StudFirst_TestHelper.createApplication(c);
        app.From_Portal__c = true;
        app.Status__c = 'Submitted';
        app.Fee_Amount__c = 100;
        app.Fee_Waiver_Redeemed__c = null;
        app.Fee_Payment__c = false;
        insert app;

        PaymentGateway__c cs = new PaymentGateway__c();
        cs.Name = 'GateWayList';
        cs.GatewayName__c = 'WU';
        cs.GatewayClass__c = 'WUAppPaymentEventImpl';
        insert cs;
    }
    @IsTest
    public static void testPositiveOutcome() {

        Test.startTest();
        InboundAppPayment__e cqe = new InboundAppPayment__e();
        cqe.Settlement_Amount__c = 100;
        cqe.Transaction_Type__c = 'TXVISA';
        cqe.Transaction_Id__c = '100015937387';
        cqe.Event_Reference__c = '20171125';
        cqe.Payer_Name__c = 'TOO JYE YUIN';
        cqe.CRM_Reference__c = [SELECT id FROM Application__c].Id;
        cqe.Phone__c = '91012903';
        cqe.Service_Amount__c = 10.000;
        cqe.First_Name__c = 'Yi Xin';
        cqe.Transaction_Source__c = 'WU';
        cqe.Last_Name__c = 'LIM';
        cqe.Email__c = 'e0004821@u.nus.edu';

        EventBus.publish(cqe);
        Map<String, AppPaymentEventInterface> gatewaysMap = new Map<String, AppPaymentEventInterface>();
        gatewaysMap.put('WU', new WUAppPaymentEventImpl());
        List<InboundAppPayment__e> channelEvents = new List<InboundAppPayment__e>{
                cqe
        };

        //Invoke the Interface which calls the method on the actual class
        WUAppPaymentEventImpl paymentInt = new WUAppPaymentEventImpl();
        paymentInt.processIncomingEvents(channelEvents[0]);
        Assert.areEqual(true,[SELECT Fee_Payment__c FROM Application__c].Fee_Payment__c);
        Test.stopTest();
    }

    @IsTest
    public static void testPositiveOutcomeWithContact() {

        Test.startTest();
        InboundAppPayment__e cqe = new InboundAppPayment__e();
        cqe.Settlement_Amount__c = 100;
        cqe.Transaction_Type__c = 'TXVISA';
        cqe.Transaction_Id__c = '100015937387';
        cqe.Event_Reference__c = '20171125';
        cqe.Payer_Name__c = 'TOO JYE YUIN';
        cqe.CRM_Reference__c = [SELECT id FROM Contact].Id;
        cqe.Phone__c = '91012903';
        cqe.Service_Amount__c = 10.000;
        cqe.First_Name__c = 'Yi Xin';
        cqe.Transaction_Source__c = 'WU';
        cqe.Last_Name__c = 'LIM';
        cqe.Email__c = 'e0004821@u.nus.edu';

        EventBus.publish(cqe);
        Map<String, AppPaymentEventInterface> gatewaysMap = new Map<String, AppPaymentEventInterface>();
        gatewaysMap.put('WU', new WUAppPaymentEventImpl());
        List<InboundAppPayment__e> channelEvents = new List<InboundAppPayment__e>{
                cqe
        };
        //Invoke the Interface which calls the method on the actual class
        WUAppPaymentEventImpl paymentInt = new WUAppPaymentEventImpl();
        paymentInt.processIncomingEvents(channelEvents[0]);
        Assert.areEqual(true,[SELECT Fee_Payment__c FROM Application__c].Fee_Payment__c);
        Test.stopTest();
    }

    @IsTest
    public static void testNegativeOutcome() {

        Test.startTest();
        InboundAppPayment__e cqe = new InboundAppPayment__e();
        cqe.Settlement_Amount__c = 100;
        cqe.Transaction_Type__c = 'TXVISA';
        cqe.Transaction_Id__c = '100015937387';
        cqe.Event_Reference__c = '20171125';
        cqe.Payer_Name__c = 'TOO JYE YUIN';
        cqe.CRM_Reference__c = null;
        cqe.Phone__c = '91012903';
        cqe.Service_Amount__c = 10.000;
        cqe.First_Name__c = 'Yi Xin';
        cqe.Transaction_Source__c = 'WU';
        cqe.Last_Name__c = 'LIM';
        cqe.Email__c = 'e0004821@u.nus.edu';
        EventBus.publish(cqe);

        Map<String, AppPaymentEventInterface> gatewaysMap = new Map<String, AppPaymentEventInterface>();
        gatewaysMap.put('WU', new WUAppPaymentEventImpl());

        List<InboundAppPayment__e> channelEvents = new List<InboundAppPayment__e>{
                cqe
        };
        AppPaymentEventInterface paymentInt = new AppPaymentEventInterface(channelEvents[0], gatewaysMap);
        paymentInt.processIncomingEvents(channelEvents[0]);
        Assert.areEqual(cqe.CRM_Reference__c, null);

        Test.stopTest();
    }
}