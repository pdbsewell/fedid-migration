import { LightningElement, api, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { FlowNavigationFinishEvent } from 'lightning/flowSupport';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import retrieveCurrentUserDetails from '@salesforce/apex/ExperienceMFAServices.retrieveCurrentUserDetails'; 
import isSfdcSmsSupported from '@salesforce/apex/ExperienceMFAServices.isSfdcSmsSupported';
import registerMobileNumber from '@salesforce/apex/ExperienceMFAServices.systemRegisterMobileNumber';
import sendSmsVerification from '@salesforce/apex/ExperienceMFAServices.sendSmsVerification';
import sendEmailVerification from '@salesforce/apex/ExperienceMFAServices.sendEmailVerification';
import verifyVerificationCode from '@salesforce/apex/ExperienceMFAServices.verifyVerificationCode';
import verifyMobileNumber from '@salesforce/apex/ExperienceMFAServices.verifyMobileNumber';
import registerMobileNumberFallback from '@salesforce/apex/ExperienceMFAServices.systemRegisterMobileNumberFallback';
import verifyMobileFallback from '@salesforce/apex/ExperienceMFAServices.verifyMobileNumberFallback';

// import custom labels
import maxMFAEmailVerificationsPermitted from '@salesforce/label/c.MaxMFAEmailVerification';

export default class AlumniManageSmsMFA extends LightningElement {
    @api startUrl;
    @api communityName;
    @api hasVerified = false;
    @api userId;
    @api origin;

    @track selectedCountryCode = '';
    @track countryCode = '';
    @track mobileNumber = '';
    @track mobileNumberCountry = '';
    @track renderEmailVerification = false;
    @track userEmail = '';
    @track identifier;
    @track verificationCode;
    @track currentCountryCode;
    @track currentMobileNumber;
    @track currentMobileNumberCountry;
    @track errorWarningMessages;
    @track countries;
    @track isEmailChallenge = false;
    @track isUpdateRequestMFA = false;	
    @track hasSuccessfulRegistration = false;	
    @track verificationCodeError;
    @track isResendCode = false;

    @track countdownTimer;
    @track showVerificationCode = false;
    @track showSpinner = false;
    @track mfaEnabledUser = false;
    @track isChallenging = false;
	@track renderDetails = false;
	@track disableDetails = false;

    get getButtonLabel() {
        return this.hasVerified || this.currentMobileNumber ? 'Update MFA' : 'Register MFA';
    }

    get lastFourDigits() {
        let lastFour = '';
        if (this.mobileNumber.length > 4) {
            lastFour = this.mobileNumber.substring(this.mobileNumber.length - 4);
        } 
        return lastFour;
    }

    get labelStyleClass() {
        let labelClass = 'slds-size_1-of-5';
        if(this.origin === 'LoginFlow'){
            labelClass = 'slds-size_5-of-5';
        }
        return labelClass;
    }

    get inputStyleClass() {
        let inputClass = 'slds-p-horizontal_small slds-size_4-of-5';
        if(this.origin === 'LoginFlow'){
            inputClass = 'slds-p-horizontal_small slds-size_5-of-5';
        }
        return inputClass;
    }

    connectedCallback(){
        this.showSpinner = true;
		this.onLoadGetCurrentUserDetails();
    }
	
	@api
    onLoadGetCurrentUserDetails(){
        this.errorWarningMessages = '';	
        retrieveCurrentUserDetails()
        .then((result) => {
            this.hasVerified = result.HasVerified; 
            this.renderDetails = result.HasVerified;
            this.mfaEnabledUser = result.MFAEnabledUser;
            this.countries = result.allCountries;
            if(this.mfaEnabledUser){
                if(this.hasVerified){
                    if(result.MobileNumber){
                        // Populate the country
                        let countryOptions = [];
                        this.countries.forEach(function(countryItem) {
                            // include country options
                            if(countryItem !== undefined){
                                countryOptions.push({ 
                                    label: countryItem.ShortName__c + ' (+' + countryItem.NumericPhoneCode__c + ')', 
                                    value: countryItem.ShortName__c + ' (+' + countryItem.NumericPhoneCode__c + ')'
                                });            
                            }
                        });
                        this.countryOption = countryOptions;

                        let splitNumber = result.MobileNumber.split(' '); 
                        //reflect server value to ui                    
                        let selectedCountry = this.findSelectedCountry(splitNumber[0]);
                        this.countryCode = result.MobileNumberCountry;
                        if(selectedCountry.NumericPhoneCode__c.includes('+')){
                            this.countryCode += ' (' + selectedCountry.NumericPhoneCode__c + ')';
                        }else{
                            this.countryCode += ' (+' + selectedCountry.NumericPhoneCode__c + ')';
                        }
						//Render the selected country code on the screen
                        let thisContent = this;
                        this.template.querySelectorAll("c-input-type-ahead").forEach(function(element) {
                            element.value = thisContent.countryCode;
                        });
                        this.selectedCountryCode = splitNumber[0];
                        this.mobileNumber = splitNumber[1];
                        this.mobileNumberCountry = result.MobileNumberCountry;
                        this.userEmail = result.Email;
    
                        //store server value
                        this.currentCountryCode = splitNumber[0];
                        this.currentMobileNumber = splitNumber[1];
                        this.currentMobileNumberCountry = result.MobileNumberCountry;
    
                        //initiate challenge flow if on login flow and is registered
                        if(this.origin === 'LoginFlow'){
                            if(this.hasVerified){
                                // determine whether the email verification link should be visible
                                console.log(maxMFAEmailVerificationsPermitted);
                                if(result.EmailVerificationCount == null || result.EmailVerificationCount == '' || result.EmailVerificationCount < maxMFAEmailVerificationsPermitted){
                                    this.renderEmailVerification = true;
                                }
                                
                                //show register mfa / challenge screen
                                this.isChallenging = true;
                                this.showVerificationCode = true;
                                this.initiateChallenge();
                            }
                        }
                    }
                }
            }
            this.showSpinner = false;
        })
        .catch((error) => {
            this.showSpinner = false;
        });
    }

    initiateChallenge(){
        this.showSpinner = true;
        sendSmsVerification()
        .then((result) => {
            this.identifier = result.Identifier;
            this.showSpinner = false;
        })
        .catch((error) => {
            this.showSpinner = false;
        });
    }

    initiateEmailChallenge(){
        this.showSpinner = true;
        sendEmailVerification()
        .then((result) => {
            this.identifier = result.Identifier;
            this.isEmailChallenge = true;
            this.showSpinner = false;
        })
        .catch((error) => {
            this.showSpinner = false;
        });
    }

    findSelectedCountry(countryPhoneCode){
        let selCountry = '';
        countryPhoneCode = countryPhoneCode.replace('+','');
        this.countries.forEach(function(countryItem) {
            // include country options
            if(countryItem !== undefined && countryItem.NumericPhoneCode__c === countryPhoneCode.trim()){
                selCountry = countryItem;            
            }
        });
        return selCountry;
    }

    renderedCallback() {}

    startTimer() {
        this.countdownTimer = 30;
        let thisContext = this;

        // Run timer code in every 100 milliseconds
        this.timeIntervalInstance = setInterval(function() {

            // Time calculations for hours, minutes, seconds and milliseconds
            var hours = Math.floor((thisContext.totalMilliseconds % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
            var minutes = Math.floor((thisContext.totalMilliseconds % (1000 * 60 * 60)) / (1000 * 60));
            var seconds = Math.floor((thisContext.totalMilliseconds % (1000 * 60)) / 1000);
            var milliseconds = Math.floor((thisContext.totalMilliseconds % (1000)));
            
            // Output the result in the timeVal variable
            thisContext.timeVal = hours + ":" + minutes + ":" + seconds + ":" + milliseconds;   
            
            thisContext.countdownTimer -= 1;

            if(thisContext.countdownTimer === 0){
                thisContext.countdownTimer = undefined;
                clearInterval(this.timeIntervalInstance);
            }
        }, 1000);
    }
    
    /* let the user confirm - update mfa */	
    confirmUpdateMFA() {	
        this.isResendCode = false;
        this.errorWarningMessages = '';	
        this.hasSuccessfulRegistration = false;	
        if(this.hasVerified){	
            // initiate confirmation if theres existing verified number	
            let hasErrors = this.validateEntries();	
            if(!hasErrors){	
                this.isUpdateRequestMFA = true;	
				this.disableDetails = true;
            }	
        }else{	
            this.sendVerificationCode();	
        }        	
    }	
    /* cancel mfa update confirmation */	
    cancelUpdateMFA() {
        this.isResendCode = false;
        // revert mobile number to the registered mobile number
        if(this.currentCountryCode.includes('+')){
            this.countryCode = this.currentMobileNumberCountry + ' (' + this.currentCountryCode + ')';
        }else{
            this.countryCode = this.currentMobileNumberCountry + ' (+' + this.currentCountryCode + ')';
        }
        let thisContent = this;
        this.template.querySelectorAll("c-input-type-ahead").forEach(function(element) {
            element.value = thisContent.countryCode;
        });
        
        this.selectedCountryCode = this.currentCountryCode;
        this.mobileNumber = this.currentMobileNumber;
        this.mobileNumberCountry = this.currentMobileNumberCountry;
        this.isUpdateRequestMFA = false; 
		this.disableDetails = false;		
    }

    /* send verification code */
    sendVerificationCode() {
        /*this.dispatchEvent(new CustomEvent(
            'testmethod', 
            {
                detail: { data:  'test'},
                bubbles: true,
                composed: true
            }
        ));*/
        this.isResendCode = false;
        //reset verification status
        this.hasVerified = false;
        // hide confirmation question	
        this.isUpdateRequestMFA = false;	
        // check country codes	
        if(!this.selectedCountryCode.includes('+')){	
            this.selectedCountryCode = '+' + this.selectedCountryCode;	
        }
        //check if the number has been changed before invoking the process
        let hasErrors = this.validateEntries();
        if(!hasErrors){
            this.showSpinner = true;
            this.errorWarningMessages = '';
            // invoke send verification code method
            isSfdcSmsSupported({
                countryCode :this.selectedCountryCode 
            })
            .then(sfdcSupported => {
                if (sfdcSupported) {
                    this.doSendVerification(); // Send code via SFDC SMS...
                } else {
                    this.requestResendVerificationCode(); // ...otherwise Twilio
                }
            })
            .catch(error =>{
                console.error(error);
            });
        }
    }

    doSendVerification() {
        registerMobileNumber({
            countryCode : this.selectedCountryCode,
            phoneNumber : this.mobileNumber,
            mobilePhoneCountry : this.mobileNumberCountry,
            resend : false
        })
        .then(result => {
            this.identifier = result;
            this.showVerificationCode = true;
            this.showSpinner = false;
        })
        .catch(error =>{
            console.error(error);
        });
    }

    /* check field details and return if there are issues */
    validateEntries() {
        let hasErrors = false;
                
        //check that the country code is populated before sending the request
        if(this.selectedCountryCode === '' || this.selectedCountryCode === undefined){
            this.errorWarningMessages = 'Please enter a country code to register for MFA.';
            hasErrors = true;
            return hasErrors;
        }
		
		if(this.currentCountryCode === this.selectedCountryCode && this.currentMobileNumber === this.mobileNumber){
            this.errorWarningMessages = 'Please enter a new country or mobile number to update your MFA.';
            hasErrors = true;
            return hasErrors;    
        }

        //check if the number has been changed before invoking the process
        if(!(this.currentCountryCode !== this.selectedCountryCode || this.currentMobileNumber !== this.mobileNumber || this.currentMobileNumberCountry !== this.mobileNumberCountry)){
            //show warning message saying the number should be changed before hitting the change mfa number
            this.errorWarningMessages = 'Please enter a new mobile number to update your MFA.';
            hasErrors = true;
            return hasErrors;
        }

        //check that the mobile number is populated before sending the request
        if(this.mobileNumber === '' || this.mobileNumber === undefined){
            this.errorWarningMessages = 'Please enter a new mobile number to register for MFA.';
            hasErrors = true;
			return hasErrors;
        }
		
		//check that the mobile number has the right format
		if(this.mobileNumber !== '' || this.mobileNumber !== undefined){
            let mobileNumberField = this.mobileNumber;
            if(mobileNumberField.includes("+") || mobileNumberField.includes(" ") || mobileNumberField.includes("-") || isNaN(mobileNumberField) || mobileNumberField.length > 15){
                this.errorWarningMessages = 'Please enter a valid mobile number.';
                hasErrors = true;
                return hasErrors;
            }
        }
        
        return hasErrors;
    }

    /* send verification code */
    requestResendVerificationCode() {
        // start timer
        this.startTimer();
        this.showSpinner = true;
        this.errorWarningMessages = '';

        if(!this.isChallenging){
            // invoke send verification code method
            this.isResendCode = true;
            registerMobileNumberFallback({
                countryCode : this.selectedCountryCode,
                phoneNumber : this.mobileNumber,
                mobilePhoneCountry : this.mobileNumberCountry
            })
            .then(result => {
                this.identifier = result;
                this.showVerificationCode = true;
                this.showSpinner = false;
            })
            .catch(error =>{
                console.error(error);
            });
        }else{
            if(!this.isEmailChallenge){
                this.initiateChallenge();
            }else{
                this.initiateEmailChallenge();
            }
        }
    }
    
    /* verify verification code */
    verifyVerificationCode() {
        this.errorWarningMessages = '';
        this.verificationCodeError = '';

        //check if the number has been changed before invoking the process
        let hasErrors = this.validateConfEntries();
        if(!hasErrors){
            if(!this.isChallenging){
                this.showSpinner = true;
                if (!this.isResendCode) {
                    // when on registration verify code - invoke send verification code method
                    verifyMobileNumber({
                        identifier : this.identifier,
                        verificationCode : this.verificationCode,
                        startUrl : this.startUrl ? this.startUrl : ''
                    })
                    .then(result => {
                        this.showSpinner = false;
                        if(result === null ){
                            if(this.startUrl === undefined){
                                this.hasVerified = true;
                                this.showVerificationCode = false;
                                this.verificationCode = '';
            
                                //store saved country code and mobile number                
                                this.currentCountryCode = this.selectedCountryCode;
                                this.currentMobileNumber = this.mobileNumber;

                                this.currentMobileNumberCountry = this.mobileNumberCountry;	
                                this.hasSuccessfulRegistration = true;
                                this.disableDetails = false;
                                this.finishFlow();
                            }                        
                        }else{
                            this.showToast('Unexpected Error', 'Incorrect code. Please try again.', 'error');
                        }
                    })
                    .catch(error =>{
                        if(error.body.message){
                            this.errorWarningMessages = error.body.message;
                            this.showToast('Unexpected Error', error.body.message, 'error');
                        }
                        console.error(error);
                        this.showSpinner = false;
                    });
                } else { // use fallback service
                    this.verifyVerificationCodeFallback();
                }
            }else{
                // when on login flow - invoke send verification code method
                verifyVerificationCode({
                    identifier : this.identifier,
                    verificationCode : this.verificationCode,
                    verificationMethod : (this.isEmailChallenge ? 'Email' : 'SMS')
                })
                .then(result => {
                    this.showSpinner = false;
    
                    if(result.Status === 'success'){
                        this.finishFlow();
                    }else{
                        this.errorWarningMessages = result.Message;
                    }
					this.disableDetails = false;
                })
                .catch(error =>{
                    if(error.body.message){
                        this.errorWarningMessages = error.body.message;
                    }
                    console.error(error);
                    this.showSpinner = false;
                });
            }
        }
    }

    /* verify verification code via fallback service */
    verifyVerificationCodeFallback() {
        verifyMobileFallback({
            identifier : this.identifier,
            verificationCode : this.verificationCode,
            startUrl : this.startUrl ? this.startUrl : ''
        })
        .then(result => {
            this.showSpinner = false;
            if(result === null || result === ''){
                if(this.startUrl === undefined){
                    this.hasVerified = true;
                    this.showVerificationCode = false;
                    this.verificationCode = '';

                    //store saved country code and mobile number                
                    this.currentCountryCode = this.selectedCountryCode;
                    this.currentMobileNumber = this.mobileNumber;

                    this.currentMobileNumberCountry = this.mobileNumberCountry;	
                    this.hasSuccessfulRegistration = true;
                    this.disableDetails = false;
                    this.finishFlow();
                }                        
            }else{
                this.showToast('Unexpected Error', 'Incorrect code. Please try again.', 'error');
            }
        })
        .catch(error =>{
            if(error.body.message){
                this.errorWarningMessages = error.body.message;
                this.showToast('Unexpected Error', error.body.message, 'error');
            }
            console.error(error);
            this.showSpinner = false;
        });
    }
    
    /* check field details and return if there are issues */
    validateConfEntries() {
        let hasErrors = false;

        //check if the number has been changed before invoking the process
        if(isNaN(this.verificationCode)){
            this.errorWarningMessages = 'Please enter the numeric confirmation code received on your mobile.';
            hasErrors = true;
        }        
        return hasErrors;
    }

    /* verification code */
    verificationCodeChange(event){
        this.verificationCode = event.target.value;
		if (event.which == 13) {
            // On Enter check the Verification code
            this.verifyVerificationCode();
        }
    }
    
    /* country code */
    countryCodeChange(event){
        this.selectedCountryCode = event.target.value;
    }
    
    /* mobile number */
    mobileChange(event){
        this.mobileNumber = event.target.value;
    }

    /* redirect the user to community home page */
    redirectHome() {
        window.location.href = '/ascendportal/s/'; 
    }

    handleCountryChange(event) {
        let thisContent = this;
        //on change pass focus to calendar
        if(event.detail.value !== ''){
            thisContent.template.querySelectorAll("c-input-type-ahead").forEach(function(element) {
                if(element.name === 'calendar'){                        
                    element.focus();
                }
            });  
        }

        //do filter
        this.changeCountry(event);
    }
    handleCountryKeyUp(event) {
        this.changeCountry(event);
    }

    changeCountry(event){
        let newValue = event.detail.value;
		if(newValue){
			if(newValue.includes('(+')){
				this.selectedCountryCode = newValue.split('(+')[1].replace(')', '');
				this.mobileNumberCountry = newValue.split(' (+')[0];
			}
		}else{
			this.selectedCountryCode = undefined;
		}
    }

    /* remove duplicates */
    removeDuplicates(collection) {
        return collection.filter(function(item, index){
            return collection.indexOf(item) >= index;
        });
    }

    finishFlow(){
        const navigateFinishEvent = new FlowNavigationFinishEvent();
        this.dispatchEvent(navigateFinishEvent);
    }
	
	/*
     * Method Name: showToast
     * Description: method to show toast
     */
    showToast(toastTitle, toastMessage, toastVariant) {
        const toast = new ShowToastEvent({
            title: toastTitle,
            message: toastMessage,
            variant: toastVariant,
        });
        this.dispatchEvent(toast);
    }
}