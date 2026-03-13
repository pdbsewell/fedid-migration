import { LightningElement, api } from 'lwc';

export default class CustomLookup extends LightningElement {
    @api childObjectApiName = 'User'; //Contact is the default value
    @api targetFieldApiName = 'Name'; //AccountId is the default value
    @api disabled = false;
    @api value;
    @api required = false;
    @api uniqueKey;
    @api variant;
    @api accessKey;

    handleChange(event) {
           
        // Creates the event
        let key = this.uniqueKey;
        let accessKey = this.accessKey;;
        let selectedId = event.detail.value[0]; 
        const selectedEvent = new CustomEvent('valueselected', {
          //  detail: event.detail.value[0]
          detail: { selectedId, key ,accessKey},
        });
        //dispatching the custom event
        this.dispatchEvent(selectedEvent);
    }

    @api isValid() {
        if (this.required) {
            this.template.querySelector('lightning-input-field').reportValidity();
        }
    }
}