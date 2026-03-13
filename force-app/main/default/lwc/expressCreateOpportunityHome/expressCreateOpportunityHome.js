import { LightningElement, track, api } from 'lwc';
import saveOpportunityAndCollaborators from '@salesforce/apex/OpportunityCreationController.saveOpportunityAndCollaborators';
import { NavigationMixin } from 'lightning/navigation';
import addButton from '@salesforce/resourceUrl/Images';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ExpressCreateOpportunityHome extends NavigationMixin(LightningElement) {
    @api accountRecordId;
    isLoading = false;
    isModalOpen= false;
    currentPageReference = null;
    addButtonImage = addButton + '/Button.svg';
    
    connectedCallback(){
        this.currentPageReference = window.location.href; 
    }

    // On Click of the Save Button
    handleSave(){
        let opportunityCreationForm = this.template.querySelector('c-opportunity-creation-form');
        if(opportunityCreationForm){
            let opportunityRecord = opportunityCreationForm.retrieveOpportunityRecord();
            // If Validation passes, the Control comes back with opptyRecord else null
            if(opportunityRecord !== null){
                // Additional Check for the Collaborator
                // If Validation passes, the Control comes back with collaborator else null
                let opportunityCollaborators = this.template.querySelector('c-opportunity-collaborators');
                let collaborator = opportunityCollaborators.retrieveCollaborators();
                if(collaborator !== null){
                    // Initiate Server Save for both Oppty and Collaborator
                    this.isLoading = true;
                    saveOpportunityAndCollaborators({opportunityRecord : JSON.stringify(opportunityRecord), collaborator : JSON.stringify(collaborator)})
                    .then(result => {
                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: result,
                                objectApiName: "Opportunity",
                                actionName: 'view'
                            }
                        });
                    })
                    .catch(error => {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title : 'ERROR',
                                message : 'An Error has occurred',
                                variant : 'error',
                            }),
                        )
                        this.isLoading = false;
                        this[NavigationMixin.Navigate]({
                            "type": "standard__webPage",
                            "attributes": {
                                "url": this.currentPageReference
                            }
                        });
                    });
                }
            } 
        }
    }

    openModal(){
        this.isModalOpen = true;
    }

    closeModal(){
        this.isModalOpen = false;
    }

    handleAmountChange(event){
        let opportunityCollaborators = this.template.querySelector('c-opportunity-collaborators');
        opportunityCollaborators.allocatedAmount = event.detail.amount;
    }
}