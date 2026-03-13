import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import APPLICATION_ID_FIELD from '@salesforce/schema/Application__c.Id';
import APPLICATION_NAME_FIELD from '@salesforce/schema/Application__c.Name';
import APPLICATION_STATUS_FIELD from '@salesforce/schema/Application__c.Status__c';
import APPLICATION_FURTHEST_PROGRESS_FIELD from '@salesforce/schema/Application__c.Furthest_Progress__c';
import APPLICATION_SUBMISSION_PROGRESS_FIELD from '@salesforce/schema/Application__c.Submission_Progress__c';
import APPLICATION_CAMPUS_LOCATION_FIELD from '@salesforce/schema/Application__c.Campus_Location__c';
import APPLICATION_STUDY_TYPE_FIELD from '@salesforce/schema/Application__c.Type_of_Study__c';

import SupportEmailAU from '@salesforce/label/c.AustraliaSupportEmail';
import SupportEmailMY from '@salesforce/label/c.MalaysiaSupportEmail';

/* assets */
import communityMyAppAssets from '@salesforce/resourceUrl/CommunityMyAppAssets';

export default class MyAppApplicationFormSidebar extends LightningElement {
    @api applicationRecordId;
    @api applicationRecord;
    @api applicationRecordWired;
    @api typeOfStudy; // This makes the attribute accessible

    @track applicationSteps = [];
    @track applicationName;
    @track furthestStep;
    @track furthestStepNumber;
    @track selectedStep;
    @track recordId
    @track error;
    showDetails;
    campusLocation;
    studyType;
    @track qualificationMenuLabel = '';
    applicationChevron = communityMyAppAssets + '/images/application-chevron.png';


    @track stepMap = { 'Declaration' : 1, 
                       'Personal Details' : 2,
                       'Study Preferences' : 3,
                       'Credentials' : 4,
                       'Scholarship' : 5,
                       'Documents' : 6,
                       'Review' : 7,
                       'Application Fee' : 8,
                       'Submit' : 9};
    @track stepFromNumberMap = { 
        1 : 'Declaration', 
        2 : 'Personal Details',
        3 : 'Study Preferences',
        4 : 'Credentials',
        5 : 'Scholarship',
        6 : 'Documents',
        7 : 'Review',
        8 : 'Application Fee',
        9 : 'Submit'
    };

    @api appRecordCampusLocation;
    @api appRecordCampusLocationItem;
    @api test = 0;
    @wire(getRecord, { recordId: '$recordId', fields: [APPLICATION_ID_FIELD,
                                                       APPLICATION_NAME_FIELD,
                                                       APPLICATION_STATUS_FIELD,
                                                       APPLICATION_FURTHEST_PROGRESS_FIELD,
                                                       APPLICATION_SUBMISSION_PROGRESS_FIELD,
                                                       APPLICATION_CAMPUS_LOCATION_FIELD,
                                                       APPLICATION_STUDY_TYPE_FIELD] })

    applicationRecordItem(result) {
        this.appRecordCampusLocation = result;
     
        if (result.data) {
            this.appRecordCampusLocationItem = result.data;   
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: [APPLICATION_ID_FIELD,
                                                       APPLICATION_NAME_FIELD,
                                                       APPLICATION_STATUS_FIELD,
                                                       APPLICATION_FURTHEST_PROGRESS_FIELD,
                                                       APPLICATION_SUBMISSION_PROGRESS_FIELD,
                                                       APPLICATION_CAMPUS_LOCATION_FIELD,
                                                       APPLICATION_STUDY_TYPE_FIELD] })
    wiredApplicationRecord(result) {
        this.applicationRecordWired = result;
        if(!this.applicationRecord){
            if (result.data) {
                this.applicationRecord = result.data;
                this.studyType = this.applicationRecord.fields.Type_of_Study__c.value;
                this.applicationName = this.applicationRecord.fields.Name.value;
                this.campusLocation = this.applicationRecord.fields.Campus_Location__c.value

                //set furthest step
                this.furthestStep = this.applicationRecord.fields.Furthest_Progress__c.value;
                //update furthest step link
                this.highlightFurthest();

                //set the active step
                this.selectedStep = this.applicationRecord.fields.Submission_Progress__c.value;
                //update highlighted link
                this.highlightActive();

                //if the application is already submitted, redirect it to the review page
                if(this.applicationRecord.fields.Status__c.value !== 'Draft' && this.applicationRecord.fields.Status__c.value !== 'Sent Draft Application to Applicant'){
                    //redirect to the application review page when the status is already submitted or being submitted
                    window.location.href = '/admissions/s/applicationreview?appId=' + this.applicationRecord.fields.Id.value + '&show=details';
                }  

                //return application name
                const changeApplicationNameEvent = new CustomEvent('changeapplicationname', {
                    detail: { applicationName: this.applicationRecord.fields.Name.value }
                });
                this.dispatchEvent(changeApplicationNameEvent);

                this.error = undefined;
            } else if (result.error) {
                this.error = result.error;
                this.applicationRecord = undefined;
            }
        }
    }

