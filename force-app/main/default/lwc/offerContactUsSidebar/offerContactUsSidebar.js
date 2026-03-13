import { LightningElement, wire } from 'lwc';
import * as util from 'c/util';
import { getRecord } from 'lightning/uiRecordApi';
import communityContactUsText from '@salesforce/label/c.Offer_ContactUs_Text';
import communityContactEmail from '@salesforce/label/c.Offer_Contact_Email';
import communityContactEmailSubject from '@salesforce/label/c.Offer_Contact_Email_Subject';

export default class OfferContactUsSidebar extends LightningElement {
    offerId = '';
    emailUrl = '';
    contactUsText = communityContactUsText;
    connectedCallback(){
        let urlParam = util.urlParameter(window.location.href);
        this.offerId = urlParam.get('id');

    }

    @wire(getRecord, {recordId: '$offerId', fields: ['SBQQ__Quote__c.Name']})
    wiredQuote({error, data}){
        if(data){            
            this.emailUrl = 'mailto:' + communityContactEmail + '?subject=' + communityContactEmailSubject + ' ' + data.fields.Name.value;
        }else if(error){
            console.log(error);
        }
    }
}