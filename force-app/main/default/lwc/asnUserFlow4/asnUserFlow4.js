import { LightningElement, api, track, wire} from 'lwc';
import ansUserFlowP from '@salesforce/label/c.ASN_UserFlow4Para';

export default class asnUserFlowThree extends LightningElement {
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