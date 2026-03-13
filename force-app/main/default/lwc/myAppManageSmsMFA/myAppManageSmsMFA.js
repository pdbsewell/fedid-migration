/* eslint-disable @lwc/lwc/no-api-reassignments */
import { LightningElement, api, track,wire } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { FlowNavigationFinishEvent } from 'lightning/flowSupport';

import retrieveCurrentUserDetails from '@salesforce/apex/ExperienceMFAServices.retrieveCurrentUserDetails';
import isSfdcSmsSupported from '@salesforce/apex/ExperienceMFAServices.isSfdcSmsSupported';
import sendEmailVerification from '@salesforce/apex/ExperienceMFAServices.sendEmailVerification';
import registerMFA from '@salesforce/apex/OTPGuard.registerMFA';
import verifyMFA from '@salesforce/apex/OTPGuard.verifyMFA';

import communityMyAppAssets from '@salesforce/resourceUrl/CommunityMyAppAssets';
import {createPhoneSplitter,startTimer} from 'c/util';

// import custom labels
import maxMFAEmailVerificationsPermitted from '@salesforce/label/c.MaxMFAEmailVerification';

export default class MyAppManageSmsMFA extends LightningElement {
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
    @track resourcesReady = false;
    @track isChallenging = false;
    @track phoneSplitter;

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

    get disableMobileNumberFields() {
        return this.showVerificationCode || this.isUpdateRequestMFA;
    }

    connectedCallback() {
        this.showSpinner = true;
        try {
            Promise.all([
                loadStyle(this, communityMyAppAssets + '/MonashStyling.css')
            ]).then(() => {
                this.resourcesReady = true;     
                retrieveCurrentUserDetails()
                    .then((result) => {
                    this.hasVerified = result.HasVerified;
                    this.loadCountryList(result.allCountries);
                    if(this.hasVerified){
                        if (result.MobileNumber) {
                            // Split the phone number into country code and local number
                            this.phoneSplitter =  createPhoneSplitter(result.allCountries);
                            let phoneData = this.phoneSplitter(result.MobileNumber,result.MobileNumberCountry);
                            console.log('phoneData: ', phoneData);
                            const _mfaVerifiedNum = result.MobileNumber;
                            const mfaEvent = new CustomEvent('mfafetched', {
                                detail: { _mfaVerifiedNum },
                                bubbles: true,
                                composed: true
                            });
                            this.dispatchEvent(mfaEvent);
                            // let splitNumber = result.MobileNumber.split(' ');
                            //reflect server value to ui                    
                            this.countryCode = phoneData.countryName+' '+phoneData.countryCodeDisplay
                            this.selectedCountryCode = phoneData.countryCode;
                            this.mobileNumber = phoneData.localNumber;
                            this.mobileNumberCountry = phoneData.countryName;
                            this.userEmail = result.Email;
                            //store server value    
                            this.currentCountryCode = phoneData.countryCode;
                            this.currentMobileNumber = phoneData.localNumber;
                            this.currentMobileNumberCountry = phoneData.countryName;
                        }
                    }
                    this.showSpinner = false;
                })
                .catch((error) => {
                    console.error('Error retrieving user details: ', error);
                    this.showSpinner = false;
                });
            });
        }catch (error) {
            console.error('Error in connectedCallback: ', error);
            this.showSpinner = false;
        }
        
    }
    /**
     * load country list
     * @param {Array} allCountries - The list of all countries.
     * @returns {void}
     */
    loadCountryList(allCountries) {
        this.countries = allCountries;
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
    }

    /**
     *  @description - iniatiate the challenge for the user for sms verification via SFDC
     *  @returns {void}
     */
    initiateChallenge() {
        this.showSpinner = true;
        registerMFA({
            countryCode: '',
            phoneNumber: '',
            mobilePhoneCountry: '',
            registerMethod: 'SFDC_INIT'
        })
        .then((result) => {
            // If result is an object with Identifier, otherwise assign directly
            if (result && result.Identifier) {
                this.identifier = result.Identifier;
            } else {
                this.identifier = result;
            }
            this.showSpinner = false;
        })
        .catch((error) => {
            this.showSpinner = false;
            console.error(error);
            if(error.body.message){
                this.errorWarningMessages = error.body.message;
            }
        });
    }
    /**
     * *  @description - iniatiate the challenge for the user for email verification
     *  @returns {void}
     */
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
    /**
     * 
     * @param {*} countryPhoneCode 
     * @returns 
     */
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

