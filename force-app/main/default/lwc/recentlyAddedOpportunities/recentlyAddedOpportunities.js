import { LightningElement, track , api } from 'lwc';
import getRecentyAddedOpportunities from '@salesforce/apex/OpportunitiesCommonController.getRecentyAddedOpportunities';
import getListView from '@salesforce/apex/OpportunitiesCommonController.getListView';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class RecentlyAddedOpportunities extends NavigationMixin(LightningElement) {
    @track relatedOpportunities = [];
    @track showSpinner = false;
    listViewId = 'recent';
    
    connectedCallback(){
        this.showSpinner = true;
        getRecentyAddedOpportunities()
            .then(result => {
                this.relatedOpportunities = result;
                this.showSpinner = false;
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title : 'ERROR',
                        message : 'An Error has occurred',
                        variant : 'error',
                    }),
                )
                this.showSpinner = false;
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
        this.showSpinner = true;
        getListView()
        .then(result => {
            this.showSpinner = false;
            if(result != null && result != undefined && result != ''){
                this.listViewId = result;   
            }
            this.navigateToListView(this.listViewId);  
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title : 'ERROR',
                    message : 'An Error has occurred',
                    variant : 'error',
                }),
            )
            this.showSpinner = false;
        });    
    }

    navigateToListView(viewId){
        // Navigate to the Oppty object's list view.
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Opportunity',
                actionName: 'list'
            },
            state: {
                filterName: viewId
            }
        });
    }
}