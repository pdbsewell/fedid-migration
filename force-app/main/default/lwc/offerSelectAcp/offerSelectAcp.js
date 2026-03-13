import * as util from 'c/util';
import { LightningElement, api, track, wire } from 'lwc';
import { unregisterAllListeners, fireEvent, registerListener } from 'c/pubsub';
import Offer_wizard_acp_info from '@salesforce/label/c.Offer_wizard_acp_info';
import selectACPs from '@salesforce/apex/ApplicationCoursePreferenceServices.selectACPOfferedByApplicantId';
import getAssocClauseByParentId from '@salesforce/apex/AssociatedClauseService.getAssocClauseByParentId';
import retrievefeeCategoryMappings from '@salesforce/apex/ApplicationCoursePreferenceServices.retrievefeeCategoryMappings';

export default class OfferSelectAcp extends LightningElement {
    //@api acps;
    @api contactId;
    @api bdpRec;
    @api preselectedAcpIds = {};
    @api regenerationReason = '';
    @api offerType = '';
    @track acps = []; 
    @track hasRecords = false;
    @track acpInfo = Offer_wizard_acp_info;
    @track preDefinedClauses = [];
    @track wiredMapping;

    @wire(retrievefeeCategoryMappings)  
    wiredMappings(value) {
        this.wiredMapping = value;
        const { data, error } = value;
        if (data) {                        
            this.records = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.records = undefined;
        }
    }  

    connectedCallback(){
        this.getACPs(this.contactId);
    }

    getACPs(contactId){
        selectACPs({ applicantId: contactId })
        .then(result => {
            this.hasRecords = false;
            this.acps = []; 
            result.forEach(elem => {
                // retrieve the mapping relevant for the selected offer type
                let fullFeeMapping = this.wiredMapping.data;
                let relevantFeeMapping = [];
                if(fullFeeMapping){
                    if(fullFeeMapping[this.offerType]){
                        for(let item in fullFeeMapping[this.offerType]){
                            relevantFeeMapping.push(fullFeeMapping[this.offerType][item]);
                        }
                    }
                }

                //var obj = {...element} //clone json object as cached item are ready only
                if (elem.Offer_Response_Date__c){
                    console.log(this.preselectedAcpIds);
                    elem["selected"] = this.preselectedAcpIds && this.preselectedAcpIds[elem.Id] ? true : false;
                    elem["startDateOverriden"] = false;
                    let type = elem.Application__r.Transfer_Type__c;
                    elem.Application__r.Transfer_Type__c = (type != null ? type : 'Offer');

                    if(this.bdpRec != null && elem.Bulk_Data_Processing__c != null){
                        elem["selected"] = elem.Id == this.bdpRec.Transfer_To__c;
                    }

                    // only show relevant acp based off the selected option
                    if(relevantFeeMapping.includes(elem.Fee_Category__c)){
                        this.acps.push(elem);
                        this.hasRecords = true;
                    }
                }
            });
            if(this.bdpRec != null) this.getOfferPreSelectedManualClauses();
            console.log('hasRecords', this.hasRecords);
        }).catch(error => {
            console.log(error);
            this.showToast('Data load Error', error.body.message, 'error');
            this.acps = undefined;
        });
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

    get displayACPs(){
        return this.acps != null;
    }

    reasonChanged(event){
        this.regenerationReason = event.detail.value;
    }    

    getOfferPreSelectedManualClauses(){
        getAssocClauseByParentId({parentField: 'Offer_Request__c', parentId: this.bdpRec.Id})
        .then(result => {
            console.log('result', result); 
            let data = JSON.parse(JSON.stringify(result));
            let assocClauses = [];
            data.forEach(elem => {
                let selectedClauseList = [];
                let mirrorClauses = {}

                if(elem.Offer_Request__c == this.bdpRec.Id){
                    assocClauses.push(elem);
                    elem["selected"] = true;
                    elem["uniqueId"] = this.bdpRec.Transfer_Course_Code__c+elem.Mirror_Clause__c;
                    selectedClauseList.push(elem);
                }
                this.acps.forEach(acp => {
                    if(acp.Id == this.bdpRec.Transfer_To__c){
                        mirrorClauses["existingAssociatedClause"] = assocClauses;
                        mirrorClauses["clauses"] = selectedClauseList;
                        mirrorClauses["parentId"] = acp.Id;
                        mirrorClauses["parentName"] = acp.Name;
                        mirrorClauses["parentObject"] = acp;
                        this.preDefinedClauses.push(mirrorClauses);
                    }
                });
                
            });
            console.log('preDefinedClauses', this.preDefinedClauses);
        }).catch(error =>{
            console.log('error', JSON.parse(JSON.stringify(error)));
        });
    }

    //get latest bdp record
    @api getBDPrecord(){
        return this.bdpRec;
    }

    @api getPreDefinedClauses(){
        return this.preDefinedClauses;
    }

    @api getSelectedAcps(){
        //get manual clauses when selected acp has bdp record and wizard was not launched in BDP layout
        if(this.preDefinedClauses.length <= 0 && this.bdpRec){
            this.getOfferPreSelectedManualClauses();
        }
        return this.acps;
    }

    @api regenerationReasonValue(){
        return this.regenerationReason;
    }

    @api gethasRecords(){
        return this.hasRecords;
    }

    showToast(title, message, type, mode = 'dismissable'){
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message, 
                variant: type,
                mode: mode
            }),
        ); 
    }

}