import { LightningElement, api, track, wire} from 'lwc';
import ansUserFlowP from '@salesforce/label/c.ASN_UserFlow2Para';

export default class AsnUserFlow2 extends LightningElement {
    @track _teachingPeriod;

    @api
    set teachingPeriod(value) {
        if (value) {
            this._teachingPeriod = value;
        }
    }

    get teachingPeriod() {
        return this._teachingPeriod;
    }
    label = {
        ansUserFlowP
    }

}