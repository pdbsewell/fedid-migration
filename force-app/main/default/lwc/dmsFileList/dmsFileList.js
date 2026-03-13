import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import getDocuments from '@salesforce/apexContinuation/DMSFileService.getDocuments';

const contactFields = ['Contact.Person_ID_unique__c'];

export default class DmsFileList extends LightningElement {
    //Get record id when opened on record page
    @api recordId;

    @track loaded = false;
    @track documentList;
    @track documentCount = 0;
    @track message;


    /* Constructor after the component is hooked on the parent component */
    connectedCallback() {}

    @wire(getDocuments, {contactId : '$recordId'})
    wiredDocuments(result) {
        this.loaded = false;
        if (result.data) {

            if (result.data.state == 'success') {
                this.documentList = result.data.docList;
                this.documentCount = result.data.docList.length;
                this.loaded = true;
            } else {
                if (result.data.statusCode == '404') {
                    this.message = 'No available records found';
                } else {
                    this.message = 'Something went wrong. Please contact your administrator.';
                }
                this.loaded = true;
            }
        } else if (result.error) {
            this.message = 'You do not have access to view the Historical offers or the server was inaccessible.';
            this.loaded = true;
        }
    }
}