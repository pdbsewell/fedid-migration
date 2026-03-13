/**
* @author       P.Sewell
* @date         09/Dec/2022
* @description  Service class to handle OTP component
* @revision
*               09.Dec.22 P.Sewell - Create Class
**/
public class OTPService {
	
    // Constants
    static final String CACHE_KEY_PREFIX = 'OTP';
    static final List<String> FAKE_MOBILES = new List<String> {'+61491570156'};
    static final List<String> FAKE_EMAILS = new List<String> {'test@example.com'};


    // Wrapper to hold valid otp destination addresses
    public class ContactOtpAddresses {
        @auraenabled public ContactMobileNumbers sms;
        @auraenabled public ContactEmailAddresses email;
    } 

    // Mobile numbers
    public class ContactMobileNumbers {
        @AuraEnabled public String result;
        @AuraEnabled public String error;
        @AuraEnabled public String contactId;
        @AuraEnabled public List<String> mobileNumbers;

        Id recordId;
        Boolean verifyAddresses;
        Boolean dummyAddresses;

        // Find valid mobile numbers for this contact
        public ContactMobileNumbers(Id recordId, Boolean verifyAddresses, Boolean dummyAddresses) {
            this.recordId = recordId;
            this.verifyAddresses = verifyAddresses;
            this.dummyAddresses = dummyAddresses;
            this.result = 'error';                                          // default
            this.error = 'No valid mobile numbers found for this contact';  // default
            this.contactId = '';                                            // default
            this.mobileNumbers = new List<String>();

            // Get contact
            Contact theContact = getContact(recordId);
            if (theContact == null) {
                setError('Contact not found for this page');
                return;
            }
            this.contactId = theContact.Id;

            // Get mobile numbers for the contact
            List<String> theMobileNumbers = (dummyAddresses == true) ? FAKE_MOBILES : getMobileNumbers(this.contactId, this.verifyAddresses);
            if (theMobileNumbers == null || theMobileNumbers.size() == 0) {
                setError('No valid mobile numbers found for this contact');
                return;
            }

            // All good, so add the numbers and mark success
            this.mobileNumbers.addAll(theMobileNumbers);
            setSuccess();      
        }

        private void setError (String errMsg) {
            this.result = 'error';
            this.error = errMsg;
        }

        private void setSuccess () {
            this.result = 'success';
            this.error = '';
        }
    }

    public class ContactEmailAddresses {
        @AuraEnabled public String result;
        @AuraEnabled public String error;
        @AuraEnabled public String contactId;
        @AuraEnabled public List<String> emailAddresses;

        Id recordId;
        Boolean verifyAddresses;
        Boolean dummyAddresses;

        // Find valid email addresses for this contact
        public ContactEmailAddresses(Id recordId, Boolean verifyAddresses, Boolean dummyAddresses) {
            this.recordId = recordId;
            this.verifyAddresses = verifyAddresses;
            this.dummyAddresses = dummyAddresses;
            this.result = 'error';                                          // default
            this.error = 'No valid email addresses found for this contact'; // default
            this.contactId = '';                                            // default
            this.emailAddresses = new List<String>();

            // Get contact
            Contact theContact = getContact(recordId);
            if (theContact == null) {
                setError('Contact not found for this page');
                return;
            }
            this.contactId = theContact.Id;

            // Get email addresses for the contact - dummy addresses for the moment
            // List<String> theEmailAddresses = new List<String>{'peter.sewell@monash.edu', 'peter@sewell.id.au'};

            List<String> theEmailAddresses = (dummyAddresses == true) ? FAKE_EMAILS : getEmailAddresses(this.contactId, this.verifyAddresses);
            if (theEmailAddresses == null || theEmailAddresses.size() == 0) {
                setError('No valid email addresses found for this contact');
                return;
            }

            // All good, so add the email addresses and mark success
            this.emailAddresses.addAll(theEmailAddresses);
            setSuccess();      
        }

        private void setError (String errMsg) {
            this.result = 'error';
            this.error = errMsg;
        }

        private void setSuccess () {
            this.result = 'success';
            this.error = '';
        }
    }

    @AuraEnabled(cacheable=false)
    public static ContactOtpAddresses getContactOtpAddresses(Id recordId, Boolean verifyAddresses, Boolean dummyAddresses) {
        ContactOtpAddresses cntOtpAddresses = new ContactOtpAddresses();
        cntOtpAddresses.sms = new ContactMobileNumbers(recordId, verifyAddresses, dummyAddresses);
        cntOtpAddresses.email = new ContactEmailAddresses(recordId, verifyAddresses, dummyAddresses);
        return cntOtpAddresses;
    }

