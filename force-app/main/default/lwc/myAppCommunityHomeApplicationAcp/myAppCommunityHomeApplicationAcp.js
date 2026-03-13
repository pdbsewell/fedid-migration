import { LightningElement, api, track } from 'lwc';

/* assets */
import communityMyAppAssets from '@salesforce/resourceUrl/CommunityMyAppAssets';

export default class MyAppCommunityHomeApplicationAcp extends LightningElement {
    applicationChevron = communityMyAppAssets + '/images/application-chevron.png';
    
    //retrieve static resource images
    offerMadeIcon = communityMyAppAssets + '/images/acp-approved.svg';
    assessingIcon = communityMyAppAssets + '/images/acp-pending.svg';
    unsuccessfulIcon = communityMyAppAssets + '/images/acp-unsuccessful.svg';
    number1 = communityMyAppAssets + '/images/acp-1.svg';
    number2 = communityMyAppAssets + '/images/acp-2.svg';
    number3 = communityMyAppAssets + '/images/acp-3.svg';
    number4 = communityMyAppAssets + '/images/acp-4.svg';
    number5 = communityMyAppAssets + '/images/acp-5.svg';

    @api applicationCoursePreference;
    @track applicationCoursePreferenceStatus;

    @track showDetails;
    @track successAcpStatusList;
    @track inProgressAcpStatusList;
    @track errorAcpStatusList;

    @track highLevelStatus;
    @track VALID_ADM_CATEGORIES;
    @track VALID_OUTCOME_STATUS;
    @track VALID_RESPONSE_STATUS;

    @track showRespondForm;
    @track isGraduateResearch = false;
    @track isAdmission  = false;
    @track isScholarship = false;
    attendanceModeDesc = '';

