/**
 * Created by smen0015 on 13/11/2018.
 */
@isTest
public with sharing class WUAppPayment_Test {
    @testSetup static void setUpData()
    {
        Contact con = new Contact();
        con.Person_Id_unique__c = 'IdAA';
        con.LastName = 'LastnameAA';
        con.FirstName = 'FirstnameAA';
        insert con;

        Application__c application = new Application__c();
        application.Applicant__c = con.Id;
        application.Passport_Number__c = 'A1234567';
        application.Campus_Location__c = null;
        application.Visa_Type__c = null;
        application.Australian_Immigration_Office_Issued__c = null;
        application.Visa_Number__c = null;
        application.Passport_Number__c = null;
        application.Visa_Start_Date__c = null;
        application.Visa_End_Date__c = null;
        application.Refused_entry_visa_to_any_country__c = null;
        application.Breached_visa_condition__c = null;
        application.Medical_health_prevent_visa__c = null;
        application.Protection_visa_in_any_country__c = null;
        application.Convicted_of_crime_offence__c = null;
        application.Status__c = 'Submitted';
        application.From_Portal__c  = true;
        application.Fee_Amount__c = 100;
        application.Fee_Waiver_Redeemed__c = null;
        application.Fee_Payment__c = false;
        insert application;

        PaymentGateway__c cs = new PaymentGateway__c();
        cs.Name = 'GateWayList';
        cs.GatewayName__c = 'WU';
        cs.GatewayClass__c = 'WUAppPaymentEventImpl';
        insert cs;

    }

    @isTest static void tesAppNotFound() {
        Application__c app = [SELECT  ID,From_Portal__c,Status__c,
                Transaction_Source__c,Fee_Waiver_Redeemed__c,Fee_Payment__c,
                Transaction_Reference__c,Fee_Amount__c,Transaction_Date__c,
                Transaction_Amount__c from Application__c];
        InboundAppPayment__e cqe = new InboundAppPayment__e();
        cqe.Settlement_Amount__c = 1000;
        cqe.Transaction_Type__c = 'TXVISA';
        cqe.Transaction_Id__c = '100015937387';
        cqe.Event_Reference__c = '20171125';
        cqe.Payer_Name__c = 'TOO JYE YUIN';
        cqe.CRM_Reference__c = app.Id;
        cqe.Phone__c = '91012903';
        cqe.Service_Amount__c =  10.000;
        cqe.First_Name__c = 'Yi Xin';
        cqe.Transaction_Source__c = 'WU';
        cqe.Last_Name__c = 'LIM';
        cqe.Email__c = 'e0004821@u.nus.edu';

       // insert cqe;
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(cqe);

        Test.stopTest();
        Application__c app1 = [SELECT  ID,From_Portal__c,Status__c,
                Transaction_Source__c,Fee_Waiver_Redeemed__c,Fee_Payment__c,
                Transaction_Reference__c,Fee_Amount__c,Transaction_Date__c,
                Transaction_Amount__c from Application__c];
        System.assertEquals(false ,app.Fee_Payment__c);
    }

    @isTest static void tesAppFound() {
        Application__c app = [SELECT  ID,From_Portal__c,Status__c,
                Transaction_Source__c,Fee_Waiver_Redeemed__c,Fee_Payment__c,
                Transaction_Reference__c,Fee_Amount__c,Transaction_Date__c,
                Transaction_Amount__c from Application__c];
        InboundAppPayment__e cqe = new InboundAppPayment__e();
        cqe.Settlement_Amount__c = 100;
        cqe.Transaction_Type__c = 'TXVISA';
        cqe.Transaction_Id__c = '100015937387';
        cqe.Event_Reference__c = '20171125';
        cqe.Payer_Name__c = 'TOO JYE YUIN';
        cqe.CRM_Reference__c = app.Id;
        cqe.Phone__c = '91012903';
        cqe.Service_Amount__c =  10.000;
        cqe.First_Name__c = 'Yi Xin';
        cqe.Transaction_Source__c = 'WU';
        cqe.Last_Name__c = 'LIM';
        cqe.Email__c = 'e0004821@u.nus.edu';



        // insert cqe;
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(cqe);
        Test.stopTest();
        Application__c app1 = [SELECT  ID,From_Portal__c,Status__c,
                Transaction_Source__c,Fee_Waiver_Redeemed__c,Fee_Payment__c,
                Transaction_Reference__c,Fee_Amount__c,Transaction_Date__c,
                Transaction_Amount__c from Application__c];
        System.assertEquals(true,app1.Fee_Payment__c);

    }

    @isTest static void testInValidContactOrApp() {

        InboundAppPayment__e cqe = new InboundAppPayment__e();
        cqe.Settlement_Amount__c = 100;
        cqe.Transaction_Type__c = 'TXVISA';
        cqe.Transaction_Id__c = '100015937387';
        cqe.Event_Reference__c = '20171125';
        cqe.Payer_Name__c = 'TOO JYE YUIN';
        cqe.CRM_Reference__c = '11111111';
        cqe.Phone__c = '91012903';
        cqe.Service_Amount__c =  10.000;
        cqe.First_Name__c = 'Yi Xin';
        cqe.Transaction_Source__c = 'WU';
        cqe.Last_Name__c = 'LIM';
        cqe.Email__c = 'e0004821@u.nus.edu';

        // insert cqe;
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(cqe);

        Test.stopTest();

    }

    @isTest static void tesContactAppFound() {
        Contact con = [SELECT  ID,( SELECT ID,From_Portal__c,Status__c,
        Transaction_Source__c,Fee_Waiver_Redeemed__c,Fee_Payment__c,
        Transaction_Reference__c,Fee_Amount__c,Transaction_Date__c,
        Transaction_Amount__c

        FROM Applications__r) FROM Contact];
        System.debug('con=='+con);
        System.debug('con app=='+con.Applications__r);
        InboundAppPayment__e cqe = new InboundAppPayment__e();
        cqe.Settlement_Amount__c = 100;
        cqe.Transaction_Type__c = 'TXVISA';
        cqe.Transaction_Id__c = '100015937387';
        cqe.Event_Reference__c = '20171125';
        cqe.Payer_Name__c = 'TOO JYE YUIN';
        cqe.CRM_Reference__c = con.Id;
        cqe.Phone__c = '91012903';
        cqe.Service_Amount__c =  10.000;
        cqe.First_Name__c = 'Yi Xin';
        cqe.Transaction_Source__c = 'WU';
        cqe.Last_Name__c = 'LIM';
        cqe.Email__c = 'e0004821@u.nus.edu';

        // insert cqe;
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(cqe);

        Test.stopTest();
        Contact con1 = [SELECT  ID,( SELECT ID,From_Portal__c,Status__c,
                Transaction_Source__c,Fee_Waiver_Redeemed__c,Fee_Payment__c,
                Transaction_Reference__c,Fee_Amount__c,Transaction_Date__c,
                Transaction_Amount__c  FROM Applications__r) FROM Contact];

        System.assertEquals(true,con1.Applications__r[0].Fee_Payment__c);

    }

    @isTest static void tesContactAppNotFound() {
        Contact con = [SELECT  ID FROM Contact];
        InboundAppPayment__e cqe = new InboundAppPayment__e();
        cqe.Settlement_Amount__c = 1000;
        cqe.Transaction_Type__c = 'TXVISA';
        cqe.Transaction_Id__c = '100015937387';
        cqe.Event_Reference__c = '20171125';
        cqe.Payer_Name__c = 'TOO JYE YUIN';
        cqe.CRM_Reference__c = con.Id;
        cqe.Phone__c = '91012903';
        cqe.Service_Amount__c =  10.000;
        cqe.First_Name__c = 'Yi Xin';
        cqe.Transaction_Source__c = 'WU';
        cqe.Last_Name__c = 'LIM';
        cqe.Email__c = 'e0004821@u.nus.edu';

        // insert cqe;
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(cqe);

        Test.stopTest();
        Contact con1 = [SELECT  ID,( SELECT ID,From_Portal__c,Status__c,
                Transaction_Source__c,Fee_Waiver_Redeemed__c,Fee_Payment__c,
                Transaction_Reference__c,Fee_Amount__c,Transaction_Date__c,
                Transaction_Amount__c  FROM Applications__r) FROM Contact];
        System.assertEquals(false,con1.Applications__r[0].Fee_Payment__c);

    }
}