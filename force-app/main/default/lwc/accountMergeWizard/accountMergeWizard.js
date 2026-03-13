import {LightningElement,api,track,wire} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';

/* APEX SERVICES */
import getEntityData from "@salesforce/apex/AccountMergeController.getEntityData";
import mergeAccounts from "@salesforce/apex/AccountMergeController.mergeAccounts";

export default class AccountMergeWizard extends NavigationMixin(LightningElement) { 
    // form variables
    @api recordId;
    duplicateCount = 0;
    
    @track showSpinner = false;
    @track isAdminUser = false;
    @track openModal = false;
    @track data = [];
    @track hasData = false;

    @wire(getRecord, { recordId: '$recordId', fields: [ 'Account.Name', 'Account.DBC_DUNS_Number__c','Account.Website','Account.TickerSymbol','Account.BillingCountry' ]})
    getDuplicateRecords({ data, error }) {
        if (data) {
            this.getData();
        }
    }

    doValidation(){
        // Check if the primary Account Account is Included
        let primaryAccount = this.data.filter(rec => rec.isPrimary == true);
        if(primaryAccount.length == 1 && !primaryAccount[0].isIncluded){
            this.displayErrorToast('Include the Primary Account to merge');
            return false;
        }
        // Check is more than 1 Account is selected
        let isIncludedCount = this.data.filter(rec => rec.isIncluded == true);
        if(isIncludedCount.length < 2 ){
            this.displayErrorToast('Include at-least 1 Non Primary Account to merge');
            return false;
        }
        if(isIncludedCount.length > 6 ){
            this.displayErrorToast('At a time you can merge maximum 5 Records');
            return false;
        }
        return true;
    }

    /*
     * Method Name: mergeOnClick
     * Description: method to start the merge process
     */
    mergeOnClick() {
        //Initiate Validation
        if (this.doValidation()) {
            //Begin Merge
            this.mergeAccounts();             
        }
    }

    async mergeAccounts(){ 
        let primaryAccountId;
        let duplicateAccountIds = [];
        this.data.forEach((rec) => {
            // set data value
            if (rec.isPrimary) {
                primaryAccountId = rec.id;
            }else if(!rec.isPrimary && rec.isIncluded){ 
                duplicateAccountIds.push(rec.id);
            }
        });
        this.showSpinner = true;
        let accountsMerged = 1;
        let initiateGivingSummary = false;
        for(let duplicateAccountId of duplicateAccountIds){
            if(accountsMerged == duplicateAccountIds.length){
                initiateGivingSummary = true;
            }
            let respVal;
            respVal = await mergeAccounts({
                        primaryAccountId: primaryAccountId, 
                        duplicateAccountId : duplicateAccountId,
                        initiateGivingSummary : initiateGivingSummary
                    })
                    .then((res) => { 
                    })
                    .catch((error) => {
                        console.error(error);
                        let errorMessage;
                        if(error.reason != undefined){
                            errorMessage = error.reason;
                        }else{
                            errorMessage = error.body.message;
                        } 
                        this.showToast(
                            "Error",
                            "An error has occurred. Message: " + errorMessage,
                            "Error"
                        );
                        this.showSpinner = false;
                    });
            accountsMerged++;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: primaryAccountId,
                objectApiName: 'Account',
                actionName: 'view'
            }
        });
    }

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
                onLoadAccountId : this.recordId
            })
            .then((result) => {
                let datalist = result.relatedAccounts;   
                if (datalist.length > 0 && !(datalist.length == 1 && datalist[0].id == this.recordId)) { 
                    //this.data = [];
                    this.data = datalist;
                    this.duplicateCount = datalist.length - 1;
                    this.hasData = true;
                    this.isAdminUser = result.isAdminUser;
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

    // When User click on Non Primary Row ..
    handlePrimaryChange(event) { 
        let recId = event.currentTarget.dataset.id;
        this.data.forEach((rec) => {
            if(rec.id === recId){
                rec.isPrimary=true;
                rec.isIncluded=true;
            }else{
                rec.isPrimary=false;
            } 
        });
    }

    handleIsIncludedChange(event) { 
        let recId = event.currentTarget.dataset.id;
        this.data.forEach((rec) => {
            if(rec.id === recId){
                if(rec.isIncluded){
                    rec.isIncluded = false;
                }else{
                    rec.isIncluded = true;
                } 
            } 
        });
    }

    handleAccountClick(event) { 
        const recId = event.currentTarget.dataset.id;
        this.navigateToAccountRecord(recId);   
    }

    navigateToAccountRecord(recId){
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
     * Method Name: toggleInclusion
     * Description: method to toggle data isIncluded flag and the include button class based from the ui selection
     */
    toggleInclusion(event) {
        let recid = event.target.dataset.recid;

        this.data.forEach((rec) => {
            // set data value
            if (rec.contactRecord.Id === recid) {
                rec.isIncluded = !rec.isIncluded;
            }

            // set include button class when selected
            if (rec.isIncluded) {
                rec.includeClass = "success";
            }
            // set include button class when unselected
            else {
                rec.includeClass = "neutral";

                // if the record is unselected but primary, revert the unselection
                if (rec.isPrimary) {
                    rec.isIncluded = true;
                    rec.includeClass = "success";
                }
            }
        });
    }

    /*
     * Method Name: togglePrimary
     * Description: method to toggle data isPrimary flag and the primary button class based from the ui selection
     */
    togglePrimary(event) {
        let recid = event.target.dataset.recid;

        let hasPrimary = false;
        // toggle own button
        this.data.forEach((rec) => {
            // set data value
            if (rec.contactRecord.Id === recid) {
                rec.isPrimary = !rec.isPrimary;
            } else {
                rec.isPrimary = false;
            }

            // set primary button class when selected
            if (rec.isPrimary) {
                rec.primaryClass = "success";
                // if the record is selected as primary, force include it
                if (!rec.isIncluded) {
                    rec.isIncluded = true;
                    rec.includeClass = "success";
                }
            }
            //set include button class when unselected
            else {
                rec.primaryClass = "neutral";
            }
            // boolean checker that the list has a primary record
            if (rec.isPrimary) {
                hasPrimary = true;
            }
        });

        // check if none is toggled as primary, if true then force primary the first in the list
        if (!hasPrimary) {
            this.data[0].isIncluded = true;
            this.data[0].includeClass = "success";
            this.data[0].isPrimary = true;
            this.data[0].primaryClass = "success";
        }
    }

    /*
     * Method Name: toggleAllSelected
     * Description: method to toggle all Accounts
     */
    toggleAllSelected() {
        this.data.forEach((rec) => {
            // set data value
            rec.isIncluded = false;
        });
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