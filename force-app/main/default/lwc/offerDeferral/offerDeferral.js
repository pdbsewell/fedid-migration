import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

export default class OfferDeferral extends LightningElement {
    @track oppty;
    //public
    @api recordId;
    @track isModalOpen = false;
    @wire(getRecord, { recordId: '$recordId', layoutTypes: 'Full', modes: 'View' })
    wireOpportunity({ error, data }) {
        if (data) {
            this.oppty = {};
            for (let f in data.fields){
                if (Object.prototype.hasOwnProperty.call(data.fields, f)) {
                    this.oppty[f] = data.fields[f].value;
                }
            }
            this.error = undefined;
        } else if (error) {
            this.showToast('Data load Error', error.body.message, 'error');
            this.oppty = undefined;
        }
    }
    openModal() {
        this.isModalOpen = true;
    }
    closeModal() {
        this.isModalOpen = false;
    }
}