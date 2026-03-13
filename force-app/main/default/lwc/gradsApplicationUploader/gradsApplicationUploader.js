/**
 * Grads Bulk Application Uploader
 *  - UI Component to upload a CSV of Graduation Applications
 *  - Supports both creating new applications and updating existing ones
 *
 * @revision 2024-08-20 - Tom Gangemi - Initial version
 * @revision 2025-04-02 - Added update functionality
 *
 * TODO:
 *  - Add help screen
 *  - Show list of recent results
 */
import {LightningElement, wire} from 'lwc';
import PARSER from '@salesforce/resourceUrl/PapaParse';
import {loadScript} from 'lightning/platformResourceLoader';
import Toast from 'lightning/toast';
import { EnclosingTabId, setTabLabel, setTabIcon } from 'lightning/platformWorkspaceApi';
import uploadApplications from '@salesforce/apex/GradsApplicationUploaderBatch.uploadApplications';
import hasAccess from '@salesforce/customPermission/Graduations_Application_Uploader';

export default class GradsApplicationUploader extends LightningElement {

    loading = true;
    parserInitialized = false;

    inputColumns = []; // for previewing the input data
    inputHeaders = []; // for passing to uploadApplications
    inputRows = [];

    errorColumns = [];
    errorRows = [];
    errorMessage = null;

    doneMessage = null;
    operationType = null; // 'create' or 'update'

    // Options for the operation radio group
    operationOptions = [
        { label: 'Create New Applications', value: 'create' },
        { label: 'Update Existing Applications', value: 'update' }
    ];

    @wire(EnclosingTabId) tabId;

    get isAccessible() {
        return hasAccess;
    }

    get operationMode() {
        return this.operationType === 'update' ? 'Update' : 'Create';
    }

    get selectedOperation() {
        return this.operationType !== null;
    }

    get operationInstructions() {
        if (this.operationType === 'create') {
            return 'Upload a CSV with data for new graduation applications.';
        } else if (this.operationType === 'update') {
            return 'Upload a CSV that includes the CallistaTransactionNumber column to identify existing awards.';
        }
        return '';
    }

    connectedCallback() {

        if(this.tabId) {
            setTabLabel(this.tabId, 'Grads CSV Upload');
            setTabIcon(this.tabId, 'utility:upload', {iconAlt:'Grads CSV Upload'});
        }

        const promises = [];

        if(!this.parserInitialized) {
            const loadParserPromise = loadScript(this, PARSER);
            promises.push(loadParserPromise);
            loadParserPromise
                .then(() => {
                    this.parserInitialized = true;
                })
                .catch(error => {
                    Toast.show({label: 'Failed to load CSV parser', variant: 'error', mode:'dismissible'}, this);
                    console.error(error);
                });
        }

        Promise.allSettled(promises).then(() => {
            this.loading = false;
        });

    }

    /**
     * Handle operation type selection
     */
    handleOperationChange(event) {
        this.operationType = event.detail.value;
        // Reset data when changing operation type
        this.inputRows = [];
        this.errorMessage = null;
        this.errorRows = [];
        this.doneMessage = null;
    }

    /**
     * Upon selecting a file, parse the CSV and display the results in the inputRows
     */
    fileSelected(event) {
        if((!event.target.files.length > 0) || !this.operationType)
            return;

        const file = event.target.files[0];
        this.loading = true;
        this.errorMessage = null;
        this.errorRows = [];
        this.errorColumns = [];
        this.inputRows = [];
        this.doneMessage = null;

        Papa.parse(file, {
            quoteChar: '"',
            header: true,
            skipEmptyLines: true,
            complete: (results) => {
                let ok = true;
                this.loading = false;

                if(results.data.length > 5000) {
                    Toast.show({
                        label: 'CSV must contain less than 5000 rows.',
                        variant: 'warning',
                        mode: 'dismissible'
                    }, this);
                    return;
                }

                if(results.errors.length > 0) {
                    this.errorColumns = [
                        {label: 'Input Row', fieldName: 'row'},
                        {label: 'Error', fieldName: 'error'}
                    ];
                    this.errorRows = results.errors.map((e, i) => {
                        return {row: e.row, error: e.message};
                    });
                    this.errorMessage = 'Errors occurred while parsing the CSV. Please correct the errors and try again.';
                    console.error(results.errors);
                    return;
                }

                // show the csv data in inputRows and inputColumns for display in lightning-datatable
                this.inputColumns = Object.keys(results.data[0]).map((f) => {
                    return {label: f, fieldName: f}
                });
                this.inputRows = results.data;
                console.log(this.inputRows);
                this.inputHeaders = results.meta.fields;
            },
            error: (error) => {
                Toast.show({label: 'Failed to parse CSV', variant: 'error', mode: 'dismissible'}, this);
                console.error(error);
                this.loading = false;
            }
        })

    }

    /**
     * Create/Update Applications from the inputRows
     */
    createApplications() {
        if (!this.operationType || this.inputRows.length === 0) {
            Toast.show({
                label: 'Please select an operation type and upload a CSV file.',
                variant: 'warning',
                mode: 'dismissible'
            }, this);
            return;
        }

        this.loading = true;
        uploadApplications({
            header: this.inputHeaders,
            data: this.inputRows,
            isUpdate: this.operationType === 'update'
        })
        .then(result => {
            this.inputRows = [];
            if(result.length > 0) {
                // show errors in error table
                console.error(result);
                this.errorColumns = [
                    {label: 'Input Row', fieldName: 'row'},
                    {label: 'Error', fieldName: 'error'}
                ];
                this.errorRows = result.map((e) => {
                    return {row: e.inputRow, error: e.message};
                });
                this.errorMessage = 'Errors occurred while processing the CSV. Please correct the errors and try again.';
            } else {
                const operation = this.operationType === 'update' ? 'updating' : 'creating';
                this.doneMessage = `The Applications are now ${operation} - Once complete you will receive an email with the results.`;
            }
        }).catch(error => {
            Toast.show({label: 'Unable to process CSV - Server Error', variant: 'error', mode: 'dismissible'}, this);
            console.error(error);
        }).finally(() => {
            this.loading = false;
        });
    }

    downloadErrorsCsv() {
        const csv = Papa.unparse(this.errorRows);

        const a = document.createElement('a');
        a.href = URL.createObjectURL(new Blob([csv]), { type: 'text/plain' });
        a.download = 'grad-upload-errors.csv';

        const tableContainer = this.template.querySelector('.table-container');
        tableContainer.appendChild(a);
        a.click();
        tableContainer.removeChild(a);
    }

    // cap table heights
    get inputTableStyle() {
        return this.inputRows.length > 10 ? 'height: 500px;' : '';
    }
    get errorTableStyle() {
        return this.errorRows.length > 10 ? 'height: 500px;' : '';
    }
}