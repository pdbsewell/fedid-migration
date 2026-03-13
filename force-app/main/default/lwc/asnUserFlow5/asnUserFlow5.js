import { LightningElement, api, track, wire} from 'lwc';
import ansUserFlowP from '@salesforce/label/c.ASN_UserFLow5Para';

export default class asnUserFlow5 extends LightningElement {
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