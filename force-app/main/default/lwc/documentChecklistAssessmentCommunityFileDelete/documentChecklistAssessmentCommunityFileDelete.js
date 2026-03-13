import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import removeContactDocumentChecklist from '@salesforce/apex/ContactDocumentServices.removeContactDocumentChecklist';

export default class DocumentChecklistAssessmentCommunityFileDelete extends LightningElement {
    @api documentDetails;
    @track loadingState = false;
    @track message;

    closeWindow() {
        const close = new CustomEvent('cancel');
        this.dispatchEvent(close);
    }

    deleteDocument() {
        //Show loading ui
        this.loadingState = true;

        //delete contact document data
        removeContactDocumentChecklist({
            conDocId : this.documentDetails.contactDocument.Id,
            appId : this.documentDetails.contactDocument.Application__c
        }).then(result => { 
            this.message = result;
            const event = new ShowToastEvent({
                title: 'Document Deleted!',
                variant: 'success',
                message: 'Successfully removed your document.',
            });
            this.dispatchEvent(event);

            //Hide loading ui
            this.loadingState = false;

            //Close the window
            const close = new CustomEvent('close');
            this.dispatchEvent(close);
        })
        .catch(err =>{
            this.message = err;
            const event = new ShowToastEvent({
                title: 'Error creating contact document.',
                variant: 'error',
                message: 'There was an issue removing your document. Please contact us regarding this issue.',
            });
            this.dispatchEvent(event);

            //Hide loading ui
            this.loadingState = false;

            //Close the window
            const close = new CustomEvent('close');
            this.dispatchEvent(close);
        });
    }

    previewFile() {
        //file preview event
        const filePreviewEvent = new CustomEvent('filepreview', {
            detail: { documentId:  this.documentDetails.contentDocument.Id }
        });
        this.dispatchEvent(filePreviewEvent)
    }
}