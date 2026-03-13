/**
 * @author Shalini Mendu
 * @date   14/01/2025  
* @group Test Class
 * @description Test class to cover the AppPaymentEventInterface virtual class
 */
@isTest
public with sharing class ConveraPaymentEventInterface_Test {

    @testSetup static void setUpData()
    {
        Contact c = StudFirst_TestHelper.createApplicant();
        c.Person_ID_unique__c = '1111111';
        insert c;
        Application__c app = StudFirst_TestHelper.createApplication(c);
        insert app;

        PaymentGateway__c cs = new PaymentGateway__c();
        cs.Name = 'GateWayList';
        cs.GatewayName__c = 'WU';
        cs.GatewayClass__c = 'WUAppPaymentEventImpl';
        insert cs;
    }

    /** 
   * @description Test verifies Fee paid is false for Application 
   * with IbdConveraPayment__e ppublished with reference to Application 
   * @author Shalini Mendu - 30/01/2025
   */
    @IsTest
    public static void testConvertString2Date()
    {   

        Test.startTest();
            //GIVEN - Static method is invoked
            //WHEN - with a sample date in a string format
            Date dd = ConveraPaymentEventInterface.convertStr2Dt('20251125');
        Test.stopTest();
            //THEN - year must match with the first digits of the date in String format
            Assert.areEqual(2025, dd.year(), 'The year must 2025');
    }   

    /**
    * @author Shalini Mendu
    * @date   14/01/2025  
    * @group Test Class
    * @description Test Nebula logging
    */
    @IsTest
    public static void testNebulaLogging()
    {

        Test.startTest();
            //GIVEN - IbdConveraPayment__e is created
            
            IbdConveraPayment__e cqe = new IbdConveraPayment__e();
            cqe.Settlement_Amount__c = 100;
            cqe.Transaction_Type__c = 'TXVISA';
            cqe.Transaction_Id__c = '100015937387';
            cqe.Event_Reference__c = '20251125';
            cqe.Payer_Name__c = 'TOO JYE YUIN';
            cqe.CRM_Reference__c = [SELECT id FROM Application__c].Id;
            cqe.Phone__c = '91012903';
            cqe.Service_Amount__c =  10.000;
            cqe.First_Name__c = 'Yi Xin';
            cqe.Transaction_Source__c = 'WU';
            cqe.Last_Name__c = 'LIM';
            cqe.Email__c = 'e0004821@u.nus.edu';

            Database.SaveResult sr = EventBus.publish(cqe);

            Map<String,ConveraPaymentEventInterface> gatewaysMap = new Map<String,ConveraPaymentEventInterface>();
            gatewaysMap.put('WU12',new ConveraPaymentEventImpl());

            List<IbdConveraPayment__e> channel_events = new List<IbdConveraPayment__e>{cqe};
            //WHEN - ConveraPaymentEventInterface constructor is called with the required data
            ConveraPaymentEventInterface paymentInt = new ConveraPaymentEventInterface(channel_events[0], gatewaysMap);
            paymentInt.processIncomingEvents(channel_events[0]);
        Test.stopTest();

        Nebula__LogEntry__c[] logs = [ SELECT Nebula__Message__c FROM Nebula__LogEntry__c];
        //THEN - There should be a Nebula error loged 
        Assert.isTrue(logs.size()>0, 'There must have been atleast one Nebula log entered');
    }
}