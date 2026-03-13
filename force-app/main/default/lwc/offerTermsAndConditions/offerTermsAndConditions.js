/* eslint-disable @lwc/lwc/no-async-operation */
/* eslint-disable no-console */
/* eslint-disable no-unused-expressions */
import { LightningElement, api, track, wire } from 'lwc';
import * as util from 'c/util';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import getQuoteLineBundles from '@salesforce/apex/OfferLightningEnabledClass.getQuoteLineBundles';
import getChildFormElements from '@salesforce/apex/OfferLightningEnabledClass.getChildFormElement';
import getOfferDetails from '@salesforce/apex/OfferLightningEnabledClass.getOfferDetails';
import pendingGenerate from '@salesforce/label/c.Offer_Accepted_Pending_Docu_Generate';
import generateError from '@salesforce/label/c.Offer_Contract_Generate_Error';
import modalText from '@salesforce/label/c.Offer_T_C_modal';
import admission_assets from '@salesforce/resourceUrl/admission_assets';

export default class OfferTermsAndConditions extends LightningElement {
    @api parent;
    @api offerRecord;
    @track elements;
    @track showModal = false;
    @track spinner = false;
    @track timer;
    @track timeCounter = 0;
    @track iconUrl = admission_assets + '/screen-icons/warning-small.png';
    @track modalContent = modalText;
    @track docuMessage = '';
    @track scollerDivClass = 'scroller-div';
    strContent = '';
    
    starting = 5;
    progress = 'width: 5%';
    journeyIcon = admission_assets + '/screen-icons/Journey.png';
    
    @wire(CurrentPageReference) pageRef;
    connectedCallback(){
        registerListener('AgreeAndSign', this.handleClick, this);

    }

    get backgroundImg(){
        let bgImg = admission_assets + '/screen-icons/Group25.jpg';
        return '--image-url: url(\''+bgImg +'\')';
    }

    get hasRendered(){
        let urlParam = util.urlParameter(window.location.href);
        this.offerId = urlParam.get('id');
        return this.parent && this.offerRecord;
    }

    updateContent(){  
        if(this.elements && this.quoteLineBundles){ 
            for(let i = 0; i < this.elements.length; i++){
                let content = this.elements[i].description;
                content = util.replaceAllString(content, '#OSC_YEAR#', this.offerRecord.Visa_Priced_Year__c.value);               
                
                if(this.elements[i].api_Name === 'tc-tuition-fees'){
                    
                    for(let x = 0; x < this.quoteLineBundles.length; x++){
                        let productCode = this.quoteLineBundles[x].SBQQ__ProductCode__c;
                        let coursefee = (this.quoteLineBundles[x].Offer_Primary_Quote_Line__r.Course_Fee_Year__c !== undefined ? this.quoteLineBundles[x].Offer_Primary_Quote_Line__r.Course_Fee_Year__c : '');       
                        if(this.quoteLineBundles[x].Offer_Primary_Quote_Line__r.SBQQ__ProductFamily__c == 'English Course'){
                            this.strContent += 'The tuition fee and administration fee for Monash College Pty Ltd English Language course is only applicable for courses commencing in ' + coursefee +'. ';
                        }else if(productCode === 'BUNFOU'){
                            this.strContent += 'The tuition fee for Monash College Pty Ltd Foundation Year is only applicable for courses commencing in ' + coursefee +'. ';
                        }else if(productCode === 'BUNCOL'){
                            this.strContent += 'The tuition fee for Monash College Pty Ltd Diploma is only applicable for courses commencing in ' + coursefee +'. ';
                        }else if(productCode === 'BUNDIP'){
                            this.strContent += 'The tuition fee for Monash College Pty Ltd Diploma is only applicable for courses commencing in ' + coursefee +'. ';
                        }else if(productCode === 'BUNUNI'){
                            this.strContent += 'The tuition fee for Monash University is only applicable for courses commencing in ' + coursefee +'. ';
                        }  
                    }
                    
                    if(this.strContent !== ''){
                        console.log(this.strContent !== '');
                        content = util.replaceAllString(content, '#BUNDLE_CONTENT#', this.strContent);  
                    }
                    this.elements[i].description = content;
                    continue;
                }   
                
                
                this.elements[i].description = content;
            }

        }
    }

