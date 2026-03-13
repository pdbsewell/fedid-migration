import { LightningElement, wire, track } from 'lwc';
import * as util from 'c/util'
import userId from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Offer_signing_complete from '@salesforce/label/c.Offer_signing_complete';
import Offer_session_timeout from '@salesforce/label/c.Offer_session_timeout';
import Offer_error_code from '@salesforce/label/c.Offer_error_code';
import Offer_signing_complete_under18 from '@salesforce/label/c.Offer_signing_complete_under18';

export default class OfferBannerCmp extends LightningElement {
    message = '';
    contactId = '';
    isUnder18 = false;
    Id = userId;

    @wire(getRecord, {recordId: '$Id', fields: ['User.ContactId']})
    wiredUser({error, data}){
        if(data){
            this.contactId = data.fields.ContactId.value;
        }else if(error){
            console.log(error);
        }
    }

    @wire(getRecord, { recordId: '$contactId', fields:  'Contact.Under_18__c'})
    wiredContact({error, data}){
        if(data){
            this.isUnder18 = data.fields.Under_18__c.value;
            let urlParam = util.urlParameter(window.location.href);
            let event = urlParam.get('event');
            let message = '';
            let type = '';
            if(event === 'signing_complete' && this.isUnder18){
                message = Offer_signing_complete_under18;
                type = 'Success';
            }else if(event === 'signing_complete'){
                message = Offer_signing_complete;
                type = 'Success';
            }else if(event === 'session_timeout' || event === 'ttl_expired'){
                message = Offer_session_timeout;
                type = 'Error';
            }else if(event === 'access_code_failed' || event === 'exception' || event === 'id_check_failed'){
                message = Offer_error_code;
                type = 'Error';
            }

            this.showToast(type, message, type);
        }else if(error){
            console.log(error);
        }
    }

    showToast(title, message, type){
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message, 
                variant: type,
                mode: 'sticky'
            }),
        ); 
    }
}