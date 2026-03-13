import { LightningElement, api, track } from 'lwc';

export default class DocumentChecklistAssessmentInternalCommentItem extends LightningElement {
    @api assessorView;
    @api commentItem;
    @api isCommentsRead;
    @api forceRead;

    @api isCommentsOpened;
    @track message;

    /* Constructor after the component is hooked on the parent component */
    connectedCallback() {
    }

    toggleComments() {
        this.isCommentsOpened = !this.isCommentsOpened;
    }
}