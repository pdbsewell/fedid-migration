import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import validate from '@salesforce/apex/EDQPhoneNumberService.validate';

import PHONE_COUNTRY from '@salesforce/schema/Phone__c.Country__c';
import COUNTRY_ISO3 from '@salesforce/schema/Phone__c.Country__r.ISO_Alpha_3__c';
import PHONE_PHONE_NUMBER from '@salesforce/schema/Phone__c.Name';
import PHONE_VERIFICATION_STATUS from '@salesforce/schema/Phone__c.Verification_Status__c';

// constants
const STATUS_VERIFIED = 'Verified';

export default class experianPhoneValidationQuickAction extends LightningElement {
    @api recordId;

    isLoading = true;
    isCalledOnce = false;

    @wire(getRecord, { recordId: '$recordId', fields: [PHONE_COUNTRY, COUNTRY_ISO3, PHONE_PHONE_NUMBER, PHONE_VERIFICATION_STATUS] })
    loadPhoneDetails( result ) {
        if(this.isCalledOnce) return;
        
        if (result.data) {
            this.isCalledOnce = true;

            // If country is not set, throw an error
            if(!result?.data?.fields?.Country__c?.value){
                this.showToast('Cannot Validate', 'Country not set', 'error');
                this.closeQuickAction();
                return;
            }

            // Experian callout to validate phone number
            validate({
                phoneNumber : result?.data?.fields?.Name?.value,
                countryIsoCode : result?.data?.fields.Country__r?.value?.fields?.ISO_Alpha_3__c?.value
            })
            .then(res => {
                // Update phone record fields based on Experian validation result
                this.updatePhoneRecord(result.data.fields.Name.value, res);
            })
            .catch(error => {
                console.error('Error:', error);
                this.showToast("Error updating record", error.body.message, "error");
                this.closeQuickAction();
            });        
        } else if (result.error) { 
            console.error('Error:', result.error);
            this.showToast("Error updating record", result.error, "error");
            this.closeQuickAction();
        }
    }

    /*
     * Method Name: updatePhoneRecord
     * Description: Method to update the phone record
     */
    updatePhoneRecord(phoneNumber, res) {
        let record = {
            fields: {
                Id: this.recordId,
                Name: (res?.result?.confidence !== STATUS_VERIFIED) ? phoneNumber : res?.result?.formatted_phone_number,
                Verification_Status__c: res?.result?.confidence
            },
        };
        updateRecord(record)
        .then(() => {
            this.isLoading = false;
            this.showToast("Success", "Phone number validated", "success");
            this.closeQuickAction();
          })
          .catch((error) => {
            this.isLoading = false;
            this.showToast("Error updating record", error.body.message, "error");
            this.closeQuickAction();
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