import { LightningElement,api, track, wire } from 'lwc'; 
import { loadStyle } from 'lightning/platformResourceLoader';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';

import retrieveCountryList  from '@salesforce/apex/AdmissionsCaseServices.retrieveCountryList';
import initiateCommitRecordWithCaptcha from '@salesforce/apex/AdmissionsCaseServices.initiateCommitRecordWithCaptcha';

import ENQUIRY_OBJECT from '@salesforce/schema/Case';
import ENQUIRY_WEB_NAME_FIELD from '@salesforce/schema/Case.SuppliedName';
import ENQUIRY_SUPPLIED_FIRST_NAME_FIELD from '@salesforce/schema/Case.Supplied_First_Name__c';
import ENQUIRY_SUPPLIED_LAST_NAME_FIELD from '@salesforce/schema/Case.Supplied_Last_Name__c';
import ENQUIRY_SUPPLIED_MOBILE_FIELD from '@salesforce/schema/Case.Supplied_Mobile__c';
import ENQUIRY_EMAIL_FIELD from '@salesforce/schema/Case.SuppliedEmail';
import ENQUIRY_STUDENT_TYPE_FIELD from '@salesforce/schema/Case.Student_Type__c';
import ENQUIRY_ORIGIN_FIELD from '@salesforce/schema/Case.Origin';
import ENQUIRY_ENQUIRY_TYPE_FIELD from '@salesforce/schema/Case.Enquiry_Type__c';
import ENQUIRY_CATEGORY_LEVEL_1_FIELD from '@salesforce/schema/Case.Category_Level_1__c';
import ENQUIRY_CATEGORY_LEVEL_2_FIELD from '@salesforce/schema/Case.Category_Level_2__c';
import ENQUIRY_SUBJECT_FIELD from '@salesforce/schema/Case.Subject';
import ENQUIRY_DESCRIPTION_FIELD from '@salesforce/schema/Case.Description';
import ENQUIRY_COMMENTS from '@salesforce/schema/Case.Comments';
import ENQUIRY_RECORD_TYPE_FIELD from '@salesforce/schema/Case.RecordTypeId';

import communityMyAppAssets from '@salesforce/resourceUrl/CommunityMyAppAssets';


export default class MfaEnquiryForm extends LightningElement {
    @track resourcesReady;
    @track hasAttemptedSubmitting;
    @track suppliedFirstName;
    @track suppliedLastName;
    @track suppliedEmail;
    @track countryCode = '';
    @track selectedCountryCode = '';
    @track mobileNumberCountry = '';
    @track countries;
    @track mobileNumber = '';
    @track standardEnquiryRecordTypeId;
    @track selectedStudentType;
    @track availableStudentTypeOptions = [];
    @track selectedErrorMessage;
    @track error;
    @track hasSubmittedEnquiry;
    @track hasSelectedCountry = false;
    @track buttonText ='Submit Enquiry';

