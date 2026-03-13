/* eslint-disable eqeqeq */
/* eslint-disable dot-notation */
/* eslint-disable vars-on-top */
import { LightningElement, wire, track, api } from 'lwc';
import getQuoteLineList from '@salesforce/apex/OfferLightningEnabledClass.getQuoteLineList';
import * as util from 'c/util';

export default class offerProductList extends LightningElement {
    @api offerRecord;
    @api quoteClauses;
    @track quoteLineItems = [];
    @track urlParam;

    @track regenReason = '';
    @track value;
    @track error;
    @track pending = true;

    get offerId(){
        if(this.offerRecord){
            this.regenReason = this.offerRecord.Offer_Regeneration_Reason__c.value;
        }
        this.urlParam = util.urlParameter(window.location.href);
        let idParam  = this.urlParam.get('id');
        return idParam;

    }

    promise = util.getQuoteLines(this.offerId);

    connectedCallback(){
        var quoteLines = util.getQuoteLines(this.offerId);
        quoteLines.then(value =>{
            var result = JSON.parse(JSON.stringify(value));
            for(var i=0; i<result.length; i++){
                if(result[i].SBQQ__ProductFamily__c == 'Grant' || result[i].SBQQ__ProductFamily__c == 'Scholarship'){                    
                        result[i]['Label'] = result[i].SBQQ__ProductFamily__c;
                        result[i]['Value'] = result[i].SBQQ__ProductName__c;
                        this.quoteLineItems.push(result[i]);
                }
                if(result[i].SBQQ__ProductFamily__c == 'Bundle'
                    && result[i].Offer_Primary_Quote_Line__c != null
                    && result[i].Offer_Primary_Quote_Line__r.Course_Title__c != null){
                        
                    result[i]['Label'] = 'Course';
                    let title = (result[i].Offer_Primary_Quote_Line__r.Course_Title__c != null ? result[i].Offer_Primary_Quote_Line__r.Course_Title__c : '');
                    let code = (result[i].Offer_Primary_Quote_Line__r.Course_Code__c != null ? ' (' + result[i].Offer_Primary_Quote_Line__r.Course_Code__c + ')' : '');
                    result[i]['Value'] = title + code;
                    this.quoteLineItems.push(result[i]);
                }
            } 

        });
    }

    get hasRendered(){
        return this.quoteLineItems.length > 0;
    }
    

}