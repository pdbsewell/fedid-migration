/* eslint-disable no-console */
/* lightning libraries */
import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';

/* assets */
import communityMyAppAssets from '@salesforce/resourceUrl/CommunityMyAppAssets';

/* metadata */
import USER_ID from '@salesforce/user/Id';

/* methods */
import retrieveHomeDetails from '@salesforce/apex/MyAppHomeServices.retrieveHomeDetails';
import createApplication from '@salesforce/apex/MyAppHomeServices.createApplication';

export default class MyAppCommunityHome extends NavigationMixin(LightningElement) {
    //retrieve static resource images
    backgroundImage = communityMyAppAssets + '/images/myApp-bg-panel.jpg';
    //backgroundImage = communityMyAppAssets + '/images/myApp-bg-panel-large.jpg';
    //backgroundImage = communityMyAppAssets + '/images/17P-0061-Professional-Development-title-web-banner-2.jpg';
    //backgroundImage = communityMyAppAssets + '/images/19P-0480_Static-Banner_2194x550-1.jpg';
    blurryMonashLogo = communityMyAppAssets + '/images/Monash_Logo_Blurry.png';
    editApplicationLogo = communityMyAppAssets + '/images/editApplication.png';

    //track if assets have been loaded
    @track resourcesReady = false;
    //enable/disable new application button
    @track disabledActionButton
    //All home details
    @track homeDetails;
    notAgentCreated;
    //Submitted tab is disabled
    @track disabledSubmittedApplicationsTab;
    //Submitted applications outstanding checklist count
    @track hasApplicationOutstandingChecklist;
    //Determine if there is an active domestic offer for the contact
    @track hasDomesticOffer;
    sourceSystem;
    //Dynamically open tabs
    @track draftHighlighted;
    @track submittedHighlighted;

    //Respond domestic offer
    @track showRespondForm;
    @track selectedApplicationCoursePreference;

    //Cancel draft application
    @track showCancelForm;
    @track cancelApplicationId;

    @track VALID_ADM_CATEGORIES;
    @track VALID_OUTCOME_STATUS;
    @track VALID_RESPONSE_STATUS;

    @track showAppTypeForm = false;
    get backgroundStyle() {
        return 'background-image: url(' + this.backgroundImage +'); background-position: top left; min-height: 450px;';
    }

    get currentUserFirstName() {
        if (!this.homeDetails.CURRENT_USER_DETAILS.Contact.FirstName || !this.homeDetails.CURRENT_USER_DETAILS.Contact.FirstName.trim()) {
            if (!this.homeDetails.CURRENT_USER_DETAILS.Contact.Preferred_Name__c || !this.homeDetails.CURRENT_USER_DETAILS.Contact.Preferred_Name__c.trim()) {
                return this.homeDetails.CURRENT_USER_DETAILS.LastName;
            }
            return this.homeDetails.CURRENT_USER_DETAILS.Contact.Preferred_Name__c;
        }
        return this.homeDetails.CURRENT_USER_DETAILS.Contact.FirstName;
    }

    //import asset css file
    connectedCallback() {

        Promise.all([
            loadStyle(this, communityMyAppAssets + '/MonashStyling.css')
        ]).then(() => {
            this.resourcesReady = true;
        });

        //Setup statuses
        this.VALID_ADM_CATEGORIES = ['UG-FEE', 'UG-CSP', 'UG-HECS', 'MO-PG-DOM', 'PG-CSP', 'PG-FEE'];
        this.VALID_OUTCOME_STATUS = ['OFFER', 'OFFER-COND'];
        this.VALID_RESPONSE_STATUS = ['PENDING'];

        //Retrieve necessary home data
        this.retrieveApplicationsData();

        //default hightlighted tab
        this.draftHighlighted = true;
    }