    disconnectedCallback() {
        if (this.timerHandle) {
            this.timerHandle.stop();
        }
    }
    timeVal;
    startCountDownTimer(countdown) {
        if (this.timerHandle) {
            this.timerHandle.stop();
        }
        this.timerHandle = startTimer(countdown, ({ seconds, formattedTime }) => {
            this.countdownTimer = seconds;
            if (seconds <= 0) {
                console.log('Timer finished');
                this.countdownTimer = false;
            }
            this.timeVal = formattedTime;
        });
    }  

    /* let the user confirm - update mfa */
    confirmUpdateMFA() {
        this.errorWarningMessages = '';
        this.hasSuccessfulRegistration = false;
        this.isResendCode = false;
        if(this.hasVerified){
            // initiate confirmation if theres existing verified number
            let hasErrors = this.validateEntries();
            if(!hasErrors){
                this.isUpdateRequestMFA = true;
            }
        }else{
            this.sendVerificationCode();
        }        
    }

    /* cancel mfa update confirmation */
    cancelUpdateMFA() {
        // revert mobile number to the registered mobile number
        this.isResendCode = false;
        this.countryCode = this.currentMobileNumberCountry + ' ' + this.currentCountryCode;
        let thisContent = this;
        this.template.querySelectorAll("c-input-type-ahead").forEach(function(element) {
            element.value = thisContent.countryCode;
        });
        
        this.selectedCountryCode = this.currentCountryCode;
        this.mobileNumber = this.currentMobileNumber;
        this.mobileNumberCountry = this.currentMobileNumberCountry;
        this.isUpdateRequestMFA = false;        
    }

    /* cancel mfa mobile number registration */
    cancelRegistration(){
        this.isResendCode = false;
        this.showVerificationCode = false;
        this.selectedCountryCode = '';
        this.mobileNumber = '';
        this.mobileNumberCountry = '';
        this.countryCode = '';
        this.selectedCountryCode = undefined;
        this.template.querySelectorAll("c-input-type-ahead").forEach(function(element) {
            element.clearValue();
        });
    }

