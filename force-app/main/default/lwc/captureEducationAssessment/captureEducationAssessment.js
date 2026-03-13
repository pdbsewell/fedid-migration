import {LightningElement, api, wire} from 'lwc';
import getContactQualifications from "@salesforce/apex/EnglishOutcomeCapture.getContactQualifications";

export default class CaptureEducationAssessment extends LightningElement {

    @api contactIdentifier;
    @api acpIdentifier;

    columns;
    data = [];
    wiredContactQualificationsResult;
    saveDisabled = true;
    error;
    educationTypeOptionValue = 'Education';
    

    //get an existing contact qualification if it already exists
    @wire(getContactQualifications, {
        contactId: '$contactIdentifier'
    })
    contactQualifications(result) {
        if (result.data) {
            this.wiredContactQualificationsResult = result.data;
            this.columns = [
                { label: 'Contact Qualification ID', fieldName: 'Name'},
                { label: 'Application Status', fieldName: 'Application_Status__c'},
                { label: 'Qualification Name', fieldName: 'Qualification_Name__c'},
                { label: 'Other Qualification', fieldName: 'Other_Qualification__c'},
                { label: 'Other Awarding Body/Institution', fieldName: 'Other_Institution__c'},
                { label: 'Awarding Body/Institution Name', fieldName: 'Institution_Name__c'},
                { label: 'Qualification Country', fieldName: 'QualificationCountry'},
                { label: 'Year of Completion', fieldName: 'Year_of_Completion__c'},
                { label: 'Score', fieldName: 'Score__c'},
                { label: 'Monash Equivalent Band', fieldName: 'Monash_Equivalent_GPA__c'},
            ];
            let tmpdata = this.wiredContactQualificationsResult.filter(
                record => record.Qualification_Type__c != 'English Test'
            );
            this.data = tmpdata.map((element) => {
                return {
                    'Id': element.Id,
                    'Name': element.Name,
                    'Application_Status__c' : element.Application_Status__c,
                    'Qualification_Name__c': element.Qualification_Name__c?.replace(/<[^>]*>/g, ''),
                    'Other_Qualification__c': element.Other_Qualification__c,
                    'Other_Institution__c': element.Other_Institution__c,
                    'Institution_Name__c': element.Institution_Name__c,
                    'QualificationCountry': element.Qualification_Country__r?.Name,
                    'Year_of_Completion__c': element.Year_of_Completion__c,
                    'Score__c': element.Score__c,
                    'Monash_Equivalent_GPA__c': element.Monash_Equivalent_GPA__c,
                }
            });
        } else if (result.error) {
            this.error = result.error;
        }
    };
}