import { LightningElement, wire, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import USER_ID from '@salesforce/user/Id';
import USER_NAME from  '@salesforce/schema/User.Name';
import USER_PROFILE_NAME_FIELD from '@salesforce/schema/User.User_Profile_Name__c';
import retrieveChecklistFiles from '@salesforce/apex/DocumentChecklistAssessmentServices.retrieveChecklistFiles';
import retrieveContactQualifications from '@salesforce/apex/EnglishTestApiService.getContactQualificationById';
import {subscribe, unsubscribe, MessageContext, APPLICATION_SCOPE} from 'lightning/messageService'
import EventBridgeMC from '@salesforce/messageChannel/AuraEventBridge__c';
import {checkDigitaryIntegrationAvailability} from "c/documentChecklistUtils";

export default class DocumentEnglishTestChecklistAssessmentCommunityItem extends NavigationMixin(LightningElement) {
    //Component public variables
    @api checklistGroupName
    @api applicationStatus;
    @api applicationStudyType;
    @api applicationId;
    @api applicantId;
    @api checklistItemId;
    @api checklistItem;
    @api isOtherChecklist;
    @api applicantUserRecord;
    @api fileColumnCount;
    @api isCommentsOpened;
    @api applicationName;
    @api checklistItemName;
    @track formats = ['bold', 'italic', 'underline', 'strike', 'list', 'indent', 'align'];
    @track originalUrl;
    @track hasChecklistInitiallyLoaded;
    credentialProviderInfos;
    @track contactQualification;
    @track infoMessage = 'No Uploaded Documents';
    @track englishTestType='';

    //Comment details
    @api showComments;
    @api commentItems;
    @track commentTitle;
    @track commentNotification;
    @track commentNotificationClass;

    //header details
    @track headerIconSize;
    @track isSubmitted;
    @track isRequested;
    @track isInsufficient;
    @track isNotRequired;
    @track documentsToggleDistance;

    //User details
    @track currentUserName;
    @track message;
    @wire(getRecord, {
            recordId: USER_ID,
            fields: [USER_PROFILE_NAME_FIELD, USER_NAME]
        }
    )
    loadCurrentUser( result ) {
        this.wiredUserDetails = result;
        if (result.data) {
            if(result.data.fields.Name.value){
                this.currentUserName = result.data.fields.Name.value;
            }
        } else if (result.error) {
            this.message = 'Error received: code' + result.error.errorCode + ', ' +
                'message ' + result.error.body.message;
        }
    }

    @wire(MessageContext)
    messageContext

    /* Constructor after the component is hooked on the parent component */
    connectedCallback() {
        checkDigitaryIntegrationAvailability(this);
        //Subscribe to message channel so when the message is received, we can refresh files.
        this.subscribeToMessageChannel();
        //Default open files
        this.isDocumentSelected = true;
        this.hasChecklistInitiallyLoaded = false;
        this.documentItems = null;

        //Set column count
        if(this.fileColumnCount){
            this.fileColumnCount = 12 / this.fileColumnCount;
        }

        //Set mode based variables
        this.headerIconSize = 'medium';
        this.documentsToggleDistance = 'slds-p-right_small slds-p-vertical_xx-small slds-border_right slds-m-right_small';

        //Parse other document variable
        this.isOtherChecklist = (this.isOtherChecklist === 'true')

        //Setup other checklist
        if(this.isOtherChecklist) {
            this.checklistItem = {
                "fields":{
                    "Id":{
                        "displayValue" : null,
                        "value" : null
                    },
                    "Allowed_Document_Type__c":{
                        "displayValue" : "Other Document Type",
                        "value" : "OTHERDCTYP"
                    },
                    "Applicant_Instructions_UI__c":{
                        "displayValue" : null,
                        "value" : "You may include any other documentation that supports your application."
                    },
                    "Application__c":{
                        "displayValue" : null,
                        "value" : this.applicationId
                    },
                    "Checklist_Requirement__c":{
                        "displayValue" : null,
                        "value" : "Other Documents"
                    },
                    "Contact__c":{
                        "displayValue" : null,
                        "value" : this.applicantId
                    },
                    "Contact_Qualification__c":{
                        "displayValue" : null,
                        "value" : null
                    },
                    "Rule_DeveloperName__c":{
                        "displayValue" : null,
                        "value" : null
                    },
                    "Status__c":{
                        "displayValue" : this.applicationStatus,
                        "value" : this.applicationStatus
                    },
                    "Work_Experience__c":{
                        "displayValue" : null,
                        "value" : null
                    }
                }
            }
        }

        //Retrieve checklist documents
        this.refreshFiles();
    }

    //Wire checklist item details to database
    @api wiredChecklistItem;
    @wire (getRecord, {
            recordId : '$checklistItemId',
            fields:[
                'Document_Checklist__c.Id',
                'Document_Checklist__c.Checklist_Requirement__c',
                'Document_Checklist__c.Applicant_Instructions_UI__c',
                'Document_Checklist__c.Contact__c',
                'Document_Checklist__c.Allowed_Document_Type__c',
                'Document_Checklist__c.Application__c',
                'Document_Checklist__c.Contact_Qualification__c',
                'Document_Checklist__c.Work_Experience__c',
                'Document_Checklist__c.Rule_DeveloperName__c',
                'Document_Checklist__c.Status__c'
            ]
        }
    )


    loadChecklist(result) {
        this.wiredChecklistItem = result;

        //handle results
        if (result.error) {
            if (Array.isArray(result.error.body)) {
                this.message = result.error.body.map(e => e.message).join(', ');
            } else if (typeof result.error.body.message === 'string') {
                this.message = result.error.body.message;
            }
        } else if (result.data) {
            this.checklistItem = result.data;
            this.getContactQualifications(this.checklistItem.fields.Contact_Qualification__c.value);

            //Set checklist status
            this.isSubmitted = false;
            this.isRequested = false;
            this.isInsufficient = false;
            this.isNotRequired = false;
            switch(this.checklistItem.fields.Status__c.value) {
                case 'Requested':
                    this.isRequested = true;

                    //Default open files on initial checklist load
                    if(this.hasChecklistInitiallyLoaded === false){
                        this.isDocumentSelected = true;
                    }
                    break;
                case 'Submitted':
                    this.isSubmitted = true;

                    //Default closed files on initial checklist load
                    if(this.hasChecklistInitiallyLoaded === false){
                        this.isDocumentSelected = false;
                    }
                    break;
                case 'Insufficient':
                    this.isInsufficient = true;

                    //Default open files on initial checklist load
                    if(this.hasChecklistInitiallyLoaded === false){
                        this.isDocumentSelected = true;
                    }
                    break;
                case 'Not Required':
                    this.isNotRequired = true;

                    //Default closed files on initial checklist load
                    if(this.hasChecklistInitiallyLoaded === false){
                        this.isDocumentSelected = false;
                    }
                    break;
                default:
                //Default catch-all
            }
            //Flag that the constructor already ran
            this.hasChecklistInitiallyLoaded = true;
        }
    }
// Method to manually fetch qualifications based on record ID
    getContactQualifications(contactQualRecordId) {
        retrieveContactQualifications({ recordId: contactQualRecordId })
            .then((data) => {
                this.contactQualification = data;
                this.setTestType(this.contactQualification.Qualification_Name__c);
                this.setDocumentChecklistMessage();
            })
            .catch((error) => {
                this.contactQualification = undefined; // Clear previous data
                console.error('Error retrieving qualification:', error);
            });
    }

    setDocumentChecklistMessage() {
        if(this.contactQualification.Qualification_Type__c === 'English Test'){
            if(this.contactQualification.Qualification_Name__c.includes('LOI')){
                this.infoMessage = 'No Uploaded Documents';
            } else if (this.contactQualification.Source_Channel__c !== 'Manual' && this.contactQualification.English_Test_Number__c){
                this.infoMessage = this.englishTestType === 'PEARSON'
                    ? 'English test has been verified successfully.'
                    : 'English test has been verified successfully, please upload your English test result.';
            } else {
                if (this.validateCompletionDate()) {
                    this.infoMessage = 'Once you have completed your English test, please return to the My.App Documents section to upload your English test.';
                } else {
                    this.infoMessage = 'No uploaded documents, please upload your English test result.';
                }
            }
        } else {
            this.infoMessage = 'No Uploaded Documents';
        }
    }

// Method to check if the completion date is valid (not less than today)
    validateCompletionDate() {
        const today = new Date(); // Current date
        const completionDate = new Date(this.contactQualification.Expected_date_of_completion__c); // Convert date string to Date object

        // Check if the completion date is today or a future date
        return completionDate >= today;
    }

    setTestType(englishTypeName) {
        const testTypeMappings = {
            'IELTS': 'IELTS',
            'Pearson': 'PEARSON',
            'TOEFL': 'TOEFL',
        };

        for (const key in testTypeMappings) {
            if (englishTypeName.includes(key)) {
                this.englishTestType = testTypeMappings[key];
                return; // Exit early once a match is found
            }
        }
    }

    //Resync checklist details from database
    refreshFiles(){
        retrieveChecklistFiles({
            checklistItemId : this.checklistItemId,
            applicantId : this.applicantId,
            applicationId : this.applicationId
        })
            .then(result => {
                this.documentItems = result.documents;
                //Exclude internal files
                let filteredDocumentItems = [];
                this.documentItems.forEach(function(element) {
                    if(element.contactDocument.Internal_Only__c === false){
                        filteredDocumentItems.push(element);
                    }
                });
                this.documentItems = filteredDocumentItems;

                this.documentItemsLength = this.documentItems.length;
                if(this.documentItems.length === 1){
                    this.documentCountNotification = this.documentItems.length + ' Document';
                }else{
                    this.documentCountNotification = this.documentItems.length + ' Documents';
                }

                this.isSubmitted = false;
                this.isRequested = false;
                this.isInsufficient = false;
                this.isNotRequired = false;

                //Identify documents state
                if(this.documentItems.length > 0){
                    this.hasDocumentItems = true;
                    this.isDocumentSelected = true;
                    this.isSubmitted = true;
                }else{
                    this.hasDocumentItems = false;
                    this.isDocumentSelected = true;
                    this.isRequested = true;
                }

                //Re-tag as not required if not required
                if(this.checklistItem){
                    if(this.checklistItem.fields.Status__c.value === 'Requested'){
                        this.isNotRequired = false;
                        this.isSubmitted = false;
                        this.isRequested = true;
                        this.isInsufficient = false;
                    }
                    if(this.checklistItem.fields.Status__c.value === 'Submitted'){
                        this.isNotRequired = false;
                        this.isSubmitted = true;
                        this.isRequested = false;
                        this.isInsufficient = false;
                    }
                    if(this.checklistItem.fields.Status__c.value === 'Not Required'){
                        this.isNotRequired = true;
                        this.isSubmitted = false;
                        this.isRequested = false;
                        this.isInsufficient = false;
                    }
                    if(this.checklistItem.fields.Status__c.value === 'Insufficient'){
                        this.isInsufficient = true;
                        this.isNotRequired = false;
                        this.isSubmitted = false;
                        this.isRequested = false;
                    }
                }

                //Process notes
                this.commentItems = result.notes;
                this.commentItemsLength = this.commentItems.length;

                //Count unread comments
                let unreadCommentsCount = 0;
                this.commentItems.forEach(function(element) {
                    if(element.contentNote.NotesSeen__c === false){
                        unreadCommentsCount++;
                    }
                });

                //Show unread comments only to applicants
                if(unreadCommentsCount > 0){
                    this.unreadCommentCount = unreadCommentsCount;
                    this.commentNotification = this.unreadCommentCount + ' Unread';
                    this.commentNotificationClass = 'badge_notification slds-m-right_x-small slds-m-top_xx-small';
                }else if(this.commentItemsLength > 1) {
                    //Show total number of comments
                    this.commentNotification = this.commentItemsLength + ' Comments';
                    this.commentNotificationClass = 'badge_warning slds-m-right_x-small slds-m-top_xx-small';
                }else if(this.commentItemsLength === 1) {
                    //Show total number of comments only one entry
                    this.commentNotification = '1 Comment';
                    this.commentNotificationClass = 'badge_warning slds-m-right_x-small slds-m-top_xx-small';
                }

                //Refresh parent checklist
                if(!this.isOtherChecklist && this.wiredChecklistItem.data){
                    refreshApex(this.wiredChecklistItem);
                }
            })
            .catch((error) => {
                this.message = 'Error received: ' + JSON.stringify(error);
            });
    }

    //Redirect to the checklist item detail page
    navigateToChecklistItem() {
        // Navigate to the Account home page
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.checklistItemId,
                objectApiName: 'Document_Checklist__c',
                actionName: 'view'
            }
        });
    }

    //Handles the checklist functionality menu
    handleMenuAction(event){
        switch(event.detail.value) {
            case 'RequestDocs':
                //Update checklist status to not required
                this.showNewComment = true;
                this.commentTitle = this.currentUserName + ' added a comment';
                this.showCommentsWindow();
                break;
            case 'MarkNotRequired':
                //Show mark as not required confirmation
                this.showMarkAsNotRequiredConfirmation = true;
                this.showCommentsWindow();
                break;
            default:
            //Default catch-all
        }
    }

    //Document related items
    @api documentItems;
    @track hasDocumentItems;
    @track documentItemsLength = 0;
    @track documentCountNotification;
    @track isDocumentSelected = true;
    @track showFileUploader = false;
    showFileUploadWindow() {
        this.showFileUploader = true;
    }

    //Hide and refresh file uploaded window (after submit)
    hideFileUploadWindow() {
        this.refreshFiles();

        this.showFileUploader = false;
    }

    //Hide file uploaded window
    cancelFileUploadWindow() {
        this.showFileUploader = false;
    }

    //Toggle documents section
    handleDocumentsSectionClick() {
        this.isDocumentSelected = !this.isDocumentSelected;
    }

    //Toggle comments section
    showCommentsWindow() {
        this.showComments = true;

        //Default notes as opened or not
        if(!this.showNewComment && !this.showMarkAsNotRequiredConfirmation){
            this.isCommentsOpened = true;
        }else{
            this.isCommentsOpened = true;
        }

        //Mark all comments as read - if the current user is the applicant
        if(this.applicantUserRecord.Id === USER_ID){
            this.commentItems.forEach(function(element) {
                if(element.contentNote.NotesSeen__c === false){
                    //Update notes to read
                    let record = {
                        fields: {
                            Id: element.contentNote.Id,
                            NotesSeen__c: true
                        },
                    };
                    updateRecord(record)
                        .then(() => {
                            //Update record silently
                        })
                        .catch(error => {
                            this.message = JSON.stringify(error);
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error',
                                    message: 'Error on stamping the comment as read.',
                                    variant: 'error',
                                }),
                            );
                        });

                }
            });
        }
    }

    //Toggle comments section
    hideCommentsWindow() {
        this.showComments = false;
        this.showNewComment = false;
        this.showMarkAsNotRequiredConfirmation = false;

        //Refresh state
        this.refreshFiles();
    }

    onFilePreview(event) {
        //file preview event
        const filePreviewEvent = new CustomEvent('filepreview', {
            detail: { documentId: event.detail.documentId }
        });
        this.dispatchEvent(filePreviewEvent);
    }

    /**
     * Subscribes to the EventBridge message channel.
     *
     * This method sets up a subscription to the EventBridge message channel if there isn't already one.
     * It listens for messages on the channel and handles them using the `handleReceiveEventBridgeMC` method.
     */
    subscribeToMessageChannel() {
        if (!this.subscription) {
            // Subscribe to the EventBridge message channel with a callback to handle received messages
            this.subscription = subscribe(
                this.messageContext,
                EventBridgeMC,
                (message) => this.handleReceiveEventBridgeMC(message),
                {scope: APPLICATION_SCOPE}
            );
        }
    }

    /**
     * Handles incoming messages from the EventBridge message channel.
     *
     * This method processes messages received from the EventBridge channel.
     * If the message indicates that files need to be refreshed (eventType is 'RefreshFiles'),
     * and the application ID and document checklist ID match, it triggers a refresh of the files.
     *
     * @param {Object} message - The message object received from the EventBridge channel.
     */
    handleReceiveEventBridgeMC(message) {
        if (message.eventType === 'RefreshFiles' && message.applicationId === this.applicationId) {
            // Trigger a refresh of files if the message matches the expected criteria
            this.refreshFiles();
        }
    }

    /**
     * Lifecycle hook called when the component is disconnected from the DOM.
     *
     * This method ensures that the component unsubscribes from the EventBridge message channel
     * to avoid memory leaks or unintended behavior when the component is destroyed.
     */
    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    /**
     * Unsubscribes from the EventBridge message channel.
     *
     * This method removes the existing subscription to the EventBridge message channel and clears the subscription reference.
     */
    unsubscribeToMessageChannel() {
        // Unsubscribe from the message channel and clear the subscription
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    get hideDocumentUpload() {
        if(this.checklistItem.fields.Status__c.value === 'Requested' || this.checklistItem.fields.Status__c.value === 'Insufficient') {
            return false;
        } else if(this.applicationStudyType === 'Graduate Research') {
            if(this.commentItems?.length > 0) {
                return this.documentItemsLength > this.commentItems.length //if the comment length is greater than the document length the hide the upload button
            } else {
                return this.documentItemsLength >= 0 //hide the button if the user has uploaded the document
            }
        }
        return false;
    }

    //Check if credential provider is available
    get isCredentialProviderAvailable() {
        return this.applicationStudyType !== 'Graduate Research' && this.credentialProviderInfos?.length > 0;
    }

}