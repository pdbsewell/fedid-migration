/* base components */
import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { getRecord, updateRecord } from 'lightning/uiRecordApi';


/* custom methods */
import retrieveApplicationRecord from '@salesforce/apex/DocumentChecklistAssessmentServices.retrieveApplicationRecord';
import retrieveChecklistItems from '@salesforce/apex/DocumentChecklistAssessmentServices.retrieveChecklistItems';
import runRules from '@salesforce/apex/DocumentChecklistAssessmentServices.runRules';
import runRulesUpdateEmailResults from '@salesforce/apex/DocumentChecklistAssessmentServices.runRulesUpdateEmailResults';
import retrieveAssessmentAdHocEmailTemplate from '@salesforce/apex/DocumentChecklistAssessmentServices.retrieveAssessmentAdHocEmailTemplate';
import retrieveLastReminderSentDateTime from '@salesforce/apex/DocumentChecklistAssessmentServices.retrieveLastReminderSentDateTime';
import getTaskRecord from '@salesforce/apex/DocumentChecklistAssessmentServices.getTaskRecord';

/* Application */
import APPLICATION_COURSE_PREFERENCE_APPLICATION_FIELD from '@salesforce/schema/Application_Course_Preference__c.Application__c';

/* APPLICANT */
import APPLICANT_FIRST_NAME_FIELD from '@salesforce/schema/Contact.FirstName';
import APPLICANT_LAST_NAME_FIELD from '@salesforce/schema/Contact.LastName';
import APPLICANT_EMAIL_FIELD from '@salesforce/schema/Contact.Email';

export default class DocumentChecklistAssessmentInternalList extends LightningElement {
    //Get record id when opened on record page
    @api recordId;
    //Get retrieve record from parent component
    @api applicationId;
    //Get retrieve record from parent component
    @api applicantId;

    //Page details
    @api checklistItems;
    @api applicationStatus;
    @api application;
    @api wiredApplication;
    @api applicant;
    @api wiredApplicant;
    @api fileColumnCount
    @api viewType;
    @api prioritizeOther;
    @api showHeader;
    @api showRefresh;
    @api showNew;
    @api showDocumentReminder;
    @api showEmailDocumentReminderForm;
    @api adHocEmailTemplate;

    //Document reminder button label
    @track documentReminderTooltip;

    //Page state
    @track listActionLoading;
    @track showChecklistCreationForm;
    @track applicationCoursePreferenceId;
    @track checklistItemsCount;
    @track disabledSendDocumentReminder;
    @track defaultDocumentChecklistRecordTypeId;
    @track message;

    //Checklist creation
    @api disabledChecklistName;
    @api checklistName;
    @api checklistHelpText;
    @api checklistSortOrder;
    @api checklistNewStatus;
    @api checklistType;
    @api checklistUniqueKey;
    @api checklistComments;

    @track gteExist;
    @track gteLabel;

    @track courseRequirementExist;
    @track courseRequirementLabel;

    //Application record wiring
    @wire(getRecord, { recordId: '$applicantId', fields: [APPLICANT_FIRST_NAME_FIELD,
                                                          APPLICANT_LAST_NAME_FIELD,
                                                          APPLICANT_EMAIL_FIELD] })
    retrieveWiredApplicant( result ) {
        this.wiredApplicant = result;
        if (result.data) {
            this.applicant = result.data;
        } else if (result.error) {
            this.message = result.error;
        }
    }
    
    //Application cource preference record wiring
    @wire(getRecord, { recordId: '$applicationCoursePreferenceId', fields: [APPLICATION_COURSE_PREFERENCE_APPLICATION_FIELD] })
    retrieveWiredApplicationCoursePreference( result ) {
        if (result.data) {
            //Check if retrieval of application course preference is successful
            this.applicationId = result.data.fields.Application__c.value;
            //Refresh checklist details
            this.refreshChecklistDetails();
        } else if (result.error) {
            this.message = result.error;
        }
    }

