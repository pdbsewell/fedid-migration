import {LightningElement,api,track,wire} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';

/* APEX SERVICES */
import getEntityData from "@salesforce/apex/ViewConvertedLeadsController.getEntityData";

export default class ViewConvertedLeads extends NavigationMixin(LightningElement) { 
    // form variables
    @api recordId;
    duplicateCount = 0;
    
    @track showSpinner = false;
    @track isAdminUser = false;
    @track openModal = false;
    @track data = [];
    @track hasData = false;

    @wire(getRecord, { recordId: '$recordId'})


    connectedCallback(){
        this.getData();
    }

    /*
     * Method Name: getData
     * Description: method to call apex function passing parameters from the UI
     */
    getData() {
        this.showSpinner = true;
        getEntityData({
            objectId : this.recordId
            })
            .then((result) => {
                console.log('davey: '+result);
                let datalist = result;   
                if (datalist.length > 0) { 
                    this.data = datalist;
                    this.hasData = true;
                }
                this.showSpinner = false;
            })
            .catch((error) => {
                this.showToast(
                    "Error",
                    "An error has occurred: " + error.body.message,
                    "Error"
                );
                this.hasData = false;
                this.showSpinner = false;
            });
    }

   
    //navigate to opportunity record
    handleLeadClick(event) { 
        const recId = event.currentTarget.dataset.id;
        this.navigateToRecord(recId);   
    }

    //navigate to account record
    handleAccountClick(event) { 
        const accId = event.currentTarget.dataset.id;
        this.navigateToRecord(accId);   
    }

    //navigate to sObject record 
    navigateToRecord(recId){
        if(recId){
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage', 
                attributes: {
                    recordId: recId,
                    actionName: 'view' 
                }
            }).then(url => {
                //Navigate to new Tab
                window.open(url);
            });
        }
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

    showModal() {
        // open modal
        this.openModal = true;
    }

    displayErrorToast(errorMessage){
        this.dispatchEvent(
            new ShowToastEvent({
                title : 'ERROR',
                message : errorMessage, 
                variant : 'error',
            }),
        )
    }

    closeModal() {
        // open modal
        this.openModal = false;
    }

}