    @AuraEnabled(cacheable=false)
    public static void postToRecord(Id recordId, String message) {
        try {
            FeedItem objPost = new FeedItem();
            objPost.ParentId = recordId;
            objPost.Body = message;
            insert objPost;
        } catch(DmlException e) {
            //LogUtilityException.debug('Could not insert feeditem to record: ' + e.getMessage());
            LogUtilityException.logException (e);
        }
    }

    @AuraEnabled(cacheable=false)
    public static void setVerificationCache(String contactId, Integer ttlSecs) {
        DateTime dt = DateTime.now();
        Cache.Org.put(CACHE_KEY_PREFIX + contactId, dt, ttlSecs);
    }

    @AuraEnabled(cacheable=false)
    public static string getVerificationCacheDateTime(String contactId) {
        String cachedDateTime = '';
        if (isVerificationCached(contactId)) {
            DateTime cachedDt = (DateTime)Cache.Org.get(CACHE_KEY_PREFIX + contactId);
            cachedDateTime = cachedDt.format();
        }
        return cachedDateTime;
    }

    @AuraEnabled(cacheable=false)
    public static void clearVerificationCache(String contactId) {
        Cache.Org.remove(CACHE_KEY_PREFIX + contactId);
    }

    @AuraEnabled(cacheable=false)
    public static Boolean isVerificationCached(String contactId) {
        return Cache.Org.contains(CACHE_KEY_PREFIX + contactId);
    }

    @AuraEnabled(cacheable=false)
    public static void publishPlatformEvent(
        String userId,
        String recordId,
        String contactId,
        String eventType,
        String channel,
        String address
    ) {
        publishPlatformEvent(
            userId,
            recordId,
            contactId,
            eventType,
            channel,
            address,
            '' // Blank Address Id
        );
    }

    public static void publishPlatformEvent(
        String userId,
        String recordId,
        String contactId,
        String eventType,
        String channel,
        String address,
        String addressId
    ) {
        List<OTP_Verification_Event__e> otpEvts = new List<OTP_Verification_Event__e>();
        try {
            OTP_Verification_Event__e otpEvt = 
                new OTP_Verification_Event__e (
                    User_Id__c = userId,
                    Record_Id__c = recordId,
                    Contact_Id__c = contactId,
                    Event_Type__c = eventType,
                    Channel__c = channel,
                    Address__c = address,
                    Address_Id__c = addressId
                );  
            otpEvts.add(otpEvt);
            
            if (otpEvts.size() > 0) {
                EventBus.publish(otpEvts);
            }
        } catch(Exception e) {
            LogUtilityException.logException (e);
        }  
    }

    private static List<String> getMobileNumbers(Id contactId, Boolean verifyAddresses) {
        List<String> mobileNumbers = new List<String>();

        // Collect all active Phone__c records
        String primaryNumber = '';
        List<String> nonPrimaryNumbers = new List<String>();
        for (Phone__c p : [SELECT Id, Name, Contact__c, Is_Active__c, Classification__c, Is_Primary__c, Primary_set_by__c, Channel__c, Verification_Status__c, Type__c 
                           FROM Phone__c
                           WHERE Contact__c = :contactId AND Is_Active__c = true AND Type__c = 'mobile'
                           ORDER BY Is_Primary__c desc, LastModifiedDate desc ]) { // Primary at the top, then sorted by most recently updated
            LogUtilityException.debug('@@##$$ unformatted number is:' + p.Name);
            String formattedNumber = getFormattedVerifiedNumber(p, verifyAddresses);
            LogUtilityException.debug('@@##$$ formatted number is:' + formattedNumber);
            if (string.isNotBlank(formattedNumber)) {
                if (p.Is_Primary__c) {
                    primaryNumber = formattedNumber;
                } else {
                    // Ensure no duplicates
                    if ((formattedNumber != primaryNumber) && !nonPrimaryNumbers.contains(formattedNumber)) {
                        nonPrimaryNumbers.add(formattedNumber);
                    }
                }
            }
            // Limit to 2 mobile numbers to avoid using up Experian verification credits
            if (((string.isNotBlank(primaryNumber) && nonPrimaryNumbers.size() == 1) || nonPrimaryNumbers.size() >= 2)) {
                break;
            }
        }

        // Put primary number at top of list...
        if (string.isNotBlank(primaryNumber)) {
            mobileNumbers.add(primaryNumber);
        }
        // ...then the rest
        mobileNumbers.addAll(nonPrimaryNumbers);

        return mobileNumbers;
    }

