/* eslint-disable vars-on-top */
/* eslint-disable no-console */
import { LightningElement, track, wire, api } from 'lwc';
import * as util from 'c/util';
import { getRecord } from 'lightning/uiRecordApi';

export default class OfferCoverLetter extends LightningElement {
    @api contactId;
    @api content;
    @api offerRecord;
    @track contactRecord;
    @api quoteLineItems = [];
    @track salutation = '';
    @api bundleCount = 0;

    get offerId(){
        this.urlParam = util.urlParameter(window.location.href);
        return this.urlParam.get('id');
    }

    connectedCallback(){
        var quoteLines = util.getQuoteLines(this.offerId);
        quoteLines.then(value =>{
            this.quoteLineItems = value;
            for(var i=0; i<this.quoteLineItems.length; i++){
                if(this.quoteLineItems[i].SBQQ__ProductFamily__c == 'Bundle'){
                    this.bundleCount++;
                }
            } 
            if(this.content){   
                let bundleText = (this.bundleCount > 1 ? 'packaged' : '');
                this.content = this.content.replace('#PACKAGED#', bundleText);
            }

        });                
    }

    @wire(getRecord, { recordId: '$contactId', fields: ['Contact.Salutation', 'Contact.First_Name__c', 'Contact.Last_Name__c']})
    wiredContact({ error, data }) {
        if (data) {
            this.contactRecord = JSON.parse(JSON.stringify(data.fields));
            let sal = (this.contactRecord.Salutation.value != null ? this.contactRecord.Salutation.value : '');
            let contactName =  sal + ' ' + this.fullname;
            if(this.content && this.contactRecord && this.offerRecord){   
                let responseDate = new Date(this.offerRecord.Calculated_Expiry_Date__c.value);
                this.content = this.content.replace('#CONTACT_NAME#', contactName);
                this.content = this.content.replace('#OFFER_RESPONSE_DATE#', util.dateFormatted(responseDate));
            }

        } else if (error) {
            this.error = error;
            console.log(error);
        }
    }

    get hasRendered(){     
        return this.offerRecord !== undefined 
                && this.contactRecord !== undefined 
                && this.content !== undefined;
    }
    // handle Mononymous names
    get fullname() {
        let firstName = this.contactRecord.First_Name__c.value;
        let lastName = this.contactRecord.Last_Name__c.value;
        // verify if First Name is null/blank or spaces -- mononym
        if (!firstName || !firstName.trim()) {
            return lastName;
        }
        return firstName + ' ' + lastName;
    }

}