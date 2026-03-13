import { LightningElement, api, wire } from 'lwc';
import retryApplicationDocumentIntegration from '@salesforce/apex/GrRetryApplicationIntegrationController.retryApplicationDocumentIntegration';
import { getRecord } from 'lightning/uiRecordApi';

// FIELD for Applicant__c
import APPLICANT_FIELD from '@salesforce/schema/Application__c.Applicant__c';

const FIELDS = [APPLICANT_FIELD];

/**
 * @description grRetryDocumentIntegration to manually retry the GR document integration
 * @author      Vishal Gupta
 * @since       19.5.2025
 * @revision
 */
export default class grRetryDocumentIntegration extends LightningElement {
    @api recordId;
    successMsg
    errorMsg
    showSpinner = true;
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.callApex(); // Call Apex only once Applicant__c is available
        } else if (error) {
            this.errorMsg = 'Error '+ error.body?.message;
        }
    }

    /**
     * @description retry document Integration method
     */
    callApex() {
        this.successMsg = ''
        this.errorMsg = ''
        retryApplicationDocumentIntegration({ recordId: this.recordId })
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