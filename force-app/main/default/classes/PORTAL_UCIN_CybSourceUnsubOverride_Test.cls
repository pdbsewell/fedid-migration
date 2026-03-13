@isTest(isParallel=true)
public class PORTAL_UCIN_CybSourceUnsubOverride_Test {
	@isTest static void testCreateUnSubEncryptedData() {
        Map<String, Object> payloadFromFrontEnd = new Map<String, Object>();

        //GIVEN: We have a payment to process
        ucinn_ascendv2__Payment__c payment1 = new ucinn_ascendv2__Payment__c();
        payment1.Name = 'Test Pledge';
        payment1.ucinn_ascendv2__Created_In_External_Payment_Gateway__c = false;
        payment1.ucinn_ascendv2__Credit_Card_Type__c = 'VISA';
        payment1.ucinn_ascendv2__Credit_Card_Expiration_Date__c = '1123';

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

        payloadFromFrontEnd.put('paymentRec', payment1);
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

    @isTest static void testCreateUnSubOnlineDonation() {
        Map<String, Object> payloadFromFrontEnd = new Map<String, Object>();

        //GIVEN: We have a payment to process
        ucinn_ascendv2__Payment__c payment1 = new ucinn_ascendv2__Payment__c();
        payment1.Name = 'Test Pledge';
        payment1.ucinn_ascendv2__Created_In_External_Payment_Gateway__c = false;
        payment1.ucinn_ascendv2__Encrypted_Payment_Information__c = 'test123';
        payment1.ucinn_ascendv2__Credit_Card_Number__c = '1234567890123456';
        payment1.ucinn_ascendv2__Credit_Card_Type__c = 'VISA';
        payment1.ucinn_ascendv2__Credit_Card_Expiration_Date__c = '1130';
        payment1.ucinn_ascendv2__Authorization_Code__c = 'test';

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

        payloadFromFrontEnd.put('paymentRec', payment1);
        payloadFromFrontEnd.put('constituentRec', donor);
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