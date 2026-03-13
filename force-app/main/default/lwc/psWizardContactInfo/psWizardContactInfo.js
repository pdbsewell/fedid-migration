/**
 * @File Name          : psWizardContactInfo.js
 * @Description        : JS Controller
 * @Author             : Nick Guia
 * @Group              : Lead Management
**/
import { LightningElement, track, api } from 'lwc';

import { fieldConfig } from './config';
const openSections = ['basicPersonInfo', 'additionalPersonInfo'];

//BIND FOR DEPENDENCY
import SPS_CITY_FIELD from '@salesforce/schema/Staged_Prospective_Student__c.Mailing_City__c';
import SPS_COUNTRY_FIELD from '@salesforce/schema/Staged_Prospective_Student__c.Mailing_Country__c';
import SPS_POSTCODE_FIELD from '@salesforce/schema/Staged_Prospective_Student__c.Mailing_Postcode__c';
import SPS_STATE_FIELD from '@salesforce/schema/Staged_Prospective_Student__c.Mailing_State__c';
import SPS_STREET_FIELD from '@salesforce/schema/Staged_Prospective_Student__c.Mailing_Street__c';

export default class PsWizardContactInfo extends LightningElement {

    @api
    set contactRecord(value) {
        if (value) {
            this._contactRec = value;
            this._contactId = value.Id;
        }
    }

    get contactRecord() {
        return this._contactRec;
    }

    @api
    set contactId(value) {
        if (value) {
            this._contactId = value;
        }
    }

    get contactId() {
        return this._contactId;
    }

    @api
    set caseRecord(value) {
        if (value) {
            this._caseRec = value;
        }
    }

    get caseRecord() {
        return this._caseRec;
    }

    @track _contactId;
    @track _contactRec;
    @track activeSections = openSections;
    @track _fieldConfig = fieldConfig;
    @track isLoading = true;

    _caseRec;   
    _spsRecord = {
        Broad_Area_of_Interest_Update_Mode__c: 'Overwrite'
    };
    _dto = { } //represents ProspectiveStudentManagerController.PsmDTO

    @api
    getInfo() {
        this.getExistingValues();
        this.buildDTO();
        return this._dto;
    }

    /**
     * @description build a DTO object based on ProspectiveStudentManagerController.PsmDTO
     * this is to extract data that are being captured in PSM but doesn't exist as a field
     * in SPS
     */
    buildDTO() {
        if(this._spsRecord.hasOwnProperty('residencyStatus')) {
            this._dto.residencyStatus = this._spsRecord.residencyStatus;
            delete this._spsRecord['residencyStatus'];
        }

        if(this._spsRecord.hasOwnProperty('educLevel')) {
            this._dto.educLevel = this._spsRecord.educLevel;
            delete this._spsRecord['educLevel'];
        }

        if(this._spsRecord.hasOwnProperty('conProf')) {
            this._dto.conProf = this._spsRecord.conProf;
            delete this._spsRecord['conProf'];
        }

        this._dto.sps = this._spsRecord;
    }

    updateRecordObject(e) {
        let value = e.target.value;
        let fieldName = e.target.dataset.item;
        this._spsRecord[fieldName] = value;
    }

    /**
     * @description for fleshing out address details 
     * from Address object
     */
    updateAddress(addressVal) {
        this._spsRecord.Mailing_City__c = addressVal.MailingCity;
        this._spsRecord.Mailing_Country__c = addressVal.MailingCountry;
        this._spsRecord.Mailing_Postcode__c = addressVal.MailingPostalCode;
        this._spsRecord.Mailing_State__c = addressVal.MailingState;
        this._spsRecord.Mailing_Street__c = addressVal.MailingStreet;
    }

    /**
     * @description get form values. if this is not done, those fields that were
     * not changed or clicked will be captured as null
     */
    getExistingValues() {
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        inputFields.forEach(e => {
            let value = e.value;
            let fieldName = e.dataset.item;
            this._spsRecord[fieldName] = value;
        });
    }

    /**
     * @description since address fields were custom mapped to SPS fields,
     *  contact address values and map them
     */
    getAddressValues(e) {
        for(let fieldMap of fieldConfig.spsFields) {
            if(this._contactRec.Id && this._contactRec[fieldMap.key])
            {
                const field = this.template.querySelector(`lightning-input-field[data-id=${fieldMap.key}]`);
                field.value = this._contactRec[fieldMap.key];
            }
        }
    }

    /**
     * @description map case fields into PSM if Contact and Lead does not exist yet.
     *  This is to avoid having to input web-captured data data twice
     */
    handleFormLoad() {
        //if contact does not exist yet, map case fields into PSM
        if(!this._contactId && this._caseRec) {
            for(let fieldMap of fieldConfig.caseFieldMapping) {
                //if field in case is populated, map across to contact field
                if(this._caseRec[fieldMap.caseField]) 
                {
                    const contactField = this.template.querySelector(`lightning-input-field[data-id=${fieldMap.contactField}]`);
                    if(contactField) {
                        contactField.value = this._caseRec[fieldMap.caseField];
                    }
                }
            }
        }
        this.isLoading = false;
    }
}