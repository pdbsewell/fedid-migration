import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { updateRecord } from 'lightning/uiRecordApi';
import writeNotes from '@salesforce/apex/DocumentChecklistAssessmentServices.writeNotes';

export default class DocumentChecklistAssessmentCommunityCommentList extends LightningElement {
    //Comment related items
    @api checklistItem;
    @api assessorView;
    @api showComments;
    @api commentItems;
    @api applicantUserRecord;
    @api checklistRequirement;
    @api showNewComment;
    @api commentTitle = '';
    @api currentUserName;
    @api isCommentsOpened;

    @track formats = ['bold', 'italic', 'underline', 'strike', 'list', 'indent', 'align'];
    @track commentItemsLength = 0;
    @track hasCommentItems;
    @track hasUnreadCommentItems;
    @track unreadCommentCount;
    @track commentNotification;
    @track commentNotificationClass;
    @track isCommentsSelected = false;
    @track comment = '';
    @track isIncompleteNoteDetails = true;
    @track showCommentPreview;
    @track showLoadingSpinner;
    @track showNewSpinner;
    @track showMarkAsNotRequiredConfirmationSpinner;

    /* Constructor after the component is hooked on the parent component */
    connectedCallback() {
        //Default to not show loading spinner
        this.showLoadingSpinner = false;
        this.showNewSpinner = false;
        this.showMarkAsNotRequiredConfirmationSpinner = false;

        //Clone comment items
        this.commentItemsLength = this.commentItems.length;
        if(this.commentItemsLength !== 0){
            this.hasCommentItems = true;
        }
    }

    commentTitleChange(event){
        this.commentTitle = event.target.value;

        //Setup publish validation
        this.isIncompleteNoteDetails = true;
        if(this.commentTitle && this.comment){
            this.isIncompleteNoteDetails = false;
        }
    }
    
    commentContentChange(event){
        this.comment = event.target.value;

        //Setup publish validation
        this.isIncompleteNoteDetails = true;
        if(this.commentTitle && this.comment){
            this.isIncompleteNoteDetails = false;
        }
    }

    showCommentsPreviewModal() {
        this.showCommentPreview = true;
    }

    hideCommentsPreviewModal() {
        this.showCommentPreview = false;
    }

    submittedCommentsPreviewModal() {
        this.showCommentPreview = false;

        this.newStatus = 'Insufficient';
        this.markAsNotRequiredComment = true;
        this.includeAdditionalComment = true;
        this.showNewSpinner = true;
        this.updateStatusAndWriteComment();
    }

    updateStatusAndWriteComment() {
        //Start loading spinner
        this.showLoadingSpinner = true;
        let record = {
            fields: {
                Id: this.checklistItem.id,
                Status__c: this.newStatus
            },
        };
        updateRecord(record)
        .then(() => {
            //Write notes if comment content is populated
            if(this.markAsNotRequiredComment && this.includeAdditionalComment){
                writeNotes({
                    checklistId : this.checklistItem.id,
                    commentContent : this.comment,
                    noteOwnerId : this.applicantUserRecord.Id
                }).then(result => { 
                    this.message = 'Call successful: ' + result;

                    //Close window and refresh files        
                    this.closeWindow();

                    //Hide loading spinner
                    this.showLoadingSpinner = false;

                    //Show toast for successful status update
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Successfully updated checklist\'s status.',
                            variant: 'success',
                        })
                    );
                })
                .catch(error =>{
                    this.message = 'Error received: ' + error;
                });
            }else if(!this.markAsNotRequiredComment && !this.includeAdditionalComment){
                //Close window and refresh files        
                this.closeWindow();

                //Hide loading spinner
                this.showLoadingSpinner = false;

                if(this.showMarkAsNotRequiredConfirmation){
                    //Show toast for successful status update
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Successfully updated checklist\'s status.',
                            variant: 'success',
                        })
                    );
                } else {
                    //Show toast for successful comment creation
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Successfully requested for documents.',
                            variant: 'success',
                        })
                    );
                }
            }            

            this.markAsNotRequiredComment = '';
            this.commentTitle = '';
            this.comment = '';
            this.showNewSpinner = false;
            this.showMarkAsNotRequiredConfirmationSpinner = false;
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error on data save',
                    message: error,
                    variant: 'error',
                }),
            );

            this.markAsNotRequiredComment = '';
            this.commentTitle = '';
            this.comment = '';
        });
    }

    //Triggered when the application's applicant current user reads an unread note
    onReadNotes() {
        //Count unread comments
        this.unreadCommentCount = this.unreadCommentCount - 1;
        if(this.unreadCommentsCount > 0){
            this.unreadCommentCount = this.unreadCommentsCount;
            this.commentNotification = this.unreadCommentCount + ' Unread';
            this.commentNotificationClass = 'badge_notification';
        }else {
            if(this.commentItemsLength > 1) {
                this.commentNotification = this.commentItemsLength + ' Comments';
                this.commentNotificationClass = 'badge_warning';
            }else if(this.commentItemsLength === 1) {
                this.commentNotification = '1 Comment';
                this.commentNotificationClass = 'badge_warning';
            }    
        }
    }

    /* call parent method to close the window */
    closeWindow() {
        const close = new CustomEvent('close');
        this.dispatchEvent(close);
    }

    //Mark as not required details
    @api markAsNotRequiredComment;
    @api showMarkAsNotRequiredConfirmation;
    @track includeAdditionalComment;
    
    /* toggle add additional comments after marking the checklist as not required */
    includeAdditionalCommentChange(event) {
        this.includeAdditionalComment = event.target.checked;
    }

    markAsNotRequiredCommentContentChange(event){
        this.markAsNotRequiredComment = event.target.value;
    }

    /* Hides the confirmation box when the checklist is attempted to be marked as required */
    hideMarkAsNotRequiredConfirmation() {
        this.showMarkAsNotRequiredConfirmation = false;
    }

    /* updates the checklist item to have a status of not required */
    updateNotRequired() {
        this.newStatus = 'Not Required';
        this.commentTitle = this.currentUserName + ' marked as not required';
        this.comment = this.markAsNotRequiredComment;        
        this.showMarkAsNotRequiredConfirmationSpinner = true;
        this.updateStatusAndWriteComment();
    }
}