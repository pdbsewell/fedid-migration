import { LightningElement, wire, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import USER_ID from '@salesforce/user/Id';
import USER_NAME from  '@salesforce/schema/User.Name';
import USER_PROFILE_NAME_FIELD from '@salesforce/schema/User.User_Profile_Name__c';
import retrieveChecklistFiles from '@salesforce/apex/DocumentChecklistAcceptanceServices.retrieveChecklistFiles';

export default class DocumentChecklistOfferAcceptanceInternalItem extends NavigationMixin(LightningElement) {
    //Get record id when opened on record page
    @api recordId;

    //Component public variables
    @api opportunityId;
    @api applicantId;
    @api checklistItemId;
    @api checklistItem;
    @api isOtherChecklist;
    @api applicantUserRecord;
    @api fileColumnCount;
    @api isCommentsOpened;
    @api viewType;

    @track formats = ['bold', 'italic', 'underline', 'strike', 'list', 'indent', 'align'];
    @track originalUrl;

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
    @track documentsToggleSize;
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

            console.error(JSON.stringify(this.message));
            this.flagError();
        }
    }

    /* Constructor after the component is hooked on the parent component */
    connectedCallback() {
        this.documentItems = null;
        
        //Document Checklist record
        if(this.recordId){
            if(this.viewType === 'Document Checklist'){   
                this.checklistItemId = this.recordId;
            }
        }

        //Default open files
        this.isDocumentSelected = true;
        
        //Set column count
        if(this.fileColumnCount){
            this.fileColumnCount = 12 / this.fileColumnCount;
        }

        //Set mode based variables
        this.headerIconSize = 'small';
        this.documentsToggleSize = 'x-small';
        this.documentsToggleDistance = 'slds-p-right_x-small slds-p-vertical_xx-small slds-border_right slds-m-right_x-small';
        
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
    @wire (getRecord, {
            recordId : '$checklistItemId',
            fields:[ 
                'Document_Checklist__c.Id',
                'Document_Checklist__c.Checklist_Requirement__c',
                'Document_Checklist__c.Applicant_Instructions_UI__c',
                'Document_Checklist__c.Contact__c',
                'Document_Checklist__c.Allowed_Document_Type__c',
                'Document_Checklist__c.Rule_DeveloperName__c',
                'Document_Checklist__c.Opportunity__c',
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

            console.error(JSON.stringify(this.message));
            this.flagError();
        } else if (result.data) {
            this.checklistItem = result.data;
            
            //Retrieve items when checklist record is provided to the component            
            this.applicantId = this.checklistItem.fields.Contact__c.value;
            this.opportunityId = this.checklistItem.fields.Opportunity__c.value;

            //Set checklist status
            this.isSubmitted = false;
            this.isRequested = false;
            this.isInsufficient = false;
            this.isNotRequired = false;
            switch(this.checklistItem.fields.Status__c.value) {
                case 'Requested':
                    this.isRequested = true;
                    break;
                case 'Submitted':
                    this.isSubmitted = true;
                    break;
                case 'Insufficient':
                    this.isInsufficient = true;
                    break;
                case 'Not Required':
                    this.isNotRequired = true;
                    break;
                default:
                    //Default catch-all
            }

            this.refreshFiles();
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
            }

            //If in assessor mode always close the documents
            this.isDocumentSelected = true;

            //Process notes
            this.commentItems = result.notes;
            this.commentItemsLength = this.commentItems.length;
     
            //Show unread comments only to applicants    
            if(this.commentItemsLength > 1) {
                //Show total number of comments
                this.commentNotification = this.commentItemsLength + ' Comments';
                this.commentNotificationClass = 'badge_warning slds-m-right_x-small';
            }else if(this.commentItemsLength === 1) {
                //Show total number of comments only one entry
                this.commentNotification = '1 Comment';
                this.commentNotificationClass = 'badge_warning slds-m-right_x-small';
            }
            
            //Refresh parent checklist
            if(!this.isOtherChecklist && this.wiredChecklistItem.data){
                refreshApex(this.wiredChecklistItem);
            }
        })
        .catch((error) => {
            this.message = 'Error received: ' + JSON.stringify(error);       

            console.error(JSON.stringify(this.message));
            this.flagError();
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
            case 'UploadFile':
                //Show Upload File Form
                this.showFileUploadWindow();
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

    flagError(){
        //file preview event
        const reportErrorEvent = new CustomEvent('reporterror');
        this.dispatchEvent(reportErrorEvent);
    }

    get isAdditional(){
        return this.checklistItem.fields.Rule_DeveloperName__c.value.includes('Additional');
    }
}