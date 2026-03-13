import { LightningElement, track, api, wire } from 'lwc';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import { NavigationMixin } from 'lightning/navigation';

/* APEX SERVICES */
import createAlumniEnquiry from "@salesforce/apex/SubmitAlumniEnquiryCntlr.createAlumniEnquiry";
import sendCode from "@salesforce/apex/SubmitAlumniEnquiryCntlr.sendCode";
import verifyPassCode from "@salesforce/apex/SubmitAlumniEnquiryCntlr.verifyPassCode";
import redirectURL from '@salesforce/label/c.Alumni_Redirect_Label';

export default class SubmitAlumniEnquiry extends NavigationMixin(LightningElement) {
    @track alumniEnquiryRecordTypeId;
    @track selectedEnqType = '';
    @track firstName = '';
    @track lastName = '';
    @track email = '';
    @track emailOTP = '';
    @track details = '';
    @track eventName = '';
    @track eventDate;
    @track eventDetails = '';
    @track monashOrStudentId = '';
    @track dateOfBirth = '';
    @track firstNameAtGrad = '';
    @track lastNameAtGrad = '';
    @track yearOfLastGrad = '';
    @track lastQualObtained = '';
    @track alumniEmail = '';
    @track selectedVolunteerType;
    @track mergedDetails = '';
    enquiryTypeEventEnquiry = false;
    enquiryTypeAlumniPortalEnquiry = false;
    enquiryTypeVolunteering = false;
    enquiryTypeGeneral = false;
    enquiryTypeTranscript = false;
    showSpinner = false;
    disableEmailVerifyBtn = true;
    emailVerified = false;
    emailRegexInternal = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/; 
    value = '';
    verifyButtonDisabled = true;
    verifyOTPInputDisabled = true;
    emailInputFieldDisabled = false;
    verificationSid = '';
    serviceSid = '';
    disablePickList = true;
    sendOTPBtnText = 'Send code';
    submitBtnDisabled = true;
    sessionTimedOut = false;
    hideForm = false;
    verifyEmailOTPBtnCss = 'bg-grey hover:bg-blue-700 text-white font-bold py-2 px-10 focus:outline-none focus:shadow-outline ucin-button';
    submitEnquiryBtnCss = 'slds-m-bottom_x-large bg-grey hover:bg-blue-700 text-white font-bold py-2 px-10 focus:outline-none focus:shadow-outline ucin-button';

