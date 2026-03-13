/**
 * @description       : 
 * @author            : Ben Greenland
 * @group             : 
 * @last modified on  : 2024-08-20
 * @last modified by  : Ben Greenland
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2024-08-20   Ben Greenland   filtered out "INTRNTNL.O" for getCitizenshipTypes SFTG-3890
**/
import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { createRecord } from 'lightning/uiRecordApi';
import { getPicklistValues, getObjectInfo } from "lightning/uiObjectInfoApi";
import CONTACT_OBJECT from '@salesforce/schema/Contact';
import APPLICATION_OBJECT from '@salesforce/schema/Application__c';
import CONTACT_FIRSTNAME_FIELD from '@salesforce/schema/Contact.FirstName';
import CONTACT_LASTNAME_FIELD from '@salesforce/schema/Contact.LastName';
import CONTACT_LEGAL_FIRSTNAME_FIELD from '@salesforce/schema/Contact.First_Name__c';
import CONTACT_LEGAL_LASTNAME_FIELD from '@salesforce/schema/Contact.Last_Name__c';
import CONTACT_BIRTHDATE_FIELD from '@salesforce/schema/Contact.Birthdate';
import CONTACT_EMAIL_FIELD from '@salesforce/schema/Contact.Email';
import CONTACT_PERSONAL_FIELD from '@salesforce/schema/Contact.Personal_Email__c';
import LOCATION_FIELD from "@salesforce/schema/Application__c.Campus_Location__c";
import SUBTITLE from "@salesforce/label/c.Partner_Application_Subtitle";

import Id from '@salesforce/user/Id';

import createApplication from '@salesforce/apex/PartnerApplicationService.createApplication';
import retrievePartnerUserDetails from '@salesforce/apex/PartnerApplicationService.retrievePartnerUserDetails';
import generateUserResetApplicationProgressStatus from '@salesforce/apex/ExperienceAuthenticationServices.generateUserResetApplicationProgressStatus';
import getCitizenshipTypes from '@salesforce/apex/StudyLocationController.getCitizenshipTypes';

export default class PartnerCreateApplication extends NavigationMixin(LightningElement) { 
    userId = Id;
    @track subtitle = SUBTITLE;

    // TYPE_SELECTION | APPLICATION_DETAILS
    @api message;
    @track formStatus = 'TYPE_SELECTION'; 
    @track applicationType;   
    @track studyDuration;
    @track location = '';
    @track citizenshipType;
    @track citizenshipTypeOptions = [];
    @track newApplicant = {};
    @track newApplication = {};
    @track processingRecords = false;
    @track incompleteForm = true;
    @track availableApplicationTypes;
    @track partnerAccountId;
    @track notKnownToMonashId;
    @track studyTypeUnits;
    @track isStudyDurationDisabled = false;
    @track locationSize = 6;
    isMononymousName = false;
    mononynmHelpText = 'In case the Applicant has a single name without a First or Last Name, please select this';

