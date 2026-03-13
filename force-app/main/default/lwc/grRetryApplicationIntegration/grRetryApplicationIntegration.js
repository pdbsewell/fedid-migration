import { LightningElement, api, wire } from 'lwc';
import retryApplicationIntegration from '@salesforce/apex/GrRetryApplicationIntegrationController.retryApplicationIntegration';
import { getRecord } from 'lightning/uiRecordApi';

// FIELD for Applicant__c
import APPLICANT_FIELD from '@salesforce/schema/Application_Course_Preference__c.Applicant__c';
// FIELD for Application__c
import APPLICATION_FIELD from '@salesforce/schema/Application_Course_Preference__c.Application__c';

const FIELDS = [APPLICANT_FIELD, APPLICATION_FIELD];

/**
 * @description GrRetryApplicationIntegration to manually retry the GR application integration
 * @author      Vishal Gupta
 * @since       19.5.2025
 * @revision
 */
export default class GrRetryApplicationIntegration extends LightningElement {
    @api recordId;
    successMsg
    errorMsg
    showSpinner = true;
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.callApex();
        } else if (error) {
            this.errorMsg = 'Error: '+ error.body?.message;
        }
    }

    /**
     * @description retry Application Integration method
     */
    callApex() {
        this.successMsg = ''
        this.errorMsg = ''
        retryApplicationIntegration({ acpId: this.recordId })
            .then(result => {
                this.showSpinner = false;
                this.successMsg = 'The job has been triggered'
            })
            .catch(error => {
                this.errorMsg = 'Error: '+ error.body?.message;
                this.showSpinner = false;
            });
    }

}