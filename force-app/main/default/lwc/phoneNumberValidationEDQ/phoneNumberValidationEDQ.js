import { LightningElement, api, track } from 'lwc';
import validate from '@salesforce/apex/PhoneNumberValidationController.validate';
import getTopCountriesList from '@salesforce/apex/PhoneNumberValidationController.getTopCountriesList';
import getRestOfTheCountriesList from '@salesforce/apex/PhoneNumberValidationController.getRestOfTheCountriesList';
import getPhoneNumberWrapper from '@salesforce/apex/PhoneNumberValidationController.getPhoneNumberWrapper';
import getConfidenceLevelDescriptions from '@salesforce/apex/PhoneNumberValidationController.getConfidenceLevelDescriptions';
import getShowGenericErrorMessageDecision from '@salesforce/apex/PhoneNumberValidationController.getShowGenericErrorMessageDecision';
import getMinimumSecondsBetweenInvocations from '@salesforce/apex/ExperianUtility.getMinimumSecondsBetweenInvocations';
import graphicsPack from '@salesforce/resourceUrl/GraphicsPackNew';

// custom permissions
import viewValidationMessage from '@salesforce/customPermission/Experian_View_Phone_Validation_Message';

// import custom labels
import displayEDQConsoleLogs from '@salesforce/label/c.Display_EDQ_console_logs';
import displayGenericValidationMessage from '@salesforce/label/c.Experian_Phone_Validation_Generic_Validation_Message';
import pleaseTryLaterMessage from '@salesforce/label/c.Experian_Phone_Try_Again_Later_Message';
import countryNotSelectedMessage from '@salesforce/label/c.Experian_No_Country_Selected_Message';
import invalidFormatMessage from '@salesforce/label/c.Experian_Phone_Invalid_Format_Message';
import FORM_FACTOR from '@salesforce/client/formFactor';

// constants
const INVALID_STYLING = 'border: 2px solid red;box-sizing: border-box; border-radius: 3px';
const DEFAULT_STYLING = 'border: 1px solid lightgray; border-radius: 3px;';
const SERVICE_UNAVAILABLE_VALIDATION_MESSAGE = 'service unavailable';
const FORBIDDEN_VALIDATION_MESSAGE = 'forbidden';
const EXPERIAN_RATELIMITING_CUSTOMSETTING = 'Experian Phone Validation';
const GUESTKEY_TEMPLATE = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx';

export default class PhoneNumberValidationEDQ extends LightningElement {

    @api currentRecordId;                   // Record Id of the current record, when form is a detail page
    @api placeholder = '123456789';         // Address bar place holder
    @api phoneNumberlabel = 'Phone Number'; // Address bar label
    @api doNotShowCountryFlags = false;     // Display country flags or not. Show flags by default
    @api phoneNumberRegEx;                  // Phone number regEx for format validation
    @api savedPhoneNumber;                  // Phone number the input field will be prepopulated with
    @api savedCountry;                      // Database saved Country Value
    @api verificationStatus;                // Database saved Verification Status
    @api sendExperianFocusOut;              // This will send to experian for validation on focus out
    @api componentName;                     // Provide component Name on Multiple Instances
    @api defaultCountry;                    // Allows default country

    @track error;

    delayTimeout;
    isVerified;
    isUnVerified;
    frequentCountryAttributeResult = [];
    restCountryAttributeResult = [];
    isSelected;
    selectedItem;
    showDropdown = false;
    phoneNumberDetails = {};
    phoneNumberDetailsComp = {};
    displayLog = displayEDQConsoleLogs;
    numberEntered = '';
    confidenceLevelDescription;
    confidenceLevelDescriptions;
    validationResult = {};
    defaultFlag = graphicsPack + '/fatcow/farmfresh/16/mail_box.png';
    inputCountry = '';
    isLoading = false;
    stylecss = DEFAULT_STYLING;
    phoneNumberRegExInternal = /^[\+]?[\d\s]{5,25}$/;
    isShowGenericValidationMessage = false;
    genericValidationMessage = displayGenericValidationMessage;
    selectCountryMessage = countryNotSelectedMessage;
    tryLaterMessage = pleaseTryLaterMessage;
    invalidPhoneFormatMessage = invalidFormatMessage;
    hasErrorOccured = false;
    errorMessage;
    minimumSecondsBetweenInvocations = 0;
    guestKey = null;
    dropdownfocus = false;
    isCountryNotSelected = false;
    initLoadComplete = false;

