/* base components */
import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
/* custom methods */
import retrieveApplicantCommunityUser from '@salesforce/apex/DocumentChecklistAssessmentServices.retrieveApplicantCommunityUser';
import retrieveChecklistItems from '@salesforce/apex/DocumentChecklistAssessmentServices.retrieveChecklistItems';
import runRules from '@salesforce/apex/DocumentChecklistAssessmentServices.runRules';
import runRulesUpdateEmailResults from '@salesforce/apex/DocumentChecklistAssessmentServices.runRulesUpdateEmailResults';
import isDigitaryIntegrationEnabled from '@salesforce/apex/DigitaryServices.isDigitaryIntegrationEnabled';
import retrieveDocumentPollingInterval from '@salesforce/apex/DigitaryServices.retrieveDocumentPollingInterval';
import myAppDigitaryDocumentRequirementsLabel from '@salesforce/label/c.MyAppDigitaryDocumentRequirements';
/* object field definitions */
import APPLICATION_APPLICANT_FIELD from '@salesforce/schema/Application__c.Applicant__c';
import APPLICATION_AD_HOC_FLAG_FIELD from '@salesforce/schema/Application__c.Checklist_Ad_Hoc_Email_Status__c';
import APPLICATION_CHECKLIST_OUTPUT_FIELD from '@salesforce/schema/Application__c.Checklist_output__c';
import APPLICATION_CHECKLIST_OUTPUT_COMPLETED_FIELD from '@salesforce/schema/Application__c.Checklist_output_completed__c';
import APPLICATION_NAME_FIELD from '@salesforce/schema/Application__c.Name';
/* message channel */
import { publish, MessageContext } from 'lightning/messageService';
import EventBridgeMC from '@salesforce/messageChannel/AuraEventBridge__c';
import APPLICATION_TYPE_OF_STUDY_FIELD from '@salesforce/schema/Application__c.Type_of_Study__c';

export default class DocumentChecklistAssessmentCommunityList extends LightningElement {
    //Get record id when opened on record page
    @api recordId;
    //Get retrieve record from parent component
    @api applicationId;
    //Get retrieve record from parent component
    @api applicantId;

    //Page details
    @api pageTitle;
    @api pageSubTitle; 
    @api checklistItems;
    @api applicationStatus;
    @api application;
    @api wiredApplication;
    @track checklistItemsCount;
    @track disabledSendDocumentReminder;
    @track message;
    isDigitaryIntegrationEnabled = undefined;
    @wire(MessageContext)
    messageContext
    documentPollingInterval;
    pollingIntervalId;
    missingDocIds = [];

    get documentRequirementLabel() {
        let label;
        if(this.isDigitaryIntegrationEnabled !== undefined ) {
            label = this.isDigitaryIntegrationEnabled && this.application?.fields.Type_of_Study__c?.value != 'Graduate Research' ? myAppDigitaryDocumentRequirementsLabel : this.pageSubTitle
        }
        return label;
    }

