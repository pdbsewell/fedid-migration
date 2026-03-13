import {LightningElement, api, track} from 'lwc';
import getContactQualifications from "@salesforce/apex/EnglishOutcomeCapture.getContactQualificationsByRecordType";
import getApplicationCoursePreference from "@salesforce/apex/EnglishOutcomeCapture.getApplicationCoursePreferences";
import createCoursePreferenceQualification from "@salesforce/apex/EnglishOutcomeCapture.createCoursePreferenceQualification";

export default class EnglishOutcomeCapture extends LightningElement {
    @api contactIdentifier;
    @api acpIdentifier;

    @track contact;
    @track englishTypeOptionValue;
    @track resultTypeValue;

    @track applicationCoursePreferences;
    @track qualificationRecords;
    @track saving;

    selectedQualificationRecords = [];
    selectedACPRecords = [];

    connectedCallback(){
        this.saving = false;
        this.findContactQualificationRecords();
        this.findApplicationCoursePreferenceRecords();
    }

    get resultTypeOptions() {
        return [
            {label: 'Satisfactory', value: 'Satisfactory'},
            {label: 'Unsatisfactory', value: 'Unsatisfactory'}
        ];
    }

    get acp(){
        return this.englishTypeOptionValue === 'Monash English Pathway';
    }

    get englishTypeOptions() {
        return [
            {label: 'VCE English Equivalent', value: 'VCE English Equivalent'},
            {label: 'Monash English Pathway', value: 'Monash English Pathway'},
            {label: 'Language of Instruction', value: 'Language of Instruction'},
            {label: 'English Test Results', value: 'English Test Results'}
        ];
    }

    addToList(event){
        console.log(event.currentTarget.dataset.contactqual)
        const index = this.selectedQualificationRecords.indexOf(event.currentTarget.dataset.contactqual);
        if(index === -1){
            this.selectedQualificationRecords.push(event.currentTarget.dataset.contactqual);
        }else{
            this.selectedQualificationRecords.splice(index, 1);
        }
        console.log(this.selectedQualificationRecords);
    }

    saveRecord(){
        console.log("saving")
        this.saving = true;

        //Create the Structure
        let saveList = {records : []};
        let processingList;
        if(this.selectedQualificationRecords.length > 0){
            processingList = this.selectedQualificationRecords;
        }else{
            processingList = this.selectedACPRecords;
        }

        processingList.forEach(element => {
            saveList.records.push({
                "recordId" : element,
                "contactId" : this.contactIdentifier,
                "type" :this.englishTypeOptionValue,
                "applicationCoursePreference" : this.acpIdentifier,
                "result" : this.resultTypeValue
            });
        });

        console.log(JSON.stringify(saveList))

        createCoursePreferenceQualification({records : JSON.stringify(saveList)}).then(result => {
            console.log(result)
            this.saving = false;
        }).catch(err => {
            console.log(err)
            this.saving = false;
        })

    }

    addToAcpList(event){
        const index = this.selectedACPRecords.indexOf(event.currentTarget.dataset.acp);
        if(index === -1){
            this.selectedACPRecords.push(event.currentTarget.dataset.acp);
        }else{
            this.selectedACPRecords.splice(index, 1);
        }
        console.log(this.selectedACPRecords);
    }

    findApplicationCoursePreferenceRecords(){
        getApplicationCoursePreference({contactId: this.contactIdentifier}).then(result => {
            console.log(result)
            this.applicationCoursePreferences = result;

        }).catch(err => {
            console.log(err);
        })
    }

    findContactQualificationRecords(){
        console.log("English type value  -- " + this.englishTypeOptionValue);
        console.log(this.contactIdentifier + " 00 " + this.englishTypeOptionValue);
        getContactQualifications({contactId: this.contactIdentifier, recordTypeName: this.englishTypeOptionValue}).then(result =>{
            console.log("The results of the records from the database -- ")
            console.log(result)
            this.qualificationRecords = result;
        }).catch(err => {
            console.log(err);
        });
    }

    handlePicklistChange(event) {
        console.log(event.detail.value)
        this.selectedACPRecords = [];
        this.selectedQualificationRecords = [];
        this.englishTypeOptionValue = event.detail.value;
        this.findContactQualificationRecords();
    }

    handleResultPicklistChange(event) {
        this.resultTypeValue = event.detail.value;
    }
}