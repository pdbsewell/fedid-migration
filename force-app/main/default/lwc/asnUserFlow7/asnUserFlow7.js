/**
 * Created by rcad0001 on 3/10/2021.
 */

import { LightningElement, api, track, wire} from 'lwc';
import ansUserFlowP from '@salesforce/label/c.ASN_UserFLow7Para';

export default class AsnUserFlow7 extends LightningElement {
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