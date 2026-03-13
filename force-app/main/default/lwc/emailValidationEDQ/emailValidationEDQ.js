import { LightningElement, api, track } from 'lwc';
import validate from '@salesforce/apex/EmailValidationController.validate';
import getEmailWrapper from '@salesforce/apex/EmailValidationController.getEmailWrapper';
import getVerboseOutputDescriptionsByConfidence from '@salesforce/apex/EmailValidationController.getVerboseOutputDescriptionsByConfidence';
import getShowGenericErrorMessageDecision from '@salesforce/apex/EmailValidationController.getShowGenericErrorMessageDecision';
import getMinimumSecondsBetweenInvocations from '@salesforce/apex/ExperianUtility.getMinimumSecondsBetweenInvocations';

// custom permissions
import viewValidationMessage from '@salesforce/customPermission/Experian_View_Email_Validation_Message';

// import custom labels
import displayEDQConsoleLogs from '@salesforce/label/c.Display_EDQ_console_logs';
import displayGenericValidationMessage from '@salesforce/label/c.Experian_Email_Validation_Generic_Validation_Message';
import pleaseTryLaterMessage from '@salesforce/label/c.Experian_Email_Try_Again_Later_Message';
import invalidFormatMessage from '@salesforce/label/c.Experian_Email_Invalid_Format_Message';

// constants
const INVALID_STYLING = 'border: 2px solid red;box-sizing: border-box; border-radius: 3px';
const DEFAULT_STYLING = 'border: 1px solid lightgray; border-radius: 3px;';
const SERVICE_UNAVAILABLE_VALIDATION_MESSAGE = 'service unavailable';
const FORBIDDEN_VALIDATION_MESSAGE = 'forbidden';
const EXPERIAN_RATELIMITING_CUSTOMSETTING = 'Experian Email Validation';
const GUESTKEY_TEMPLATE = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx';

export default class EmailValidationEDQ extends LightningElement {

    @api currentRecordId;                       // Record Id of the current record, when form is a detail page
    @api placeHolder = 'john.doe@gmail.com';    // Email field place holder
    @api emailRegex;                            // Phone number regEx for format validation
    @api savedEmail;                            // Email address the input field will be prepopulated with
    @api verificationStatus;                    // Database saved Verification Status
    @api sendExperianFocusOut;                  // This will send to experian for validation on focus out
    @api componentName;                         // Provide component Name on Multiple Instances

    @track error;

    displayLog = displayEDQConsoleLogs;
    genericValidationMessage = displayGenericValidationMessage;
    isVerified;
    isUnVerified;
    isDidYouMeanDisplayed = false;
    emailEntered = '';
    emailDetails = {};
    emailDetailsComp = {};
    verboseDescription;
    confidenceLevelDescriptions;
    isLoading = false;
    isShowGenericValidationMessage = false;
    stylecss = DEFAULT_STYLING;
    emailRegexInternal = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    hasErrorOccured = false;
    errorMessage = pleaseTryLaterMessage;
    invalidEmailFormatMessage = invalidFormatMessage;
    minimumSecondsBetweenInvocations = 0;
    guestKey = null;
    initLoadComplete = false;

    connectedCallback(){
        if(Object.keys(this.emailDetails).length === 0){
            this.retrieveEmailWrapper();
            this.retrieveVerboseOutputDescriptionsByConfidence();
            this.retrieveShowGenericErrorMessageDecision();
            this.retrieveMinimumSecondsBetweenInvocations(EXPERIAN_RATELIMITING_CUSTOMSETTING);
        }
        if(this.sendExperianFocusOut === null || this.sendExperianFocusOut === undefined){
            this.sendExperianFocusOut = true;
        }
        this.emailEntered = this.savedEmail ?? '';
        if(this.verificationStatus && this.initLoadComplete === false){
            this.emailDetails.email = this.emailEntered;
            this.emailDetails.confidence = this.verificationStatus;
            this.emailDetailsComp = {...this.emailDetails};
            this.initLoadComplete = true;
        }
    }

    @api
    getEmailValidationResult(){
        return this.emailDetails;
    }

    @api
    async getEmailValidationResultAsync(){
        return await this.validateEmail();
    }

    get isClearIconHidden() {
        return (this.emailEntered === undefined || this.emailEntered === '');
    }

