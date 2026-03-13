import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import fetchCalendarRounds from '@salesforce/apex/GrReleaseScholarshipOffer.fetchCalendarRounds';
import publishScholarshipRound from '@salesforce/apex/GrReleaseScholarshipOffer.publishScholarshipRound';

export default class GrReleaseScholarshipOfferAction extends NavigationMixin(LightningElement) {
    round
    showSpinner
    calendarData
    showModal
    calendarId
    items = [
        { label: 'International Scholarship Round', value: 'International' },
        { label: 'Domestic Scholarship Round', value: 'Domestic' },
    ];

    fetchScholarshipCalendar() {
        this.showSpinner = true
        fetchCalendarRounds({
            'round': this.round
        }).then(response => {
            var objResponse = new Map(Object.entries(response))
            this.calendarData = objResponse.get('calendarData')
            this.showSpinner = false
        }).catch((error) => {
            this.showSpinner = false
        })
    }

    onFieldChange(e){
        const fieldName = e.target.name
        switch(fieldName) {
            case "round":
                this.round = e.target.value
                this.fetchScholarshipCalendar();
                break
            default:
                //nothing selected
        }
    }

    redirectToCalendar(e) {
        const recordId = e.target.name
        const pageReference = {
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view',
                objectApiName: 'Calendar__c'
            }
        };

        this[NavigationMixin.GenerateUrl](pageReference).then((url) => {
            window.open(url, '_blank'); 
        });
    }

    onPublish(e) {
        this.calendarId = e.target.name
        this.showModal = true; // Show the modal
    }

    handleConfirm() {
        this.showModal = false; // Close the modal
        this.showSpinner = true
        publishScholarshipRound({
            'calendarId': this.calendarId,
            'round': this.round
        }).then(response => {
            var objResponse = response
            if(objResponse == 'success') {
                this.fetchScholarshipCalendar();
                const evt = new ShowToastEvent({
                    title: 'Success!',
                    message: 'Publishing of the scholarship round is in progress!',
                    variant: 'success',
                });
                this.dispatchEvent(evt);

            } else {
                const event = new ShowToastEvent({
                    title: 'Error',
                    message: 'unexpected error.',
                    variant: 'error', 
                    mode: 'dismissable' 
                });
                this.dispatchEvent(event);
            }            
            this.showSpinner = false
        }).catch((error) => {
            this.showSpinner = false
            const event = new ShowToastEvent({
                title: 'Error',
                message: 'unexpected error >' + error.body?.message,
                variant: 'error', 
                mode: 'dismissable' 
            });
            this.dispatchEvent(event);
        })
    }

    handleCancel() {
        this.showModal = false; // Close the modal
        console.log('User canceled!');
    }

}