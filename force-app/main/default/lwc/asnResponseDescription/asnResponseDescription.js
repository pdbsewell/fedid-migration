/**
 * Created by rcad0001 on 16/07/2020.
 */

import { LightningElement, api, track, wire} from 'lwc';
import asnResource from '@salesforce/resourceUrl/ASN';

export default class AsnResponseDescription extends LightningElement {
    @api title;
    @api desc;
    @api icon;
    @api renderIcon;

    sfrlogo = asnResource + '/ASN/redo-black-48dp.svg';
    wdnlogo = asnResource + '/ASN/call_missed_outgoing-black-48dp.svg';
    nclogo = asnResource + '/ASN/remove-black-48dp.svg';
    get iconName() {
        let iconTyp;
        if (this.icon === 'sfr') {
            iconTyp = this.sfrlogo;
        }
        if (this.icon === 'wdn') {
            iconTyp = this.wdnlogo;
        } 
        if (this.icon === 'nc') {
            iconTyp = this.nclogo;
        }
        return iconTyp;
    }

    get layoutSize(){
        let thisClass;
        let renderFlag = this.renderIcon;
        if(renderFlag == "true"){
            thisClass = "slds-card card-large-layout";
        }
        else {
            thisClass = "slds-card card-small-layout";
        }

        return thisClass;
    }


}