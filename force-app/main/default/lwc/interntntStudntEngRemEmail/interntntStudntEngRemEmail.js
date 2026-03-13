import {LightningElement,api, track} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import { NavigationMixin } from 'lightning/navigation';
import LightningConfirm from 'lightning/confirm';

/* APEX SERVICES */
import sendReminderEmail from "@salesforce/apex/InterntntStudntEngRemEmailCntrl.sendReminderEmail";
import filterRecepients from "@salesforce/apex/InterntntStudntEngRemEmailCntrl.filterRecepients";

export default class InterntntStudntEngRemEmail extends LightningElement {

    @track showSpinner = false;
    @api campaignRecordId;
    revisedCaseIdList = [];

    connectedCallback(){
        this.filterRecepients();
    }

    sendReminderEmail(){
        this.showSpinner = true;
        sendReminderEmail({
            campaignRecordId : this.campaignRecordId,
            l_revisedCaseIdList : this.revisedCaseIdList
        })
        .then((result) => {
            this.showToast(
                "Success",
                "The Emails have been initiated",
                "Success"
            );
            this.showSpinner = false;
            this.closeForm();
        })
        .catch((error) => {
            this.showToast(
                "Error",
                "An error has occurred: " + error.body.message,
                "Error"
            );
            this.showSpinner = false;
        });
    }

    filterRecepients(){
        this.showSpinner = true;
        filterRecepients({
            campaignRecordId : this.campaignRecordId
        })
        .then((result) => {
            this.showSpinner = false;
            this.revisedCaseIdList = result;
            let count;
            if(result === '' || result === null  || result === undefined) {
                count = 0;
            }else{
                count = result.length;
            }
            this.validateRecepientCount(count);
        })
        .catch((error) => {
            this.showToast(
                "Error",
                "An error has occurred: " + error.body.message,
                "Error"
            );
            this.showSpinner = false;
        });
    }

    async validateRecepientCount(count){
        const result = await LightningConfirm.open({
            message: "The Reminder email will be sent to " + count + " students, do you wish to continue?",
            theme: "success",
            label: "Confirm"
        });
        if(result){
            this.sendReminderEmail();
        }else{
            this.closeForm();
        } 
    }

    //close form
    closeForm(){
        const action = 'close';
        //request subtab to be closed
        const dispatchEvent = new CustomEvent('requestclose', {
            detail: { action }
        });
        this.dispatchEvent(dispatchEvent);
    }

    /*
    * Method Name: showToast
    * Description: method to show toast
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