/**
 * @File Name          : campaignUnsub.js
 * @Description        : Component that enables unsubscribe from Campaign
 * @Author             : Nick Guia
 * @Group              : Lead Management
**/
import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import CASE_CONTACT_FIELD from '@salesforce/schema/Case.ContactId';
import CASE_NAME_FIELD from '@salesforce/schema/Case.CaseNumber';

import unsubService from '@salesforce/apex/CampaignMemberServices.unsubscribeService';

export default class CampaignUnsub extends LightningElement {

    @api recordId;

    @track _contactId;
    @track isLoading = true;
    @track unsubReasonOptions = [
        {
            value: "I'm getting too many emails, SMS messages, or phone calls from Monash", 
            label: "I'm getting too many emails, SMS messages, or phone calls from Monash"
        },
        {
            value: "I didn't sign up to receive communications from Monash", 
            label: "I didn't sign up to receive communications from Monash"
        },
        {
            value: "I'm not interested in what Monash is sending me", 
            label: "I'm not interested in what Monash is sending me"
        },
        {
            value: "I can't view what Monash is sending me", 
            label: "I can't view what Monash is sending me"
        },
        {
            value: "The content wasn't relevant to me", 
            label: "The content wasn't relevant to me"
        },
        {
            value: "No reason", 
            label: "No reason"
        },
    ]
    @track isAllUnsub = false;
    @track isMieUnsub = false;
    @track isOpenDayUnsub = false;
    @track isMrUnsub = false;

    _wiredCase
    _campaignId;
    _unsubSource = 'Case :';
    _reason;

    @wire(getRecord, { recordId: '$recordId', fields: [CASE_CONTACT_FIELD, CASE_NAME_FIELD] })
    wiredCaseRecord(result) {
        this._wiredCase = result;
        if (result.data) {
            this._contactId = result.data.fields.ContactId.value;
            this._unsubSource = `${this._unsubSource} ${result.data.fields.CaseNumber.value}`;
            this.isLoading = false;
        } else if (result.error) {
            console.error(error.body.message);
        }
    }

    get isRenderUnsub() {
        let isShow = false;
        if (this._contactId) {
            isShow = true;
        }
        return isShow;
    }

    get isRenderMsg() {
        let isShow = true;
        if (this._contactId) {
            isShow = false;
        }
        return isShow;
    }

    get isUnsubDisabled() {
        return !(this.isMieUnsub || this.isOpenDayUnsub || this.isMrUnsub);
    }

    updateCampaignId(e) {
        this._campaignId = e.target.value;
    }

    updateUnsubReason(e) {
        this._reason = e.target.value;
    }

    updateAll(e) {
        this.isAllUnsub = e.target.checked;
        this.isMieUnsub = e.target.checked;
        this.isOpenDayUnsub = e.target.checked;
        this.isMrUnsub = e.target.checked;
    }

    handleMie(e) {
        this.isMieUnsub = e.target.checked;
        if(!this.isMieUnsub) {
            this.isAllUnsub = false;
        }
    }

    handleOpenDay(e) {
        this.isOpenDayUnsub = e.target.checked;
        if(!this.isOpenDayUnsub) {
            this.isAllUnsub = false;
        }
    }

    handleMr(e) {
        this.isMrUnsub = e.target.checked;
        if(!this.isMrUnsub) {
            this.isAllUnsub = false;
        }
    }

    handleUnsub() {
        this.isLoading = true;
        let payload = {
            contactId: this._contactId,
            isMieUnsub : this.isMieUnsub,
            isOpenDayUnsub : this.isOpenDayUnsub,
            isMrUnsub : this.isMrUnsub,
            source : this._unsubSource,
            reason : this._reason
        }

        unsubService(
            {
                payloadStr: JSON.stringify(payload)
            })
            .then(result => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Successfully Unsubscribed from Campaign',
                        variant: 'success',
                        mode: 'sticky'
                    }),
                );
                this.resetFields();
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'An Error occurred while trying to Unsubscribe from Campaign. Please contact your System Administrator.',
                        variant: 'error',
                    }),
                );
                console.error(error.body.message);
            })
            .finally(() => {
                //reset values
                this.isAllUnsub = false;
                this.isMieUnsub = false;
                this.isOpenDayUnsub = false;
                this.isMrUnsub = false;
                this.isLoading = false;
            });
    }

    resetFields() {
        const inputFields = this.template.querySelectorAll('lightning-input');
        inputFields.forEach(inp => {
            inp.checked = false;
        });

        const reasonFld = this.template.querySelector('lightning-combobox');
        if (reasonFld) {
            reasonFld.value = '';
        }
    }
}