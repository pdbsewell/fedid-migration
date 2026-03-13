import { LightningElement, track, api } from 'lwc';
import getRelatedCases from '@salesforce/apex/OpportunityRelatedCasesController.getRelatedCases';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; 

// datatable columns
const columns = [
    {label: 'Enquiry', fieldName: 'CaseNumber', type: 'text'},
    {label: 'Type', fieldName: 'Type', type: 'text'}, 
    {label: 'Owner', fieldName: 'Case_Owner_String__c', type: 'text'},
    {label: 'Status', fieldName: 'Status', type: 'text'},
    {label: 'Outcome', fieldName: 'MonashCollege_Outcome__c', type: 'text'},
];

export default class OpportunityRelatedCases extends NavigationMixin(LightningElement) {
    @api recordId;
    // reactive variable
    @track cases;
    @track columns = columns;
    displayEnquires = false;

    connectedCallback(){
        getRelatedCases({opportunityId : this.recordId})
        .then(result => {
            this.cases = result;
            if(result.length > 0){
                this.displayEnquires = true;
            }
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title : 'ERROR',
                    message : 'An Error has occurred',
                    variant : 'error',
                }),
            )
        });
    }
}