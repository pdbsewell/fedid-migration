import { LightningElement, track, api, wire } from 'lwc';
import validateAccess from '@salesforce/apex/AttachIntrlExtrlCollabController.validateAccess';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord } from 'lightning/uiRecordApi';

export default class AttachInternalExternalCollaborator extends LightningElement {
    @api recordId;
    editAccess = false;
    showSpinner = false;

    @wire(getRecord, { recordId: '$recordId', fields: [ 'Opportunity.Name' ]})

    connectedCallback(){
        this.showSpinner = true;
        if(this.recordId != undefined){
            validateAccess({opptyId : this.recordId})
            .then(result => {
                this.editAccess = result;
                // User does not have edit access to the Opportunity so display an Error message and Close the Modal
                if(!this.editAccess){
                    this.dispatchErrorMessageAndCloseModal();
                } 
                this.showSpinner = false;
            })
            .catch(error => {
                this.showSpinner = false;
            });
        }
    }

    dispatchErrorMessageAndCloseModal(){
        this.dispatchEvent(
            new ShowToastEvent({
                title : 'ERROR',
                message : 'You do not have access to edit this Record',  
                variant : 'error',
            }),
        )
        this.closeAction();
    }

    closeAction(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }


}