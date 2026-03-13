import {LightningElement,api,track,wire} from "lwc";
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';

/* APEX SERVICES */
import getOpportunities from "@salesforce/apex/SyncRefreshPureOpportunityController.getOpportunities";
import initiateSync from "@salesforce/apex/SyncRefreshPureOpportunityController.initiateSync";
import switchPureIds from "@salesforce/apex/SyncRefreshPureOpportunityController.switchPureIds";
import validateAccess from "@salesforce/apex/SyncRefreshPureOpportunityController.validateAccess";

export default class SyncRefreshPureOpportunity extends NavigationMixin(LightningElement) { 

    // form variables
    @api recordId;
    
    @track hasEditAccess = false;
    @track showSpinner = false;
    @track pureApplicnId = '';
    @track delOpportunityId;
    @track currentOpportunity;
    @track openModal = false;
    @track isPureOppty = false;
    @track data = [];

    connectedCallback(){ 
        validateAccess({
            opportunityId : this.recordId
        })
        .then((result) => {
            this.hasEditAccess = result.hasEditAccess;
            this.currentOpportunity = result.linkedOppty;
            //ENGAGEIE-1866 remove the sync opportunity widget
            /*if(this.currentOpportunity != null && this.currentOpportunity.Source__c == 'PURE'){
                this.isPureOppty = true;
                this.pureApplicnId = this.currentOpportunity.PURE_Application_ID__c;
            }*/
            this.survOpportunityId = this.recordId;
        })
        .catch((error) => {
            this.showToast("Error","An error has occurred: " + error.body.message,"Error");
            this.showSpinner = false;
            this.closeModal();
        });
    }

    /*
     * Method Name: getOpportunitiesFromPureId
     * Description: method to call apex function passing parameters from the UI
     */
    getOpportunitiesFromPureId() {
        this.showSpinner = true;
        this.openModal = true;
        getOpportunities({
            pureApplicnId : this.pureApplicnId,
            survOpportunityId : this.recordId
        })
        .then((result) => {
            let datalist = result;  
            if(datalist.length > 0) {
                datalist.forEach((rec) => {
                    // set data value
                    rec.isPrimary = false; 
                    this.data.push(rec);
                });
            }else{
                this.showToast('Error', 'No related opptys found', 'Error');
                this.closeModal();
            }
            this.showSpinner = false;
        })
        .catch((error) => {
            this.showToast("Error","An error has occurred: " + error.body.message,"Error");
            this.showSpinner = false;
            this.closeModal();
        });
    }

    /*
     * Method Name: delOpptyInitiateSync
     * Description: method to call apex function passing parameters from the UI to Delete Opportunity
     */
    delOpptyInitiateSync() {
        if(this.delOpportunityId == '' || this.delOpportunityId == undefined){
            this.showToast("Error","Please select an Opportunity to Sync from.","Error");
        }else{
            this.showSpinner = true;
            switchPureIds({
                pureApplicnId : this.pureApplicnId,
                survOpportunityId : this.recordId,
                delOpportunityId : this.delOpportunityId
            })
            .then((result) => { 
                if(result == 'Success'){
                    this.showToast('Success', 'Selected Opportunity deleted, Initiating sync from PURE', 'success');
                    // Initiate Sync
                    this.handleInitiateSync();
                }else if(result == 'Access Violation'){
                    this.showToast("Error","This operation can only be performed with edit permissions for the Opportunity.","Error");
                }
                this.closeModal();
                this.showSpinner = false;
            })
            .catch((error) => {
                this.showToast("Error","An error has occurred: " + error.body.message,"Error");
                this.showSpinner = false;
                this.closeModal();
            });
        }   
    }

    handleInitiateSync(){
        initiateSync({
            survOpportunityId : this.survOpportunityId,
            pureApplicnId : this.pureApplicnId,
            isPureOppty : this.isPureOppty
        })
        .then((result) => {  
            if(result == 'Success') {
                this.showToast('Success', 'Oppty Sync Initiated', 'success');
            }else{
                this.showToast("Error","An error has occurred: " + result, "Error");
            }
            this.showSpinner = false;
            this.closeModal();
        })
        .catch((error) => {
            this.showToast("Error","An error has occurred: " + error.body.message,"Error");
            this.showSpinner = false;
            this.closeModal();
        });
    }

    /*
     * Method Name: handlePrimaryChange
     * Description: method to handle event when Opportunity is selected
     */
    handlePrimaryChange(event) { 
        let recId = event.currentTarget.dataset.id;
        this.delOpportunityId = event.currentTarget.dataset.id;
        this.data.forEach((rec) => {
            if(rec.linkedOppty.Id === recId){
                rec.isPrimary=true;
            }else{
                rec.isPrimary=false;
            } 
        });
    }

    /*
     * Method Name: handlePureIdChange
     * Description: method to handle event when Opportunity Pure id is entered
     */
    handlePureIdChange(event){ 
        this.pureApplicnId = event.detail.value;
    }

    /*
     * Method Name: handleSearchAndShowModal
     * Description: method to show modal with Search results
     */
    handleSearchAndShowModal(){
        let validPureId = this.validatePureId();
        if(validPureId){
            this.getOpportunitiesFromPureId(); 
        }          
    }

    /*
     * Method Name: validatePureId
     * Description: method to check the PURE Id
     */
    validatePureId(){
        let pureSearchId = this.pureApplicnId;
        if(pureSearchId == "" || pureSearchId == undefined || pureSearchId.includes("+") || pureSearchId.includes(" ") || pureSearchId.includes("-") || isNaN(pureSearchId)){
            this.showToast("Error","Please enter a valid Pure Id.","Error");
            return false;
        }else{
            return true;
        }   
    }

    /*
     * Method Name: handleKeyUpChange
     * Description: method to check if user hots ENTER with the Pure Id
     */
    handleKeyUpChange(event){
        if (event.which == 13) {
            // On Enter initiate the search
            this.handleSearchAndShowModal();
        }
    }

    /*
     * Method Name: closeModal
     * Description: method to close modal and reset params
     */
    closeModal(){
        this.openModal = false;
        this.delOpportunityId = '';
        this.data = [];
    }

    /*
     * Method Name: handleRecordClick
     * Description: method to handle click event and Navigate to record
     */
    handleRecordClick(event) { 
        const recId = event.currentTarget.dataset.id;
        this.navigateToRecord(recId);   
    }

    /*
     * Method Name: navigateToRecord
     * Description: method to Navigate to record
     */
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