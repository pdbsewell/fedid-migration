import { LightningElement, api, track } from 'lwc';

export default class CustomVisualPicker extends LightningElement {
    @api svgIcon;
    @api title;
    @api content;
    @api linkId;
    @api hideIcon;
    @api isDisabled;
    @api type;

    handleClick(event) {
        const id = event.currentTarget.id.split('-'); //because id returns string-000
        const selectEvent = new CustomEvent('pickerclick', {
            detail: {
                id :(id ? id[0] : ''),
                value: this.type + ' ' + this.title
            }
        });
       this.dispatchEvent(selectEvent);
    }
}