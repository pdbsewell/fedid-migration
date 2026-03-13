import { LightningElement, api } from 'lwc';
import getAccountDetails from '@salesforce/apex/OpportunityCollaboratorController.getAccountDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OpportunityCollaborators extends LightningElement {
    selectedAccountId;
    isLoading = false;
    newCollaborator = new Object();
    showTable = false;
    showCollaboratorSelection = true;
    @api allocatedAmount;

    @api
    retrieveCollaborators(){
        if(this.newCollaborator.collaboratorName){
            this.newCollaborator.allocatedAmount = this.allocatedAmount; 
            return this.newCollaborator;
        }else{
            this.displayErrorToast('Please select a Collaborator');
            return null;
        }        
    }

    handleAccountSelection(event){
        this.newCollaborator.collaboratorName = event.detail.data.selectedName;
        this.newCollaborator.collaboratorId = event.detail.data.selectedId;
        this.newCollaborator.relationShipType = 'Internal Organisation'; 
        this.newCollaborator.allocatedAmount = this.allocatedAmount;
        this.newCollaborator.Lead = true;
        this.showCollaboratorSelection = false;
        this.showTable = true;
    }

    remove(event){
        this.showTable = false;
        this.showCollaboratorSelection = true;
        this.newCollaborator = new Object();
    }

    displayErrorToast(errorMessage){
        this.dispatchEvent(
            new ShowToastEvent({
                title : 'ERROR',
                message : errorMessage,
                variant : 'error',
            }),
        )
    }
}