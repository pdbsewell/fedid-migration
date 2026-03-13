/* eslint-disable eqeqeq */
/* eslint-disable dot-notation */
/* eslint-disable vars-on-top */
/* eslint-disable no-console */
/* eslint-disable no-unused-vars */
import { LightningElement, wire, track, api } from 'lwc';
import * as util from 'c/util';
import { refreshApex } from '@salesforce/apex';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import formPageList from '@salesforce/apex/OfferLightningEnabledClass.getFormPageList';
import { loadStyle } from 'lightning/platformResourceLoader';
import static_resource from '@salesforce/resourceUrl/admission_assets'
import getManagedClauseByQuoteId from '@salesforce/apex/OfferLightningEnabledClass.getManagedClauseByQuoteId';

const quoteFields = ['SBQQ__Quote__c.Name', 'SBQQ__Quote__c.Offer_Status__c', 'SBQQ__Quote__c.SBQQ__PrimaryContact__c',
                    'SBQQ__Quote__c.Person_ID_unique__c', 'SBQQ__Quote__c.Gender__c',
                    'SBQQ__Quote__c.Birthdate__c', 'SBQQ__Quote__c.MailingAddress__c',
                    'SBQQ__Quote__c.SBQQ__PrimaryContact__r.MailingStreet', 'SBQQ__Quote__c.SBQQ__PrimaryContact__r.MailingCity',
                    'SBQQ__Quote__c.SBQQ__PrimaryContact__r.MailingState', 'SBQQ__Quote__c.SBQQ__PrimaryContact__r.MailingPostalCode',
                    'SBQQ__Quote__c.SBQQ__PrimaryContact__r.MailingCountry',
                    'SBQQ__Quote__c.SBQQ__PrimaryContact__r.HomePhone',
                    'SBQQ__Quote__c.SBQQ__PrimaryContact__r.MobilePhone',
                    'SBQQ__Quote__c.SBQQ__PrimaryContact__r.Phone',
                    'SBQQ__Quote__c.Phone__c', 'SBQQ__Quote__c.Email__c', 'SBQQ__Quote__c.Id',
                    'SBQQ__Quote__c.Agent_Name__c', 'SBQQ__Quote__c.Offer_Response_Date__c',
                    'SBQQ__Quote__c.Application_Course_Preference__c', 'SBQQ__Quote__c.Net_Deposit__c',
                    'SBQQ__Quote__c.Contact_Firstname__c', 'SBQQ__Quote__c.Contact_Middlename__c', 'SBQQ__Quote__c.Contact_Lastname__c',
                    'SBQQ__Quote__c.Payment_Option__c', 'SBQQ__Quote__c.Primary_Document__c',
                    'SBQQ__Quote__c.SBQQ__Status__c', 'SBQQ__Quote__c.Calculated_Expiry_Date__c',
                    'SBQQ__Quote__c.SBQQ__PrimaryContact__r.Under_18__c', 'SBQQ__Quote__c.Sub_Status__c',
                    'SBQQ__Quote__c.Guardian_First_Name__c', 'SBQQ__Quote__c.Guardian_Last_Name__c',
                    'SBQQ__Quote__c.Guardian_Relationship_Type__c', 'SBQQ__Quote__c.Guardian_Email__c',
                    'SBQQ__Quote__c.Guardian_Other_Relationship_Type__c', 'SBQQ__Quote__c.SBQQ__PrimaryContact__r.Full_Name__c',
                    'SBQQ__Quote__c.SBQQ__PrimaryContact__r.First_Name__c', 'SBQQ__Quote__c.SBQQ__PrimaryContact__r.Last_Name__c',
                    'SBQQ__Quote__c.Contract_Generated__c', 'SBQQ__Quote__c.Acknowledged_by_applicant__c',
                     'SBQQ__Quote__c.DocuSign_Signing_URL__c', 'SBQQ__Quote__c.Visa_Start_Year__c',
                    'SBQQ__Quote__c.Offer_has_grant__c', 'SBQQ__Quote__c.Offer_has_scholarship__c',
                    'SBQQ__Quote__c.Visa_Priced_Year__c', 'SBQQ__Quote__c.Health_Cover_Provider_Type__c',
                    'SBQQ__Quote__c.Offer_Regeneration_Reason__c','SBQQ__Quote__c.Onshore_MU_Transfer__c',
                    'SBQQ__Quote__c.VisaDetails_AustralianVisaStatus__c','SBQQ__Quote__c.VisaDetails_ImmigrationOffice__c',
                    'SBQQ__Quote__c.VisaDetails_VisaNumber__c','SBQQ__Quote__c.VisaDetails_StartDate__c',
                    'SBQQ__Quote__c.VisaDetails_EndDate__c',
                    'SBQQ__Quote__c.Guardian_has_Email_Address__c'
                ];

