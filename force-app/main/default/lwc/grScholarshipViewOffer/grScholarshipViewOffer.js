import { LightningElement, wire } from 'lwc';
import fetchQuote from "@salesforce/apex/GrScholarshipViewOfferController.fetchQuote";
import { CurrentPageReference } from 'lightning/navigation';
import updateRecord from "@salesforce/apex/GrScholarshipViewOfferController.updateRecord";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import communityMyAppAssets from '@salesforce/resourceUrl/CommunityMyAppAssets';

/**
*  @author Vishal Gupta
*  @date 3-2-2025
*  @group My App Application
*  @description used for graduate research scholarship offer details
**/
export default class GrScholarshipViewOffer extends LightningElement {
    
    showSpinner
    proceedWithoutOffer
    quoteData 
    admissionApplicationStatus
    quoteStatus
    application = {}
    offerDescription
    offerAcceptanceDate
    scholarshipPublishedDate
    durationOfScholarship
    isOfferAcceptedOrDeclined
    acceptOrDecline
    isOfferReadyToAcceptDecline
    isOfferConditional
    offerConditions
    addressLine2
    rtpStipendYearValueRange
    checkbox1
    checkbox2
    recordId
    applicantId
    monashCandidateId
    applicationId
    monashLogoUrl = communityMyAppAssets + '/images/monash-logo.svg';
    acceptDecline = [
        { label: 'Accept', value: 'Accepted' },
        { label: 'Decline', value: 'Declined' },
    ]
    items = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' },
    ]
    
    /**
     * @description capturing recordid from url
     */
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state?.id; // Extracting 'id' from URL
        }
    }

    /**
     * onFieldChange method
     * @description capturing all the field inputs
     * @returns N/A
     */
    onFieldChange(e) {
        const fieldName = e.target.name
        switch(fieldName) {
            case "proceedWithoutOffer":
                this.application.Id = this.quoteData?.SBQQ__Opportunity2__r.Application_Course_Preference__r.Application__c
                this.application.Proceed_without_scholarship__c = e.target.value
                break
            case "acceptOrDecline":
                this.acceptOrDecline = e.target.value
                if(this.acceptOrDecline == 'Accepted') {
                    this.quoteData.Decline_Reason__c = ''
                }
                this.quoteData.SBQQ__Status__c = this.acceptOrDecline
                break
            case "declineReason":
                this.quoteData.Decline_Reason__c = e.target.value
                break                           
            default:
                //nothing selected
        }
    }

    /**
     * @description property for offer declined selected
     */
    get isDeclinedSelected(){
        return this.acceptOrDecline == 'Declined'
    }

    /**
     * @description property for offer declined
     */
    get isOfferDeclined() {
        return this.acceptOrDecline == undefined && this.quoteData?.SBQQ__Status__c == 'Declined'
    }

    /**
     * @description property for offer accepted
     */
    get isOfferAccepted() {
        return this.acceptOrDecline == 'Accepted' || this.quoteData?.SBQQ__Status__c == 'Accepted'
    }

    /**
     * @description property for offer expired
     */
    get isOfferExpired() {
        return this.quoteData?.SBQQ__Status__c == 'Expired'
    }

    /**
     * @description connected callback to get the offer details
     */
    connectedCallback() {
        this.getOfferDetails()
    }
    getOfferDetails() {        
        this.showSpinner = true
        fetchQuote({
            quoteId: this.recordId
        }).then(data => {
            this.quoteData = data.quote
            this.applicationId = this.quoteData?.SBQQ__Opportunity2__r.Application_Course_Preference__r.GradRes_Callista_Id__c
            this.applicantId = this.quoteData?.SBQQ__Opportunity2__r.Application_Course_Preference__r.Callista_Applicant_Id__c
            this.monashCandidateId = this.quoteData?.SBQQ__Opportunity2__r.Application_Course_Preference__r.Applicant__r.Person_ID_unique__c
            if(data.quote.SBQQ__Opportunity2__r?.Application_Course_Preference__r.Attendance_Type__c == 'PT') {
                this.quoteData.attendanceType = 'Part-Time'
            } else if(data.quote.SBQQ__Opportunity2__r?.Application_Course_Preference__r.Attendance_Type__c == 'FT'){
                this.quoteData.attendanceType = 'Full-Time'
            } else {
                this.quoteData.attendanceType = data.quote.SBQQ__Opportunity2__r?.Application_Course_Preference__r.Attendance_Type__c
            }

            if(data.quote.SBQQ__Opportunity2__r?.Application_Course_Preference__r.Attendance_Mode__c == 'IN') {
                this.quoteData.attendanceMode = 'Internal/On-campus'
            } else if(data.quote.SBQQ__Opportunity2__r?.Application_Course_Preference__r.Attendance_Mode__c == 'EX'){
                this.quoteData.attendanceMode = 'External/Off-campus'
            } else {
                this.quoteData.attendanceMode = data.quote.SBQQ__Opportunity2__r?.Application_Course_Preference__r.Attendance_Mode__c
            }
            
            this.quoteData.courseName = data.quote.SBQQ__Opportunity2__r?.Application_Course_Preference__r.Course_Code__c +' '+ data.quote.SBQQ__Opportunity2__r?.Application_Course_Preference__r.Course_Title__c
            this.proceedWithoutOffer = data.quote.SBQQ__Opportunity2__r?.Application_Course_Preference__r.Application__r.Proceed_without_scholarship__c
            this.offerAcceptanceDate = data.scholarshipApplicationDueDate
            this.scholarshipPublishedDate = data.quote.SBQQ__Opportunity2__r?.Offer_published_date__c
            this.offerDescription = data.lineItemsDescription
            this.durationOfScholarship = data.durationOfScholarship
            this.isOfferAcceptedOrDeclined = data.isOfferAcceptedOrDeclined
            this.isOfferReadyToAcceptDecline = data.isOfferReadyToAcceptDecline
            this.quoteStatus = data.quote.SBQQ__Status__c
            this.admissionApplicationStatus = data.scholOnlyApplicationCourseStatus
            if(this.isOfferAcceptedOrDeclined) {
                this.checkbox1 = true
                this.checkbox2 = true
            } 
            this.isOfferConditional = data.isConditionalOffer
            this.offerConditions = data.lineItemsConditions
            this.addressLine2 = data.quote.Contact_Access__r.MailingCity +' '+ data.quote.Contact_Access__r.MailingState +' '+ data.quote.Contact_Access__r.MailingPostalCode
            this.rtpStipendYearValueRange = data.rtpStipendYearValueRange       
                    
            this.showSpinner = false         
        }).catch((error) => {
            this.showSpinner = false
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'unexpected error!',
                variant: 'error'
            }));
        })
    }

    /**
     * @description property for, if there is no offer given
     */
    get isNoOffer(){
        return this.quoteData?.SBQQ__Opportunity2__r.Offer_Type__c == 'NO-OFFER'
    }

    /**
     * @description property for, isFacultyScholarhipOnly
     */
    get isFacultyScholarhipOnly(){
        return Boolean(this.quoteData?.SBQQ__Opportunity2__r.Faculty_Scholarship_Awarded__c && !this.quoteData?.SBQQ__Opportunity2__r.Faculty_Sponsorship_Awarded__c)
    }

    /**
     * @description property for, isFacultySponsorshipOnly
     */
    get isFacultySponsorshipOnly(){
        return Boolean(this.quoteData?.SBQQ__Opportunity2__r.Faculty_Sponsorship_Awarded__c && !this.quoteData?.SBQQ__Opportunity2__r.Faculty_Scholarship_Awarded__c)
    }

    /**
     * @description property for, isFacultyScholarshipAndSponsorship
     */
    get isFacultyScholarshipAndSponsorship(){
        return Boolean(this.quoteData?.SBQQ__Opportunity2__r.Faculty_Scholarship_Awarded__c && this.quoteData?.SBQQ__Opportunity2__r.Faculty_Sponsorship_Awarded__c)
    }

    /**
     * @description property for, if there is offer given
     */
    get isOffer(){
        return this.quoteData?.SBQQ__Opportunity2__r.Offer_Type__c == 'OFFER' && this.quoteData?.SBQQ__LineItemCount__c > 0
    }

    /**
     * @description property for FacultyScholarshipOnly
     */
    get isFacultyScholarshipSponsorshipWithoutOffer(){
        return (this.quoteData?.SBQQ__Opportunity2__r.Offer_Type__c == 'OFFER' || this.quoteData?.SBQQ__Opportunity2__r.Offer_Type__c == 'REJECTED') && 
                (this.quoteData?.SBQQ__Opportunity2__r.Faculty_Scholarship_Awarded__c || this.quoteData?.SBQQ__Opportunity2__r.Faculty_Sponsorship_Awarded__c) &&
                this.quoteData?.SBQQ__LineItemCount__c == 0
    }

    /**
     * @description property for FacultyScholarshipOnly type
     */
    get scholarshipType(){
        if(this.quoteData?.SBQQ__Opportunity2__r.Faculty_Scholarship_Awarded__c && this.quoteData?.SBQQ__Opportunity2__r.Faculty_Sponsorship_Awarded__c) {
            return 'Faculty Stipend Scholarship and Faculty Tuition-paying Scholarship'
        } else if(this.quoteData?.SBQQ__Opportunity2__r.Faculty_Scholarship_Awarded__c) {
            return 'Faculty Stipend Scholarship'
        } else if(this.quoteData?.SBQQ__Opportunity2__r.Faculty_Sponsorship_Awarded__c) {
            return 'Faculty Tuition-paying Scholarship'
        }
    }

    /**
     * @description property for domestic scholarship with RTP stipend
     */
    get showRTPStipendSectionDomestic() {
        return this.rtpStipendYearValueRange && this.quoteData?.SBQQ__Opportunity2__r.Application_Course_Preference__r.Application__r.Citizenship_Classification__c == 'Domestic' && this.quoteData?.SBQQ__Opportunity2__r.Application_Course_Preference__r.Graduate_Research_Application_Type__c == 'Admission and Scholarship'
    }

    /**
     * @description property for International scholarship with RTP stipend
     */
    get showRTPStipendSectionInternational() {
        return this.rtpStipendYearValueRange && this.quoteData?.SBQQ__Opportunity2__r.Application_Course_Preference__r.Application__r.Citizenship_Classification__c == 'International' && this.quoteData?.SBQQ__Opportunity2__r.Application_Course_Preference__r.Graduate_Research_Application_Type__c == 'Admission and Scholarship'
    }
    
    /**
     * @description property for scholarship only 
     */
    get showScholarshipOnlySection() {
        return this.quoteData?.SBQQ__Opportunity2__r.Application_Course_Preference__r.Graduate_Research_Application_Type__c == 'Scholarship'
    }

    /**
     * @description capturing the response of offer accepted/rejected
     */
    handleUpdate() {        
        if(this.checkValidity()) {
            this.showSpinner = true
            let objData = this.application.Proceed_without_scholarship__c != null && this.application.Proceed_without_scholarship__c != undefined ? 
                                                                                                                                this.application : 
                                                                                                                                this.quoteData
            
            updateRecord({objData : objData, applicationId : this.applicationId, applicantId : this.applicantId, quoteId : this.quoteData?.Id})
            .then((data) => {
                if(data.error) {
                    this.showSpinner = false
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: 'unexpected error!',
                        variant: 'error'
                    }));
                } else {
                    // Record is updated successfully
                    this.showSpinner = false
                    this.acceptOrDecline = undefined
                    const evt = new ShowToastEvent({
                        title: 'Success!',
                        message: 'Response saved!',
                        variant: 'success',
                    });
                    this.dispatchEvent(evt);
                    this.getOfferDetails()
                }                
            })
            .catch(error => {
                this.showSpinner = false
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'unexpected error!',
                    variant: 'error'
                }));
            });
        }        
    }

    /**
     * @description checking validation of input components 
     */
    checkValidity() {
        const allValid = [
            ...this.template.querySelectorAll('lightning-input'),
            ...this.template.querySelectorAll('lightning-radio-group'),
            ...this.template.querySelectorAll('lightning-textarea'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        return allValid;
    }

}