    //retrieve static resource images
    backgroundImage = communityMyAppAssets + '/images/myApp-bg-sidepanel.jpg';

    get backgroundStyle() {
        return 'background-image: url(' + this.backgroundImage +');';
    }

    /* Constructor after the component is hooked on the parent component */
    connectedCallback() {
        //set record
        this.recordId = this.applicationRecordId;
        this.qualificationMenuLabel =  this.typeOfStudy === 'Coursework' ? 'qualifications' : 'educational history';
        //default links
        this.applicationSteps.push({step : 1, name : 'Declaration', label : 'privacy declaration', stepclass : 'sidebarStepIcon sidebarStepIconComplete', nameclass : 'sidebarStep sidebarStepComplete', mainclass : 'stepsDefault', isComplete : false, isHidden : false});
        this.applicationSteps.push({step : 2, name : 'Personal Details', label : 'personal details', stepclass : 'sidebarStepIcon sidebarStepIconDefault', nameclass : 'sidebarStep sidebarStepDefault', mainclass : 'stepsDefault', isComplete : false, isHidden : false});
        this.applicationSteps.push({step : 3, name : 'Study Preferences', label : 'Study preferences', stepclass : 'sidebarStepIcon sidebarStepIconDefault', nameclass : 'sidebarStep sidebarStepDefault', mainclass : 'stepsDefault', isComplete : false, isHidden : false});
        this.applicationSteps.push({step : 4, name : 'Credentials', label : this.qualificationMenuLabel, stepclass : 'sidebarStepIcon sidebarStepIconDefault', nameclass : 'sidebarStep sidebarStepDefault', mainclass : 'stepsDefault', isComplete : false, isHidden : false});
        this.applicationSteps.push({step : 5, name : 'Scholarship', label : 'sponsorship / proxy', stepclass : 'sidebarStepIcon sidebarStepIconDefault', nameclass : 'sidebarStep sidebarStepDefault', mainclass : 'stepsDefault', isComplete : false, isHidden : false});
        this.applicationSteps.push({step : 6, name : 'Documents', label : 'documents', stepclass : 'sidebarStepIcon sidebarStepIconDefault', nameclass : 'sidebarStep sidebarStepDefault', mainclass : 'stepsDefault', isComplete : false, isHidden : false});
        this.applicationSteps.push({step : 7, name : 'Review', label : 'review', stepclass : 'sidebarStepIcon sidebarStepIconDefault', nameclass : 'sidebarStep sidebarStepDefault', mainclass : 'stepsDefault', isComplete : false, isHidden : false});
        this.applicationSteps.push({step : 8, name : 'Application Fee', label : 'processing fee', stepclass : 'sidebarStepIcon sidebarStepIconDefault', nameclass : 'sidebarStep sidebarStepDefault', mainclass : 'stepsDefault', isComplete : false, isHidden : false});
        this.applicationSteps.push({step : 9, name : 'Submit', label : 'Student Declaration', stepclass : 'sidebarStepIcon sidebarStepIconDefault', nameclass : 'sidebarStep sidebarStepDefault', mainclass : 'stepsDefault', isComplete : false, isHidden : false});
        this.applicationSteps.push({step : 10, name : 'Receipt', label : 'receipt', stepclass : 'sidebarStepIcon sidebarStepIconDefault', nameclass : 'sidebarStep sidebarStepDefault', mainclass : 'stepsDefault', isComplete : false, isHidden : true});
    }

