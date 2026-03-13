import {LightningElement, api, wire} from 'lwc';
import createCoursePreferenceQualification from "@salesforce/apex/EnglishOutcomeCapture.createCoursePreferenceQualification";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { FlowNavigationFinishEvent } from 'lightning/flowSupport';

export default class CaptureQualificationAssessment extends LightningElement {

    @api contactIdentifier;
    @api acpIdentifier;
    @api columns;
    @api tableData;
    @api qualificationSubType;
    @api saveDisabled;
    @api messageText;
    @api monashEnglishModule;

    resultTypeValue;

    wiredContactQualificationsResult;
    saving;
    selectedQualificationRecords = [];

    titleText = "Sample Title";
    variant = "error";

    get showTable() {
        return this.tableData.length > 0;
    }

    connectedCallback(){
        this.saving = false;
    }

    get resultTypeOptions() {
        let resultTypeOptionsList =  [
            {label: 'Satisfactory', value: 'Satisfactory'},
            {label: 'Unsatisfactory', value: 'Unsatisfactory'},
            {label: 'To be completed', value: 'To be completed'}
        ];
        if(this.qualificationSubType === 'Valid and Verified Professional Registration') {
            resultTypeOptionsList = [ 
                {label: 'Satisfactory', value: 'Satisfactory'} 
            ];
            this.resultTypeValue = 'Satisfactory';
        }
        return resultTypeOptionsList;
    }


    addToList(event) {
        switch (event.detail.config.action) {
            case 'selectAllRows':
                this.saveDisabled = false;
                this.selectedQualificationRecords = [];
                for (let i = 0; i < event.detail.selectedRows.length; i++) {
                    this.selectedQualificationRecords.push(event.detail.selectedRows[i].Id);
                }
                break;
            case 'deselectAllRows':
                this.saveDisabled = true;
                this.selectedQualificationRecords = [];
                break;
            case 'rowSelect':
                this.saveDisabled = false;
                this.selectedQualificationRecords.push(event.detail.config.value);
                break;
            case 'rowDeselect':
                let index = this.selectedQualificationRecords.indexOf(event.detail.config.value);
                if (index !== -1) {
                    this.selectedQualificationRecords.splice(index, 1);
                }
                if(Array.isArray(this.selectedQualificationRecords) && !this.selectedQualificationRecords.length) {
                    this.saveDisabled = true;
                }
                break;
            default:
                break;
        }
    }

    saveRecord(){

        const allValid = this.checkValidity();

        if(allValid === true) {
            this.saving = true;

            //Create the Structure
            let saveList = {records : []};
            let processingList;
            if(this.selectedQualificationRecords.length > 0){
                processingList = this.selectedQualificationRecords;
            }else{
                processingList = ['dummyRecord'];
            }

            processingList.forEach(element => {
                saveList.records.push({
                    "recordId" : element,
                    "contactId" : this.contactIdentifier,
                    "type" :this.qualificationSubType,
                    "applicationCoursePreference" : this.acpIdentifier,
                    "result" : this.resultTypeValue,
                    "monashEnglishModule" : this.monashEnglishModule
                });
            });

            
            createCoursePreferenceQualification({records : JSON.stringify(saveList)}).then(result => {
                this.titleText = "Success";
                this.variant = "success";
                this.showNotification();
                const navigateFinishEvent = new FlowNavigationFinishEvent();
                this.dispatchEvent(navigateFinishEvent);
                this.saving = false;
            }).catch(err => {
                this.saving = false;
            })
        } 
    }

    handleResultPicklistChange(event) {
        this.resultTypeValue = event.detail.value;
    }

    showNotification() {
        const evt = new ShowToastEvent({
          title: this.titleText,
          message: this.messageText,
          variant: this.variant,
        });
        this.dispatchEvent(evt);
    }

    checkValidity() {
        const allValid = [
            ...this.template.querySelectorAll('lightning-combobox'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        return allValid;
    }
    
}