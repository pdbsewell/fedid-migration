import { LightningElement, track, api } from 'lwc';
import Offer_Document_Email from '@salesforce/label/c.Offer_Document_Email';
import Offer_MC_Document_Email from '@salesforce/label/c.Offer_MC_Document_Email';
import * as util from 'c/util';
import getFirstCourseQuoteLineProductCode from '@salesforce/apex/OfferLightningEnabledClass.getFirstCourseQuoteLineProductCode';

export default class OfferSummary extends LightningElement {
    @api offerRecord;
    @api content;
    @track customer;
    @track error;

    @api updatedContent;

    connectedCallback() {
        getFirstCourseQuoteLineProductCode({quoteId: this.offerRecord.Id.value})
        .then(result => {
            if (result) {
                if(this.content && this.offerRecord){ 
                    let expiry = new Date(this.offerRecord.Calculated_Expiry_Date__c.value);
                    this.content = util.replaceAllString(this.content, '#FULLNAME#', this.fullname );
                    this.content = util.replaceAllString(this.content, '#OFFER_RESPONSE_DATE#', util.dateFormatted(expiry))
                    this.content = this.content.replace(/#EMAIL#/g, contactEmailHyperlink(result));
                    this.updatedContent = this.content;
                }
            }
        })
        .catch(error => {
            console.log(error);
            return this.content;
        });
    }
    // handle Mononymous names
    get fullname() {
        let firstName = this.offerRecord.SBQQ__PrimaryContact__r.value.fields.First_Name__c.value;
        let lastName = this.offerRecord.SBQQ__PrimaryContact__r.value.fields.Last_Name__c.value;
        // verify if First Name is null/blank or spaces -- mononym
        if (!firstName || !firstName.trim()) {
            return lastName;
        }
        return firstName + ' ' + lastName;
    }

}

/*
If the first course's quote line's product code = BUNENG, display email hyperlink to mc.documents@monash.edu
If the first course's quote line's product code = BUNFOU, display email hyperlink to mc.documents@monash.edu
If the first course's quote line's product code = BUNCOL, display email hyperlink to mc.documents@monash.edu
If the first course's quote line's product code = BUNDIP, display email hyperlink to mc.documents@monash.edu
If the first course's quote line's product code = BUNUNI, display email hyperlink to mu.documents@monash.edu
*/
function contactEmailHyperlink(productCode) {
    if (productCode === 'BUNUNI') {
        return Offer_Document_Email;
    } else {
        return Offer_MC_Document_Email;
    }
}