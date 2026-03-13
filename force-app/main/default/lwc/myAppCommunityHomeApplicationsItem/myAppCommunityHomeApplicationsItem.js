import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
/* assets */
import communityMyAppAssets from '@salesforce/resourceUrl/CommunityMyAppAssets';

export default class MyAppCommunityHomeApplicationsItem extends NavigationMixin(LightningElement) {
    applicationChevron = communityMyAppAssets + '/images/application-chevron.png';

    @api application;
    @api selectedId;
    applicationReviewURL;
    @track disabledActionButton;
    @api appSourceSystem;
    agentPortalApplication;
    graduateResearchApplication;
    applicationType;

    //Comments details
    @api outstandingApplicationChecklistCount;
    @api totalApplicationCommentCount;
    @api unreadApplicationCommentCount;
    
    //Determine if there is an active domestic offer for the contact
    @track hasDomesticOffer;
    @track domesticOfferCountLabel;

    @track VALID_ADM_CATEGORIES;
    @track VALID_OUTCOME_STATUS;
    @track VALID_RESPONSE_STATUS;

    get isApplicationSubmitted() {
        return (
            this.application.Status__c === 'Submitted' || 
            this.application.Status__c === 'Sent for Submission' || 
            this.application.Status__c === 'Review' || 
            this.application.Status__c === 'Submission on Hold (Duplicate Contact)' ||
            this.application.Status__c === 'Agent Declaration Accepted'
        );
    }

    get isSelectedApplicationId() {
        return this.selectedId === this.application.Id;
    }

    get applicationContainerStyle() {
        let blockStyle = '';
        if(this.selectedId === this.application.Id){
            blockStyle = blockStyle + 'selectedApplicationContainer';
        }else{
            blockStyle = blockStyle + 'nonSelectedApplicationContainer';
        }
        return blockStyle;
    }

    get applicationBlockStyle() {
        let blockStyle = 'slds-float_left slds-p-vertical_xx-small slds-p-left_x-small slds-m-top_x-small';
        if(this.selectedId === this.application.Id){
            blockStyle = blockStyle + ' selectedApplicationItem';
        }else{
            blockStyle = blockStyle + ' applicationItem';
        }
        return blockStyle;
    }
    
    get totalActionsCount() {
        let actionsCount = 0;
        
        //Count unread comments
        if(this.unreadApplicationCommentCount){
            if(this.unreadApplicationCommentCount[this.application.Id]){
                actionsCount = actionsCount + this.unreadApplicationCommentCount[this.application.Id];
            }
        }

        return actionsCount;
    }

    get hasOutstandingChecklist() {
        let hasOutstanding = false;
        //Count outstanding checklists
        if(this.outstandingApplicationChecklistCount){
            if(this.outstandingApplicationChecklistCount[this.application.Id]){
                hasOutstanding = true;
            }
        }
       return hasOutstanding;
    }

    get isAgentReviewing() {
        let agentReviewing = false;
        if(this.application.Source_System__c === 'AgentPortal' && this.application.Status__c === 'Applicant Declaration Accepted') {
            agentReviewing = true;
        }
        return agentReviewing;
    }

    /* constructor */
    connectedCallback() {
        this.agentPortalApplication =  this.appSourceSystem=='AgentPortal'?true:false; // this variable needs to be revisited. I don't think it's accurate
        this.graduateResearchApplication = this.application.Type_of_Study__c === 'Graduate Research' ? true : false;
        if(this.application.Graduate_Research_Application_Type__c == 'Admission application only'){
            this.applicationType = 'Admission only';
        }else if(this.application.Graduate_Research_Application_Type__c == 'Scholarship application only'){
            this.applicationType = 'Scholarship only';
        }else{
            this.applicationType = this.application.Graduate_Research_Application_Type__c;
        }
        //Setup statuses
        this.VALID_ADM_CATEGORIES = ['UG-FEE', 'UG-CSP', 'UG-HECS', 'MO-PG-DOM', 'PG-CSP', 'PG-FEE'];
        this.VALID_OUTCOME_STATUS = ['OFFER', 'OFFER-COND'];
        this.VALID_RESPONSE_STATUS = ['PENDING'];
        this.determineHasDomesticOffer();
        this.applicationReviewURL = '/admissions/s/applicationreview/?appId=' + this.application.Id + '&show=details';
    }