    //Task record wiring
    @wire(getTaskRecord, { recordId: '$recordId' })
    retrieveWiredTask( result ) {
        if (result?.data) {
            if(this.viewType === 'Task')
            {   
                this.applicationCoursePreferenceId = result.data.WhatId;

            }
        } 
        else if(result?.error) {
            this.message = result.error;
        }
    }
    
    /* Constructor after the component is hooked on the parent component */
    connectedCallback() {
        //Application record
        if(this.recordId){
            if(this.viewType === 'Application'){
                this.applicationId = this.recordId;

                //Refresh checklist details
                this.refreshChecklistDetails();
            }
        }

        //Application Course Preference record
        if(this.recordId){
            if(this.viewType === 'Application Course Preference'){   
                this.applicationCoursePreferenceId = this.recordId;
            }
        }
        //Default the reminder button label
        this.documentReminderTooltip = 'Last sent: N/A';

        //Default send document reminder as disabled
        this.disabledSendDocumentReminder = true;

        //Retrieve ad hoc reminder email
        retrieveAssessmentAdHocEmailTemplate()
        .then(templateResult => {
            this.adHocEmailTemplate = templateResult;

            this.message = 'Success response received: 200, ' +
                'message ' + JSON.stringify(templateResult); 
        })
        .catch(templateError =>{
            this.message = 'Error received: code' + templateError.errorCode + ', ' +
                'message ' + templateError.body.message;
        });
    }

    //Retrieve last date time document reminder sent
    retrieveServerDocumentReminderDateTime(){

        //Retrieve last date time document reminder is sent
        retrieveLastReminderSentDateTime({
            applicationId : this.applicationId,
            applicantId : this.applicantId,
            applicationSourceSystem : this.applicationSourceSystem
        })
        .then(lastDateTimeReminderSentResult => {
            let tooltip = 'N/A';
            if(lastDateTimeReminderSentResult.LastSentDateTime !== undefined){
                tooltip = lastDateTimeReminderSentResult.LastSentDateTime;
            }

            this.documentReminderTooltip = 'Last sent: ' + tooltip;

            this.message = 'Success response received: 200, ' +
                'message ' + JSON.stringify(lastDateTimeReminderSentResult); 
        })
        .catch(lastDateTimeReminderSentError =>{
            this.message = 'Error received: code' + lastDateTimeReminderSentError.errorCode + ', ' +
                'message ' + lastDateTimeReminderSentError.body.message;
        });

    }

    //Fire preview document request sending back the event to the parent aura component
    onFilePreview(event) {
        //file preview event
        const filePreviewEvent = new CustomEvent('filepreview', {
            detail: { documentId: event.detail.documentId }
        });
        this.dispatchEvent(filePreviewEvent);
    }

    //Refresh the wired application record
    refreshWiredApplication() {
        //Run rules engine
        retrieveApplicationRecord({
            applicationId : this.applicationId
        }).then(applicationResult => { 
            this.application = applicationResult;
            this.disabledSendDocumentReminder = this.application.Checklist_Ad_Hoc_Email_Status__c === 'Send to MC';
            this.applicantId = this.application.Applicant__c;
            this.applicationSourceSystem = this.application.Source_System__c;            

            //Retrieve date time when last document reminder sent
            this.retrieveServerDocumentReminderDateTime();
            
            this.message = 'Success response received: 200, ' +
                'message ' + JSON.stringify(applicationResult); 
        })
        .catch(applicationError =>{
        this.message = 'Error received: code' + applicationError.errorCode + ', ' +
            'message ' + applicationError.body.message;
        });
    }

    //Run rules to refresh checklist details
    refreshChecklistDetails(){
        //Clear checklist items
        this.checklistItems = null;  

        //Refresh wired application data
        this.refreshWiredApplication();

        //Run rules engine
        runRules({
            category :'Application Assessment',
            requestApplicationId : this.applicationId
        }).then(rulesResult => { 
            //Requery checklist items
            this.refreshChecklistItems();

            this.message = 'Success response received: 200, ' +
                'message ' + JSON.stringify(rulesResult); 
        })
        .catch(rulesError =>{
            this.message = 'Error received: code' + rulesError.errorCode + ', ' +
                'message ' + rulesError.body.message;
        });
    }

