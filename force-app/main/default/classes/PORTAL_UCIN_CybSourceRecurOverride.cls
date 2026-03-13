/**
 * @author          Charlie Park: UC Innovation
 * @description    	This override class is to provide custom logic for Monash Alumni Portal to send credit card info without bluefin.Approval
                    Instead of using the encrypted payment info field, will tokenize the credit card info to send securely.
 * @revision        12/17/2019 - Charlie Park - Initial version
 *  * Modifications Log 
 * Date         Author         		 Modification
 * 2025-06-13   Matthew Maramot     Ascend Package Upgrade 5.48.7 EPCP-4869
 * 2022-06-23   Inderpal Dhanoa    	Adding American Express PENGAGE-2011
 * 2019-12-17   Charlie Park    	Initial version
 */

global class PORTAL_UCIN_CybSourceRecurOverride extends ucinn_ascendv2.ascend_GIFT_ExternalPaymentRecurGift {

    // From page 481 of cybersource documentation: http://apps.cybersource.com/library/documentation/dev_guides/CC_Svcs_SO_API/Credit_Cards_SO_API.pdf
    private Map<String, String> creditCardTypeMap = new Map<String, String> {
        'visa' => '001',
        'mastercard' => '002',
        'amex' => '003',
		'american express' => '003',
        'discover' => '004',
        'diners club' => '005'
    };

    global Map<String, String> requiredFieldMap = new Map<String, String> { 'merchantID' => 'Merchant ID (Please configure custom metadata type)', 
                                                                                        'merchantReferenceCode' => 'Merchant Reference Code', 
                                                                                        'wsdlVersion' => 'WSDL Version (Please configure custom metadata type)', 
                                                                                        'terminalCapability' => 'Terminal Capability (Please configure custom metadata type)', 
                                                                                        'firstName' => 'Constituent First Name', 
                                                                                        'lastName' => 'Constituent Last Name',
                                                                                        'currency' => 'Currency Code (Please configure custom metadata type)',
                                                                                        'grandTotal' => 'Grand Total',
                                                                                        'entryMode' => 'Entry Mode',
                                                                                        'cardPresent' => 'Card Present',
                                                                                        'paymentDescriptor' => 'Payment Descriptor',
                                                                                        //'paymentData' => 'Payment Data',
                                                                                        'authService' => 'Auth Service Enabled',
                                                                                        'captureService' => 'Capture Service Enabled',
                                                                                        'paySubscriptionCreateService' => 'Subscription Create Service Enabled',
                                                                                        'disableAutoAuth' => 'Disabled Auto Auth',
                                                                                        'frequency' => 'Recurring Gift Frequency',
                                                                                        'recurringAmount' => 'Recurring Amount',
                                                                                        'recurringStartDate' => 'Recurring Start Date',
                                                                                        'namedCredentialName' => 'Named Credential Name (Please configure custom metadata type)'};


    /*******************************************************************************
	* @author       Charlie Park - UC Innovation
	* @date         10/9/2019 
	* @description  
	********************************************************************************/
    global override void constructVarMap() {
        //ucinn_ascendv2__Payment__c paymentRec = ucinn_ascendv2.ascend_GIFT_ExternalPaymentCyberSource.paymentRec;
        Opportunity oppRec = ucinn_ascendv2.ascend_GIFT_ExternalPaymentCyberSource.oppRec;
        ucinn_ascendv2__Gift_Processing_External_Pymnt_Gateways__mdt paymentGatewaySetting = ucinn_ascendv2.ascend_GIFT_ExternalPaymentCyberSource.paymentGatewaySetting;
        Contact constituentRec = ucinn_ascendv2.ascend_GIFT_ExternalPaymentCyberSource.constituentRec;
        Map<String, Boolean> tenderTypeToZeroDollarAuthEnabled = ucinn_ascendv2.ascend_GIFT_ExternalPaymentCyberSource.tenderTypeToZeroDollarAuthEnabled;

        if (tenderTypeToZeroDollarAuthEnabled.get(oppRec.ucinn_ascendv2__Tender_Type_For_Gifts__c) == true) {
            zeroDollarAuthEnabled = true;
        }

        String merchantReferenceCode;

        // If encrypted payment info is there, that means it's from regular gift processing. 
        if (String.isEmpty(oppRec.ucinn_ascendv2__Card_Number__c)) {
            //If it's from regular gift processing and the constituentrec does not exist, it should be an Account CC related gift
            //so constituentCardHolder should be used in lieu of constituentRec 
            if(constituentRec == null || constituentRec.Id == null){
                constituentRec = ucinn_ascendv2.ascend_GIFT_ExternalPaymentCyberSource.constituentCardHolder;
            }
            
            requiredFieldMap.put('paymentData', 'Encrypted Payment Data');
            if (oppRec.ucinn_ascendv2__External_Payment_Gateway_ID__c != null) {
                merchantReferenceCode = oppRec.ucinn_ascendv2__External_Payment_Gateway_ID__c;
            } else {
                merchantReferenceCode = oppRec.Id;
            }

            ucinn_ascendv2.ascend_GIFT_ExternalPaymentCyberSource.varMap = new Map<String, String>{
                'userName' => '{!$Credential.UserName}',
                'password' => '{!$Credential.Password}',
                'merchantID' => paymentGatewaySetting.ucinn_ascendv2__Merchant_ID__c,
                'merchantReferenceCode' => merchantReferenceCode,
                'wsdlVersion' => paymentGatewaySetting.ucinn_ascendv2__WSDL_Version__c,
                'terminalCapability' => '2',
                'firstName' => constituentRec.FirstName,
                'lastName' => constituentRec.LastName,
                'currency' => paymentGatewaySetting.ucinn_ascendv2__Currency_Code__c,
                'grandTotal' => '0.00',
                'entryMode' => 'keyed',
                'cardPresent' => 'N',
                'paymentDescriptor' => 'Ymx1ZWZpbg==',
                'paymentData' => oppRec.ucinn_ascendv2__Encrypted_Payment_Information__c,
                'authService' => 'true',
                'paySubscriptionCreateService' => 'true',
                'subscriptionID' => oppRec.ucinn_ascendv2__Subscription_ID__c,
                'disableAutoAuth' => 'false',
                'recurringAmount' => String.valueOf(oppRec.Amount),
                'recurringStartDate' => correctDate(oppRec.ucinn_ascendv2__Start_Date__c),
                'frequency' => correctFrequency(oppRec.ucinn_ascendv2__Frequency__c),
                'commerceIndicator' => 'recurring',
                'paymentMethod' => 'credit card',
                'namedCredentialName' => paymentGatewaySetting.ucinn_ascendv2__Gateway_Named_Credential_Name__c
            };
        }

        // If encrypted payment info is NOT there, then it's from portal. It needs to get payment info directly as a tokenized card.
        else {
            if (oppRec.ucinn_ascendv2__External_Payment_Gateway_ID__c != null) {
                merchantReferenceCode = oppRec.ucinn_ascendv2__External_Payment_Gateway_ID__c;
            } 

            ucinn_ascendv2.ascend_GIFT_ExternalPaymentCyberSource.varMap = new Map<String, String>{
                'userName' => '{!$Credential.UserName}',
                'password' => '{!$Credential.Password}',
                'merchantID' => paymentGatewaySetting.ucinn_ascendv2__Merchant_ID__c,
                'merchantReferenceCode' => merchantReferenceCode,
                'wsdlVersion' => paymentGatewaySetting.ucinn_ascendv2__WSDL_Version__c,
                'terminalCapability' => '2',
                'firstName' => constituentRec.FirstName,
                'lastName' => constituentRec.LastName,
                'currency' => paymentGatewaySetting.ucinn_ascendv2__Currency_Code__c,
                'grandTotal' => '0.00',
                'entryMode' => 'keyed',
                'cardPresent' => 'N',
                'paymentDescriptor' => 'Ymx1ZWZpbg==',
                'accountNumber' => oppRec.ucinn_ascendv2__Card_Number__c,
                'cardType' => creditCardTypeMap.get(oppRec.ucinn_ascendv2__Payment_Type__c.toLowerCase()),
                'expirationMonth' => oppRec.ucinn_ascendv2__Card_Expiration_Date__c.substring(0,2),
                'expirationYear' => '20' + oppRec.ucinn_ascendv2__Card_Expiration_Date__c.substring(2,4),
                'cardsecuritycode' => oppRec.ucinn_ascendv2__CCV__c,
                'authService' => 'true',
                'paySubscriptionCreateService' => 'true',
                'subscriptionID' => oppRec.ucinn_ascendv2__Subscription_ID__c,
                'disableAutoAuth' => 'false',
                'recurringAmount' => String.valueOf(oppRec.Amount),
                'recurringStartDate' => correctDate(oppRec.ucinn_ascendv2__Start_Date__c),
                'frequency' => correctFrequency(oppRec.ucinn_ascendv2__Frequency__c),
                'commerceIndicator' => 'recurring',
                'paymentMethod' => 'credit card',
                'namedCredentialName' => paymentGatewaySetting.ucinn_ascendv2__Gateway_Named_Credential_Name__c
            };
        }
    }

    /*******************************************************************************
	* @author       Charlie Park - UC Innovation
	* @date         10/9/2019 
	* @description  
	********************************************************************************/
    global override void constructRequestToPaymentGateway() {
        final String bodyId = 'TheBody';
        
        // If encrypted payment info is there, that means it's from regular gift processing. 
        if (!String.isEmpty(getVar('paymentData'))) {
            ucinn_ascendv2.ascend_GIFT_ExternalPaymentCyberSource.requestBody =
                        '<soapenv:Body xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" wsu:Id="' + bodyId + '">' +
                            '<requestMessage xmlns="urn:schemas-cybersource-com:transaction-data-' + getVar('wsdlVersion') + '">' +
                                '<merchantID>' + getVar('merchantID') + '</merchantID>' +
                                '<merchantReferenceCode>' + getVar('merchantReferenceCode') + '</merchantReferenceCode>' +
                                '<billTo>' +
                                    '<firstName>' + getVar('firstName') + '</firstName>' +
                                    '<lastName>' + getVar('lastName') + '</lastName>' +
                                    '<street1>' + getVar('street') + '</street1>' +
                                    '<city>' + getVar('city') + '</city>' +
                                    '<state>' + getVar('state') + '</state>' +
                                    '<postalCode>' + getVar('postalCode') + '</postalCode>' +
                                    '<country>' + getVar('country') + '</country>' +
                                    '<phoneNumber>' + getVar('phoneNumber') + '</phoneNumber>' +
                                    '<email>' + getVar('email') + '</email>' +
                                '</billTo>' +
                                '<purchaseTotals>' +
                                    '<currency>' + getVar('currency') + '</currency>' +
                                    processFieldsForNonZeroDollarAuth(zeroDollarAuthEnabled,
                                    '<grandTotalAmount>' + getVar('grandTotal') + '</grandTotalAmount>') +
                                '</purchaseTotals>' +
                                '<pos>' +
                                    '<entryMode>' + getVar('entryMode') + '</entryMode>' +
                                    '<cardPresent>' + getVar('cardPresent') + '</cardPresent>' +
                                    '<terminalCapability>' + getVar('terminalCapability') + '</terminalCapability>' +
                                '</pos>' +
                                '<encryptedPayment>' +
                                    '<descriptor>' + getVar('paymentDescriptor') + '</descriptor>' +
                                    '<data>' + getVar('paymentData') + '</data>' +
                                '</encryptedPayment>' +
                                '<subscription>' +
                                    '<paymentMethod>' + getVar('paymentMethod') + '</paymentMethod>' +
                                '</subscription>' +
                                '<recurringSubscriptionInfo>' +
                                    '<amount>' + getVar('recurringAmount') + '</amount>' +
                                    '<frequency>' + getVar('frequency') + '</frequency>' +
                                    '<startDate>' + getVar('recurringStartDate') + '</startDate>' +
                                '</recurringSubscriptionInfo>' +
                                processFieldsForNonZeroDollarAuth(zeroDollarAuthEnabled,
                                '<ccAuthService run="' + getVar('authService') + '">' +
                                    '<commerceIndicator>' + getVar('commerceIndicator') + '</commerceIndicator>' +
                                '</ccAuthService>') +
                                '<paySubscriptionCreateService run="' + getVar('paySubscriptionCreateService') + '">' +
                                    '<disableAutoAuth>' + getVar('disableAutoAuth') + '</disableAutoAuth>' +
                                '</paySubscriptionCreateService>' +
                            '</requestMessage>' +
                        '</soapenv:Body>';
        }
        else {
            ucinn_ascendv2.ascend_GIFT_ExternalPaymentCyberSource.requestBody =
                        '<soapenv:Body xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" wsu:Id="' + bodyId + '">' +
                            '<requestMessage xmlns="urn:schemas-cybersource-com:transaction-data-' + getVar('wsdlVersion') + '">' +
                                '<merchantID>' + getVar('merchantID') + '</merchantID>' +
                                '<merchantReferenceCode>' + getVar('merchantReferenceCode') + '</merchantReferenceCode>' +
                                '<billTo>' +
                                    '<firstName>' + getVar('firstName') + '</firstName>' +
                                    '<lastName>' + getVar('lastName') + '</lastName>' +
                                    '<street1>' + getVar('street') + '</street1>' +
                                    '<city>' + getVar('city') + '</city>' +
                                    '<state>' + getVar('state') + '</state>' +
                                    '<postalCode>' + getVar('postalCode') + '</postalCode>' +
                                    '<country>' + getVar('country') + '</country>' +
                                    '<phoneNumber>' + getVar('phoneNumber') + '</phoneNumber>' +
                                    '<email>' + getVar('email') + '</email>' +
                                '</billTo>' +
                                '<purchaseTotals>' +
                                    '<currency>' + getVar('currency') + '</currency>' +
                                    processFieldsForNonZeroDollarAuth(zeroDollarAuthEnabled,
                                    '<grandTotalAmount>' + getVar('grandTotal') + '</grandTotalAmount>') +
                                '</purchaseTotals>' +
                                '<pos>' +
                                    '<entryMode>' + getVar('entryMode') + '</entryMode>' +
                                    '<cardPresent>' + getVar('cardPresent') + '</cardPresent>' +
                                    '<terminalCapability>' + getVar('terminalCapability') + '</terminalCapability>' +
                                '</pos>' +
                                '<card>' +
                                    '<accountNumber>' + getVar('accountNumber') + '</accountNumber>' +
                                    '<expirationMonth>' + getVar('expirationMonth') + '</expirationMonth>' +
                                    '<expirationYear>' + getVar('expirationYear') + '</expirationYear>' +
                                    '<cvNumber>' + getVar('cardsecuritycode') + '</cvNumber>' +
                                    '<cardType>' + getVar('cardType') + '</cardType>' +
                                '</card>' +
                                '<subscription>' +
                                    '<paymentMethod>' + getVar('paymentMethod') + '</paymentMethod>' +
                                '</subscription>' +
                                '<recurringSubscriptionInfo>' +
                                    '<amount>' + getVar('recurringAmount') + '</amount>' +
                                    '<frequency>' + getVar('frequency') + '</frequency>' +
                                    '<startDate>' + getVar('recurringStartDate') + '</startDate>' +
                                '</recurringSubscriptionInfo>' +
                                processFieldsForNonZeroDollarAuth(zeroDollarAuthEnabled,
                                '<ccAuthService run="' + getVar('authService') + '">' +
                                    '<commerceIndicator>' + getVar('commerceIndicator') + '</commerceIndicator>' +
                                '</ccAuthService>') +
                                '<paySubscriptionCreateService run="' + getVar('paySubscriptionCreateService') + '">' +
                                    '<disableAutoAuth>' + getVar('disableAutoAuth') + '</disableAutoAuth>' +
                                '</paySubscriptionCreateService>' +
                            '</requestMessage>' +
                        '</soapenv:Body>';
        }

        
    }
}