    /* send verification code */
    sendVerificationCode() {
        // reset verification status
        this.hasVerified = false;
        // hide confirmation question
        this.isUpdateRequestMFA = false;
        // check country codes
        if(!this.selectedCountryCode.includes('+')){
            this.selectedCountryCode = '+' + this.selectedCountryCode;
        }
        // check if the number has been changed before invoking the process
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
        //this.logger.info('initiating challenge');
        registerMFA({
            countryCode : this.selectedCountryCode,
            phoneNumber : this.mobileNumber,
            mobilePhoneCountry: this.mobileNumberCountry,
            registerMethod:'SFDC_REGISTER'
        })
        .then(result => {
            this.identifier = result;
            this.showVerificationCode = true;
            this.showSpinner = false;
        })
        .catch(error =>{
            console.error(error);
            if(error.body.message){
                this.errorWarningMessages = error.body.message;
            }
            this.showSpinner = false;
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
        }
        
        return hasErrors;
    }

    /* send verification code */
    requestResendVerificationCode() {
        // start timer
        this.startCountDownTimer(60);
        this.showSpinner = true;
        this.errorWarningMessages = '';

        if(!this.isChallenging){
            // invoke send verification code method
            this.isResendCode = true;
            registerMFA({
                countryCode : this.selectedCountryCode,
                phoneNumber : this.mobileNumber,
                mobilePhoneCountry: this.mobileNumberCountry,
                registerMethod:'FALLBACK_REGISTER'
            })
            .then(result => {
                this.identifier = result;
                this.showVerificationCode = true;
                this.showSpinner = false;
            })
            .catch(error =>{
                console.error(error);
                if(error.body.message){
                    this.errorWarningMessages = error.body.message;
                }
                this.showSpinner = false;
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
            this.showSpinner = true;
            if(!this.isChallenging){
                // when on registration verify code - invoke send verification code method
                if (!this.isResendCode) {
                    verifyMFA({
                        identifier: this.identifier,
                        verificationCode: this.verificationCode,
                        startUrl: this.startUrl ? this.startUrl : '',
                        verifyType: 'SFDC_VERIFY'
                    })
                    .then(result => {
                        this.showSpinner = false;
                        if ((result === null || result === '') && this.startUrl === undefined) {
                            this.hasVerified = true;
                            this.showVerificationCode = false;
                            this.verificationCode = '';

                            //store saved country code and mobile number                
                            this.currentCountryCode = this.selectedCountryCode;
                            this.currentMobileNumber = this.mobileNumber;
                            this.currentMobileNumberCountry = this.mobileNumberCountry;
                            this.hasSuccessfulRegistration = true;
                            this.finishFlow();
                        } else {
                            if(result === 'Token not valid'){
                                this.verificationCodeError = '* You have entered an incorrect verification code';
                            }
                        }
                    })
                    .catch(error =>{
                        if(error.body && error.body.message){
                            this.errorWarningMessages = error.body.message;
                        }
                        console.error(error);
                        this.showSpinner = false;
                    });
                } else { // use fallback service
                    this.verifyVerificationCodeFallback();
                }
            } else {
                // when on login flow - invoke send verification code method
                verifyMFA({
                    identifier: this.identifier,
                    verificationCode: this.verificationCode,
                    startUrl: this.startUrl ? this.startUrl : '',
                    verifyType: 'SFDC_CHALLENGE'
                })
                .then(result => {
                    this.showSpinner = false;
                    if(result && result.Status === 'success'){
                        this.finishFlow();
                    }else{
                        this.errorWarningMessages = result && result.Message ? result.Message : 'Verification failed.';
                    }
                })
                .catch(error =>{
                    if(error.body && error.body.message){
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
        verifyMFA({
            identifier : this.identifier,
            verificationCode : this.verificationCode,
            startUrl: this.startUrl ? this.startUrl : '',
            verifyType: 'FALLBACK_VERIFY'
        })
        .then(result => {
            this.showSpinner = false;
            if((result === null || result === '') && this.startUrl === undefined){
                this.hasVerified = true;
                this.showVerificationCode = false;
                this.verificationCode = '';

                //store saved country code and mobile number                
                this.currentCountryCode = this.selectedCountryCode;
                this.currentMobileNumber = this.mobileNumber;
                this.currentMobileNumberCountry = this.mobileNumberCountry;
                this.hasSuccessfulRegistration = true;

                this.finishFlow();
            }else{
                if(result === 'Token not valid'){
                    this.verificationCodeError = '* You have entered an incorrect verification code';
                }
            }
        })
        .catch(error =>{
            if(error.body.message){
                this.errorWarningMessages = error.body.message;
            }
            console.error(error);
            this.showSpinner = false;
        });
    }

    /* check field details and return if there are issues */
    validateConfEntries() {
        let hasErrors = false;
        this.errorWarningMessages = '';
        //check if the number has been changed before invoking the process
        if(isNaN(this.verificationCode)){
            this.verificationCodeError = 'Please enter the numeric confirmation code received on your mobile.';
            hasErrors = true;
        }        
        return hasErrors;
    }

    /* verification code */
    verificationCodeChange(event){
        this.verificationCode = event.target.value;
    }

    /* verification code - numerical only */
    verificationCodeNumericOnly(event){
        // Only ASCII character in that range allowed
        let isNumeric = true;
        var ASCIICode = (event.which) ? event.which : event.keyCode
        if (ASCIICode > 31 && (ASCIICode < 48 || ASCIICode > 57)){
            isNumeric =  false;
        }
        if(!isNumeric){
            event.preventDefault();
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
    
    /* mobile number - numerical only */
    mobileChangeNumericOnly(event){
        // Only ASCII character in that range allowed
        let isNumeric = true;
        var ASCIICode = (event.which) ? event.which : event.keyCode
        if (ASCIICode > 31 && (ASCIICode < 48 || ASCIICode > 57)){
            isNumeric =  false;
        }
        if(!isNumeric){
            event.preventDefault();
        }
    }

    /* redirect the user to community home page */
    redirectHome() {
        window.location.href = '/admissions/s/';
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
        //let countryCode = event.detail.value;
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
}