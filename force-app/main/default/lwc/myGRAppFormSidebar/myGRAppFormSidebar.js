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
import APPLICATION_APPLICATION_TYPE_FIELD from '@salesforce/schema/Application__c.Graduate_Research_Application_Type__c';

import SupportEmailAU from '@salesforce/label/c.AustraliaSupportEmail';
import SupportEmailMY from '@salesforce/label/c.MalaysiaSupportEmail';

/* assets */
import communityMyAppAssets from '@salesforce/resourceUrl/CommunityMyAppAssets';
import getGradResearchStepsAndDeleteContactQualification from '@salesforce/apex/MyAppWithoutSharingController.getGradResearchStepsAndDeleteContactQualification';

export default class MyGRAppFormSidebar extends LightningElement {
    @api applicationRecordId;
    @api applicationRecord;
    @api applicationRecordWired;
    
    @track applicationSteps = [];
    @track applicationName;
    @track furthestStep;
    @track furthestStepNumber;
    @track selectedStep;
    @track recordId
    @track error;
    activeStep
    showSpinner
    showDetails;
    campusLocation;
    studyType;
    applicationType;
    applicationChevron = communityMyAppAssets + '/images/application-chevron.png';
    stepResetToPersonalDetails

    @track stepMap = {};

    @track stepFromNumberMap = {};
    
    @api appRecordCampusLocation;
    @api appRecordCampusLocationItem;
    @api test = 0;
    @wire(getRecord, { recordId: '$applicationRecordId', fields: [APPLICATION_ID_FIELD,
                                                       APPLICATION_NAME_FIELD,
                                                       APPLICATION_STATUS_FIELD,
                                                       APPLICATION_FURTHEST_PROGRESS_FIELD,
                                                       APPLICATION_SUBMISSION_PROGRESS_FIELD,
                                                       APPLICATION_CAMPUS_LOCATION_FIELD,
                                                       APPLICATION_STUDY_TYPE_FIELD,
                                                       APPLICATION_APPLICATION_TYPE_FIELD] })

    applicationRecordItem(result) {
        this.appRecordCampusLocation = result;
     
        if (result.data) {
            this.appRecordCampusLocationItem = result.data;   
        }
    }