    //Refresh checklist items from server
    refreshChecklistItems() {
        //Retrieve latest set of checklist items
        retrieveChecklistItems({
            requestApplicationId : this.applicationId
        }).then(checklistResult => { 
            //Store checklist items from server
            this.checklistItems = checklistResult;

            //Store number of checklist items
            this.checklistItemsCount = this.checklistItems.length;

            //Check checklist details - gte
            for(let checklistCounter = 0; checklistCounter < this.checklistItemsCount; checklistCounter++){
                if(this.checklistItems[checklistCounter].Type__c === 'GTE'){
                    this.gteExist = true;
                }
            }
            
            //Set gte label
            if(this.gteExist){
                this.gteLabel = 'GTE Checklist Exists';
            }else{
                this.gteLabel = 'GTE Checklist Item';
            }
            
            //Check checklist details - course requirement
            for(let checklistCounter = 0; checklistCounter < this.checklistItemsCount; checklistCounter++){
                if(this.checklistItems[checklistCounter].Type__c === 'Course'){
                    this.courseRequirementExist = true;
                }
            }
            
            //Set course requirement label
            if(this.courseRequirementExist){
                this.courseRequirementLabel = 'Course Requirement Checklist Exists';
            }else{
                this.courseRequirementLabel = 'Course Requirement Checklist Item';
            }

            //Retrieve application status
            this.applicationStatus = this.checklistItems[0].Application__r.Status__c;
        })
        .catch(checklistError =>{
            this.message = 'Error received: code' + checklistError.errorCode + ', ' +
                'message ' + checklistError.body.message;
        });
    }

    //Initiate ad hoc email content calculation
    sendDocumentReminder(){
        //Refresh application
        this.refreshWiredApplication();
        
        //Disable Document Reminder button
        this.listActionLoading = true;
        this.disabledSendDocumentReminder = true;

        //Retrieve latest set of checklist items
        retrieveChecklistItems({
            requestApplicationId : this.applicationId
        }).then(checklistResult => { 
            //Store checklist items from server
            this.checklistItems = checklistResult;
            
            //Fire reminder logic
            this.executeReminderType();
        })
        .catch(checklistError =>{
            this.message = 'Error received: code' + checklistError.errorCode + ', ' +
                'message ' + checklistError.body.message;
        });            
    }