    get options() {
        return [
            { label: 'SMS', value: 'SMS' },
            { label: 'Email', value: 'Email' },
        ];
    }
    validateForm(){
       if(!this.validateFirstnameAndLastName()){
            return false;
       }

        this.email = this.trim(this.email);
        if(this.email === '' || this.email === null  || this.email === undefined) {
            this.showToast("Error", "Please enter your email address.", "Error", "sticky");
            return false;
        }
        if(this.email !== '' && this.email !== null  && this.email !== undefined && !this.validEmail(this.email)){
            this.showToast("Error", "Please enter a valid email format.", "Error", "sticky");
            return false;
        }
        if(this.selectedEnqType === '' || this.selectedEnqType === null  || this.selectedEnqType === undefined || this.selectedEnqType === '-- Select a Value --') {
            this.showToast("Error", "Please select the reason that you are contacting us for.", "Error", "sticky");
            return false;
        }
        if(!this.hideForm){
            this.showToast("Error", "Please validate your email using the one time pass code", "Error", "sticky");
            return false;
        }
        if(this.selectedEnqType == 'Event Enquiry'){
            this.eventName = this.trim(this.eventName);
            if(this.eventName === '' || this.eventName === null  || this.eventName === undefined){
                this.showToast("Error", "Please specify the event that you are enquiring about.", "Error", "sticky");
                return false;   
            }else if(this.eventName.length > 150){
                this.showToast("Error", "Please specify the event name in less than 150 characters.", "Error", "sticky");
                return false;
            }else if(this.specialCharacterPresent(this.eventName)){
                this.showToast("Error", "Please do not enter special characters.", "Error", "sticky");
                return false;
            }

            this.eventDetails = this.trim(this.eventDetails);
            if(this.eventDetails === '' || this.eventDetails === null  || this.eventDetails === undefined){
                this.showToast("Error", "Please provide further details of the event.", "Error", "sticky");
                return false;   
            }else if(this.specialCharacterPresent(this.eventDetails)){
                this.showToast("Error", "Please do not enter special characters.", "Error", "sticky");
                return false;
            }else if(this.eventDetails.length > 30000){
                this.showToast("Error", "Please enter less than 30,000 characters for details of the event.", "Error", "sticky");
                return false;
            }
            if(this.eventDate !== '' && this.eventDate !== null  && this.eventDate !== undefined){
                let date_regex = /^\d{4}[\-\/\s]?((((0[13578])|(1[02]))[\-\/\s]?(([0-2][0-9])|(3[01])))|(((0[469])|(11))[\-\/\s]?(([0-2][0-9])|(30)))|(02[\-\/\s]?[0-2][0-9]))$/;
                if (!(date_regex.test(this.eventDate))) {
                    this.showToast("Error", "Please enter event date in the format of dd/mm/yyyy.", "Error", "sticky");
                    return false;
                }
            }
        }
        if(this.selectedEnqType == 'Alumni Portal Enquiry'){
            this.monashOrStudentId = this.trim(this.monashOrStudentId);
            if(this.monashOrStudentId !== '' && this.monashOrStudentId !== null && this.monashOrStudentId !== undefined){
                let numberCheck = /^\d+$/.test(this.monashOrStudentId);
                if(!numberCheck){
                    this.showToast("Error", "Please enter a number for your Monash ID or Student ID.", "Error", "sticky");
                    return false;
                }
                if(this.monashOrStudentId.length > 8 || this.monashOrStudentId.length < 6){
                    this.showToast("Error", "ID Should be a number between 6 to 8 digits.", "Error", "sticky");
                    return false;
                } 
            }
            if(this.dateOfBirth === '' || this.dateOfBirth === null  || this.dateOfBirth === undefined || isNaN(this.dateOfBirth) || this.dateOfBirth.length !== 4){
                this.showToast("Error", 'Please enter your year of birth in yyyy format.', "Error", "sticky");
                return false;   
            }else {
                const d = new Date();
                let year = d.getFullYear();
                if(parseInt((this.dateOfBirth)) < 1900 || parseInt((this.dateOfBirth)) > parseInt(year)){
                    this.showToast("Error", 'Please enter a valid year of birth.', "Error", "sticky");
                    return false;
                } 
            }

            // Check for script injection on FirstName at Grad 
            if(this.firstNameAtGrad !== '' && this.firstNameAtGrad !== null && this.firstNameAtGrad !== undefined){
                // Check for special character
                if(this.specialCharacterPresent(this.firstNameAtGrad)){
                    this.showToast("Error", "Please do not enter special characters for first name.", "Error", "sticky");
                    return false;
                }
                // Check for length
                if(this.firstNameAtGrad.length < 2 || this.firstNameAtGrad.length > 40){
                    // Check for Length
                    this.showToast("Error", "First name at graduation must contain between 2 and 40 characters.", "Error", "sticky");
                    return false;
                }
            } 
            // Check for script injection on FirstName at Grad 
            if(this.lastNameAtGrad !== '' && this.lastNameAtGrad !== null && this.lastNameAtGrad !== undefined){
                // Check for special character
                if(this.specialCharacterPresent(this.lastNameAtGrad)){
                    this.showToast("Error", "Please do not enter special characters for last name.", "Error", "sticky");
                    return false;
                }
                if(this.lastNameAtGrad.length < 2 || this.lastNameAtGrad.length > 40){
                    // Check for Length
                    this.showToast("Error", "Last name at graduation must contain between 2 and 40 characters.", "Error", "sticky");
                    return false;
                }  
            }
            // Check for yearOfLastGrad
            if(this.yearOfLastGrad === '' || this.yearOfLastGrad === null  || this.yearOfLastGrad === undefined){
                this.showToast("Error", "Please enter the 4 digits of the year you completed your course at Monash.", "Error", "sticky");
                return false;   
            }else {
                let numberCheck = /^\d+$/.test(this.yearOfLastGrad);
                if(!numberCheck){
                    this.showToast("Error", "Please enter a number for the year you completed your course at Monash.", "Error", "sticky");
                    return false;
                }
                const d = new Date();
                let nextYear = d.getFullYear();
                nextYear = parseInt(nextYear) + 1;
                if(!(this.yearOfLastGrad > 1950 && this.yearOfLastGrad < nextYear)){
                    this.showToast("Error", "Please enter a valid year you completed your course at Monash.", "Error", "sticky");
                    return false;
                } 
            } 
            // Check for lastQualObtained max length of 150 characters
            if(this.lastQualObtained !== '' && this.lastQualObtained !== null && this.lastQualObtained !== undefined){
                if(parseInt(this.lastQualObtained.length) > 150){
                    this.showToast("Error", "Last qualification obtained should be less than 150 characters.", "Error", "sticky");
                    return false; 
                }
                // Check for special characters
                if(this.specialCharacterPresent(this.lastQualObtained)){
                    this.showToast("Error", "Please do not enter special characters.", "Error", "sticky");
                    return false;
                }
            }
            // Check for alumniEmail
            if(this.alumniEmail !== '' && this.alumniEmail !== null  && this.alumniEmail !== undefined && !this.validEmail(this.alumniEmail)){
                this.showToast("Error", "Please enter a valid email for preferred email for Alumni Portal login.", "Error", "sticky");
                return false;
                
            }else if(this.alumniEmail.length > 150){
                this.showToast("Error", "Please enter an Alumni email less than 150 characters.", "Error", "sticky");
                return false;
            }
            // Check if the yearOfLastGrad is greater than dateOfBirth
            if(parseInt(this.yearOfLastGrad) < parseInt(this.dateOfBirth)){
                this.showToast("Error", "Course completion year must be later than your Year of birth.", "Error", "sticky");
                return false;
            }
        }
        if(this.selectedEnqType == 'Volunteering'){
            if(this.selectedVolunteerType === '' || this.selectedVolunteerType === null  || this.selectedVolunteerType === undefined){
                this.showToast("Error", "Please select the the type of Volunteering you are interested in.", "Error", "sticky");
                return false;   
            }
        }
        if(this.selectedEnqType == 'General Enquiry'){
            this.details = this.trim(this.details);
            if(this.details === '' || this.details === null  || this.details === undefined) {
                this.showToast("Error", "Please specify details of your enquiry.", "Error", "sticky");
                return false;
            }else if(this.specialCharacterPresent(this.details)){
                this.showToast("Error", "Please do not enter special characters.", "Error", "sticky");
                return false;
            }
        }
        return true;
    }