    connectedCallback(){
        this.showDropdown = false;
        if(Object.keys(this.phoneNumberDetails).length === 0){
            this.retrieveTopCountryAttributes();
            this.retrieveRestCountryAttributes();
            this.retrievePhoneNumberWrapper();
            this.retrieveConfidenceLevelDescriptions();
            this.retrieveShowGenericErrorMessageDecision();
            this.retrieveMinimumSecondsBetweenInvocations(EXPERIAN_RATELIMITING_CUSTOMSETTING);
        }
        if(this.sendExperianFocusOut === null || this.sendExperianFocusOut === undefined){
            this.sendExperianFocusOut = true;
        }
        this.numberEntered = this.savedPhoneNumber ?? '';
        if (this.verificationStatus && this.initLoadComplete === false) {
            this.phoneNumberDetails.confidence = this.verificationStatus;
            this.phoneNumberDetails.entered_phone_number = this.numberEntered;
            this.phoneNumberDetails.formatted_phone_number = this.numberEntered;
            this.isVerified = (this.phoneNumberDetails.confidence === "Verified");
            this.phoneNumberDetailsComp = {...this.phoneNumberDetails};
            this.initLoadComplete = true;
        }
    }

    renderedCallback(){ 
        if(this.defaultCountry){
            if(!this.isSelected){
                for (var i = 0; i < this.picklistOptionsTop.length; i++) {
                    if(this.picklistOptionsTop[i].name === this.defaultCountry){
                        this.selectedItem = this.picklistOptionsTop[i];
                        this.isSelected = true;
                    }
                }
            }
        } 
    }     
    
    @api
    getPhoneNumberValidationResult(){
        return this.phoneNumberDetails;
    }

    @api
    async getPhoneNumberValidationResultAsync(){
        return await this.validateNumber();
    }

    get isEntryDisabled() {
        return (this.selectedItem === undefined || this.selectedItem === '');
    }
    
    get picklistOptionsRest(){
        if(this.inputCountry){ 
            // Show countries in the pickist based on user entry
            let filteredArr = this.restCountryAttributeResult.filter(col => col.Country__c.toLowerCase().includes(this.inputCountry.toLowerCase()));
            return this.createPicklistOptions(filteredArr);
         }
         else{
            return this.createPicklistOptions(this.restCountryAttributeResult);
        }
    }

    get picklistOptionsTop(){
        if(this.inputCountry){
            // Show countries in the picklist based on user entry
            let filteredArr = this.frequentCountryAttributeResult.filter(col => col.Country__c.toLowerCase().includes(this.inputCountry.toLowerCase()));
            return this.createPicklistOptions(filteredArr);
         }
         else{
            return this.createPicklistOptions(this.frequentCountryAttributeResult);
        }
    }

    get countryName(){
        return this.selectedItem?.name ?? 'Select a country…';
    }

    // Display Generic validation message if
    //  - Phone_Validation_Show_Generic_Error__c field in EDQ_Settings__c custom setting is set to true and
    //  - Experian_Phone_Validation_Generic_Error_Message custom label has value and
    //  - Experian Service is NOT unavailable and
    //  - There are sufficient Experian credits
    //  else display the validation message returned by Experian (Verbose Output + Description)
    get validationMessage() {
        return (this.isShowGenericValidationMessage && 
                this.genericValidationMessage !== null && 
                this.genericValidationMessage !== '' &&
                !this.confidenceLevelDescription.toLowerCase().includes(SERVICE_UNAVAILABLE_VALIDATION_MESSAGE) &&
                !this.confidenceLevelDescription.toLowerCase().includes(FORBIDDEN_VALIDATION_MESSAGE))
                ? this.genericValidationMessage
                : this.confidenceLevelDescription;
    }

    get hasViewValidationMessagePermission(){
        return viewValidationMessage;
    }

    get isClearIconHidden() {
        return (this.numberEntered === undefined || this.numberEntered === '');
    }

    get frequentlyUsedExists(){
        return this.frequentCountryAttributeResult.length > 0;
    }

    get isSmallMediumFormFactor(){
        return FORM_FACTOR === 'Small' || FORM_FACTOR === 'Medium';
    }

    get isLargeFormFactor(){
        return FORM_FACTOR === 'Large'
    }

    /**
     * Retrieve top country details
     */    
    retrieveTopCountryAttributes(){
        this.isLoading = true;
        getTopCountriesList()
        .then((result) => {
            this.isLoading = false;
            this.frequentCountryAttributeResult = result;
            if (this.savedCountry && !this.selectedItem) {
                this.inputCountry = this.savedCountry;
                let fromTop = this.picklistOptionsTop;
                if (fromTop?.length) this.selectedItem = fromTop[0];
                this.isSelected = !!this.selectedItem;
            }
        })
        .catch((error) => {
            this.isLoading = false;
            this.error = error;
        });
    }

