import { LightningElement, api } from 'lwc';
import confirmsec1 from '@salesforce/label/c.ASN_ConfirmMSGSec1';
import confirmsec2 from '@salesforce/label/c.ASN_ConfirmMSGSec2';

export default class AsnConfirmSection extends LightningElement {
	@api teachingPeriod = '';
	@api unitAttemptList;
	label = {
        confirmsec1,
        confirmsec2
	};
	get teachingPeriodText(){
		return this.label.confirmsec1+' '+this.teachingPeriod;
	}
}