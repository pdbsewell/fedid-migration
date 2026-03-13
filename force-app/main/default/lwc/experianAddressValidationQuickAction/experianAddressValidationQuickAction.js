import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import search from '@salesforce/apex/AddressSearchController.search';
import format from '@salesforce/apex/AddressSearchController.format';
import getAddressWrapper from '@salesforce/apex/AddressSearchController.getAddressWrapper';
import getMinimumSecondsBetweenInvocations from '@salesforce/apex/ExperianUtility.getMinimumSecondsBetweenInvocations';
import retrieveCountryRecord from '@salesforce/apex/EDQAddressService.retrieveCountryRecord';

import ADDRESS_SOURCE from '@salesforce/schema/Address__c.Source__c';
import ADDRESS_COUNTRY from '@salesforce/schema/Address__c.Country2__c';
import STREET_NAME from '@salesforce/schema/Address__c.Street_Name__c';

// constants
const SOURCE_CALLISTA = 'Callista';
const ERROR_MESSAGE_CALLISTA = 'Addresses from Callista will not be validated';
const ERROR_MESSAGE_COUNTRY = 'Country not set';
const TOAST_VARIANT_ERROR = 'error';
const TOAST_VARIANT_WARNING = 'warning';

const DELAY = 300;
const EXPERIAN_RATELIMITING_CUSTOMSETTING = 'Experian Address Search';
const GUESTKEY_TEMPLATE = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx';

export default class experianAddressValidationQuickAction extends LightningElement {
    @api recordId;

    // Labels styling
    @api countryLabelCss;                                   // Set the styling for Country drop down label
    @api addressSearchLabelCss;                             // Set the styling for address search label
    @api cantFindAddressLabelCss = 'font-style: italic; font-size: 0.75rem;'; // Set the styling for 'Cant find your address?' checbox label

    error;
    isManual = false;

    isLoading = true;
    isCalledOnce = false;
    countryISO = null;
    searchAddress = null;
    delayTimeout;
    textvalue = '';
    searchRecords;
    objectLabel;
    selectedRecord;
    selectedSplitRecord;
    fullAddress;
    showDropdown = false;
    selectedItem;
    isSelected;
    dropdownfocus = false;
    addressComponents;
    addressDetails = {};
    errorMessage;
    ICON_URL = '/apexpages/slds/latest/assets/icons/{0}-sprite/svg/symbols.svg#{1}';

    @wire(getRecord, { recordId: '$recordId', fields: [ADDRESS_SOURCE, ADDRESS_COUNTRY, STREET_NAME] })
    loadAddressDetails( result ) {
        if(this.isCalledOnce) return;
        
        if (result.data) {
            this.isCalledOnce = true;

            let errorMessage = null;
            let toastVariant = TOAST_VARIANT_ERROR;

            this.searchAddress = result?.data?.fields?.Street_Name__c?.value

            // If address source is Callista, throw an warning
            if(result?.data?.fields?.Source__c?.value === SOURCE_CALLISTA){
                errorMessage = ERROR_MESSAGE_CALLISTA;
                toastVariant = TOAST_VARIANT_WARNING;
            }

            // If country is not set, throw an error
            if(!result?.data?.fields?.Country2__c?.value){
                errorMessage = ERROR_MESSAGE_COUNTRY;
            }
            if(errorMessage){
                this.showToast('Validation Failed', errorMessage, toastVariant);
                this.closeQuickAction();
                return;
            }
            this.isLoading = false;
            this.getCountryRecord(result?.data?.fields?.Country2__c?.value);    
        } else if (result.error) { 
            console.error('Error:', result.error);
            this.closeQuickAction();
            this.showToast("Error updating record", result.error, "error");
        }
    }

    connectedCallback(){
        this.handleAddressWrapper();
        this.retrieveMinimumSecondsBetweenInvocations(EXPERIAN_RATELIMITING_CUSTOMSETTING);
    }