    /**
     * Retrieve rest of the country details
     */    
    retrieveRestCountryAttributes(){
        this.isLoading = true;
        getRestOfTheCountriesList()
        .then((result) => {
            this.isLoading = false;
            this.restCountryAttributeResult = result;
            if (this.savedCountry && !this.selectedItem) {
                this.inputCountry = this.savedCountry;
                let fromRest = this.picklistOptionsRest;
                if (fromRest?.length) this.selectedItem = fromRest[0];
                this.isSelected = !!this.selectedItem;
            }
        })
        .catch((error) => {
            this.isLoading = false;
            this.error = error;
        });
    }

    /**
     * Retrieve Phone number wrapper
     */ 
    retrievePhoneNumberWrapper(){
        getPhoneNumberWrapper()
        .then((result) => {
            this.phoneNumberDetails = JSON.parse(JSON.stringify(result));
            this.phoneNumberDetails.currentRecordId = this.currentRecordId ?? '';
        })
        .catch((error) => {
            this.error = error;
        });
    }

    /**
     * Retrieve confidence levels and their description
     */ 
    retrieveConfidenceLevelDescriptions(){
        getConfidenceLevelDescriptions()
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

    createPicklistOptions(picklistInput){
        return picklistInput.map(function (element) {
            return {id: element.Id,
                    flag: graphicsPack + '/flags/16/flags/' + element.ISO_Alpha_2__c.toLowerCase() + '.png', 
                    name: element.Country__c,
                    isoCode: element.ISO_Alpha_3__c}
          });
    }

    validatePhoneNumberPattern(mobileNumber){
        let isValid = true;
        mobileNumber.setCustomValidity("");
        let phoneValue = mobileNumber.value;

        let regEx = new RegExp('^'+this.phoneNumberRegEx+'$');

        if(phoneValue !== '' && this.phoneNumberRegEx && !phoneValue.match(regEx)){
            mobileNumber.setCustomValidity(this.invalidPhoneFormatMessage);
            isValid = false;
        }
        mobileNumber.reportValidity();
        return isValid;
    }

    validatePhoneNumberFormat(){
        let mobileNumber = this.template.querySelector(".input");
        let validPN = this.validatePhoneNumberPattern(mobileNumber);
        if(validPN === true && this.sendExperianFocusOut === true){
            this.validateNumber();
        }
    }

    async validateNumber(){
        this.stylecss = DEFAULT_STYLING;
        this.showDropdown = false;
        this.isVerified = false;
        this.isUnVerified = false;
        this.hasErrorOccured = false;

        let mobileNumber = this.template.querySelector(".input");
        let isValid = this.validatePhoneNumberPattern(mobileNumber);
        if(!isValid) return this.phoneNumberDetails;

        if (this.verificationStatus === 'Verified') {
            this.isVerified = true;
            this.phoneNumberDetails.confidence = 'Verified';
            this.phoneNumberDetails.entered_phone_number = this.numberEntered;
            this.phoneNumberDetails.formatted_phone_number = this.numberEntered;
            this.phoneNumberDetailsComp = {...this.phoneNumberDetails};
            return this.phoneNumberDetails;
        }

        // Remove non-numeric characters and leading '0011', '00' characters from the entered nunmber before validation
        let cleanedNumber = this.numberEntered.replace(/\D/g,'').replace(/^(0011|00)/g,'');

        let isPerformValidate = this.deepEqual(this.phoneNumberDetails, this.phoneNumberDetailsComp);
        if(cleanedNumber.length >= 8 && !isNaN(cleanedNumber) && isPerformValidate === false){
            this.isLoading = true;

            return await validate({
                phoneNumber : cleanedNumber,
                countryIsoCode : this.selectedItem?.isoCode,
                customSettingName : EXPERIAN_RATELIMITING_CUSTOMSETTING,
                guestKey : this.getGuestKey()
            })
            .then(res => {
                //this.isValidated = true;

                if(!this.numberEntered) return;

                if(res == null){
                    this.isLoading = false;
                    this.hasErrorOccured = true;
                    this.errorMessage = this.tryLaterMessage;
                    this.errorMessage = this.errorMessage.replace('#', this.minimumSecondsBetweenInvocations);
                }
                else{
                    this.hasErrorOccured = false;
                    this.validationResult = res;

                    let confidenceLevel = this.validationResult?.result?.confidence;
                    let description = this.confidenceLevelDescriptions[confidenceLevel];
                    this.confidenceLevelDescription = confidenceLevel + ' : ' + description;

                    if(confidenceLevel){
                        this.isVerified = confidenceLevel === "Verified";
                        this.isUnVerified = confidenceLevel !== "Verified";
                        this.phoneNumberDetails.confidence = confidenceLevel;
                        this.phoneNumberDetails.confidence_description = description;
                    }
                    if(this.isUnVerified && this.hasViewValidationMessagePermission) {
                        this.stylecss = INVALID_STYLING;
                    }
                    
                    this.phoneNumberDetails.formatted_phone_number = this.validationResult?.result?.formatted_phone_number;
                    this.phoneNumberDetails.phone_type = this.validationResult?.result?.phone_type;

                    // format to have a space between country code and phone number
                    let prefix = '+' + this.validationResult?.metadata?.phone_detail?.original_country_prefix;
                    this.phoneNumberDetails.unicrm_formatted_phone_number = this.validationResult?.result?.formatted_phone_number.includes(prefix)
                                                                            ? this.validationResult?.result?.formatted_phone_number.replace(prefix, prefix + ' ')
                                                                            : '';

                    this.dispatchEvent(new CustomEvent('validate', {
                        detail: {
                            data : this.phoneNumberDetails
                        }
                    }));
                    this.isLoading = false;
                    //console.log('PhoneDetails:',JSON.stringify(this.phoneNumberDetails));
                    //Create a copy
                    this.phoneNumberDetailsComp = {...this.phoneNumberDetails};
                    //
                    return this.phoneNumberDetails;
                }
            })
            .catch(error => {
                this.isLoading = false;
                console.error('Error:', error);
                this.isVerified = false;
                this.isUnVerified = true;
                this.phoneNumberDetails.confidence = error?.body?.message;
                this.phoneNumberDetails.confidence_description = error?.statusText;
                return null
            });
        } else {
            this.isVerified = (this.phoneNumberDetails.confidence === "Verified");
            this.isLoading = false;
            return this.phoneNumberDetails;
        }
        return null;
    }

    assignDefaultFlag(event){
        event.target.src = this.defaultFlag;
    }
    
    handleOnInput(event){
        this.showDropdown = true;
        this.inputCountry = event.target.value;
    }

    handleNumberChange(event){
        this.reset();
        this.clearValidation();
        this.numberEntered = event.target.value;
        this.phoneNumberDetails.entered_phone_number = this.numberEntered;
    }

    handleClearField(){
        this.reset();
        this.clearValidation();
    }

    handleShowDropDown(){
        if(this.showDropdown){
            this.showDropdown = false;
        }
        else{
            this.showDropdown = true;
            this.inputCountry = '';
            this.isSelected = false;
            this.selectedItem = undefined;
            this.dropdownfocus = true;
        }
    }

    handleSelectCountry(event) {
        let idx = event.currentTarget.dataset.id;
        this.selectedItem = event.currentTarget.dataset.category == 'top'
                            ? this.picklistOptionsTop[idx] 
                            : this.picklistOptionsRest[idx];

        this.isSelected = true;
        this.showDropdown = false;
        this.isCountryNotSelected = false;

        this.handleClearField();
    }

    hideDropDown(){
        this.isVerified = false;
        this.isUnVerified = false;
        this.stylecss = DEFAULT_STYLING;
        this.isCountryNotSelected = false;
        this.hasErrorOccured = false;
        if(!this.isSelected){
            this.isCountryNotSelected = true;
        }
    }

    handleDropDownBlur(){
        this.dropdownfocus = false;
        this.showDropdown = false;
    }

    handleDropDownFcous(){
        this.dropdownfocus = true;
    }

    handleBlur(){
        setTimeout(function(){
            if(this.showDropdown && !this.dropdownfocus){
                this.showDropdown = false;
            }
        }.bind(this), 300);
    }

    reset(){
        this.verificationStatus = '';
        this.numberEntered = '';
        this.isVerified = false;
        this.isUnVerified = false;
        this.stylecss = DEFAULT_STYLING;
        this.hasErrorOccured = false;
        this.phoneNumberDetailsComp = {};
        this.phoneNumberDetails.confidence = '';
        this.phoneNumberDetails.confidence_description = '';
        this.phoneNumberDetails.formatted_phone_number = '';
        this.phoneNumberDetails.phone_type = '';
        this.phoneNumberDetails.unicrm_formatted_phone_number = '';
        this.phoneNumberDetails.entered_phone_number = '';
    }

    clearValidation(){
        let mobileNumber = this.template.querySelector(".input");
        mobileNumber.setCustomValidity("");
        mobileNumber.reportValidity();
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
            areObjects && !deepEqual(val1, val2) ||
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

    handleKeydown(event) {        
        if (event.key === 'Enter') {
            this.handleSelectCountry(event);
        }
    }
}