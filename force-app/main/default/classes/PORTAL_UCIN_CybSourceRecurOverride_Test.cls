@isTest(isParallel=true)
public class PORTAL_UCIN_CybSourceRecurOverride_Test {
	@isTest static void testCreateRecurringSubEncryptedData() {
        Map<String, Object> payloadFromFrontEnd = new Map<String, Object>();

        //GIVEN: We have a pledge to process
        Opportunity opp1 = new Opportunity();
        opp1.Name = 'Test Pledge';
        opp1.StageName = 'Active';
        opp1.CloseDate = System.Date.today();
        opp1.ucinn_ascendv2__Credit_Date__c = Date.today().addDays(-1);
        opp1.ucinn_ascendv2__Subscription_ID__c = 'abc123';
        opp1.ucinn_ascendv2__Encrypted_Payment_Information__c = 'abc123';

        ucinn_ascendv2__Gift_Processing_External_Pymnt_Gateways__mdt customMetadata = new ucinn_ascendv2__Gift_Processing_External_Pymnt_Gateways__mdt();
        customMetadata.ucinn_ascendv2__Is_Preferred_Gateway__c = true;
        customMetadata.ucinn_ascendv2__Merchant_ID__c = 'testMerchant';
        customMetadata.ucinn_ascendv2__WSDL_Version__c = '1.155';
        customMetadata.ucinn_ascendv2__Currency_Code__c = 'USD';
        customMetadata.ucinn_ascendv2__Gateway_Named_Credential_Name__c = 'Cybersource';
        customMetadata.ucinn_ascendv2__Payment_Gateway__c = 'CyberSource';


        Contact donor = new Contact();
        donor.firstName = 'Bob';
        donor.lastName = 'Jones';

        payloadFromFrontEnd.put('giftRec', opp1);
        payloadFromFrontEnd.put('constituentRec', donor);
        payloadFromFrontEnd.put('constituentCardHolder', donor);
        payloadFromFrontEnd.put('paymentGatewaySetting', customMetadata);

        //WHEN: The a payment is processed through CyberSource
        test.startTest();
        ucinn_ascendv2.ascend_GIFT_ExternalPaymentGateway cyberSourceCalloutClass = new ucinn_ascendv2.ascend_GIFT_ExternalPaymentGateway();
        cyberSourceCalloutClass.processPaymentThroughGateway(payloadFromFrontEnd);
        test.stopTest();

        //THEN: transaction data records are created
        List<ucinn_ascendv2__Transaction_Data__c> transData = [SELECT ID FROM ucinn_ascendv2__Transaction_Data__c];
        Assert.isTrue(!transData.isEmpty(), 'transaction data records created');
    }

    @isTest static void testCreateRecurringSubOnlineDonation() {
        Map<String, Object> payloadFromFrontEnd = new Map<String, Object>();

        //GIVEN: We have a pledge to process
        Opportunity opp1 = new Opportunity();
        opp1.Name = 'Test Pledge';
        opp1.StageName = 'Active';
        opp1.CloseDate = System.Date.today();
        opp1.ucinn_ascendv2__Credit_Date__c = Date.today().addDays(-1);
        opp1.ucinn_ascendv2__Subscription_ID__c = 'abc123';
        opp1.ucinn_ascendv2__External_Payment_Gateway_ID__c = 'test123';
        opp1.ucinn_ascendv2__Card_Expiration_Date__c = '1123';
        opp1.ucinn_ascendv2__Payment_Type__c = 'VISA';
        opp1.ucinn_ascendv2__Card_Number__c = '1234567890123456';

        ucinn_ascendv2__Gift_Processing_External_Pymnt_Gateways__mdt customMetadata = new ucinn_ascendv2__Gift_Processing_External_Pymnt_Gateways__mdt();
        customMetadata.ucinn_ascendv2__Is_Preferred_Gateway__c = true;
        customMetadata.ucinn_ascendv2__Merchant_ID__c = 'testMerchant';
        customMetadata.ucinn_ascendv2__WSDL_Version__c = '1.155';
        customMetadata.ucinn_ascendv2__Currency_Code__c = 'USD';
        customMetadata.ucinn_ascendv2__Gateway_Named_Credential_Name__c = 'Cybersource';
        customMetadata.ucinn_ascendv2__Payment_Gateway__c = 'CyberSource';

        Contact donor = new Contact();
        donor.firstName = 'Bob';
        donor.lastName = 'Jones';

        payloadFromFrontEnd.put('giftRec', opp1);
        payloadFromFrontEnd.put('constituentRec', donor);
        payloadFromFrontEnd.put('constituentCardHolder', donor);
        payloadFromFrontEnd.put('paymentGatewaySetting', customMetadata);

        //WHEN: The a payment is processed through CyberSource
        test.startTest();
        ucinn_ascendv2.ascend_GIFT_ExternalPaymentGateway cyberSourceCalloutClass = new ucinn_ascendv2.ascend_GIFT_ExternalPaymentGateway();
        cyberSourceCalloutClass.processPaymentThroughGateway(payloadFromFrontEnd);
        test.stopTest();

        //THEN: transaction data records are created
        List<ucinn_ascendv2__Transaction_Data__c> transData = [SELECT ID FROM ucinn_ascendv2__Transaction_Data__c];
        Assert.isTrue(!transData.isEmpty(), 'transaction data records created');
    }
}