    /*
     * Method Name: updatePhoneRecord
     * Description: Method to update the phone record
     */
    updateAddressRecord() {
        let record = {
            fields: {
                Id: this.recordId,
                Street_Name__c : this.addressDetails?.splitRecord?.address_line_full,
                City__c : this.addressDetails?.splitRecord?.locality,
                State__c : this.addressDetails?.splitRecord?.region,
                Post_Code__c : this.addressDetails?.splitRecord?.postal_code,
                DPID__c : this.addressDetails?.dpId,
                Verification_Status__c : this.addressDetails?.confidence
            },
        };
        updateRecord(record)
        .then(() => {
            this.isLoading = false;
            this.showToast("Success", "Address validated", "success");
            this.closeQuickAction();
          })
          .catch((error) => {
            this.isLoading = false;
            this.showToast("Error updating record", error.body.message, "error");
            this.closeQuickAction();
          });
    }

    /**
     * Retrieve country record
     */ 
    getCountryRecord(countryString){
        retrieveCountryRecord({country : countryString})
        .then((result) => {
            this.countryISO = result?.ISO_Alpha_3__c;
            this.handlePassedAddress();
        })
        .catch((error) => {
            this.error = error;
        });
    }

    get isSearchDisabled() {
        if(this.defaultCountry === 'Australia'){
            return false;
        }
        else{
            return (this.isAddressDisabled || ((this.countryISO === '' || (this.isManual && this.countryISO != '')) && !this.countryISOPassed));
        }
        
    }

    get isClearIconHidden() {
        return (this.textvalue === undefined || this.textvalue === '');
    }

    get district(){
        return this.addressComponents?.locality?.district?.name ?? '';
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

    handleInputChange(event){
        this.hasErrorOccured = false;
        this.errorMessage = '';
        this.showCountryValidationMessage = false;
        window.clearTimeout(this.delayTimeout);
        let searchKey = event.target.value;
        this.textvalue = searchKey;
        this.addressSearch(this.textvalue);
    }

    handlePassedAddress(){
        this.textvalue = this.searchAddress;
        console.log('searchAddress:',this.searchAddress);
        this.addressSearch(this.searchAddress);
    }

    addressSearch(input){
        //this.delayTimeout = setTimeout(() => {
            if(input.length >= 2){
                search({ 
                    searchTerm : input,
                    countryISO : this.countryISOPassed ?? this.countryISO
                })
                .then(res => {
                    // If Experian service is down or out of Experian credits
                    if(res?.result?.confidence === 'Service Unavailable'){
                        this.showToast('Validation Failed', "Currently experiencing technical difficulties, please try again later.", "error");
                        this.closeQuickAction();
                    }
                    if(res?.result?.confidence === 'Forbidden'){
                        this.showToast('Validation Failed', "Out of Experian credits!", "error");
                        this.closeQuickAction();
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
        //}, DELAY);
    }

    handleSelect(event){
        this.isLoading = true;
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
        console.log('in handleSplitAddress:',this.selectedRecord);
        if(this.selectedRecord?.addressKey){
            format({ 
                addressKey : this.selectedRecord.addressKey,
                customSettingName : EXPERIAN_RATELIMITING_CUSTOMSETTING,
                guestKey : this.getGuestKey()
            })
            .then(res => {
                console.log(JSON.parse(JSON.stringify(res)));
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
                    //if(this.displayLog === 'true') console.log(this.getAddress());
                    this.updateAddressRecord();
                    //this.closeQuickAction();
                }
            })
            .catch(error => {
                console.error('Error:', error);
            });
        }
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

    setDetails(dpid, confidence){
        this.addressDetails.dpId = dpid;
        this.addressDetails.splitRecord = this.selectedSplitRecord;
        //this.addressDetails.splitRecord.country = this.countryName;
        this.addressDetails.splitRecord.address_line_full = this.addressLineFull;
        this.addressDetails.confidence = confidence;

        console.log(this.addressDetails);
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

    handleClearField(){
        console.log('clear');
        this.resetDetails();
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

    /*
     * Method Name: closeQuickAction
     * Description: Method to close quick action modal
     */
    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    /*
     * Method Name: showToast
     * Description: Method to show toast
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