    //Retrieve necessary applications data
    retrieveApplicationsData(){
        //Close forms
        this.showRespondForm = false;
        this.showCancelForm = false;
        this.disabledSubmittedApplicationsTab = true;
        this.homeDetails = undefined;
        retrieveHomeDetails({ communityUserId : USER_ID })
        .then(constructorResult => {
            let thisContent = this;
            this.homeDetails = constructorResult;

            var ownerName = this.homeDetails.CURRENT_USER_CREATEDBY;
            this.notAgentCreated =  ownerName ? ownerName.includes('Site Guest User') : true;

            //submitted applications details
            this.disabledSubmittedApplicationsTab = !(this.homeDetails.SUBMITTED_APPLICATIONS);
            this.sourceSystem = this.homeDetails.SOURCE_SYSTEM;
            this.homeDetails.Agent__c
            let outstandingChecklistCount = 0;
            if(this.homeDetails.SUBMITTED_APPLICATIONS){
                this.homeDetails.SUBMITTED_APPLICATIONS.forEach(function(element) {
                    if(thisContent.homeDetails.OUTSTANDING_CHECKLIST){
                        outstandingChecklistCount = outstandingChecklistCount + thisContent.homeDetails.OUTSTANDING_CHECKLIST[element.Id];
                    }
                });
            }
            this.hasApplicationOutstandingChecklist = false;
            if(outstandingChecklistCount > 0){
                this.hasApplicationOutstandingChecklist = true;
            }

            //set hightlighted tab
            this.draftHighlighted = true;
            this.submittedHighlighted = false;
            if(!this.homeDetails.DRAFT_APPLICATIONS && this.homeDetails.SUBMITTED_APPLICATIONS){
                this.draftHighlighted = false;
                this.submittedHighlighted = true;
            }

            if(this.homeDetails.SUBMITTED_APPLICATIONS){
                this.determineHasDomesticOffer();
            }
        })
        .catch(constructorError => {
            //Expose error
            console.log('Error: ' + JSON.stringify(constructorError));
        });
    }

    /* create new application */
    createDraftApplication() {
        //disabled new application button
        this.disabledActionButton = true;
        //set hightlighted tab
        this.draftHighlighted = true;
        this.submittedHighlighted = false;
        //Created and return application id
        createApplication({
            contactId : this.homeDetails.CURRENT_USER_DETAILS.ContactId
        }).then(createApplicationResult => {

            //navigate to the application edit page
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__webPage',
                attributes: {
                    //url: '/admissions/s/signup-declaration?appId=' + createApplicationResult
                    url: '/admissions/s/application/' + createApplicationResult
                }
            }).then(url => {
                window.location.href = url;
            });

            //enable new application button
            //this.disabledActionButton = false;
        })
        .catch(createApplicationError =>{
            //Expose error
            console.log('Error: ' + JSON.stringify(createApplicationError));
            //enable new application button
            this.disabledActionButton = false;
        });
    }

    openRespondForm(event) {
        this.selectedApplicationCoursePreference = event.detail;
        this.showRespondForm = true;
        this.draftHighlighted = false;
        this.submittedHighlighted = true;
        document.body.setAttribute('style', 'overflow: hidden;');
    }

    closeRespondForm() {
        this.showRespondForm = false;
        this.draftHighlighted = false;
        this.submittedHighlighted = true;
        document.body.setAttribute('style', 'overflow: auto;');
    }

    openCancelApplicationForm(event) {
        this.cancelApplicationId = event.detail;
        this.showCancelForm = true;
        document.body.setAttribute('style', 'overflow: hidden;');
    }

    closeCancelApplicationForm() {
        this.showCancelForm = false;
        document.body.setAttribute('style', 'overflow: auto;');
    }

    determineHasDomesticOffer() {
        let thisPage = this;
        this.hasDomesticOffer = false;

        //Iterate through each submitted applications
        this.homeDetails.SUBMITTED_APPLICATIONS.forEach(function(applicationItem) {
            //Iterate through each acp of submitted applications
            if(applicationItem.Application_Course_Preferences__r){
                applicationItem.Application_Course_Preferences__r.forEach(function(acpItem) {

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
                    }

                });
            }
        });
    }

    showMyHomeModal()
    {
        console.log(' whats happening?');
        this.showAppTypeForm = true;
    }
    closeMyHomeModal() {
        console.log('close home modal');
        this.showAppTypeForm = false;
        document.body.setAttribute('style', 'overflow: auto;');
    }
}