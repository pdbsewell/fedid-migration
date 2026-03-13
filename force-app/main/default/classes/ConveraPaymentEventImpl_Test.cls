/**
 * @author Shalini Mendu
 * @date   14/01/2025 
 * @group Test Class
 * @description Test class to cover ConveraPaymentEventImpl class 
 */
@isTest
public with sharing class ConveraPaymentEventImpl_Test {

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
        cs.GatewayClass__c = 'ConveraPaymentEventImpl';
        insert cs;
    }
    
   /** 
   * @description Test verifies Fee paid is true for Application 
   * with IbdConveraPayment__e published with reference to Application 
   * @author Shalini Mendu - 30/01/2025
   */
    @IsTest
    public static void testFeePaidApplicationReference() {

        Test.startTest();
        //GIVEN - IbdConveraPayment__e is set up correctly 
        IbdConveraPayment__e cqe = new IbdConveraPayment__e();
        cqe.Settlement_Amount__c = 100;
        cqe.Transaction_Type__c = 'TXVISA';
        cqe.Transaction_Id__c = '100015937387';
        cqe.Event_Reference__c = '20241125';
        cqe.Payer_Name__c = 'TOO JYE YUIN';
        cqe.CRM_Reference__c = [SELECT id FROM Application__c].Id;
        cqe.Phone__c = '91012903';
        cqe.Service_Amount__c = 10.000;
        cqe.First_Name__c = 'Yi Xin';
        cqe.Transaction_Source__c = 'WU';
        cqe.Last_Name__c = 'LIM';
        cqe.Email__c = 'e0004821@u.nus.edu';
        
        //WHEN - IbdConveraPayment__e is published against CRM_Reference__c of the Application
        Database.SaveResult sr = EventBus.publish(cqe);
        Map<String, ConveraPaymentEventImpl> gatewaysMap = new Map<String, ConveraPaymentEventImpl>();
        gatewaysMap.put('WU', new ConveraPaymentEventImpl());
        List<IbdConveraPayment__e> channel_events = new List<IbdConveraPayment__e>{
                cqe
        };

        //Invoke the Interface which calls the method on the actual class
        ConveraPaymentEventImpl paymentInt = new ConveraPaymentEventImpl();
        paymentInt.processIncomingEvents(channel_events[0]);
        
        //THEN - Fee_Payment__c on the Application must be true
        Assert.isTrue([SELECT Fee_Payment__c FROM Application__c].Fee_Payment__c, 'Fee payment must be true');
        Test.stopTest();
    }


    /** 
   * @description Test verifies Fee paid is true for Application 
   * with IbdConveraPayment__e published with reference to Contact 
   * @author Shalini Mendu - 30/01/2025
   */
    @IsTest
    public static void testFeePaidContactReference() {

        //GIVEN - IbdConveraPayment__e is set up correctly 
        IbdConveraPayment__e cqe = new IbdConveraPayment__e();
        cqe.Settlement_Amount__c = 100;
        cqe.Transaction_Type__c = 'TXVISA';
        cqe.Transaction_Id__c = '100015937387';
        cqe.Event_Reference__c = '20241125';
        cqe.Payer_Name__c = 'TOO JYE YUIN';
        cqe.CRM_Reference__c = [SELECT id FROM Contact].Id;
        cqe.Phone__c = '91012903';
        cqe.Service_Amount__c = 10.000;
        cqe.First_Name__c = 'Yi Xin';
        cqe.Transaction_Source__c = 'WU';
        cqe.Last_Name__c = 'LIM';
        cqe.Email__c = 'e0004821@u.nus.edu';

        Test.startTest();
            Database.SaveResult sr = EventBus.publish(cqe);
            Map<String, ConveraPaymentEventInterface> gatewaysMap = new Map<String, ConveraPaymentEventInterface>();
            gatewaysMap.put('WU', new ConveraPaymentEventInterface());
            List<IbdConveraPayment__e> channel_events = new List<IbdConveraPayment__e>{
                    cqe
            };
            //WHEN - Invoke the Interface is invoked with the payload
            ConveraPaymentEventInterface paymentInt = new ConveraPaymentEventInterface();
            paymentInt.processIncomingEvents(channel_events[0]);
          
        Test.stopTest();
        // THEN - Fee_Payment__c must be set to true
        Assert.isTrue([SELECT Fee_Payment__c FROM Application__c].Fee_Payment__c, 'Fee payment must be true');
    }

    /** 
   * @description Test verifies Nebula logging 
   * with IbdConveraPayment__e ppublished with reference to Application 
   * verifies Exception logging
   * @author Shalini Mendu - 31/01/2025
   */
    @IsTest
    public static void testNebulaLogging() {

        Test.startTest();
        IbdConveraPayment__e cqe = new IbdConveraPayment__e();
        cqe.Settlement_Amount__c = 100;
        cqe.Transaction_Type__c = 'TXVISA';
        cqe.Transaction_Id__c = '100015937387';
        cqe.Event_Reference__c = '20241125';
        cqe.Payer_Name__c = 'TOO JYE YUIN';
        cqe.CRM_Reference__c = [SELECT id FROM Application__c].Id;
        cqe.Phone__c = '91012903';
        cqe.Service_Amount__c = 10.000;
        cqe.First_Name__c = 'Yi Xin';
        cqe.Transaction_Source__c = 'WU';
        cqe.Last_Name__c = 'LIM';
        cqe.Email__c = 'e0004821@u.nus.edu';
        Database.SaveResult sr = EventBus.publish(cqe);

        Map<String, ConveraPaymentEventInterface> gatewaysMap = new Map<String, ConveraPaymentEventInterface>();
        gatewaysMap.put('WU', new ConveraPaymentEventImpl());

        List<IbdConveraPayment__e> channel_events = new List<IbdConveraPayment__e>{
                cqe
        };
        ConveraPaymentEventInterface paymentInt = new ConveraPaymentEventInterface(channel_events[0], gatewaysMap);
        paymentInt.processIncomingEvents(channel_events[0]);
        Test.stopTest();
      
        Nebula__LogEntry__c[] logs = [ SELECT Nebula__Message__c FROM Nebula__LogEntry__c];
        // THEN - There should be a Nebula error loged 
        Assert.isTrue(logs.size()>0, 'There must have been atleast one Nebula log entered');
     
    }
}