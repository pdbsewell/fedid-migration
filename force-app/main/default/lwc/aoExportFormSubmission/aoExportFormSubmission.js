import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
//import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import YEAR_FIELD from '@salesforce/schema/AO_Program__c.AO_Program_Year__c';
import STATUS_FIELD from '@salesforce/schema/AO_Program_Applicant__c.AO_Application_Status__c';
import getPrograms from "@salesforce/apex/AOExportFormSubmissionController.getPrograms";
import getForms from "@salesforce/apex/AOExportFormSubmissionController.getAssociatedForms";
import searchSubmissions from "@salesforce/apex/AOExportFormSubmissionController.searchSubmissions";
import { exportCSVFile } from 'c/aoUtils';

export default class AoExportFormSubmission extends LightningElement {
    isLoading = false;
    columns;
    data=[];
    filteredData=[];
    @api recordId;
    @track programOptions=[];
    formOptions=[];
    value;
    selectedProgramId;
    selectedFormId;
    fromDateValue;
    toDateValue;
    customDT ={};
    //showExport = true;
    searchKeyword;
    //Sorting Params
    sortField;
    sortDirection = 'asc';
    hasError = false;
    //Pagination Params
    totalRecords =0;
    pageSize;
    totalPages;
    pageNumber=1;
    pageSizeOptions = [5,10,25,50,75,100];
    recordsToDisplay=[];
    displayError = false;
    yearValues=[];
    selectedYear;
    status;
    statusOptions=[];
    enableStatus=true;
    selectedFormName; 

    @wire(getPicklistValues, {recordTypeId:'012000000000000AAA',  fieldApiName: YEAR_FIELD })
    wiredYear({error, data}){
        if(data){
            let tempYearOptions=[];
            data.values.forEach(element=>{
                tempYearOptions.push({value:element.value, label:element.value});
            });
            this.yearValues = tempYearOptions;
        }
        else if(error){
            console.log('Error--->'+ JSON.stringify(error));
        }
    }
    @wire(getPicklistValues, {recordTypeId:'012000000000000AAA',  fieldApiName: STATUS_FIELD })
    wiredYear({error, data}){
        if(data){
            let tempOptions=[{value : '-None-', label:'-None-'}];
            data.values.forEach(element=>{
                tempOptions.push({value:element.value, label:element.value});
            });
            this.statusOptions = tempOptions;
        }
        else if(error){
            console.log('Error--->'+ JSON.stringify(error));
        }
    }
    connectedCallback(){
        this.yearValues.push({value:"2024", label:"2024"});
        this.yearValues.push({value:"2025", label:"2025"});
        this.yearValues.push({value:"2026", label:"2026"});
        this.yearValues.push({value:"2027", label:"2027"});
        this.yearValues.push({value:"2028", label:"2028"});
        this.yearValues.push({value:"2029", label:"2029"});
        this.yearValues.push({value:"2030", label:"2030"});
        this.yearValues.push({value:"2031", label:"2031"});
        this.yearValues.push({value:"2032", label:"2032"});
        this.yearValues.push({value:"2033", label:"2033"});
        this.yearValues.push({value:"2034", label:"2034"});
    }
    
    handleYearChange(event){
        console.log('====='+JSON.stringify(event));
        this.valChanged=false;
        this.isLoading =true;
        this.selectedYear = event.target.value;
        this.selectedProgramId = undefined;
        this.formOptions =[];
        this.programOptions =[];
        this.selectedFormId = undefined;
        let options =[];
        console.log('no--->'+ this.selectedFormId + '-->'+ this.selectedProgramId);
        getPrograms({year:this.selectedYear})
        .then(result=>{ 
            let tempoptions=[];
            result.forEach(element=>{
                tempoptions.push({value:element.Id, label:element.Name});
            });
            this.programOptions = tempoptions;
            this.isLoading =false;
        })
        .catch(error=>{
            this.isLoading =false;
        })
        .finally(() => {
            this.refs.programPL.setOptionsAndValues();
            this.refs.formPL.setOptionsAndValues();
            this.refs.statusPL.setOptionsAndValues();
            //this.template.querySelector("c-aosearchablepicklist").setOptionsAndValues();lwc:ref="yearPL"
            /*this.template.querySelectorAll('c-aosearchablepicklist').forEach(inputElem => {
                console.log('--->'+ inputElem + JSON.stringify(inputElem));
                inputElem.setOptionsAndValues();
            });*/
        });
    }
    handleOnChange(event){
        this.isLoading =true;
        this.selectedProgramId = event.target.value;
        this.formOptions =[];
        this.selectedFormId = undefined;
        let options =[];
        getForms({programId : this.selectedProgramId})
        .then(result=>{
            result.forEach(element=>{
                if(element.AO_Form__r){
                    let formDis = element.AO_Form__r;
                    options.push({value:element.AO_Form__c,label:formDis.AO_Form_Display_Name__c} );
                }
            });
            this.formOptions= options;
            this.isLoading = false;
        })
        .catch(error=>{
            this.isLoading =false;
        })
        .finally(() => {
            this.refs.formPL.setOptionsAndValues();
            this.refs.statusPL.setOptionsAndValues();
        });
    }
    handleOnFormChange(event){
        this.selectedFormId = event.target.value;
        this.enableStatus = false;
        this.refs.statusPL.setOptionsAndValues();
        this.selectedFormName = event.target.options.find(opt => opt.value === event.detail.value).label;
        
    }
    handleDateChange(event){
        let fieldName = event.target.name;
        let fieldValue = event.target.value;
        if(fieldName=== 'fromDateInput'){
            this.fromDateValue = fieldValue;
        }
        else if(fieldName=== 'toDateInput'){
            this.toDateValue = fieldValue;
        }
        
    }
    handleStatusChange(event){
        this.status = event.target.value !== '-None-' ? event.target.value : '';
    }
    handleExportClick(){
        //this.showExport = false;
    }
    handleSearchClick(event){
        if(!this.validateInput()){
            this.isLoading =true;
            var searchTerm = {
                programId : this.selectedProgramId,
                formId : this.selectedFormId,
                fromDate : this.fromDateValue,
                toDate : this.toDateValue,
                year :  this.selectedYear,
                status : this.status
                //semester : this.sele
            }
            console.log(JSON.stringify(searchTerm));
            searchSubmissions({searchKey : JSON.stringify(searchTerm)})//{programId: this.selectedProgramId , formId : this.selectedFormId})
            .then(result=>{

                this.customDT = result;
                this.data = this.customDT.data;
                this.filteredData = this.data;
                this.columns =  this.customDT.columns;
                //this.showExport = false;
                this.totalRecords = this.data.length;
                this.pageSize = this.pageSizeOptions[0];
                this.handlePagination();
                this.isLoading =false;
            })
            .catch(error=>{
                console.log('Error->'+ JSON.stringify(error) + error);
                this.isLoading =false;
            });
        }else{
            const toastevent = new ShowToastEvent({
                title: 'Error !',
                message: 'Please populate mandatory fields before clicking on Search.',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(toastevent);
        }
    }
    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                  return primer(x[field]);
              }
            : function (x) {
                  return x[field];
              };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }
    /**Handle Sorting of Data on Result Table  - BEGIN*/
    handleSort(event){
        const sortField = event.detail.fieldName;
        const sortDirection = event.detail.sortDirection;
        const clonedData = this.filteredData;
        clonedData.sort(this.sortBy(this.sortField, this.sortDirection==='asc' ? 1 : -1));
        //this.filteredData=[];
        this.filteredData = clonedData;
        console.log(JSON.stringify(this.filteredData));
        this.sortDirection = sortDirection;
        this.sortField = sortField;
        console.log(this.sortDirection);
        console.log(this.sortField);
    }
    /**Handle Sorting of Data on Result Table  - END*/

