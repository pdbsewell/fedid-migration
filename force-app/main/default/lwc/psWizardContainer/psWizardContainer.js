/**
 * @File Name          : psWizardContainer.js
 * @Description        : JS Controller 
 * @Author             : Nick Guia
 * @Group              : Lead Management
**/
import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import createProspectiveStudent from '@salesforce/apex/ProspectiveStudentManagerController.createProspectiveStudent';
import createProspectiveStudentLead from '@salesforce/apex/ProspectiveStudentManagerController.createProspectiveStudentLead';
import updateProspectiveStudent from '@salesforce/apex/ProspectiveStudentManagerController.updateProspectiveStudent';

export default class PsWizardContainer extends LightningElement {

    @api
    set contactRecord(value) {
        if (value) {
            this._contactRec = value;
            this._contactId = value.Id;
            this._sps.Exploded_Target__c = value.Id;
        }
    };

    get contactRecord() {
        return this._contactRec;
    } 

    @api
    set leadRecord(value) {
        if (value) {
            this._leadRec = value;
            this._leadId = value.Id;
            this._sps.Exploded_Lead__c = value.Id;
        }
    }

    get leadRecord() {
        return this._leadRec;
    }

    @api
    set caseRecord(value) {
        if (value) {
            this._caseRec = value;
            this._caseId = value.Id;
            this._sps.Exploded_Enquiry__c = value.Id;
        }
    }

    get caseRecord() {
        return this._caseRec;
    }

    @track isLoading = false;

    @track _contactRec = {};
    @track _contactId;

    @track _leadRec = {};
    @track _leadId;

    @track _caseRec = {};
    @track _caseId;

    _sps = {
        is_Synchronous__c : true,
    };
    _dto = { };

    /**
     * @description handle clicking on Cancel button
     */
    handleCancelBtn() {
        this.dispatchCloseModalEvent();
    }

    /**
     * @description handle clicking on Save button
     * This will merge all child component details
     * then invokes apex method for Exploding Leads
     */
    handleSaveBtn() {
        //merge details from subcomponents
        let dto = this.getContactDetails(); //returns a PsmDTO
        let conSps = dto.sps;
        let leadSps = this.getLeadDetails(); //returns an SPS
        let spsRec;

        if (conSps && leadSps) {
            spsRec = Object.assign(conSps, leadSps);
        } else if (conSps) {
            spsRec = conSps;
        } else if (leadSps) {
            spsRec = leadSps;
        }
        
        Object.assign(this._sps, spsRec);
        this._sps.Lead_Source__c = 'Enquiry';
        console.log(`this._sps : ${JSON.stringify(this._sps)}`);
        dto.sps = this._sps;
        this._dto = dto;
        console.log(`this._dto : ${JSON.stringify(this._dto)}`);

        if (this._sps.Exploded_Lead__c && this._sps.Exploded_Target__c) {
            this.saveUpdateProspectiveStudent(); //if both contact and lead exists
        } else if (this._sps.Exploded_Target__c) {
            this.saveProspectiveStudentLead(); //method when only contact exists
        } else {
            this.saveProspectiveStudent(); //method when contact and lead doesn't exist
        }
    }

    /**
     * @description method for calling Exploding Leads without Contact ID
     */
    saveProspectiveStudent() {
        this.isLoading = true;

        createProspectiveStudent({ dto: this._dto })
            .then(result => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Prospective student record created',
                        variant: 'success',
                        mode: 'sticky'
                    }),
                );
                this._contactRec.Id = result;
                this.dispatchSaveEvent();
                this.dispatchCloseModalEvent();
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating record',
                        message: 'An Error occurred while trying to save record. Please contact your System Administrator.',
                        variant: 'error',
                    }),
                );
                console.error(error.body.message);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * @description method for calling Exploding Leads with Contact ID
     */
    saveProspectiveStudentLead() {
        this.isLoading = true;

        createProspectiveStudentLead({ dto: this._dto })
            .then(result => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Prospective student Lead created',
                        variant: 'success',
                        mode: 'sticky'
                    }),
                );
                this._leadRec.Id = result;
                this.dispatchSaveEvent();
                this.dispatchCloseModalEvent();
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating record',
                        message: 'An Error occurred while trying to save record. Please contact your System Administrator.',
                        variant: 'error',
                    }),
                );
                console.error(error.body.message);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * @description for updating Contact and Lead details
     */
    saveUpdateProspectiveStudent() {
        this.isLoading = true;

        updateProspectiveStudent({ dto: this._dto })
            .then(result => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Prospective student record successfully updated',
                        variant: 'success',
                        mode: 'sticky'
                    }),
                );
                this.dispatchSaveEvent();
                this.dispatchCloseModalEvent();
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating record',
                        message: 'An Error occurred while trying to save record. Please contact your System Administrator.',
                        variant: 'error',
                    }),
                );
                console.error(error.body.message);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * @description get contact details from child component
     */
    getContactDetails() {
        return this.template.querySelector('c-ps-wizard-contact-info').getInfo();
    }

    /**
     * @description get lead details from child component
     */
    getLeadDetails() {
        return this.template.querySelector('c-ps-wizard-lead-info').getInfo();
    }

    /**
     * @description event dispatcher for closing modal.
     */
    dispatchCloseModalEvent() {
        const closeModalEvent = new CustomEvent('closemodal');
        this.dispatchEvent(closeModalEvent);
    }

    /**
     * @description event dispatcher for notifying parent component of save process
     */
    dispatchSaveEvent() {
        const saveEvent = new CustomEvent(
            'save', {
                detail : {
                    contactId: this._contactRec.Id,
                    leadId: this._leadRec.Id
                }
            });
        this.dispatchEvent(saveEvent);
    }
}