export default class offersFormPage extends LightningElement {    
    
    @api formPageAPI;
    @track contactId;
    @api offerId;
    @track error;
    @track offerRecord;
    @track formPage;
    @track junctionRecords;
    @track wizardPages;
    @track loading = 'load-spinner';
    @track urlParam;
    @track page;
    @track paymentSelected;
    @track loadPage = true;
    @track spinner = true;
    @track showTitle = true;
    @track loadClause = false;
    @track quoteClauses = [];

    @wire(CurrentPageReference) pageRef;

    @wire(formPageList, {apiName: ''})
    wiredFormPageList({ error, data }) {
        if (data) {
            this.wizardPages = data;
            this.error = undefined;
            this.urlParam = util.urlParameter(window.location.href);
            this.offerId = this.urlParam.get('id');
            this.spinner = false;
        } else if (error) {
            this.error = error;
            this.wizardPages = undefined;
        }
    
    }

    @wire(getRecord, { recordId: '$offerId', fields:  quoteFields})
    wiredOffer({error, data}){
        if(data && this.wizardPages){
            this.offerRecord = data.fields;
            this.error = undefined;
            var offer = JSON.parse(data.fields.Offer_Status__c.value);
            this.contactId = data.fields.SBQQ__PrimaryContact__c.value;
            var pages = JSON.parse(JSON.stringify(this.wizardPages));
            let isUnder18 = data.fields.SBQQ__PrimaryContact__r.value.fields.Under_18__c.value;
            this.showTitle = true;
            let onshoreMUTransfer = this.offerRecord.Onshore_MU_Transfer__c.value;
            for(var x =0; x< pages.length; x++){
                if (pages[x]['api_Name'] === 'under18' && !isUnder18
                    || pages[x]['api_Name'] === 'grant' && this.offerRecord.Offer_has_grant__c.value <= 0
                    || pages[x]['api_Name'] === 'scholarship' && this.offerRecord.Offer_has_scholarship__c.value <= 0) {
                    pages.splice(x, 1);
                    x = x - 1;
                }
            }
            // remove the OSHC page on portal for Onshore MU Course Transfer offers
            for(var x =0; x< pages.length; x++){
                if (pages[x].api_Name == 'healthInsurance' && onshoreMUTransfer) {
                    pages.splice(x, 1);
                }
            }
            // remove the Summary of Financials page on portal for Onshore MU Course Transfer offers
            for(var x =0; x< pages.length; x++){
                if (pages[x].api_Name == 'financials' && onshoreMUTransfer) {
                    pages.splice(x, 1);
                }
            }
            // remove the Payment Option page on portal for Onshore MU Course Transfer offers
            for(var x =0; x< pages.length; x++){
                if (pages[x].api_Name == 'payment' && onshoreMUTransfer) {
                    pages.splice(x, 1);
                }
            }
            for(var i =0; i< pages.length; i++){ 
                pages[i]['index'] = i;
                pages[i]['backBtnClass'] = 'slds-back-button';
                pages[i]['nextBtnClass'] = 'slds-next-button';
                if(offer.API_Name__c == pages[i].api_Name){                        
                    if(pages[i]['display_Order'] == 1){
                        pages[i]['backBtnClass'] = 'hide-button';
                    
                    }else if(pages[i]['display_Order'] == 10){
                        pages[i]['nextBtnClass'] = 'hide-button';
                    
                    }
                    this.page = pages[i];  
                }
                
            }
            
            this.wizardPages = pages;
        }else if(error){
            var exception = JSON.parse(JSON.stringify(error));  
            util.log('*** Error Form Page ***' );
            util.logJson(exception);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: exception.body.message, 
                    variant: 'error',
                }),
            );  
        }        
    }

    @wire(getManagedClauseByQuoteId, {quoteId: '$offerId'})
    wiredManagedClause({error, data}){
        if(data){
            this.quoteClauses = JSON.parse(data);
            this.loadClause = true;
            //console.log(this.quoteClauses); 
        }else if(error){
            console.log(JSON.stringify(error));
        }
    }   
    
    previousHandler() {
        this.showTitle = true;
        this.spinner = true;
        if(this.page['index'] != 0){
            var pages = JSON.parse(JSON.stringify(this.wizardPages));
            for(var i =0; i< pages.length; i++){
                let decrease = (this.page.api_Name === 'my-details' ? 1 : 1);
                if(this.page.api_Name == 'payment' && 
                    this.offerRecord.Payment_Option__c.value != this.paymentSelected){
                        this.paymentSelected = this.offerRecord.Payment_Option__c.value;
                }
                if(pages[i]['index'] == this.page['index']-decrease){
                    if(pages[i]['display_Order'] == 1){
                        pages[i]['backBtnClass'] = 'hide-button';
                    
                    }else if(pages[i]['display_Order'] == 10){
                        pages[i]['nextBtnClass'] = 'hide-button';
                    }
                    this.page = pages[i];
                    fireEvent(this.pageRef, 'onButtonNavigate', pages[i]); 
                    fireEvent(this.pageRef, 'onNavigatePage', pages[i]); 
                    window.scroll(0,0);
                }
            }//end loop
            
        }
        this.spinner = false;
    }

    nextHandler() {
        this.showTitle = true;
        var pages = JSON.parse(JSON.stringify(this.wizardPages));
        var offer = JSON.parse(this.offerRecord.Offer_Status__c.value);
        let isValid = this.isValidPayment(this.page);

        if(isValid){
            for(var i =0; i< pages.length; i++){
                //let add = (this.page.api_Name === 'coverletter' ? 2 : 1);
                let add = (this.page.api_Name === 'offersummary' ? 1 : 1);
                if(pages[i]['index'] == this.page['index']+add){
                    pages[i]['index'] = i;

                    let pageInfo = {
                        API_Name__c: pages[i].api_Name,
                        Display_Order__c: pages[i].display_Order,
                        Status__c: 'active'
                    };
                    let offerStatusRecord = {
                        fields:{
                            Id: this.offerRecord.Id.value,
                            Offer_Status__c: JSON.stringify(pageInfo)
                        }
                    };

                    if(pages[i]['display_Order'] == 1){
                        pages[i]['backBtnClass'] = 'slds-back-button';
                    
                    }else if(pages[i]['display_Order'] == 10){
                        pages[i]['nextBtnClass'] = 'hide-button';
                    }
                    else if(pages[i].display_Order > offer.Display_Order__c){
                        this.updateRecordMethod(offerStatusRecord);

                    }//end diplay order condition

                    this.page = pages[i];
                    this.loadPage = true;
                    fireEvent(this.pageRef, 'onButtonNavigate', pages[i]); 
                    fireEvent(this.pageRef, 'onNavigatePage', pages[i]); 
                    window.scroll(0,0);
                    break;
                }//end index condition
            }//end loop
        }//end isValid condition

    } //END: nextHandler

    isValidPayment(page){
        //UPDATE PAYMENT OPTION
        let subStatus = util.subStatusTriggerConga;
        if(page['api_Name'] == 'payment'){
            if(this.paymentSelected == null){
                this.spinner = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please select a payment option to continue', 
                        variant: 'error',
                    }),
                );  
                return false;
            }else if(this.offerRecord.Payment_Option__c.value != this.paymentSelected){                
                let paymentRecord = {
                    fields:{
                        Id: this.offerRecord.Id.value,
                        Payment_Option__c: this.paymentSelected,
                        Sub_Status__c: subStatus
                    }
                };
                this.updateRecordMethod(paymentRecord);
            }
        }
        return true;
    }

    updateRecordMethod(record){
        this.spinner = true;
        updateRecord(record)
            .then(() => {
                this.spinner = false;
                util.log('*** Success ***');  
                return true;              
            })
            .catch(error => {
                this.spinner = false;
                var exception = JSON.parse(JSON.stringify(error));  
                util.log('*** Error ***' );
                util.logJson(exception);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: exception.body.message, 
                        variant: 'error',
                    }),
                );  
                  
            });
    }
    
    connectedCallback() {
        // subscribe to pageNavigate event from progressIndicator
        registerListener('pageNavigate', this.navigate, this);

        // subscribe to toggleFormPage event from mobile header nav
        registerListener('toggleFormPage', this.toggleFormPage, this);

        // subscribe to onPaymentSelect event from payment page
        registerListener('onPaymentSelect', this.setSelectedPayment, this);

        registerListener('setPageTitle', this.setPageTitle, this);

        registerListener('setPageTitle', this.setPageTitle, this);

        registerListener('ContinueFromVisaDetails', this.visaDetailsContinue, this);
        registerListener('ContinueFromUnder18', this.under18Continue, this);
        registerListener('ContinueFromHealth', this.continueHealth, this);
        registerListener('ConfirmDetails', this.confirmPersonalDetails, this);

        loadStyle(this, static_resource + '/css/desktop-style-sheet.css');
        loadStyle(this, static_resource + '/css/mobile-style-sheet.css');
        loadStyle(this, static_resource + '/css/tablet-visibility.css');
    } 
    disconnectedCallback() {
        // unsubscribe from pageNavigate event from progressIndicator
        unregisterAllListeners(this);
    }

    visaDetailsContinue(data){
        this.page = data;
        this.nextHandler();
    }
    under18Continue(data){
        this.page = data;
        this.nextHandler();
    }
    continueHealth(detail){
        this.page = detail.page;
        this.nextHandler();
    }

    navigate(data) {   
        this.spinner = true;  
        this.showTitle = true;   
        var pages = JSON.parse(JSON.stringify(this.wizardPages));
        for(var i =0; i< pages.length; i++){
            if(pages[i]['api_Name'] == data){
                
                if(pages[i]['api_Name'] == 'payment' && 
                    this.offerRecord.Payment_Option__c.value != this.paymentSelected){
                        this.paymentSelected = this.offerRecord.Payment_Option__c.value;
                }
                
                if(pages[i]['display_Order'] == 1){
                    pages[i]['backBtnClass'] = 'hide-button';
                
                }else if(pages[i]['display_Order'] == 10){
                    pages[i]['nextBtnClass'] = 'hide-button';
                }

                this.page = pages[i];
                this.loadPage = true;
                fireEvent(this.pageRef, 'onMenuNavigate', this.page); 
                break;
            }//end index condition
        }
        this.hasRendered();
        
    }

    toggleFormPage(data){
        this.loadPage = data;
        this.showTitle = true;
    }

    setSelectedPayment(data){
        this.paymentSelected = data;
        this.showTitle = true;
    }

    setPageTitle(data){
        this.showTitle = false;
    }

    confirmPersonalDetails(data){
        console.log('** enter confirm **');
        if(this.offerRecord.Sub_Status__c.value === util.subStatusTriggerConga){
            console.log('** enter details completed update **');
            let offerUpdate = {
                fields:{
                    Id: this.offerRecord.Id.value,
                    Sub_Status__c: util.subStatusCompleted
                }
            };
            this.updateRecordMethod(offerUpdate);
        }
        this.nextHandler();
    }
    
    get hasRendered(){      
        this.spinner = false;
        window.scroll(0,0);
        return this.page && this.loadPage && this.loadClause;
    }


}