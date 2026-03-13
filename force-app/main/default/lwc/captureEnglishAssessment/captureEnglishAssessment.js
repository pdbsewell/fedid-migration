import {LightningElement, api, wire} from 'lwc';
import getContactQualifications from "@salesforce/apex/EnglishOutcomeCapture.getContactQualifications";

export default class CaptureEnglishAssessment extends LightningElement {

    @api contactIdentifier;
    @api acpIdentifier;

    columns;
    data = [];
    englishTypeOptionValue;
    wiredContactQualificationsResult;
    saveDisabled = true;
    monashEnglishModuleOptionValue;
    
    get isMonashEnglishPathway() {
        if(this.englishTypeOptionValue === 'Monash English Pathway') {
            return true;
        }
        return false;
    }

    get monashEnglishModuleOptions() {
        return [
            {label: 'Module 1', value: 'Module 1'},
            {label: 'Module 2', value: 'Module 2'},
            {label: 'Module 3', value: 'Module 3'},
            {label: 'Module 4', value: 'Module 4'},
            {label: 'Module 4 Advanced', value: 'Module 4 Advanced'},
            {label: 'Module 4 Advanced Plus', value: 'Module 4 Advanced Plus'}
        ];
    }
    
    get englishTypeOptions() {
        return [
            {label: 'VCE English Equivalent', value: 'VCE English Equivalent'},
            {label: 'Language of Instruction', value: 'Language of Instruction'},
            {label: 'English Test Results', value: 'English Test Results'},
            {label: 'Monash English Pathway', value: 'Monash English Pathway'},
            {label: 'Valid and Verified Professional Registration', value: 'Valid and Verified Professional Registration'},
        ];
    }

    //get an existing contact qualification if it already exists
    @wire(getContactQualifications, {
        contactId: '$contactIdentifier'
    })
    contactQualifications(result) {
        if (result.data) {
            this.wiredContactQualificationsResult = result.data;
        } else if (result.error) {
            this.showError = true;
            this.errorMessage = result.error.body.message;
        }
    };

    handleEnglishTypeChange(event) {
        this.englishTypeOptionValue = event.detail.value;
        this.findContactQualificationRecords();
    }

    handleMonashEnglishModuleChange(event) {
        this.monashEnglishModuleOptionValue = event.detail.value;
    }

