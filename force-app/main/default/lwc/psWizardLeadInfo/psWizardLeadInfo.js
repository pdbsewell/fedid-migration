/**
 * @File Name          : psWizardLeadInfo.js
 * @Description        : JS Controller
 * @Author             : Nick Guia
 * @Group              : Lead Management
**/
import { LightningElement, track, api } from 'lwc';

import { fieldConfig } from './config';

export default class PsWizardLeadInfo extends LightningElement {

    @api
    getInfo() {
        this.getExistingValues();
        return this.spsRecord;
    }

    @api
    set leadId(value) {
        if (value) {
            this._leadId = value;
        }
    }

    get leadId() {
        return this._leadId;
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

    @track _fieldConfig = fieldConfig;
    @track _leadId = '';
    @track spsRecord = {
        Broad_Area_of_Interest_Update_Mode__c: 'Overwrite'
    };
    @track isLoading = true;

    _caseRec;

    updateRecordObject(e) {
        let value = e.target.value;
        let fieldName = e.target.dataset.item;
        this.spsRecord[fieldName] = value;
    }

    /**
     * @description get form values. if this is not done, those fields that were
     * not changed or clicked will captured as null
     */
    getExistingValues() {
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        inputFields.forEach(e => {
            let value = e.value;
            let fieldName = e.dataset.id;
            this.spsRecord[fieldName] = value;
        });
    }

    /**
     * @description map case fields into PSM if Contact and Lead does not exist yet.
     *  This is to avoid having to input web-captured data data twice
     */
    handleFormLoad() {
        //if contact does not exist yet, map case fields into PSM
        if(!this._leadId && this._caseRec) {
            for(let fieldMap of fieldConfig.caseFieldMapping) {
                //if field in case is populated, map across to contact field
                if(this._caseRec[fieldMap.caseField]) 
                {
                    const leadField = this.template.querySelector(`lightning-input-field[data-item=${fieldMap.leadField}]`);
                    if(leadField) {
                        leadField.value = this._caseRec[fieldMap.caseField];
                    }
                } else if(fieldMap.leadField === 'Company'){
                    //auto populate Lead Company with N/A if not supplied in Case
                    const leadField = this.template.querySelector(`lightning-input-field[data-item=${fieldMap.leadField}]`);
                    if(leadField) {
                        leadField.value = 'N/A';
                    }
                }
            }
        }

        this.isLoading = false;
    }
}