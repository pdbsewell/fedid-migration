// General LWC modules
import { wire, api, track, LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

// Modules for detecting record changes
import { getRecord } from 'lightning/uiRecordApi';
import CONTACT_MOBILE_FIELD from '@salesforce/schema/Contact.MobilePhone';
import CONTACT_EMAIL_FIELD from '@salesforce/schema/Contact.Email';
import CASE_CONTACT_FIELD from '@salesforce/schema/Case.ContactId';

// Module for getting running user Id
import Id from '@salesforce/user/Id';

// Modules for Lightning Message Service features
import { publish, subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';
import otpVerificationChannel from "@salesforce/messageChannel/OtpVerificationChannel__c";

// Module to check custom permissions 
import hasCacheResetPermission from '@salesforce/customPermission/Access_OTP_ID_Verification_Cache_Reset';

// OTPService Apex Controller methods 
import publishPlatformEvent from "@salesforce/apex/OTPService.publishPlatformEvent";
import postToRecord from "@salesforce/apex/OTPService.postToRecord";
import getContactOtpAddresses from "@salesforce/apex/OTPService.getContactOtpAddresses";
import setVerificationCache from "@salesforce/apex/OTPService.setVerificationCache";
import clearVerificationCache from "@salesforce/apex/OTPService.clearVerificationCache";
import isVerificationCached from "@salesforce/apex/OTPService.isVerificationCached";
import getVerificationCacheDateTime from "@salesforce/apex/OTPService.getVerificationCacheDateTime";

// OneTimeTokenService Apex Controller methods 
import sendOtpCode from "@salesforce/apex/OneTimeTokenService.sendOtp";
import verifyOtpCode from "@salesforce/apex/OneTimeTokenService.verifyOtp";

export default class OtpGenerator extends LightningElement {
    
    // Passed into component
    @api recordId;
    @api title = 'Contact Unverified';
    @api iconName = 'utility:identity';

    // Design time variables
    @api verifyAddresses;       // Verify the contact addresses (phone, email, etc) using external service (e.g. Experian)
    @api enableEmailFallback;   // Enables email to be used as an address if no valid mobile numbers exist for contact
    @api expiryTimer;           // Time in seconds to wait for otp to be entered by agent 
    @api verificationCacheTtl;  // Time in seconds to cache verification for the contact 

    // Lightning message service variables
    @wire(MessageContext)
    messageContext;
    @track subscription = null;
    @track otpMessage = '';
    @track receivedMessage = '';

    // *** CONSTANTS ***

    MSG_NO_CONTACT = 'Contact not found for this page';
    MSG_VERIFICATION_SOURCE_ANOTHER_PAGE = 'another page';
    MSG_VERIFICATION_SOURCE_SOFTPHONE = 'softphone';

    EXPIRY_TIMER_DEFAULT = 60; // Default time in seconds to wait for otp to be entered by agent 
    CACHE_SECS_MIN = 300;

    // Verification channels
    CHANNEL_SMS = 'sms';                // Twilio SMS
    CHANNEL_EMAIL = 'email';            // Twilio email
    CHANNEL_PAGE = 'page';              // Contact verified on another page
    CHANNEL_SOFTPHONE = 'softphone';    // Future use

    // Possible states
    STATE_INACTIVE = 'inactive';
    STATE_VERIFIED = 'verified';
    STATE_UNVERIFIED = 'unverified';
    STATE_WAITING_CODE_ENTRY = 'waiting';
    STATE_ERROR = 'error';

    // Platform and LMS event types
    OTP_EVT_SENT = 'SENT';
    OTP_EVT_PREVERIFIED = 'PREVERIFIED';
    OTP_EVT_VERIFIED = 'VERIFIED';
    OTP_EVT_FAILED = 'FAILED';
    OTP_EVT_MANUAL_EMAIL_FALLBACK = "EMAILFALLBACK";
    OTP_EVT_MANUAL_SMS_FALLFORWARD = "SMSFALLFORWARD";

    CONTACT_PREXIX = '003';

    DUMMY_ADDRESSES = true;
    REAL_ADDRESSES = false;

    // Controls state of UI
    @track state;
    @track waitingForServer = false;
    @track expiryTimerId = null;       // Id of expiry timer;
    @track refreshCounter;
    @track counter=1;
    @track errMsg;
    @track error;

    // Variables (I realise we dont need @track, but no harm)
    @track picklistOptions = [];// Selectable Otp Addresses
    @track userId = Id;         // Id of running user
    @track contactId;           // Contact to which the OTP relates
    @track channel;             // Channel to send otp to (sms or email)
    @track verificationSource;  // Channel contact was verified by
    @track selectedAddress;     // The selected mobile number or email address
    @track mobileNumbers = [];  // List of valid otp mobile numbers
    @track emailAddresses = []; // List of valid otp email addresses
    @track tokenWrapper = {     // Wraps the otp code, sids, etc needed by otp sending utility
        'Code' : '',
        'VerificationSid' : '',
        'ServiceSid' : ''
    };        
    @track verificationCacheEnabled = false;    // Deterimines if verification status is cached
    @track lastVerification = '';               // Time of last verification hh:mm am|pm

    // The below is used to detect page record changes 
    // If certain fields change we need to refresh the component
    // e.g where contact is changed on case record
    @wire(getRecord, { 
        recordId: '$recordId', 
        fields: [],
        optionalFields: [CONTACT_MOBILE_FIELD, CONTACT_EMAIL_FIELD, CASE_CONTACT_FIELD]
    })
    getTheRecord({ data, error }) {
        if (data) {
            if (this.isContactChanged(data)) {
                this.transitionToStartUpState();
            }
        }
    }

    // Start here!
    connectedCallback() {

        // Ensure OTP entry expiry timer is correctly set
        if (!this.expiryTimer || this.expiryTimer <= 0) {
            this.expiryTimer = EXPIRY_TIMER_DEFAULT;
        }

        // Ensure cache and ttl is correctly set
        if (this.verificationCacheTtl && (this.verificationCacheTtl >= this.CACHE_SECS_MIN)) {
            this.verificationCacheEnabled = true;
            console.log('@@##$$ Verification cache is enabled: validity period = ' + this.verificationCacheTtl);
        }

        // Subscribe to verification events from other pages
        this.subscribeLMS();    

        // Setup initial state
        this.state = this.STATE_INACTIVE;

        this.transitionToStartUpState();
    }

    // *** STATE TRANSITION METHODS ***

    // Determine initial state of component and switch to it
    // 1. Already verified
    // 2. Inactive (wait for user to press button to start verification)
    // 3. Error - something bad happened
    async transitionToStartUpState() {
        this.waitingForServer = true;
        // Check we have a contact to actually verify
        this.contactId = await this.getContact();
        if (!this.contactId) {
            this.transitionToErrorState(this.MSG_NO_CONTACT);
            return;
        }

        // Now transition to either 'already verified state' or the inactive state
        if (await this.isAlreadyVerified()) {
            this.transitionToPreVerifiedState();
        } else {
            this.transitionToInactiveState();
        }
        this.waitingForServer = false;
    }

    // Set componant to inactive state - waits for user to press button to start verification
    transitionToInactiveState() {
        this.state = this.STATE_INACTIVE;
        this.logState();
    }

    // Display that contact has been verified already (and is within validity period)
    transitionToPreVerifiedState() {
        this.getPreverificationTime();
        this.notifyPreVerified(this.getPreverificationSource()); 
        this.state = this.STATE_VERIFIED;
        this.logState();
    }

    // Set contact to verified state
    transitionToVerifiedState() {
        this.setContactVerified(); // Cache the verification status, if caching enabled
        this.notifyVerified(); 
        this.state = this.STATE_VERIFIED;
        this.logState();
    }

    // Activate verification panel
    // Will transition to SMS or Email verification depending on 
    // what OTP-valid mobile or email addresses are found on the contact
    transitionToActiveState() {
        this.waitingForServer = true;               // Show spinner while we are waiting on the server
        getContactOtpAddresses({
            recordId: this.recordId,
            verifyAddresses: this.verifyAddresses,  // Controls if Experian used to verifiy addresses
            dummyAddresses: false                   // false = get real addresses from contact
        }).then(res => {
            
            // load up mobile and/or email addresses of contact
            this.initSmsChannel(res);
            this.initEmailChannel(res);

            // Now figure out whether to switch SMS or Email

            // Priority is SMS channel...
            if (this.validSmsChannel()) {
                this.transitionToSmsState();
                return;
            }
            // ...fallback is email
            if (this.validEmailChannel()) {
                this.transitionToEmailState();
                return;
            }
            // No valid channel - error baby!
            this.transitionToErrorState(res)
        }).catch(error => {
            this.handleError(error);
        }).finally(() => {
            this.waitingForServer = false;      // // Hide spinner now server activity is complete
        });
    }

    // Setup to send otp to SMS channel
    transitionToSmsState() {
        console.log('@@##$$ transition to SMS');
        this.selectedAddress = this.mobileNumbers[0]; // default is first number in list
        this.channel = this.CHANNEL_SMS;
        this.setupPicklist(this.mobileNumbers);
        this.state = this.STATE_UNVERIFIED;
        this.logState();
    }

    // Setup to send otp to email channel
    transitionToEmailState() {
        console.log('@@##$$ transition to EMAIL');
        this.selectedAddress = this.emailAddresses[0]; // default
        this.channel = this.CHANNEL_EMAIL;
        this.setupPicklist(this.emailAddresses);
        this.state = this.STATE_UNVERIFIED;
        this.logState();
    }

    // User sent OTP code to contact 
    transitionToWaitingForCodeState(resp) {
        this.waitingForServer = true;
        this.state = this.STATE_WAITING_CODE_ENTRY;
        this.tokenWrapper.VerificationSid = resp.VerificationSid;
        this.tokenWrapper.ServiceSid = resp.ServiceSid;
        this.logToken('@@##$$ sendOtp: response');              
        this.notifyOtpSent();
        this.startExpiryTimer();
        this.logState();
        this.waitingForServer = false;
    }

    // Setup error state 
    transitionToErrorState(res) {
        this.waitingForServer = true;
        this.errMsg = this.getErrorMsg(res);
        this.state = this.STATE_ERROR;
        this.logState();
        this.waitingForServer = false;
    }

    // *** MAIN METHODS ***

    // Is verification for this contact cached
    async isAlreadyVerified() {

        // Nothing good can happen without a contactId
        if (!this.contactId) {
            return false;
        }

        // If verification cache is disabled, then clear it for the contact
        if (!this.verificationCacheEnabled) {
            console.log('@@##$$ isAlreadyVerified: verification cache is disabled, clearing existing cache');
            this.clearContactVerified();
            return false;
        }

        try {
            // Now reach into the cache and see if contact has been pre-verified
            const isVerificationCachedResult = await isVerificationCached({contactId: this.contactId});
            console.log('@@##$$ isAlreadyVerified: cached contact verification state is: '+ isVerificationCachedResult);
            return isVerificationCachedResult;

        } catch(error) {
            this.handleError(error);
            return false;
        }
    }

    // Initilises mobile numbers if valid mobile numbers found for this contact
    // 'res' is Wrapper returned from OTPService
    // res.sms.contactId        Id of contact
    //        .mobileNumbers[]  List of valid mobile numbers 
    //        .result           success | error
    //        .error            Contains error message if result = error
    initSmsChannel(res) {
        // If there are no valid mobile numbers then assign empty array
        if ((!res.sms) || (res.sms.result == 'error')) {
            this.mobileNumbers = [];
            return;
        }
        if (!res.sms.mobileNumbers || res.sms.mobileNumbers.length == 0) {
            this.mobileNumbers = [];
            return;
        }
        // We have valid mobile numbers
        this.mobileNumbers = [...res.sms.mobileNumbers];
    }

    // Returns true if there valid email addresses found for this contact
    // 'res' is Wrapper returned from OTPService
    // res.email.contactId        Id of contact
    //          .emailAddresses[] List of valid email addresses 
    //          .result           success | error
    //          .error            Contains error message if result = error
    initEmailChannel(res) {
        // If there are no valid email addresses then assign empty array
        if (this.enableEmailFallback == false) {
            return false;
        }
        if ((!res.email) || (res.email.result == 'error')) {
            return false;
        }
        if (!res.email.emailAddresses || res.email.emailAddresses.length == 0) {
            return false;
        }
        // We have valid email addresses
        this.emailAddresses = [...res.email.emailAddresses];
    }

    // Returns true if there valid mobile numbers found for this contact
    validSmsChannel() {
        return (this.mobileNumbers.length > 0);
    }

    // Returns true if there valid email addresses found for this contact
    validEmailChannel() {
        return (this.emailAddresses.length > 0);
    }

    // Send otp to contact via currently selected channel and address
    sendCodeToContact() {
        this.state = this.STATE_WAITING_CODE_ENTRY;
        this.waitingForServer = true;
        this.resetTokenWrapper();
        console.log('@@##$$ sending otp code -> ' + 'channel:' + this.channel + ', address: ' + this.selectedAddress);
        sendOtpCode({
            toAddress: this.selectedAddress,
            channel: this.channel
        }).then(resp => {
            this.transitionToWaitingForCodeState(resp);
        }).catch(error => {
            this.handleError(error);
        });
    }

    // Give agent a time-limit to enter the code from the contact
    startExpiryTimer() {
        this.stopExpiryTimer(); // Only allow one timrer at a time
        this.expiryTimerId=setInterval(function() {
            if(this.refreshCounter==1) {
                this.counter = 1;
                this.refreshCounter = 0;
                this.handleTimerExpired();
                clearInterval(interval);
            }
            this.refreshCounter = this.expiryTimer - (this.counter++);
        }.bind(this), 1000);
    }

    stopExpiryTimer() {
        if (this.expiryTimerId) {
            this.counter = 1;
            this.refreshCounter = 0;
            clearInterval(this.expiryTimerId);
            this.expiryTimerId = null;
        }
    }

    // Is verification for this contact cached **TODO - replace with isAlreadyVerified
    async isPreVerified(res) {

        // Make sure we have a contact id   
        if (!res.sms && !res.sms.contactId && !res.sms.contactId.startsWith(this.CONTACT_PREXIX)) {
            console.log('@@##$$ isPreVerified: no contact id');
            return false;
        }
        this.contactId = res.sms.contactId;

        // If verification cache is disabled, then clear it for the contact
        if (!this.verificationCacheEnabled) {
            console.log('@@##$$ isPreVerified: verification cache is disabled, clearing existing cache');
            this.clearContactVerified();
            return false;
        }

        try {
            // Now reach into the cache and see if contact has been pre-verified
            const isVerificationCachedResult = await isVerificationCached({contactId: this.contactId});
            console.log('@@##$$ isPreVerified: verification cache for contact is: '+ isVerificationCachedResult);
            return isVerificationCachedResult;

        } catch(error) {
            this.handleError(error);
            return false;
        }
    }

    // *** EVENT HANDLERS ***

    // User clicked the Verify button to show verification panel
    handleActivateVerification() {
        this.transitionToActiveState();
    }

    // User clicked cancel to close verification panel
    handleCancelVerification() {
        this.transitionToInactiveState();
    }

    // User clicked the Refresh button on verified or error panel
    handleRefreshVerification() {
        this.transitionToStartUpState();
    }

    // OTP-code-entry timer expired
    handleTimerExpired() {
        // Only do someting is we were waiting for code
        if (this.state == this.STATE_WAITING_CODE_ENTRY) {
            this.transitionToStartUpState();
        }
    }

    // Clicked email fallback checkbox
    handleEmailFallback(event) {
        // this.value = event.target.checked;        
        console.log("handleEmailFallback: " + event.target.checked);
        this.publishEvt(this.OTP_EVT_MANUAL_EMAIL_FALLBACK);
        this.transitionToEmailState();
    }

    // Clicked email fallback checkbox
    handleSmsFallforward(event) {
        // this.value = event.target.checked;        
        console.log("handleSmsFallforward: " + event.target.checked);
        this.publishEvt(this.OTP_EVT_MANUAL_SMS_FALLFORWARD);
        this.transitionToSmsState();
    }

    // User selected an alternative otp address
    handleAddressChange(event) {
        this.selectedAddress = event.detail.value;
    }

    // Handle verification events received from another components (or other instances of this component)
    // In future this could include verification events published by the Softphone
    handleLMSMessage(message) {
        this.receivedMessage = message ? JSON.stringify(message, null, '\t') : 'no message payload';
        console.log('@@##$$ received otp LMS event' + this.receivedMessage);

        // Dont respond to messages from myself
        if (message.sourceRecordId == this.recordId) {
            return;
        }
        // If this verification event relates to my contact, 
        // then re-init the component to refresh the cached verification status
        if (message.contactId == this.contactId) {
            if (message.eventType == this.OTP_EVT_VERIFIED || this.OTP_EVT_FAILED) {
                console.log('@@##$$ returning component to startup state');
                this.transitionToStartUpState();
            }
        }
    }

    handleError(error) {
        if (error.body != undefined) { // Apex error
            this.error = error.body.message;
        } else {
            this.error = error;
        }
        console.error(error);
        this.transitionToErrorState(null);
    }

    // Translate error messages from Apex into human useful form
    translateApexErrorMessage(msg) {
        let translatedmessage = this.getFromRegexKeys (msg);
        return translatedmessage ? translatedmessage : msg;
    }

    getFromRegexKeys(key, map) {
        // Map of Apex error messages to human useful messages
        const APEX_ERROR_MSG = new Map([
            // Twilio errors
            ["Max send attempts reached", "Max send attempts reached for this contact. Please retry in 10 minutes"],
            ["Too many requests", "Too many send requests. Please contact UniCRM admins"],
            [/^Invalid parameter.*To/, `Can't ${this.channel} code to ${this.selectedAddress}. Check format or select another number.`]
        ]);

        for (const [re, val] of APEX_ERROR_MSG.entries()) {
            const res = key.match(re);
            if (res) return val;
        }
    }

    async getContact() {
        let contactId = null;
        try {
            const res = await getContactOtpAddresses({
                recordId: this.recordId,
                verifyAddresses: this.verifyAddresses,
                dummyAddresses: true  // true = use dummy addresses to avoid overheads
            });
            if (res.sms && res.sms.contactId) {
                contactId = res.sms.contactId;
            }
        } catch(error) {
            this.handleError(error);
        }
        return contactId;
    }

    isContactChanged(record) {
        if (record.fields && record.fields.ContactId) {
            if (record.fields.ContactId.value != this.contactId) {
                console.log('@@##$$ Contact changed on parent record from:' + this.contactId + ' to: ' + record.fields.ContactId.value);
                return true;
            }
        }
        return false;
    }

    getPreverificationTime() {
        this.lastVerification = '';
        getVerificationCacheDateTime({
            contactId: this.contactId
        }).then(res => {
            // extract time part xx/xx/xx hh:mm am|pm
            const dt = res.split(" ");
            if (dt.length == 3) {
                this.lastVerification = dt[1] + dt[2].toLowerCase();
                console.log('@@##$$ last verification time = ' + this.lastVerification);
            }
        })
    }

    getPreverificationSource() {
        //**TODO store pre-verification source in cache and return this instead of hardcoded value
        // Future source may include softphone or self-service verification
        return this.MSG_VERIFICATION_SOURCE_ANOTHER_PAGE;
    }

    // Set verification cache for this contact
    setContactVerified() {
        if (this.contactId && this.verificationCacheEnabled) {
            setVerificationCache({
                contactId: this.contactId,
                ttlSecs: this.verificationCacheTtl
            }).then(resp => {
                console.log('@@##$$ verification cache set for: ' + this.contactId + ' ttl: ' + this.verificationCacheTtl);
                this.getPreverificationTime();          
            }).catch(error => {
                this.handleError(error);
            });
        }
    }

    // Clear verification cache for this contact
    clearContactVerified() {
        this.clearIdCache(this.contactId);
        this.notifyCacheCleared();
    }

    clearIdCache(contactId) {
        clearVerificationCache({
            contactId: contactId
        }).then(resp => {
            console.log('@@##$$ verification cache cleared for: ' + contactId);              
        }).catch(error => {
            this.handleError(error);
        });
    }

    // Figure out what error message to show based on context
    getErrorMsg(res) {
        if(res == null) { // Apex error
            return this.translateApexErrorMessage(this.error);
        }

        if ((typeof res) == 'string') {
            return res;
        }

        if (!res.sms.contactId || res.sms.contactId == '') {
            return this.MSG_NO_CONTACT;
        }
        if (!res.sms.mobileNumbers || res.sms.mobileNumbers.length == 0) {
            if (this.enableEmailFallback == true) {
                return 'No valid mobile numbers or email addresses found for this Contact';
            } else {
                return 'No valid mobile numbers found for this Contact';
            }
        }
    }

    // Populate address picklist 
    setupPicklist(theValues) {
        this.picklistOptions  = [];
        for (let i=0; i < theValues.length; i++){
            let anOption = {label: theValues[i], value: theValues[i]};
            this.picklistOptions.push(anOption);
        }
    }

    verifyOTP() {
        // Get code entered by agent
        var input=this.template.querySelector('.verify');
        var otp=input.value;

        // If we have a code let's verify it
        if(otp!=undefined && otp!==null) {
            this.tokenWrapper.Code = otp;
            verifyOtpCode({
                tokenRequest: this.tokenWrapper
            }).then(res => {
                // Code matches
                if(res == true) {
                    this.transitionToVerifiedState();
                }
                // Code does not match
                else {
                    input.focus();
                    this.selectText(input);
                    this.clearContactVerified();
                    this.notifyNotVerified();
                }
            }).catch(error => {
                this.handleError(error);
            });
        }
    }

    notifyOtpSent() {
        postToRecord({
            recordId: this.recordId,
            message: 'OTP Verification - code sent to contact at: ' + this.obfuscatedAddress()
        });
        this.publishLMS(this.OTP_EVT_SENT);
        this.publishEvt(this.OTP_EVT_SENT);
        this.showMessage('Notification', 'Code sent to contact', 'success');
    }

    notifyPreVerified(verificationSource) {
        console.log('@@##$$ pre-verification is complete');
        postToRecord({
            recordId: this.recordId,
            message: 'OTP Verification - contact already verified via: ' + verificationSource
        });
        this.publishEvt(this.OTP_EVT_PREVERIFIED);
    }

    notifyVerified() {
        postToRecord({
            recordId: this.recordId,
            message: 'OTP Verification - code verification is complete'
        });
        this.publishLMS(this.OTP_EVT_VERIFIED);
        this.publishEvt(this.OTP_EVT_VERIFIED);
        this.showMessage('Notification', 'Code verification is complete', 'success');
    }

    notifyNotVerified() {
        console.log('@@##$$ verification not complete - code did not match');
        this.logToken('@@##$$ token state');
        postToRecord({
            recordId: this.recordId,
            message: 'OTP Verification - code did not match'
        });
        this.publishLMS(this.OTP_EVT_FAILED);
        this.publishEvt(this.OTP_EVT_FAILED);
        this.showMessage('Notification', 'Code does not match, please try again', 'error');
    }

    notifyCacheCleared() {
        console.log('@@##$$ verification cache cleared');
        // Only show toast if user has cache clearing perm
        if (hasCacheResetPermission) {
            this.showMessage('Notification', 'Verification cache cleared', 'success');
        }
    }

    publishEvt (evtType) {
        publishPlatformEvent({
            userId: this.userId,
            recordId: this.recordId,
            contactId: this.contactId,
            eventType: evtType,
            channel: this.isEvtShowNone(evtType) ? 'NONE' : this.channel,
            address: this.isEvtShowNone(evtType) ? 'NONE' : this.obfuscatedAddress()
        });
    }

    isEvtShowNone (evtType) {
        return (
            (evtType == this.OTP_EVT_PREVERIFIED) ||
            (evtType == this.OTP_EVT_MANUAL_EMAIL_FALLBACK) ||
            (evtType == this.OTP_EVT_MANUAL_SMS_FALLFORWARD) 
        );
    }

    publishLMS(evtType) {
        const message = {
            eventType: evtType,
            contactId: this.contactId,
            sourceRecordId: this.recordId
        };
        publish(this.messageContext, otpVerificationChannel, message);
    }

    subscribeLMS() {
        if (this.subscription) {
            return;
        }
        this.subscription = subscribe(
            this.messageContext, 
            otpVerificationChannel, 
            (message) => { this.handleLMSMessage(message);},
            {scope: APPLICATION_SCOPE}
        );
    }

    unsubscribeLMS() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    selectText(el) {
        el.selectionStart = 0 ;
        if(el.value){
            el.selectionEnd = el.value.toString().length ;
        }else{
            el.selectionEnd = 0 ;
        }
    }

    showMessage( t, m,type ){
        const toastEvt = new ShowToastEvent({
            title: t,
            message:m,
            variant: type
        });
        this.dispatchEvent(toastEvt);
    };

    resetTokenWrapper() {
        this.tokenWrapper = {     // Wraps the otp code, sids, etc needed by otp sending utility
            'Code' : '',
            'VerificationSid' : '',
            'ServiceSid' : ''
        };  
    }

    obfuscatedAddress() {

        let obfuscatedAddess = this.selectedAddress.slice().toLowerCase();
        const PHONE_CHARS_TO_OBFUSCATE = 4;
        const EMAIL_CHARS_TO_OBFUSCATE = 4;
        const REPLACEMENT_CHAR = 'X';

        // For SMS, x out all last N digits
        if (this.channel ==this.CHANNEL_SMS) {
            for (let i=0; i < this.selectedAddress.length - PHONE_CHARS_TO_OBFUSCATE; i++) {
                obfuscatedAddess = this.replaceAt(obfuscatedAddess, REPLACEMENT_CHAR.toLowerCase(), i);
            }
        } 

        // For Email x out N characters either side of the @ 
        if (this.channel == this.CHANNEL_EMAIL) {
            let emailParts = this.selectedAddress.split("@");
            if (emailParts.length == 2) {
                // Part 1 - before the @
                let startIndex = Math.max(emailParts[0].length - EMAIL_CHARS_TO_OBFUSCATE, 0); // 
                for (let i=startIndex; i < emailParts[0].length; i++) {
                    emailParts[0] = this.replaceAt(emailParts[0], REPLACEMENT_CHAR, i);
                }
                // Part 2 - after the @
                let endLen = Math.min(emailParts[1].length, EMAIL_CHARS_TO_OBFUSCATE); // 
                for (let i=0; i < endLen; i++) {
                    emailParts[1] = this.replaceAt(emailParts[1], REPLACEMENT_CHAR, i);
                }    
                obfuscatedAddess = emailParts[0] + '@' + emailParts[1];
            }
        }

        return obfuscatedAddess;
    }

    replaceAt(str, char, index) {
        return (
            str.substring(0, index) +
            char +
            str.substring(index + 1)
        )
    }

    logState() {
        console.log('OTP State = ' + this.state + ', Channel = ' + this.channel + ', Contact = ' + this.contactId);
    }

    logToken(msg) {
        console.log(msg);
        let tokenLog = {
            "Code" : this.tokenWrapper.Code,
            "VerificationSid" : this.tokenWrapper.VerificationSid,
            "ServiceSid": this.tokenWrapper.ServiceSid
        }
    }

    // Getters

    get otpChannel() {
        return this.channel;
    }

    get isShowEmailFallback() {
        return ((this.channel == this.CHANNEL_SMS) && 
                (this.enableEmailFallback == true)) && 
                (this.validEmailChannel());
    }

    get isShowSmsFallforward() {
        return ((this.channel == this.CHANNEL_EMAIL) && 
                (this.validSmsChannel()));
    }

    get options() {
        return this.picklistOptions;
    }

    get ringCounter() {
        return (100 / this.expiryTimer) * this.refreshCounter;
    }

    get ringVariant() {
        if (this.refreshCounter < (this.expiryTimer * 0.1)) {   // Red at 10% to go
            return 'expired'
        }
        if (this.refreshCounter < (this.expiryTimer * 0.25)) {  // Orange at 25% to go
            return 'warning'
        }
        return 'base';
    }

    get isInactive() {
        return (this.state == this.STATE_INACTIVE);
    }

    get isLoading() {
        return (this.waitingForServer == true);
    }

    get isUnverified() {
        return (this.state == this.STATE_UNVERIFIED);
    }

    get isShowCancel() {
        return (this.state == this.STATE_UNVERIFIED || this.state == this.STATE_WAITING_CODE_ENTRY);
    }

    get isShowRefresh() {
        return (this.state == this.STATE_VERIFIED || this.state == this.STATE_ERROR);
    }

    get isShowWaitingForCode() {
        return (this.state == this.STATE_WAITING_CODE_ENTRY && this.waitingForServer == false);
    }

    get isShowExpiryTimer() {
        return (this.refreshCounter > 0);
    }

    get isShowErrorPanel() {
        return (this.state == this.STATE_ERROR && this.waitingForServer == false);
    }

    get isVerified() {
        return (this.state == this.STATE_VERIFIED && this.waitingForServer == false);
    }

    get isCacheResetEnabled() {
        return hasCacheResetPermission;
    }

    get isError() {
        return (this.state == this.STATE_ERROR);
    }

    get defaultAddress() {
        if (this.channel == this.CHANNEL_SMS) {
            return this.mobileNumbers[0];
        }
        if (this.channel == this.CHANNEL_EMAIL) {
            return this.emailAddresses[0];
        }
    }

    get toAddress() {
        return this.selectedAddress;
    }

    get cardIcon() {
        if (this.state == this.STATE_VERIFIED) {
            return "action:approval";
        } else {
            return this.iconName;
        }
    }

    get cardTitle() {
        if (this.state == this.STATE_VERIFIED) {
            return "Contact Verified";
        } else {
            return this.title;
        }
    }

    get cardSize() {
        if (this.state == this.STATE_VERIFIED) {
            return "xx-small";
        } else {
            return 'small';
        }
    }

    get cardBackground() {
        return (this.state == this.STATE_VERIFIED) ? 'otp-id-verified slds-m-bottom_none' : 'otp-id-unverified slds-m-bottom_none';
    }

    get lastVerifyTime() {
        return ((this.lastVerification || (this.lastVerification.length > 0)) ? this.lastVerification : '');
    }
}