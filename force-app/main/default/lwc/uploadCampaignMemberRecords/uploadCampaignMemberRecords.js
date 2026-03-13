/**
 * @description        : MCT-388 - Data Upload Component
 * @author             : indrpal.dhanoa@monash.edu
 * @group              : Student Admin
 */

import {LightningElement, track, wire, api} from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import submitCreationRequest from '@salesforce/apex/CampaignMemberCreator.submitCreationRequest';
import retrieveSampleFile from '@salesforce/apex/CampaignMemberCreator.retrieveSampleFile';

import PARSER from '@salesforce/resourceUrl/PapaParse';

import OBJ_CAMP_MEMBER from '@salesforce/schema/CampaignMember';
import OBJ_OUTB_CALL_RESULT from '@salesforce/schema/Outbound_Call_Result__c';
import FIELD_ENGAGEMENT_TYPE from '@salesforce/schema/Outbound_Call_Result__c.Engagement_Type__c'; 
import FIELD_COURSE_ATTEMPT from '@salesforce/schema/Outbound_Call_Result__c.Course_Attempt__c';
import FIELD_PERSON_ID from '@salesforce/schema/Outbound_Call_Result__c.Contact__c';

export default class UploadCampaignMemberRecords extends LightningElement {
    parserInitialized = false;
    loading = true;
    noRows = true;
    confirmationModalVisible = false;

    @api campaignId;
    sampleFileContentDocumentId;

    csvColumnOptions = [];
    csvRows = false;
    recordsToInsert = [];
    renderSection = false;
    duplicateCount = 0;

    @track defaultRecordTypeId;
    engageTypePicklistSelectedValue;

    @wire(getObjectInfo, { objectApiName: OBJ_OUTB_CALL_RESULT })
    handleObjectInfoResult({error, data}) {
        if(data) {
            this.defaultRecordTypeId = data.defaultRecordTypeId;
        } else {
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: FIELD_ENGAGEMENT_TYPE })
    pickValues({ error, data }) {
        if (data) {
            this.engageTypePicklistOptions = data.values.map(plValue => {
                return {
                    label: plValue.label,
                    value: plValue.value
                };
            });
            this.renderSection = true;
        } else if (error) {
            console.log(error);
        }
    }

    // Mapping of SF field to DAO object properties
    daoMapping = {
        [FIELD_COURSE_ATTEMPT.fieldApiName]: 'courseAttemptCallistaId',
        [FIELD_PERSON_ID.fieldApiName]: 'personId'
    };

    // Default mapping of SF field to CSV column
    defaultCsvMapping = {
        [FIELD_COURSE_ATTEMPT.fieldApiName]: 'Callista_External_Id__c',
        [FIELD_PERSON_ID.fieldApiName]: 'Person ID'
    };

    mapping = { ...this.defaultCsvMapping };

    // Field labels mapped to SF field
    fieldLabels = [
        {label: 'Course Attempt', fieldName: FIELD_COURSE_ATTEMPT.fieldApiName},
        {label: 'Person ID', fieldName: FIELD_PERSON_ID.fieldApiName}
    ];

    errors = [];
    errorMessage = false;
    errorColumns = [
        {label: 'Message', fieldName: 'message'},
        {label: 'Reference', fieldName: 'reference'}
    ];

    // Create select options for mapping combo boxes
    get mappingOptions() {
        return this.fieldLabels.map((row, index) => {
            row.key = index;
            row.selected = null;
            // if this field is currently mapped to a CSV column that is present, show it as selected in the combobox
            if(this.csvColumnOptions.some(col => col.value == this.mapping[row.fieldName]))
                row.selected = this.mapping[row.fieldName];
            return row;
        })
    }

    connectedCallback() {
        if(!this.parserInitialized) {
            loadScript(this, PARSER)
                .then(() => {
                    this.parserInitialized = true;
                    this.loading = false;
                })
                .catch(error => console.error(error));
        }

        // Retrieve sample file link
        retrieveSampleFile({})
            .then(result => {
                this.sampleFileContentDocumentId = result;
            })
            .catch(error => {})
            .finally(() => {
                this.loading = false;
            });
    }

    fileSelected(event) {
        if(event.target.files.length > 0) {
            const file = event.target.files[0];
            this.loading = true;
            Papa.parse(file, {
                quoteChar: '"',
                header: 'true',
                skipEmptyLines: true,
                complete: (results) => {
                    if(results.data.length > 10000) {
                        this.showNotification('Error', 'CSV must contain less than 10000 rows.', 'warning');
                    } else {
                        this.csvRows = results.data;
                        this.csvColumnOptions = results.meta.fields.map((f) => {return {label:f, value:f}});
                        this.updateRecordsToInsert();
                        this.clearErrors();
                    }
                    this.loading = false;
                },
                error: (error) => {
                    console.error(error);
                    this.loading = false;
                }
            })
        }
    }