    private static String getFormattedVerifiedNumber(Phone__c p, Boolean verifyAddresses) {

        // Pre-format number
        String formattedNumber = phoneservices.formatphone(p.Name);

        // If number is tagged as 'verified' and 'mobile', no futher verification required
        Boolean alreadyVerified = (string.isNotBlank(p.Type__c) && 
                                   string.isNotBlank(p.Verification_Status__c) && 
                                   (p.Type__c.equalsIgnoreCase('mobile') && p.Verification_Status__c.startsWithIgnoreCase('verified')));

        // Now check we have a valid mobile number
        if(!alreadyVerified && (verifyAddresses == true)) {
            EDQPhoneNumberService stub = new EDQPhoneNumberService();
            EDQPhoneNumberDAO.PhoneNumberResponse response = stub.validatePhoneNumber(formattedNumber,'');
            if (response?.result?.phone_type == 'Mobile') {
                formattedNumber = response.result.formatted_phone_number;       // Valid mobile, woo hoo
                formattedNumber = phoneservices.formatphone(formattedNumber);   // Will ensure there is a space between country code and the number
                // Fire platform event to let someone who cares know we validated the number via Experian
                publishPlatformEvent(
                    UserInfo.getUserId(),
                    p.Contact__c,
                    p.Contact__c,
                    'experian',
                    'SMS',
                    formattedNumber,
                    p.Id
                );
            } else {
                formattedNumber = '';   // Not a valid mobile, make an empty string
            }
        } else {
            LogUtilityException.debug('@@##$$ Bypassing number verification');
        }

        // Exclude formatted numbers with country prefixes in the exclusion list
        formattedNumber = isCountryExcluded(formattedNumber) ? '' : formattedNumber;

        return formattedNumber;
    }

    // formattedNumber param must have been washed via phoneservices.formatphone();
    // i.e. must be in format '+nnn nnnnnnnnnn' (note the space between country code and number)
    private static Boolean isCountryExcluded(String formattedNumber) {
        Boolean retval = false;

        // Grab country prefix to test against exclusions
        String countryPrefix = formattedNumber.split(' ')[0];

        // Does countryPrefix match any prefix in our exclusion list
        OTP_Widget__c c = OTP_Widget__c.getInstance();
        if (c != null && String.isNotBlank(c.Country_Code_Exclusions__c)) {
            for (String excludedPrefix : c.Country_Code_Exclusions__c.split(',')) {
                if (countryPrefix == excludedPrefix) {
                    retval = true;
                    break;
                }
            }
        }

        return retval;
    }

    private static List<String> getEmailAddresses(Id contactId, Boolean verifyAddresses) {
        List<String> emailAddresses = new List<String>();

        // Collect all active Email__c records
        String primaryEmail = '';
        List<String> nonPrimaryEmails = new List<String>();
        for (Email__c e : [SELECT Id, Name, Is_Active__c, Classification__c, Is_Primary__c, Primary_set_by__c, Channel__c 
                           FROM Email__c
                           WHERE Contact__c = :contactId AND Is_Active__c = true]) {
            LogUtilityException.debug('@@##$$ unformatted email is:' + e.Name);
            String formattedEmail = makeFormattedEmail(e.Name, verifyAddresses);
            LogUtilityException.debug('@@##$$ formatted email is:' + formattedEmail);
            if (string.isNotBlank(formattedEmail)) {
                if (e.Is_Primary__c) {
                    primaryEmail = formattedEmail;
                } else {
                    // Ensure no duplicates
                    if ((formattedEmail != primaryEmail) && !nonPrimaryEmails.contains(formattedEmail)) {
                        nonPrimaryEmails.add(formattedEmail);
                    }
                }
            }
        }

        // Put primary number at top of list...
        if (string.isNotBlank(primaryEmail)) {
            emailAddresses.add(primaryEmail);
        }
        // ...then the rest
        emailAddresses.addAll(nonPrimaryEmails);

        return emailAddresses;
    }

    private static String makeFormattedEmail(String unformattedEmail, Boolean verifyAddresses) {

        // No email formatting as yet
        return unformattedEmail;
    }


    private static Contact getContact(Id recordId) {
        Contact theContact = null;
        Id contactId = recordId;
        
        // recordId can be a contact or a case
        String recType = recordId.getSobjectType().getDescribe().getName();
        if (recType == 'Case') {
            for (Case theCase : [SELECT ContactId FROM Case WHERE Id = :recordId]) {
                contactId = theCase.ContactId;
            }
        }

        // Get the contact
        List<String> fields = new List<String>(Contact.SObjectType.getDescribe().fields.getMap().keySet());
        String strWhereClause = ' Id = :contactId';
        //
        String soql = DynamicSoqlBuilder.getInstance()
               .showSOQLStatement(true)
               .setEnforced(false)
               .querySObject('Contact')
               .queryFields(new Set<String>(fields))
               .getQuery(strWhereClause);
        for (Contact c : (Contact[]) Database.query(soql)) {
            theContact = c;
        }

        if (theContact == null) {
            LogUtilityException.debug('@@##$$ contact not found for recordId ' + recordid);
        }

        return theContact;
    }
}