    // Display Generic validation message if
    //  - Email_Validation_Show_Generic_Error__c field in EDQ_Settings__c custom setting is set to true and
    //  - Experian_Email_Validation_Generic_Validation_Message custom label has value and
    //  - Experian Service is NOT unavailable and
    //  - There are sufficient Experian credits
    //  else display the validation message returned by Experian (Verbose Output + Description)
    get validationMessage() {
        return (this.isShowGenericValidationMessage && 
                this.genericValidationMessage !== null && 
                this.genericValidationMessage !== '' &&
                !this.verboseDescription.toLowerCase().includes(SERVICE_UNAVAILABLE_VALIDATION_MESSAGE) &&
                !this.verboseDescription.toLowerCase().includes(FORBIDDEN_VALIDATION_MESSAGE))
                ? this.genericValidationMessage
                : this.verboseDescription;
    }

    // Display suggested email address, if available
    get didYouMean(){
        return (this.emailDetails?.didYouMean &&
                this.emailDetails.didYouMean[0]);
    }

    get hasViewValidationMessagePermission(){
        return viewValidationMessage;
    }

    /**
     * Retrieve Phone wrapper
     */ 
    retrieveEmailWrapper(){
        getEmailWrapper()
        .then((result) => {
            this.emailDetails = JSON.parse(JSON.stringify(result));
            this.emailDetails.currentRecordId = this.currentRecordId ?? '';
        })
        .catch((error) => {
            this.error = error;
        });
    }

    /**
     * Retrieve confidence level, verbose output and their description
     */ 
    retrieveVerboseOutputDescriptionsByConfidence(){
        getVerboseOutputDescriptionsByConfidence()
        .then((result) => {
            this.confidenceLevelDescriptions = JSON.parse(JSON.stringify(result));
        })
        .catch((error) => {
            this.error = error;
        });
    }

    /**
     * Retrieve custom setting which decides if Experian validation message should be shown or a generic message 
     */ 
    retrieveShowGenericErrorMessageDecision(){
        getShowGenericErrorMessageDecision()
        .then((result) => {
            this.isShowGenericValidationMessage = JSON.parse(JSON.stringify(result));
        })
        .catch((error) => {
            this.error = error;
        });
    }

    /**
     * Retrieve minimum seconds between invocations from the custom setting
     */    
     retrieveMinimumSecondsBetweenInvocations(customSettingName){
        getMinimumSecondsBetweenInvocations({ 
            customSettingName : customSettingName
        })
        .then((result) => {
            this.minimumSecondsBetweenInvocations = result;
        })
        .catch((error) => {
            this.error = error;
            console.error('Error:', this.error);
        });
    }

    handleEmailChange(event){
        this.reset();
        this.emailEntered = event.target.value;
        this.emailDetails.email = this.emailEntered;
    }

    handleClearField(){
        this.reset();
        let email = this.template.querySelector(".input");
        email.setCustomValidity("");
        email.reportValidity();
    }

    getGuestKey(){
        let gkeyId = 'gkey';
        if(this.componentName){
            gkeyId = 'gkey_'+this.componentName;
        }
        if(this.guestKey === null) {
            this.guestKey = localStorage.getItem(gkeyId);
            if (this.guestKey === null) {            
                this.guestKey = GUESTKEY_TEMPLATE.replace(/[xy]/g, function(c) {
                    var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
                    return v.toString(16);
                });
                localStorage.setItem(gkeyId, this.guestKey);
            }
        }
        console.log(''+gkeyId,this.guestKey);
        return this.guestKey;
    }

    suggestionSelected(){
        this.isDidYouMeanDisplayed = false;
        this.emailEntered = this.didYouMean;
        this.emailDetails.email = this.emailEntered;
        this.stylecss = DEFAULT_STYLING;
        this.hasErrorOccured = false;
        this.isVerified = false;
        this.isUnVerified = false;
    }

    validateEmailPattern(email){
        let isValid = true;
        let emailValue = email.value;
        email.setCustomValidity("");

        let regEx = new RegExp('^'+this.emailRegex+'$');
        
        if(emailValue !== '' && (!emailValue.match(this.emailRegexInternal) || (this.emailRegex && !emailValue.match(regEx)))){
            email.setCustomValidity(this.invalidEmailFormatMessage);
            isValid = false;
        }
        email.reportValidity();

        return isValid;
    }

    validateEmailFormat(){ 
        let email = this.template.querySelector(".input");
        let validEm = this.validateEmailPattern(email);
        if(validEm === true && this.sendExperianFocusOut === true){
            this.validateEmail();
        }
    }

