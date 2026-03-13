import * as util from 'c/util';
import { LightningElement, api, track, wire } from 'lwc';
import { unregisterAllListeners, fireEvent, registerListener } from 'c/pubsub';
import Offer_wizard_acp_info from '@salesforce/label/c.Offer_wizard_acp_info';
import selectACPs from '@salesforce/apex/ApplicationCoursePreferenceServices.selectACPOfferedForDomesticByApplicantId';

export default class OfferSelectDomesticAcp extends LightningElement {
    @api contactId;

    @track acps = [];
    @track hasRecords = false;

    connectedCallback() {
        this.getACPs(this.contactId);
    }

    getACPs(contactId) {
        selectACPs({ applicantId: contactId })
        .then(result => {
            this.hasRecords = false;
            this.acps = []; 
            result.forEach(elem => {
                //var obj = {...element} //clone json object as cached item are ready only
                if (elem.Offer_Response_Date__c) {
                    elem["selected"] = false;
                    elem["startDateOverriden"] = false;
                    let type = elem.Application__r.Transfer_Type__c;
                    elem.Application__r.Transfer_Type__c = (type != null ? type : 'Offer');

                    this.acps.push(elem);
                    this.hasRecords = true;
                }
            });
        }).catch(error => {
            console.log(error);
            this.showToast('Data load Error', error.body.message, 'error');
            this.acps = undefined;
        });
    }

    get displayACPs() {
        return this.acps != null;
    }

    selectACPRow(evt){
        const recordId = evt.currentTarget.id.substring(0,18); //because id returns a205P0000000Ff2QAE-134
        let acpList = JSON.parse(JSON.stringify(this.acps));
        acpList.forEach((elem)=>{
            if (elem.Id === recordId){
                elem.selected = !elem.selected;
                //set bdp record when wizard was launched outside BDP record or if selected acp w/ BDP was changed
                if(elem.selected && elem.Bulk_Data_Processing__c){
                    this.bdpRec = elem.Bulk_Data_Processing__r;
                }
            }
        });
        this.acps = acpList;
    }

    @api getSelectedAcps() {
        return this.acps;
    }
}