import { LightningElement, wire, track, api } from 'lwc';
import { getListUi } from 'lightning/uiListApi';
import { getListInfoByName } from 'lightning/uiListsApi';
import { refreshApex } from '@salesforce/apex';

import CASE_OBJECT from '@salesforce/schema/Case';
import NAME_FIELD from '@salesforce/schema/Contact.Name';

export default class LightningListView extends LightningElement {
    @track columns = [];
    @track records = [];
    @track error;

    @api listViewName = '';
    pageToken = null;
    nextPageToken = null;
    previousPageToken = null;

    title = '';
    loading = true;
    wiredData;

    defaultSortDirection = 'desc';
    sortDirection = 'desc';
    sortBy;

    doSorting(event) {
        console.log('doSorting', event.detail.fieldName, event.detail.sortDirection);
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.records));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1: -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.records = parseData;
    }

    handleNextPage(e) {
        this.pageToken = this.nextPageToken;
    }

    handlePreviousPage(e) {
        this.pageToken = this.previousPageToken;
    }

    @api
    refresh() {
        if(this.wiredData) {
            this.loading = true;
            refreshApex(this.wiredData).finally(() => {
                this.loading = false;
            });
        }
    }

    // Get List View Data by List View ID
    @wire(getListUi, {
        objectApiName: 'Case',
        listViewApiName: '$listViewName',
        pageSize: 100,
        pageToken: '$pageToken',
    })
    wiredListView(wireResult) {
        const { data, error } = wireResult;
        this.wiredData = wireResult;
        console.log('Wire Result');
        console.log(JSON.parse(JSON.stringify(wireResult)));
        if (data) {
            if(!data.records) {
                return;
            }

            // Storing list view data
            console.log(JSON.parse(JSON.stringify(data)));
//            console.log(JSON.parse(JSON.stringify(data.records.records)));
            this.error = undefined;
            this.title = data.info.label;

            this.nextPageToken = data.records.nextPageToken;
            this.previousPageToken = data.records.previousPageToken;

            const columns = data.info.displayColumns.map(col => {
                const fname = col.fieldApiName.split('.')[0]; // only keep the name of the related object
                return {
                    label: col.label,
                    fieldName: fname,
                    type: col.lookupId != null ? 'url' : 'richText',
                    typeAttributes: col.lookupId != null ? { label: { fieldName: fname+'Label' } } : undefined,
                    lookupId: col.lookupId,
                    sortable: true,
                    wrapText: true
                };
            });
            const columnsByFieldName = columns.reduce((acc, item) => {
                acc[item.fieldName] = item;
                return acc;
            }, {});

//            console.log('columns', columns);
//            console.log('columns', columnsByFieldName);
            this.columns = columns;

            const records = data.records.records.map(record => {
                let rowData = {};
//                console.log('--------');
//                console.log('record', record);
                Object.keys(record.fields).forEach(field => {
                    const fieldData = record.fields[field];
//                    console.log(field, fieldData);
                    if(field in columnsByFieldName) {
                        const column = columnsByFieldName[field];
                        if(column.lookupId != null) {
                            if(column.lookupId == 'Id' && fieldData.value) {
                                // record link
                                rowData[field] = `/lightning/r/Case/${record.id}/view`;
                                rowData[field+'Label'] = fieldData.value;
                            } else if(fieldData.value) {
                                // related link
                                rowData[field] = `/lightning/r/${fieldData.value.apiName}/${fieldData.value.id}/view`;
                                rowData[field+'Label'] = fieldData.displayValue;
                            }
                        } else {
                            rowData[field] = fieldData.displayValue ? fieldData.displayValue : fieldData.value;
                        }
                    }
                })
                return rowData;
            })
            this.records = records;
            this.loading = false;
        } else if (error) {
            this.error = 'Error loading list view - ' + error.body.message;
            console.log('Record Error', error);
            this.loading = false;
        }
    }
}