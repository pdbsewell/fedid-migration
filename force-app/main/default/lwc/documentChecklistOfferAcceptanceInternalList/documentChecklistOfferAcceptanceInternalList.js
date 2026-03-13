/* base components */
import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';

/* custom methods */
import retrieveOffer from '@salesforce/apex/DocumentChecklistAcceptanceServices.retrieveOffer';
import retrieveChecklistItems from '@salesforce/apex/DocumentChecklistAcceptanceServices.retrieveChecklistItems';
import runRules from '@salesforce/apex/DocumentChecklistAcceptanceServices.runRules';

/* APPLICANT */
import APPLICANT_FIRST_NAME_FIELD from '@salesforce/schema/Contact.FirstName';
import APPLICANT_LAST_NAME_FIELD from '@salesforce/schema/Contact.LastName';
import APPLICANT_EMAIL_FIELD from '@salesforce/schema/Contact.Email';

/* Opportunity */
import OPPORTUNITY_SBQQ_QUOTE_FIELD from '@salesforce/schema/Opportunity.SBQQ__PrimaryQuote__c';

export default class DocumentChecklistOfferAcceptanceInternalList extends LightningElement {
    //Get record id when opened on record page
    @api recordId;
    //Get retrieve record from parent component
    @track opportunityId;
    //Get retrieve record from parent component
    @api applicantId;

    //Page details
    @api offerId;
    @api quoteStatus;
    @api checklistItems;
    @api offer;
    @api wiredOffer;
    @api applicant;
    @api wiredApplicant;
    @api fileColumnCount
    @api viewType;
    @api prioritizeOther;
    @api showHeader;
    @api showRefresh;
    @api showNew;
    @api hasNoNewChecklistAccess;

    //Page state
    @track listActionLoading;
    @track showChecklistCreationForm;
    @track checklistItemsCount;
    @track defaultDocumentChecklistRecordTypeId;
    @track message;

    //Checklist creation
    @api disabledChecklistName;
    @api checklistName;
    @api checklistHelpText;
    @api checklistSortOrder;
    @api checklistNewStatus;
    @api checklistType;
    @api checklistUniqueKey;
    @api checklistComments;
    @api isBulkCreation;
    @api documentChecklistTemplates;

    //Error tracking
    @api hasError = false;

    //Applicant record wiring
    @wire(getRecord, { recordId: '$applicantId', fields: [APPLICANT_FIRST_NAME_FIELD,
                                                          APPLICANT_LAST_NAME_FIELD,
                                                          APPLICANT_EMAIL_FIELD] })
    retrieveWiredApplicant( result ) {
        this.wiredApplicant = result;
        if (result.data) {
            this.applicant = result.data;
        } else if (result.error) {
            this.message = result.error;
            
            this.hasError = true;
            console.error(JSON.stringify(this.message));
        }
    }

    /* Constructor after the component is hooked on the parent component */
    connectedCallback() {
        //Quote record
        if(this.recordId){
            if(this.viewType === 'Opportunity'){
                this.opportunityId = this.recordId;

                //Refresh checklist details
                this.refreshChecklistDetails();
            }
        }
    }

    get isQuoteChecked(){
        return this.quoteStatus === 'Signed';
    }

    //Fire preview document request sending back the event to the parent aura component
    onFilePreview(event) {
        //file preview event
        const filePreviewEvent = new CustomEvent('filepreview', {
            detail: { documentId: event.detail.documentId }
        });
        this.dispatchEvent(filePreviewEvent);
    }

    //Refresh the wired application record
    refreshWiredOffer() {
        //Run rules engine
        retrieveOffer({
            opportunityId : this.opportunityId
        }).then(offerResult => { 
            this.offer = offerResult.Opportunity;
            this.applicantId = this.offer.PrimaryContact__c;
            this.quoteStatus = this.offer.StageName;
            this.hasNoNewChecklistAccess = !offerResult.hasAcceptanceChecklistNewAccess;
            this.documentChecklistTemplates = offerResult.documentChecklistTemplates;

            this.message = 'Success response received: 200, ' +
                'message ' + JSON.stringify(offerResult); 
        })
        .catch(offerError =>{
            this.message = 'Error received: code' + offerError.errorCode + ', ' +
                'message ' + offerError.body.message;

            this.hasError = true;
            console.error(JSON.stringify(this.message));
        });
    }

