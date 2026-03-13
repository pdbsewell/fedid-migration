/* eslint-disable eqeqeq */
/* eslint-disable dot-notation */
/* eslint-disable vars-on-top */
/* eslint-disable no-console */
/* eslint-disable no-unused-vars */
import { LightningElement, wire, track, api } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import getFormPage from '@salesforce/apex/OfferLightningEnabledClass.getFormPage';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import * as util from 'c/util';
import { loadStyle } from 'lightning/platformResourceLoader';
import static_resource from '@salesforce/resourceUrl/admission_assets'

export default class OfferMobileHeaderNav extends LightningElement {
    @track showNavigation = false;
    @track menuIcon = true;
    @track offerRecord;
    @track currentPage;
    @track activePage;
    @track numLength;


    @wire(getFormPage)
    wiredGetFormPageList({ error, data }) {
        if (data) {
            this.wizardPages = data;
            this.error = undefined;
            this.urlParam = util.urlParameter(window.location.href);
            this.offerId = this.urlParam.get('id');
        } else if (error) {
            this.error = error;
            this.wizardPages = undefined;
            console.log(error);
        }
    }

    
    @wire(getRecord, { recordId: '$offerId', fields: ['SBQQ__Quote__c.Offer_Status__c'] })
    wiredParent({ error, data }) {
        if (data) {
            this.error = undefined; 
            var offer = JSON.parse(data.fields.Offer_Status__c.value);
            this.activePage = offer;
            var pages = JSON.parse(JSON.stringify(this.wizardPages));
            for(var i =0; i< pages.length; i++){
                if(offer.API_Name__c == pages[i].api_Name){
                    pages[i]['numberClass'] = 'header-page-name single-digit';
                    if(offer.Display_Order__c > 9){
                        pages[i]['numberClass'] = 'header-page-name double-digit'; 
                    }else if(pages[i].parent_Page != null){
                        //pages[i].display_Order = pages[i].Parent_Page__r.Display_Order__c;
                        pages[i].display_Order = Math.trunc(pages[i].display_Order);
                    }
                    this.currentPage = pages[i];
                }
            }
        } else if (error) {
            this.error = error;
            this.currentPage = undefined;
        }
    }


    handleOnclick(){
        this.showNavigation = !this.showNavigation;
        this.menuIcon = !this.menuIcon;
        fireEvent(this.pageRef, 'toggleFormPage', this.menuIcon); 
    }    

    get visibility(){
        return this.showNavigation ? 'show-nav' : 'hide-nav';
    }

    get iconClass(){
        return this.menuIcon ? 'show-up' : 'show-down';
    }

    connectedCallback() {
        loadStyle(this, static_resource + '/css/desktop-style-sheet.css');
        loadStyle(this, static_resource + '/css/mobile-style-sheet.css');
        // subscribe to event from form page (get page currently displayed)
        registerListener('onMenuNavigate', this.onMenuNavigate, this);
        registerListener('onButtonNavigate', this.onButtonNavigate, this);
    }
    disconnectedCallback() {
        // unsubscribe to event from form page (get page currently displayed)
        unregisterAllListeners(this);
    }

    onMenuNavigate(data) {
        data['numberClass'] = 'header-page-name single-digit';
        if(data.display_Order > 9){
            data['numberClass'] = 'header-page-name double-digit'; 
        }else if(data.parent_Page != null){
            //data.display_Order = data.Parent_Page__r.Display_Order__c;
            data.display_Order = Math.trunc(data.display_Order);
        }
        this.currentPage = data;
        this.showNavigation = !this.showNavigation;
        this.menuIcon = !this.menuIcon;
    }

    onButtonNavigate(data) {
        data['numberClass'] = 'header-page-name single-digit';
        if(data.display_Order > 9){
            data['numberClass'] = 'header-page-name double-digit'; 
        }else if(data.parent_Page != null){
            //data.display_Order = data.Parent_Page__r.Display_Order__c;
            data.display_Order = Math.trunc(data.display_Order);
        }
        this.currentPage = data;
    }
}