    @api
    myRecordId;
    @wire(getObjectInfo, { objectApiName: ENQUIRY_OBJECT })
    wiredEnquiryInfo({ error, data }) {
        if (data) {
            const recordTypeList = data.recordTypeInfos;
            this.standardEnquiryRecordTypeId = Object.keys(recordTypeList).find(rti => recordTypeList[rti].name === 'Standard Enquiry')
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.standardEnquiryRecordTypeId = undefined;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$standardEnquiryRecordTypeId', fieldApiName: ENQUIRY_STUDENT_TYPE_FIELD })
    wiredStudentTypeInfo({ error, data }) {
        if (data) {
            this.availableStudentTypeOptions = data.values;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.availableStudentTypeOptions = [];
        }
    }

    get standardEnquiryRecordTypeId() {
        console.log(this.objectInfo);
        const rtis = this.objectInfo.data;
        return Object.keys(rtis).find(rti => rtis[rti].name === 'Standard Enquiry');
    }

    get studentTypeOptions() {        
        let options = [];
        this.availableStudentTypeOptions.forEach(function (item, index) {
            if(item.value != 'International Onshore' && item.value != 'International Offshore'){
                options.push({ label: item.label, value: item.value });                
            }
        });
        return options;
    }

    get errorMessageOptions() {        
        let options = [];
        options.push({ label: 'Country not supported', value: 'Country not supported' });
        options.push({ label: 'Mobile Number not supported', value: 'Mobile Number not supported' });
        return options;
    }

    //import asset css file
    connectedCallback() {
        this.onLoadGetCountryList();
        Promise.all([
            loadStyle(this, communityMyAppAssets + '/MonashStyling.css')
        ]).then(() => {
            this.resourcesReady = true;
        });
    }

    @api
    onLoadGetCountryList(){
        retrieveCountryList()
        .then((result) => {
            this.countries = result.allCountries;
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
        })
        .catch((error) => {
            this.error = error;
        });
    }

    renderedCallback() {
        // read country records
        var xhr = new XMLHttpRequest();
        xhr.open("GET", countriesList);
        xhr.onload = () => this.countries = xhr.responseText;
        xhr.send(null);
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

        // set selected code properly
        if(this.selectedCountryCode){
            this.hasSelectedCountry = true;
        }
    }

    /* first name */
    firstNameChange(event){
        this.suppliedFirstName = event.target.value;        
    }

    /* last name */
    lastNameChange(event){
        this.suppliedLastName = event.target.value;        
    }
    
    /* email */
    emailChange(event){
        this.suppliedEmail = event.target.value;        
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
    get disableMobileNumberFields() {
        return false;
    }

    handleStudentTypeChange(event) {
        this.selectedStudentType = event.detail.value;
    }

    handleErrorChange(event) {
        this.selectedErrorMessage = event.detail.value;
    }

    

    resetCaptchaButton(){
        let crmcaptchabuttonlwc = this.template.querySelector(
             '[data-id="crmcaptchabuttonlwc"]'
        );
        // Resets and gets new token
        if(crmcaptchabuttonlwc){
            crmcaptchabuttonlwc.resetButton();
        }
   }

    /* build and submit enquiry */
    handleButtonClick(event){
        if(this.validateForm()){
            this.resetCaptchaButton();
        } else {
            const recordInput = this.buildEnquiry();
            initiateCommitRecordWithCaptcha({ 
                record: JSON.stringify(recordInput),
                fireAssignmentRule: true,
                fireAutoResponseRule: true,
                captchaToken: event.detail.captchaToken
            })
            .then((result) => {
                this.hasSubmittedEnquiry = true;
                this.error = undefined;
            })
            .catch((error) => {
                this.error = error;
                this.resetCaptchaButton();
            });
        }
    }

    /* validate form fields */
    validateForm() {
        const recordInput = {};

        let hasError = false;
        this.template.querySelectorAll(".mfaFormField").forEach(function(element) {      
            if(element.name === 'country'){
                // flag missing field
                if(element.fireError('Please complete this field.')){
                    hasError = true;
                }
            }else{
                if(!element.value){
                    element.setCustomValidity('Please complete this field.');  
                    element.reportValidity();
                    // flag missing field
                    hasError = true;
                }else{
                    element.setCustomValidity('');  
                    element.reportValidity();
                }
            }
        });
        
        // stop submission when country havent been manually selected
        if(this.selectedCountryCode === undefined || this.hasSelectedCountry === false){
            hasError = true;
        }

        this.hasAttemptedSubmitting = true;
        this.isSubmitting = false;
        return hasError;
    } 

    /* construct enquiry record */
    buildEnquiry(){
        const recordInput = {};       
        let thisContent = this;

        // re-retrieve input values
        this.template.querySelectorAll(".mfaFormField").forEach(function(element) {
            switch(element.name) {
                case 'legalGivenName':
                    thisContent.suppliedFirstName = element.value;
                    break;
                case 'legalLastName':
                    thisContent.suppliedLastName = element.value;
                    break;
                case 'email':
                    thisContent.suppliedEmail = element.value;
                    break;
                case 'country':
                    let newCountryValue = element.value;
                    if(newCountryValue.includes('(+')){
                        thisContent.selectedCountryCode = newCountryValue.split('(+')[1].replace(')', '');
                        thisContent.mobileNumberCountry = newCountryValue.split(' (+')[0];
                    }
                    break;
                case 'mobileNumber':
                    thisContent.mobileNumber = element.value;
                    break;
                default:
                    // do nothing when nothing matches
            }
        });

        // map input values to enquiry fields
        recordInput[ENQUIRY_WEB_NAME_FIELD.fieldApiName] = this.suppliedFirstName + ' ' + this.suppliedLastName;
        recordInput[ENQUIRY_SUPPLIED_FIRST_NAME_FIELD.fieldApiName] = this.suppliedFirstName;
        recordInput[ENQUIRY_SUPPLIED_LAST_NAME_FIELD.fieldApiName] = this.suppliedLastName;
        recordInput[ENQUIRY_SUPPLIED_MOBILE_FIELD.fieldApiName] = this.mobileNumber;
        recordInput[ENQUIRY_EMAIL_FIELD.fieldApiName] = this.suppliedEmail;
        recordInput[ENQUIRY_STUDENT_TYPE_FIELD.fieldApiName] = this.selectedStudentType;
        recordInput[ENQUIRY_ORIGIN_FIELD.fieldApiName] = 'Web - My.App';
        recordInput[ENQUIRY_ENQUIRY_TYPE_FIELD.fieldApiName] = 'Future Course';
        recordInput[ENQUIRY_CATEGORY_LEVEL_1_FIELD.fieldApiName] = 'Application';
        recordInput[ENQUIRY_CATEGORY_LEVEL_2_FIELD.fieldApiName] = 'Application Assistance';
        recordInput[ENQUIRY_SUBJECT_FIELD.fieldApiName] = 'My.App MFA Support Enquiry - ' + this.selectedErrorMessage;
        recordInput[ENQUIRY_RECORD_TYPE_FIELD.fieldApiName] = this.standardEnquiryRecordTypeId;
         
        let descriptionDetails = 'Legal given name(s): ' + this.suppliedFirstName + '\n';
        descriptionDetails += 'Legal last name: ' + this.suppliedLastName + '\n';
        descriptionDetails += 'Country Code: +' + this.selectedCountryCode + ' ' + this.mobileNumberCountry + '\n';
        descriptionDetails += 'Mobile Number: ' + this.mobileNumber + '\n';
        descriptionDetails += 'Additional details provided: ' + this.comments;
        recordInput[ENQUIRY_DESCRIPTION_FIELD.fieldApiName] = descriptionDetails;

        return recordInput;
    }       

    //handle register redirection
    redirectLogin(){
        window.location.href = '/admissions/s/login';
    }

    
}