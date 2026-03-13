/* eslint-disable eqeqeq */
/* eslint-disable no-unused-vars */
/* eslint-disable no-console */
/* eslint-disable dot-notation */
/* eslint-disable vars-on-top */
import { LightningElement, api, track, wire } from 'lwc';
import * as util from 'c/util';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import getFormPageList from '@salesforce/apex/OfferLightningEnabledClass.getFormPage';
import getPrimaryContact from '@salesforce/apex/OfferLightningEnabledClass.getPrimaryContact';
import { loadStyle } from 'lightning/platformResourceLoader';
import static_resource from '@salesforce/resourceUrl/admission_assets'

export default class ProgressIndicator extends LightningElement {
    @track wizardPages;
    @api offerId;
    @track urlParam;
    @track loading = true;
    @track offerRecord;
    @track contactId;

    @wire(CurrentPageReference) pageRef;

    pageNavigate(event){
        this.loading = true;
        var status = event.target.dataset.status;
        if(status != 'inactive'){
            //clear highlighted
            let pages = JSON.parse(JSON.stringify(this.wizardPages));
            for(var i = 0; i< pages.length; i++){
                pages[i]['linkStyleClass'] = 'defaultLinkClass';
                if(pages[i].form_Pages != undefined){
                    for(var y = 0; y < pages[i].form_Pages.length; y++){
                        pages[i].form_Pages[y]['linkStyleClass'] = 'defaultLinkClass';
                    }
                }
                this.wizardPages = pages;
            }
            this.template.querySelectorAll(".defaultLinkClass").forEach(function(element) {
                element.classList.remove('currentActivePage');
            });    

            //clear highlighted
            event.target.classList.add('currentActivePage');
            
            fireEvent(this.pageRef, 'pageNavigate', event.target.dataset.id);  
        }
        this.loading = false;
    }    
    
    connectedCallback() {
        registerListener('onNavigatePage', this.onNavigatePage, this);
    }
    disconnectedCallback() {
        // unsubscribe to event from form page (get page currently displayed)
        unregisterAllListeners(this);
    }

    rerenderCallback(){        
        loadStyle(this, static_resource + '/css/desktop-style-sheet.css');
        loadStyle(this, static_resource + '/css/mobile-style-sheet.css');
        this.loading = false;
    }

    @wire(getFormPageList)
    wiredGetFormPageList({ error, data }) {
        if (data) {
            this.wizardPages = data;
            this.error = undefined;
            this.urlParam = util.urlParameter(window.location.href);
            this.offerId = this.urlParam.get('id');
        } else if (error) {
            this.error = error;
            this.wizardPages = undefined;
        }
    }

    onNavigatePage(data){
        //clear highlighted
        this.template.querySelectorAll(".defaultLinkClass").forEach(function(element) {
            element.classList.remove('currentActivePage');
        });    

        //clear and set highlighted
        let pages = JSON.parse(JSON.stringify(this.wizardPages));
        for(var i = 0; i< pages.length; i++){
            pages[i]['linkStyleClass'] = 'defaultLinkClass';
            if(data.api_Name == pages[i].api_Name){
                pages[i]['linkStyleClass'] = 'defaultLinkClass currentActivePage';
            }
            if(pages[i].form_Pages != undefined){
                for(var y = 0; y < pages[i].form_Pages.length; y++){
                    pages[i].form_Pages[y]['linkStyleClass'] = 'defaultLinkClass';
                    if(data.api_Name == pages[i].form_Pages[y].api_Name){
                        pages[i].form_Pages[y]['linkStyleClass'] = 'defaultLinkClass currentActivePage';
                    }
                }
            }
            this.wizardPages = pages;
        }
    }
    
