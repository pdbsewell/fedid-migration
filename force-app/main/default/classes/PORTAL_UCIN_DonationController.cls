/**
 * @author Sulung Chandra, UC Innovation
 * @date 9/9/2019
 * @group PORTAL_UCIN
 * @group-content 
 * @description Controller for PORTAL_UCIN Donation components
 *  * Modifications Log 
 * Date         Author          Modification
 * 2020-10-15   Ken McGuire   	Moved processing methods off of client and onto server
 * 2021-11-01   Chaldrin Cruz   Replaced refereces to review transaction with review transaction v2
 * 2022-03-01   Chaldrin Cruz   Retrive custom metadata record using getInstance() function instead of using SOQL
 * 2022-07-14   Inderpal Dhan   Email template Fix PENGAGE-2434
 * 2022-07-27   Inderpal Dhan   Captcha Fix PENGAGE-2442
 * 2022-08-02 	Inderpal Dhan	Captcha Fix PENGAGE-2453
 * 2022-08-05 	Inderpal Dhan	Captcha Fix PENGAGE-2470
 * 2022-08-16 	Inderpal Dhan	Captcha Fix PENGAGE-2479
 * 2022-09-21 	Inderpal Dhan	IP enhancement PENGAGE-2499
 * 2022-10-05 	Inderpal Dhan	IP enhancement PENGAGE-2521
 * 2022-10-17 	Inderpal Dhan	Capture Request Id for Outright gifts PENGAGE-2530
 * 2022-10-24 	Inderpal Dhan	IP enhancement PENGAGE-2543
 * 2022-11-18 	Inderpal Dhan	Designation Label capture PENGAGE-2575
 * 2025-06-17   Matthew Maramot Fixing gift receipt for logged in user (EPCP-4946)
 * 2025-07-16   Matthew Maramot Ascend Package Upgrade 5.48.7 EPCP-4869
 */
