import { LightningElement, track, api } from 'lwc';
import saveCollaborator from '@salesforce/apex/AttachCollaboratorsController.saveCollaborator';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AttachCollaborators extends NavigationMixin(LightningElement) {
    @api opptyRecordId;
    @track collaboratorRecord = { collaboratorType: 'Opportunity', orgId: '', amount: '', lead : false };
    showSpinner = false;
    filter = 'RecordType.DeveloperName IN (\'Faculty\',\'Monash_Organisation\')';

    get options() {
        return [
            { label: 'Internal Collaborator', value: 'Opportunity' },
            { label: 'External Collaborator', value: 'Group' },
        ];
    }

    save(){
        if(this.validateCollaborator()){
            this.collaboratorRecord.opportunityId = this.opptyRecordId;
            this.showSpinner = true;
            saveCollaborator({collaboratorRecord : JSON.stringify(this.collaboratorRecord)})
            .then(result => {
                this.showSpinner = false;
                this.closeModal();
                // Redirect to the Opportunity Detail Page with new Related List Record
                // Unable to use NavigationMixin.Navigate here as the Oppty Related List does not display the new Record 
                // As the Oppty record has not been updated so the Navigating to the Oppty page shows the unrefreshed Related list 
                // Using window href as it refreshes the entire page and displays the updated Related List
                let url = window.location.href;
                let revUrl = url.substring(0, url.indexOf(".com/")+4) + '/lightning/r/Opportunity/'+this.opptyRecordId + '/view';
                window.location.href = revUrl;
            })
            .catch(error => {
                this.showSpinner = false;
                this.displayErrorToast(error.body.message);
            });
        }
    }

    validateCollaborator(){
        // Check for Org
        if(this.collaboratorRecord.orgId === undefined || this.collaboratorRecord.orgId === null || 
           this.collaboratorRecord.orgId === ''){
            // Display Error
            this.displayErrorToast('Please link an Organisation');
            return false;
        }

        // Check for Amount
        if(this.collaboratorRecord.amount === undefined || this.collaboratorRecord.amount === null || 
            this.collaboratorRecord.amount === '' || (this.collaboratorRecord.amount.trim()).length === 0){
             // Display Error
             this.displayErrorToast('Please enter an Amount');
             return false;
        }
        return true;
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

    closeModal(){
        const closeQA = new CustomEvent('close');
        // Dispatches the event.
        this.dispatchEvent(closeQA);
    }
 
    handleOrganisationChange(event){
        this.collaboratorRecord.orgId = event.detail.data.selectedId;
    }

    handleLeadChange(event){
        this.collaboratorRecord.lead = event.target.value;
    }

    handleValueChange(event){
        this.collaboratorRecord.amount = event.target.value;
    }

    handleCollaboratorChange(event){
        this.collaboratorRecord.collaboratorType = event.target.value;
        if(event.target.value == 'Opportunity'){
            this.filter = 'RecordType.DeveloperName IN (\'Faculty\',\'Monash_Organisation\')';
        }else{
            this.filter = 'RecordType.DeveloperName = \'External_Organisation\'';
        }
    }
}