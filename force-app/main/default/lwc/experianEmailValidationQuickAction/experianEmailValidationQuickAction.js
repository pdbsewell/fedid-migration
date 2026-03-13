import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import validate from '@salesforce/apex/EDQEmailService.validate';

import EMAIL_EMAIL_ADDRESS from '@salesforce/schema/Email__c.Name';

// constants
const STATUS_UNREACHABLE = 'unreachable';

export default class ExperianEmailValidationQuickAction extends LightningElement {
    @api recordId;

    isLoading = true;
    isCalledOnce = false;

    @wire(getRecord, { recordId: '$recordId', fields: [EMAIL_EMAIL_ADDRESS] })
    loadEmailDetails( result ) {
        if(this.isCalledOnce) return;
        
        if (result.data) {
            this.isCalledOnce = true;

            // Experian callout to validate Email
            validate({
                email : result?.data?.fields?.Name?.value
            })
            .then(res => {
                // Update email record fields based on Experian validation result
                this.updatePhoneRecord(result?.data?.fields?.Unreachable_Reason__c?.value, res);
            })
            .catch(error => {
                console.error('Error:', error);
                this.showToast("Error updating record", error.body.message, "error");
            });        
        } else if (result.error) { 
            console.error('Error:', result.error);
            this.closeQuickAction();
            this.showToast("Error updating record", result.error, "error");
        }
    }

    /*
     * Method Name: updatePhoneRecord
     * Description: Method to update the phone record
     */
    updatePhoneRecord(reason, res) {
        let status = res?.result?.confidence;
        let record = {
            fields: {
                Id: this.recordId,
                Verification_Status__c: status.substring(0, 1).toUpperCase() + status.substring(1, status.length),
                Unreachable__c: (status === STATUS_UNREACHABLE)? true : false
            },
        };
        updateRecord(record)
        .then(() => {
            this.isLoading = false;
            this.showToast("Success", "Email validated", "success");
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