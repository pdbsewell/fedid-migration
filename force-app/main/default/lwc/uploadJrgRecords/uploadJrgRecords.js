/**
 * @description        : SA-1286 JRG - Data Upload Component
 * @author             : tom.gangemi@monash.edu
 * @group              : Student Admin
 */

import {LightningElement, api, track, wire} from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import submitCreationRequest from '@salesforce/apex/JrgCaseCreator.submitCreationRequest';
import getDefaultCsvMappingJSON from '@salesforce/apex/JrgCaseCreator.getDefaultCsvMappingJSON';

import PARSER from '@salesforce/resourceUrl/PapaParse';

import FIELD_CALENDAR from '@salesforce/schema/Case.Calendar__c';
import FIELD_COURSE_ATTEMPT from '@salesforce/schema/Case.Course_Attempt__c';
import FIELD_CONTACT_ID from '@salesforce/schema/Case.ContactId';
import FIELD_RISK_CATEGORY from '@salesforce/schema/Case.Risk_Category__c';
import FIELD_PRIORITY from '@salesforce/schema/Case.Priority';
import FIELD_SUPPLIED_STATE from '@salesforce/schema/Case.Supplied_State__c';
import FIELD_UNIT_CODE from '@salesforce/schema/Case.Unit_Code__c';

export default class UploadJrgRecords extends LightningElement {
    parserInitialized = false;
    loading = true;
    noRows = true;
    confirmationModalVisible = false;

    csvColumnOptions = [];
    csvRows = false;
    recordsToInsert = [];
    duplicateCount = 0;

    @api recordId;

    // SF field -> DAO object property
    daoMapping = {
        [FIELD_CALENDAR.fieldApiName]: 'calendarCode',
        [FIELD_COURSE_ATTEMPT.fieldApiName]: 'courseAttemptCallistaId',
        [FIELD_CONTACT_ID.fieldApiName]: 'personId',
        [FIELD_RISK_CATEGORY.fieldApiName]: 'outreachCategory',
        [FIELD_PRIORITY.fieldApiName]: 'outreachPriority',
        [FIELD_SUPPLIED_STATE.fieldApiName]: 'suppliedState',
        [FIELD_UNIT_CODE.fieldApiName]: 'unitCode'
    };

    // CSV Mapping: SF field -> CSV column
    mapping = {};

    // UI Label -> SF field (config for lightning-datatable)
    fieldLabels = [
        {label: 'Calendar Code', fieldName: FIELD_CALENDAR.fieldApiName},
        {label: 'Callista External Id', fieldName: FIELD_COURSE_ATTEMPT.fieldApiName},
        {label: 'Person ID', fieldName: FIELD_CONTACT_ID.fieldApiName, initialWidth: 104},
        {label: 'Outreach Category', fieldName: FIELD_RISK_CATEGORY.fieldApiName},
        {label: 'Outreach Priority', fieldName: FIELD_PRIORITY.fieldApiName},
        {label: 'Student Category', fieldName: FIELD_SUPPLIED_STATE.fieldApiName},
        {label: 'Unit Code', fieldName: FIELD_UNIT_CODE.fieldApiName}
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
        const promises = [];
        if(!this.parserInitialized) {
            const loadParserPromise = loadScript(this, PARSER);
            promises.push(loadParserPromise);
            loadParserPromise
                .then(() => {
                    this.parserInitialized = true;
                })
                .catch(error => {
                    this.showNotification('Error', 'Failed to load CSV parser', 'error');
                    console.error(error);
                });
        }

        const getMappingPromise = getDefaultCsvMappingJSON();
        promises.push(getMappingPromise);
        getMappingPromise
            .then(result => {
                if (result) {
                    this.mapping = JSON.parse(result);
                } else {
                    console.warn('Default CSV mapping is blank');
                }
            }).catch(error => {
                console.warn('Error retrieving default CSV mapping', error);
                this.showNotification('Warning', 'Unable to retrieve default CSV mapping', 'warning');
            });

        // clear loading once mappings and parser are loaded
        Promise.allSettled(promises).then(() => {this.loading = false});
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
            row[FIELD_CONTACT_ID.fieldApiName],
            row[FIELD_COURSE_ATTEMPT.fieldApiName],
            row[FIELD_CALENDAR.fieldApiName]
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

            submitCreationRequest({requests: inserts, campaignId : this.recordId})
                .then(result => {
                    if(result.success) {
                        this.showNotification(
                            this.recordsToInsert.length + ' Records Successfully Submitted',
                            'Once the records are process you will receive an email with the results.',
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