    //Run rules to refresh checklist details
    refreshChecklistDetails(){
        //Clear checklist items
        this.checklistItems = null;  

        //Refresh wired application data
        this.refreshWiredOffer();

        //Requery checklist items
        this.refreshChecklistItems();
        
        /* Current requirement is NOT to reevaluate the Acceptance Checklist every time the component is loaded.
        //Run rules engine
        runRules({
            category : 'Offer Acceptance',
            requestOfferId : this.offerId
        }).then(rulesResult => { 
            //Requery checklist items
            this.refreshChecklistItems();

            this.message = 'Success response received: 200, ' +
                'message ' + JSON.stringify(rulesResult); 
        })
        .catch(rulesError =>{
            this.message = 'Error received: code' + rulesError.errorCode + ', ' +
                'message ' + rulesError.body.message;
        });*/
    }

    //Refresh checklist items from server
    refreshChecklistItems() {
        //Retrieve latest set of checklist items
        retrieveChecklistItems({
            requestOfferId : this.opportunityId
        }).then(checklistResult => { 
            //Store checklist items from server
            this.checklistItems = checklistResult;

            //Store number of checklist items
            this.checklistItemsCount = this.checklistItems.length;
        })
        .catch(checklistError =>{
            this.message = 'Error received: code' + checklistError.errorCode + ', ' +
                'message ' + checklistError.body.message;

            this.hasError = true;
            console.error(JSON.stringify(this.message));
        });
    }

    //Shows the form to create checklist items
    showChecklistForm() {
        this.isBulkCreation = false;
        //Create Manual Checklist Item
        this.checklistName = '';
        this.checklistHelpText = '';
        this.checklistSortOrder = 200;
        this.checklistNewStatus = 'Requested';
        this.checklistType = 'Manual';
        this.checklistUniqueKey = this.opportunityId + '-' + this.checklistType + '-' + new Date();        
        this.checklistComments = 'Monash Assessment has requested additional evidence.';
        this.disabledChecklistName = false;
        
        this.showChecklistCreationForm = true;
    }

    //Shows the form to create checklist items
    showBulkChecklistForm() {
        this.isBulkCreation = true;
        //Create from template checklist items
        
        this.showChecklistCreationForm = true;
    }

    //Shows the form to create checklist items
    submittedChecklistForm() {
        this.showChecklistCreationForm = false;

        //Refresh checklist details
        this.refreshChecklistDetails();
    }

    //Hides the form to create checklist items
    hideChecklistForm() {
        this.showChecklistCreationForm = false;
    }

    //Update error flag when child components reports an error
    childHasError(){
        this.hasError = true;
    }

