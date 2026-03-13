import { LightningElement, api, track } from 'lwc';
import search from '@salesforce/apex/AddressSearchController.search';
import format from '@salesforce/apex/AddressSearchController.format';
import getTopCountriesList from '@salesforce/apex/AddressSearchController.getTopCountriesList';
import getRestOfTheCountriesList from '@salesforce/apex/AddressSearchController.getRestOfTheCountriesList';
import getAddressWrapper from '@salesforce/apex/AddressSearchController.getAddressWrapper';
import getMinimumSecondsBetweenInvocations from '@salesforce/apex/ExperianUtility.getMinimumSecondsBetweenInvocations';
import graphicsPack from '@salesforce/resourceUrl/GraphicsPackNew';

// import custom labels
import displayEDQConsoleLogs from '@salesforce/label/c.Display_EDQ_console_logs';
import pleaseTryLaterMessage from '@salesforce/label/c.Experian_Address_Try_Again_Later_Message';
import countryNotSelectedMessage from '@salesforce/label/c.Experian_No_Country_Selected_Message';
import experianUnavailableMessage from '@salesforce/label/c.Experian_Unavailable_Or_Out_Of_Credits';
import FORM_FACTOR from '@salesforce/client/formFactor';

// constants
const DELAY = 300;
const EXPERIAN_RATELIMITING_CUSTOMSETTING = 'Experian Address Search';
const DEFAULT_STYLING = 'border: 1px solid lightgray; border-radius: 3px;';
const GUESTKEY_TEMPLATE = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx';
const CONFIDENCE_VALUE_MANUAL = 'Manual';

export default class SearchComponent extends LightningElement {

    @api iconName = 'utility:location';                     // Search result icon
    @api isAddressDisabled = false;                         // True if field is readOnly
    @api currentRecordId;                                   // Record Id of the current record, when form is a detail page
    @api placeholder = 'Enter in your address details';     // Address bar place holder
    @api addressSearchlabel = 'Address search';             // Address bar label
    @api doNotShowCountryFlags = false;                     // Display country flags or not (Default: Show country flags)
    @api doNotShowLocationIcon = false;                     // Display location icon or not (Default: Show icon)
    @api countryISOPassed;                                  // ISO Alpha 3 code for a Country
    @api manualCheckboxTop = false;                         // Determines if the manual entry checkbox needs to be at the top or below address search (Default: Below)
    @api manualFieldsHidden = false;                        // Show/Hide address fields in manual mode (Default: Manual fields are visible)
    @api manualFieldsStacked = false;                       // Determines if the address fields need to be stacked or placed horizontally (Default: Horizontal)
    @api defaultCountry;                                    // Sets the default value to Australia

    

    // Manual fields RegEx
    @api streetRegEx;                                       // RegEx to validate format of the street entered
    @api cityRegEx;                                         // RegEx to validate format of the city entered
    @api stateRegEx;                                        // RegEx to validate format of the state entered
    @api postCodeRegEx;                                     // RegEx to validate format of the postcode entered
    
    // Mandatory manual fields
    @api streetMandatory = false;                           // Determines if Street field is mandatory. (Default: Optional)
    @api cityMandatory = false;                             // Determines if City field is mandatory. (Default: Optional)
    @api stateMandatory = false;                            // Determines if State field is mandatory. (Default: Optional)
    @api postCodeMandatory = false;                         // Determines if Post Code field is mandatory. (Default: Optional)
    
    // Labels styling
    @api countryLabelCss;                                   // Set the styling for Country drop down label
    @api addressSearchLabelCss;                             // Set the styling for address search label
    @api cantFindAddressLabelCss = 'font-style: italic; font-size: 0.75rem;'; // Set the styling for 'Cant find your address?' checbox label
    @api manualFieldsLabelCss;                              // Set the styling for all the manual fields label
    @api componentName;                         // Provide component Name on Multiple Instances

    @track error;
    @track isManual = false;