    //Determine if the reminder to be sent out is automated or email form
    executeReminderType(){
        //Check if there are insufficient or required checklists
        let hasIncomplete = false;
        this.checklistItems.forEach(function(element) {  
            if(element.Status__c === 'Insufficient' || element.Status__c === 'Requested'){ 
                hasIncomplete = true;
            }
        });

        //Send comms if there are pending and send error toast if no checklist is pending
        //Check if there are checklists tagged as insufficient or requested. If there are then proceed with sending email. If none then show a warning toast.
        if(hasIncomplete === true){
            //Logic for my.app created applications
            if(this.application.Source_System__c === 'my.app' || this.application.Source_System__c === 'Partner'){
                runRulesUpdateEmailResults({
                    category :'Application Assessment',
                    requestApplicationId : this.applicationId
                }).then(docsResult => { 
                    this.listActionLoading = false;
                    this.disabledSendDocumentReminder = true;
                    this.updateApplicationDocumentCalculation(docsResult);
                })
                .catch(docsError =>{
                    this.message = 'Error received: code' + docsError.errorCode + ', ' +
                        'message ' + docsError.body.message;
                });
            }

            //Logic for non my.app created applications
            if(this.application.Source_System__c !== 'my.app' && this.application.Source_System__c !== 'Partner'){
                //Hide body scroll
                document.body.setAttribute('style', 'overflow: hidden;');

                //Show email form
                this.disabledSendDocumentReminder = false;
                this.showEmailDocumentReminderForm = true;                
            }
        }else{
            //Enable header
            this.listActionLoading = false;
            //Enable Document Reminder button
            this.disabledSendDocumentReminder = false;
            
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Email not sent',
                    message: 'At least one checklist item needs to be outstanding to send a Document Reminder email.',
                    variant: 'error'
                }),
            );
        }    
    }

    //Send an update request to update application's ad hoc email related data
    updateApplicationDocumentCalculation(calculationResult) {       
        //Update application with document ad hoc send email request details             
        let record = {
            fields: {
                Id: this.applicationId,
                Checklist_Ad_Hoc_Email_Status__c: 'Send to MC',
                Checklist_output__c: calculationResult.PENDING,
                Checklist_output_completed__c: calculationResult.COMPLETED
            },
        };
        updateRecord(record)
        .then(() => {            
            this.message = 'Update successfully';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Document request reminder email sent.',
                    variant: 'success'
                }),
            );

            //Show email form
            this.disabledSendDocumentReminder = true;
        })
        .catch(error => {
            this.message = JSON.stringify(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Error sending document reminder email.',
                    variant: 'error'
                }),
            );
        });
    }

    //Hides the form to create checklist items
    hideEmailForm() {
        //Enable header
        this.listActionLoading = false;
        //Enable Document Reminder button
        this.showEmailDocumentReminderForm = false;        
        //Show body scroll
        document.body.setAttribute('style', 'overflow: initial;');
    }

    //Shows the form to create checklist items
    showChecklistForm() {
        //Create Manual Checklist Item
        this.checklistName = '';
        this.checklistHelpText = '';
        this.checklistSortOrder = 200;
        this.checklistNewStatus = 'Requested';
        this.checklistType = 'Manual';
        this.checklistUniqueKey = this.applicationId + '-' + this.checklistType + '-' + new Date();        
        this.checklistComments = 'Monash Assessment has requested additional evidence.';
        this.disabledChecklistName = false;
        
        this.showChecklistCreationForm = true;
    }

    //Shows the form to create checklist items
    submittedChecklistForm() {
        this.showChecklistCreationForm = false;

        //Refresh checklist details
        this.refreshChecklistDetails();
    }

    //Hides the form to create checklist items
    hideChecklistForm() {
        this.showChecklistCreationForm = false;
    }

    //Handles the checklist functionality menu
    handleMenuAction(event){
        switch(event.detail.value) {
            case 'gteChecklistItem':
                //Create GTE Checklist Item
                this.checklistName = 'Genuine Temporary Entrant requirements';
                this.checklistHelpText = '';
                this.checklistSortOrder = 100;
                this.checklistNewStatus = 'Requested';
                this.checklistType = 'GTE';
                this.checklistUniqueKey = this.applicationId + '-' + this.checklistType + '-Manual-' + new Date();
                this.checklistComments = 'Monash Assessment has requested additional evidence.';
                this.disabledChecklistName = true;

                //Show checklist creation form
                this.showChecklistCreationForm = true;
                break;
            case 'courseRequirementChecklistItem':
                //Create Course Requirement Checklist Item
                this.checklistName = 'Course Requirements';
                //this.checklistHelpText = 'If the course(s) you are applying for have request specific documentary evidence, please attach them here. E.g. folios, statement of purpose, supplementary Faculty forms, professional registration documents etc.';
                this.checklistHelpText = '';
                this.checklistSortOrder = 65;
                this.checklistNewStatus = 'Requested';
                this.checklistType = 'Course';
                this.checklistUniqueKey = this.applicationId + '-' + this.checklistType + '-Manual-' + new Date();
                this.checklistComments = 'Monash Assessment has requested additional evidence.';
                this.disabledChecklistName = true;

                //Show checklist creation form
                this.showChecklistCreationForm = true;
                break;
            default:
                //Default catch-all
        }
    }
}