    get isButtonDisabled(){
        return this.offerRecord.Sub_Status__c.value === 'Signed recipient 1'
            || this.offerRecord.Sub_Status__c.value === 'Signed recipient 2'
            || this.offerRecord.Sub_Status__c.value === 'APEX Doc. Gen/Save Error'
            || this.offerRecord.SBQQ__Status__c.value === 'Accepted';
    }

    //GET CHILD ELEMENT OF FORM ELEMENT
    @wire(getChildFormElements, {parentElementId: '$parent.Id'})
    wiredGetChildFormElements({ error, data }) {
        if (data) {
            let res = JSON.parse(JSON.stringify(data));          
            this.elements = res;

            getQuoteLineBundles({offerId: this.offerRecord.Id.value})
            .then(result => {
                this.quoteLineBundles = result;
                this.updateContent();
            })
            .catch(error => {
                console.log('error: ' , error);
            });

        } else if (error) {
            console.log('ERROR: ' + JSON.stringify(error));
            this.elements = undefined;
            let exception = JSON.parse(JSON.stringify(error)); 
            this.showToastMethod('ERROR', exception.body.message, 'error');
        }
    }

    handleClick(){
        if(!this.isButtonDisabled){
            this.showModal = true;
        }
    }

    closeModal(){
        this.showModal = false;
    }

    handleAgree(){    
        if(!this.isButtonDisabled ){  
            this.showModal = false; 
            this.spinner = true; 
            this.agreed = true;
            this.scollerDivClass = 'scroller-div hide-scroller';
            let fields = {};
            fields.Id = this.offerId;
            fields.Acknowledged_by_applicant__c = this.agreed;
            if(this.offerRecord.Sub_Status__c.value == util.subStatusTriggerConga){
                fields.Sub_Status__c = util.subStatusCompleted;
            }
            let record = {fields};
            this.updateOffer(record, true);
            window.scroll(0,0);            
            this.validateConga();                     
        } 
    }

    validateConga(){
        this.timer = setTimeout(function() {
            getOfferDetails({offerId: this.offerRecord.Id.value})
                .then(result => {              
                    this.timeCounter++;
                    let data = JSON.parse(JSON.stringify(result));
                    let maxCount = 60;
                    let multiplyProgress = (100 / maxCount);
                    let updatedProgress = this.starting + this.calculateProgress(this.timeCounter * multiplyProgress);
                    this.progress = 'width: ' + (updatedProgress >= 100 ? 100 : updatedProgress) + '%';
                    let hasError = (data.Sub_Status__c === 'Conga Error' || data.Sub_Status__c === 'DocuSign Error' || data.Sub_Status__c === 'Timed out on portal');
                    let hasDocusign = (data.Sub_Status__c === 'Pending Signature in DocuSign' && data.Acknowledged_by_applicant__c && 
                                        data.DocuSign_Signing_URL__c !== this.offerRecord.DocuSign_Signing_URL__c.value);
                    let isReady = (data.Sub_Status__c === 'Ready for acknowledgement' && data.Acknowledged_by_applicant__c === true
                                    && data.Primary_Document__c != null);
                    console.log('isReady: ', (isReady));
                    if(hasDocusign){
                        window.open(data.DocuSign_Signing_URL__c, '_self');

                    }else if(hasError){
                        this.docuMessage = generateError;

                    }else if(this.timeCounter >= maxCount){
                        let record = {
                            fields:{
                                Id: this.offerId,
                                Sub_Status__c: 'Timed out on portal'
                            }
                        };
                        this.updateOffer(record, false);
                        this.docuMessage = generateError;

                    } else {
                        this.validateConga();
                    }
                })
                .catch(error => {
                    console.log('** error: ' + JSON.stringify(error));
                });
        }.bind(this), 3000);
        
    }
    
    updateOffer(record, offerAccepted){
        updateRecord(record)
            .then(() => {     
                if(offerAccepted){
                    console.log('** SUCCESS **');
                }
            })
            .catch(error => {
                //this.spinner = false; 
                var exception = JSON.parse(JSON.stringify(error));  
                util.log('*** Error ***' );
                util.logJson(exception);                          
                this.showToastMethod('ERROR', exception.body.message, 'error');
            });  
    }

    calculateProgress(min){
        let max = 100;
        let incomplete = (min - max) / max;
        let completed = (incomplete * 100) + 100;
        //let completedPercentage = "width:"+ completed + "%";
        return completed;
    }
    

    showToastMethod(title, message, type){
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message, 
                variant: type,
            }),
        ); 
    }

}