    searchTerm;
    delayTimeout;
    countryISO = '';
    searchRecords;
    objectLabel;
    selectedRecord;
    selectedSplitRecord;
    fullAddress;
    frequentCountryAttributeResult = [];
    restCountryAttributeResult = [];
    ICON_URL = '/apexpages/slds/latest/assets/icons/{0}-sprite/svg/symbols.svg#{1}';
    textvalue = '';
    addressDetails = {};
    displayLog = displayEDQConsoleLogs;
    showDropdown = false;
    selectedItem;
    isSelected;
    defaultFlag = graphicsPack + '/fatcow/farmfresh/16/mail_box.png';
    inputCountry = '';
    hasErrorOccured = false;
    errorMessage;
    tryAgainLaterMessage = pleaseTryLaterMessage;
    selectCountryMessage = countryNotSelectedMessage;
    streetValidationMessage;
    cityValidationMessage;
    stateValidationMessage;
    postCodeValidationMessage;
    minimumSecondsBetweenInvocations = 0;
    showCountryValidationMessage = false;
    guestKey = null;
    dropdownfocus = false;
    addressComponents;

    connectedCallback(){
        let icons           = this.iconName.split(':');
        this.ICON_URL       = this.ICON_URL.replace('{0}',icons[0]);
        this.ICON_URL       = this.ICON_URL.replace('{1}',icons[1]);
        this.showDropdown   = false;
        this.handleAddressWrapper();
        this.retrieveTopCountryAttributes();
        this.retrieveRestCountryAttributes();
        this.retrieveMinimumSecondsBetweenInvocations(EXPERIAN_RATELIMITING_CUSTOMSETTING);
    }

    @api
    getAddress(){
        this.addressDetails.splitRecord.address_line_full = this.addressLineFull;
        this.addressDetails.manualAddressValidity = this.manualAddressValidity;
        return this.addressDetails;
    }

    /**
     * Retrieve top country details
     */    
     retrieveTopCountryAttributes(){
        getTopCountriesList()
        .then((result) => {
            this.frequentCountryAttributeResult = result;
            if (this.defaultCountry && !this.selectedItem) {
                this.inputCountry = this.defaultCountry;
                let fromTop = this.picklistOptionsTop;
                if (fromTop?.length) this.selectedItem = fromTop[0];
                this.isSelected = !!this.selectedItem;
                this.setCountryValue();
            }
            
        })
        .catch((error) => {
            this.error = error;
        });
    }

    /**
     * Retrieve rest of the country details
     */    
    retrieveRestCountryAttributes(){
        getRestOfTheCountriesList()
        .then((result) => {
            this.restCountryAttributeResult = result;
        })
        .catch((error) => {
            this.error = error;
        });
    }