    validateFirstnameAndLastName(){
         // FirstName check
         this.firstName = this.trim(this.firstName);
         if(this.firstName === '' || this.firstName === null  || this.firstName === undefined) {
             this.showToast("Error", "Please enter your first name.", "Error", "sticky");
             return false;
         }else if(this.specialCharacterPresent(this.firstName)){
             // Check for Script Injection
             this.showToast("Error", "Please do not enter special characters.", "Error", "sticky");
             return false;
         }else if(this.firstName.length < 2 || this.firstName.length > 40){
             // Check for Length
             this.showToast("Error", "First Name must contain between 2 and 40 characters.", "Error", "sticky");
             return false;
         }
 
         //LastName check
         this.lastName = this.trim(this.lastName);
         if(this.lastName === '' || this.lastName === null  || this.lastName === undefined) {
             this.showToast("Error", "Please enter last name (if you have no last name, re-enter your first name).", "Error", "sticky");
             return false;
         }else if(this.specialCharacterPresent(this.lastName)){
             // Check for Script Injection
             this.showToast("Error", "Please do not enter special characters.", "Error", "sticky");
             return false;
         }else if(this.lastName.length < 2 || this.lastName.length > 40){
             // Check for Length
             this.showToast("Error", "Last Name must contain between 2 and 40 characters.", "Error", "sticky");
             return false;
         }
         return true;
    }

