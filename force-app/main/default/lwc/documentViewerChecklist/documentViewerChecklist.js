import { LightningElement, api, track } from 'lwc';
import retrieveChecklistDetails from '@salesforce/apex/DocumentViewerService.retrieveChecklistDetails';

export default class DocumentViewerChecklist extends LightningElement {
    //parameters
    @api applicationId;
    @api opportunityId;
    @api applicantId;
    @api checklistId;
    @api selectedContactDocumentId;
    @api selectedDocumentChecklistId;
    @api pageCount;
    @api splitResult;

    //page controls
    @api checklistApplicant;
    @api checklistApplication;
    @api checklistName;
    @api newChecklistName;
    @api hasNoNewChecklistAccess;
    @track loadingData;
    @track showAlerts;
    @track showChecklistCreatedSuccess;
    @track showFileUpdateSuccess;
    @track showFileUpdateError;
    @track linkedContactQualictn;

    //files data
    @track documentItems;

    //checklist data
    @api checklistsMap;
    @api checklistDocumentTypesMap;

    get isNewDisabled(){
        return (this.hasNoNewChecklistAccess && !this.applicationId);
    }

    /* Constructor after the component is hooked on the parent component */
    connectedCallback() {
        this.showAlerts = false;
        this.showChecklistCreatedSuccess = false;
        this.showFileUpdateSuccess = false;
        this.showFileUpdateError = false;
        this.refreshFiles();

        if(window.location.href.includes('u=1')){
            this.showAlerts = true;
            this.showFileUpdateSuccess = true;
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            this.timeout = setTimeout(function() {
                this.showAlerts = false;
                this.showChecklistCreatedSuccess = false;
                this.showFileUpdateSuccess = false;
                this.showFileUpdateError = false;
            }.bind(this), 3000);
        }
    }

    //Resync checklist details from database
    refreshFiles(){
        this.loadingData = true;
        retrieveChecklistDetails({
            checklistItemId : this.checklistId,
            applicantId : this.applicantId,
            applicationId : this.applicationId,
            opportunityId : this.opportunityId,
            selectedContactDocumentId : this.selectedContactDocumentId
        })
        .then(result => {
            this.checklistApplicant = result.checklist.ApplicantName;
            this.checklistApplication = result.checklist.ApplicationName;
            this.checklistName = result.checklist.ChecklistName;
            this.documentItems = result.documents;
            this.hasNoNewChecklistAccess = !result.hasAcceptanceChecklistNewAccess;
            this.linkedContactQualictn = result.linkedContactQualictn;
            this.loadingData = false;
            
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

            //Determine if there is a gte checklist already associated 
            this.gteExist = result.hasGTE;            
            //Set gte label
            if(this.gteExist){
                this.gteLabel = 'GTE Checklist Exists';
            }else{
                this.gteLabel = 'GTE Checklist Item';
            }

            //Determine if there is a course requirement checklist already associated 
            this.courseRequirementExist = result.hasCourseRequirement;            
            //Set course requirement label
            if(this.courseRequirementExist){
                this.courseRequirementLabel = 'Course Requirement Checklist Exists';
            }else{
                this.courseRequirementLabel = 'Course Requirement Checklist Item';
            }
        })
        .catch((error) => {
            this.message = 'Error received: ' + JSON.stringify(error);
        });
    }

    //comments section
    @api showComments;
    @api commentItems;
    @api isCommentsOpened;
    @track showNewComment;
    @track showMarkAsNotRequiredConfirmation;
    @track commentNotification;
    @track commentNotificationClass;

    //toggle comments section
    showCommentsWindow() {
        this.showComments = true;
        this.isCommentsOpened = true;
        this.showNewComment = false;
        this.showMarkAsNotRequiredConfirmation = false;
    }

    //toggle comments section
    hideCommentsWindow() {
        this.showComments = false;
    }

    //new checklist section
    @api checklistHelpText;
    @api checklistSortOrder;
    @api checklistNewStatus;
    @api checklistType;
    @api checklistUniqueKey;
    @api checklistComments;
    @api disabledChecklistName;
    
    @track gteExist;
    @track gteLabel;
    @track courseRequirementExist;
    @track courseRequirementLabel;
    @track showChecklistCreationForm;

    //Shows the form to create checklist items
    showChecklistForm() {
        //Create Manual Checklist Item
        this.newChecklistName = '';
        this.checklistHelpText = '';
        this.checklistSortOrder = 200;
        this.checklistNewStatus = 'Requested';
        this.checklistType = 'Manual';
        this.checklistUniqueKey = (this.applicationId ? this.applicationId : this.opportunityId) + '-' + this.checklistType + '-' + new Date();        
        this.checklistComments = 'Monash Assessment has requested additional evidence.';
        this.disabledChecklistName = false;
        
        this.showChecklistCreationForm = true;  
    }

