import {LightningElement,api,track,wire} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';

/* APEX SERVICES */
import getEntityData from "@salesforce/apex/OpportunityMergeController.getEntityData";
import switchPureIds from "@salesforce/apex/OpportunityMergeController.switchPureIds";

export default class OpportunityMergeWizard extends NavigationMixin(LightningElement) { 
    // form variables
    @api recordId;
    duplicateCount = 0;
    
    @track showSpinner = false;
    @track isAdminUser = false;
    @track openModal = false;
    @track data = [];
    @track hasData = false;

    @wire(getRecord, { recordId: '$recordId', fields: [ 'Opportunity.Name', 'Opportunity.Monash_System_Id__c']})

    //validate primary and incldued records
    doValidation(){
        // Check if the primary Account Account is Included
        let primaryOpportunity = this.data.filter(rec => rec.isPrimary == true);
        if(primaryOpportunity.length == 1 && !primaryOpportunity[0].isIncluded){
            this.displayErrorToast('Please select a primary opportunity record to proceed with the merge operation.');
            return false;
        }
        // Check is more than 1 Account is selected
        let isIncludedCount = this.data.filter(rec => rec.isIncluded == true);
        if(isIncludedCount.length < 2 ){
            this.displayErrorToast('Please Include at least one non-primary record to proceed with the merge operation.');
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
            this.switchPureIds();             
        }
    }

    async switchPureIds(){ 
        let primaryOpportunityId;
        let duplicateOpportunityIds = [];
        let isProvenancePure = false;
        this.data.forEach((rec) => {
            // set data value
            if (rec.isPrimary) {
                primaryOpportunityId = rec.id;
                if(rec.provenance == 'PURE'){
                    isProvenancePure = true;
                }
            }else if(!rec.isPrimary && rec.isIncluded){ 
                duplicateOpportunityIds.push(rec.id);
            }
        });        
        this.showSpinner = true;
        let opportunityMerged = 1;
        let initiateGivingSummary = false;
        for(let duplicateOpportunityId of duplicateOpportunityIds){
            if(opportunityMerged === duplicateOpportunityId.length){
                initiateGivingSummary = true;
            }
            let respVal;
            respVal = await switchPureIds({
                //pureApplicnId : this.pureApplicnId,
                survOpportunityId : primaryOpportunityId,
                delOpportunityId : duplicateOpportunityId,
                isPure: isProvenancePure
            })
            .then((result) => { 
                if(result == 'Success'){
                    this.showToast('Success', 'Merging of opportunities successful.', 'success');
                    // Initiate Sync
                    //this.handleInitiateSync();
                }else if(result == 'Access Violation'){
                    this.showToast("Error","This operation can be only performed by users with edit permissions to the opportunity.","Error");
                }
                else if(result == 'Merge Close to Open Violation'){
                    this.showToast("Error","Both opportunities need to be either open or closed to merge. Please update the stage of one of the opportunities.","Error");
                }
                this.closeModal();
                this.showSpinner = false;
            })
            .catch((error) => {
                this.showToast("Error","An error has occurred: " + error.body.message,"Error");
                this.showSpinner = false;
                this.closeModal();
            });
            opportunityMerged++;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: primaryOpportunityId,
                objectApiName: 'Opportunity',
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
                onLoadOppId : this.recordId
            })
            .then((result) => {
                let datalist = result.relatedOpportunity;   
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

    //when user click included 
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
    //navigate to opportunity record
    handleOpportunityClick(event) { 
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