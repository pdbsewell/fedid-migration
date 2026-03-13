/* eslint-disable no-console */
/* eslint-disable eqeqeq */
/* eslint-disable vars-on-top */
import * as util from 'c/util';
import { fireEvent } from 'c/pubsub';
import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getChildFormElements from '@salesforce/apex/OfferLightningEnabledClass.getChildFormElement';

export default class OfferPaymentOptions extends LightningElement {
    @api offerRecord;
    @api parent;
    @track selectedPayment;
    @track elements = [];
    @track headerContent;

    get hasRendered(){        
        this.selectedPayment = this.offerRecord.Payment_Option__c.value;
        let studentID = (this.offerRecord.Person_ID_unique__c.value != null ?
                            this.offerRecord.Person_ID_unique__c.value : '');
        this.headerContent = this.parent.description.replace('#STUDENT_ID#', studentID);    
        return this.parent;
    }

    
    //GET PAYMENT PICKLIST VALUES
    @wire(CurrentPageReference) pageRef;
    renderedCallback() {        
        fireEvent(this.pageRef, 'onPaymentSelect', this.selectedPayment);  
    }
    
    //GET CHILD ELEMENT OF FORM ELEMENT
    @wire(getChildFormElements, {parentElementId: '$parent.Id'})
    wiredGetChildFormElements({ error, data }) {
        if (data) {
            this.elements = data;
        } else if (error) {
            console.log('ERROR: ' + JSON.stringify(error));
            this.elements = undefined;
        }
    }

    //INPUT RADIO OPTION VALUES 
    get options() {
        if(this.elements){
            var options = [];
            //COLLECT RADIO BUTTON OPTION VALUES
            var elems = JSON.parse(JSON.stringify(this.elements));
            for(var i = 0; i < elems.length; i++ ){
               var opt = {};
               opt.Id = elems[i].label.replace(/\s/g,'');
               opt.label = elems[i].description;
               opt.value = elems[i].label;
               opt.checked = (elems[i].label == this.offerRecord.Payment_Option__c.value ? true : false);
               opt.elementDisabled = 'slds-form-element__control';
               opt.labelDisabled = 'lightning-rich-text-content';
               opt.disabledClass = 'slds-radio_faux';
               if(util.isOfferReadOnly(this.offerRecord) && !opt.checked){
                   opt.disabled = true;
                   opt.elementDisabled = 'slds-form-element__control disable-radio';
                   opt.labelDisabled = 'lightning-rich-text-content disable-input';
                   opt.disabledClass = 'slds-radio_faux disable-select';
               }
               
               options.push(opt);
            }
        }
        return options;
    }

    //SET SELECTED PAYMENT OPTION AND FIRE CUSTOM EVENT
    handleChange(event) {
        this.selectedPayment = event.target.value;
        fireEvent(this.pageRef, 'onPaymentSelect', this.selectedPayment);         
    }


    
}