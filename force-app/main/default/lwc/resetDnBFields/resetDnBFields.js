import {LightningElement,api,track} from "lwc";
import { CloseActionScreenEvent } from 'lightning/actions';

import {ShowToastEvent} from "lightning/platformShowToastEvent";
/* APEX SERVICES */
import clearFields from "@salesforce/apex/ResetDnBFieldsController.clearFields";

export default class ResetDnBFields extends LightningElement {
    @track showSpinner = false;
    @api recordId;

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    initiateClearFields(){
        this.showSpinner = true;
        clearFields({
            accountId : this.recordId 
        })
        .then((result) => {
            this.showToast('Success', 'DnB Fields reset.', 'success');
            this.closeQuickAction();
            this.showSpinner = false;
        })
        .catch((error) => {
            this.showToast("Error","An error has occurred: " + error.body.message,"Error");
            this.showSpinner = false;
        });   
    }

     /*
     * Method Name: showToast
     * Description: method to show Tost Message
     */
     showToast(title, message, type){
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message, 
                variant: type
            }),
        ); 
    }
}