    @wire(getRecord, { recordId: '$offerId', fields: ['SBQQ__Quote__c.Offer_Status__c', 'SBQQ__Quote__c.SBQQ__PrimaryContact__c',
                                                        'SBQQ__Quote__c.Offer_has_grant__c', 'SBQQ__Quote__c.Offer_has_scholarship__c',
                                                        'SBQQ__Quote__c.Onshore_MU_Transfer__c'
                                                    ] })
    wiredParent({ error, data }) {
        this.loading = true;
        if (data) {
            
            this.error = undefined; 
            this.offerRecord = JSON.parse(JSON.stringify(data.fields));
            this.contactId = data.fields.SBQQ__PrimaryContact__c.value;

            getPrimaryContact({contactId: this.contactId})
            .then(result => {
                let pages = JSON.parse(JSON.stringify(this.wizardPages));
                let offer = JSON.parse(this.offerRecord.Offer_Status__c.value);
                let cont = JSON.parse(JSON.stringify(result[0]));

                let defaultClass = 'progress-item';
                let activeClass = ' progress-item-active';
                let completedClass = ' progress-item-completed';
                let lastChildClass = ' progress-item-last-child';
                let lastChildActiveClass = ' progress-item-last-child-active';

                let subDefaultClass = 'sub-progress-item';
                let subActiveClass = ' sub-progress-item-active';
                let subCompletedClass = ' sub-progress-item-completed';
                let subLastChildClass = ' sub-progress-item-last-child';
                let subLastChildActiveClass = ' sub-progress-item-last-child-active';
                let onshoreMUTransfer = this.offerRecord.Onshore_MU_Transfer__c.value;
                //remove under 18 page from the menu when User is above 18
                //remove grant page from the menu if offer doesn't have grant/scholarship
                for(var x =0; x< pages.length; x++){
                    if(pages[x].form_Pages != undefined){
                        for(var y=0; y<pages[x].form_Pages.length; y++){
                            //guardian page
                            if(pages[x].form_Pages[y].api_Name == 'under18' && !cont.Under_18__c){
                                pages[x].form_Pages.splice(y, 1);
                            }
                        }
                        for(var y=0; y<pages[x].form_Pages.length; y++){
                            //grant
                            if(pages[x].form_Pages[y].api_Name == 'grant' && this.offerRecord.Offer_has_grant__c.value <= 0){
                                pages[x].form_Pages.splice(y, 1);
                            }
                        }
                        for(var y=0; y<pages[x].form_Pages.length; y++){
                            //scholarship
                            if(pages[x].form_Pages[y].api_Name == 'scholarship' && this.offerRecord.Offer_has_scholarship__c.value <= 0){
                                pages[x].form_Pages.splice(y, 1);
                            }
                        }
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
                //loop through the updated list of pages
                for(var i = 0; i< pages.length; i++){
                    pages[i]['linkStyleClass'] = 'defaultLinkClass';
                    pages[i]['styleClass'] = defaultClass;
                    pages[i]['Status'] = 'inactive';
                    if(i === (pages.length-1)){
                        if(offer.API_Name__c == pages[i].api_Name){
                            pages[i]['linkStyleClass'] = 'defaultLinkClass currentActivePage';
                            pages[i]['styleClass'] = defaultClass + lastChildActiveClass;
                            pages[i]['Status'] = 'active';
                        }else{
                            pages[i]['styleClass'] = defaultClass + lastChildClass;
                        }
                        
                    }
                    else if(offer.API_Name__c == pages[i].api_Name){
                        pages[i]['linkStyleClass'] = 'defaultLinkClass currentActivePage';
                        pages[i]['styleClass'] = defaultClass + activeClass;
                        pages[i]['Status'] = 'active';
                    }
                    else if(pages[i].api_Name === 'personaldetails' && pages[i].form_Pages != undefined){
                        pages[i]['Status'] = 'inactive';
                        let childPages = [];
                        for(var j=0; j<pages[i].form_Pages.length; j++){
                            pages[i].form_Pages[j]['Status'] = 'inactive';
                            if(pages[i].form_Pages[j].display_Order <= offer.Display_Order__c){
                                pages[i].form_Pages[j]['Status'] = 'active';
                                pages[i]['styleClass'] = defaultClass + activeClass;

                            }
                            childPages.push(pages[i].form_Pages[j]);
                        }
                        if(offer.Display_Order__c >= 3){
                            pages[i]['styleClass'] = defaultClass + completedClass;
                        }
                        pages[i].form_Pages = childPages;
                    }


                    else if(pages[i].display_Order < offer.Display_Order__c){
                        pages[i]['styleClass'] = defaultClass + completedClass;
                        pages[i]['Status'] = 'completed';

                    }
                    if(pages[i]['label'] != null){
                        pages[i]['styleClass'] += ' upper-text-padding';

                    }

                    if(pages[i].form_Pages != undefined){
                        for(var y = 0; y < pages[i].form_Pages.length; y++){
                            pages[i].form_Pages[y]['linkStyleClass'] = 'defaultLinkClass';
                            pages[i].form_Pages[y]['styleClass'] = subDefaultClass;
                            pages[i].form_Pages[y]['Status'] = 'inactive';
                            if(i === (pages.length-1)){
                                if(offer.API_Name__c == pages[i].form_Pages[y].api_Name){
                                    pages[i].form_Pages[y]['linkStyleClass'] = 'defaultLinkClass currentActivePage';
                                    pages[i].form_Pages[y]['styleClass'] = subDefaultClass + subLastChildActiveClass;
                                    pages[i].form_Pages[y]['Status'] = 'active';
                                }else{
                                    pages[i].form_Pages[y]['styleClass'] = subDefaultClass + subLastChildClass;
                                }
                                
                            }
                            else if(offer.API_Name__c == pages[i].form_Pages[y].api_Name){
                                pages[i].form_Pages[y]['linkStyleClass'] = 'defaultLinkClass currentActivePage';
                                pages[i].form_Pages[y]['styleClass'] = subDefaultClass + subActiveClass;
                                pages[i].form_Pages[y]['Status'] = 'active';
                            }
                            else if(pages[i].form_Pages[y].display_Order < offer.Display_Order__c){
                                pages[i].form_Pages[y]['styleClass'] = subDefaultClass + subCompletedClass;
                                pages[i].form_Pages[y]['Status'] = 'completed';

                            }
                            if(pages[i].form_Pages[y]['label'] != null){
                                pages[i].form_Pages[y]['styleClass'] += ' upper-text-padding';

                            }
                        }
                    }
                }
                this.wizardPages = pages;
            })
            .catch(error => {
                console.log(error);
               return error;
            });
        } else if (error) {
            console.log('PROGRESS ERROR: ' + JSON.stringify(error));
            this.error = error;
            this.offerRecord = undefined;
        }
        this.loading = false;
    }
  
}