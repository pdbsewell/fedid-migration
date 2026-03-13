/**
 * @author			Inderpal Dhanoa
 * @group			ERDA
 * @description		Handlers for Submit Alumni Enquiry.
 */
public with sharing class SubmitAlumniEnquiryCntlr { 
    private static final string CACHE_NAMESPACE = 'ALUMNIENQUIRYFORM';
    private static final string ERROR_PROCESSING_REQUEST = 'An unexpected donation processing error occured.';

    /**
    * @description Method to create Enquiry             
    * @param firstName                      param for first name
    * @param lastName                      param for last name
    * @param enqType                      param for enquiry type
    * @param email                          param for email
    * @param details                      param for enquiry details
    * @param detailsPlainText                  param for details as Plain Text
    * @return  String         String of result                 
    */
    @AuraEnabled
    public static string createAlumniEnquiry(String firstName, String lastName, String enqType, String email, String details, String detailsPlainText){
        try {
            // Check if User has entered the details
            Alumni_Enquiry__c alumniEnq = new Alumni_Enquiry__c();
            alumniEnq.Subject__c = enqType;
            alumniEnq.Description__c = detailsPlainText;
            alumniEnq.Rich_Description__c = details;
            alumniEnq.SuppliedEmail__c = email; 
            alumniEnq.Enquiry_Type__c = enqType;
            insert alumniEnq;
            GetLinkedCase fetchEnq = new GetLinkedCase();
            return fetchEnq.sendEmail(email, firstName, LastName, enqType);
        } catch (Exception e) {
            Nebula.Logger.error(e.getMessage(), e);Nebula.Logger.saveLog();throw new AuraHandledException('Error while creating Enquiry: ' + e.getMessage());
        }
    }

    /**
    * @description Simulate a callout to the Twilio to send the Email             
    * @param receipient                     email adress of receipient
    * @param channel                        email as mode of info
    * @return  String         String of verification ID and Service Id                 
    */
    @AuraEnabled
    public static String sendCode(String receipient, String channel) {
        String errorMessage; Map<String, Object> donationFormParams = new Map<String, Object>{'rateLimitKey' => 'REQ_GUEST_OTP' + receipient};
        try {
            if(!IPCheckExceedsLimit(donationFormParams, 'Alumni Donate Form OTP')){
                OneTimeTokenService.OneTimeTokenWrapper resp = OneTimeTokenService.sendOtp(receipient, channel);
                putOtpRequestInCache(resp.verificationSid, receipient);
                return resp.verificationSid + ',' + resp.serviceSid;
            }else{
                errorMessage = 'Rate Limit Exceeded';throw new AuraHandledException(ERROR_PROCESSING_REQUEST);
            }            
        }
        catch (Exception e) {
            Nebula.Logger.error(e.getMessage(), e);Nebula.Logger.saveLog();throw new AuraHandledException('Error sending otp code: ' + (String.isBlank(errorMessage) ? e.getMessage() : errorMessage));
        }
    }

    /**
    * @description verify Pass Code entered
    * @param formData		  Map of String and String for form Data
    */
    @AuraEnabled
    public static void verifyPassCode(Map<String, String> formData) {
        String errorMessage; Map<String, Object> donationFormParams = new Map<String, Object>{'rateLimitKey' => 'VER_GUEST_OTP' + formData.get('emailSMS')};
        try {
            if(!IPCheckExceedsLimit(donationFormParams, 'Alumni Donate Form OTP')){
                // Verify otp code sent for this contact point
                if (isVerifiedContactPoint(String.valueof(formData.get('verificationSid')), String.valueof(formData.get('serviceSid')), String.valueof(formData.get('emailSMS')), String.valueof(formData.get('otpCode')))){
                    donationFormParams = new Map<String, Object>{'rateLimitKey' => 'VER_GUEST_OTP' + formData.get('emailSMS')};resetRateLimit(donationFormParams, 'Alumni Donate Form OTP');
                    donationFormParams = new Map<String, Object>{'rateLimitKey' => 'REQ_GUEST_OTP' + formData.get('emailSMS')};resetRateLimit(donationFormParams, 'Alumni Donate Form OTP');
                }else{
                    errorMessage = 'Unverified Contact Point';throw new AuraHandledException('Unverified Contact Point');  
                }
            }else{
                errorMessage = 'Rate Limit Exceeded';throw new AuraHandledException(ERROR_PROCESSING_REQUEST);
            }
        } catch (Exception e) {
            Nebula.Logger.error(e.getMessage(), e);Nebula.Logger.saveLog();throw new AuraHandledException('Error submitting pass code: ' + (String.isBlank(errorMessage) ? e.getMessage() : errorMessage));
        }
    }

    /**
    * @description IPCheckExceedsLimit : check IP limit. 
    * @param donationFormParams Map                               Key value pair of Donation params 
    * @return Boolean if the IP check clears    
    */
    private static Boolean IPCheckExceedsLimit(Map<String, Object> donationFormParams, String rateLimitUtilityName){
        IP_RateLimitUtility rateLimit = generateKeyAndObject(donationFormParams, rateLimitUtilityName);
        return rateLimit.exceedsRateLimit();
    }

    /**
    * @description resetRateLimit : Reset the rate limit. 
    * @param  donationFormParams Map                               Key value pair of Donation params  
    */
    private static void resetRateLimit(Map<String, Object> donationFormParams, String rateLimitUtilityName){
        IP_RateLimitUtility rateLimit = generateKeyAndObject(donationFormParams, rateLimitUtilityName);        
        rateLimit.resetRateLimit();
    }

    /**
    * @description generateKey : generate the Key based on Custom MetaData. 
    * @param donationFormParams Map                               Key value pair of Donation params
    * @param rateLimitUtilityName Custom settings value for IP Rate limit utility
    * @return     IP_RateLimitUtility wrapper object
    */
    private static IP_RateLimitUtility generateKeyAndObject(Map<String, Object> donationFormParams, String rateLimitUtilityName){
        String key = donationFormParams.containsKey('rateLimitKey') ? String.valueOf(donationFormParams.get('rateLimitKey')) : '';
        IP_RateLimitUtility rateLimit;
        if(String.isBlank(key)){
            rateLimit = new IP_RateLimitUtility(rateLimitUtilityName); // 'Alumni Form'
        }else{
            rateLimit = new IP_RateLimitUtility(rateLimitUtilityName, key); 
        } 
        return rateLimit;
    }

    /**
    * @description Method to put request in Cache
    * @param verificationSid		  verification Sid received from Twilio
    * @param contactPoint       	  Id for Content Point ID* 
    */
    private static void putOtpRequestInCache(String verificationSid, String contactPoint) {
        // Cache key-value pair in Org Cache
        String cacheKey = CACHE_NAMESPACE + generateCacheKey(verificationSid);
        String cacheValue = contactPoint;
        Cache.Org.put(cacheKey, cacheValue);
    }

    /**
    * @description Method to check request in Cache
    * @param verificationSid		  verification Sid received from Twilio
    * @param contactPoint       	  Id for Content Point ID* 
    * @return Boolean is request in Cache
    */
    private static boolean isOtpRequestInCache(String verificationSid, String contactPoint) {
        Boolean isInCache = false;

        // Check is cached key-value pair exists in Org Cache
        String cacheKey = CACHE_NAMESPACE + generateCacheKey(verificationSid);
        if (Cache.Org.contains(cacheKey)) {
            String cachedContactPoint = (String) Cache.Org.get(cacheKey);
            isInCache = (cachedContactPoint == contactPoint);
        }
        return isInCache;
    }

    /**
    * @description Method to generate Cache Key
    * @param token		  TOekn generated
    * @return String return of Key
    */
    private static String generateCacheKey(String token) {
        // Get the hash code of the string
        Integer hashCode = token.hashCode();

        // Make sure the hash code is positive
        Integer positiveHashCode = Math.abs(hashCode);

        // return the string version of the hashcode
        return String.valueOf(positiveHashCode);
    }

    /**
    * @description Method to verify OTP
    * @param verificationSid		  verification Sid received from Twilio
    * @param ServiceSid		          Service Sid received from Twilio
    * @param contactPoint       	  Id for Content Point ID
    * @param otpCode    	          String for One time passcode
    * @return Boolean return of verified OTP
    */
    private static boolean isVerifiedContactPoint(String verificationSid, String ServiceSid, String contactPoint, String otpCode) {
        // Does verification request id match the contact point it was generated for?
        if (!isOtpRequestInCache(verificationSid, contactPoint)) {
            return false;
        }
        // Does the submitted code match the one sent to the users contact point?
        OneTimeTokenService.OneTimeTokenWrapper tokenRequest = new OneTimeTokenService.OneTimeTokenWrapper();
        tokenRequest.Code = otpCode; tokenRequest.VerificationSid = verificationSid; tokenRequest.ServiceSid = serviceSid;
        return OneTimeTokenService.verifyOtp(tokenRequest); 
    }

    /**
    * @author Inderpal Dhanoa
    * @date 3 08 2024
    * @description Class retrieves in Without Sharing to retrireve the linked ENquiry
    **/
    private without sharing class GetLinkedCase{
        /**
        * @author Inderpal Dhanoa
        * @date 3 08 2024
        * @description Method rto send Email
        * @param suppliedEmail Supplied EMail 
        * @param firstName Desc of First Name
        * @param lastName desc of last Name 
        * @param enqType Type of Enquiry
        * @param recdTypeId Rec Type Id
        * return String of the result
        **/
        private String sendEmail(String suppliedEmail, String firstName, String lastName, String enqType){
            Id recdTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Alumni_Engagement').getRecordTypeId();
            Case alumniEnq = [SELECT CaseNumber FROM Case WHERE Subject = :enqType
                              AND SuppliedEmail = :suppliedEmail 
                              AND RecordTypeId = :recdTypeId 
                              ORDER BY CreatedDate DESC LIMIT 1];
            Map<String, String> enqTypeByEmailTempDevName = createMapping();
            if(enqTypeByEmailTempDevName.containsKey(enqType)){
                List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
                List<OrgWideEmailAddress> owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'am-noreply@f.e.monash.edu']; 
                List<EmailTemplate> unReadEmailAlert = [SELECT Id, Subject, Htmlvalue FROM EmailTemplate WHERE Developername = :enqTypeByEmailTempDevName.get(enqType)];
                String htmlBody = unReadEmailAlert[0].HtmlValue;
                // Create a new Email Message
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

                // If the Email template does not exist then do not send out Emails
                if(String.isNotBlank(htmlBody)){
                    htmlBody = htmlBody.replace('{!Receiving_User.FirstName}', firstName);
                    htmlBody = htmlBody.replace('{!$Setup.PORTAL_UCIN_Domain_Name__c.Domain_Name__c}', generateDomainURL()); 
                    htmlBody = htmlBody.replace('{!$Organization.Id}', String.valueOf(UserInfo.getOrganizationId()));
                    mail.setSubject(unReadEmailAlert[0].Subject + ', ' + firstName + ' - ENQ #' + alumniEnq.CaseNumber);
                    mail.setToAddresses(new String[]{suppliedEmail});
                    mail.setHtmlBody(htmlBody);
                    mail.saveAsActivity = false;
                    mail.setOrgWideEmailAddressId(owea[0].Id);
                    mail.setWhatId(alumniEnq.Id);
                    mails.add(mail);
                } 
                //Queue emails
                if(!mails.isEmpty()){
                    if(!Test.isRunningTest()){
                        Messaging.sendEmail(mails);
                    }
                }
            }
            
            return String.valueOf(alumniEnq.CaseNumber);
        }

        /**
        * @author Inderpal Dhanoa
        * @date 3 08 2024
        * @description Method fetch Org URL
        * @return String of the result
        **/
        private String generateDomainURL(){
            PORTAL_UCIN_Domain_Name__c cs = PORTAL_UCIN_Domain_Name__c.getInstance();
            return String.valueOf(cs.Domain_Name__c);
        }

        /**
        * @author Inderpal Dhanoa
        * @date 3 08 2024
        * @description Method creates a mapping of results
        * @return Map<String, String> of the result
        **/
        private Map<String, String> createMapping(){
            Map<String, String> enqTypeByEmailTempDevName = new Map<String, String>();
            String[] enqTypeEmailArr;
            for(String enqTypeEmail : Label.Alumni_Enq_Type_Email.split(';')){
                enqTypeEmailArr = enqTypeEmail.split(':');
                enqTypeByEmailTempDevName.put(enqTypeEmailArr[0], enqTypeEmailArr[1]);
            }
            return enqTypeByEmailTempDevName;
        }
    } 
}