    /* constructor */
    connectedCallback() {
        this.showDetails = false;
        this.applicationCoursePreferenceStatus = 'Draft';
        this.highLevelStatus = 'Draft';
        this.showRespondForm = false;

        //Setup statuses
        this.VALID_ADM_CATEGORIES = ['UG-FEE', 'UG-CSP', 'UG-HECS', 'MO-PG-DOM', 'PG-CSP', 'PG-FEE'];
        this.VALID_OUTCOME_STATUS = ['OFFER', 'OFFER-COND'];
        this.VALID_RESPONSE_STATUS = ['PENDING'];

        //set type of study and application type
        if(this.applicationCoursePreference.Application__r.Type_of_Study__c == 'Graduate Research'){
            this.isGraduateResearch = true;
            if(this.applicationCoursePreference.Application__r.Graduate_Research_Application_Type__c == 'Admission application only'){
                    this.isAdmission = true;
            }

            if(this.applicationCoursePreference.Application__r.Graduate_Research_Application_Type__c == 'Scholarship application only'){
                    this.isScholarship = true;
            }
        }



        //retrieve mapping value
        if(this.applicationCoursePreference.Outcome_Status_LOV__c){
            //Set status label
            this.applicationCoursePreferenceStatus = this.applicationCoursePreference.Outcome_Status_LOV__r.Applicant_Value__c;
            if(this.applicationCoursePreference.Outcome_Status_LOV__r.Value__c === 'OFFER-COND') {
                if(this.applicationCoursePreference.Documentation_Status_LOV__c && this.applicationCoursePreference.Conditional_Offer_Status_LOV__c && this.applicationCoursePreference.Conditional_Offer_Status_LOV__r.Value__c === 'WAIVED') {
                    if(this.applicationCoursePreference.Documentation_Status_LOV__r.Value__c === 'DOC-UNCERT' || this.applicationCoursePreference.Documentation_Status_LOV__r.Value__c === 'DOC-ENROL'){
                        this.applicationCoursePreferenceStatus = 'Full Offer';
                    }
                }else if(this.applicationCoursePreference.Documentation_Status_LOV__c && this.applicationCoursePreference.Documentation_Status_LOV__r.Value__c === 'SATISFIED' &&
                        this.applicationCoursePreference.Conditional_Offer_Status_LOV__c && this.applicationCoursePreference.Conditional_Offer_Status_LOV__r.Value__c === 'SATISFIED') {
                            this.applicationCoursePreferenceStatus = 'Full Offer';
                        }
           } else if(this.applicationCoursePreference.Outcome_Status_LOV__r.Value__c === 'OFFER-PROV')
           {
                if(this.applicationCoursePreference.Documentation_Status_LOV__c && this.applicationCoursePreference.Documentation_Status_LOV__r.Value__c === 'SATISFIED')
                {
                    this.applicationCoursePreferenceStatus = 'Full Offer';
                }
           }

            
            //Set status styling
            if(this.applicationCoursePreference.Outcome_Status_LOV__r.System_Code__c === 'ACCEPTED'){
                this.highLevelStatus = 'success';
            } else if(this.applicationCoursePreference.Outcome_Status_LOV__r.System_Code__c === 'COND-OFFER'){
                this.highLevelStatus = 'success';
            } else if(this.applicationCoursePreference.Outcome_Status_LOV__r.System_Code__c === 'OFFER'){
                this.highLevelStatus = 'success';
            } else if(this.applicationCoursePreference.Outcome_Status_LOV__r.System_Code__c === 'PENDING'){
                this.highLevelStatus = 'inProgress';
            } else if(this.applicationCoursePreference.Outcome_Status_LOV__r.System_Code__c === 'SATISFIED'){
                this.highLevelStatus = 'inProgress';
            } else if(this.applicationCoursePreference.Outcome_Status_LOV__r.System_Code__c === 'DEFERRAL'){
                this.highLevelStatus = 'error';
            } else if(this.applicationCoursePreference.Outcome_Status_LOV__r.System_Code__c === 'LAPSED'){
                this.highLevelStatus = 'error';
            } else if(this.applicationCoursePreference.Outcome_Status_LOV__r.System_Code__c === 'NOT-APPLIC'){
                this.highLevelStatus = 'error';
            } else if(this.applicationCoursePreference.Outcome_Status_LOV__r.System_Code__c === 'REJECTED'){
                this.highLevelStatus = 'error';
            } else if(this.applicationCoursePreference.Outcome_Status_LOV__r.System_Code__c === 'UNSATISFAC'){
                this.highLevelStatus = 'error';
            } else if(this.applicationCoursePreference.Outcome_Status_LOV__r.System_Code__c === 'VOIDED'){
                this.highLevelStatus = 'error';
            } else if(this.applicationCoursePreference.Outcome_Status_LOV__r.System_Code__c === 'WAIVED'){
                this.highLevelStatus = 'error';
            } else if(this.applicationCoursePreference.Outcome_Status_LOV__r.System_Code__c === 'WITHDRAWN'){
                this.highLevelStatus = 'error';
            } else {
                this.highLevelStatus = 'draft';
            }
        }
    }
    get acpNumberIcon() {
        let icon = '';
        switch(this.applicationCoursePreference.Preference_Number__c)
        {
            case '1':
                icon = this.number1;
                break;
            case '2':
                icon = this.number2;
                break;
            case '3':
                icon = this.number3;
                break;
            case '4':
                icon = this.number4;
                break;
            case '5':
                icon = this.number5;
                break;
            default:
                icon = '';
        }
        return icon;
    }

    get acpIcon() {
        let icon = '';
        switch(this.highLevelStatus) {
            case 'success':
                icon = this.offerMadeIcon;
                break;
            case 'inProgress':
                icon = this.assessingIcon;
                break;
            case 'error':
                icon = this.unsuccessfulIcon;
                break;
            default:
                icon = '';
        }
        return icon;
    }

    get acpNumberColor() {
        let colorClass = 'draftAcpNumber';
        switch(this.highLevelStatus) {
            case 'success':
                colorClass = 'successAcpNumber';
                break;
            case 'inProgress':
                colorClass = 'inProgressAcpNumber';
                break;
            case 'error':
                colorClass = 'errorAcpNumber';
                break;
            default:
                colorClass = 'draftAcpNumber';
        }
        return colorClass;
    }

    get acpNumberColorMobile() {
        let colorClass = 'slds-size_12-of-12 draftAcpNumberMobile';
        switch(this.highLevelStatus) {
            case 'success':
                colorClass = 'slds-size_12-of-12 successAcpNumberMobile';
                break;
            case 'inProgress':
                colorClass = 'slds-size_12-of-12 inProgressAcpNumberMobile';
                break;
            case 'error':
                colorClass = 'slds-size_12-of-12 errorAcpNumberMobile';
                break;
            default:
                colorClass = 'slds-size_12-of-12 draftAcpNumberMobile';
        }
        return colorClass;
    }

    get acpStatus() {
        let colorClass = 'draftAcpStatus';
        switch(this.highLevelStatus) {
            case 'success':
                colorClass = 'successAcpStatus';
                break;
            case 'inProgress':
                colorClass = 'inProgressAcpStatus';
                break;
            case 'error':
                colorClass = 'errorAcpStatus';
                break;
            default:
                colorClass = 'draftAcpStatus';
        }
        return colorClass;
    }

 