    validateEmail(){
        this.email = this.trim(this.email);
        if(this.email === '' || this.email === null  || this.email === undefined) {
            this.showToast("Error", "Please enter your email address.", "Error", "sticky");
            return false;
        }
        if(this.email !== '' && this.email !== null && this.email !== undefined){
            if(!this.validEmail(this.email)){
                this.showToast("Error", "Please enter a valid email format.", "Error", "sticky");
                return false;
            }
            if(this.email.length > 80){
                this.showToast("Error", "Please enter an email for less than 80 characters.", "Error", "sticky");
                return false;
            }
        }
        return true;
    }

    trim(field){
        if(field !== '' && field !== null && field !== undefined){
            return field.trim();      
        }
        return field;
    }

    /*
     * Method Name: send Data
     * Description: method to call apex function passing parameters from the UI
     */
    sendOTPCode() {
        // Null check
        if(this.validateFirstnameAndLastName() && this.validateEmail()){
            this.showSpinner = true;
            if(this.sessionTimedOut){
                this.sessionTimedOut = false;
            }
            sendCode({
                receipient : this.email,
                channel : 'email'
            })
            .then((result) => {
                this.showToast("Success", "Check your email for your code. If it's not there soon, check your spam/junk folder or click 'Resend code'.", "Success", "dismissable");
                this.showSpinner = false;
                // Enable VERIFY field and Button
                this.verifyButtonDisabled = false;
                this.verifyOTPInputDisabled = false;

                this.verifyEmailOTPBtnCss = 'bg-blue hover:bg-blue-700 text-white font-bold py-2 px-10 focus:outline-none focus:shadow-outline ucin-button';
                let returnValue = result.split(",");
                this.verificationSid = returnValue[0];
                this.serviceSid = returnValue[1];

                this.sendOTPBtnText = 'Resend code';

                setTimeout(() => {
                    if(this.emailOTP === '' || this.emailOTP === null || this.emailOTP === undefined){
                        this.resetOTPValidtn();
                    }
                }, 600000);                
            })
            .catch((error) => {
                this.showSpinner = false;
                let toastMessage = 'An Error has occurred';
                if (error && error.body && error.body.message) {
                    // Handle max limit exceeded
                    let limitExceeded = "Rate Limit Exceeded";
                    let errorMessage = error.body.message;
                    toastMessage = error.body.message;
                    if(errorMessage.includes(limitExceeded)){
                        toastMessage = 'You’ve exceeded the maximum number of attempts. Please try again later or email monashalumni@monash.edu for assistance.';
                        this.hideForm = true;
                    }
                }
                this.showToast("Error", toastMessage, "Error", "sticky");
            });
        }  
    }

    /*
     * Method Name: send Data
     * Description: method to call apex function passing parameters from the UI
     */
    verifyOTPCode() {
        // Null check
        if(this.validateEmail()){
            if(this.emailOTP === '' || this.emailOTP === null  || this.emailOTP === undefined || isNaN(this.emailOTP) || this.emailOTP.length !== 4){
                this.showToast("Error", 'Please enter a 4 digit one time passcode', "Error", "sticky");
                return;
            }
            if(this.sessionTimedOut){
                this.sessionTimedOut = false;
            }
            const fields = {
                emailSMS: this.email,
                otpCode: this.emailOTP,
                verificationSid: this.verificationSid,
                serviceSid: this.serviceSid
            };
            this.showSpinner = true;
            verifyPassCode({
                formData : fields
            })
            .then((result) => {
                this.showToast("Success", "Thanks for verifying your email. Please enter the details of your enquiry.", "Success", "dismissable");
                this.showSpinner = false;
                this.hideForm = true;
                setTimeout(() => {
                    this.resetOTPValidtn();
                }, 600000);

                // Enable the Picklist field
                this.disablePickList = false;

                // Disable EMail input
                this.emailInputFieldDisabled = true;
            })
            .catch((error) => {
                this.showSpinner = false;
                let toastMessage = 'An Error has occurred'; 
                if (error && error.body && error.body.message) {
                    // Handle incorrect OTP message
                    let invalidOTP = "Unverified Contact Point";
                    let errorMessage = error.body.message;
                    toastMessage = error.body.message;
                    if(errorMessage.includes(invalidOTP)){
                        toastMessage = 'The code you have entered is incorrect. Please check and try again or select “Resend code” to receive a new code.';
                    } 

                    // Handle max limit exceeded
                    let limitExceeded = "Rate Limit Exceeded";
                    if(errorMessage.includes(limitExceeded)){
                        toastMessage = 'You’ve exceeded the maximum number of attempts. Please try again later or email monashalumni@monash.edu for assistance.';
                        this.hideForm = true;
                    }
                }
                this.showToast("Error", toastMessage, "Error", "sticky");
            });
        }  
    }

