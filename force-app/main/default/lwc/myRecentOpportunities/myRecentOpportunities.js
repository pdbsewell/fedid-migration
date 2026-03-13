import { LightningElement, track , api } from 'lwc';
import getMyRelatedOpportunities from '@salesforce/apex/OpportunitiesCommonController.getMyRelatedOpportunities';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; 
import { NavigationMixin } from 'lightning/navigation';

export default class MyRecentOpportunities extends NavigationMixin(LightningElement) {
    @track relatedOpportunities = [];
    connectedCallback(){
        getMyRelatedOpportunities()
            .then(result => {
                this.relatedOpportunities = result;
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
            });
    }

    handleClick(event){
        let recId = event.currentTarget.dataset.id;
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage', 
            attributes: {
                recordId: recId,
                actionName: 'view' 
            }
        }).then(url => {
            //Navigate to new Tab
            window.open(url);
        });
    }
	
	handleViewAll(){
        // Navigate to the Oppty object's recent list view.
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Opportunity',
                actionName: 'list'
            },
            state: {
                filterName: 'Recent'
            }
        });
    }

}