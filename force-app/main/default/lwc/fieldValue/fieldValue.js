import { LightningElement, api, track } from 'lwc';

export default class FieldValue extends LightningElement {
    @api item;
    @api key;

    connectedCallback(){
    }

    @api
    get value(){
        return this.item[this.key.fieldName];
    }

    @api
    get nameValue(){
        return this.key.hasOwnProperty('typeAttributes') ? this.item[this.key.typeAttributes.label.fieldName] : '';
    }

    @api
    get nameLink(){
        return this.item.hasOwnProperty('linkName') ? this.item['linkName'] : '';
    }

    @api
    get isName(){
        return this.key.fieldName === 'linkName';
    }
}