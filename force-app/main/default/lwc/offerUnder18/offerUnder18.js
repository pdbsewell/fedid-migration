import { LightningElement, api, track } from 'lwc';
import static_resource from '@salesforce/resourceUrl/admission_assets'

export default class OfferUnder18 extends LightningElement {
    @api offerRecord;
    @api content;
    @track imgUrl;

    get updatedContent(){
        if(this.offerRecord && this.content){
            this.content = this.content.replace('#OFFER_RESPONSE_DATE#', this.offerRecord.Offer_Response_Date__c.value);
            this.content = this.content.replace('#WARNING#', static_resource + '/screen-icons/warning-medium.png');
            this.content = this.content.replace('#DOCUMENT_ICON#', static_resource + '/screen-icons/document-icon.png');
        }
        return this.content;
    }

}