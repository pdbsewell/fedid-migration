/* eslint-disable no-console */
import { LightningElement, api, track } from 'lwc';

export default class OfferHealthOption extends LightningElement {

    @api radioOption = {};
    @api selectedValue = '';
    @api radioDisabled = false;
    
    get AUD()
    {
        return '$A ';
    }
    get radioSelected()
    {
        return this.selectedValue === this.radioOption.value;
    }

    handleSelectChange(event)
    {
        let newValue = event.target.value;
        this.dispatchEvent(new CustomEvent('select', {detail: {value: newValue} }));
    }

}