import { LightningElement, track, api } from 'lwc';

export default class asyncMarkup extends LightningElement {
    @track value;
    @track error;
    @track pending = true;

    @api promise;

    connectedCallback() {
        this.promise
            .then(value => {
                this.value = value;
                this.pending = false
            })
            .catch(error => {
                this.error = error;
                this.pending = false;
            });
    }
}