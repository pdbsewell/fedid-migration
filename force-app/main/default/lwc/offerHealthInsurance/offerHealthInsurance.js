/* eslint-disable no-unused-vars */
/* eslint-disable no-console */
import { LightningElement, api, track, wire } from 'lwc';
import * as util from 'c/util';
import getHealthData from '@salesforce/apex/OfferLightningEnabledClass.getQuoteOSHCView';
import saveHealthData from '@salesforce/apex/OfferLightningEnabledClass.setQuoteOSHCView';
import quoteCalculationComplete from '@salesforce/apex/OfferLightningEnabledClass.quoteCalculationComplete';
// import getHealthData from '@salesforce/apex/QuoteService.getQuoteOSHCView';
// import saveHealthData from '@salesforce/apex/QuoteService.setQuoteOSHCView';
// import quoteCalculationComplete from '@salesforce/apex/QuoteService.quoteCalculationComplete';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
import admissions_assets from '@salesforce/resourceUrl/admission_assets'

export default class OfferHealthInsurance extends LightningElement {

    @api content;
    @api offerRecord;
    @api recordId;
    
    @track quotelineItems;
    @track quote;
    @track urlParam;
    @track healthBundleId;

    @track isLocked = true;
    @track radioOptions = [];
    @track radioSelectedValue = '';
    @track savedRadioSelectedValue = '';
    
    @track comboOptions = [];
    @track comboSelectedValue = '';
    ALLIANZ_OSHC = 'Allianz';
    STUDENT_OSHC = 'Student Nominated';
    VISA_EXEMPTED_OSHC = 'No OSHC due to visa type';
    PR_EXEMPTED_OSHC = 'No OSHC due to country of permanent residence';

    @track providerName;
    @track originalProviderName;

    @track isSaving = false;
    @track isLoaded = false;
    @track requireSave = false;
    inPollCount = 0;
    inPollFrequency = [1,2,2,2,2,2,5,5,5,15,30,30,30];
    
    warningImg = admissions_assets + '/screen-icons/warning-medium.png';

    @wire(CurrentPageReference) pageRef;