    mappingChange(event) {
        this.mapping[event.target.name] = event.detail.value;
        console.log(this.mapping);
        this.updateRecordsToInsert();
    }

    createExternalId(row) {
        return [
            row[FIELD_PERSON_ID.fieldApiName],
            row[FIELD_COURSE_ATTEMPT.fieldApiName]
        ].join('-');
    }

    updateRecordsToInsert() {
        if(this.csvRows) {
            // Copy CSV data into array of objects with keys according to current mapping
            this.recordsToInsert = this.csvRows.map((row, index) => {
                const newRow = {};
                for (const [sfField, csvColumn] of Object.entries(this.mapping)) {
                    newRow[sfField] = row[csvColumn];
                }
                newRow.id = this.createExternalId(newRow);
                newRow.key = index;
                return newRow;
            });
            // Remove duplicates - based on id
            this.recordsToInsert = this.recordsToInsert.filter((v,i,a)=>a.findIndex(t=>(t.id===v.id))===i);
            this.duplicateCount = this.csvRows.length - this.recordsToInsert.length;
        } else {
            this.recordsToInsert = [];
        }
        this.noRows = !this.recordsToInsert.length > 0;
    }

    insertRecords() {
        // validation
        if(!this.engageTypePicklistSelectedValue){
            this.showNotification('Error', 'Engage Type value Incomplete', 'error');
            return;
        }

        this.closeModal();
        const mappingInput = this.template.querySelector('.mapping-input');

        const missingMapping = this.mappingOptions.some((elem) => !elem.selected);

        if(missingMapping) {
            // has errors
            this.showNotification('Error', 'Field Mapping Incomplete', 'warning');
        } else {
            // proceed with insert
            this.loading = true;
            this.clearErrors();

            // Map to DAO object
            const inserts = this.recordsToInsert.map((row, index) => {
                const newRow = {};
                for (const [sfField, daoProp] of Object.entries(this.daoMapping)) {
                    newRow[daoProp] = row[sfField];
                }
                newRow['inputCsvRow'] = row.key;
                return newRow;
            });
            submitCreationRequest({requests: inserts, engageTypeRequest: this.engageTypePicklistSelectedValue, campaignId : this.campaignId})
                .then(result => {
                    if(result.success) {
                        this.showNotification(
                            this.recordsToInsert.length + ' Records Successfully Submitted',
                            'Once the records are processed, you will receive an email with the results.',
                            'success');
                        this.close();
                    } else {
                        this.showNotification('Error','Failed To Upload Records','error');
                        console.log(result);
                        this.errors = result.errors.map((err, index) => {
                            err.key = index;
                            return err;
                        });
                    }
                })
                .catch(error => {
                    console.log(error);
                    this.errorMessage = JSON.stringify(error, null, 2);
                    this.showNotification('Server Error','Failed To Upload Records','error');
                })
                .finally(() => {
                    this.recordsToInsert = [];
                    this.csvColumnOptions = [];
                    this.loading = false;
                });
        }
    }

    setEngageTypePicklistSelectedValue(event){
        this.engageTypePicklistSelectedValue = event.target.value;
    }

    downloadSampleFile() {
        window.open('/sfc/servlet.shepherd/document/download/' + this.sampleFileContentDocumentId);
    }

    downloadErrorsCsv() {
        var csv = Papa.unparse(this.errors);

        const a = document.createElement('a');
        a.href = URL.createObjectURL(new Blob([csv]), { type: 'text/plain' });
        a.download = 'jrg-errors.csv';

        const tableContainer = this.template.querySelector('.table-container');
        tableContainer.appendChild(a);
        a.click();
        tableContainer.removeChild(a);
    }

    clearErrors() {
        this.errorMessage = false;
        this.errors = [];
    }

    showNotification(title, message, variant) {
        let mode = 'dismissible';
        if(variant == 'success')
            mode = 'sticky';
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }

    close() {
        this.csvRows = false;
        this.dispatchEvent(new CloseActionScreenEvent());
        this.dispatchEvent(new CustomEvent('close'))
    }

    closeModal() {
        this.confirmationModalVisible = false;
    }

    openModal() {
        this.confirmationModalVisible = true;
    }

    // View State Helpers
    getTableHeight(rowCount) {
        return rowCount > 4 ? 'height: 160px;' : '';
    }

    get datatableHeight() {
        return this.getTableHeight(this.recordsToInsert.length);
    }

    get errorsTableHeight() {
        return this.getTableHeight(this.errors.length);
    }

}