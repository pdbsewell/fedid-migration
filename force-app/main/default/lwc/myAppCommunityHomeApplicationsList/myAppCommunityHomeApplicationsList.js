import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
/* assets */
import communityMyAppAssets from '@salesforce/resourceUrl/CommunityMyAppAssets';

export default class MyAppCommunityHomeApplicationsList extends NavigationMixin(LightningElement) {
    editApplicationLogo = communityMyAppAssets + '/images/editApplication.png';

    @api applicationList;
    @api currentUserFirstName;
    @api isSubmitted;
    @api appSourceSystem;


    //Comments details
    @api outstandingApplicationChecklistCount;
    @api totalApplicationCommentCount;
    @api unreadApplicationCommentCount;
    
    @track selectedApplication;

    //Initialize component
    connectedCallback() {
        //Default the selected application to the first application on the list
        if(!this.selectedApplication){
            this.selectedApplication = this.applicationList[0];
        }
    }

    //Action to change the selected application
    handleApplicationChange(event){
        let thisContent = this;
        this.applicationList.forEach(function(element) {
            if(element.Id === event.detail){
                thisContent.selectedApplication = element;
            }
        });
    }

    //Action to open the acp open page
    openRespondForm(event) {
        //Create change event
        const openRespondEvent = new CustomEvent('openrespond', {
            detail: event.detail
        });
        //Dispatch event
        this.dispatchEvent(openRespondEvent);
    }

    //Open cancel application form
    openCancelApplication(event) {
        //Create change event
        const cancelApplicationEvent = new CustomEvent('cancelapplication', {
            detail: event.detail
        });
        //Dispatch event
        this.dispatchEvent(cancelApplicationEvent);
    }
}