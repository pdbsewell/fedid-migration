/* @author Sulung Chandra, UC Innovation
 * @date 10/9/2019
 * @group PORTAL_UCIN
 * @group-content 
 * @description Handles gift creation using ascend
 * 2020-10-15   Ken McGuire cleaned createPortalAnonymousUserGiftTransaction of unused parameters and ability to consume externalPaymentGatewayId.
 * 2021-11-01   Chaldrin Cruz   Replaced refereces to review transaction with review transaction v2
 * 2022-03-01   Chaldrin Cruz   Commented code for logged in users to prevent rtv2 from posting.  Create interim for all donors.
 * 2022-10-13   Inderpal Dhan   Mapped the payment Id on the Review Transaction record.
 * 2022-10-13   Inderpal Dhan   Mapped the Designation Name on the Review Transaction record PENGAGE-2575
 * 2023-13-02   APRivera        Added Address mapping on Review Transaction; Cleanup of commented lines
 */
public without sharing class PORTAL_UCIN_GiftCreation {
    ucinn_ascendv2.ascend_GIFT_GiftCreation ascendDefaultClass = new ucinn_ascendv2.ascend_GIFT_GiftCreation();



    /**
    * Create a review transaction record for a successful payment
    *                   
    * @return: Aura (JSON)                   a mapped object containing the review transaction id, success or failure messages.                    
    * @param: objects                        form parameters passed into controller method.
    */
    public Object createPortalAnonymousUserGiftTransaction(Map<String, Object> params, Map<String, Object> devParams) {
        Map<String, Object> result = new Map<String, Object>();

        Boolean isAnonymousUser = (Boolean) params.get('isAnonymousUser');
        String creditCardNumber = (String) params.get('creditCardNumber');
        String creditCardType = (String) params.get('creditCardType');
        String creditCardExpirationDate = (String) params.get('creditCardExpirationDate');
        String paymentChargeId = (String) params.get('paymentChargeId');
        Contact constituentRec = (Contact) params.get('constituentRec');
        Account organizationRec = (Account) params.get('organizationRec');
        Opportunity giftRec = (Opportunity) params.get('giftRec');
        List<ucinn_ascendv2__Designation_Detail__c> ascendDesignationDetailRecList = (List<ucinn_ascendv2__Designation_Detail__c>) params.get('designationDetailRecList');
        Boolean isOtherDesignation = (Boolean) params.get('isOtherDesignation');
        String defaultDesignation = (String) params.get('defaultDesignation');
        String defaultAppeal = (String) params.get('defaultAppeal');
        String selectedDesignation = (String) params.get('designationName');
        String externalPaymentGatewayID = (String)params.get('externalPaymentGatewayId');
        String subscriptionID = (String)params.get('subscriptionId');

        ucinn_ascendv2__Review_Transaction_v2__c reviewTransactionRec = new ucinn_ascendv2__Review_Transaction_v2__c();
        try {
                reviewTransactionRec.Salutation__c = (String)params.get('contact_salutation');
                reviewTransactionRec.Designation_Name__c = (String)params.get('s_designationName');
                reviewTransactionRec.ucinn_ascendv2__First_Name__c = (String)params.get('contact_firstname');
                reviewTransactionRec.ucinn_ascendv2__Last_Name__c = (String)params.get('contact_lastname');
                reviewTransactionRec.ucinn_ascendv2__Phone_1__c = (String)params.get('contact_phone');
                if (String.isNotBlank(ReviewTransactionRec.ucinn_ascendv2__Phone_1__c)) {
                    reviewTransactionRec.ucinn_ascendv2__Phone_1_Type__c = 'Mobile';
                    reviewTransactionRec.Phone_1_Is_Active__c = true;
                }
                reviewTransactionRec.ucinn_ascendv2__Email_1__c = (String)params.get('contact_email');
                if (String.isNotBlank(ReviewTransactionRec.ucinn_ascendv2__Email_1__c)) {
                    reviewTransactionRec.ucinn_ascendv2__Email_1_Type__c = 'Private';
                    reviewTransactionRec.Email_1_Is_Active__c = true;
                }
				if(params.containsKey('transactionRequestId') && String.isNotBlank((String) params.get('transactionRequestId'))){
                    reviewTransactionRec.ucinn_ascendv2__Transaction_ID__c = (String) params.get('transactionRequestId');
                }
                reviewTransactionRec.ucinn_ascendv2__Address_1_Line_1__c = (String)params.get('contact_address1');
                reviewTransactionRec.ucinn_ascendv2__City_1__c = (String)params.get('contact_city');
                reviewTransactionRec.ucinn_ascendv2__State_1__c = (String)params.get('contact_state');
                reviewTransactionRec.ucinn_ascendv2__Postal_Code_1__c = (String)params.get('contact_postalcode');
                reviewTransactionRec.ucinn_ascendv2__Country_1__c = (String)params.get('contact_country');
                reviewTransactionRec.Address_1_Date_From__c = system.today();
                if (String.isNotBlank(ReviewTransactionRec.ucinn_ascendv2__Address_1_Line_1__c)) {
                    reviewTransactionRec.ucinn_ascendv2__Address_1_Type__c = 'Mailing';
                    reviewTransactionRec.Address_1_Is_Active__c = true;
                }
                // Experian Address field mapping
                reviewTransactionRec.DPID__c = (String)params.get('address_dpid');
                reviewTransactionRec.Address_Verification_Status__c = (String)params.get('address_verification');
                reviewTransactionRec.Email_Verification_Status__c = (String)params.get('email_verification');
                reviewTransactionRec.Phone_Verification_Status__c = (String)params.get('phone_verification');
                reviewTransactionRec.Address_Verification_Source__c = 'Contact supplied';
                reviewTransactionRec.Email_Verification_Source__c = 'Contact supplied';
                reviewTransactionRec.Phone_Verification_Source__c = 'Contact supplied';

            RecordType transactionRecordType_online = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'ucinn_ascendv2__Review_Transaction_v2__c' and DeveloperName = 'Online_Donation_Transaction'];
            reviewTransactionRec.RecordTypeId = transactionRecordType_online.Id;
            reviewTransactionRec.ucinn_ascendv2__Payment_Amount_1_1__c = giftRec.Amount;
            reviewTransactionRec.ucinn_ascendv2__Payment_Date_1_1__c = giftRec.ucinn_ascendv2__Credit_Date__c;
            reviewTransactionRec.ucinn_ascendv2__Is_Anonymous__c = giftRec.ucinn_ascendv2__Is_Anonymous__c;
            reviewTransactionRec.Gift_Comments__c = giftRec.ucinn_ascendv2__Notes__c;
            reviewTransactionRec.Learn_About_Will__c = giftRec.Learn_About_Will__c;
            reviewTransactionRec.Gifted_in_Will__c = giftRec.Gifted_in_Will__c;
            reviewTransactionRec.Source__c = 'Online Donation';//'Contact Supplied';
            reviewTransactionRec.ucinn_ascendv2__Transaction_Date__c = giftRec.ucinn_ascendv2__Credit_Date__c;
            if(isOtherDesignation == true) {
                reviewTransactionRec.ucinn_ascendv2__Description__c = selectedDesignation;
                reviewTransactionRec.ucinn_ascendv2__Designation_External_ID_1__c = defaultDesignation;
            } else {
                reviewTransactionRec.ucinn_ascendv2__Designation_External_ID_1__c = selectedDesignation;
            }
            if(giftRec.Type == 'Outright') {
                reviewTransactionRec.ucinn_ascendv2__Transaction_Type__c = 'Gift';
                reviewTransactionRec.ucinn_ascendv2__Opportunity_Type__c = 'Outright';
                reviewTransactionRec.ucinn_ascendv2__Installment_Frequency_1__c = 'Irregular';
            } else {
                reviewTransactionRec.ucinn_ascendv2__Transaction_Type__c = 'Recurring Gift';
                reviewTransactionRec.ucinn_ascendv2__Opportunity_Type__c = 'Recurring';
                reviewTransactionRec.ucinn_ascendv2__Installment_Frequency_1__c = 'Monthly';
                reviewTransactionRec.ucinn_ascendv2__Installment_Amount_1_1__c = giftRec.Amount;
            }
            Datetime currentT = Datetime.now();
            String currentTime = currentT.formatGmt('MMddyy-kkmmssSSS');
            reviewTransactionRec.ucinn_ascendv2__External_System_ID__c = externalPaymentGatewayID;
            reviewTransactionRec.ucinn_ascendv2__External_Payment_Gateway_ID__c = externalPaymentGatewayID;
            reviewTransactionRec.ucinn_ascendv2__Tender_Type_1__c  = creditCardType;
            reviewTransactionRec.ucinn_ascendv2__Campaign_External_ID__c = defaultAppeal;
            reviewTransactionRec.ucinn_ascendv2__Subscription_ID__c = subscriptionID;
            //appeal code default?
            
            insert reviewTransactionRec;
    
            // For now, use ascend review transaction. And limit the designation to only 1.
            String returnSuccessMessage = 'Thank you for your donation.';
            result.put('successMessage', returnSuccessMessage);
            result.put('giftRec', reviewTransactionRec);
            result.put('giftReceiptId', reviewTransactionRec.Id);
        } catch (exception ex) {
            result.put('message',ex.getMessage() +'---'+ ex.getStackTraceString());
        }

        return result;
    }
    
    /**
    * Create Interim record
    *                   
    * @return: Interim Id                    The Interim Record Id                    
    * @param: objects                        Map of <String, Object>
    */
    public Id createInterim(Map<String, Object> params) {
        ucinn_ascendv2__Interim__c interimRec = new ucinn_ascendv2__Interim__c();
        RecordType onlineDonationRT = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'ucinn_ascendv2__Interim__c' and DeveloperName = 'Online_Donation_Interface'];
        interimRec.RecordTypeId = onlineDonationRT.Id;
        if ((String)params.get('contact_salutation') != null) {
            interimRec.ucinn_ascendv2__Salutation__c = (String)params.get('contact_salutation');
        }
        if ((String)params.get('contact_firstname') != null) {
            interimRec.ucinn_ascendv2__First_Name__c = (String)params.get('contact_firstname');
        }
        if ((String)params.get('contact_lastname') != null) {
            interimRec.ucinn_ascendv2__Last_Name__c = (String)params.get('contact_lastname');
        }
        if ((String)params.get('contact_phone') != null) {
            interimRec.ucinn_ascendv2__Phone_1__c = (String)params.get('contact_phone');
        }
        if ((String)params.get('contact_email') != null) {
            interimRec.ucinn_ascendv2__Email_1__c = (String)params.get('contact_email');
        }
        if ((String)params.get('contact_address1') != null) {
            interimRec.ucinn_ascendv2__Address_1_Line_1__c = (String)params.get('contact_address1');            
        }
        if ((String)params.get('contact_city') != null) {
            interimRec.ucinn_ascendv2__City_1__c = (String)params.get('contact_city');
        }
        if ((String)params.get('contact_state') != null) {
            interimRec.ucinn_ascendv2__State_1__c = (String)params.get('contact_state');
        }
        if ((String)params.get('contact_postalcode') != null) {
            interimRec.ucinn_ascendv2__Postal_Code_1__c = (String)params.get('contact_postalcode');
        }
        if ((String)params.get('contact_country') != null) {
            interimRec.ucinn_ascendv2__Country_1__c = (String)params.get('contact_country');            
        }

        // Hardcode classifications and source. Set to Manual Review to make sure it is reviewed before auto processing.
        interimRec.ucinn_ascendv2__Email_1_Type__c = 'Private';
        interimRec.ucinn_ascendv2__Phone_1_Type__c = 'Other';
        interimRec.ucinn_ascendv2__Address_1_Type__c = 'Mailing';
        interimRec.Address_1_Date_From__c = system.today();
        interimRec.ucinn_ascendv2__Source_File__c = 'Contact Supplied';
        interimRec.ucinn_ascendv2__Status__c = 'Manual Review';
        insert interimRec;
        
        return interimRec.Id;
    }
}