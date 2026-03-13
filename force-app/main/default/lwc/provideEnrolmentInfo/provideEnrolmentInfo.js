import {LightningElement,api,track,wire} from "lwc";
import { getRecord } from 'lightning/uiRecordApi';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from 'lightning/actions';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import ENQUIRY_OBJECT from '@salesforce/schema/Case';
import STAFF_ORG_FIELD from '@salesforce/schema/Case.Staff_Organisation_Unit__c';
import REQ_TYPE_FIELD from '@salesforce/schema/Case.Request_Type__c';

/* APEX SERVICES */
import submitEnquiryDetails from "@salesforce/apex/ProvideEnrolmentInfoController.submitEnquiryDetails";
import retrieveEnquiryDetails from "@salesforce/apex/ProvideEnrolmentInfoController.retrieveEnquiryDetails";

export default class ProvideEnrolmentInfo extends LightningElement {
    //@api recordId;
    @track showSpinner;
    standardRecordTypeId = '';
    bulkSinglRequest = 'Single';
    commentFurtherInfo = '';
    courseCode = '';
    reqReceiveDate = '';
    reqUnivError = '';
    noOfUnits = '';
    s_description = '';
    staffOrgUnitOptions = [];
    staffOrgUnitSelectedValue;

    reqTypeOptions = [];
    reqTypeSelectedValue;

    howManyIndivStudentRecds = '';
    details = '';
    otherFreeText = false;

    // Entry 1
    entry1Year = "";
    entry1UnitCode = "";
    entry1TeachingPeriod  = "";
    entry1Standard = "";
    entry1NonStandard = "";
    entry1Outcome = "";

    // Entry 2
    entry2Year = "";
    entry2UnitCode = "";
    entry2TeachingPeriod = "";
    entry2Standard = "";
    entry2NonStandard = "";
    entry2Outcome = "";

    // Entry 3
    entry3Year = "";
    entry3UnitCode = "";
    entry3TeachingPeriod = "";
    entry3Standard = "";
    entry3NonStandard = "";
    entry3Outcome = "";

    // Entry 4
    entry4Year = "";
    entry4UnitCode = "";
    entry4TeachingPeriod = "";
    entry4Standard = "";
    entry4NonStandard = "";
    entry4Outcome = "";

    // Entry 5
    entry5Year = "";
    entry5UnitCode = "";
    entry5TeachingPeriod = "";
    entry5Standard = "";
    entry5NonStandard = "";
    entry5Outcome = "";
    
    // Entry 6
    entry6Year = "";
    entry6UnitCode = "";
    entry6TeachingPeriod = "";
    entry6Standard = "";
    entry6NonStandard = "";
    entry6Outcome = "";


    // Entry 7
    entry7Year = "";
    entry7UnitCode = "";
    entry7TeachingPeriod = "";
    entry7Standard = "";
    entry7NonStandard = "";
    entry7Outcome = "";


    // Entry 8
    entry8Year = "";
    entry8UnitCode = "";
    entry8TeachingPeriod = "";
    entry8Standard = "";
    entry8NonStandard = "";
    entry8Outcome = "";

    // Entry 9
    entry9Year = "";
    entry9UnitCode = "";
    entry9TeachingPeriod = "";
    entry9Standard = "";
    entry9NonStandard = "";
    entry9Outcome = "";


    // Entry 10
    entry10Year = "";
    entry10UnitCode = "";
    entry10TeachingPeriod = "";
    entry10Standard = "";
    entry10NonStandard = "";
    entry10Outcome = "";

    @api set recordId(value) {
        this._recordId = value;
        this.getData();
    }

    get outcomeOptions() {
        return [
            { label: 'Withdrawn Early (WD-EARLY)', value: 'Withdrawn Early (WD-EARLY)' },
            { label: 'Withdrawn Late (WD-LATE)', value: 'Withdrawn Late (WD-LATE)' },
            { label: 'Withdrawn Fail (WD-FAIL)', value: 'Withdrawn Fail (WD-FAIL)' },
            { label: 'Enrol', value: 'Enrol' }
        ];
    }

    get recordId() {
        return this._recordId;
    }