    get getLocation() {
        let locationDetail = '';
        if(this.applicationCoursePreference.Course_Offering__r.Location_Description__c){
            locationDetail = this.applicationCoursePreference.Course_Offering__r.Location_Description__c.charAt(0).toUpperCase() + this.applicationCoursePreference.Course_Offering__r.Location_Description__c.toLowerCase().slice(1);
        }
        return locationDetail;
    }

    get attendanceMode(){
        let attendanceModeDesc = '';
        if(this.applicationCoursePreference.Attendance_Mode__c == 'EX'){
            attendanceModeDesc = 'External (off-campus)';
        }
        if(this.applicationCoursePreference.Attendance_Mode__c == 'IN'){
            attendanceModeDesc = 'Internal (on-campus)';
        }
        return attendanceModeDesc;
    }

    get parentApplicationSubmitted() {
        return (this.applicationCoursePreference.Application__r.Status__c === 'Submitted' || this.applicationCoursePreference.Application__r.Status__c === 'Sent for Submission');
    }


    get retrieveUnitSetDescription() {
        let unitSetDescription;
        unitSetDescription = this.applicationCoursePreference.Unit_Set_Description__c;

        return unitSetDescription;
    }

    get isDomestic() {
        let isDomestic = false;
        if(this.applicationCoursePreference.Application__r.Citizenship_Classification__c === 'Domestic'){
            isDomestic = true;
        }
        return isDomestic;
    }

    get showOfferButton() {
        let showOffer = true;

        if(!this.applicationCoursePreference.Admission_Category__c || this.VALID_ADM_CATEGORIES.indexOf(this.applicationCoursePreference.Admission_Category__c) < 0) {
            showOffer = false;
        }

        if(!this.applicationCoursePreference.Outcome_Status_LOV__c || this.VALID_OUTCOME_STATUS.indexOf(this.applicationCoursePreference.Outcome_Status_LOV__r.Value__c) < 0) {
            showOffer = false;
        }
        
        if(!this.applicationCoursePreference.Offer_Response_Status_LOV__c || this.VALID_RESPONSE_STATUS.indexOf(this.applicationCoursePreference.Offer_Response_Status_LOV__r.Value__c) < 0) {
            showOffer = false;
        }

        if(this.applicationCoursePreference.Offer_Response_Date__c && this.applicationCoursePreference.Offer_Response_Status_LOV__c && this.VALID_RESPONSE_STATUS.indexOf(this.applicationCoursePreference.Offer_Response_Status_LOV__r.Value__c) >= 0){
            let dateToday = new Date();
            let dateExpiry = new Date(this.applicationCoursePreference.Offer_Response_Date__c);

            if((dateExpiry.getDate() < dateToday.getDate() && dateExpiry.getMonth() === dateToday.getMonth() && dateExpiry.getYear() === dateToday.getYear()) || 
               ((dateExpiry.getDate() !== dateToday.getDate() || dateExpiry.getMonth() !== dateToday.getMonth() || dateExpiry.getYear() !== dateToday.getYear()) && dateExpiry < dateToday)) {
                showOffer = false;
            }            
        }

        return showOffer;
    }

    get determineExpired() {
        let isExpired = false;
        if(this.applicationCoursePreference.Offer_Response_Date__c && this.applicationCoursePreference.Offer_Response_Status_LOV__c && this.VALID_RESPONSE_STATUS.indexOf(this.applicationCoursePreference.Offer_Response_Status_LOV__r.Value__c) >= 0){
            let dateToday = new Date();
            let dateExpiry = new Date(this.applicationCoursePreference.Offer_Response_Date__c);

            if((dateExpiry.getDate() < dateToday.getDate() && dateExpiry.getMonth() === dateToday.getMonth() && dateExpiry.getYear() === dateToday.getYear()) || 
               ((dateExpiry.getDate() !== dateToday.getDate() || dateExpiry.getMonth() !== dateToday.getMonth() || dateExpiry.getYear() !== dateToday.getYear()) && dateExpiry < dateToday)) {
                isExpired = true;
            }            
        }
        return isExpired;
    }
 
    //Action to open the acp open page
    openRespondForm() {
        //Create change event
        const openRespondEvent = new CustomEvent('openrespond', {
            detail: this.applicationCoursePreference
        });
        //Dispatch event
        this.dispatchEvent(openRespondEvent);
    }
}