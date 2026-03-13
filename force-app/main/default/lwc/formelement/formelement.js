import { LightningElement, track, api } from 'lwc';
import * as util from 'c/util';

export default class Formelement extends LightningElement {
    @api parent;
    @api form;
    @api offerId;
    @api section;
    @api offerRecord;
    @api contactId;
    @api quoteClauses;
    @track elements;
    @track elementClass;
    @track showCustomerDetails;
    @track showCoverLetter;
    @track showProductList;
    @track showOfferSummary;
    @track showOfferDetails;
    @track showUnder18;
    @track showTerms;
    @track showFinancialSummary;
    @track showPaymentOptions;
    @track showUnder18Form;
    @track showHealthInsurance;
    @track showConfirmation;
    @track showVisaDetailsForm;
    
    
    get isStaticDisplay(){
        return this.section.display_Type === undefined;
    }
    get isComponent(){
        //console.log(JSON.stringify(this.section));
        if(this.section.display_Type === 'component'){
            this.showCustomerDetails = this.section.component_Name === 'customerDetailsDisplay';
            this.showCoverLetter = this.section.component_Name === 'offerCoverLetter';
            this.showProductList = this.section.component_Name === 'offerProductList';
            this.showOfferSummary = this.section.component_Name === 'offersummary';
            this.showOfferDetails = this.section.component_Name === 'offerdetailscomponent';
            this.showVisaDetailsForm = this.section.component_Name === 'offerVisaDetailsForm';
            this.showUnder18 = this.section.component_Name === 'offerUnder18';
            this.showUnder18Form = this.section.component_Name === 'offerUnder18Form';
            this.showTerms = this.section.component_Name === 'offerTermsAndConditions';
            this.showFinancialSummary = this.section.component_Name === 'offerFinancialSummary';
            this.showPaymentOptions = this.section.component_Name === 'offerPaymentOptions';
            this.showHealthInsurance = this.section.component_Name === 'offerHealthInsurance';   
            this.showConfirmation = this.section.component_Name === 'offerConfirmDetails';         
        }
        return this.section.display_Type === 'component';
    }

    

    
}