    pollCalculateStatus(counter)
    {
        console.log(`retrying attempt: #${counter} `);

        // eslint-disable-next-line no-undef-init
        let MOCK_DELAY = undefined;
        if(MOCK_DELAY !== undefined && counter >= MOCK_DELAY)   
        {
            return new Promise((resolve,reject) => { resolve(); } );
        }        
        if(counter >= this.inPollFrequency.length)
        {
            return new Promise((resolve,reject) => { reject(); } );
        }

        return new Promise((resolve, reject) => {
            let seconds = this.inPollFrequency[counter];
            let requestData = {quoteId: this.recordId};
            console.log(`retrying for calculation result in ${seconds} seconds` );

           const infoEvent = new ShowToastEvent({
                title: `retrying for calculation result in ${seconds} seconds`,
                variant: 'Info',
                message: ''
            });
            if(MOCK_DELAY !== undefined)
            {
                this.dispatchEvent(infoEvent);

            }


            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => { 
                quoteCalculationComplete(requestData)
                    .then(result => {
                        if(result) {
                            console.debug('CPQ calculation complete');
                            resolve();
                        } else {

                            this.pollCalculateStatus(++this.inPollCount)
                            .then(gogo => { resolve(gogo); })
                            .catch(rj => { reject(rj) } );
                        }
                    })
                    .catch(error => {
                        console.log(error);
                    });
            }, seconds * 1000);

        
    
        });
        } 


    get isThroughMonash(){
        return this.comboSelectedValue === this.ALLIANZ_OSHC;
    }

    get showWarning()
    {
        return this.comboSelectedValue === this.STUDENT_OSHC;
    }

    get isExempted(){
        return this.comboSelectedValue === this.VISA_EXEMPTED_OSHC || this.comboSelectedValue === this.PR_EXEMPTED_OSHC;;
    }

    onValidate()
    {
        let isValid = true;
        let isRadioBlank = this.radioSelectedValue === '' || this.radioSelectedValue === undefined;
        if(isRadioBlank && this.comboSelectedValue === this.ALLIANZ_OSHC)
        {
            isValid = false;
        }
        if(this.comboSelectedValue === this.STUDENT_OSHC && this.providerName === '')
        {
            isValid = false;
        }
        if(!this.comboSelectedValue){
            isValid = false;
        }
        if(!isValid)
        {
            if(!this.comboSelectedValue){
                const event = new ShowToastEvent({
                    title: 'Validation',
                    variant: 'Warning',
                    message: 'Please select your OSHC.'
                });
                this.dispatchEvent(event);
            }else if(this.comboSelectedValue === this.STUDENT_OSHC){
                const event = new ShowToastEvent({
                    title: 'Validation',
                    variant: 'Warning',
                    message: 'Please fill up the Provider Name field.'
                });
                this.dispatchEvent(event);
            }else{
                const event = new ShowToastEvent({
                    title: 'Validation',
                    variant: 'Warning',
                    message: 'Missing field selection'
                });
                this.dispatchEvent(event);
            }
        }

        return isValid;

    }

    get showSpinner()
    {
        return !this.isLoaded || this.isSaving; 
    }
    
    connectedCallback()
    {
        registerListener('SaveHealth', this.handleSave, this);

        this.recordId = this.offerRecord.Id.value;
        this.providerName = '';
        console.log(`recordId: ${this.recordId}`);
        this.isLoaded = false;
        this.requireSave = false;
        let requestData = {quoteId: this.recordId, requestUpdate: false};
        getHealthData(requestData)
            .then(result => {
                this.isLoaded = true;                
                this.mapResult(result);
            })
            .catch(error => {
                this.handleError(error);
            });
    }

    disconnectedCallback()
    {
        unregisterAllListeners(this);
    }   
    mapResult(result)
    {
        this.isLocked = util.isOfferReadOnly(this.offerRecord) || util.disableButton(this.offerRecord); //result.isLocked;
        this.radioOptions = result.coverOptions;
        this.comboSelectedValue = result.selectedProvider;
        this.providerName = result.selectedProviderName ? result.selectedProviderName : '';
        this.radioSelectedValue = result.selectedHealthOption;
        this.savedRadioSelectedValue = result.selectedHealthOption;
        this.healthBundleId = result.bundleQuoteLineId;
        this.comboOptions = result.providerOptions;
    }

    handleDDLChange(event)
    {
        if(this.requireSave === false){
            this.requireSave = this.comboSelectedValue !== event.detail.value;
        }
        if(this.isLocked === false){
            const selectedOption = event.detail.value;
            this.comboSelectedValue = selectedOption;
            console.debug(`Option selected with value: ${selectedOption}`);
            if(!this.canSelectRadio)
            {
                this.radioSelectedValue = '';
            }
        }
    }

    handleRadioChange(event)
    {
        const selectedOption = event.detail.value;
        if(this.requireSave === false){
            this.requireSave = this.savedRadioSelectedValue !== event.detail.value;
        }
        this.radioSelectedValue = selectedOption;
        console.debug(`Option selected with value: ${selectedOption}`);
    }

    handleSave(data)
    {
        console.log('requireSave: ', this.requireSave);
        let isValid = this.onValidate();
        if(!isValid)
        {

            return false;
        }
        console.debug(`value of isValid is: ${isValid}`);

        if(!this.requireSave)
        {
            let eventData = {page: data, reloadRequired: false};
            fireEvent(this.pageRef, 'ContinueFromHealth', eventData); 
            return true;
        }
        this.isSaving = true;
        console.debug('child save');
        let offer = JSON.parse(this.offerRecord.Offer_Status__c.value);
        let subStatus = util.subStatusTriggerConga;
        
        let requestData = {quoteId: this.recordId, healthBundleId: null, subStatus: subStatus, isLocked: this.isLocked, 
                            selectedProvider: this.comboSelectedValue, selectedProviderName: this.providerName, selectedHealthOption: this.radioSelectedValue};
        let rData = {hqr: requestData};
        saveHealthData(rData)
        .then(result => {
            console.log('save succeed');
            this.proxyLog(result);
            this.pollCalculateStatus(0)
                .then(r2 => {
                    console.debug('promise chain resolved success');
                    this.isSaving = false;
                    this.mapResult(result);
                    let eventData = {page: data, reloadRequired: true};
                    fireEvent(this.pageRef, 'ContinueFromHealth', eventData);
            })
                .catch(error => 
                    {
                        this.handleError(error);          
            });
        })
        .catch(error => {
            this.handleError(error);
        });
    }

    handleError(error)
    {
        const errorToastEvent = new ShowToastEvent({
            title: 'Timeout error trying to re-calculate price',
            variant: 'Error',
            message: ''
        });
        this.dispatchEvent(errorToastEvent);                        
        console.debug('promise chain resolved errror');
        this.isSaving = false;
        this.proxyLog(error);
    }

    proxyLog(data)
    {
        console.debug(JSON.parse(JSON.stringify(data)) );
    }
    get comboDisabled()
    {
        return this.isLocked === true;
    }
    get radioDisabled()
    {
        return this.isLocked === true
        || this.comboSelectedValue === this.STUDENT_OSHC 
        || this.comboSelectedValue === '';
    }
    get hasRendered()
    {
        console.log(this.offerRecord)
        return this.offerRecord && this.quotelineItems;
    }

    onProviderNameChange(event){
        this.providerName = event.target.value;
        this.requireSave = true;
    }
}