    @api 
    findContactQualificationRecords()
    {   
        if(this.wiredContactQualificationsResult) {
            this.template.querySelector('c-capture-qualification-assessment').saveDisabled = true;
            this.columns = [
                { label: 'Contact Qualification ID', fieldName: 'Name'},
                { label: 'Application Status', fieldName: 'Application_Status__c'},
                { label: 'Qualification Name', fieldName: 'Qualification_Name__c'},
                { label: 'Record Type', fieldName: 'RecordType'},
                { label: 'Other Qualification', fieldName: 'Other_Qualification__c'},
                { label: 'Other Awarding Body/Institution', fieldName: 'Other_Institution__c'},
                { label: 'Awarding Body/Institution Name', fieldName: 'Institution_Name__c'},
                { label: 'Qualification Country', fieldName: 'QualificationCountry'},
                { label: 'Date Achieved', fieldName: 'Date_Achieved__c'},
                { label: 'Year of Completion', fieldName: 'Year_of_Completion__c'},
                { label: 'Last Year Enrolled', fieldName: 'Last_Year_Enrolled__c'},
            ];
            switch (this.englishTypeOptionValue) {
                
                case 'VCE English Equivalent':
                    this.data = this.wiredContactQualificationsResult.filter(
                        record => record.Qualification_Type__c === 'Secondary Education'
                    ).map((element) => {
                        return {
                            'Id': element.Id,
                            'Name': element.Name,
                            'Application_Status__c' : element.Application_Status__c,
                            'Qualification_Name__c': element.Qualification_Name__c?.replace(/<[^>]*>/g, ''),
                            'RecordType': element.Qualification_Type__c,
                            'Other_Qualification__c': element.Other_Qualification__c,
                            'Other_Institution__c': element.Other_Institution__c,
                            'Institution_Name__c': element.Institution_Name__c,
                            'QualificationCountry': element.Qualification_Country__r?.Name,
                            'Date_Achieved__c': element.Date_Achieved__c,
                            'Year_of_Completion__c': element.Year_of_Completion__c,
                            'Last_Year_Enrolled__c': element.Last_Year_Enrolled__c,
                        }
                    });
                    break;
                case 'Language of Instruction':
                    this.data = this.wiredContactQualificationsResult.filter(
                        record => record.Qualification_Type__c === 'Tertiary Education'
                    ).map((element) => {
                        return {
                            'Id': element.Id,
                            'Name': element.Name,
                            'Application_Status__c' : element.Application_Status__c,
                            'Qualification_Name__c': element.Qualification_Name__c?.replace(/<[^>]*>/g, ''),
                            'RecordType': element.Qualification_Type__c,
                            'Other_Qualification__c': element.Other_Qualification__c,
                            'Other_Institution__c': element.Other_Institution__c,
                            'Institution_Name__c': element.Institution_Name__c,
                            'QualificationCountry': element.Qualification_Country__r?.Name,
                            'Date_Achieved__c': element.Date_Achieved__c,
                            'Year_of_Completion__c': element.Year_of_Completion__c,
                            'Last_Year_Enrolled__c': element.Last_Year_Enrolled__c,
                        }
                    });
                    break;
                case 'English Test Results':
                    this.columns = [
                        { label: 'Contact Qualification ID', fieldName: 'Name'},
                        { label: 'Application Status', fieldName: 'Application_Status__c'},
                        { label: 'Type', fieldName: 'Qualification_Type__c'},
                        { label: 'Status', fieldName: 'Verification_Status__c'},
                        { label: 'Listening', fieldName: 'Listening__c'},
                        { label: 'Reading', fieldName: 'Reading__c'},
                        { label: 'Speaking', fieldName: 'Speaking__c'},
                        { label: 'Writing', fieldName: 'Writing__c'},
                        { label: 'Year', fieldName: 'Year_of_Completion__c'},
                        { label: 'Date Achieved', fieldName: 'Date_Achieved__c'}
                    ];
                    this.data = this.wiredContactQualificationsResult.filter(
                        record => record.Qualification_Type__c === 'English Test'
                    ).map((element) => {
                        return {
                            'Id': element.Id,
                            'Name': element.Name,
                            'Application_Status__c' : element.Application_Status__c,
                            'Qualification_Type__c': element.Qualification_Type__c,
                            'Verification_Status__c': element.Verification_Status__c,
                            'Listening__c': element.Listening__c,
                            'Reading__c': element.Reading__c,
                            'Speaking__c': element.Speaking__c,
                            'Writing__c': element.Writing__c,
                            'Year_of_Completion__c': element.Year_of_Completion__c,
                            'Date_Achieved__c': element.Date_Achieved__c,
                        }
                    });
                    break;
                    case 'Monash English Pathway':
                        this.template.querySelector('c-capture-qualification-assessment').saveDisabled = false;
                        this.data = [];
                        break;
                    case 'Valid and Verified Professional Registration':
                        this.template.querySelector('c-capture-qualification-assessment').saveDisabled = false;
                        this.data = [];
                        break;
                default:
                    this.data = this.wiredContactQualificationsResult.map((element) => {
                        return {
                            'Id': element.Id,
                            'Name': element.Name,
                            'Application_Status__c' : element.Application_Status__c,
                            'Qualification_Name__c': element.Qualification_Name__c?.replace(/<[^>]*>/g, ''),
                            'RecordType': element.Qualification_Type__c,
                            'Other_Qualification__c': element.Other_Qualification__c,
                            'Other_Institution__c': element.Other_Institution__c,
                            'Institution_Name__c': element.Institution_Name__c,
                            'QualificationCountry': element.Qualification_Country__r?.Name,
                            'Date_Achieved__c': element.Date_Achieved__c,
                            'Year_of_Completion__c': element.Year_of_Completion__c,
                            'Last_Year_Enrolled__c': element.Last_Year_Enrolled__c,
                        }
                    });
                    break;
            }
        }
    }
}