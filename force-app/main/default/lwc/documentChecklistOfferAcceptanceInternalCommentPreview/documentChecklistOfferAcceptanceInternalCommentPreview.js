import { LightningElement, api } from 'lwc';

export default class DocumentChecklistOfferAcceptanceInternalCommentPreview extends LightningElement {
    @api checklist;
    @api notesTitle;
    @api notesContent;
    @api currentUserName;

    /* Constructor after the component is hooked on the parent component */
    connectedCallback() {
    }

    publishComments() {        
        const close = new CustomEvent('submit');
        this.dispatchEvent(close);
    }

    closeWindow() {
        const close = new CustomEvent('close');
        this.dispatchEvent(close);
    }
}