    resetOTPValidtn(){
        if(!this.sessionTimedOut){
            let errorMessage;
            this.verificationSid = '';
            this.serviceSid = '';
            if(this.hideForm){
                this.hideForm = false;
                this.emailInputFieldDisabled = false; 
                this.emailOTP = '';
                errorMessage = 'Your session has timed out. Please select “Resend code”.';
            }else{
                this.verifyButtonDisabled = true;
                this.verifyOTPInputDisabled = true;
                this.verifyEmailOTPBtnCss = 'bg-grey hover:bg-blue-700 text-white font-bold py-2 px-10 focus:outline-none focus:shadow-outline ucin-button';
                errorMessage = 'Your code has timed out. Please select resend code.';
            }
            this.showToast("Error", errorMessage, "Error", "sticky");
            this.sessionTimedOut = true;this.emailOTP='';
        }
    }

    /*
     * Method Name: create Data
     * Description: method to call apex function passing parameters from the UI
     */
    createCase() {
        if(this.validateForm()){
            //firing an child method
            
            this.populateDescription();
            let plainTextMergedDetails = this.mergedDetails.replaceAll("<br/> <br/>", "----");
            this.showSpinner = true;
            createAlumniEnquiry({
                firstName : this.firstName,
                lastName : this.lastName,
                enqType : this.selectedEnqType,
                email : this.email,
                details : this.mergedDetails,
                detailsPlainText : plainTextMergedDetails
            })
            .then((result) => {
                this.showToast("Success", "Thanks for reaching out — your enquiry #" + result + " was submitted. An acknowledgement has been sent to the email address provided." , "Success", "dismissable");
                this.resetForm();
                this.showSpinner = false;
                setTimeout(() => {
                    this.handleNavigate();
                }, 5000);
            })
            .catch((error) => {
                this.showToast("Error", error.body.message, "Error", "sticky");
                this.showSpinner = false;
            });
        }
    }

