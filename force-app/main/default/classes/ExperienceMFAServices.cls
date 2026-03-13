/**
 * @description Service class for MFA / 2FA related processing
 * @group       Services
 * @revision    14/02/2022 - Kristian Vegerano - Created
 * Ver   Date         Author          		Modification
 * 2.3   2024-02-05   Peter Sewell          In systemRegisterMobileNumberFallback() set MFA mobile to the number returned by Twilio
 * 2.2   2023-11-28   Peter Sewell          Use Twilio as default MFA method where SFDC SMS does not support country
 * 2.1   2023-07-03   Peter Sewell          MFA - SMS fallback to Twilio 
 * 2.0   2022-10-07   Inderpal Dhanoa		Defect fix for Contact Sync PENGAGE-2524 
 * 1.9   2022-09-02   Sachin Shetty	        Set Verification Status on Phone record to 'Verified by MFA'
 * 1.8   2022-08-22   Ken McGuire			Replace country static resource with table. 
 * 1.7   2022-08-10   Ken McGuire			Security Uplift
 * 1.6   2022-08-09   Inderpal Dhanoa   	PENGAGE-2472 
 * 1.5   2022-07-12   Martin Cadman		   	Swallow an exception if Phone can not be updated due to validation rule 
 * 1.5   2022-07-08   Martin Cadman		   	Support phone UID hash changes 
 * 1.4   2022-06-08   Inderpal Dhanoa   	PENGAGE-2388
 * 1.3   2022-04-26   Inderpal Dhanoa   	PENGAGE-2309
 * 1.2   2022-04-06   Inderpal Dhanoa   	PENGAGE-2206
 * 1.1   2022-02-03   Inderpal Dhanoa   	PENGAGE-2235
 * 1.0   2022-14-02   Kristian Vegerano   	Initial Version
 */
