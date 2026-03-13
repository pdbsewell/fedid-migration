import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import { refreshApex } from '@salesforce/apex';
import ENGLISH_PROFICIENCY_FIELD from "@salesforce/schema/Contact_Qualification__c.English_Proficiency__c";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CONTACT_QUALIFICATION_OBJECT from "@salesforce/schema/Contact_Qualification__c";
import CONTACT_ID from '@salesforce/schema/User.ContactId';
import USER_ID from '@salesforce/user/Id';
import getQualificationRecords from "@salesforce/apex/searchWithDropdownCC.getSearchResults";
import upsertQualificationToContact from "@salesforce/apex/MyGRAppAddQualificationController.upsertQualificationToContact";
import getContactQualifications from "@salesforce/apex/MyGRAppAddQualificationController.getContactQualifications";

/**
*  @author Sethu Venna
*  @date 23-08-2024
*  @group My App Application for English Proficiency
*  @description used to manage the English Proficiency requirements for graduate research applications 
**/
export default class MyGRAppEnglishProficiency extends LightningElement {

    //hardcoded static variables
    ENGLISH_TEST_RECORD_TYPE_NAME = 'English Test';
    ENGLISH_TEST_RECORD_TYPE_DEV_NAME = 'English_Test';
    ENGLISH_TEST_DONE_VAL_LIST = ['TEST-DONE','ELBP-DONE'];
    ENGLISH_TEST_TODO_VAL_LIST = ['TEST-TODO'];
    //global variables
    @api applicationId;
    //local variables
    showSpinner = false;
    englishQualificationPicklistOptions = [];
    testNamePicklistOptions = [];
    declarationSigned;
    showTestNamePicklist = false;
    showDateCompleted = false;
    showDateToBeCompleted = false;
    contactQualificationRecord = {};
    today;
    showError;
    errorMessage;
    wiredContactQualificationsResult;
    
    
    connectedCallback(){
        let todayDate = new Date().toLocaleDateString('en-US').split('/')
        this.today = todayDate[2] +'-'+todayDate[0]+'-'+todayDate[1]
        this.showError = false;
        this.getQualificationRecords();
    }

    //getting the user record to get the contact id
    @wire(getRecord, { recordId: USER_ID, fields: [CONTACT_ID] })
    user;
    get contactId() {
        return getFieldValue(this.user.data, CONTACT_ID);
    }

    //store record type id of recordtye name ="English Test"
    englishTestRecordTypeId;
    @wire(getObjectInfo, { objectApiName: CONTACT_QUALIFICATION_OBJECT })
    function({error,data}) 
    {
        if(data && data.recordTypeInfos){
            for (let i in data.recordTypeInfos){
                if(data.recordTypeInfos[i].name === this.ENGLISH_TEST_RECORD_TYPE_NAME){
                    this.englishTestRecordTypeId = data.recordTypeInfos[i].recordTypeId;
                    break;
                }   
            }
        }else if(error){
            this.showError = true;
            this.errorMessage = error.body.message;
        }
    }

    //store picklist values to show English Proficiency options on the UI
    @wire(getPicklistValues, {
        recordTypeId: '$englishTestRecordTypeId',
        fieldApiName: ENGLISH_PROFICIENCY_FIELD
    })
    picklistResults({ error, data }) {
        if (data) {
            this.englishQualificationPicklistOptions = this.makeSelectOptions(data.values);
        } else if (error) {
            this.showError = true;
            this.errorMessage = error.body.message;
        }
    };

    //get an existing contact qualification if it already exists
    @wire(getContactQualifications, {
        applicationId: '$applicationId',
        recordTypeName: '$ENGLISH_TEST_RECORD_TYPE_DEV_NAME'
    })
    contactQualifications(result) {
        this.wiredContactQualificationsResult = result;
        if (result.data) {
            let records = result.data;
            this.contactQualificationRecord = {};
            records.forEach(item => {
                this.contactQualificationRecord.Id = item.Id;
                this.declarationSigned = true;
                this.contactQualificationRecord.English_Proficiency__c = item.English_Proficiency__c;
                this.contactQualificationRecord.Qualification__c = item.Qualification__c ? item.Qualification__c : item.Qualification_Name__c == 'Other' ? 'Other' : '';
                this.contactQualificationRecord.Expected_date_of_completion__c = item.Expected_date_of_completion__c ? item.Expected_date_of_completion__c : '';
                this.contactQualificationRecord.Date_Achieved__c = item.Date_Achieved__c ? item.Date_Achieved__c : '';
                this.resetEngProfChangeBooleanValues();
            });
            
        } else if (result.error) {
            this.showError = true;
            this.errorMessage = result.error.body.message;
        }
    };

    //handler when english qualification picklist is changed on the UI
    handleEnglishQualificationChange(event) {
        this.contactQualificationRecord.English_Proficiency__c = event.detail.value;
        setTimeout(() => {
            this.contactQualificationRecord = { ...this.contactQualificationRecord, Qualification__c : '', Expected_date_of_completion__c : '', Date_Achieved__c : '' };
        }, 0);
        this.resetEngProfChangeBooleanValues();
    }