    /**Handle pagination based upon returned result of Data on Result Table - BEGIN */
    get disableFirstButton() {
        return this.pageNumber == 1;
    }
    get disableLastButton() {
        return this.pageNumber == this.totalPages;
    }
    get displayDT(){
        return this.totalRecords > 0;
    }
    get displaySearch(){
        return this.data.length >0;
    }
    get disableExport(){
        return this.totalRecords <= 0;
    }
    /*get displayError(){
        return this.recordsToDisplay.length <= 0;
    }*/
    handleRecordsPerPage(event) {
        this.pageSize = event.target.value;
        this.handlePagination();
    }
    previousPage() {
        this.pageNumber = this.pageNumber - 1;
        this.handlePagination();
    }
    nextPage() {
        this.pageNumber = this.pageNumber + 1;
        this.handlePagination();
    }
    firstPage() {
        this.pageNumber = 1;
        this.handlePagination();
    }
    lastPage() {
        this.pageNumber = this.totalPages;
        this.handlePagination();
    }
    handlePagination(){
        this.recordsToDisplay=[];
        // calculate total pages
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        // set page number 
        if (this.pageNumber <= 1) {
            this.pageNumber = 1;
        } else if (this.pageNumber >= this.totalPages) {
            this.pageNumber = this.totalPages;
        }
        // set records to display on current page 
        for (let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
            if (i === this.totalRecords) {
                break;
            }
            this.recordsToDisplay.push(this.filteredData[i]);
        }
        console.log(JSON.stringify(this.recordsToDisplay));
        this.displayError = this.recordsToDisplay.length > 0 ? false : true;
    }
    /**Handle pagination based upon returned result of Data on Result Table - END */

   /** Handle export of CSV on Result Table - BEGIN */
    handleExport(event){

        let fileName = "Report-Export-"+this.selectedFormName;
        exportCSVFile(this.columns, this.filteredData, fileName);
        const toastevent = new ShowToastEvent({
            title: 'Success',
            message: 'Your search report has been downloaded successfully.',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(toastevent);
    }
    /** Handle export of CSV on Result Table - END */

    /** Handle search mechanism on result table - BEGIN */
    handleSearchKeyword(event){
        let searchkey = event.target.value;
        let newData=[];
        //this.validateInput();
        if(searchkey && searchkey.length >= 2){
            if(this.filteredData.length === 0){
                this.filteredData = this.data;
            }
            for(var i=0; i<this.filteredData.length; i++) {
                //Object.keys(this.filteredData[i]).forEach(key=>{
                for(const key of Object.keys(this.filteredData[i])){
                    const val = this.filteredData[i][key].toLowerCase();
                    if(val && val.indexOf(searchkey.toLowerCase()) != -1){
                        newData.push(this.filteredData[i]);
                        break;
                    }
                }
                
            }
            this.filteredData = newData;
        }
        else{
            this.filteredData = this.data;
        } 
        this.totalRecords = this.filteredData.length;
        this.handlePagination();
    }
    /** Handle search mechanism on result table - END */
    setInputValidity(input, message){
        input.setCustomValidity(message);
        input.reportValidity();
    }
    validateInput(){
        if(!(this.selectedProgramId && this.selectedFormId && this.selectedYear)){
            this.hasError=true;
            console.log('Error'+ this.hasError);
            return true;
        }
        return false;
    }
}