    @wire(getRecord, { recordId: '$applicationRecordId', fields: [APPLICATION_ID_FIELD,
                                                       APPLICATION_NAME_FIELD,
                                                       APPLICATION_STATUS_FIELD,
                                                       APPLICATION_FURTHEST_PROGRESS_FIELD,
                                                       APPLICATION_SUBMISSION_PROGRESS_FIELD,
                                                       APPLICATION_CAMPUS_LOCATION_FIELD,
                                                       APPLICATION_STUDY_TYPE_FIELD,
                                                       APPLICATION_APPLICATION_TYPE_FIELD] })
    wiredApplicationRecord(result) {
        this.applicationRecordWired = result;
        if(!this.applicationRecord){
            if (result.data) {
                this.applicationRecord = result.data;
                this.studyType = this.applicationRecord.fields.Type_of_Study__c.value;
                if(this.applicationRecord.fields.Graduate_Research_Application_Type__c.value != ''){
                    if(this.applicationRecord.fields.Graduate_Research_Application_Type__c.value == 'Admission application only'){
                        this.applicationType = 'Admission only';
                    }else if(this.applicationRecord.fields.Graduate_Research_Application_Type__c.value == 'Scholarship application only'){
                        this.applicationType = 'Scholarship only';
                    }else{
                        this.applicationType = this.applicationRecord.fields.Graduate_Research_Application_Type__c.value;
                    }
                }
                this.applicationName = this.applicationRecord.fields.Name.value;
                this.campusLocation = this.applicationRecord.fields.Campus_Location__c.value

                //set furthest step
                this.furthestStep = this.applicationRecord.fields.Furthest_Progress__c.value;
                this.getGRSteps();
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

    highlightFurthest(){
        let thisContent = this;
        if(!thisContent.furthestStep){
            this.furthestStep = 'declaration';
        }
        if(this.stepResetToPersonalDetails) {
            this.furthestStep = 'personal details'
            this.stepResetToPersonalDetails = null
        }
        this.applicationSteps.forEach(function(element) {            
            if(thisContent.furthestStep.toLowerCase() === element.name.toLowerCase()){
                thisContent.furthestStepNumber = element.step;
            }
        });
        this.applicationSteps.forEach(function(element) {
            if(element.step <= thisContent.furthestStepNumber && element.name != 'Validate & Submit'){
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
            if(this.selectedStep != 'Validate & Submit') {
                this.applicationSteps.forEach(function(element) {  
                    if(element.name == 'Validate & Submit'){
                        element.stepclass = 'sidebarStepIcon sidebarStepIconDefault';
                        element.nameclass = 'sidebarStep sidebarStepDefault';
                        element.mainclass = 'stepsDefault';                
                        element.isComplete = false;       
                    }
                });
            }             
            
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

    //initializing the step names for grad research side bar component
    setSteps(stepNames) {
        var step1 = ['Declaration','Personal Details','Application Details','Research Program','English Proficiency', 'Qualifications', 'Awards, Prizes & Scholarship','Employment & Research Experience']      
        var step2 = ['Additional Supporting Information','Referees','Documents','Validate & Submit']
        var totalNumberOfSteps = step1.length + stepNames?.length + step2.length
        var stepCounter = 1;
        var stepMap = {}
        var stepFromValueMap = {}
        for(stepCounter = 1; stepCounter<=step1.length; stepCounter++ ) {
            stepMap[stepCounter] = step1[stepCounter-1]
            stepFromValueMap[step1[stepCounter-1]] = stepCounter
        }
        if(stepNames != undefined) {
            var count = 0
            for(stepCounter = step1.length+1; stepCounter<=step1.length + stepNames.length; stepCounter++ ) {                
                stepMap[stepCounter] = stepNames[count]
                stepFromValueMap[stepNames[count]] = stepCounter
                count++
            }
        }
        
        var countlast = 0;
        for(stepCounter = step1.length + stepNames?.length + 1; stepCounter<=totalNumberOfSteps; stepCounter++) {            
            stepMap[stepCounter] = step2[countlast]
            stepFromValueMap[step2[countlast]] = stepCounter
            countlast++
        }
        this.stepFromNumberMap = stepMap
        this.stepMap = stepFromValueMap
        
        this.applicationSteps.push({step : 1, name : 'Declaration', label : 'privacy declaration', stepclass : 'sidebarStepIcon sidebarStepIconComplete', nameclass : 'sidebarStep sidebarStepComplete', mainclass : 'stepsDefault', isComplete : false, isHidden : false});
        this.applicationSteps.push({step : 2, name : 'Personal Details', label : 'personal details', stepclass : 'sidebarStepIcon sidebarStepIconDefault', nameclass : 'sidebarStep sidebarStepDefault', mainclass : 'stepsDefault', isComplete : false, isHidden : false});
        this.applicationSteps.push({step : 3, name : 'Application Details', label : 'application details', stepclass : 'sidebarStepIcon sidebarStepIconDefault', nameclass : 'sidebarStep sidebarStepDefault', mainclass : 'stepsDefault', isComplete : false, isHidden : false});
        this.applicationSteps.push({step : 4, name : 'Research Program', label : 'research program', stepclass : 'sidebarStepIcon sidebarStepIconDefault', nameclass : 'sidebarStep sidebarStepDefault', mainclass : 'stepsDefault', isComplete : false, isHidden : false});
        this.applicationSteps.push({step : 5, name : 'English Proficiency', label : 'english proficiency', stepclass : 'sidebarStepIcon sidebarStepIconDefault', nameclass : 'sidebarStep sidebarStepDefault', mainclass : 'stepsDefault', isComplete : false, isHidden : false});
        this.applicationSteps.push({step : 6, name : 'Qualifications', label : 'qualifications', stepclass : 'sidebarStepIcon sidebarStepIconDefault', nameclass : 'sidebarStep sidebarStepDefault', mainclass : 'stepsDefault', isComplete : false, isHidden : false});
        this.applicationSteps.push({step : 7, name : 'Awards, Prizes & Scholarship', label : 'awards, prizes & scholarship', stepclass : 'sidebarStepIcon sidebarStepIconDefault', nameclass : 'sidebarStep sidebarStepDefault', mainclass : 'stepsDefault', isComplete : false, isHidden : false});
        this.applicationSteps.push({step : 8, name : 'Employment & Research Experience', label : 'employment & research experience', stepclass : 'sidebarStepIcon2 sidebarStepIconDefault2', nameclass : 'sidebarStep sidebarStepDefault', mainclass : 'stepsDefault', isComplete : false, isHidden : false});
        if(this.stepMap['Publications'])
            this.applicationSteps.push({step : this.stepMap['Publications'], name : 'Publications', label : 'publications', stepclass : 'sidebarStepIcon sidebarStepIconDefault', nameclass : 'sidebarStep sidebarStepDefault', mainclass : 'stepsDefault', isComplete : false, isHidden : false});
        if(this.stepMap['Creative Works'])
            this.applicationSteps.push({step : this.stepMap['Creative Works'], name : 'Creative Works', label : 'creative works', stepclass : 'sidebarStepIcon sidebarStepIconDefault', nameclass : 'sidebarStep sidebarStepDefault', mainclass : 'stepsDefault', isComplete : false, isHidden : false});
        if(this.stepMap['Music'])
            this.applicationSteps.push({step : this.stepMap['Music'], name : 'Music', label : 'music', stepclass : 'sidebarStepIcon sidebarStepIconDefault', nameclass : 'sidebarStep sidebarStepDefault', mainclass : 'stepsDefault', isComplete : false, isHidden : false});
        if(this.stepMap['Theatre Performance'])
            this.applicationSteps.push({step : this.stepMap['Theatre Performance'], name : 'Theatre Performance', label : 'theatre performance', stepclass : 'sidebarStepIcon sidebarStepIconDefault', nameclass : 'sidebarStep sidebarStepDefault', mainclass : 'stepsDefault', isComplete : false, isHidden : false});
        if(this.stepMap['Exhibitions'])
            this.applicationSteps.push({step : this.stepMap['Exhibitions'], name : 'Exhibitions', label : 'exhibitions', stepclass : 'sidebarStepIcon sidebarStepIconDefault', nameclass : 'sidebarStep sidebarStepDefault', mainclass : 'stepsDefault', isComplete : false, isHidden : false});
        if(this.stepMap['Agent'])
            this.applicationSteps.push({step : this.stepMap['Agent'], name : 'Agent', label : 'agent', stepclass : 'sidebarStepIcon sidebarStepIconDefault', nameclass : 'sidebarStep sidebarStepDefault', mainclass : 'stepsDefault', isComplete : false, isHidden : false});
        if(this.stepMap['Additional Supporting Information'])
            this.applicationSteps.push({step : this.stepMap['Additional Supporting Information'], name : 'Additional Supporting Information', label : 'additional supporting information', stepclass : 'sidebarStepIcon sidebarStepIconDefault', nameclass : 'sidebarStep sidebarStepDefault', mainclass : 'stepsDefault', isComplete : false, isHidden : false});
        if(this.stepMap['Referees'])
            this.applicationSteps.push({step : this.stepMap['Referees'], name : 'Referees', label : 'referees', stepclass : 'sidebarStepIcon sidebarStepIconDefault', nameclass : 'sidebarStep sidebarStepDefault', mainclass : 'stepsDefault', isComplete : false, isHidden : false});
        if(this.stepMap['Documents'])
            this.applicationSteps.push({step : this.stepMap['Documents'], name : 'Documents', label : 'documents', stepclass : 'sidebarStepIcon sidebarStepIconDefault', nameclass : 'sidebarStep sidebarStepDefault', mainclass : 'stepsDefault', isComplete : false, isHidden : false});
        if(this.stepMap['Validate & Submit'])
            this.applicationSteps.push({step : this.stepMap['Validate & Submit'], name : 'Validate & Submit', label : 'validate & submit', stepclass : 'sidebarStepIcon sidebarStepIconDefault', nameclass : 'sidebarStep sidebarStepDefault', mainclass : 'stepsDefault', isComplete : false, isHidden : false, isBlocked : true});

        //sending the step names to the parent compoenent
        const selectItemEvent = new CustomEvent('loadapp', {
            detail: { 
                stepMap:  this.stepFromNumberMap
            }
        });
        this.dispatchEvent(selectItemEvent);  

        //update furthest step link
        this.highlightFurthest();

        //set the active step
        this.selectedStep = this.activeStep == undefined ? this.applicationRecord.fields.Submission_Progress__c.value : this.activeStep;
        //update highlighted link
        this.highlightActive();

        //if the application is already submitted, redirect it to the review page
        if(this.applicationRecord.fields.Status__c.value !== 'Draft' && this.applicationRecord.fields.Status__c.value !== 'Sent Draft Application to Applicant'){
            //redirect to the application review page when the status is already submitted or being submitted
            window.location.href = '/admissions/s/applicationreview?appId=' + this.applicationRecord.fields.Id.value + '&show=details';
        }  

        //fire the application name to parent
        const changeApplicationNameEvent = new CustomEvent('changeapplicationname', {
            detail: { applicationName: this.applicationRecord.fields.Name.value }
        });
        this.dispatchEvent(changeApplicationNameEvent);

        this.error = undefined;  
    }

    @api
    callbackFromCourseToVerifySteps(activeStep){
        this.applicationSteps = []
        this.furthestStepNumber = 2
        this.checkFurthest(activeStep)
        this.activeStep = activeStep
        if(activeStep == 'Personal Details') {
            this.stepResetToPersonalDetails = true
        }
        this.getGRSteps()
    } 
    //getting the additional steps from the getGradResearchStepsAndDeleteContactQualification method
    getGRSteps() {
        getGradResearchStepsAndDeleteContactQualification({ 
            'applicationId':this.applicationRecordId
        }).then(response => {
            this.setSteps(response)
            this.showSpinner = false
            
        }).catch((error) => {
            this.showSpinner = false
        })
    }
}