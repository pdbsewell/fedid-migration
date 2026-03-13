import * as util from 'c/util';
import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import OFFER_OBJ from '@salesforce/schema/SBQQ__Quote__c';
import AUSTRALIAN_VISA_STATUS_PICKLIST from '@salesforce/schema/SBQQ__Quote__c.VisaDetails_AustralianVisaStatus__c';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';

export default class OfferVisaDetailsForm extends LightningElement {
    AUS_VISA_STATUS_IWILLGET = 'AUS_STUDENT_WILLBE';
    AUS_VISA_STATUS_IHAVESTUDVISA = 'AUS_STUDENT_HOLD';
    AUS_VISA_STATUS_IHAVETEMPVISA = 'AUS_STUDENT_TEMP';

    @api offerRecord;

    @track spinner = false;
    @track visaDetailsInfo = {};

    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
        this.visaDetailsInfo.VisaDetails_AustralianVisaStatus__c = this.offerRecord.VisaDetails_AustralianVisaStatus__c.value;
        this.visaDetailsInfo.VisaDetails_ImmigrationOffice__c = this.offerRecord.VisaDetails_ImmigrationOffice__c.value;
        this.visaDetailsInfo.VisaDetails_VisaNumber__c = this.offerRecord.VisaDetails_VisaNumber__c.value;
        this.visaDetailsInfo.VisaDetails_StartDate__c = this.offerRecord.VisaDetails_StartDate__c.value;
        this.visaDetailsInfo.VisaDetails_EndDate__c = this.offerRecord.VisaDetails_EndDate__c.value;
        