    @wire(getObjectInfo, { objectApiName: ENQUIRY_OBJECT })
    handleObjectInfoResult({error, data}) {
        if(data) {            
            //Get application assessment record type
            const rtis = data.recordTypeInfos;
            this.standardRecordTypeId = Object.keys(rtis).find(rti => rtis[rti].name === 'Standard Enquiry');
        } else {
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$standardRecordTypeId', fieldApiName: STAFF_ORG_FIELD })
    handleStaffOrgPicklistInfoResult({error, data}) {
        if(data) {
            let optionsValues = [];
            let resultValues = data.values;

            for(let i = 0; i < resultValues.length; i++) {
                optionsValues.push({
                    label: resultValues[i].label,
                    value: resultValues[i].value
                })
            }
            this.staffOrgUnitOptions = optionsValues;
        } else {
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$standardRecordTypeId', fieldApiName: REQ_TYPE_FIELD })
    handleReqTypePicklistInfoResult({error, data}) {
        if(data) {
            let optionsValues = [];
            let resultValues = data.values;

            for(let i = 0; i < resultValues.length; i++) {
                optionsValues.push({
                    label: resultValues[i].label,
                    value: resultValues[i].value
                })
            }
            this.reqTypeOptions = optionsValues;
        } else {
            this.error = error;
        }
    }

    /*
     * Method Name: getData
     * Description: method to call apex function passing parameters from the UI
     */
    getData() {
        this.showSpinner = true;
        retrieveEnquiryDetails({
                s_caseRecId : this.recordId
            })
            .then((result) => {
                if(result){
                    if(result.staffOrgUnit){
                        this.staffOrgUnitSelectedValue = result.staffOrgUnit;
                    }
                    if(result.reqType){
                        this.reqTypeSelectedValue = result.reqType;
                        if(this.reqTypeSelectedValue == 'Other (free text)'){
                            this.otherFreeText = true;
                        }else{
                            this.otherFreeText = false;
                        }
                    }
                    this.howManyIndivStudentRecds = result.indivStudentsRecd;
                    if(result.details){
                        this.details = result.details;
                    }
                }
                this.showSpinner = false;
            })
            .catch((error) => {
                this.showToast(
                    "Error",
                    "An error has occurred: " + error.body.message,
                    "Error"
                );
                this.showSpinner = false;
            });
    }

    submitOnClick(){
        // Validate
        if(this.validateDetails()){
            // Consolidate all details 
            this.consolidateDetails();

            this.showSpinner = true;
            submitEnquiryDetails({
                s_description : this.s_description,
                s_staffOrgUnit : this.staffOrgUnitSelectedValue,
                s_reqType : this.reqTypeSelectedValue, 
                s_howManyIndivStudents : this.howManyIndivStudentRecds,
                s_details : this.details,
                s_caseRecId : this.recordId
            })
            .then((result) => {
                this.showToast(
                    "Success",
                    "Enrolment details updated",
                    "Success"
                );
                this.dispatchEvent(new CloseActionScreenEvent());
                this.showSpinner = false;
            })
            .catch((error) => {
                this.showToast(
                    "Error",
                    "An error has occurred: " + error.body.message,
                    "Error"
                );
                this.showSpinner = false;
            });
        }  
    }

    consolidateDetails(){
        this.s_description = 'Is this a bulk request, or a single-student : ' + this.bulkSinglRequest + ' \n ' +
                         'Comments/Further Information : ' + this.commentFurtherInfo  + ' \n ' +
                         'Date request was received from the Student : ' + this.reqReceiveDate  + ' \n ' +
                         'Course Code : ' + this.courseCode  + ' \n ' +
                         'If the request is due to a University error, provide an additional explanation:  ' + this.reqUnivError  + ' \n ' +
                         'Please select the number of units required : ' + this.noOfUnits + ' \n  \n' +
                         'ENTRY 1' + ' \n  \n' +
                         'Year : ' + this.entry1Year + ' \n ' +
                         'Unit Code : ' + this.entry1UnitCode  + ' \n ' +
                         'Teaching Period : ' + this.entry1TeachingPeriod  + ' \n ' +
                         'Is this a standard date teaching period? : ' + this.entry1Standard +  ' \n ' +
                         'If ‘No’ non-standard TEACHING PERIOD must include URL  : ' + this.entry1NonStandard +  ' \n ' +
                         'Outcome :  ' + this.entry1Outcome +  ' \n  \n' + 
                         'ENTRY 2' + ' \n  \n' +
                         'Year : ' + this.entry2Year + ' \n ' +
                         'Unit Code : ' + this.entry2UnitCode  + ' \n ' +
                         'Teaching Period : ' + this.entry2TeachingPeriod  + ' \n ' +
                         'Is this a standard date teaching period? : ' + this.entry2Standard +  ' \n ' +
                         'If ‘No’ non-standard TEACHING PERIOD must include URL  : ' + this.entry2NonStandard +  ' \n ' +
                         'Outcome :  ' + this.entry2Outcome +  ' \n  \n' + 
                         'ENTRY 3' + ' \n  \n' +
                         'Year : ' + this.entry3Year + ' \n ' +
                         'Unit Code : ' + this.entry3UnitCode  + ' \n ' +
                         'Teaching Period : ' + this.entry3TeachingPeriod  + ' \n ' +
                         'Is this a standard date teaching period? : ' + this.entry3Standard +  ' \n ' +
                         'If ‘No’ non-standard TEACHING PERIOD must include URL  : ' + this.entry3NonStandard +  ' \n ' +
                         'Outcome :  ' + this.entry3Outcome +  ' \n  \n' +
                         'ENTRY 4' + ' \n  \n' +
                         'Year : ' + this.entry4Year + ' \n ' +
                         'Unit Code : ' + this.entry4UnitCode  + ' \n ' +
                         'Teaching Period : ' + this.entry4TeachingPeriod  + ' \n ' +
                         'Is this a standard date teaching period? : ' + this.entry4Standard +  ' \n ' +
                         'If ‘No’ non-standard TEACHING PERIOD must include URL  : ' + this.entry4NonStandard +  ' \n ' +
                         'Outcome :  ' + this.entry4Outcome +  ' \n  \n' +  
                         'ENTRY 5' + ' \n  \n' +
                         'Year : ' + this.entry5Year + ' \n ' +
                         'Unit Code : ' + this.entry5UnitCode  + ' \n ' +
                         'Teaching Period : ' + this.entry5TeachingPeriod  + ' \n ' +
                         'Is this a standard date teaching period? : ' + this.entry5Standard +  ' \n ' +
                         'If ‘No’ non-standard TEACHING PERIOD must include URL  : ' + this.entry5NonStandard +  ' \n ' +
                         'Outcome :  ' + this.entry5Outcome +  ' \n  \n' + 
                         'ENTRY 6' + ' \n  \n' +
                         'Year : ' + this.entry6Year + ' \n ' +
                         'Unit Code : ' + this.entry6UnitCode  + ' \n ' +
                         'Teaching Period : ' + this.entry6TeachingPeriod  + ' \n ' +
                         'Is this a standard date teaching period? : ' + this.entry6Standard +  ' \n ' +
                         'If ‘No’ non-standard TEACHING PERIOD must include URL  : ' + this.entry6NonStandard +  ' \n ' +
                         'Outcome :  ' + this.entry6Outcome +  ' \n  \n' +
                         'ENTRY 7' + ' \n  \n' +
                         'Year : ' + this.entry7Year + ' \n ' +
                         'Unit Code : ' + this.entry7UnitCode  + ' \n ' +
                         'Teaching Period : ' + this.entry7TeachingPeriod  + ' \n ' +
                         'Is this a standard date teaching period? : ' + this.entry7Standard +  ' \n ' +
                         'If ‘No’ non-standard TEACHING PERIOD must include URL  : ' + this.entry7NonStandard +  ' \n ' +
                         'Outcome :  ' + this.entry7Outcome +  ' \n  \n' +  
                         'ENTRY 8' + ' \n  \n' +
                         'Year : ' + this.entry8Year + ' \n ' +
                         'Unit Code : ' + this.entry8UnitCode  + ' \n ' +
                         'Teaching Period : ' + this.entry8TeachingPeriod  + ' \n ' +
                         'Is this a standard date teaching period? : ' + this.entry8Standard +  ' \n ' +
                         'If ‘No’ non-standard TEACHING PERIOD must include URL  : ' + this.entry8NonStandard +  ' \n ' +
                         'Outcome :  ' + this.entry8Outcome +  ' \n  \n' +
                         'ENTRY 9' + ' \n  \n' +
                         'Year : ' + this.entry9Year + ' \n ' +
                         'Unit Code : ' + this.entry9UnitCode  + ' \n ' +
                         'Teaching Period : ' + this.entry9TeachingPeriod  + ' \n ' +
                         'Is this a standard date teaching period? : ' + this.entry9Standard +  ' \n ' +
                         'If ‘No’ non-standard TEACHING PERIOD must include URL  : ' + this.entry9NonStandard +  ' \n ' +
                         'Outcome :  ' + this.entry9Outcome +  ' \n  \n' +  
                         'ENTRY 10' + ' \n  \n' +
                         'Year : ' + this.entry10Year + ' \n ' +
                         'Unit Code : ' + this.entry10UnitCode  + ' \n ' +
                         'Teaching Period : ' + this.entry10TeachingPeriod  + ' \n ' +
                         'Is this a standard date teaching period? : ' + this.entry10Standard +  ' \n ' +
                         'If ‘No’ non-standard TEACHING PERIOD must include URL  : ' + this.entry10NonStandard +  ' \n ' +
                         'Outcome :  ' + this.entry10Outcome  ;
    }

    validateDetails(){
        // Validate staff Org Unit Selected Value
        if(this.staffOrgUnitSelectedValue == null || this.staffOrgUnitSelectedValue == '' || this.staffOrgUnitSelectedValue == undefined){
            this.showToast(
                "Error",
                "Please fill out Staff Organisation Unit." ,
                "Error"
            );
            return false; 
        }

        // Validate Req Type Value
        if(this.reqTypeSelectedValue == null || this.reqTypeSelectedValue == '' || this.reqTypeSelectedValue == undefined){
            this.showToast(
                "Error",
                "Please fill out Req Type." ,
                "Error"
            );
            return false; 
        }

        // Validate individual student records
        if(this.howManyIndivStudentRecds == null || this.howManyIndivStudentRecds == '' || this.howManyIndivStudentRecds == undefined){
            if(this.howManyIndivStudentRecds != 0){
                this.showToast(
                    "Error",
                    "Please fill out How many Individual Students." ,
                    "Error"
                );
                return false;  
            }
        }else{
            let isNum = /^\d+$/.test(this.howManyIndivStudentRecds);
            if(!isNum){
                this.showToast(
                    "Error",
                    "Incorrect value for field How many Individual Students provided." ,
                    "Error"
                );
                return false;
            }
        }
        
        // Validate Req Type Value
        if(this.otherFreeText && this.details == ''){
            this.showToast(
                "Error",
                "Please fill out the Details." ,
                "Error"
            );
            return false; 
        }

        // Validate Year
        if(!this.validYear(this.entry1Year, 'Entry 1') || !this.validYear(this.entry2Year, 'Entry 2') || !this.validYear(this.entry3Year, 'Entry 3') 
            || !this.validYear(this.entry4Year, 'Entry 4') || !this.validYear(this.entry5Year, 'Entry 5') || !this.validYear(this.entry6Year, 'Entry 6') 
            || !this.validYear(this.entry7Year, 'Entry 7') || !this.validYear(this.entry8Year, 'Entry 8') || !this.validYear(this.entry9Year, 'Entry 9') 
            || !this.validYear(this.entry10Year, 'Entry 10')){
            return false;           
        }

        // Validate Bulk or Single Req
        if(this.bulkSinglRequest == null || this.bulkSinglRequest == '' || this.bulkSinglRequest == undefined){
            this.showToast(
                "Error",
                "Please fill out bulk request or a single-student." ,
                "Error"
            );
            return false;
        }
        //Validate Course COde
        if(this.courseCode == null || this.courseCode == '' || this.courseCode == undefined){
            this.showToast(
                "Error",
                "Please fill out course code." ,
                "Error"
            );
            return false;
        }
        //Validate Requerst date
        if(this.reqReceiveDate == null || this.reqReceiveDate == '' || this.reqReceiveDate == undefined){
            this.showToast(
                "Error",
                "Please fill out Request date." ,
                "Error"
            );
            return false;
        }
        //Validate no of Units
        if(this.noOfUnits == null || this.noOfUnits == '' || this.noOfUnits == undefined){
            this.showToast(
                "Error",
                "Please fill out number of Units." ,
                "Error"
            );
            return false;
        }
        return true;
    }

    validYear(year, details){
        if(year !== ''){
            let isNum = /^\d+$/.test(year);
            if(!isNum || (isNum && year > 2199)){
                this.showToast(
                    "Error",
                    details + " - Incorrect value for the Year field provided." ,
                    "Error"
                );
                return false;
            }
            return true;           
        }else{
            return true;
        }
    }

    /*
     * Method Name: showToast
     * Description: method to show toast
     */
    showToast(toastTitle, toastMessage, toastVariant) {
        const toast = new ShowToastEvent({
            title: toastTitle,
            message: toastMessage,
            variant: toastVariant,
        });
        this.dispatchEvent(toast);
    }

    handleDetailsChange(event){
        this.details = event.target.value;
    }

    handleHowManyIndivStudentRecdsChange(event){
        this.howManyIndivStudentRecds = event.target.value;
    }

    handleStaffOrgUnitChange(event) {
        this.staffOrgUnitSelectedValue = event.detail.value;
    }

    handleReqTypeChange(event) {
        this.reqTypeSelectedValue = event.detail.value;
        if(this.reqTypeSelectedValue == 'Other (free text)'){
            this.otherFreeText = true;
        }else{
            this.otherFreeText = false;
        }
    }

    handleCourseCode(event) {
        this.courseCode = event.target.value;
    }
    
    handleBulkSinglRequestChange(event) {
        this.bulkSinglRequest = event.target.value;
    }

    handleCommentFurtherInfo(event) {
        this.commentFurtherInfo = event.target.value;
    }

    handleReqReceiveDate(event) {
        this.reqReceiveDate = event.target.value;
    }

    handleReqUnivError(event) {
        this.reqUnivError = event.target.value;
    }

    handleNoOfUnits(event) {
        this.noOfUnits = event.target.value;
    }


    // Entry 1
    handleEntry1Year(event) {
        this.entry1Year = event.target.value;
    }
    
    handleEntry1UnitCode(event) {
        this.entry1UnitCode = event.target.value;
    }

    handleEntry1TeachingPeriod(event) {
        this.entry1TeachingPeriod = event.target.value;
    }

    handleEntry1Standard(event) {
        this.entry1Standard = event.target.value;
    }

    handleEntry1NonStandard(event) {
        this.entry1NonStandard = event.target.value;
    }

    handleEntry1Outcome(event) {
        this.entry1Outcome = event.detail.value;
    }

    // Entry 2
    handleEntry2Year(event) {
        this.entry2Year = event.target.value;
    }
    
    handleEntry2UnitCode(event) {
        this.entry2UnitCode = event.target.value;
    }

    handleEntry2TeachingPeriod(event) {
        this.entry2TeachingPeriod = event.target.value;
    }

    handleEntry2Standard(event) {
        this.entry2Standard = event.target.value;
    }

    handleEntry2NonStandard(event) {
        this.entry2NonStandard = event.target.value;
    }

    handleEntry2Outcome(event) {
        this.entry2Outcome = event.detail.value;
    }

    // Entry 3
    handleEntry3Year(event) {
        this.entry3Year = event.target.value;
    }
    
    handleEntry3UnitCode(event) {
        this.entry3UnitCode = event.target.value;
    }

    handleEntry3TeachingPeriod(event) {
        this.entry3TeachingPeriod = event.target.value;
    }

    handleEntry3Standard(event) {
        this.entry3Standard = event.target.value;
    }

    handleEntry3NonStandard(event) {
        this.entry3NonStandard = event.target.value;
    }

    handleEntry3Outcome(event) {
        this.entry3Outcome = event.detail.value;
    }


    // Entry 4
    handleEntry4Year(event) {
        this.entry4Year = event.target.value;
    }
    
    handleEntry4UnitCode(event) {
        this.entry4UnitCode = event.target.value;
    }

    handleEntry4TeachingPeriod(event) {
        this.entry4TeachingPeriod = event.target.value;
    }

    handleEntry4Standard(event) {
        this.entry4Standard = event.target.value;
    }

    handleEntry4NonStandard(event) {
        this.entry4NonStandard = event.target.value;
    }

    handleEntry4Outcome(event) {
        this.entry4Outcome = event.detail.value;
    }

    // Entry 5
    handleEntry5Year(event) {
        this.entry5Year = event.target.value;
    }
    
    handleEntry5UnitCode(event) {
        this.entry5UnitCode = event.target.value;
    }

    handleEntry5TeachingPeriod(event) {
        this.entry5TeachingPeriod = event.target.value;
    }

    handleEntry5Standard(event) {
        this.entry5Standard = event.target.value;
    }

    handleEntry5NonStandard(event) {
        this.entry5NonStandard = event.target.value;
    }

    handleEntry5Outcome(event) {
        this.entry5Outcome = event.detail.value;
    }

    // Entry 6
    handleEntry6Year(event) {
        this.entry6Year = event.target.value;
    }
    
    handleEntry6UnitCode(event) {
        this.entry6UnitCode = event.target.value;
    }

    handleEntry6TeachingPeriod(event) {
        this.entry6TeachingPeriod = event.target.value;
    }

    handleEntry6Standard(event) {
        this.entry6Standard = event.target.value;
    }

    handleEntry6NonStandard(event) {
        this.entry6NonStandard = event.target.value;
    }

    handleEntry6Outcome(event) {
        this.entry6Outcome = event.detail.value;
    }

    // Entry 7
    handleEntry7Year(event) {
        this.entry7Year = event.target.value;
    }
    
    handleEntry7UnitCode(event) {
        this.entry7UnitCode = event.target.value;
    }

    handleEntry7TeachingPeriod(event) {
        this.entry7TeachingPeriod = event.target.value;
    }

    handleEntry7Standard(event) {
        this.entry7Standard = event.target.value;
    }

    handleEntry7NonStandard(event) {
        this.entry7NonStandard = event.target.value;
    }

    handleEntry7Outcome(event) {
        this.entry7Outcome = event.detail.value;
    }

    // Entry 8
    handleEntry8Year(event) {
        this.entry8Year = event.target.value;
    }
    
    handleEntry8UnitCode(event) {
        this.entry8UnitCode = event.target.value;
    }

    handleEntry8TeachingPeriod(event) {
        this.entry8TeachingPeriod = event.target.value;
    }

    handleEntry8Standard(event) {
        this.entry8Standard = event.target.value;
    }

    handleEntry8NonStandard(event) {
        this.entry8NonStandard = event.target.value;
    }

    handleEntry8Outcome(event) {
        this.entry8Outcome = event.detail.value;
    }

    // Entry 9
    handleEntry9Year(event) {
        this.entry9Year = event.target.value;
    }
    
    handleEntry9UnitCode(event) {
        this.entry9UnitCode = event.target.value;
    }

    handleEntry9TeachingPeriod(event) {
        this.entry9TeachingPeriod = event.target.value;
    }

    handleEntry9Standard(event) {
        this.entry9Standard = event.target.value;
    }

    handleEntry9NonStandard(event) {
        this.entry9NonStandard = event.target.value;
    }

    handleEntry9Outcome(event) {
        this.entry9Outcome = event.detail.value;
    }

    // Entry 10
    handleEntry10Year(event) {
        this.entry10Year = event.target.value;
    }
    
    handleEntry10UnitCode(event) {
        this.entry10UnitCode = event.target.value;
    }

    handleEntry10TeachingPeriod(event) {
        this.entry10TeachingPeriod = event.target.value;
    }

    handleEntry10Standard(event) {
        this.entry10Standard = event.target.value;
    }

    handleEntry10NonStandard(event) {
        this.entry10NonStandard = event.target.value;
    }

    handleEntry10Outcome(event) {
        this.entry10Outcome = event.detail.value;
    }
}