public without sharing class PORTAL_UCIN_DonationController {
    
    private static final string TRANSACTION_TYPE_SUBSCRIPTION_CREATION = 'On-Demand Subscription Creation';
    private static final string GIFT_TYPE_OUTRIGHT = 'Outright';
 	private static final string REASON_CODE_SUCCESS = '100';
    private static final string ERROR_PROCESSING_REQUEST = 'An unexpected donation processing error occured.';
    private static final string ERROR_INVALID_TRANSACTION = 'Invalid Transaction';
    private static final string ERROR_INVALID_PAYMENT_GATEWAY = 'Invalid Payment Gateway';
    public static final string TYPE_REVIEW_TRANSACTION = 'ucinn_ascendv2__Review_Transaction_v2__c';
    public static final integer FAUX_DELAY = 1000;
    public static Boolean throwExceptionForTesting = false;
    public static Boolean ipLimitExceeded = false;
    public static String transactionRequestId;
    public static Object s_designationName;
    public static PORTAL_UCIN_GiftCreation giftCreationHandler = new PORTAL_UCIN_GiftCreation();
    
      
    /**
    * Retrieve selectable designations by using supplied Ids
    * @return: Designations                      List of selectable Designations                    
    * @param: designationIdsCommaSeparated       Designation Ids separated by Comma 
    */
    @AuraEnabled
    public static List<ucinn_ascendv2__Designation__c> getSelectableDesignations(String designationIdsCommaSeparated) {
        List<ucinn_ascendv2__Designation__c> designationList = new List<ucinn_ascendv2__Designation__c>();
        Map<String, ucinn_ascendv2__Designation__c> designationMap = new Map<String, ucinn_ascendv2__Designation__c>();
        String[] designationIds = (designationIdsCommaSeparated+'').split(',');
        for (ucinn_ascendv2__Designation__c dsg : [Select Id, Name, ucinn_ascendv2__Designation_Name__c, ucinn_ascendv2__External_System_ID__c
                From ucinn_ascendv2__Designation__c Where ucinn_ascendv2__Status_Formula__c='Active' And ucinn_ascendv2__External_System_ID__c In :designationIds]) {
            designationMap.put(dsg.ucinn_ascendv2__External_System_ID__c, dsg);
        }
        for (String s : designationIds) {
            if (designationMap.containsKey(s)) {
                designationList.add(designationMap.get(s));
            }
        }
        return designationList;
    }

    /**
    * Retrieve current user, constituent record, and organization record
    * @return: currentUser, constituentRec, organizationRec    Map of <String, Object>                      
    */
    @AuraEnabled
    public static Object getDonorByLoggedInUser() {
        Map<String, Object> result = new Map<String, Object>();
        Id currentUserId = UserInfo.getUserId();
        User currentUser;

        try {
            if (Test.isRunningTest() && throwExceptionForTesting == true) {
                throw new AuraHandledException('Testing Error');
            }
            
            currentUser = [SELECT Id, Name, ContactId, AccountId, Recommend_Type_1__c, Recommend_Type_2__c, Recommend_Type_3__c FROM User WHERE Id =: currentUserId];
            result.put('currentUser', currentUser);
            
            if (currentUser.ContactId != null) {
                Contact contactRec = [SELECT Id, Name, AccountId, FirstName, LastName, Email, Phone, Salutation, ucinn_ascendv2__Preferred_Address_Line_1__c,
                                    ucinn_ascendv2__Preferred_Address_Line_2__c, ucinn_ascendv2__Preferred_Address_City__c, ucinn_ascendv2__Preferred_Address_State__c,
                                    ucinn_ascendv2__Preferred_Address_Postal_Code__c, ucinn_ascendv2__Preferred_Address_Country__c, ucinn_ascendv2__Subscription_ID__c,
                                    Phone_Verification_Status__c, Email_Verification_Status__c, ucinn_ascendv2__Preferred_Address_Formula__c,
                                    (SELECT Id, Name, Is_Active__c, Is_Primary__c, Classification__c, Verification_Status__c
                                        FROM Emails__r WHERE Is_Active__c = TRUE AND Is_Primary__c = TRUE ORDER BY LastModifiedDate DESC LIMIT 1),
                                    (SELECT Id, Name, Is_Active__c, Is_Primary__c, Type__c, Classification__c,Verification_Status__c,ISO_Country__c
                                        FROM Phones__r WHERE Is_Active__c = TRUE AND Is_Primary__c = TRUE ORDER BY LastModifiedDate DESC LIMIT 1),
                                    (SELECT Id, Name, Address__c, Is_Active__c, Is_Primary__c, Country2__c, Street_Name__c, Type__c, Post_Code__c, DPID__c, Verification_Status__c,
                                        City__c, State__c, Classification__c FROM Addresses__r WHERE Is_Primary__c = TRUE  AND Is_Active__c = TRUE ORDER BY LastModifiedDate DESC LIMIT 1)
                                    FROM Contact WHERE Id =: currentUser.ContactId LIMIT 1];
                
                result.put('constituentRec', contactRec);
                
                if (contactRec.AccountId != null) {
                    List<Account> accountList = [SELECT Id FROM Account WHERE Id = :contactRec.AccountId LIMIT 1];
                    if (!accountList.isEmpty()) {
                        result.put('organizationRec', accountList[0]);
                    }
                }
            }
            return result;
        }
        catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
    * Get Base Url
    * @return: url                          Base Url
    */
    @AuraEnabled
    public static String getBaseUrl() {
        return PORTAL_UCIN_Utils.getBaseURL();
    }

    /**
    * Get list of Country options
    * @return Countries
    */
    @AuraEnabled
    public static List<SelectOptionDetail> getCountryOptions()
    {
        List<SelectOptionDetail> mylist = new List<SelectOptionDetail>();
        Schema.DescribeFieldResult fr = Address__c.Country2__c.getDescribe();
        List<Schema.PicklistEntry> pleList = fr.getPicklistValues();
        for(Schema.PicklistEntry ple : pleList) {
            mylist.add(new SelectOptionDetail(ple.getLabel(), ple.getValue()));
        }
        return mylist;
    }

    /**
    * Get list of Salutations options
    * @return Salutations
    */
    @AuraEnabled
    public static List<SelectOptionDetail> getSalutationsOptions()
    {
        List<SelectOptionDetail> mylist = new List<SelectOptionDetail>();
        Schema.DescribeFieldResult fr = Contact.Salutation_ERDA__c.getDescribe();
        List<Schema.PicklistEntry> pleList = fr.getPicklistValues();   
        for(Schema.PicklistEntry ple : pleList) {
            mylist.add(new SelectOptionDetail(ple.getLabel(), ple.getValue()));
        }
        return mylist;
    }

    /**
    * Get list of error message metadata options
    */
    @AuraEnabled
    public static Map<String, String> getErrorMessages()
    {
        List<PORTAL_UCIN_Donation_Error__mdt> errorList = PORTAL_UCIN_Donation_Error__mdt.getAll().values();
        Map <String, String> errorMessageMap = new Map<String, String>();
        for(PORTAL_UCIN_Donation_Error__mdt donationError : errorList) {
            errorMessageMap.put(donationError.MasterLabel, donationError.Error_Message__c);
        }
        return errorMessageMap;
    }
    
    /**
    * Create a subscription transaction record for processing outright gift donations. 
    * @return: Aura JSON type result             stateful subscription reference ids               
    * @param: donationFormParams      			 Client form data
    */
    @AuraEnabled
    public static  Map<String, Object> createTransaction(Map<String, Object> donationFormParams)
    {
		// Method is invoked only for Outright gifts, first createTransaction is fired and then processPayment is called, 
		// params should have a Captcha token, Captcha token is to be verified, after that an encrypted String is created and sent back to Client
		// Encrypted string is to be verified in Outright gift processPayment call 
        Map<String, Object> devParams;
        PORTAL_UCIN_Utils.onelineDonationParseParams(donationFormParams, devParams);
        try {
            if(!IPCheckExceedsLimit(donationFormParams)){
                String captchaResponseKey = String.valueOf(donationFormParams.get('captchaResponseKey'));
                String captchaBypassToken = String.valueOf(donationFormParams.get('captchaBypassToken'));
                if(String.isNotBlank(captchaBypassToken)){
                    captchaResponseKey = captchaBypassToken;
                }
                if(ReCaptchaService.validateCaptchaToken(captchaResponseKey)){
                    donationFormParams.remove('captchaResponseKey');
                    donationFormParams.remove('captchaBypassToken');  
                    Map<String, Object> result = createSubscription(donationFormParams);
                    String sAllComp = String.valueof(result.get('transactionId')) + '&&' + String.valueof(donationFormParams.get('contact_firstname')) + '&&' + String.valueOf(System.now());
                    String encryptedKey = generateEcnryptedString(sAllComp); 
                    result.put('encryptedKey', encryptedKey);
                    return result;
                }else{
                    throw new AuraHandledException(ERROR_PROCESSING_REQUEST);
                }
            }else{
                ipLimitExceeded = true;
                throw new AuraHandledException(ERROR_PROCESSING_REQUEST);
            }                       
        }catch (Exception ex) {
			if(ipLimitExceeded) ex.setMessage('IP rate limit exceeded for firstname ' + String.valueOf(donationFormParams.get('contact_firstname')) + ', lastname ' + String.valueof(donationFormParams.get('contact_lastname')) + ', Email address ' + String.valueof(donationFormParams.get('contact_email')));
            LogUtilityException.logException(ex);
            String errorMessage = ipLimitExceeded ? String.valueOf(Label.Ascend_Processing_Error) : ERROR_PROCESSING_REQUEST;
            throw new AuraHandledException(errorMessage);
        }
    }
    /**
    * Processes a donation payment. 
    * @return: Aura JSON type result             giftId used by client for google analytics               
    * @param: donationFormParams      			 Client form data
    */
    @AuraEnabled
    public static Map<String, Object> processPayment(Map<String, Object> donationFormParams) {
        Map<String, Object> devParams;
		Map<String, Object> resultParams;
        String netId = network.getNetworkId();
        PORTAL_UCIN_Utils.onelineDonationParseParams(donationFormParams, devParams);
		// for Recurring Gifts only processPayment is invoked and for Outright gifts processPayment is a invoked after createTransaction
		// for Recurring Gifts we need to validate the Captcha token
		// for Outright gifts control flows to the else section and validates the Encrypted String generated in createTransaction method
		// On Validating the Encrypted String, Transaction Data record generated createTransaction method is flagged so that same subscription cannot be reused  
        try {
            s_designationName = donationFormParams.get('designationLabel');
            if(donationFormParams.containsKey('captchaResponseKey') || donationFormParams.containsKey('captchaBypassToken')){
				// Control flows here for Recurring gifts
                String captchaResponseKey = String.valueOf(donationFormParams.get('captchaResponseKey')); 
                String captchaBypassToken = String.valueOf(donationFormParams.get('captchaBypassToken'));
                // Validate for IP check
                if(!IPCheckExceedsLimit(donationFormParams)){
                    if(String.isNotBlank(captchaBypassToken)){
                        captchaResponseKey = captchaBypassToken;
                    }
                    if(ReCaptchaService.validateCaptchaToken(captchaResponseKey)){
                        donationFormParams.remove('captchaResponseKey');donationFormParams.remove('captchaBypassToken');
                        Opportunity giftRec = (Opportunity) donationFormParams.get('giftRec');
                        if(giftRec.Type == GIFT_TYPE_OUTRIGHT){
                            resultParams = processOutrightPayment(donationFormParams);
                            updateTransaction(String.valueOf(donationFormParams.get('transactionId')));
                        }else{
                            resultParams = createCharge(donationFormParams);
                        }
                        // Transaction successfull, reset IP check Limit
                        // Check if Donation is successfull
                        if((!resultParams.containsKey('message') && resultParams.containsKey('successMessage')) || Test.isRunningTest() ){
                            resetRateLimit(donationFormParams);

                            if(!Test.isRunningTest()){
                                // Determine receipt url and send gift receipt
                                String receiptURL = Portal_UCIN_Utils.getReviewTransactionReceiptURL((Id)resultParams.get('giftReceiptId')); 
                                createGiftReceipt((Id)resultParams.get('giftReceiptId'), (String)resultParams.get('paymentGroupId'), (String)donationFormParams.get('contact_email'), receiptURL, netId);
                            }
                        }
                        return resultParams;
                    }else{
                        throw new AuraHandledException(ERROR_PROCESSING_REQUEST);
                    }
                }else{
                    ipLimitExceeded = true;
                    throw new AuraHandledException(ERROR_PROCESSING_REQUEST);  
                }                 
            }else if(donationFormParams.containsKey('encryptedKey') && validateDecryptedString(donationFormParams)){
				// COntrol flows here for OUTRIGHT gifts
                Opportunity giftRec = (Opportunity) donationFormParams.get('giftRec');
                if(giftRec.Type == GIFT_TYPE_OUTRIGHT){
                    resultParams = processOutrightPayment(donationFormParams);
					// Transaction Data record created is flagged so that this record cannot be used for future fradulent donations 
					updateTransaction(String.valueOf(donationFormParams.get('transactionId')));
                }else{
                    resultParams = createCharge(donationFormParams);
                }
                // Transaction successfull, reset IP check Limit
                // Check if Donation is successfull
                if((!resultParams.containsKey('message') && resultParams.containsKey('successMessage')) || Test.isRunningTest()){
                    resetRateLimit(donationFormParams);

                    if(!Test.isRunningTest()){
                        // Determine receipt url and send gift receipt
                        String receiptURL = Portal_UCIN_Utils.getReviewTransactionReceiptURL((Id)resultParams.get('giftReceiptId')); 
                        createGiftReceipt((Id)resultParams.get('giftReceiptId'), (String)resultParams.get('paymentGroupId'), (String)donationFormParams.get('contact_email'), receiptURL, netId);
                    }
                }                
                return resultParams;
            }
            throw new AuraHandledException(ERROR_PROCESSING_REQUEST);          
        }
		catch (Exception ex) {
			if(ipLimitExceeded) ex.setMessage('IP rate limit exceeded for firstname ' + String.valueOf(donationFormParams.get('contact_firstname')) + ', lastname ' + String.valueof(donationFormParams.get('contact_lastname')) + ', Email address ' + String.valueof(donationFormParams.get('contact_email')));
            LogUtilityException.logException(ex);
            String errorMessage = ipLimitExceeded ? String.valueOf(Label.Ascend_Processing_Error) : ERROR_PROCESSING_REQUEST;
            throw new AuraHandledException(errorMessage); 
        }
    }

    /**
    * IPCheckExceedsLimit : check IP limit. 
    * @param: Map                               Key value pair of Donation params   
    */
    private static Boolean IPCheckExceedsLimit(Map<String, Object> donationFormParams){
        IP_RateLimitUtility rateLimit = generateKeyAndObject(donationFormParams);
        return rateLimit.exceedsRateLimit();
    }

    /**
    * resetRateLimit : Reset the rate limit. 
    * @param: Map                               Key value pair of Donation params  
    */
    private static void resetRateLimit(Map<String, Object> donationFormParams){
        IP_RateLimitUtility rateLimit = generateKeyAndObject(donationFormParams);        
        rateLimit.resetRateLimit();
    }

    /**
    * generateKey : generate the Key based on Custom MetaData. 
    * @param: Map                               Key value pair of Donation params   
    */
    private static IP_RateLimitUtility generateKeyAndObject(Map<String, Object> donationFormParams){
        String key = donationFormParams.containsKey('rateLimitKey') ? String.valueOf(donationFormParams.get('rateLimitKey')) : '';
        IP_RateLimitUtility rateLimit;
        if(String.isBlank(key)){
            rateLimit = new IP_RateLimitUtility('Alumni Form');
        }else{
            rateLimit = new IP_RateLimitUtility('Alumni Form', key); 
        } 
        return rateLimit;
    } 
	
    /**
    * Update Transaction Data as Charged. 
    * @param: String                               Transacrtion Data Record Id   
    */
    private static void updateTransaction(String transactionId){
        List<ucinn_ascendv2__Transaction_Data__c> linkedTransaction = [Select Id, isCharged__c from ucinn_ascendv2__Transaction_Data__c WHERE Id = :Id.valueOf(transactionId)];
        linkedTransaction[0].isCharged__c = true;
        update linkedTransaction;
    }

    /**
    * Generate a Encrypted Key. 
    * @return: String                               encrypted String               
    * @param: String                 			    String form data
    */
    private static String generateEcnryptedString(String components){
        List<Environment_Settings__c> temp = [Select id, Captcha_Key__c from Environment_Settings__c LIMIT 1];
        Blob key = EncodingUtil.base64Decode(temp[0].Captcha_Key__c);
        Blob cipherText = Blob.valueOf(components);
        Blob bEncrypted = Crypto.encryptWithManagedIV('AES256', key, cipherText);
        String sEncrypted = EncodingUtil.base64Encode(bEncrypted);
        return sEncrypted;
    }

    /**
    * Generate a Decrypted String and validate it. 
    * @return:  Boolean                             Validator if the encrypted string is correct or not             
    * @param:  Map <Id, Object>                     Map of Input parameters from the Form
    */
    private static Boolean validateDecryptedString(Map<String, Object> donationFormParams){
        Blob bEncrypted = EncodingUtil.base64Decode(String.valueOf(donationFormParams.get('encryptedKey')));
        List<Environment_Settings__c> temp = [SELECT id, Captcha_Key__c FROM Environment_Settings__c LIMIT 1];
        Blob key = EncodingUtil.base64Decode(temp[0].Captcha_Key__c);
        Blob decrypted = Crypto.decryptWithManagedIV('AES256', key, bEncrypted);
        String decryptedString = EncodingUtil.base64Decode(EncodingUtil.base64Encode(decrypted)).toString();

        List<String> components = decryptedString.split('&&');
        
		// Check for the Encrypted String and check if the linked Transaction is not already charged
        String sTransactionId = String.valueOf(donationFormParams.get('transactionId'));
        List<ucinn_ascendv2__Transaction_Data__c> linkedTransaction = [Select Id, isCharged__c from ucinn_ascendv2__Transaction_Data__c WHERE Id = :Id.valueOf(sTransactionId) AND isCharged__c = false];
        if(components[0] == String.valueof(donationFormParams.get('transactionId')) && components[1] == String.valueof(donationFormParams.get('contact_firstname')) &&
            components[2] >= String.valueOf(System.now().addMinutes(-1)) && components[2] <= String.valueOf(System.now().addMinutes(1)) && !linkedTransaction.isEmpty()){
            return true;
        }else{
            return false;
        }
    }
  /**
    * Create gift receipt pdf,
    * Email the receipt pdf to the current user
    *                   
    * @param: giftId                        Gift Opportunity Id                   
    * @param: paymentGroupId                Payment Group Id
    */
    @future(callout=true)
    public static void createGiftReceipt(Id giftId, string paymentGroupId, String sendToAddress, String receiptURL, String netId) {
        if (!isReviewTransaction(giftId)) {
            randomDelay(FAUX_DELAY);return;
        }
        ucinn_ascendv2__Review_Transaction_v2__c rtRecord = getReviewTransaction(giftId);
        if (rtRecord == null) return;
        //Added fix for test classes, cannot use getContent call in test classes (performed in PORTAL_UCIN_Utils.createGiftReceiptFile)
        Id contentVersionId;
        String templateToQuery;

        if (rtRecord.ucinn_ascendv2__Transaction_Type__c == 'Gift') {
            templateToQuery = 'PORTAL_UCIN_Donation_Gift_Receipt';
            
            if(!test.isRunningTest()){
                // If it is a guest user, need to generate receipt based on the RT. If paymentGroupId is null, we know it is a review transaction.
                contentVersionId = PORTAL_UCIN_Utils.createGiftReceiptFile(giftId, paymentGroupId, receiptURL, netId);
            }
        } else if (rtRecord.ucinn_ascendv2__Transaction_Type__c == 'Recurring Gift') {
            templateToQuery = 'PORTAL_UCIN_Recurring_Donation';
        }

        //added test.IsRunningTest for test classes
		// select the right Email template based on the transaction Type
        PORTAL_UCIN_Email_Template__mdt selEmailTemp;
        for(PORTAL_UCIN_Email_Template__mdt mdtList : PORTAL_UCIN_Email_Template__mdt.getAll().values()){
            if(mdtList.DeveloperName == 'PORTAL_UCIN_Donation_Gift_Receipt' && rtRecord.ucinn_ascendv2__Transaction_Type__c == 'Gift'){
                selEmailTemp = mdtList;break;                
            }
            if(mdtList.DeveloperName == 'PORTAL_UCIN_Recurring_Donation' && rtRecord.ucinn_ascendv2__Transaction_Type__c == 'Recurring Gift'){
                selEmailTemp = mdtList;
                break;
            }
        }
        if(selEmailTemp != null){
        	sendMail(selEmailTemp, rtRecord, contentVersionId, sendToAddress);    
        }
    }
    /**
    * Outright gift donations requre two call-outs. The first one (this) creates a subscription against which the payment is made.
    * Payment validation is NOT performed in this step.
    * @return: Aura JSON type result             stateful subscription reference ids               
    * @param: donationFormParams      			 Client form data
    */
    private static  Map<String, Object>  createSubscription(Map<String, Object> donationFormParams) {
        Map<String, Object> result = new  Map<String, Object> ();
        // Setup params map to pass to cybersource
        Map<String, Object> cyberSourceParams = constructCyberSourceParams(donationFormParams);
        // add payment record to cybersource parameters
        ucinn_ascendv2__Payment__c paymentRecord = constructPaymentRecord(donationFormParams);
        cyberSourceParams.put('paymentRec', paymentRecord);
        // execute cybersource callout
        ucinn_ascendv2__Transaction_Data__c calloutTransactionRecord = cybersourceCallout(cyberSourceParams);
        // return transaction id and gatewayId
        result.put('externalPaymentGatewayId',paymentRecord.ucinn_ascendv2__External_Payment_Gateway_ID__c);
        result.put('transactionId',calloutTransactionRecord.id);
        return result;
    }

    private static boolean isReviewTransaction(id sObjectId) {
        return sObjectId.getSObjectType().getDescribe().getName() == TYPE_REVIEW_TRANSACTION;
    }
    
    /**
    * Outright gift donations requre two call-outs. This method orchestrates the second call out.
    * Payment validatino for the subscription (first call-out) and charge (second call out) are done here.
    * @return: Aura JSON type result             the gift Id              
    * @param: donationFormParams      			 Client form data
    */
    private static Map<String, Object> processOutrightPayment(Map<String, Object> donationFormParams) {
        if (!donationFormParams.containsKey('transactionId'))  throw new DonationProcessingException(ERROR_INVALID_TRANSACTION ); 
		Id transactionId = (Id)donationFormParams.get('transactionId');
        String externalPaymentGatewayID = donationFormParams.containsKey('externalPaymentGatewayId') ?  (String)donationFormParams.get('externalPaymentGatewayId') : '';
        if (String.isEmpty(externalPaymentGatewayID))  throw new DonationProcessingException(ERROR_INVALID_PAYMENT_GATEWAY); 
        ucinn_ascendv2__Transaction_Data__c transactionRecord =  getTransaction(transactionId);
        if (transactionRecord == null ) throw new DonationProcessingException(ERROR_INVALID_TRANSACTION);

        if(transactionRecord.ucinn_ascendv2__Reason_Code__c == REASON_CODE_SUCCESS) 
        {
            donationFormParams.put('subscriptionId',transactionRecord.ucinn_ascendv2__Subscription_ID__c);
        } else 
        {
        	string appealCode = (String)donationFormParams.get('defaultAppeal');
            if (!donationFormParams.containsKey('pageName')) throw new DonationProcessingException(ERROR_INVALID_TRANSACTION ); 
            string pageName = (String)donationFormParams.get('pageName');
            PORTAL_UCIN_Donation_Security__mdt securitySettings = getPageSecuritySettings(pageName,appealCode);
           if (securitySettings != null && securitySettings.IgnoreReturnCodes__c.contains(transactionRecord.ucinn_ascendv2__Reason_Code__c)) return fauxPaymentCallout(transactionId); 
           return errorMessage(getErrorCodeMessage(transactionRecord.ucinn_ascendv2__Reason_Code__c));
       	}
        return createOutrightCharge(donationFormParams);
    }    
    /**
    * creates a payment for a gift donation.
    * @return: Aura JSON type result             the gift Id              
    * @param: donationFormParams      			 Client form data
    */
    private static Map<String, Object> createCharge(Map<String, Object> donationFormParams) {
        // Setup params map to pass to cybersource
        Map<String, Object> cyberSourceParams = constructCyberSourceParams(donationFormParams);
        // add payment record to cybersource parameters
        Opportunity opportunityRecord = constructOpportunityRecord(donationFormParams);
        cyberSourceParams.put('giftRec', opportunityRecord);
        donationFormParams.put('externalPaymentGatewayId', opportunityRecord.ucinn_ascendv2__External_Payment_Gateway_ID__c);
        // execute cybersource callout
        ucinn_ascendv2__Transaction_Data__c calloutTransactionRecord = cybersourceCallout(cyberSourceParams);
        if(calloutTransactionRecord.ucinn_ascendv2__Reason_Code__c == REASON_CODE_SUCCESS) {
            donationFormParams.put('subscriptionId', calloutTransactionRecord.ucinn_ascendv2__Subscription_ID__c);
            return createNewOnlineDonation(donationFormParams);
        } 
        else {
            string pageName = (String)donationFormParams.get('pageName');
           	string appealCode = (String)donationFormParams.get('defaultAppeal');
            PORTAL_UCIN_Donation_Security__mdt securitySettings = getPageSecuritySettings(pageName,appealCode);
           	if (securitySettings != null && securitySettings.IgnoreReturnCodes__c.contains(calloutTransactionRecord.ucinn_ascendv2__Reason_Code__c)) return fauxPaymentCallout(calloutTransactionRecord.id); 
            return errorMessage(getErrorCodeMessage(calloutTransactionRecord.ucinn_ascendv2__Reason_Code__c));
        }
    }
    /**
    * creates a payment for an outright gift donation. This is the second call out associated with an outright payment process.
    * @return: Aura JSON type result             the gift Id              
    * @param: donationFormParams      			 Client form data
    */
    private static Map<String, Object> createOutrightCharge(Map<String, Object> donationFormParams) {
        // Setup params map to pass to cybersource
        Map<String, Object> cyberSourceParams = constructCyberSourceParams(donationFormParams);
        // add payment record to cybersource parameters
        if (!donationFormParams.containsKey('subscriptionId')) throw new DonationProcessingException(ERROR_INVALID_TRANSACTION ); 
        ucinn_ascendv2__Payment__c paymentRec =  constructPaymentRecord(donationFormParams);cyberSourceParams.put('paymentRec', paymentRec);
        // execute cybersource callout
        ucinn_ascendv2__Transaction_Data__c calloutTransactionRecord = cybersourceCallout(cyberSourceParams);
       
        if(calloutTransactionRecord.ucinn_ascendv2__Reason_Code__c == REASON_CODE_SUCCESS) {
            donationFormParams.put('externalPaymentGatewayId',paymentRec.ucinn_ascendv2__External_Payment_Gateway_ID__c);donationFormParams.put('transactionRequestId',transactionRequestId);return createNewOnlineDonation(donationFormParams);
        } 
        else {
             return errorMessage(getErrorCodeMessage(calloutTransactionRecord.ucinn_ascendv2__Reason_Code__c));
        }
    }
    /**
    * Makes a call-out to cybersource.
    * @return: ucinn_ascendv2__Transaction_Data__c       the transaction data record resulting from the callout            
    * @param: Map<String, Object> cyberSourceParams      data required to make the callout
    */
    private static ucinn_ascendv2__Transaction_Data__c cybersourceCallout(Map<String, Object> cyberSourceParams) {
         ucinn_ascendv2__Transaction_Data__c resultTransaction;
        // Make the callout. 
        try {
            ucinn_ascendv2.ascend_GIFT_ExternalPaymentGateway cyberSourceCalloutClass = new ucinn_ascendv2.ascend_GIFT_ExternalPaymentGateway();
            cyberSourceCalloutClass.setDefaultParams(cyberSourceParams);
            cyberSourceCalloutClass.processPaymentsPreProcess(cyberSourceParams, null);
            cyberSourceCalloutClass.processPayments(cyberSourceParams, null);

            Map<String, Object> returnMapFromAscend = (Map<String, Object>) cyberSourceCalloutClass.processPaymentsPostProcess(cyberSourceParams, null);
            if(returnMapFromAscend.containsKey('parsedReturnMap')){
                Object oParsedReturnMap = returnMapFromAscend.get('parsedReturnMap');
                Map<String, Object> deserializedReturnMap = (Map<string,Object>) JSON.deserializeUntyped(JSON.serialize(oParsedReturnMap));
                transactionRequestId = deserializedReturnMap.containsKey('requestID') ? (String)deserializedReturnMap.get('requestID') : '';
            }            
            if(returnMapFromAscend.containsKey('transactionData'))
            {
                resultTransaction = (ucinn_ascendv2__Transaction_Data__c)returnMapFromAscend.get('transactionData');
                
            }
            else
            {
                resultTransaction = new ucinn_ascendv2__Transaction_Data__c(ucinn_ascendv2__Message__c = 'No transaction returned');
                insert resultTransaction;
            }
        } catch (Exception e) {            
            // Create a transaction data record to indicate exception
            resultTransaction = new ucinn_ascendv2__Transaction_Data__c();
            resultTransaction.ucinn_ascendv2__Message__c = e.getMessage().left(255);
            resultTransaction.ucinn_ascendv2__Response__c = e.getStackTraceString();
            insert resultTransaction;

            //Nebula logger
            Nebula.Logger.error('PORTAL_UCIN_DonationController.cybersourceCallout - ', e);
            Nebula.Logger.saveLog();
        }
        return resultTransaction;
    }
    /**
    * Create online donation (gift)
    * @return: objects                      Map of <String, Object>                     
    * @param: params                        Map of <String, Object>
    */
	@testvisible
    private static Map<String, Object> createNewOnlineDonation(Map<String, Object> params) {
        Map<String, Object> devParams;
        // Make a save point when needed; in case any operation fails.
        Savepoint sp;
        if (params.get('rollbackOnException') != false) {
            sp = Database.setSavepoint();
        }

        try {
            if (Test.isRunningTest() && throwExceptionForTesting == true) {
                throw new AuraHandledException('Testing Error');
            }
            
            // Parse all records that require front/back end convertion
            PORTAL_UCIN_Utils.onelineDonationParseParams(params, devParams);
            params.put('s_designationName', s_designationName);
            Map<String, Object> returnMap = (Map<String, Object>) giftCreationHandler.createPortalAnonymousUserGiftTransaction(params, devParams);         
            linkTransactionDataToRT((ucinn_ascendv2__Review_Transaction_v2__c)returnMap.get('giftRec'));
            return returnMap;
        }
        catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage() + '                                ' + ex.getStackTraceString());
        }
    }
    /**
    * Retrieve a Transaction Record
    * @return: ucinn_ascendv2__Transaction_Data__c                  
    * @param: params	The Transaction Id to retrieve.
    */
    @testVisible
    private static ucinn_ascendv2__Transaction_Data__c getTransaction(Id transactionId) {
        List<ucinn_ascendv2__Transaction_Data__c> transactions = 
            [SELECT id,ucinn_ascendv2__Reason_Code__c,ucinn_ascendv2__Subscription_ID__c,ucinn_ascendv2__Transaction_Type__c
             FROM ucinn_ascendv2__Transaction_Data__c
             WHERE id = :transactionId];
        return transactions.size() ==0 ? null : transactions[0];
    }
    private static ucinn_ascendv2__Review_Transaction_v2__c getReviewTransaction(Id transactionId) {
        List<ucinn_ascendv2__Review_Transaction_v2__c> rtRecords = 
            [SELECT ID,
             ucinn_ascendv2__Transaction_Type__c,
             ucinn_ascendv2__Contact__c,
             ucinn_ascendv2__Contact__r.FirstName,
             ucinn_ascendv2__Contact__r.LastName,
             ucinn_ascendv2__Interim__c,
             ucinn_ascendv2__Interim__r.ucinn_ascendv2__First_Name__c,
             ucinn_ascendv2__Interim__r.ucinn_ascendv2__Last_Name__c
             FROM ucinn_ascendv2__Review_Transaction_v2__c 
             WHERE ID =: transactionId LIMIT 1];
        if (rtRecords.size() ==0) return null;
        return rtRecords[0];
    }
    
    
    /**
    * Create an ID to use as a transaction gateway Id.
    * @return: timestamp based UID                 
    */
    private static string constructPraxId() {
        Datetime currentT = Datetime.now();
        String currentTime = currentT.formatGmt('MMddyy-kkmmssSSS');
        return 'PRAX-' + currentTime;
    }
    /**
    * Cleans date strings of unwanted characters
    * @return: the cleaned string                   
    * @param: the date string to clean
    */
    private static string cleanDateString(string expirationDate) {
         return expirationDate.remove('/');
    }
    
    
    /**
    * Retreve custom settings for external payment gateway
    */
    private static ucinn_ascendv2__Gift_Processing_External_Pymnt_Gateways__mdt getPaymentGateway()
    {
        // Ellen: Query to get full value of ucinn_ascendv2__Email_Reporting_CC_Recipients__c
        ucinn_ascendv2__Gift_Processing_External_Pymnt_Gateways__mdt paymentGateWayMD = [SELECT DeveloperName, 
                                                                                      Id, 
                                                                                      Label, 
                                                                                      ucinn_ascendv2__Automated_Payment_Retry_Maximum__c, 
                                                                                      ucinn_ascendv2__Automated_Payment_Retry_Weekdays__c, 
                                                                                      ucinn_ascendv2__Credit_Card_Obfuscation__c, 
                                                                                      ucinn_ascendv2__Currency_Code__c, 
                                                                                      ucinn_ascendv2__Currency_Decimal_Places__c, 
                                                                                      ucinn_ascendv2__Daily_Report_Name__c, 
                                                                                      ucinn_ascendv2__Email_Reporting__c, 
                                                                                      ucinn_ascendv2__Email_Reporting_CC_Recipients__c, 
                                                                                      ucinn_ascendv2__Email_Reporting_Primary_Recipient__c, 
                                                                                      ucinn_ascendv2__Email_Reporting_ReplyTo_Address__c, 
                                                                                      ucinn_ascendv2__Environment_Key__c, 
                                                                                      ucinn_ascendv2__Gateway_Named_Credential_Name__c, 
                                                                                      ucinn_ascendv2__Is_Preferred_Gateway__c, 
                                                                                      ucinn_ascendv2__Is_Retrieve_Orphan_Payments_V2_Enabled__c, 
                                                                                      ucinn_ascendv2__Merchant_Defined_Data_Field_Index__c, 
                                                                                      ucinn_ascendv2__Merchant_ID__c, 
                                                                                      ucinn_ascendv2__Number_Of_Previous_Failure_Retries__c, 
                                                                                      ucinn_ascendv2__Payment_Gateway__c, 
                                                                                      ucinn_ascendv2__Report_Batch_Hour_Differential__c, 
                                                                                      ucinn_ascendv2__Reporting_Batch_Size__c, 
                                                                                      ucinn_ascendv2__Reporting_Named_Credential_Name__c, 
                                                                                      ucinn_ascendv2__Retry_Failed_Report_Retrieval__c, 
                                                                                      ucinn_ascendv2__Review_Transaction_Record_Type__c, 
                                                                                      ucinn_ascendv2__Review_Transaction_Record_Type_Namespace__c, 
                                                                                      ucinn_ascendv2__Review_Transaction_Record_Type_Prefix__c, 
                                                                                      ucinn_ascendv2__Transaction_Timeout_Limit__c, 
                                                                                      ucinn_ascendv2__Update_Payment_Summary_Batch_Size__c, 
                                                                                      ucinn_ascendv2__Use_Reporting_V2__c, 
                                                                                      ucinn_ascendv2__WSDL_Version__c 
                                                                                      FROM ucinn_ascendv2__Gift_Processing_External_Pymnt_Gateways__mdt 
                                                                                      WHERE DeveloperName = 'Cybersource'];
        return paymentGateWayMD;
    }
    /**
    * Retreve security settings for donation page
    */
    private static PORTAL_UCIN_Donation_Security__mdt getPageSecuritySettings(string pageName, string appealCode)
    {
        PORTAL_UCIN_Donation_Security__mdt pageSecurity = PORTAL_UCIN_Donation_Security__mdt.getInstance(pageName);
        if (pageSecurity != null && pageSecurity.Label == appealCode) {
            return pageSecurity;
        }
        else {
            return null;
        }
    }
    
    
    /**
    * Constructs the data needed for a cybersource callout
    *
    * @return: Map<String,Object> 	the data needed for a cybersource callout          
    * @param: donationFormParams    the form data submitted by the client  
    */
    private static Map<String,Object> constructCyberSourceParams(Map<String,Object> donationFormParams) {
        Map<String,Object> cyberSourceParams = new Map<String,Object>();
        cyberSourceParams.put('paymentGatewaySetting',getPaymentGateway()); 
        Contact constituentRec = (Contact)donationFormParams.get('constituentRec');
        if (constituentRec == null) {
            constituentRec = new Contact();
        }
        constituentRec.FirstName = (String)donationFormParams.get('contact_firstname');
        constituentRec.LastName = (String)donationFormParams.get('contact_lastname');
        cyberSourceParams.put('constituentRec', constituentRec);
        return cyberSourceParams;
    }
    /**
    * Constructs a payment record for outright gifts. This is needed for the cybersource callout.
    *
    * @return: ucinn_ascendv2__Payment__c		the payment record         
    * @param: donationFormParams    			the form data submitted by the client  
    */
    private static ucinn_ascendv2__Payment__c constructPaymentRecord(Map<String,Object> donationFormParams)
    {
            ucinn_ascendv2__Payment__c paymentRecord = new ucinn_ascendv2__Payment__c();
       		string subscriptionId = donationFormParams.containsKey('subscriptionId') ? (String)donationFormParams.get('subscriptionId') : '';
        	paymentRecord.ucinn_ascendv2__Payment_Amount__c = Decimal.valueOf((String)donationFormParams.get('amountToPayToday'));
            paymentRecord.ucinn_ascendv2__External_Payment_Gateway_ID__c = constructPraxId();

            paymentRecord.ucinn_ascendv2__Credit_Card_Number__c = (String)donationFormParams.get('creditCardNumber');
            paymentRecord.ucinn_ascendv2__Credit_Card_Type__c = (String)donationFormParams.get('creditCardType');
            paymentRecord.ucinn_ascendv2__Credit_Card_Expiration_Date__c = cleanDateString((String)donationFormParams.get('creditCardExpirationDate'));
            paymentRecord.ucinn_ascendv2__Authorization_Code__c = (String)donationFormParams.get('cardsecuritycode');
        	if (string.isEmpty(SubscriptionId))
            {
            	paymentRecord.ucinn_ascendv2__Created_In_External_Payment_Gateway__c = false;
            }
        	else
            {
                paymentRecord.ucinn_ascendv2__Created_In_External_Payment_Gateway__c = true;paymentRecord.ucinn_ascendv2__Status_In_External_Payment_Gateway__c = 'Active - Needs Authorization and Charge';paymentRecord.ucinn_ascendv2__Subscription_ID__c =subscriptionId;           
            }
            paymentRecord.ucinn_ascendv2__Transaction_Type__c = 'Outright Gift';
        	return paymentRecord;
    }
    /**
    * Constructs an opportunity record for gifts. This is needed for the cybersource callout.
    *
    * @return: Opportunity				the Opportunity record         
    * @param: donationFormParams    	the form data submitted by the client  
    */
    @testvisible
    private static Opportunity constructOpportunityRecord(Map<String,Object> donationFormParams)
    {
        Opportunity giftRec = (Opportunity) donationFormParams.get('giftRec');
        Opportunity opportunityRecord = new Opportunity();
        opportunityRecord.Amount = Decimal.valueOf((String)donationFormParams.get('amountToPayToday'));
        opportunityRecord.ucinn_ascendv2__Start_Date__c = giftRec.ucinn_ascendv2__Credit_Date__c;
        opportunityRecord.ucinn_ascendv2__Frequency__c = 'Monthly';
        opportunityRecord.ucinn_ascendv2__External_Payment_Gateway_ID__c = constructPraxId();
        opportunityRecord.ucinn_ascendv2__Created_In_External_Payment_Gateway__c = false;
        opportunityRecord.ucinn_ascendv2__Card_Number__c = (String)donationFormParams.get('creditCardNumber');
        opportunityRecord.ucinn_ascendv2__Payment_Type__c = (String)donationFormParams.get('creditCardType');
        opportunityRecord.ucinn_ascendv2__CCV__c = (String)donationFormParams.get('cardsecuritycode');
        opportunityRecord.ucinn_ascendv2__Card_Expiration_Date__c =  cleanDateString((String)donationFormParams.get('creditCardExpirationDate'));
        return opportunityRecord;
    }
    
    /**
    * Converts cybersource error codes into user friendly messages.
    *
    * @return: String				the user friendly message   
    * @param: errorCode		    	the cybersource error code
    */
    @testVisible
    private static string getErrorCodeMessage(string errorCode) {
        Map<String,String> codeMap = cybersourceCodes();
        if(codeMap.containsKey(errorCode)) return codeMap.get(errorCode);
        return getErrorMessages().get('Default Error');
    }
    
    /**
    * Maps cybersource error codes to a user friendly message.
    *
    * @return: a map of error codes containing the user friendly message   
    */    
    private static Map<String,String> cybersourceCodes()
    {
        Map<String,String> codeMap = new Map<String,String> {
            '102'=>'The credit card details provided are not valid. Please check and try again.',
			'202'=>'The credit card provided has expired card or an incorrect expiry date has been provided. Please check and try again.',
       		'203' => 'The credit card provided has been declined. Please contact your bank for more details.',
			'204' => 'The credit card provided has insufficient funds. Please contact your bank for more details.',
			'230' =>'Incorrect CVV - please enter again.'
        };
        return codeMap;
    }
    
    /**
    * wraps a user friendly error message for consumption by Aura components.
    *
    * @return: Map<string,Object>	JSON type object for consumption by Aura components
     * @param: error		    	the user friendly message
    */
    private static Map<string,Object> errorMessage(string error) {
        return new Map<String, Object>{'message' => error};
    }
   

    private static void sendMail(PORTAL_UCIN_Email_Template__mdt templateMD, ucinn_ascendv2__Review_Transaction_v2__c rtRecord, ID contentVersionId, String sendToAddress) {
        try {                   
            List<EmailTemplate> templateList = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName =: templateMD.DeveloperName];

            if (!templateList.isEmpty()) {
                EmailTemplate emailTemplate = templateList[0];
                String firstName;
                String orgId = UserInfo.getOrganizationId();
                String domainName;

                if (rtRecord.ucinn_ascendv2__Contact__c != null) {
                    firstName = rtRecord.ucinn_ascendv2__Contact__r.FirstName;
                } else if (rtRecord.ucinn_ascendv2__Interim__c != null) {
                    firstName = rtRecord.ucinn_ascendv2__Interim__r.ucinn_ascendv2__First_Name__c;
                }

                PORTAL_UCIN_Domain_Name__c mhc = PORTAL_UCIN_Domain_Name__c.getInstance();
                domainName = mhc.Domain_Name__c;   

                List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

                List<OrgWideEmailAddress> owa = [select Id, Address, DisplayName from OrgWideEmailAddress WHERE Address = :templateMD.OrgWideEmailAddress__c limit 1];
                if (!owa.isEmpty()) {
                    mail.setOrgWideEmailAddressId(owa[0].Id);
                }
                // process the merge fields manually. We need to do this b/c community guest users don't have a proper user record, so merge fields don't work.
                String subject = emailTemplate.Subject;
                if (subject != null) {
                    subject = subject.replace('{!Receiving_User.FirstName}', firstName);
                }
                
                String htmlBody = emailTemplate.HtmlValue;
                if (htmlBody != null) {
                    htmlBody = htmlBody.replace('{!$Setup.PORTAL_UCIN_Domain_Name__c.Domain_Name__c}', domainName);htmlBody = htmlBody.replace('{!$Organization.Id}', orgId);htmlBody = htmlBody.replace('{!Receiving_User.FirstName}', firstName);
                }
                
                String plainBody = emailTemplate.Body;
                if (plainBody != null) {
                    plainBody = plainBody.replace('{!Receiving_User.FirstName}', firstName);
                }

                mail.setSubject(subject);mail.setHtmlBody(htmlBody);mail.setPlainTextBody(plainBody);
                mail.setToAddresses(new String[]{sendToAddress});
                if (rtRecord.ucinn_ascendv2__Transaction_Type__c == 'Gift' && !String.isBlank(contentVersionId)) {
                    mail.setEntityAttachments(new String[]{String.valueOf(contentVersionId)});
                }
                mail.saveAsActivity = false;mailList.add(mail);
                Messaging.sendEmail(mailList);    
            }                    
        } catch (Exception ex) {
            Nebula.Logger.error('PORTAL_UCIN_DonationController.sendMail - contentVerId: ' +  contentVersionId, ex);
            Nebula.Logger.saveLog();
        }
    }

    /**
    * Link transaction data to the RT, so RT trigger can pick it up.
    * If RT is already complete at this time, then carry out all logic required for 
    */
    private static void linkTransactionDataToRT(ucinn_ascendv2__Review_Transaction_v2__c thisRT) {
        List<ucinn_ascendv2__Transaction_Data__c> transDataList = [SELECT ID,ucinn_ascendv2__Authorized_Date__c,
                                                                ucinn_ascendv2__Contact__c,ucinn_ascendv2__Gift_or_Pledge__c,ucinn_ascendv2__Is_Success__c,
                                                                ucinn_ascendv2__Merchant_Reference_Code__c,ucinn_ascendv2__Message__c,ucinn_ascendv2__Account__c,
                                                                ucinn_ascendv2__Reason_Code__c,ucinn_ascendv2__Request_ID__c,Review_TransactionV2__c,ucinn_ascendv2__Session__c,
                                                                ucinn_ascendv2__Subscription_ID__c,ucinn_ascendv2__Transaction_Type__c
                                                                FROM ucinn_ascendv2__Transaction_Data__c 
                                                                WHERE ucinn_ascendv2__Merchant_Reference_Code__c =: thisRT.ucinn_ascendv2__External_System_ID__c];
        
        // Requery the RT to get latest status, and grab the opportunity under it if it exists.
        thisRT = [SELECT ID, ucinn_ascendv2__Status__c, ucinn_ascendv2__Session__c, ucinn_ascendv2__Contact__c,
                    (SELECT ID FROM ucinn_ascendv2__Opportunities_Review_Transaction_v2__r) 
                    FROM ucinn_ascendv2__Review_Transaction_v2__c 
                    WHERE ID =: thisRT.ID];

        //Since we do two callouts for outright gift creation now.
        String subId;

        // DEPRECATED: There should only be one transaction data record. Parent it to the RT if it exists.
        // UPDATE: There can be multiple transaction data records now. One for subscription creation, and one for auth and charge. 
        if (!transDataList.isEmpty()) {

            for (ucinn_ascendv2__Transaction_Data__c transDataToUpdate : transDataList) {

                transDataToUpdate.Review_TransactionV2__c = thisRT.Id;

                // If it's posted, that means the session, contact and opp should all be there.
                if (thisRT.ucinn_ascendv2__Status__c == 'Posted') {
                    if (!thisRT.ucinn_ascendv2__Opportunities_Review_Transaction_v2__r.isEmpty()) {
                        transDataToUpdate.ucinn_ascendv2__Gift_or_Pledge__c = thisRT.ucinn_ascendv2__Opportunities_Review_Transaction_v2__r[0].Id;
                    }
                    transDataToUpdate.ucinn_ascendv2__Session__c = thisRT.ucinn_ascendv2__Session__c;
                    transDataToUpdate.ucinn_ascendv2__Contact__c = thisRT.ucinn_ascendv2__Contact__c;

                    if (transDataToUpdate.ucinn_ascendv2__Transaction_Type__c == 'On-Demand Subscription Creation') {
                        subId = transDataToUpdate.ucinn_ascendv2__Subscription_ID__c;
                    }
                }

            }

            update transDataList;

            if (thisRT.ucinn_ascendv2__Status__c == 'Posted') {

                for (ucinn_ascendv2__Transaction_Data__c transDataToUpdate : transDataList) {
                    if (transDataToUpdate.ucinn_ascendv2__Transaction_Type__c == 'Payment Authorization and Capture') {
                        transDataToUpdate.ucinn_ascendv2__Subscription_ID__c = subId;
                        PORTAL_UCIN_CybSourceUtils.updateRelatedRecords(new List<ucinn_ascendv2__Transaction_Data__c>{transDataToUpdate});
                    }
                }
            }

        }
    }
    /**
    * Wrapper class for select option
    */
    public class SelectOptionDetail {
        @AuraEnabled
        public String name {get;set;}
        
        @AuraEnabled
        public String value {get;set;}
        
        public selectOptionDetail(String name, String value) {
            this.name = name;
            this.value = value;
        }
    }
      /**
    * Simulate a callout to the payment processor (security feature)             
    * @param: returnId                      a faux gift receipt id                  
    */
    @testvisible
    private static Map<String, Object> fauxPaymentCallout(Id returnId)
    {
        randomDelay(FAUX_DELAY);
        return new Map<String, Object>{'giftReceiptId' => returnId,'paymentGroupId'=>''};
    }
    /**
    * create a randomized delay
    *                   
    * @param: baseDelay	 the base delay time in ms            
    */
    private static void randomDelay(integer baseDelay) {
        Integer delay = baseDelay+Integer.valueof((Math.random() * baseDelay));
        Long start = DateTime.now().getTime();
        while(DateTime.now().getTime()-start<delay);
    }
    /**
    * Custom exception class
    */
   	private virtual class DonationProcessingException extends Exception {
	}
}