    handleNavigate() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: redirectURL//'https://www.monash.edu/alumni/redirects/submit'
            }
        }).then(url => {
            window.location.href = url;
        });
      }

    resetForm(){
        this.selectedEnqType = '';
        this.firstName = '';
        this.lastName = '';
        this.email = '';
        this.details = '';
        this.eventName = '';
        this.eventDate='';
        this.eventDetails = '';
        this.monashOrStudentId = '';
        this.dateOfBirth='';
        this.firstNameAtGrad = '';
        this.lastNameAtGrad = '';
        this.yearOfLastGrad = '';
        this.lastQualObtained = '';
        this.alumniEmail = '';
        this.selectedVolunteerType = '';
        this.mergedDetails = '';
        this.enquiryTypeEventEnquiry = false;
        this.enquiryTypeAlumniPortalEnquiry = false;
        this.enquiryTypeVolunteering = false;
        this.enquiryTypeGeneral = false;
        this.enquiryTypeTranscript = false;
        this.emailInputFieldDisabled = false;
    }

    populateDescription(){
        let desc = '';
        desc = 'First Name: ' + this.firstName + '<br/> <br/>' + 'Last Name: ' + this.lastName + '<br/> <br/>';
        if(this.selectedEnqType == 'Event Enquiry'){
            if(this.eventName !== '' && this.eventName !== null && this.eventName !== undefined){
                desc = desc + 'Event Name: ' + this.eventName + '<br/> <br/>';      
            } 
            if(this.eventDate !== '' && this.eventDate !== null && this.eventDate !== undefined){
                desc = desc + 'Event Date: ' + this.eventDate + '<br/> <br/>';      
            }
            if(this.eventDetails !== '' && this.eventDetails !== null  && this.eventDetails !== undefined){
                desc = desc + 'Event Details: ' + this.eventDetails + '<br/> <br/>';    
            }
        }
        if(this.selectedEnqType == 'Alumni Portal Enquiry'){
            if(this.monashOrStudentId !== '' && this.monashOrStudentId !== null  && this.monashOrStudentId !== undefined){
                desc = desc + 'Monash ID / Student ID: ' + this.monashOrStudentId + '<br/> <br/>';   
            }
            if(this.dateOfBirth !== '' && this.dateOfBirth !== null  && this.dateOfBirth !== undefined){
                desc = desc + 'Year Of Birth: ' + this.dateOfBirth + '<br/> <br/>';   
            }
            if(this.firstNameAtGrad != '' && this.firstNameAtGrad !== null  && this.firstNameAtGrad !== undefined){
                desc = desc + 'First name at graduation: ' + this.firstNameAtGrad + '<br/> <br/>'; 
            }
            if(this.lastNameAtGrad != '' && this.lastNameAtGrad !== null  && this.lastNameAtGrad !== undefined){
                desc = desc + 'Last name at graduation: ' + this.lastNameAtGrad + '<br/> <br/>'; 
            } 
            if(this.yearOfLastGrad !== '' && this.yearOfLastGrad !== null  && this.yearOfLastGrad !== undefined){
                desc = desc + 'Year of last course completion: ' + this.yearOfLastGrad + '<br/> <br/>';
            }
            if(this.lastQualObtained !== '' && this.lastQualObtained !== null  && this.lastQualObtained !== undefined){
                desc = desc + 'Last Monash qualification obtained: ' + this.lastQualObtained + '<br/> <br/>';
            }
            if(this.alumniEmail !== '' && this.alumniEmail !== null  && this.alumniEmail !== undefined){
                desc = desc + 'Alumni Email: ' + this.alumniEmail + '<br/> <br/>';
            }
        }
        if(this.selectedEnqType == 'Volunteering'){
            if(this.selectedVolunteerType !== '' && this.selectedVolunteerType !== null && this.selectedVolunteerType !== undefined){
                desc = desc + 'Volunteer Type: ' + this.selectedVolunteerType + '<br/> <br/>';  
            }
        }
        if(this.selectedEnqType == 'General Enquiry'){
            if(this.details !== '' && this.details !== null && this.details !== undefined) {
                desc = desc + 'Details: ' + this.details + '<br/> <br/>';  
            }
        }
        this.mergedDetails = desc;
    }

    validEmail(emailValue){
        if(emailValue !== '' && emailValue.match(this.emailRegexInternal)){
            return true;
        }else{
            return false;
        }
    }

    onchangeFirstName(event) {
        this.firstName = event.currentTarget.value;
    }

    onchangeLastName(event) {
        this.lastName = event.currentTarget.value;
    }

    onchangeEmail(event) {
        this.email = event.currentTarget.value;
    }
    
    onchangeEmailOTP(event){
        this.emailOTP = event.currentTarget.value;
    }

    handleEnqTypeChange(event) {
        this.selectedEnqType = event.currentTarget.value;
        if(this.selectedEnqType == 'Event Enquiry'){
            this.enquiryTypeEventEnquiry = true;
            this.enquiryTypeAlumniPortalEnquiry = false;
            this.enquiryTypeVolunteering = false;
            this.enquiryTypeGeneral = false;
            this.enquiryTypeTranscript = false;
            this.submitBtnDisabled = false;
            this.submitEnquiryBtnCss = 'slds-m-bottom_x-large bg-blue hover:bg-blue-700 text-white font-bold py-2 px-10 focus:outline-none focus:shadow-outline ucin-button';
        }else if(this.selectedEnqType == 'Alumni Portal Enquiry'){
            this.enquiryTypeAlumniPortalEnquiry = true;
            this.enquiryTypeEventEnquiry = false;
            this.enquiryTypeVolunteering = false;
            this.enquiryTypeGeneral = false;
            this.enquiryTypeTranscript = false;
            this.submitBtnDisabled = false;
            this.submitEnquiryBtnCss = 'slds-m-bottom_x-large bg-blue hover:bg-blue-700 text-white font-bold py-2 px-10 focus:outline-none focus:shadow-outline ucin-button';
        }else if(this.selectedEnqType == 'Volunteering'){
            this.enquiryTypeVolunteering = true;
            this.enquiryTypeAlumniPortalEnquiry = false;
            this.enquiryTypeEventEnquiry = false;
            this.enquiryTypeGeneral = false;
            this.enquiryTypeTranscript = false;
            this.submitBtnDisabled = false;
            this.submitEnquiryBtnCss = 'slds-m-bottom_x-large bg-blue hover:bg-blue-700 text-white font-bold py-2 px-10 focus:outline-none focus:shadow-outline ucin-button';
        }else if(this.selectedEnqType == 'General Enquiry'){
            this.enquiryTypeGeneral = true;
            this.enquiryTypeVolunteering = false;
            this.enquiryTypeAlumniPortalEnquiry = false;
            this.enquiryTypeEventEnquiry = false;
            this.enquiryTypeTranscript = false;
            this.submitBtnDisabled = false;
            this.submitEnquiryBtnCss = 'slds-m-bottom_x-large bg-blue hover:bg-blue-700 text-white font-bold py-2 px-10 focus:outline-none focus:shadow-outline ucin-button';
        }else if(this.selectedEnqType == 'Transcript/Qualification'){
            this.enquiryTypeGeneral = false;
            this.enquiryTypeVolunteering = false;
            this.enquiryTypeAlumniPortalEnquiry = false;
            this.enquiryTypeEventEnquiry = false;
            this.enquiryTypeTranscript = true;
            this.submitBtnDisabled = true;
            this.submitEnquiryBtnCss = 'slds-m-bottom_x-large bg-grey hover:bg-blue-700 text-white font-bold py-2 px-10 focus:outline-none focus:shadow-outline ucin-button';
        }else {
            this.enquiryTypeEventEnquiry = false;
            this.enquiryTypeAlumniPortalEnquiry = false;
            this.enquiryTypeVolunteering = false;
            this.enquiryTypeGeneral = false;
            this.enquiryTypeTranscript = false;
            this.submitBtnDisabled = true;
            this.submitEnquiryBtnCss = 'slds-m-bottom_x-large bg-grey hover:bg-blue-700 text-white font-bold py-2 px-10 focus:outline-none focus:shadow-outline ucin-button';
        }
        this.renderButton();
    }

    onchangeDetails(event) {
        this.details = event.currentTarget.value;
    }

    onchangeEventName(event) {
        this.eventName = event.currentTarget.value;
    } 

    onchangeEventDate(event) {
        this.eventDate = event.currentTarget.value;
    } 

    onchangeEventDetails(event) {
        this.eventDetails = event.currentTarget.value;
    } 

    onchangeMonashOrStudentId(event) {
        this.monashOrStudentId = event.currentTarget.value;
    }

    onchangeDateOfBirth(event) {
        this.dateOfBirth = event.currentTarget.value;
    }

    onchangeFirstNameAtGrad(event) {
        this.firstNameAtGrad = event.currentTarget.value;
    }

    onchangeLastNameAtGrad(event) {
        this.lastNameAtGrad = event.currentTarget.value;
    }

    onchangeYearOfLastGrad(event) {
        this.yearOfLastGrad = event.currentTarget.value;
    } 

    onchangeLastQualObtained(event) {
        this.lastQualObtained = event.currentTarget.value;
    }

    onchangeAlumniEmail(event) {
        this.alumniEmail = event.currentTarget.value;
    }

    onchangeVolunteerTypeChange(event){
        this.selectedVolunteerType = event.currentTarget.value;
    }

    /*
     * Method Name: showToast
     * Description: method to show toast
     */
    showToast(toastTitle, toastMessage, toastVariant, toastMode) {
        const toast = new ShowToastEvent({
            title: toastTitle,
            message: toastMessage,
            variant: toastVariant,
            mode: toastMode
        });
        this.dispatchEvent(toast);
    }

    /*
     * Method Name: special char check
     * Description: method to check script injection
     */
    specialCharacterPresent(inputText) {
        if(inputText.includes('<script>') || inputText.includes('$("') || inputText.includes('<') || inputText.includes('>')){
            return true;
        }else{
            return false;
        }
    }
}