public with sharing class ExperienceMFAServices {

    // Constants
    Public Static final String MFA_OTP_TEMPLATE_NAME = 'Experience MFA'; // Used to select default Twilio message template
    Public Static final String MFA_OTP_SEPARATOR = '::'; // token to split Twilio verification and service ids

    /**
     * @author      Kristian Vegerano
     * @description Method that determines whether the logging in user needs to bypass the mfa challenge page
     * @param       Id - id of the logging in user
     * @return      Boolean - true if the mfa challenge screen will be bypassed
     * @revision    07/02/2022 - Kristian Vegerano - Created
     */
    public static Boolean determineByPassTwoFactor(Id userId){
        return new CommitQueryRecords().determineByPassTwoFactor(userId);
    }

    /**
     * @author      Peter Sewell
     * @description Method that checks whether SFDC SMS supports the country
     * @param       countryCode - country phone extension
     * @return      Boolean - true if supported, otherwise false
     * @revision    28/11/2023 - Peter Sewell - Created
     */
    @AuraEnabled
    public static Boolean isSfdcSmsSupported(String countryCode){
        if (ExperienceAuthenticationServices.isUnsafe(new List<String>{countryCode})) return true;
        return (!new CountriesSelector().isSfdcSmsUnsupported(countryCode));
    }

    /**
     * @author      Kristian Vegerano
     * @description Method that initiates mobile number registration process
     * @param       countryCode - country phone extension
     *              phoneNumber - user's phone number
     *              mobilePhoneCountry - country name where the phone number is registered
     * @return      String - encrypted identifier for the verification code sent to the the user
     * @revision    07/02/2022 - Kristian Vegerano - Created
     */
    @AuraEnabled
    public static String systemRegisterMobileNumber(String countryCode, String phoneNumber, String mobilePhoneCountry){
        if (ExperienceAuthenticationServices.isUnsafe(new List<String>{countryCode,phoneNumber,mobilePhoneCountry})) return null;
        // initiate register mobile number process
        return new CommitQueryRecords().systemRegisterMobileNumber(countryCode, phoneNumber, mobilePhoneCountry); // Uses SFDC
    }

    /**
     * @author      Peter Sewell
     * @description Method that initiates resend of mobile number registration process
     * @param       countryCode - country phone extension
     *              phoneNumber - user's phone number
     *              mobilePhoneCountry - country name where the phone number is registered
     * @return      String - identifier for the verification code sent to the the user
     * @revision    27/07/2023 - Peter Sewell - Created
     */
    @AuraEnabled
    public static String systemRegisterMobileNumberFallback(String countryCode, String phoneNumber, String mobilePhoneCountry){
        if (ExperienceAuthenticationServices.isUnsafe(new List<String>{countryCode,phoneNumber,mobilePhoneCountry})) return null;
        // initiate register mobile number process
        return new CommitQueryRecords().systemRegisterMobileNumberFallback(countryCode, phoneNumber, mobilePhoneCountry); // Uses Twilio
    }

    @TestVisible
    private static Map<String, Object> testCurrentUserDetails {get;set;}
    @AuraEnabled
    public static Map<String, Object> retrieveCurrentUserDetails() {
        //Initialize variables
        Map<String, Object> resultsMap = new Map<String, Object>();
        try {
            //retrieve current user details in without sharing context
            if(!Test.isRunningTest()){
                resultsMap = new CommitQueryRecords().retrieveCurrentUserDetails(UserInfo.getUserId());
            }else{
                resultsMap = testCurrentUserDetails;
            }
        }catch(Exception ex){
            Nebula.Logger.error('ExperienceMFAServices.retrieveCurrentUserDetails '+ex.getMessage(), ex);
            Nebula.Logger.saveLog();
        } 
        return resultsMap;
    }

    @AuraEnabled
    public static String verifyMobileNumber(String identifier, String verificationCode, String startUrl) {
        if (ExperienceAuthenticationServices.isUnsafe(new List<String>{identifier,verificationCode,startUrl})) return ExperienceAuthenticationServices.MESSAGE_UNSAFE_INPUT;
        String exceptionText = '';
        try {
            exceptionText = System.UserManagement.verifyRegisterVerificationMethod(verificationCode, Auth.VerificationMethod.SMS);
			if(String.isBlank(exceptionText)){
				syncMobileDetails(); 
			}
        }catch(Exception ex){
            Nebula.Logger.error('ExperienceMFAServices.verifyMobileNumber '+ex.getMessage(), ex);  
            Nebula.Logger.saveLog();
        } 
        return exceptionText;
    }

    @AuraEnabled
    public static String verifyMobileNumberFallback(String identifier, String verificationCode, String startUrl) {
        if (ExperienceAuthenticationServices.isUnsafe(new List<String>{identifier,verificationCode,startUrl})) return ExperienceAuthenticationServices.MESSAGE_UNSAFE_INPUT;
        String exceptionText = '';
        try {
            // Code was sent via external SMS service. e.g. Twilio., So verify with external service 
            Boolean isVerified = !isTst()? OneTimeTokenService.verifyOtp(ExperienceMFAServices.otpWrapper(verificationCode, identifier), OneTimeTokenService.Service.MFA) : true;
            exceptionText = isVerified ? '' : 'Could not verify code';			
            if(String.isBlank(exceptionText)){
				syncMobileDetails(); 
                ExperienceMFAServices.setVerifiedByExternalService();
			}
        }catch(Exception ex){
            Nebula.Logger.error('ExperienceMFAServices.verifyMobileNumberFallback '+ex.getMessage(), ex);
            Nebula.Logger.saveLog();
        } 
        return exceptionText;
    }

    /**
     * @author      Kristian Vegerano
     * @description Method that initiates the 2FA SMS
     * @param       None
     * @return      None
     * @revision    07/02/2022 - Kristian Vegerano - Created
     */
    @AuraEnabled
    public static Map<String, Object> sendSmsVerification(){
        //Initialize variables
        Map<String, Object> resultsMap = new Map<String, Object>();
        try {
            String identifier;
            if(!test.isRunningTest()){
                identifier = UserManagement.initVerificationMethod(Auth.VerificationMethod.SMS);
                resultsMap.put('Identifier', identifier);
            }     
        }catch(Exception ex){
            Nebula.Logger.error('ExperienceMFAServices.sendSmsVerification '+ex.getMessage(), ex);
            Nebula.Logger.saveLog();
        } 
        return resultsMap;
    }

    @AuraEnabled
    public static Map<String, Object> sendEmailVerification(){
        //Initialize variables
        Map<String, Object> resultsMap = new Map<String, Object>();
        try {
            String identifier;
            if(!test.isRunningTest()){
                identifier = UserManagement.initVerificationMethod(Auth.VerificationMethod.EMAIL);
                resultsMap.put('Identifier', identifier);
            }
        }catch(Exception ex){
            Nebula.Logger.error('ExperienceMFAServices.sendEmailVerification '+ex.getMessage(), ex);
            Nebula.Logger.saveLog();
        } 
        return resultsMap;
    }

    @TestVisible
    private static Auth.VerificationResult testVerificationResult {get;set;}
    /**
     * @author      Kristian Vegerano
     * @description Method that verifies user's entered verification code for 2FA SMS
     * @param       None
     * @return      None
     * @revision    07/02/2022 - Kristian Vegerano - Created
     */
    @AuraEnabled
    public static Map<String, Object> verifyVerificationCode(String identifier, String verificationCode, String verificationMethod){
        //Initialize variables
        Map<String, Object> resultsMap = new Map<String, Object>();
        if (ExperienceAuthenticationServices.isUnsafe(new List<String>{identifier,verificationCode,verificationMethod})) return unsafeUserInputMessage();

        try {
            //verificationCodeError = '';
            // requiring identifier from the initVerification
            // the code will need to be entered in this method
            Auth.VerificationResult verificationResult;
            Auth.VerificationMethod challengeMethod = Auth.VerificationMethod.SMS;
            if(verificationMethod == 'Email'){
                challengeMethod = Auth.VerificationMethod.Email;
            }
            
            //retrieve current user details in without sharing context
            if(!Test.isRunningTest()){
                verificationResult = UserManagement.verifyVerificationMethod(identifier, verificationCode, challengeMethod);
            }else{
                verificationResult = testVerificationResult;
            }

            // check if the match is success, if so redirect to the home page else show error message
            if((verificationResult != null && verificationResult.success)){            
                //verificationCodeError = '';
                resultsMap.put('Status', 'success');
                resultsMap.put('Message', '');
                
                // update last Email verfification login of the user
                User contextUser = [SELECT Id, MFA_Email_Verification_Count__c FROM User WHERE Id = :UserInfo.getUserId()];
                contextUser.Last_2FA_Login__c = System.NOW();
                contextUser.Last_2FA_Login_Device__c = 0; // clear if not coming from VF login page
                if(verificationMethod == 'Email'){
                    if(contextUser.MFA_Email_Verification_Count__c == null){
                        contextUser.MFA_Email_Verification_Count__c = 0;
                    }
                    contextUser.MFA_Email_Verification_Count__c = Integer.valueOf(contextUser.MFA_Email_Verification_Count__c) + 1;
                }else if(verificationMethod == 'SMS'){
                    contextUser.MFA_Email_Verification_Count__c = 0;
                }
                update contextUser;
				
				syncMobileDetails(); 
            }else{
                resultsMap.put('Status', 'error');
                resultsMap.put('Message', '* You have entered an incorrect verification code');
            }
        }catch(Exception ex){
            Nebula.Logger.error('ExperienceMFAServices.verifyVerificationCode '+ex.getMessage(), ex);
            Nebula.Logger.saveLog();
        } 
        return resultsMap;
    }
	
	/**
     * @author      Inderpal Dhanoa
     * @description Method that syncs the mobile details to the Phone object
     * @param       None
     * @return      None
     * @revision    04/04/2022 - Inderpal Dhanoa - Created
     *              02/09/2022 - Sachin Shetty   - Set Verification Status on Phone record to 'Verified by MFA'
     */
    @future 
    public static void syncMobileDetails(){
        try { 
            User loggedUser = fetchLoggedUser();
            if (loggedUser.MobilePhone != null) {
                processMobileDetails(loggedUser);
            }
        } catch (Exception err) {
            logError('ExperienceMFAServices.syncMobileDetails', err);
        }
    }

	/**
	 * @author      Arnie Ug
	 * @description method to support syncMobileDetails in relation to CognitiveComplexity
	 * @revision    13/05/2025 - Arnie Ug - Created
	 */
    private static User fetchLoggedUser() {
        return [SELECT Id, ContactId, MobilePhone FROM User WHERE Id = :UserInfo.getUserId()];
    }

	/**
	 * @author      Arnie Ug
	 * @description method to support syncMobileDetails in relation to CognitiveComplexity
	 * @revision    13/05/2025 - Arnie Ug - Created
	 */
    private static void processMobileDetails(User loggedUser) {
        Set<String> keySet = PhoneServices.buildPhoneKeySet(loggedUser.ContactId, 'Mobile', PhoneServices.formatPhone(loggedUser.MobilePhone));
        if (!keySet.isEmpty()) {
            List<Phone__c> phoneRecords = createPhoneRecords(loggedUser, keySet);
            upsertPhoneRecords(phoneRecords);
        }
    }

	/**
	 * @author      Arnie Ug
	 * @description method to support syncMobileDetails in relation to CognitiveComplexity
	 * @revision    13/05/2025 - Arnie Ug - Created
	 */
    private static List<Phone__c> createPhoneRecords(User loggedUser, Set<String> keySet) {
        List<Phone__c> phoneRecords = new List<Phone__c>();
        phoneRecords.add(new Phone__c(
            Name = loggedUser.MobilePhone,
            End_Date__c = null,
            Key_UID__c = Person360Helper.generatePerson360Key(keySet),
            Contact__c = loggedUser.ContactId,
            Type__c = 'Mobile',
            Classification__c = 'Private',
            Source__c = 'Contact supplied',
            Verification_Status__c = 'Verified by MFA'
        ));
        return phoneRecords;
    }

	/**
	 * @author      Arnie Ug
	 * @description method to support syncMobileDetails in relation to CognitiveComplexity
	 * @revision    13/05/2025 - Arnie Ug - Created
	 */
    private static void upsertPhoneRecords(List<Phone__c> phoneRecords) {
        if (!phoneRecords.isEmpty()) {
            List<Database.UpsertResult> upsertResults = Database.upsert(phoneRecords, Phone__c.Key_UID__c, false);
            for (Database.UpsertResult result : upsertResults) {
                if (!result.isSuccess()) {
                    handleUpsertErrors(result);
                }
            }
        }
    }


    /**
     * @author      Vishal Gupta
     * @description Method that syncs the unverified mobile details to the Phone object
     * @param       contactId
     * @param       phoneNumber
     * @revision    10/04/2025 - Vishal gupta - Created
     */
    @future 
    public static void syncUnverifiedMobileDetails(Id contactId, String phoneNumber){
        try { 
            Set<String> keySet = buildPhoneKeySet(contactId, phoneNumber);
            if (!keySet.isEmpty()) {
                List<Phone__c> phoneRecords = createPhoneRecords(contactId, phoneNumber, keySet);
                upsertPhoneRecords(phoneRecords);
            }
        } catch (Exception err) {
            logError('ExperienceMFAServices.syncUnverifiedMobileDetails', err);
        }
    }

	/**
	 * @author      Arnie Ug
	 * @description method to support syncUnverifiedMobileDetails in relation to CognitiveComplexity
	 * @revision    13/05/2025 - Arnie Ug - Created
	 */
    private static Set<String> buildPhoneKeySet(Id contactId, String phoneNumber) {
        return PhoneServices.buildPhoneKeySet(contactId, 'Mobile', PhoneServices.formatPhone(phoneNumber));
    }

	/**
	 * @author      Arnie Ug
	 * @description method to support syncUnverifiedMobileDetails in relation to CognitiveComplexity
	 * @revision    13/05/2025 - Arnie Ug - Created
	 */
    private static List<Phone__c> createPhoneRecords(Id contactId, String phoneNumber, Set<String> keySet) {
        List<Phone__c> phoneRecords = new List<Phone__c>();
        phoneRecords.add(new Phone__c(
            Name = phoneNumber,
            End_Date__c = null,
            Key_UID__c = Person360Helper.generatePerson360Key(keySet),
            Contact__c = contactId,
            Type__c = 'Mobile',
            Classification__c = 'Private',
            Source__c = 'Contact supplied',
            Verification_Status__c = 'Unverified'
        ));
        return phoneRecords;
    }

	/**
	 * @author      Arnie Ug
	 * @description method to support syncUnverifiedMobileDetails in relation to CognitiveComplexity
	 * @revision    13/05/2025 - Arnie Ug - Created
	 */
    private static void handleUpsertErrors(Database.UpsertResult result) {
        for (Database.Error error : result.getErrors()) {
            if (error.getStatusCode() != System.StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION) {
                Nebula.Logger.error('ExperienceMFAServices.syncUnverifiedMobileDetails' + ' ' + error.getMessage());
                Nebula.Logger.saveLog();
                throw new LogUtilityException(String.valueOf(result.getErrors()));
            }
        }
    }

	/**
	 * @author      Arnie Ug
	 * @description method to support syncUnverifiedMobileDetails in relation to CognitiveComplexity
	 * @revision    13/05/2025 - Arnie Ug - Created
	 */
    private static void logError(String context, Exception err) {
        Nebula.Logger.error(context + ' ' + err.getMessage(), err);
        Nebula.Logger.saveLog();
    }

	/**
     * @author      Peter Sewell
     * @description Method that sets mobile verification flag to true
     *              if mobile was verified by external service. e.g. Twilio
     * @param       None
     * @return      None
     * @revision    04/07/2023 - Peter Sewell - Created
     */ 
    public static void setVerifiedByExternalService(){
        try{ 
            User loggedUser = [SELECT Id, MFA_Mobile_Verified_External__c FROM User WHERE Id = :UserInfo.getUserId()];
            loggedUser.MFA_Mobile_Verified_External__c = true;
            update loggedUser;                     
        } catch(Exception err){
            Nebula.Logger.error('ExperienceMFAServices.setVerifiedByExternalService '+err.getMessage(), err);
            Nebula.Logger.saveLog();
        }
    }

    /**
     * @description       : Inner class for committing and querying records
     * @author            : Kristian Vegerano
     * @group             : Services
     * @last modified on  : 05-05-2022
     * @last modified by  : rajesh.punjabi@monash.edu
     * Modifications Log  : conflict fix.
     * Ver   Date         Author          Modification
     * 1.0   2022-02-07 - Kristian Vegerano - Created
     */
    @TestVisible
    private without sharing class CommitQueryRecords {
        /**
         * @author      Kristian Vegerano
         * @description Method that retrieves all current user details
         * @revision    11/02/2022 - Kristian Vegerano - Created
         */
        public Map<String, Object> retrieveCurrentUserDetails(Id userId) {
            Map<String, Object> resultsMap = new Map<String, Object>();
            try {
                User currentUser = fetchCurrentUser(userId);
                populateContactPhone(currentUser, resultsMap);
                populateVerificationState(userId, currentUser, resultsMap);
                populateFailedAttempts(userId, resultsMap);
                populateCountryData(resultsMap);
                populateLoginHistory(userId, resultsMap);
                populateUserDetails(currentUser, resultsMap);
            } catch (Exception ex) {
                logError('ExperienceMFAServices.syncUnverifiedMobileDetails', ex);
            }
            return resultsMap;
        }

        /**
         * @author      Arnie Ug
         * @description method to support retrieveCurrentUserDetails in relation to CognitiveComplexity
         * @revision    13/05/2025 - Arnie Ug - Created
         */
        private User fetchCurrentUser(Id userId) {
            return [SELECT Id, Alias, CommunityNickname, Email, MFA_Email_Verification_Count__c, LastPasswordChangeDate, Last_2FA_Login__c, ContactId,
                            LanguageLocaleKey, LastName, MobilePhone, MFA_Mobile_Verified_External__c, ProfileId, Username, Mobile_Phone_Country__c 
                    FROM User 
                    WHERE Id = :userId];
        }

        /**
         * @author      Arnie Ug
         * @description method to support retrieveCurrentUserDetails in relation to CognitiveComplexity
         * @revision    13/05/2025 - Arnie Ug - Created
         */
        private void populateContactPhone(User currentUser, Map<String, Object> resultsMap) {
            if (currentUser.ContactId != null) {
                Contact userContact = [SELECT Phone FROM Contact WHERE Id = :currentUser.ContactId LIMIT 1];
                if (userContact.Phone != null) {
                    resultsMap.put('contactPhone', userContact.Phone);
                }
            }
        }

        /**
         * @author      Arnie Ug
         * @description method to support retrieveCurrentUserDetails in relation to CognitiveComplexity
         * @revision    13/05/2025 - Arnie Ug - Created
         */
        private void populateVerificationState(Id userId, User currentUser, Map<String, Object> resultsMap) {
            Boolean userHasVerified = false;
            Boolean externalVerification = false;

            if (currentUser.MFA_Mobile_Verified_External__c) {
                userHasVerified = true;
                externalVerification = true;
            } else {
                for (TwoFactorMethodsInfo loopTwoFactorMethod : [SELECT HasUserVerifiedMobileNumber, HasUserVerifiedEmailAddress
                                                                FROM TwoFactorMethodsInfo
                                                                WHERE UserId = :userId]) {
                    userHasVerified = loopTwoFactorMethod.HasUserVerifiedMobileNumber;
                }
            }

            resultsMap.put('HasVerified', userHasVerified);
            resultsMap.put('HasExternalVerification', externalVerification);
        }

        /**
         * @author      Arnie Ug
         * @description method to support retrieveCurrentUserDetails in relation to CognitiveComplexity
         * @revision    13/05/2025 - Arnie Ug - Created
         */
        private void populateFailedAttempts(Id userId, Map<String, Object> resultsMap) {
            DateTime fifteenMinutesAgoDateTime = System.NOW().addMinutes(-15);
            Integer failedAttempts = [SELECT COUNT() 
                                       FROM VerificationHistory 
                                       WHERE UserId = :userId
                                             AND Status = 'FailedInvalidCode'
                                             AND VerificationMethod IN ('SMS','Email')
                                             AND VerificationTime > :fifteenMinutesAgoDateTime];
            resultsMap.put('FailedAttempts', failedAttempts);
        }

        /**
         * @author      Arnie Ug
         * @description method to support retrieveCurrentUserDetails in relation to CognitiveComplexity
         * @revision    13/05/2025 - Arnie Ug - Created
         */
        private void populateCountryData(Map<String, Object> resultsMap) {
            resultsMap.put('allCountries', CountriesSelector.validCountryList());
        }

        /**
         * @author      Arnie Ug
         * @description method to support retrieveCurrentUserDetails in relation to CognitiveComplexity
         * @revision    13/05/2025 - Arnie Ug - Created
         */
        private void populateLoginHistory(Id userId, Map<String, Object> resultsMap) {
            String challengeCountriesString = Label.Activate_MFA_Locations;
            Set<String> challengeCountriesSet = new Set<String>();
            if (!String.isBlank(challengeCountriesString)) {
                for (String loopCountry : challengeCountriesString.split(';')) {
                    challengeCountriesSet.add(loopCountry.toLowerCase());
                }
            }

            Boolean shouldShowInternalMFA = false;
            Integer deviceHashCode = 0; 
            for (LoginHistory contextLoginHistory : [SELECT Id, SourceIp, Browser, LoginGeo.Country
                                                FROM LoginHistory
                                                WHERE UserId = :userId
                                                ORDER BY LoginTime DESC
                                                LIMIT 1]) {
                shouldShowInternalMFA = challengeCountriesSet.contains(contextLoginHistory.LoginGeo.Country) || challengeCountriesSet.contains('all');
                deviceHashCode = (contextLoginHistory.SourceIp + contextLoginHistory.Browser).hashCode();
            }
            resultsMap.put('ShouldShowInternalMFA', shouldShowInternalMFA);
            resultsMap.put('DeviceHashCode', deviceHashCode);
        }

        /**
         * @author      Arnie Ug
         * @description method to support retrieveCurrentUserDetails in relation to CognitiveComplexity
         * @revision    13/05/2025 - Arnie Ug - Created
         */
        private void populateUserDetails(User currentUser, Map<String, Object> resultsMap) {
            Boolean mfaEnabledUser = FeatureManagement.checkPermission('Alumni_Experience_2FA');
            resultsMap.put('MFAEnabledUser', mfaEnabledUser);
            resultsMap.put('MobileNumberCountry', currentUser.Mobile_Phone_Country__c);
            resultsMap.put('MobileNumber', currentUser.MobilePhone);
            resultsMap.put('Email', currentUser.Email);

            if (currentUser.MFA_Email_Verification_Count__c == null) {
                currentUser.MFA_Email_Verification_Count__c = 0;
            }
            resultsMap.put('EmailVerificationCount', currentUser.MFA_Email_Verification_Count__c);
            resultsMap.put('HasRequestedPasswordReset', (currentUser.Last_2FA_Login__c < currentUser.LastPasswordChangeDate));
        }
		
        /**
         * @author      Kristian Vegerano
         * @description Method that registers a mobile number as the user's verified number
         * @revision    11/02/2022 - Kristian Vegerano - Created
         */
        public String systemRegisterMobileNumber(String countryCode, String phoneNumber, String mobilePhoneCountry){

            Savepoint beforeMobileNumberUpdate = Database.setSavepoint();
            String identifier = ''; 
            String errMsg = '';
            try{
                // Register with SFDC mobile verification service...
                User currentUser;
                for(User loopUser : [SELECT Id, Alias, CommunityNickname, Email, MFA_Email_Verification_Count__c,
                                            MFA_Mobile_Verified_External__c, LanguageLocaleKey, LastName, MobilePhone, ProfileId, Username 
                                    FROM User 
                                    WHERE Id = :UserInfo.getUserId()]){
                    currentUser = loopUser;
                }

                //remove mobile number
                currentUser.MobilePhone = null;    
                currentUser.Mobile_Phone_Country__c = null;       
                update currentUser;

                //apply new mobile number
                //no format is applied beyond what the usermanagement function does. This does mean that the base number may have a leading 0.
                currentUser.MobilePhone = System.UserManagement.formatPhoneNumber(countryCode, phoneNumber);        
                currentUser.Mobile_Phone_Country__c = mobilePhoneCountry;
                update currentUser;

                if(currentUser != null && !Test.isRunningTest()){
                    errMsg = System.UserManagement.initRegisterVerificationMethod(Auth.VerificationMethod.SMS);
                }  
            }catch(Exception ex){
                String exptn = ex.getMessage();
                if(exptn.containsIgnoreCase('provide a valid country code') || exptn.containsIgnoreCase('provide a valid phone number')){
                    errMsg = exptn;

                    // log unsupported countries for sms messaging
                    Nebula.Logger.error('ExperienceMFAServices.systemRegisterMobileNumber - Unsupported country for SMS messaging: ' + mobilePhoneCountry + ' (' + countryCode + ') ' + phoneNumber, ex);
                    Nebula.Logger.saveLog();
                }else{
                    Nebula.Logger.error('ExperienceMFAServices.systemRegisterMobileNumber '+ex.getMessage(), ex);
                    Nebula.Logger.saveLog();
                }
                Database.rollback(beforeMobileNumberUpdate);
            } 
            identifier = errMsg;
            return identifier;
        }

        /**
         * @author      Peter Sewell
         * @description Resends registration code via extrernal SMS verification service
         * @revision    04/07/2023 - Peter Sewell - Created
         *              05/02/2024 - Peter Sewell - Use Twilio returned number to update mobile on user record
         */
        public String systemRegisterMobileNumberFallback(String countryCode, String phoneNumber, String mobilePhoneCountry) {
            String identifier = '';
            User currentUser;
            for(User loopUser : [SELECT Id, Alias, CommunityNickname, Email, MFA_Email_Verification_Count__c,
                                        MFA_Mobile_Verified_External__c, LanguageLocaleKey, LastName, MobilePhone, ProfileId, Username 
                                FROM User 
                                WHERE Id = :UserInfo.getUserId()]){
                currentUser = loopUser;
            }

            String mobileNumber = System.UserManagement.formatPhoneNumber(countryCode, phoneNumber);        
            OneTimeTokenService.OneTimeTokenWrapper resp = !isTst()? OneTimeTokenService.sendOtp(mobileNumber, 'sms', MFA_OTP_TEMPLATE_NAME, OneTimeTokenService.Service.MFA)  :TEST_OTP_WRAPPER();
            identifier = resp.VerificationSid + MFA_OTP_SEPARATOR + resp.ServiceSid;
            mobileNumber = resp.To;

            // apply mobile number
            currentUser.MobilePhone = mobileNumber;        
            currentUser.Mobile_Phone_Country__c = mobilePhoneCountry;
            update currentUser;

            return identifier; 
        }

        /**
         * @author      Kristian Vegerano
         * @description Method that determines if the user's identity needs to be challenged or not
         * @revision    11/02/2022 - Kristian Vegerano - Created
         */
        public Boolean determineByPassTwoFactor(Id userId){
            // initialize variable
            Boolean doBypass = false;
            LoginHistory contextLoginHistory;
            Integer contextLoginDeviceHash = 0;
            List<VerificationHistory> verificationHistoryList = new List<VerificationHistory>();
            if(Test.isRunningTest()){
                // mock VerificationHistory list as it can't be committed and can only be queried
                verificationHistoryList.add(new VerificationHistory());
            }

            try{
                //if the Logged in User does not have a verified Mobile then he is to be challenged for MFA
                TwoFactorMethodsInfo verifiedInfos;
                if(!Test.isRunningTest()){
                    verifiedInfos = [SELECT HasUserVerifiedMobileNumber, HasUserVerifiedEmailAddress
                                    FROM TwoFactorMethodsInfo
                                    WHERE UserId = :userId];
                }            
                
                // retrieve user details            
                User contextUser = [SELECT Id, CreatedDate, LastLoginDate, LastPasswordChangeDate, Last_2FA_Login__c, Last_2FA_Login_Device__c, 
                                           MFA_Mobile_Verified_External__c, Contact.Phone FROM User WHERE Id = :userId LIMIT 1];

                // retrieve LoginHistory for the current user
                for(LoginHistory loopLoginHistory : [SELECT Id, SourceIp, Browser, LoginGeo.Country
                                                    FROM LoginHistory 
                                                    WHERE UserId = :userId
                                                    ORDER BY LoginTime DESC
                                                    LIMIT 1]){
                    contextLoginHistory = loopLoginHistory;
                }

                // retrieve VerificationHistory of the current user for email
                if(contextLoginHistory != null){
                    for(VerificationHistory loopVerificationHistory : [SELECT Id, SourceIp, LoginHistory.Browser FROM VerificationHistory WHERE UserId = :userId AND Status = 'Succeeded'
                                                                            AND LoginHistory.SourceIp = :contextLoginHistory.SourceIp AND VerificationMethod IN ('SMS','Email') ORDER BY VerificationTime DESC]){
                        // check per browser
                        if(contextLoginHistory.Browser == loopVerificationHistory.LoginHistory.Browser) verificationHistoryList.add(loopVerificationHistory);
                    }
                    contextLoginDeviceHash = (contextLoginHistory.SourceIp + contextLoginHistory.Browser).hashCode();
                }
                
                // determine if the user has the permission required to initiate mfa
                Boolean hasAlumni2FAPermission = FeatureManagement.checkPermission('Alumni_Experience_2FA');
                Boolean hasMyApp2FAPermission = FeatureManagement.checkPermission('MyApplication_Experience_2FA');

                // retrieve all eligible mfa challenge countries
                String challengeCountriesString = Label.Activate_MFA_Locations;
                Set<String> challengeCountriesSet = new Set<String>();
                if(!String.isBlank(challengeCountriesString)){
                    for(String loopCountry: Label.Activate_MFA_Locations.split(';')){
                        challengeCountriesSet.add(loopCountry.toLowerCase());
                    }
                }

                if(contextUser != null){
                    // the user have not logged in yet before
                    if(contextUser.Last_2FA_Login__c == null){
                        doBypass = true;
                    }
                    
                    // skip challenge if device address already verified
                    if(!verificationHistoryList.isEmpty()){
                        doBypass = true;

                        // do not skip challenge on change password
                        if(contextUser.Last_2FA_Login__c != null && contextUser.Last_2FA_Login__c < contextUser.LastPasswordChangeDate){
                            doBypass = false;
                        }
                        
                        // do not skip challenge if the user do not have a verified mobile number - even they are on a recognized IP address + browser
                        if(verifiedInfos != null && verifiedInfos.HasUserVerifiedMobileNumber == false){
                            doBypass = false;
                        }
                    }

                    // skip challenge if user registered with external service and last device == this device
                    if(contextUser.MFA_Mobile_Verified_External__c == true &&
                       contextLoginDeviceHash == contextUser.Last_2FA_Login_Device__c) {
                            doBypass = true;
                    }

                    // skip challenge if user does not have 2fa custom permissions
                    if(!hasAlumni2FAPermission && !hasMyApp2FAPermission){
                        doBypass = true;
                    }

                    // skip challenge if the login location is outside the challenged countries ONLY for My.App Users NOT Ascend Users
                    String experienceURL = Network.getLoginUrl(Network.getNetworkId());
                    Boolean ascendUser = false;
                    Boolean myappUser = false;
                    if(String.isNotBlank(experienceURL) && (experienceURL.containsIgnoreCase('admissions') || experienceURL.containsIgnoreCase('myapp'))){
                        myappUser = true;
                    }  
                    if(String.isNotBlank(experienceURL) && (experienceURL.containsIgnoreCase('ascendportal') || experienceURL.containsIgnoreCase('alumni'))){
                        ascendUser = true;
                    }
                    if((!Test.isRunningTest() && !ascendUser && !challengeCountriesSet.contains(contextLoginHistory.LoginGeo.Country) && !challengeCountriesSet.contains('all')) || String.isBlank(challengeCountriesString)){
                        doBypass = true;
                    }

                    // skip the challenge if the community they are logging in to is not alumni portal or my.app portal
                    if(!ascendUser && !myappUser){
                        doBypass = true;
                    }

                    //checking if the user is from my.app and phone number is sanctioned
                    if(myappUser && contextUser.Contact.Phone != null) {
                        List<String> compoundMobileNumber = contextUser.Contact.Phone.split(' ');
					    String countryCode = compoundMobileNumber[0];
                        if(new CountriesSelector().isSanctionedBySFDC(countryCode)) {
                            doBypass = false;
                        }
                    }
                }

                // parameter bypass for autotest usage
                String bypassParameter = ApexPages.currentPage().getParameters().get('ByPass');
                if(bypassParameter != null){
                    ExperienceMFASetting__c mfaSetting = ExperienceMFASetting__c.getInstance();
                    doBypass = mfaSetting != null && mfaSetting.Autotest_Bypass_Key__c != null && bypassParameter.containsIgnoreCase(mfaSetting.Autotest_Bypass_Key__c);
                }
            }catch(Exception ex){
                Nebula.Logger.error('ExperienceMFAServices.determineByPassTwoFactor '+ex.getMessage(), ex);
                Nebula.Logger.saveLog();
            } 
            return doBypass;
        }
    }

    // Create Twilio verification wrapper
    Public static OneTimeTokenService.OneTimeTokenWrapper otpWrapper(String code, String identifier) {
        OneTimeTokenService.OneTimeTokenWrapper wrapper = new OneTimeTokenService.OneTimeTokenWrapper();
        wrapper.VerificationSid = identifier.split(MFA_OTP_SEPARATOR)[0];
        wrapper.ServiceSid = identifier.split(MFA_OTP_SEPARATOR)[1];
        wrapper.Code = code;
        return wrapper;
    }

    // For use in test class
    Private static OneTimeTokenService.OneTimeTokenWrapper TEST_OTP_WRAPPER() {
        OneTimeTokenService.OneTimeTokenWrapper wrapper = new OneTimeTokenService.OneTimeTokenWrapper();
        wrapper.VerificationSid = '1234567890';
        wrapper.ServiceSid = '1234567890';
        wrapper.To = '+61412345678';
        wrapper.Code = '';
        return wrapper;
    }

    // Are we running in a test class
    private static Boolean isTst() {
        if (Test.isRunningTest()) {
            return true;
        }
        return false;
    }

    private static Map<String,String> unsafeUserInputMessage() {
        return ExperienceAuthenticationServices.userMessage(ExperienceAuthenticationServices.RESULT_TYPE_ERROR,ExperienceAuthenticationServices.MESSAGE_UNSAFE_INPUT);
    }
}