    @wire (getObjectInfo, {objectApiName: APPLICATION_OBJECT})
    objectInfo;  
    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: LOCATION_FIELD
    })
    locationPicklistValues;
	
	get locationOptions(){
        //retrieve related units
        let locationOptions = [];
        let relatedUnits = [];
        let thisContent = this;

        if(this.studyTypeUnits[this.applicationType]){
            relatedUnits = JSON.stringify(this.studyTypeUnits[this.applicationType]);
        }

        //conditionally add online option if relevant
        this.locationPicklistValues.data.values.forEach(function(option) {
            let includeOption = true;
            
            //ignore south africa or China
            if(option.value == 'South Africa' || option.value == 'China'){
                includeOption = false;
            //ignore online if the selected study type does not have an available unit
            }else if(option.value == 'Online' && thisContent.studyTypeUnits[thisContent.applicationType] === undefined){
                includeOption = false;
            }

            if(includeOption){
                locationOptions.push(option);
            }
        });

        return locationOptions;
    }
	
    @wire(getCitizenshipTypes, {
        campusLocation: '$location'
    })
    citizenshipTypePicklistValues({error, data}) {
        this.citizenshipTypeOptions = [];
        if (data) {
        //remove the INTRNTNL.O option from the list SFTG-3890
        data.forEach(option=> { 
            if(option.value !=='INTRNTNL.O'){
                this.citizenshipTypeOptions.push(option);
            }
        });
        } else if (error) {
            console.log('CitizenshipType fetch issue: ' + JSON.stringify(error,null,2));
            this.citizenshipTypeOptions = [{ label: 'No valid options available', value: ''}];
        }
    }
    get showApplicationSelection(){
        return this.formStatus === 'TYPE_SELECTION';
    }

    get showApplicationDetails(){
        return this.formStatus === 'APPLICATION_DETAILS';
    }

    get durationOfStudyOptions() {
        return [
            { label: 'One Semester', value: '1' },  
            { label: 'Two Semesters', value: '2' },
        ];
    }

    get disableActions(){
        // catch same year birthdate
        let currentYearSelected = false;
        if(this.newApplicant.Birthdate){
            //clear validation
            this.template.querySelectorAll(".birthdateField").forEach(function(element) {        
                element.setCustomValidity("");  
                element.reportValidity();
            });

            let firstItem = 0;
            let enteredYear = this.newApplicant.Birthdate.split('-')[firstItem];
            //show invalid date of birth year if the entered year is the current year
            if(enteredYear === JSON.stringify(new Date().getFullYear())){
                this.template.querySelectorAll(".birthdateField").forEach(function(element) {        
                    element.setCustomValidity("Cannot be the current year.");  
                    element.reportValidity();
                });
                currentYearSelected = true;
            }
        }  

        return this.processingRecords || this.incompleteForm || currentYearSelected;
    }

    validateForm(){  
        let isInputsCorrect = false;
        if(this.newApplicant.Email){      
            isInputsCorrect = [...this.template.querySelectorAll('.emailField')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
        }
        this.incompleteForm = !isInputsCorrect || (!this.isMononymousName && (!this.newApplicant.FirstName || !this.newApplicant.FirstName.trim())) 
                                        || !this.newApplicant.LastName 
                                        || !this.newApplicant.Birthdate || !this.newApplicant.Email 
                                        || !this.location || (this.location !== 'Online' && !this.citizenshipType);
    }

    /* constructor */
    connectedCallback() {
        document.body.setAttribute('style', 'overflow: hidden;');

        //retrieve contact details
        retrievePartnerUserDetails({
            userId: this.userId
        }).then(result => { 
            if(result.STATUS === 'SUCCESS'){     
                this.availableApplicationTypes = [];
                this.availableApplicationTypes = [...JSON.parse(result.ALLOWED_APP_TYPES)];
                this.partnerAccountId = JSON.parse(result.PARTNER_ACCOUNT_ID);
                this.notKnownToMonashId = JSON.parse(result.NOT_KNOWN_TO_MONASH_ID); 
                this.studyTypeUnits = JSON.parse(result.STUDYTYPE_UNITS);
            }
        })
        .catch(generatedUserError =>{
            this.message = 'Error received: code' + generatedUserError.errorCode + ', ' +
                'message ' + generatedUserError;
        });
    }

    navigateToHome(){
        document.body.setAttribute('style', 'overflow: auto;');

        // Use the built-in 'Navigate' method
        this[NavigationMixin.Navigate]({
            // Pass in pageReference
            type: 'comm__namedPage',
            attributes: {
                pageName: 'home'
            }
        });
    }

    backToTypeSelection(event){
        this.isMononymousName = false; 
        this.formStatus = 'TYPE_SELECTION';
    }

    selectApplicationType(event){
        this.formStatus = 'APPLICATION_DETAILS';
        this.applicationType = event.target.dataset.id;
    }   
    
    /*sendToStudent(){ //SFTG-2007 Remove Send to Student option from Partner Modal
        this.createApplicant(true);
    }*/   

    saveAndContinue(){
        this.createApplicant();
    }

    createApplicant(isSendToStudent){
        //flag spinner
        this.processingRecords = true;
        if (this.isMononymousName) {
            this.newApplicant[CONTACT_FIRSTNAME_FIELD.fieldApiName] = '';
            this.newApplicant[CONTACT_LEGAL_FIRSTNAME_FIELD.fieldApiName] = '';
        }
        this.newApplicant.RecordTypeId = this.notKnownToMonashId;

        const fields = this.newApplicant;
        const applicantRecordInput = { apiName: CONTACT_OBJECT.objectApiName, fields };

        //retrieve contact details
        createApplication({
            //isSendToStudent : isSendToStudent, //SFTG-2007 Remove Send to Student option from Partner Modal
            applicantJSON : JSON.stringify(applicantRecordInput),
            partnerAccountId : this.partnerAccountId,
            applicationType : this.applicationType,
            studyDuration : this.studyDuration,
            location : this.location,
            citizenshipType : this.citizenshipType
        }).then(result => { 
            //re-enable sidebar
            document.body.setAttribute('style', 'overflow: auto;');
            //remove spinner
            this.processingRecords = false;

            if(result.STATUS === 'SUCCESS'){
                let applicationResult = JSON.parse(result.APPLICATION);
                //success message when applicant user generated
                if(isSendToStudent){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Successfully created the application. The applicant will receive my.app welcome email to continue their application.',
                            variant: 'success',
                        }),
                    );
                }else{
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Successfully created the application.',
                            variant: 'success',
                        }),
                    );
                }

                // View the generated application record
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: applicationResult.Id,
                        actionName: 'view'
                    }
                });
            }
        })
        .catch(error =>{
            this.message = 'Error received: code' + error.errorCode + ', ' +
                'message ' + error;

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error creating application record',
                    message: error,
                    variant: 'error',
                }),
            );

            //re-enable sidebar
            document.body.setAttribute('style', 'overflow: auto;');

            // Use the built-in 'Navigate' method
            this[NavigationMixin.Navigate]({
                // Pass in pageReference
                type: 'comm__namedPage',
                attributes: {
                    pageName: 'home'
                }
            });

            //remove spinner
            this.processingRecords = false;
        });
    }

    createApplication(applicantId, isSendToStudent){
        const fields = this.newApplication;
        const applicationRecordInput = { apiName: APPLICATION_OBJECT.objectApiName, fields };
        createRecord(applicationRecordInput)
        .then(application => {
            //remove spinner
            this.processingRecords = false;

            if(isSendToStudent){
                this.createApplicationSendToStudent(application.id);
            }else{
                this.createApplicationSaveAndContinue(application.id);
            }
        })
        .catch(error => {
            console.log(JSON.stringify(error));
            //remove spinner
            this.processingRecords = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error creating application record',
                    message: error.body.message,
                    variant: 'error',
                }),
            );
        });
    }

    createApplicationSendToStudent(applicationId){        
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Successfully created the application. The applicant will receive my.app welcome email to continue their application.',
                variant: 'success',
            }),
        );

        //generate the user
        generateUserResetApplicationProgressStatus({
            applicationId : applicationId
        }).then(generatedUser => { 
            console.log(JSON.stringify(generatedUser));
        })
        .catch(generatedUserError =>{
            console.log(JSON.stringify(generatedUserError));
            this.message = 'Error received: code' + generatedUserError.errorCode + ', ' +
                'message ' + generatedUserError.body.message;
        });
        
        // View a custom object record.
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: applicationId,
                actionName: 'view'
            }
        });
    }

    createApplicationSaveAndContinue(applicationId){
        sessionStorage.setItem('localTransfer', applicationId);
        
        // View a custom object record.
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'update-application'
            }
        });
    }

    onchangeNewApplicantFirstName(event) {
        this.newApplicant[CONTACT_FIRSTNAME_FIELD.fieldApiName] = event.detail.value;
        this.newApplicant[CONTACT_LEGAL_FIRSTNAME_FIELD.fieldApiName] = event.detail.value;
        this.validateForm();
    }

    onchangeNewApplicantLastName(event) {
        this.newApplicant[CONTACT_LASTNAME_FIELD.fieldApiName] = event.detail.value;
        this.newApplicant[CONTACT_LEGAL_LASTNAME_FIELD.fieldApiName] = event.detail.value;
        this.validateForm();
    }

    onchangeNewApplicantBirthDate(event) {
        this.newApplicant[CONTACT_BIRTHDATE_FIELD.fieldApiName] = event.detail.value;
        this.validateForm();
    }

    onchangeNewApplicantEmail(event) {
        this.newApplicant[CONTACT_EMAIL_FIELD.fieldApiName] = event.detail.value;
        this.newApplicant[CONTACT_PERSONAL_FIELD.fieldApiName] = event.detail.value;
        this.validateForm();
    }

    onchangeNewApplicationDurationOfStudy(event) {
        this.studyDuration = event.detail.value;
        this.validateForm();
    }
    onchangeNewApplicationLocation(event) {
        this.location = event.detail.value;
        this.isStudyDurationDisabled = false;
        this.locationSize = 6;
        this.studyDuration = '';
        this.newApplication.Duration_of_Study__c = '';

        // disable the stydy duration field and default it to One Semester when Campus Location is Online
        if(this.location === 'Online'){
            this.studyDuration = '1';
            this.newApplication.Duration_of_Study__c = '1';
            this.isStudyDurationDisabled = true;
            this.locationSize = 6;
        }
        
        this.validateForm();
    }

    onchangeCitizenshipType(event) {
        this.citizenshipType = event.detail.value;
        this.validateForm();
    }
    get hasAvailableTypes(){
        return this.availableApplicationTypes && !this.availableApplicationTypes.includes("Exchange") && !this.availableApplicationTypes.includes("Study Abroad");
    }

    get isExchangeAvailable(){
        return this.availableApplicationTypes && this.availableApplicationTypes.includes("Exchange");
    }

    get isStudyAbroadAvailable(){
        return this.availableApplicationTypes && this.availableApplicationTypes.includes("Study Abroad");
    }    

    get isNotOnline(){
        return this.location !== 'Online' && this.location;
    }

    handleMononymousName() {
        this.isMononymousName = !this.isMononymousName;
        this.validateForm();
    }
}