    async validateEmail(){
        this.stylecss = DEFAULT_STYLING;
        this.hasErrorOccured = false;
        this.isDidYouMeanDisplayed = false;
        this.isVerified = false;
        this.isUnVerified = false;

        let email = this.template.querySelector(".input");
        let isValid = this.validateEmailPattern(email);
        let isPerformValidate = this.deepEqual(this.emailDetails, this.emailDetailsComp);

        if(this.emailEntered.length > 4 && isValid && isPerformValidate === false){
            this.isLoading = true;
            return await validate({
                email : this.emailEntered,
                customSettingName : EXPERIAN_RATELIMITING_CUSTOMSETTING,
                guestKey : this.getGuestKey()
            })
            .then(res => {
                if(res == null){
                    this.hasErrorOccured = true;
                    this.errorMessage = this.errorMessage.replace('#', this.minimumSecondsBetweenInvocations);
                    this.isLoading = false;
                    return null;
                }
                else{
                    this.validationResult = res;

                    let confidenceLevel = this.validationResult?.result?.confidence;
                    let verboseOutput = this.validationResult?.result?.verbose_output;
                    let displayMessage = this.confidenceLevelDescriptions &&
                                            this.confidenceLevelDescriptions[confidenceLevel] &&
                                            this.confidenceLevelDescriptions[confidenceLevel][verboseOutput];
                    this.verboseDescription = verboseOutput.substring(0, 1).toUpperCase() + verboseOutput.substring(1, verboseOutput.length) + 
                                            ' - ' + displayMessage;

                    if(confidenceLevel){
                        this.isVerified = confidenceLevel === "verified";

                        this.isUnVerified = confidenceLevel !== "verified";
                        if(this.isUnVerified && this.hasViewValidationMessagePermission) {
                            this.stylecss = INVALID_STYLING;
                        }

                        this.emailDetails.confidence = confidenceLevel;
                    }
                    this.emailDetails.email = this.validationResult?.result?.email;
                    this.emailDetails.verboseOutput = this.validationResult?.result?.verbose_output;
                    this.emailDetails.type = this.validationResult?.metadata?.domain_detail?.type;
                    this.emailDetails.didYouMean = this.validationResult?.result?.did_you_mean;
                    this.isDidYouMeanDisplayed = this.emailDetails?.didYouMean?.length > 0;
                    //Fix undeliverable revert to email entered value
                    if(this.emailDetails.email == null || this.emailDetails.email.trim().length === 0){
                        this.emailDetails.email = this.emailEntered;
                    }
                    this.dispatchEvent(new CustomEvent('validate', {
                        detail: {
                            data : this.emailDetails
                        }
                    }));

                    if(this.displayLog === 'true') console.log(this.getEmailValidationResult());

                    this.isLoading = false;
                    this.emailDetailsComp = {...this.emailDetails};
                    return this.emailDetails;
                }
            })
            .catch(error => {
                console.error('Error:', error);
                this.isLoading = false;
                this.emailDetails.email = this.emailEntered;
                this.emailDetails.verboseOutput = error?.body?.message;
                this.emailDetails.confidence = error?.body?.message;
                this.isVerified = false;
                this.isUnVerified = true;
                if(this.isUnVerified && this.hasViewValidationMessagePermission) {
                    this.stylecss = INVALID_STYLING;
                }
                return null;
            });
        } else {
            this.isVerified = (this.emailDetails.confidence === "verified");
            this.isLoading = false;
            return this.emailDetails;
        }
        return null;
    }

    reset(){
        this.emailEntered = '';
        this.stylecss = DEFAULT_STYLING;
        this.isDidYouMeanDisplayed = false;
        this.isVerified = false;
        this.isUnVerified = false;
        this.hasErrorOccured = false;

        this.emailDetails.confidence = '';
        this.emailDetails.email = '';
        this.emailDetails.verboseOutput = '';
        this.emailDetails.type = '';
        this.emailDetails.didYouMean = [];
        this.emailDetailsComp = {};
    }
    deepEqual(object1, object2) {
        const keys1 = Object.keys(object1);
        const keys2 = Object.keys(object2);
        if (keys1.length !== keys2.length) {
          return false;
        }
        for (const key of keys1) {
          const val1 = object1[key];
          const val2 = object2[key];
          const areObjects = this.isObject(val1) && this.isObject(val2);
          if (
            areObjects && !this.deepEqual(val1, val2) ||
            !areObjects && val1 !== val2
          ) {
            return false;
          }
        }
        return true;
      }
    isObject(object) {
        return object != null && typeof object === 'object';
    }
}