    //util method to create Select Options from picklist values
    makeSelectOptions(picklistValues) {
        let returnOptions = [];
        returnOptions.push({
            value: '',
            label: '--None--'
        });
        picklistValues.forEach((item) => {
            returnOptions.push({
                label: item.label,
                value: item.value
            });
        });
        return returnOptions;
    }

    //get All Qualification records by Admission Test record type to show Test Name options on the UI
    getQualificationRecords() {
        getQualificationRecords({
            fieldsToReturn: ['Id', 'Qualification_Name__c', 'Callista_Code__c'],
            objectAPIName: 'Qualification__c',
            whereFields: ['RecordType.Name'],
            whereValues: ['Admission Test'],
            optionalWhereFields: [],
            searchFields: [],   
            searchText: ''
        }).
        then(response => {
            if (response) {
                let records = [];
                records.push({
                    value: '',
                    label: '--None--'
                });
                response.forEach((item) => {
                    if(item.Callista_Code__c == 'IELTS' || item.Callista_Code__c == 'ITOEFL' || item.Callista_Code__c == 'PTOEFL'){
                        records.push({
                            value: item.Id,
                            label: item.Qualification_Name__c
                        });
                    }
                });
                //Add the Other option
                records.push({
                    value: 'Other',
                    label: 'Other'
                });
                if(records){
                    this.testNamePicklistOptions = records;
                }
            }
        }).catch(errors => {
            if (errors) {
                this.showError = true;
                this.errorMessage = error.body.message;
            }
        });
    }

    //handler when test Name picklist is changed on the UI
    handleTestNameChange(event) {
        if(event.detail.value == 'Other'){
            this.contactQualificationRecord.Qualification__c = null;
            this.contactQualificationRecord.Other_Qualification__c = event.detail.value;
        }else{
            this.contactQualificationRecord.Qualification__c = event.detail.value;
            this.contactQualificationRecord.Other_Qualification__c = null;
        }
    }

    //handler when declaration is changed on the UI
    handleDeclarationChange(event) {
        this.declarationSigned = event.target.checked;
    }

    //handler when date completed is changed on the UI
    handleDateCompletedChange(event) {
        this.contactQualificationRecord.Date_Achieved__c = event.target.value;
    }

    //handler when date to becompleted is changed on the UI
    handleDateToBeCompletedChange(event) {
        this.contactQualificationRecord.Expected_date_of_completion__c = event.target.value;
    }

    //re-usable method to set the boolean values required to show/hide components on the UI
    resetEngProfChangeBooleanValues() {
        this.showTestNamePicklist = false;
        this.showDateCompleted = false;
        this.showDateToBeCompleted = false;
        if(this.ENGLISH_TEST_DONE_VAL_LIST.includes(this.contactQualificationRecord.English_Proficiency__c)) {
            this.showTestNamePicklist = true;
            this.showDateCompleted = true;
        } else if (this.ENGLISH_TEST_TODO_VAL_LIST.includes(this.contactQualificationRecord.English_Proficiency__c)) {
            this.showTestNamePicklist = true;
            this.showDateToBeCompleted = true;
        }
    }

    //expandable method to check validity of required components; returns true if valid, else false
    @api
    checkValidity() {
        const allValid = [
            ...this.template.querySelectorAll('lightning-input'),
            ...this.template.querySelectorAll('lightning-select'),
            ...this.template.querySelectorAll('lightning-radio-group'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        return allValid;
    }
    
    //save method to execute upsert of contact qualification record
    @api
    saveEnglishProficiencyQualification() {
        if(this.declarationSigned === true && this.contactQualificationRecord) {
            this.showSpinner = true;
            this.contactQualificationRecord.isTestCompleted__c = this.contactQualificationRecord.Date_Achieved__c ? true : false;
            this.clearUnusedValuesBeforeSave();
            upsertQualificationToContact({
                'contactId': this.contactId,
                'applicationId': this.applicationId,
                'contactQualification': this.contactQualificationRecord,
                'recordTypeName': this.ENGLISH_TEST_RECORD_TYPE_DEV_NAME
            }).then(response => {
                this.showSpinner = false;
                let saveSuccess = true;
                refreshApex(this.wiredContactQualificationsResult);
                const saveEvent = new CustomEvent("savesuccess", {
                    detail: { saveSuccess },
                  });
                this.dispatchEvent(saveEvent);
            }).catch((error) => {
                this.showError = true;
                this.errorMessage = error.body.message;
                this.showSpinner = false;
            })
        }
    }

    clearUnusedValuesBeforeSave() {
        if(!this.ENGLISH_TEST_DONE_VAL_LIST.includes(this.contactQualificationRecord.English_Proficiency__c) && !this.ENGLISH_TEST_TODO_VAL_LIST.includes(this.contactQualificationRecord.English_Proficiency__c)) {
            this.contactQualificationRecord.Other_Qualification__c = '';
            this.contactQualificationRecord.Qualification__c = null;
            this.contactQualificationRecord.Date_Achieved__c = null;
            this.contactQualificationRecord.Expected_date_of_completion__c = null;
        }
        if(this.contactQualificationRecord.Qualification__c == 'Other') {
            this.contactQualificationRecord.Qualification__c = null
            this.contactQualificationRecord.Other_Qualification__c = 'Other'
        }
    }
}