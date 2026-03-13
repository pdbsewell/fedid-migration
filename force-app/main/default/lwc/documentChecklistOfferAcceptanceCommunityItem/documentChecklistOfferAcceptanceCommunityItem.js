import { LightningElement, wire, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import USER_ID from '@salesforce/user/Id';
import USER_NAME from  '@salesforce/schema/User.Name';
import retrieveChecklistFiles from '@salesforce/apex/DocumentChecklistAcceptanceServices.retrieveChecklistFiles';
import retrieveChecklistItem from '@salesforce/apex/DocumentChecklistAcceptanceServices.retrieveChecklistItem';

export default class DocumentChecklistOfferAcceptanceCommunityItem extends LightningElement {
    
    //Component public variables
    @api opportunityId;
    @api applicantId;
    @api checklistItemId;
    @api checklistItem;
    @api isOtherChecklist;
    @api applicantUserRecord;
    @api fileColumnCount;
    @api isCommentsOpened;
    @track formats = ['bold', 'italic', 'underline', 'strike', 'list', 'indent', 'align'];
    @track originalUrl;
    @track hasChecklistInitiallyLoaded;

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
            fields: [USER_NAME] 
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

    /* Constructor after the component is hooked on the parent component */
    connectedCallback() {
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
                        "displayValue" : "Acceptance: Other acceptance documents",
                        "value" : "AC_OTHR"
                    },
                    "Applicant_Instructions_UI__c":{
                        "displayValue" : null,
                        "value" : "You may include any other documentation for your offer acceptance."
                    },
                    "Opportunity__c":{
                        "displayValue" : null, 
                        "value" : this.opportunityId
                    },
                    "Checklist_Requirement__c":{
                        "displayValue" : null,
                        "value" : "Other Documents"
                    },
                    "Contact__c":{
                        "displayValue" : null,
                        "value" : this.applicantId
                    },
                    "Status__c":{
                        "displayValue" : "Submitted",
                        "value" : "Submitted"
                    },
                    "Rule_DeveloperName__c":{
                        "displayValue" : null,
                        "value" : null
                    },
                }
            }
        }

        //Retrieve checklist documents
        this.refreshFiles();
    }

    //Wire checklist item details to database
    @api wiredChecklistItem;
    @wire (retrieveChecklistItem, {
        checklistId : '$checklistItemId'
    })
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

            //Set checklist status
            this.isSubmitted = false;
            this.isRequested = false;
            this.isInsufficient = false;
            this.isNotRequired = false;
            switch(this.checklistItem.Status__c) {
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

    //Resync checklist details from database
    refreshFiles(){
        retrieveChecklistFiles({
            checklistItemId : this.checklistItemId,
            applicantId : this.applicantId,
            opportunityId : this.opportunityId
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
                if(!this.isOtherChecklist){
                    this.isDocumentSelected = false;
                }
                this.isSubmitted = true;
            }else{
                this.hasDocumentItems = false;
                this.isDocumentSelected = true;
                this.isRequested = true;
            }

            //Re-tag as not required if not required
            if(this.checklistItem){
                if(this.checklistItem.Status__c === 'Requested'){
                    this.isNotRequired = false;
                    this.isSubmitted = false;
                    this.isRequested = true;
                    this.isInsufficient = false;
                }
                if(this.checklistItem.Status__c === 'Submitted'){
                    this.isNotRequired = false;
                    this.isSubmitted = true;
                    this.isRequested = false;
                    this.isInsufficient = false;
                }
                if(this.checklistItem.Status__c === 'Not Required'){
                    this.isNotRequired = true;
                    this.isSubmitted = false;
                    this.isRequested = false;
                    this.isInsufficient = false;
                }
                if(this.checklistItem.Status__c === 'Insufficient'){
                    this.isInsufficient = true;
                    this.isNotRequired = false;
                    this.isSubmitted = false;
                    this.isRequested = false;
                }
            }

            //open documents whenever the checklist status is not submited
            if(!this.isSubmitted && !this.isNotRequired){
                this.isDocumentSelected = true;
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

    get isAdditional(){
        return this.checklistItem.Rule_DeveloperName__c.includes('Additional');
    }
}