    //Handles the checklist functionality menu
    handleMenuAction(event){
        switch(event.detail.value) {
            case 'newChecklist':
                this.showChecklistForm();
                break;
            case 'gteChecklistItem':
                //Create GTE Checklist Item
                this.newChecklistName = 'Genuine Temporary Entrant requirements';
                this.checklistHelpText = '';
                this.checklistSortOrder = 100;
                this.checklistNewStatus = 'Requested';
                this.checklistType = 'GTE';
                this.checklistUniqueKey = (this.applicationId ? this.applicationId : this.opportunityId) + '-' + this.checklistType + '-Manual-' + new Date();
                this.checklistComments = 'Monash Assessment has requested additional evidence.';
                this.disabledChecklistName = true;

                //Show checklist creation form
                this.showChecklistCreationForm = true;
                break;
            case 'courseRequirementChecklistItem':
                //Create Course Requirement Checklist Item
                this.newChecklistName = 'Course Requirements';
                //this.checklistHelpText = 'If the course(s) you are applying for have request specific documentary evidence, please attach them here. E.g. folios, statement of purpose, supplementary Faculty forms, professional registration documents etc.';
                this.checklistHelpText = '';
                this.checklistSortOrder = 65;
                this.checklistNewStatus = 'Requested';
                this.checklistType = 'Course';
                this.checklistUniqueKey = (this.applicationId ? this.applicationId : this.opportunityId) + '-' + this.checklistType + '-Manual-' + new Date();
                this.checklistComments = 'Monash Assessment has requested additional evidence.';
                this.disabledChecklistName = true;

                //Show checklist creation form
                this.showChecklistCreationForm = true;
                break;
            case 'newQualification':
                this.showChecklistForm();
                break;
            default:
                //Default catch-all
        }
    }

    //Hides the form to create checklist items
    hideChecklistForm() {
        this.showChecklistCreationForm = false;
    }

    //Shows the form to create checklist items
    submittedChecklistForm() {
        this.showChecklistCreationForm = false;

        //Show alert
        this.showAlerts = true;
        this.showChecklistCreatedSuccess = true;


        //Refresh checklist details
        this.refreshFiles();

        //Send refresh to refresh files
        if(this.showAlerts){
            const dispatchEvent = new CustomEvent('checklistrefresh');
            this.dispatchEvent(dispatchEvent);
        }
        
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.timeout = setTimeout(function() {   
            this.showAlerts = false;
            this.showChecklistCreatedSuccess = false;
            this.showFileUpdateSuccess = false;
            this.showFileUpdateError = false;
        }.bind(this), 3000);
    }

    //change selected document
    handleSelectDocument(event){
        window.location.replace('/c/DocumentPreviewer.app?cd=' + event.detail.selectedId + '&dc=' + this.checklistId + '&app=' + this.applicationId);
    }

    //event when checklist is changed
    handleUpdatedDocument(event){
        this.showAlerts = true;
        
        //Show success result
        if(event.detail.updateResult){
            this.showFileUpdateSuccess = true;

            //Refresh checklist if changed
            if((event.detail.newChecklist !==  this.checklistId) && !(event.detail.newChecklist === '' && this.checklistId === undefined)){
                //Redirect to checklist detail with no specified file
                if(this.applicationId){
                    window.location.replace('/c/DocumentPreviewer.app?dc=' + this.checklistId + '&u=1&app=' + this.applicationId);
                }
                if(this.opportunityId){
                    window.location.replace('/c/DocumentPreviewer.app?dc=' + this.checklistId + '&u=1&opp=' + this.opportunityId);
                }
                //changed focused checklist id then refresh the files
                //this.checklistId = event.detail.newChecklist;
                //this.refreshFiles();
            }
        }else{
            this.showFileUpdateError = true;
        }

        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.timeout = setTimeout(function() {
            this.showAlerts = false;
            this.showChecklistCreatedSuccess = false;
            this.showFileUpdateSuccess = false;
            this.showFileUpdateError = false;
        }.bind(this), 3000);
    }

    //Detect requested pages
    handleRequestSplit(event){
        const requestedPages = event.detail.requestedPageNumbers;
        //Send back requested page split
        const dispatchEvent = new CustomEvent('requestsplit', {
            detail: { requestedPages }
        });
        this.dispatchEvent(dispatchEvent);
    }

    //Detect split results from parent then send it to the child file component
    @api
    splitResultSent(){
        let thisContent = this;

        //Iterate through each file child then send data to the correct one
        this.template.querySelectorAll("c-document-viewer-checklist-file").forEach(function(element) {  
            if(element.documentItem.contactDocumentId === element.selectedContactDocumentId){
                element.splitResultData = thisContent.splitResult;
                element.splitResultReceived();
            }
        });
    }

    renderedCallback(){
        //Iterate through each file child then send data to the correct one
        this.template.querySelectorAll("c-document-viewer-checklist-file").forEach(function(element) {
            if(element.documentItem.contactDocumentId === element.selectedContactDocumentId){
                element.scrollIntoView({behavior: "smooth"});
            }
        });
    }
}