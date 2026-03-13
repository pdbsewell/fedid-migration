/* base components */
import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { updateRecord } from 'lightning/uiRecordApi';

/* custom methods */
import retrieveApplicantCommunityUser from '@salesforce/apex/DocumentChecklistAcceptanceServices.retrieveApplicantCommunityUser';
import retrieveChecklistItems from '@salesforce/apex/DocumentChecklistAcceptanceServices.retrieveChecklistItems';
import retrieveOffer from '@salesforce/apex/DocumentChecklistAcceptanceServices.retrieveOffer';
import runRules from '@salesforce/apex/DocumentChecklistAcceptanceServices.runRules';

/* utility js methods */
import * as util from 'c/util';

/* assets */
import admissionAssets from '@salesforce/resourceUrl/admission_assets'
import communityMyAppAssets from '@salesforce/resourceUrl/CommunityMyAppAssets';

export default class DocumentChecklistOfferAcceptanceCommunityList extends LightningElement {
    //retrieve static resource images
    backgroundImage = communityMyAppAssets + '/images/myApp-bg-panel.jpg';
    courseImageUrl = admissionAssets + '/screen-icons/course.png';
    grantImageUrl = admissionAssets + '/screen-icons/Scholarship_icn.png';

    //Get record id when opened on record page
    @api recordId;
    //Retrieved quote record
    @track opportunityId;
    @api offer;
    @api wiredOffer;
    //Retrieved opportunity record
    @api opportunityId;
    @api opportunity;
    @api wiredOpportunity;

    //Page details
    @api pageTitle;
    @api pageSubTitle; 
    @api checklistItems;
    @track checklistItemsCount;
    @track message;

    //Offer record wiring
    @wire(retrieveOffer, { opportunityId: '$opportunityId'})
    retrieveWiredOffer( result ) {
        this.wiredOffer = result;
        if (result.data) {
            this.offer = result.data.Opportunity;
        } else if (result.error) {
            this.message = result.error;
        }
    }

    @wire(retrieveApplicantCommunityUser, { opportunityId: '$opportunityId' })
    applicantCommunityUser;

    get offerName() {
        let name;
        if(this.offer){
            name = this.offer.Name.split('-')[1];
        }
        return name;
    }

    get offerType() {
        let type;
        if(this.offer){
            type = (this.offer.Offer_Type__c === 'COND-OFFER' ? 'Conditional Offer' : 'Full Offer of place');
        }
        return type;
    }

    get offerStartDate() {
        let startDate;
        if(this.offer){
            startDate = new Date(this.offer.Offer_Start_Date__c);
            let monthDate = util.longMonthName(startDate) + ' ' + startDate.getFullYear();
            startDate = monthDate;
        }
        return startDate;
    }

    get offerLocation(){
        let location;
        if(this.offer){
            if(this.offer.OpportunityLineItems){
                location = this.offer.OpportunityLineItems[0].Location__c;
            }
        }
        return location;
    }

    get offerFeeType(){
        let feeType;
        if(this.offer){
            if(this.offer.Pricebook2Id){
                feeType = (this.offer.Pricebook2.Name === 'International' ? 'International, Full-fee' : this.offer.Pricebook2.Name);
            }       
        }
        return feeType;
    }

    get grantName(){
        let name;
        if(this.offer){
            if(this.offer.OpportunityLineItems){
                this.offer.OpportunityLineItems.forEach(function(lineItem) {        
                    if(lineItem.Product2.Family === 'Grant' || lineItem.Product2.Family === 'Scholarship'){
                        name = lineItem.Product2.Family;
                    }        
                });
            }
        }
        return name;
    }

    get grantProductName(){
        let productName;
        if(this.offer){
            if(this.offer.OpportunityLineItems){
                this.offer.OpportunityLineItems.forEach(function(lineItem) {        
                    if(lineItem.Product2.Family === 'Grant' || lineItem.Product2.Family === 'Scholarship'){
                        productName = lineItem.Product2.Name;
                    }        
                });
            }
        }
        return productName;
    }

    /*get grantValue(){        
        let value;
        if(this.offer){
            if(this.offer.SBQQ__LineItems__r){
                this.offer.SBQQ__LineItems__r.forEach(function(lineItem) {        
                    if(lineItem.SBQQ__ProductFamily__c === 'Grant' || lineItem.SBQQ__ProductFamily__c === 'Scholarship'){
                        value = util.formattedCurrency(lineItem.Total_Grant_Scholarship_Value__c);
                    }        
                });
            }
        }
        return value;
    }*/
    
    /*get grantExpiry(){
        let expiry;
        if(this.offer){
            if(this.offer.SBQQ__LineItems__r){
                this.offer.SBQQ__LineItems__r.forEach(function(lineItem) {        
                    if(lineItem.SBQQ__ProductFamily__c === 'Grant' || lineItem.SBQQ__ProductFamily__c === 'Scholarship'){
                        expiry = util.dateFormatted(new Date(lineItem.Expiry_Date__c));
                    }        
                });
            }
        }
        return expiry;
    }*/

    get backgroundStyle() {
        return 'background-image: url(' + this.backgroundImage +'); min-height: 450px;';
    }
    
    /* Constructor after the component is hooked on the parent component */
    connectedCallback() {
        //Set offer record id
        if(this.recordId != null){
            this.opportunityId = this.recordId;
        }

        //Refresh checklist details
        this.refreshChecklistDetails();
    }

    //Fire preview document request sending back the event to the parent aura component
    onFilePreview(event) {
        //file preview event
        const filePreviewEvent = new CustomEvent('filepreview', {
            detail: { documentId: event.detail.documentId }
        });
        this.dispatchEvent(filePreviewEvent);
    }

    //Refresh the wired offer record
    refreshWiredOffer() {
        //Check offer's ad hoc flag
        if(this.wiredOffer){
            if(this.wiredOffer.data){
                refreshApex(this.wiredOffer);
            }
        }
    }

    //Run rules to refresh checklist details
    refreshChecklistDetails(){
        //Clear checklist items
        this.checklistItems = null;  

        //Refresh wired offer data
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
        });
    }
}