    /* always process first draft application */
    editDraftApplication() {
        //disabled new application button
        this.disabledActionButton = true;
        let redURL;
        //setup next page
		let path = '';
		switch (this.application.Submission_Progress__c) {
			case 'Study Preferences':
                path = '/course-selection';
                break;
			case 'Declaration':
                path ='/signup-declaration';
                break;
			case 'Personal Details':
                path = '/personal-details';
                break;
			case 'Credentials':
                path = '/qualifications-work-experience';
                break;
			case 'Scholarship':
                path = '/external-scholarship';
                break;
			case 'Documents':
                path = '/document-upload';
                break;
			case 'Application Fee':
                path = '/payment';
                break;
			case 'Submit':
                path = '/submission-declaration';
                break;
			case 'Review':
                path = '/review';
                break;
			default:
                path = '/signup-declaration';
                break;
		}
        if(this.application.Type_of_Study__c == 'Graduate Research') {
            redURL = 'gradresearchapplication?recordId='
        } else {
            redURL = 'application/'
        }
        //navigate to the application edit page
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                //url: '/admissions/s' + path + '?appId=' + this.application.Id
                url: '/admissions/s/'+ redURL + this.application.Id
            }
        }).then(url => {
            window.location.href = url;
        });
    }

    //Action to change the highlighted application
    changeApplication(){
        if(this.selectedId !== this.application.Id){
            //Create change event
            const applicationChangeEvent = new CustomEvent('applicationchange', {
                detail: this.application.Id
            });
            //Dispatch event
            this.dispatchEvent(applicationChangeEvent);
        }
    }

    /* redirect to the application details page */
    reviewApplicationDetails() {
        //setup next page
		let path = '/applicationreview';

        //navigate to the application edit page
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: '/admissions/s' + path + '?appId=' + this.application.Id + '&show=details'
            }
        }).then(url => {
            window.location.href = url;
        });
    }

    /* redirect to the application documents page */
    reviewApplicationDocuments() {
        //disabled new application button
        this.disabledActionButton = true;

        //setup next page
		let path = '/applicationreview';

        //navigate to the application edit page
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: '/admissions/s' + path + '?appId=' + this.application.Id + '&show=documents'
            }
        }).then(url => {
            window.location.href = url;
        });
    }

    //Open cancel application form
    openCancelApplication() {
        //Create change event
        const cancelApplicationEvent = new CustomEvent('cancelapplication', {
            detail: this.application.Id
        });
        //Dispatch event
        this.dispatchEvent(cancelApplicationEvent);
    }

    determineHasDomesticOffer() {
        let thisPage = this;
        let domesticOfferCount = 0;
        this.hasDomesticOffer = false;
        //Iterate through each acp of submitted application
        if(this.application.Application_Course_Preferences__r){
            this.application.Application_Course_Preferences__r.forEach(function(acpItem) {
                
                //Determine if the acp has a domestic offer
                let showOffer = true;
                if(!acpItem.Admission_Category__c || thisPage.VALID_ADM_CATEGORIES.indexOf(acpItem.Admission_Category__c) < 0) {
                    showOffer = false;
                }
        
                if(!acpItem.Outcome_Status_LOV__c || thisPage.VALID_OUTCOME_STATUS.indexOf(acpItem.Outcome_Status_LOV__r.Value__c) < 0) {
                    showOffer = false;
                }
                
                if(!acpItem.Offer_Response_Status_LOV__c || thisPage.VALID_RESPONSE_STATUS.indexOf(acpItem.Offer_Response_Status_LOV__r.Value__c) < 0) {
                    showOffer = false;
                }
        
                if(acpItem.Offer_Response_Date__c && acpItem.Offer_Response_Status_LOV__c && thisPage.VALID_RESPONSE_STATUS.indexOf(acpItem.Offer_Response_Status_LOV__r.Value__c) >= 0){
                    let dateToday = new Date();
                    let dateExpiry = new Date(acpItem.Offer_Response_Date__c);
        
                    if((dateExpiry.getDate() < dateToday.getDate() && dateExpiry.getMonth() === dateToday.getMonth() && dateExpiry.getYear() === dateToday.getYear()) || 
                        ((dateExpiry.getDate() !== dateToday.getDate() || dateExpiry.getMonth() !== dateToday.getMonth() || dateExpiry.getYear() !== dateToday.getYear()) && dateExpiry < dateToday)) {
                        showOffer = false;
                    }            
                }

                //Roll-up domestic offer flag
                if(showOffer){
                    thisPage.hasDomesticOffer = showOffer;
                    domesticOfferCount = domesticOfferCount + 1;
                }

            });
        }

        //Set offers label
        if(domesticOfferCount > 1){
            this.domesticOfferCountLabel = 'Contains ' + domesticOfferCount + 'offers';
        }else{
            this.domesticOfferCountLabel = 'Contains 1 offer';
        }
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
}