    /**
     * Retrieve address wrapper
     */ 
    handleAddressWrapper(){
        getAddressWrapper()
        .then((result) => {
            let temp = JSON.parse(JSON.stringify(result));
            this.addressDetails = temp;
            this.addressDetails.currentRecordId = this.currentRecordId ?? '';
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

    get picklistOptionsRest(){
        if(this.inputCountry){
            // Show countries in the picklist based on user entry
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
        return this.selectedItem?.name ?? 'Select a Country…';
    }

    get isSearchDisabled() {
        if(this.defaultCountry === 'Australia'){
            return false;
        }
        else{
            return (this.isAddressDisabled || ((this.countryISO === '' || (this.isManual && this.countryISO != '')) && !this.countryISOPassed));
        }
        
    }

    get isManualDisabled() {
        return (this.isAddressDisabled || (this.countryISO === '' && !this.countryISOPassed));
    }

    get addressLine1() {
        return this.addressDetails?.splitRecord?.address_line_1 ?? '';
    }

    get addressLine2() {
        return this.addressDetails?.splitRecord?.address_line_2 ?? '';
    }

    get addressLine3() {
        return this.addressDetails?.splitRecord?.address_line_3 ?? '';
    }

    get addressLineFull() {
        return this.addressLine1 + 
                ((this.addressLine1 !== '' && (this.addressLine2 !== '' || this.addressLine3 !== '')) ? ',' : '') + 
                this.addressLine2 + 
                ((this.addressLine2 !== '' && this.addressLine3 !== '') ? ',' : '') + 
                this.addressLine3 +
                ((this.district !== '' && !this.addressLine1.includes(this.district) && !this.addressLine2.includes(this.district) && !this.addressLine3.includes(this.district)) 
                ? (',' + this.district) 
                : '');
    }

    get district(){
        return this.addressComponents?.locality?.district?.name ?? '';
    }

    get isClearIconHidden() {
        return (this.textvalue === undefined || this.textvalue === '');
    }

    get addressSearchSize(){
        return this.countryISOPassed ? 12 : 8;
    }

    get manualAddressValidity(){
        if(this.isManual){
            if(this.manualFieldsHidden || (this.validateCountry() && this.validateStreet() && this.validateCity() && this.validateState() && this.validatePostCode())){
                return 'valid';
            }
            else{
                return 'invalid';
            }
        }
        else{
            return null;
        }
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

    handleInputChange(event){
        this.hasErrorOccured = false;
        this.errorMessage = '';
        this.showCountryValidationMessage = false;
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        this.textvalue = searchKey;
        
        this.delayTimeout = setTimeout(() => {
            if(searchKey.length >= 2){
                search({ 
                    searchTerm : searchKey,
                    countryISO : this.countryISOPassed ?? this.countryISO
                })
                .then(res => {
                    // If Experian service is down or out of Experian credits, auto select manual address entry
                    if(res?.result?.confidence === 'Service Unavailable' || res?.result?.confidence === 'Forbidden'){
                        this.isManual = true;
                        this.resetDetails();
                        this.addressDetails.splitRecord.country = this.countryName;
                        this.addressDetails.confidence = CONFIDENCE_VALUE_MANUAL;
                        this.hasErrorOccured = true;
                        this.errorMessage = experianUnavailableMessage;
                    }
                    if(res?.result?.suggestions){
                        let stringResult = JSON.stringify(res.result.suggestions);
                        let allResult    = JSON.parse(stringResult);
                        allResult.forEach( record => {
                            record.addressKey = record['global_address_key'];
                            record.addressText = record['text'];
                        });
                        this.searchRecords = allResult;
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                });
            }
        }, DELAY);
    }

    handleSelect(event){
        this.hasErrorOccured = false;
        this.errorMessage = '';
        this.fullAddress = '';
        let recordId = event.currentTarget?.dataset?.recordId;
        
        let selectRecord = this.searchRecords.find((item) => {
            return item.addressKey === recordId;
        });
        this.selectedRecord = selectRecord;
        this.handleSplitAddress();
    }

    handleSplitAddress(){
        if(this.selectedRecord?.addressKey){
            format({ 
                addressKey : this.selectedRecord.addressKey,
                customSettingName : EXPERIAN_RATELIMITING_CUSTOMSETTING,
                guestKey : this.getGuestKey()
            })
            .then(res => {
                if(res == null) {
                    this.hasErrorOccured = true;
                    this.errorMessage = this.tryAgainLaterMessage;
                    this.errorMessage = this.errorMessage.replace('#', this.minimumSecondsBetweenInvocations);
                    this.selectedRecord = undefined;
                }
                else{
                    this.hasErrorOccured = false;
                    this.errorMessage = '';
                    this.selectedSplitRecord = res?.result?.address;
                    this.addressComponents = res?.result?.components;

                    let dpid = res?.metadata?.address_info?.identifier?.dpid ?? '';
                    this.setDetails(dpid, res?.result?.confidence);
                    this.fullAddress = this.addressDetails.splitRecord.address_line_full + ', ' +
                            this.addressDetails.splitRecord.locality + ', ' +
                            this.addressDetails.splitRecord.region + ' ' +
                            this.addressDetails.splitRecord.postal_code;
                    if(this.displayLog === 'true') console.log(this.getAddress());

                    this.dispatchEvent(new CustomEvent('validate', {
                        detail: {
                            data : this.addressDetails
                        }
                    }));
                }
            })
            .catch(error => {
                console.error('Error:', error);
            });
        }
    }

    setCountryValue(){
        this.isSelected = true;
        this.showCountryValidationMessage = false;
        this.hasErrorOccured = false;
        this.showDropdown = false;

        this.countryISO = this.selectedItem?.isoCode;

        if(this.isManual){
            this.addressDetails.splitRecord.country = this.countryName;
            this.addressDetails.confidence = '';
        }
        else{
            this.textvalue = '';
            this.selectedRecord = undefined;
            this.searchRecords  = undefined;
        }
    }

    handleSelectCountry(event){
        let idx = event.currentTarget.dataset.id;
        this.selectedItem = event.currentTarget.dataset.category == 'top'
                            ? this.picklistOptionsTop[idx] 
                            : this.picklistOptionsRest[idx];
        this.setCountryValue();
    }

    handleManualEntry(event) {
        this.isManual = event.target.checked;
        console.log('IS MANUAL ' + this.isManual);
        this.resetDetails();
        this.addressDetails.splitRecord.country = this.countryName;
        
        if(this.isManual){
            this.addressDetails.confidence = CONFIDENCE_VALUE_MANUAL;
        }
        else{
            this.addressDetails.confidence = '';
        }
        this.dispatchEvent(new CustomEvent('manualaddressentry', {
            detail: {
                data : this.addressDetails
            }
        }));
        
    }
    
    handleAddressLine1Change(event) {
        this.addressDetails.splitRecord.address_line_1 = event.detail.value;
        if(this.displayLog === 'true') console.log(this.getAddress());
    }

    handleAddressLine2Change(event) {
        this.addressDetails.splitRecord.address_line_2 = event.detail.value;
        if(this.displayLog === 'true') console.log(this.getAddress());
    }

    handleAddressLine3Change(event) {
        this.addressDetails.splitRecord.address_line_3 = event.detail.value;
        if(this.displayLog === 'true') console.log(this.getAddress());
    }

    handleCityChange(event) {
        this.addressDetails.splitRecord.locality = event.detail.value;
        if(this.displayLog === 'true') console.log(this.getAddress());
    }

    handleStateChange(event) {
        this.addressDetails.splitRecord.region = event.detail.value;
        if(this.displayLog === 'true') console.log(this.getAddress());
    }

    handlePostCodeChange(event) {
        this.addressDetails.splitRecord.postal_code = event.detail.value;
        if(this.displayLog === 'true') console.log(this.getAddress());
    }
    
    handleInputCountry(event){
        this.inputCountry = event.target.value;
    }

    handleOnInput(event){
        this.showDropdown = true;
        this.inputCountry = event.target.value;
    }

    handleShowDropDown(){
        if(this.showDropdown){
            this.showDropdown = false;
        }
        else{
            this.showDropdown = true;
            this.inputCountry = '';
            this.countryISO = '';
            this.addressDetails.splitRecord.country = '';
            this.isSelected = false;
            this.defaultCountry = '';
            this.dropdownfocus = true;
        }
    }

    hideDropDown(){
        if(!this.isSelected){
            this.showCountryValidationMessage = (!this.countryISO && !this.countryISOPassed)
                                                ? true
                                                : false;
            this.hasErrorOccured = this.showCountryValidationMessage;
            this.errorMessage = this.showCountryValidationMessage
                                ? this.selectCountryMessage
                            : '';
        }
    }

    handleClearField(){
        this.resetDetails();
        this.template.querySelectorAll(".addressfield").forEach(function(element) { element.value = ''});
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

    setDetails(dpid, confidence){
        this.addressDetails.dpId = dpid;
        this.addressDetails.splitRecord = this.selectedSplitRecord;
        this.addressDetails.splitRecord.country = this.countryName;
        this.addressDetails.splitRecord.address_line_full = this.addressLineFull;
        this.addressDetails.confidence = confidence;
    }

    resetDetails(){
        this.textvalue = '';
        this.selectedRecord = undefined;
        this.searchRecords  = undefined;
        this.selectedSplitRecord = undefined;
        this.hasErrorOccured = false;
        this.errorMessage = '';
        this.addressDetails.dpId = '';
        this.addressDetails.confidence = '';
        this.addressDetails.splitRecord.address_line_1 = '';
        this.addressDetails.splitRecord.address_line_2 = '';
        this.addressDetails.splitRecord.address_line_3 = '';
        this.addressDetails.splitRecord.address_line_full = '';
        this.addressDetails.splitRecord.locality = '';
        this.addressDetails.splitRecord.region = '';
        this.addressDetails.splitRecord.postal_code = '';
        this.addressDetails.splitRecord.country = '';

        this.streetValidationMessage = undefined;
        this.cityValidationMessage = undefined;
        this.stateValidationMessage = undefined;
        this.postCodeValidationMessage = undefined;
        this.dispatchEvent(new CustomEvent('clearaddressdetails', {
            detail: {
                data : this.addressDetails
            }
        }));
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

    validateCountry(){
        return this.addressDetails.splitRecord.country 
                ? true 
                : false;
    }

    validateStreet(){
        let isValid = true;
        this.streetValidationMessage = undefined;

        let regEx = new RegExp('^'+this.streetRegEx+'$');

        let street = this.addressDetails.splitRecord.address_line_1;
        if(this.streetMandatory && street.trim().length === 0 ) {
            this.streetValidationMessage = 'Please enter street details';
            isValid = false;
        }
        else if(this.streetRegEx && !street.match(regEx)){
            this.streetValidationMessage = 'Please enter correct street format';
            isValid = false;
        }
        return isValid;
    }

    validateCity(){
        let isValid = true;
        this.cityValidationMessage = undefined;

        let regEx = new RegExp('^'+this.cityRegEx+'$');

        let city = this.addressDetails.splitRecord.locality;
        if(this.cityMandatory && city.trim().length === 0){
            this.cityValidationMessage = 'Please enter the city';
            isValid = false;
        }
        else if(this.cityRegEx && !city.match(regEx)){
            this.cityValidationMessage = 'Please enter correct city format';
            isValid = false;
        }
        return isValid;
    }

    validateState(){
        let isValid = true;
        this.stateValidationMessage = undefined;

        let regEx = new RegExp('^'+this.stateRegEx+'$');

        let state = this.addressDetails.splitRecord.region;
        if(this.stateMandatory && state.trim().length === 0){
            this.stateValidationMessage = 'Please enter the state';
            isValid = false;
        }
        else if(this.stateRegEx && !state.match(regEx)){
            this.stateValidationMessage = 'Please enter correct state format';
            isValid = false;
        }
        return isValid;
    }

    validatePostCode(){
        let isValid = true;
        this.postCodeValidationMessage = undefined;

        let regEx = new RegExp('^'+this.postCodeRegEx+'$');

        let postCode = this.addressDetails.splitRecord.postal_code;
        if(this.postCodeMandatory && postCode.trim().length === 0){
            this.postCodeValidationMessage = 'Please enter post code';
            isValid = false;
        }
        else if(this.postCodeRegEx && !postCode.match(regEx)){
            this.postCodeValidationMessage = 'Please enter correct post code format';
            isValid = false;
        }
        return isValid;
    }

    createPicklistOptions(picklistInput){
        return picklistInput.map(function (element) {
            return {id: element.Id,
                    flag: graphicsPack + '/flags/16/flags/' + element.ISO_Alpha_2__c.toLowerCase() + '.png', 
                    name: element.Country__c,
                    isoCode: element.ISO_Alpha_3__c}
          });
    }

    assignDefaultFlag(event){
        event.target.src = this.defaultFlag;
    }

    handleKeydown(event) {        
        if (event.key === 'Enter') {
            this.handleSelectCountry(event);
        }
    }
    handleKeydownAddress(event) {        
        if (event.key === 'Enter') {
            this.handleSelect(event);
        }
    }
}