        // subscribe to pageNavigate event from navigationComponent
        registerListener('SaveVisaDetails', this.handleSave, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    /***** GET RELATIONSHIP TYPE PICKLIST OPTION VALUES  *****/
    @wire(getObjectInfo, { objectApiName: OFFER_OBJ })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: AUSTRALIAN_VISA_STATUS_PICKLIST})
    AusVisaStatusTypePicklistValues;

    get hasRendered() {
        return this.offerRecord !== undefined;
    }

    get immigrationOfficeLabel() {
        console.log('### label:' + this.visaDetailsInfo.VisaDetails_AustralianVisaStatus__c);
        var label_Immigration_Office_Def = 'Through which Australian Immigration Office will you apply for your visa?';
        if (this.visaDetailsInfo.VisaDetails_AustralianVisaStatus__c) {
            console.log('### here 0:');
            if (this.visaDetailsInfo.VisaDetails_AustralianVisaStatus__c == this.AUS_VISA_STATUS_IWILLGET) {
                label_Immigration_Office_Def = 'Through which Australian Immigration Office will you apply for your visa?';
                console.log('### here 1:');
            }
            if (this.visaDetailsInfo.VisaDetails_AustralianVisaStatus__c == this.AUS_VISA_STATUS_IHAVESTUDVISA
                    || this.visaDetailsInfo.VisaDetails_AustralianVisaStatus__c == this.AUS_VISA_STATUS_IHAVETEMPVISA) {
                label_Immigration_Office_Def = 'Which Australian Immigration Office issued your visa?';
                console.log('### here 2:');
            }
        }
        console.log('### label_Immigration_Office_Def:' + label_Immigration_Office_Def);
        return label_Immigration_Office_Def;
    }

    get showSubInformation() {
        if (!this.visaDetailsInfo.VisaDetails_AustralianVisaStatus__c) {
            return false;
        }
        return true;
    }

    get showVisaNumberStartDateEndDate() {
        if (this.visaDetailsInfo.VisaDetails_AustralianVisaStatus__c == this.AUS_VISA_STATUS_IHAVESTUDVISA
            || this.visaDetailsInfo.VisaDetails_AustralianVisaStatus__c == this.AUS_VISA_STATUS_IHAVETEMPVISA) {
            return true;
        }
        return false;
    }

    /*** HANDLE ACTION WHEN SELECT OPTION VALUE WAS CHANGED ****/
    handlePicklistChange(event) {
        this.visaDetailsInfo.VisaDetails_AustralianVisaStatus__c = event.detail.value;
    }

    /*** HANDLE ACTION WHEN INPUT TEXT VALUE WAS CHANGED ****/
    handleTextChange(event){
        this.visaDetailsInfo[event.target.name] = event.target.value;
    }

    /*** HANDLE ACTION WHEN INPUT DATE VALUE WAS CHANGED ****/
    handleDateChange(event){
        this.visaDetailsInfo[event.target.name] = event.target.value;
    }

    /*** VALIDATE FORM INPUTS ****/
    get validateInputs() {
        var dateToday = new Date();
        var startDate = new Date();
        var endDate = new Date();

        if (this.visaDetailsInfo.VisaDetails_StartDate__c != null || this.visaDetailsInfo.VisaDetails_StartDate__c != undefined) {
            startDate = new Date(this.visaDetailsInfo.VisaDetails_StartDate__c);
        }
        if (this.visaDetailsInfo.VisaDetails_EndDate__c != null || this.visaDetailsInfo.VisaDetails_EndDate__c != undefined) {
            endDate = new Date(this.visaDetailsInfo.VisaDetails_EndDate__c);
        }
        
        if (!this.visaDetailsInfo.VisaDetails_AustralianVisaStatus__c) {
            this.errorHandling('Error', 'Please fill out all fields.', 'error');
            return false;

        } else if (this.visaDetailsInfo.VisaDetails_AustralianVisaStatus__c
                && this.visaDetailsInfo.VisaDetails_AustralianVisaStatus__c == this.AUS_VISA_STATUS_IWILLGET
                && !this.visaDetailsInfo.VisaDetails_ImmigrationOffice__c) {
            this.errorHandling('Error', 'Please fill out all fields.', 'error');
            return false;

        } else if (this.visaDetailsInfo.VisaDetails_AustralianVisaStatus__c == this.AUS_VISA_STATUS_IHAVESTUDVISA || this.visaDetailsInfo.VisaDetails_AustralianVisaStatus__c == this.AUS_VISA_STATUS_IHAVETEMPVISA) {
            
            if (!this.visaDetailsInfo.VisaDetails_VisaNumber__c || !this.visaDetailsInfo.VisaDetails_StartDate__c || !this.visaDetailsInfo.VisaDetails_EndDate__c || !this.visaDetailsInfo.VisaDetails_ImmigrationOffice__c) {
                this.errorHandling('Error', 'Please fill out all fields.', 'error');
                return false;
            }
            if (startDate >= endDate) {
                this.errorHandling('Error', 'Visa Start Date must be earlier than Visa End Date.', 'error');
                return false;
            }
            if (endDate <= dateToday) {
                this.errorHandling('Error', 'Visa End Date must be in future.', 'error');
                return false;
            }
        }
        return true;
    }

    /*** VALIDATE IF FORM WAS UPDATED OR NOT ****/
    get infoHasChanged() {
        if (this.visaDetailsInfo.VisaDetails_AustralianVisaStatus__c == this.offerRecord.VisaDetails_AustralianVisaStatus__c.value
                && this.visaDetailsInfo.VisaDetails_ImmigrationOffice__c == this.offerRecord.VisaDetails_ImmigrationOffice__c.value
                && this.visaDetailsInfo.VisaDetails_VisaNumber__c == this.offerRecord.VisaDetails_VisaNumber__c.value
                && this.visaDetailsInfo.VisaDetails_StartDate__c == this.offerRecord.VisaDetails_StartDate__c.value
                && this.visaDetailsInfo.VisaDetails_EndDate__c == this.offerRecord.VisaDetails_EndDate__c.value) {
            return false;
        }
        return true;
    }

    /*** REMOVE VALUE IN FIELDS DEPENDS ON ANSWER ***/
    removeFieldValues() {
        if (this.visaDetailsInfo.VisaDetails_AustralianVisaStatus__c) {
            if (this.visaDetailsInfo.VisaDetails_AustralianVisaStatus__c == this.AUS_VISA_STATUS_IWILLGET) {
                this.visaDetailsInfo.VisaDetails_VisaNumber__c = null;
                this.visaDetailsInfo.VisaDetails_StartDate__c = null;
                this.visaDetailsInfo.VisaDetails_EndDate__c = null;
            }
        }
    }

    /*** FIRE THIS EVENT WHEN NAVIGATION WAS CLICKED AND UPDATED OFFER RECORD ****/
    handleSave(data) {
        let isValid = this.validateInputs;
        let hasUpdate = this.infoHasChanged;
        let subStatus = util.subStatusTriggerConga;
        if (isValid) {
            if (!hasUpdate) {
                //util.log('*** GO TO NEXT PAGE ***');
                fireEvent(this.pageRef, 'ContinueFromVisaDetails', data);
            }
            else {
                this.spinner = true;
                this.removeFieldValues();
                let offerFieldUpdate = {
                    fields:{
                        Id: this.offerRecord.Id.value,
                        VisaDetails_AustralianVisaStatus__c: this.visaDetailsInfo.VisaDetails_AustralianVisaStatus__c,
                        VisaDetails_ImmigrationOffice__c: this.visaDetailsInfo.VisaDetails_ImmigrationOffice__c,
                        VisaDetails_VisaNumber__c: this.visaDetailsInfo.VisaDetails_VisaNumber__c,
                        VisaDetails_StartDate__c: this.visaDetailsInfo.VisaDetails_StartDate__c,
                        VisaDetails_EndDate__c: this.visaDetailsInfo.VisaDetails_EndDate__c,
                        Sub_Status__c: subStatus
                    }
                };
                //util.log(offerFieldUpdate);
                updateRecord(offerFieldUpdate)
                    .then(() => {
                        this.spinner = false;
                        //util.log('*** Success Visa Details Update ***');
                        fireEvent(this.pageRef, 'ContinueFromVisaDetails', data);
                    })
                    .catch(error => {
                        var exception = JSON.parse(JSON.stringify(error));
                        //util.log('*** Error ***' );
                        //util.logJson(exception);
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: exception.body.message, 
                                variant: 'error',
                            }),
                        );
                    });
            }
        }
    }

    errorHandling(title, message, type) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message, 
                variant: type
            }),
        ); 
    }
}