    // Get Digitary feature switch
    @wire(isDigitaryIntegrationEnabled, {})
    retrieveDigitaryIntegrationFeatureSwitch(result){
        if (result.data !== undefined) {
            this.isDigitaryIntegrationEnabled = result.data;
        } else if (result.error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: result.error?.body?.message,
                    variant: 'error',
                    mode: 'sticky'
                }),
            );
        }
    }

    //Application record wiring
    @wire(getRecord, { recordId: '$applicationId', fields: [APPLICATION_APPLICANT_FIELD,
                                                            APPLICATION_NAME_FIELD,
                                                            APPLICATION_TYPE_OF_STUDY_FIELD,
                                                            APPLICATION_AD_HOC_FLAG_FIELD, 
                                                            APPLICATION_CHECKLIST_OUTPUT_FIELD,
                                                            APPLICATION_CHECKLIST_OUTPUT_COMPLETED_FIELD] })
    retrieveWiredApplication( result ) {
        this.wiredApplication = result;
        if (result.data) {
            this.application = result.data;
            this.disabledSendDocumentReminder = this.application.fields.Checklist_Ad_Hoc_Email_Status__c.value === 'Send to MC';
        } else if (result.error) {
            this.message = result.error;
        }
    }

    get isGraduateResearch() {
        return this.application?.fields.Type_of_Study__c?.value == 'Graduate Research'
    }

    @wire(retrieveApplicantCommunityUser, { applicationId: '$applicationId' })
    applicantCommunityUser;

    /* Constructor after the component is hooked on the parent component */
    connectedCallback() {
        //Set application record id
        if(this.recordId != null){
            this.applicationId = this.recordId;
        }

        //Default send document reminder as disabled
        this.disabledSendDocumentReminder = true;

        //Refresh checklist details
        this.refreshChecklistDetails();
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
        //Check application's ad hoc flag
        if(this.wiredApplication){
            if(this.wiredApplication.data){
                refreshApex(this.wiredApplication);
            }
        }
    }

    //Run rules to refresh checklist details
    refreshChecklistDetails(){
        //Clear checklist items
        this.checklistItems = null;  

        //Refresh wired application data
        this.refreshWiredApplication();

        //Run rules engine
        runRules({
            category : 'Application Assessment',
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

            //Retrieve application status
            this.applicationStatus = this.checklistItems[0].Application__r.Status__c;

            //sending message to parent app to proceed to next step
            if(this.application?.fields.Type_of_Study__c?.value == 'Graduate Research') {
                this.dispatchEvent(new CustomEvent ('checklistloaded'));
                this.checklistItems.forEach(element => { 
                    if(element.Contact_Qualification__r?.Qualification_Type__c != 'Referees' && element.Status__c != 'Submitted') {
                        this.missingDocIds.push(element.Id)
                    }
                });
            }            
        })
        .catch(checklistError =>{
            this.message = 'Error received: code' + checklistError.errorCode + ', ' +
                'message ' + checklistError.body.message;
        });
    }

    //Initiate ad hoc email content calculation
    sendDocumentReminder(){
        //Disable Document Reminder button
        this.disabledSendDocumentReminder = true;

        runRulesUpdateEmailResults({
            category : 'Application Assessment',
            requestApplicationId : this.applicationId
        }).then(docsResult => { 
            this.updateApplicationDocumentCalculation(docsResult);
        })
        .catch(docsError =>{
            this.message = 'Error received: code' + docsError.errorCode + ', ' +
                'message ' + docsError.body.message;
        });        
    }

    //Send an update request to update application's ad hoc email related data
    updateApplicationDocumentCalculation(calculationResult) {
        //Update application with document ad hoc send email request details
        
        //Check if there are checklists tagged as insufficient or requested. If there are then proceed with sending email. If none then show a warning toast.
        let isIncomplete = calculationResult.HASINCOMPLETE;
        if(isIncomplete){
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
                this.message = 'Update successfuly';
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Document request reminder email sent.',
                        variant: 'success'
                    }),
                );
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
        } else {
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

    /**
     * Handles the wired data for polling interval.
     *
     * @wire retrieveDocumentPollingInterval
     * Retrieves the polling interval value or an error.
     *
     * @param {Object} wiredPollingInterval - Contains the result of the wire service.
     * @param {Object} wiredPollingInterval.error - Error object if the wire service fails.
     * @param {number} wiredPollingInterval.data - Polling interval value (in milliseconds) if the wire service succeeds.
     *
     * - If `data` is available: stores the polling interval and sets up periodic polling using `setInterval`.
     * - If `error` occurs: clears the polling interval and stores the error message.
     */
    @wire(retrieveDocumentPollingInterval)
    wiredPollingInterval({ error, data }) {
        if (data) {
            this.documentPollingInterval = data; // Store the polling interval value
            // Start the polling by calling the function every pollingInterval
            this.pollingIntervalId = setInterval(() => {
                this.handleDigitaryDocumentPolling();
            }, this.documentPollingInterval);
        } else if (error) {
            this.documentPollingInterval = undefined;
            this.message = error; // Store error information
        }
    }

    /**
     * Publishes a 'RefreshFiles' event to the Lightning Message Channel.
     * This method is called periodically based on the polling interval.
     * @function handleDigitaryDocumentPolling
     * Prepares the event payload with:
     * - `eventType`: Specifies the type of event (`'RefreshFiles'`).
     * - `applicationId`: The ID of the application being polled.
     *
     * Publishes the event using `publish` to the `EventBridgeMC` message channel.
     */
    handleDigitaryDocumentPolling() {
        // Prepare the payload for the 'RefreshFiles' event
        const payload = {
            eventType: 'RefreshFiles', // Specifies the type of event
            applicationId: this.applicationId
        };
        // Publish the event using the Lightning Message Channel
        publish(this.messageContext, EventBridgeMC, payload);
    }

    /**
     * Lifecycle hook that runs when the component is removed from the DOM.
     * @function disconnectedCallback
     * Clears the polling interval by calling `clearInterval` if the `pollingIntervalId` exists.
     * Prevents continued polling after the component is destroyed.
     */
    disconnectedCallback() {
        // Clear the interval when the component is removed from the DOM
        if (this.pollingIntervalId) {
            clearInterval(this.pollingIntervalId);
        }
    }

    /**
     * capturing the event from child component to check if the files are uploaded or not
     * this is only applicable for Grad Research applications
     */
    onFileSubmitted(event) {
        let docId = event.detail.documentId;
        let status = event.detail.status
        if(status == 'Submitted') {
            const index = this.missingDocIds.indexOf(docId.value);
            if (index !== -1) {
                this.missingDocIds.splice(index, 1);
            }
        }
        else  {
            if(!this.missingDocIds.includes(docId.value)) {
                this.missingDocIds.push(docId.value)
            }            
        }        
    }

    /**
     * method to check if the files are uploaded for all the checklist items for grad research application 
     */
    @api
    checkMissingDocIds() {
        return this.missingDocIds.length == 0
    }
}