    highlightFurthest(){
        let thisContent = this;
        if(!thisContent.furthestStep){
            this.furthestStep = 'declaration';
        }
        this.applicationSteps.forEach(function(element) {            
            if(thisContent.furthestStep.toLowerCase() === element.name.toLowerCase()){
                thisContent.furthestStepNumber = element.step;
            }
        });
        this.applicationSteps.forEach(function(element) {
            if(element.step <= thisContent.furthestStepNumber){
                element.stepclass = 'sidebarStepIcon sidebarStepIconComplete';
                element.nameclass = 'sidebarStep sidebarStepComplete';
                element.mainclass = 'stepsComplete';
                element.isComplete = true;
            }
        });
    }

    highlightActive(){
        let thisContent = this;
        this.applicationSteps.forEach(function(element) {  
            if(thisContent.selectedStep.toLowerCase() === element.name.toLowerCase()){
                element.stepclass = 'sidebarStepIcon sidebarStepIconActive';
                element.nameclass = 'sidebarStep sidebarStepActive';
                element.mainclass = 'stepsActive';                
                element.isComplete = false;

                //change highlighted section
                const stepChangeEvent = new CustomEvent('stepchange', {
                    detail: { stepNumber: element.step }
                });
                thisContent.dispatchEvent(stepChangeEvent);                
            }
        });
    }

    selectItem(event){
        if(event.detail.stepNumber <= this.furthestStepNumber){
            //reset highlighted
            this.highlightFurthest();
            //set the active step
            this.selectedStep = event.detail.stepName;
            //update highlighted link
            this.highlightActive();

            let record = {
                fields: {
                    Id: this.applicationRecordId,
                    Submission_Progress__c: this.selectedStep
                },
            };
            updateRecord(record)
            .then(() => {
                //successful application submission progress update
            })
            .catch(error => {
                //unsuccessful application submission progress update
                console.error(JSON.stringify(error));
            });
        }
    }

    @api
    checkFurthest(newStep){
        this.selectedStep = newStep;
        if(this.stepMap[this.selectedStep] > this.furthestStepNumber){
            //set furthest step
            this.furthestStep = this.selectedStep;
            if(this.furthestStep !== 'Receipt'){
                let record = {
                    fields: {
                        Id: this.applicationRecordId,
                        Submission_Progress__c: this.stepFromNumberMap[this.stepMap[this.selectedStep]],
                        Furthest_Progress__c: this.stepFromNumberMap[this.stepMap[this.selectedStep]]
                    },
                };
                updateRecord(record)
                .then(() => {
                    //successful application submission progress update
                })
                .catch(error => {
                    //unsuccessful application submission progress update
                    console.error(JSON.stringify(error));
                });
            }
        }else{
            let record = {
                fields: {
                    Id: this.applicationRecordId,
                    Submission_Progress__c: this.stepFromNumberMap[this.stepMap[this.selectedStep]]
                },
            };
            updateRecord(record)
            .then(() => {
                //successful application submission progress update
            })
            .catch(error => {
                //unsuccessful application submission progress update
                console.error(JSON.stringify(error));
            });
        }

        //reset highlighted
        this.highlightFurthest();
        //update highlighted link
        this.highlightActive();
    }

    retrieveMailToLink(){
        let thisContent = this;
        refreshApex(this.appRecordCampusLocation);        
        
        setTimeout(function(){
            let contactUsSubject = 'mailto:' + SupportEmailAU + '?subject=APPLICATION-' + thisContent.applicationName;
            if(thisContent.appRecordCampusLocationItem){            
                if(getFieldValue(thisContent.appRecordCampusLocationItem, APPLICATION_CAMPUS_LOCATION_FIELD) === 'Malaysia'){
                    contactUsSubject = 'mailto:' + SupportEmailMY + '?subject=APPLICATION-' + thisContent.applicationName;
                }
            }
    
            location.href = contactUsSubject;
        }, 1000);
    }
    //show / hide acp details
    toggleDetails() {
        this.showDetails = !this.showDetails;
        this.template.querySelector("div[data-component=additionalDetailsDesktop]").classList.toggle('acpAdditionalDetailsClosed');
        this.template.querySelector("div[data-component=additionalDetailsMobile]").classList.toggle('acpAdditionalDetailsClosed');
    }

    get showSeeMore(){return true;}

    get seeStatus() {
        return this.showDetails ? 'Need a different application here?' : 'Need a different application here?';
    }

}