import { LightningElement, track, wire, api } from 'lwc';
import { refreshApex } from "@salesforce/apex";
import { notifyRecordUpdateAvailable } from "lightning/uiRecordApi";

import getActionPlanSummary from '@salesforce/apex/ActionPlanEnquirySummaryController.getActionPlanSummary';


const COLUMNS = [
    { label: 'Enquiry Number', fieldName: 'recordIdURL',  type: 'url', hideDefaultActions: true, cellAttributes: { iconName: { fieldName: 'iconParentChild' }}, typeAttributes: {label: { fieldName: 'caseNumber' }, target: '_self'}, sortable: true, initialWidth: 140 },
    { label: 'Organisation', fieldName: 'accountName', type: 'text', hideDefaultActions: true, sortable: true},
    { label: 'Referral Group', fieldName: 'referralGroup', type: 'text', hideDefaultActions: true, sortable: true },
    { label: 'Action Plan Name', fieldName: 'actionPlanIdURL',  type: 'url', hideDefaultActions: true, typeAttributes: {label: { fieldName: 'actionPlanName' }, target: '_self'}, sortable: true },
    { label: 'Action Plan Status', fieldName: 'actionPlanStatus', type: 'text', hideDefaultActions: true, sortable: true },
    { label: 'Pending Tasks', fieldName: 'pendingTasks', type: 'text', hideDefaultActions: true, sortable: true,  initialWidth: 110},
    { label: 'Total Tasks', fieldName: 'totalTasks', type: 'text', hideDefaultActions: true, sortable: true, initialWidth: 90 },
    { label: 'Tasks Completed (%)', fieldName: 'completedPercentage', type: 'customTypeProgressBar', hideDefaultActions: true, sortable: true },
];

export default class MroActionPlanSummaryView extends LightningElement {

    @api recordId;
    @track data;
    @track columns = COLUMNS;
    @track sortBy;
    @track sortDirection;
    wiredData;
    /** Pagination */
    page = 1; //initialize 1st page
    items = []; //contains all the records.
    //columns; //holds column info.
    startingRecord = 1; //start record position per page
    endingRecord = 0; //end record position per page
    pageSize = 10; //default value we are assigning
    totalRecountCount = 0; //total record count received from all retrieved records
    totalPage = 0; //total number of page is needed to display all records
    /** Pagination */

    @wire(getActionPlanSummary,{idEnquiryId: '$recordId'})
    actionPlanSummary(value) {
        const { data, error } = value;
        this.wiredData = value;

        if (data) {
           // this.data = data;
           // this.error = undefined;

            this.items = data;
            this.totalRecountCount = data.length;
            this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize);
            //here we slice the data according page size
            this.data = this.items.slice(0,this.pageSize); 
            this.endingRecord = this.data.length;
            this.error = undefined;

        } else if (error) {
            this.error = result.error;
            this.data = undefined;
            //this.showToast(this.error, 'Error', 'Error'); //show toast for error
        }
    }
    
    /** Sorting */

    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.data));
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
        this.data = parseData;
    } 

    /** Refresh Grid */

    async refreshSummary(){
         // Refresh LDS cache and wires
         notifyRecordUpdateAvailable([{recordId: this.recordId}]);

         // Display fresh data in the datatable
         await refreshApex(this.wiredData);
    }

    /** Pagination */

    // previous button 
    previousHandler() {
        if (this.page > 1) {
            this.page = this.page - 1;
            this.displayRecordPerPage(this.page);
        }
    }
 
    //press on next button this method will be called
    nextHandler() {
        if((this.page < this.totalPage) && this.page !== this.totalPage){
            this.page = this.page + 1;
            this.displayRecordPerPage(this.page);            
        }             
    }
 
    //this method displays records page by page
    displayRecordPerPage(page){
         
        this.startingRecord = ((page -1) * this.pageSize) ;
        this.endingRecord = (this.pageSize * page);
 
        this.endingRecord = (this.endingRecord > this.totalRecountCount) 
                            ? this.totalRecountCount : this.endingRecord; 
                            
        this.data = this.items.slice(this.startingRecord, this.endingRecord);
 
        //increment by 1 to display the startingRecord count, 
        //so for 2nd page, it will show "Displaying 6 to 10 of 23 records. Page 2 of 5"
        this.startingRecord = this.startingRecord + 1;
    }    
 
    showToast(message, variant, title) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    /** Pagination */
}