import { LightningElement, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import MOMENT_JS from '@salesforce/resourceUrl/moment';

export default class OfferWizardACPUpdateCard extends LightningElement {
    @api acp = {'id':'','acpNumber':'','courseTitle':'','courseOfferingCommercementPeriod':'', 'revisedStartDate': '', 'revisedEndDate': '', 'adjustedCourseDurationUnit': '', 'approvedCreditPoints': ''};

    initialRender = true;
    previousRevisedEndDate;

    constructor() {
        super();        
    }

    renderedCallback() {

        if (this.momentjsInitialized) {
            return;
        }
        this.momentjsInitialized = true;

        loadScript(this, MOMENT_JS)
            .then(() => {
                console.log('Moment loaded!');
            })
            .catch(error => {
                this.error = error;
            });

        if (this.initialRender) {
            this.previousRevisedEndDate = this.acp.revisedEndDate;
            this.initialRender = false;
        }
    }

    handleCourseDurationChange(event) {
        let adjustedCourseDuration = event.target.value;
        let acpnew = JSON.parse(JSON.stringify(this.acp));

        // ensure this is blank instead of undefined, in case user wants to 
        // remove any approved credit points
        if (!adjustedCourseDuration) {
            acpnew.adjustedCourseDuration = '';
        }

        // prevent user from putting in a negative value because html min does
        // not prevent the user from doing so in the keyboard
        if (adjustedCourseDuration && adjustedCourseDuration < 0) {
            acpnew.adjustedCourseDuration = '';
        } else {
            // do the date calculation for end date
            let standardDurationUnit = this.getStandardisedCourseDurationUnit(this.acp.adjustedCourseDurationUnit);
            // calculate the end date based on this duration
            let revisedStartDateMoment = moment(this.acp.revisedStartDate, moment.ISO_8601);
            if (adjustedCourseDuration && adjustedCourseDuration != 0) {
                let endDate = revisedStartDateMoment.add(parseInt(adjustedCourseDuration, 10), standardDurationUnit);
                acpnew.revisedEndDate = endDate.format('YYYY-MM-DD');
            } else {
                // Reset the revised end date back if it has been cleared or set to 0
                acpnew.revisedEndDate = this.previousRevisedEndDate;
            }
            acpnew.adjustedCourseDuration = adjustedCourseDuration;
        }
        this.acp = acpnew;
    }

    handleRevisedStartDateChange(event) {
        let revisedStartDateInput = event.target.value;
        if (revisedStartDateInput) {
            let acpnew = JSON.parse(JSON.stringify(this.acp));
            acpnew.revisedStartDate = revisedStartDateInput;
            this.acp = acpnew;
        }
    }

    handleRevisedEndDateChange(event) {
        let revisedEndDateInput = event.target.value;
        if (revisedEndDateInput) {
            let acpnew = JSON.parse(JSON.stringify(this.acp));
            acpnew.revisedEndDate = revisedEndDateInput;
            this.acp = acpnew;
        }
    }

    /* for momentjs */
    getStandardisedCourseDurationUnit(durationUnit) {
        durationUnit = durationUnit || 'year';
        switch(durationUnit.toLowerCase()) {
            case "week":
            case "week(s)":
                return "weeks";
            case "month":
            case "month(s)":
                return "months";
            default:
                return "years";
        }
    }

    @api isInputsValid() {
        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputCmp) => {
                        inputCmp.reportValidity();
                        return validSoFar && inputCmp.checkValidity();
            }, true);
        return allValid;
    }

    handleApprovedCreditPointsChange(event) {
        let approvedCreditPointInput = event.target.value;
        if (approvedCreditPointInput) {
            let acpnew = JSON.parse(JSON.stringify(this.acp));
            acpnew.approvedCreditPoints = approvedCreditPointInput;
            this.acp = acpnew;
        } else {
            let acpnew = JSON.parse(JSON.stringify(this.acp));
            // ensure this is blank instead of undefined, in case user wants to 
            // remove any approved credit points
            acpnew.approvedCreditPoints = '';   
            this.acp = acpnew;
        }
    }

}