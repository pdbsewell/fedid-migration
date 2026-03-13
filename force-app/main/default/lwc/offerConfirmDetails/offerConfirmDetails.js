import { LightningElement, api, track, wire } from 'lwc';
import * as util from 'c/util';
import selectByQuoteIdAndProductFamily from '@salesforce/apex/OfferLightningEnabledClass.selectByQuoteIdAndProductFamily';

export default class OfferConfirmDetails extends LightningElement {
    @api offerRecord;
    @api content;
    @api parent;
    @track oshcProduct;
    @track summary = '';
    @track oshcUpdate = false;

    get offerId(){
        return this.offerRecord.Id.value;
    }

    get hasRendered(){
        return this.offerRecord && this.summary && this.oshcUpdate;
    }

    oshcContent(){
        if(this.offerRecord && this.content){
            let content = this.content;
            selectByQuoteIdAndProductFamily({offerId: this.offerId, productFamily:  'OSHC'})
            .then(result => {
                let oshc = '';
                let data = JSON.parse(JSON.stringify(result));
                for(let i=0; i < data.length; i++){
                    let d = data[i];
                    if(!d.SBQQ__Hidden__c && d.SBQQ__ProductCode__c != 'BUNHEALTH'){
                        this.oshcProduct = d;
                    }
                }
                content = util.replaceAllString(content, '#OSHC_TYPE#', (this.oshcProduct ? this.oshcProduct.Health_Cover_Type__c : ''));
                this.content = content; 
                this.contentSummary;
                this.oshcUpdate = true;
            }).catch(error => {
                console.log(error);
            });    
        }
        
    }

    get contentSummary(){ 
        let content = this.content;
        let isUnder18 = this.offerRecord.SBQQ__PrimaryContact__r.value.fields.Under_18__c.value;
        content = util.replaceAllString(content, '#GUARDIAN_VISIBILITY#', !isUnder18 ? 'hide-content' : ''); 
        content = util.replaceAllString(content, '#OSHC_PROVIDER#', this.offerRecord.Health_Cover_Provider_Type__c.value);
        content = util.replaceAllString(content, '#GUARDIAN_FNAME#', this.offerRecord.Guardian_First_Name__c.value);
        content = util.replaceAllString(content, '#GUARDIAN_LNAME#', this.offerRecord.Guardian_Last_Name__c.value);
        content = util.replaceAllString(content, '#GUARDIAN_EMAIL#', this.offerRecord.Guardian_Email__c.value);
        content = util.replaceAllString(content, '#GUARDIAN_RELATIONSHIP#', this.offerRecord.Guardian_Relationship_Type__c.value);
        content = util.replaceAllString(content, '#GUARDIAN_OTHER#', this.offerRecord.Guardian_Other_Relationship_Type__c.value);
        content = util.replaceAllString(content, '#PAYMENT_METHOD#', this.offerRecord.Payment_Option__c.value);
        this.summary = content;
        return this.summary;
    }

    connectedCallback(){
        this.oshcContent();
        this.contentSummary;
    }

}