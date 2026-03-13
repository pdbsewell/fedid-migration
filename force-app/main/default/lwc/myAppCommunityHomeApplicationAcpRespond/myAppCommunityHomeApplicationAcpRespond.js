/* eslint-disable no-console */
import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

/* methods */
import doAcceptACP from '@salesforce/apex/MyAppHomeServices.doAcceptACP';
import doRejectACP from '@salesforce/apex/MyAppHomeServices.doRejectACP';

export default class MyAppCommunityHomeApplicationAcpRespond extends LightningElement {
    @api applicationCoursePreference;
    @track isAcceptConfirmation;
    @track isRejectConfirmation;
    @track headerClass;
    @track processing;
    @track modalBodyClass;
    @track hasResponded;

    get retrieveUnitSetDescription() {
        let unitSetDescription;
        unitSetDescription = this.applicationCoursePreference.Unit_Set_Description__c;

        return unitSetDescription;
    }

    get getLocation() {
        let locationDetail = '';
        if(this.applicationCoursePreference.Course_Offering__r.Location_Description__c){
            locationDetail = this.applicationCoursePreference.Course_Offering__r.Location_Description__c.charAt(0).toUpperCase() + this.applicationCoursePreference.Course_Offering__r.Location_Description__c.toLowerCase().slice(1);
        }
        return locationDetail;
    }

    get determineConditionalOffer() {
        let isConditional = false;
        //Check if acp is conditional offer
        if(this.applicationCoursePreference.Outcome_Status_LOV__c && this.applicationCoursePreference.Outcome_Status_LOV__r.Value__c === 'OFFER-COND') {
            if(this.applicationCoursePreference.Conditional_Offer_Status_LOV__c && this.applicationCoursePreference.Conditional_Offer_Status_LOV__r.Value__c !== 'WAIVED') {
                isConditional = true;
            }
        }
        return isConditional;
    }

    get determineConditionalSatisfied() {
        let isConditionalSatisfied = false;
        //Check if acp is conditional offer
        if(this.applicationCoursePreference.Outcome_Status_LOV__c) {
            if(this.applicationCoursePreference.Conditional_Offer_Status_LOV__c && 
               (this.applicationCoursePreference.Conditional_Offer_Status_LOV__r.Value__c === 'SATISFIED' || 
                this.applicationCoursePreference.Conditional_Offer_Status_LOV__r.Value__c === 'WAIVED' || 
                (this.applicationCoursePreference.Outcome_Status_LOV__r.Value__c === 'OFFER-COND' && this.applicationCoursePreference.Conditional_Offer_Satisfied_Date__c))) {

                isConditionalSatisfied = true;

            }
        }
        return isConditionalSatisfied;
    }

    get isConfirmation() {
        return this.isAcceptConfirmation || this.isRejectConfirmation;
    }

    get showFullOfferConfirmation() {
        let isFull = true;
        if(this.applicationCoursePreference.Outcome_Status_LOV__c && this.applicationCoursePreference.Outcome_Status_LOV__r.Value__c === 'OFFER-COND'){
            if(this.applicationCoursePreference.Conditional_Offer_Status_LOV__c && this.applicationCoursePreference.Documentation_Status_LOV__c && this.applicationCoursePreference.Conditional_Offer_Status_LOV__r.Value__c === 'WAIVED') {
                if(this.applicationCoursePreference.Documentation_Status_LOV__r.Value__c === 'DOC-UNCERT' || this.applicationCoursePreference.Documentation_Status_LOV__r.Value__c === 'DOC-ENROL'){
                    isFull = true;
                }else {
                    isFull = false;
                }
            }else{
                isFull = false;
            }
        }
        return isFull;
    }

    /* constructor */
    connectedCallback() {
        this.processing = false;
        this.isAcceptConfirmation = false;
        this.isRejectConfirmation = false;
        this.hasResponded = false;
        this.headerClass = 'slds-modal__header defaultHeader';
        this.headerTextClass = 'defaultHeaderText';
        this.modalBodyClass = 'slds-modal__content slds-p-around_medium slds-is-relative';
    }

    closeRespondForm(){
        //Create change event
        const cancelEvent = new CustomEvent('cancel');
        //Dispatch event
        this.dispatchEvent(cancelEvent);
    }

    doCancel(){
        this.headerClass = 'slds-modal__header defaultHeader';
        this.headerTextClass = 'defaultHeaderText';
        this.isAcceptConfirmation = false;
        this.isRejectConfirmation = false;
    }

    doReject(){
        if(!this.isRejectConfirmation){
            this.headerClass = 'slds-modal__header rejectHeader';
            this.headerTextClass = 'confirmHeaderText';
            this.isAcceptConfirmation = false;
            this.isRejectConfirmation = true;
        }else{
            this.processing = true;
            this.modalBodyClass = 'slds-modal__content slds-p-around_medium slds-is-relative hideScroll';
            doRejectACP({ acp : this.applicationCoursePreference })
            .then(() => {
                this.processing = false;
                this.hasResponded = true;
                
                //Create change event
                const respondEvent = new CustomEvent('respond');
                //Dispatch event
                this.dispatchEvent(respondEvent);
            })
            .catch(rejectAcpError => {
                //Expose error
                console.log('Error: ' + JSON.stringify(rejectAcpError));
            });
        }
    }

    doAccept(){
        if(!this.isAcceptConfirmation){
            this.headerClass = 'slds-modal__header acceptHeader';
            this.headerTextClass = 'confirmHeaderText';
            this.isAcceptConfirmation = true;
            this.isRejectConfirmation = false;
        }else{
            this.processing = true;
            this.modalBodyClass = 'slds-modal__content slds-p-around_medium slds-is-relative hideScroll';
            doAcceptACP({ acp : this.applicationCoursePreference })
            .then(() => {
                this.processing = false;
                this.hasResponded = true;

                //Show success toast
                const event = new ShowToastEvent({
                    title: 'Offer Accepted!',
                    variant: 'success',
                    message: 'Successfully accepted your offer.',
                });
                this.dispatchEvent(event);

                //Create change event
                const respondEvent = new CustomEvent('respond');
                //Dispatch event
                this.dispatchEvent(respondEvent);
            })
            .catch(acceptAcpError => {
                //Expose error
                console.log('Error: ' + JSON.stringify(acceptAcpError));
            });
        }
    }
}