    //Handles the checklist functionality menu
    /*handleMenuAction(event){
        switch(event.detail.value) {
            case 'finalContractSignature':

                break;
            case 'proofMeetingConditions':

                break;
            case 'proofPaymentSponsor':
            
                break;
            case 'underAgeWelfareAccomodationForm':
            
                break;
            case 'proofOHSCHealthCover':
            
                break;
            case 'proofVisa':
            
                break;
            case 'additionalProofVisa':
            
                break;
            case 'proofPassport':
            
                break;
            case 'additionalProofPassport':
            
                break;
            default:
                //Default catch-all
        }
    }

    get isDisabledFinalContractSignature(){
        console.log(this.checklistItems.filter(checklist => checklist.Rule_Name__c === 'Guardian Signature Contract'));
        let isDisabled = false;
        this.checklistItems.forEach(function(element) {
            if(element.Rule_Name__c === 'Guardian Signature Contract'){
                isDisabled = true;
            }
        });
        return isDisabled;
    }

    get isDisabledProofMeetingConditions(){
        let isDisabled = false;
        this.checklistItems.forEach(function(element) {
            if(element.Rule_Name__c === 'Meeting Conditions'){
                isDisabled = true;
            }
        });
        return isDisabled;
    }

    get isDisabledProofPaymentSponsor(){
        console.log(this.checklistItems.filter(checklist => checklist.Rule_Name__c === 'Payment / Sponsor Proof'));
        let isDisabled = false;
        this.checklistItems.forEach(function(element) {
            if(element.Rule_Name__c === 'Payment / Sponsor Proof'){
                isDisabled = true;
            }
        });
        return isDisabled;
    }

    get isDisabledUnderAgeWelfareAccomodationForm(){
        let isDisabled = false;
        this.checklistItems.forEach(function(element) {
            if(element.Rule_Name__c === 'Underage Welfare and Accomodation'){
                isDisabled = true;
            }
        });
        return isDisabled;
    }

    get isDisabledProofOHSCHealthCover(){
        let isDisabled = false;
        this.checklistItems.forEach(function(element) {
            if(element.Rule_Name__c === 'OHSC Health Cover'){
                isDisabled = true;
            }
        });
        return isDisabled;
    }

    get isDisabledProofVisa(){
        let isDisabled = false;
        this.checklistItems.forEach(function(element) {
            if(element.Rule_Name__c === 'Visa Confirm'){
                isDisabled = true;
            }
        });
        return isDisabled;
    }

    get isDisabledAdditionalProofVisa(){
        let isDisabled = false;
        this.checklistItems.forEach(function(element) {
            if(element.Rule_Name__c === 'Visa Inquire Additional'){
                isDisabled = true;
            }
        });
        return isDisabled;
    }

    get isDisabledProofPassport(){
        let isDisabled = false;
        this.checklistItems.forEach(function(element) {
            if(element.Rule_Name__c === 'Passport Confirm'){
                isDisabled = true;
            }
        });
        return isDisabled;
    }

    get isDisabledAdditionalProofPassport(){
        let isDisabled = false;
        this.checklistItems.forEach(function(element) {
            if(element.Rule_Name__c === 'Passport Inquire Additional'){
                isDisabled = true;
            }
        });
        return isDisabled;
    }

    get isCheckedFinalContractSignature(){
        let isChecked = '';
        this.checklistItems.forEach(function(element) {
            if(element.Rule_Name__c === 'Guardian Signature Contract'){
                isChecked = 'utility:check';
            }
        });
        return isChecked;
    }

    get isCheckedProofMeetingConditions(){
        let isChecked = '';
        this.checklistItems.forEach(function(element) {
            if(element.Rule_Name__c === 'Meeting Conditions'){
                isChecked = 'utility:check';
            }
        });
        return isChecked;
    }

    get isCheckedProofPaymentSponsor(){
        let isChecked = '';
        this.checklistItems.forEach(function(element) {
            if(element.Rule_Name__c === 'Payment / Sponsor Proof'){
                isChecked = 'utility:check';
            }
        });
        return isChecked;
    }

    get isCheckedUnderAgeWelfareAccomodationForm(){
        let isChecked = '';
        this.checklistItems.forEach(function(element) {
            if(element.Rule_Name__c === 'Underage Welfare and Accomodation'){
                isChecked = 'utility:check';
            }
        });
        return isChecked;
    }

    get isCheckedProofOHSCHealthCover(){
        let isChecked = '';
        this.checklistItems.forEach(function(element) {
            if(element.Rule_Name__c === 'OHSC Health Cover'){
                isChecked = 'utility:check';
            }
        });
        return isChecked;
    }

    get isCheckedProofVisa(){
        let isChecked = '';
        this.checklistItems.forEach(function(element) {
            if(element.Rule_Name__c === 'Visa Confirm'){
                isChecked = 'utility:check';
            }
        });
        return isChecked;
    }

    get isCheckedAdditionalProofVisa(){
        let isChecked = '';
        this.checklistItems.forEach(function(element) {
            if(element.Rule_Name__c === 'Visa Inquire Additional'){
                isChecked = 'utility:check';
            }
        });
        return isChecked;
    }

    get isCheckedProofPassport(){
        let isChecked = '';
        this.checklistItems.forEach(function(element) {
            if(element.Rule_Name__c === 'Passport Confirm'){
                isChecked = 'utility:check';
            }
        });
        return isChecked;
    }

    get isCheckedAdditionalProofPassport(){
        let isChecked = '';
        this.checklistItems.forEach(function(element) {
            if(element.Rule_Name__c === 'Passport Inquire Additional'){
                isChecked = 'utility:check';
            }
        });
        return isChecked;
    }*/
}