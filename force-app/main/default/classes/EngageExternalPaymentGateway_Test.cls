/**
 * @author          Mark Johnson: UC Innovation
 * @description    	This test class is to test the logic for EngageExternalPaymentGateway
 * @revision        27/05/2021 - Mark Johnson  
 */
@isTest
public class EngageExternalPaymentGateway_Test {
    
    @isTest static void testEndToEnd() {

        Map<String, Object> payloadFromFrontEnd = new Map<String, Object>();
        
        Contact donor = new Contact();
        donor.firstName = 'Bob';
        donor.lastName = 'Jones';
        insert donor;
        
        Opportunity opp = new Opportunity(CloseDate = Date.today(), 
                                          ucinn_ascendv2__Contact__c = donor.id,
                                          Name = 'Test',
                                          StageName = 'Active');
        insert opp;
        
        ucinn_ascendv2__Designation_Detail__c dd = new ucinn_ascendv2__Designation_Detail__c(ucinn_ascendv2__Opportunity__c = opp.id);
        insert dd;

        ucinn_ascendv2__Payment__c payment1 = new ucinn_ascendv2__Payment__c();

        payment1.ucinn_ascendv2__Designation_Detail__c = dd.id;
        payment1.ucinn_ascendv2__Payment_Amount__c = 0;
        payment1.ucinn_ascendv2__Payment_Group_ID__c = 'TestGroupID34li6tb3u5bil235vBTVt2323h45vgdsgdfgg';
        payment1.ucinn_ascendv2__Send_to_G_L__c = true;
        payment1.ucinn_ascendv2__Transaction_Type__c = 'Outright Gift';
        payment1.ucinn_ascendv2__Non_Gift_Amount__c = 0;
        payment1.ucinn_ascendv2__Credit_Date__c = date.valueof('2016-07-27');
        payment1.ucinn_ascendv2__Is_Tax_Receipt__c = true;
        payment1.ucinn_ascendv2__Created_In_External_Payment_Gateway__c = true;
        payment1.ucinn_ascendv2__Status_In_External_Payment_Gateway__c = 'Charged';
        payment1.ucinn_ascendv2__Subscription_ID__c = '12345';
        
        insert payment1;

        ucinn_ascendv2__Gift_Processing_External_Pymnt_Gateways__mdt customMetadata = new ucinn_ascendv2__Gift_Processing_External_Pymnt_Gateways__mdt();
        customMetadata.ucinn_ascendv2__Is_Preferred_Gateway__c = true;
        customMetadata.ucinn_ascendv2__Merchant_ID__c = 'testMerchant';
        customMetadata.ucinn_ascendv2__WSDL_Version__c = '1.155';
        customMetadata.ucinn_ascendv2__Currency_Code__c = 'USD';
        customMetadata.ucinn_ascendv2__Gateway_Named_Credential_Name__c = 'Cybersource';
        customMetadata.ucinn_ascendv2__Payment_Gateway__c = 'CyberSource';

        payloadFromFrontEnd.put('paymentRec', payment1);
        payloadFromFrontEnd.put('constituentRec', donor);
        payloadFromFrontEnd.put('paymentGatewaySetting', customMetadata);
        
        EngageExternalPaymentGateway gw = new EngageExternalPaymentGateway();
        
        gw.processPaymentThroughGateway(payloadFromFrontEnd);

        ucinn_ascendv2__Payment__c PaymentLst = [select id,ucinn_ascendv2__Transaction_Type__c from ucinn_ascendv2__Payment__c Limit 1];
        System.assertEquals(PaymentLst.ucinn_ascendv2__Transaction_Type__c,'Outright Gift');
        Opportunity oppLst = [select id,CloseDate from Opportunity where StageName ='Active'];
        System.assertEquals(oppLst.CloseDate,Date.today());
        ucinn_ascendv2__Designation_Detail__c designationLst =[select id,ucinn_ascendv2__Opportunity__c from ucinn_ascendv2__Designation_Detail__c 
                                                               where ucinn_ascendv2__Opportunity__c = :oppLst.Id];
        System.assertEquals(designationLst.ucinn_ascendv2__Opportunity__c,oppLst.ID);

    }
}