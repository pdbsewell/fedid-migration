/**
 * Created by rcad0001 on 1/07/2020.
 */

import { LightningElement, api, track, wire} from 'lwc';
import ansUserFlowP from '@salesforce/label/c.ASN_UserFlow3P';

export default class AsnUserFlow3 extends LightningElement {
    @track _teachingPeriod;
    label = {
        ansUserFlowP
    }

    @api
    set teachingPeriod(value) {
        if (value) {
            this._teachingPeriod = value;
        }
    }

    get teachingPeriod() {
        return this._teachingPeriod;
    }
}