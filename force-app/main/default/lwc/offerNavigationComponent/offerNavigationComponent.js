/* eslint-disable eqeqeq */
/* eslint-disable no-console */
/* eslint-disable no-loop-func */
/* eslint-disable no-unused-vars */
/* eslint-disable vars-on-top */
import { LightningElement, api, track, wire } from 'lwc';
import * as util from 'c/util';
import { updateRecord } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import { loadStyle } from 'lightning/platformResourceLoader';
import static_resource from '@salesforce/resourceUrl/admission_assets'

export default class OfferNavigationComponent extends LightningElement {
    @api offerRecord;
    @api wizardPage;
    @track loading = false;
    @track backBtnClass;
    @track nextBtnClass;
    @track nextBtnDisabled = false;
    @track continueBtnText;

    @wire(CurrentPageReference) pageRef;

    connectedCallback(){        
        loadStyle(this, static_resource + '/css/desktop-style-sheet.css');
        loadStyle(this, static_resource + '/css/mobile-style-sheet.css');
    }

    previousHandler() {
        this.dispatchEvent(new CustomEvent('previous'));
    }

    nextHandler(event){
        if(this.wizardPage){
            let parsedPage = JSON.parse(JSON.stringify(this.wizardPage));
            if(parsedPage.api_Name == 'healthInsurance'){
                fireEvent(this.pageRef, 'SaveHealth', parsedPage); 
            }
            else if(parsedPage.api_Name == 'visadetails'){
                fireEvent(this.pageRef, 'SaveVisaDetails', parsedPage); 
            }
            else if(parsedPage.api_Name == 'under18'){
                fireEvent(this.pageRef, 'SaveUnder18', parsedPage); 
            }
            else if(parsedPage.api_Name == 'termsAndConditions'){
                fireEvent(this.pageRef, 'AgreeAndSign', parsedPage); 
            }
            else if(parsedPage.api_Name === 'confirm-details'){
                fireEvent(this.pageRef, 'ConfirmDetails', parsedPage); 
            }
            else{
                this.dispatchEvent(new CustomEvent('next'));
            }
        }
    }

    get hasRendered(){
        if(this.wizardPage){
            let parsedPage = JSON.parse(JSON.stringify(this.wizardPage));
            this.backBtnClass =  'slds-button slds-button_neutral ' + parsedPage.backBtnClass;
            this.nextBtnClass =  'slds-button slds-button_neutral ' + parsedPage.nextBtnClass;
            this.continueBtnText = 'Continue';
            this.nextBtnDisabled = false;
            let pageNeedSave = parsedPage.api_Name == 'under18' || parsedPage.api_Name == 'payment'
                || parsedPage.api_Name === 'healthInsurance' || parsedPage.api_Name === 'visadetails';
            if(pageNeedSave){
                this.continueBtnText = 'Save & Continue';
            }else if(parsedPage.api_Name === 'termsAndConditions'){
                this.nextBtnDisabled = util.disableButton(this.offerRecord);
                this.continueBtnText = 'Agree & Sign';
                this.nextBtnClass += ' long-btn';
            }else if(parsedPage.api_Name === 'confirm-details'){
                this.continueBtnText = 'Confirm';
            }
            this.wizardPage = parsedPage;
        }
        return this.wizardPage;
    }

}