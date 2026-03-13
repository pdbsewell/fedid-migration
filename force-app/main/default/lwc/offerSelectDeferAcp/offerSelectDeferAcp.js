import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {NavigationMixin,CurrentPageReference} from 'lightning/navigation';
import { unregisterAllListeners, fireEvent, registerListener } from 'c/pubsub';
import getOffersForDeferral from '@salesforce/apex/OfferDeferalService.getOffersForDeferral';

export default class OfferSelectDeferAcp extends LightningElement {
    @api offeredAcp;
    @api contactId;
    @api grants;
    @api selectedClauses;
    @api preDefinedClauses;
    @api selectedDeferralList = [];

    offerDeferralList = [];
    deferredOpp = [];
    updateACPs = {};
    hasRecords = true;
    isLoading = true;

    @track _selectedAcps = {};

    @api 
    getSelectedAcps() {
        return this._selectedAcps;
    }

    connectedCallback(){        
        //registerListener('offerDeferrals', this.getOffers, this);
        //this.getOffers(this.offeredAcp);
        this.updateACPs = {};
        this.getDeferrals(this.contactId);        
    }

    getDeferrals(id){
        getOffersForDeferral({contactId: id, opptyStatus: 'Signed'})
        .then(result => {
            this.isLoading = true;  
            this.hasRecords = false; 
            if(result.length > 0){
                let parsedResult= JSON.parse(result);  
                parsedResult[0]["latest"] = true;   
                this.deferredOpp = parsedResult[0].oppty;
                this.getOffers(parsedResult);
                this.getOfferPreSelectedManualClauses(parsedResult);
                this.hasRecords = true;
            }
            this.isLoading = false;
        }).catch(error =>{
            console.log('error', JSON.parse(JSON.stringify(error)));
            this.offerDeferralList = undefined;
        });
    }

    getOfferPreSelectedManualClauses(offerDeferralList){
        this.preDefinedClauses = [];
        let associatedClause = offerDeferralList[0].oppty.Associated_Clauses__r;
        if(associatedClause){
            offerDeferralList[0].acps.forEach(elem => {
                let selectedClauseList = [];
                let mirrorClauses = {}

                associatedClause.records.forEach(clause => {
                    if(elem.acp.Id == clause.ACP__c){
                        clause["selected"] = true;
                        clause["uniqueId"] = clause.ACP__r.Course_Code__c+clause.Mirror_Clause__c;
                        selectedClauseList.push(clause);

                    }
                });        
                this.selectedClauses.forEach(selectedClause =>{
                    selectedClauseList.forEach(sc =>{
                        if(selectedClause.uniqueId == sc.uniqueId){
                            sc.selected = selectedClause.selected;
                        }
                    })
                });    

                mirrorClauses["clauses"] = selectedClauseList;
                mirrorClauses["parentId"] = elem.acp.Id;
                mirrorClauses["parentName"] = elem.acp.Name;
                mirrorClauses["parentObject"] = elem.acp;
                this.preDefinedClauses.push(mirrorClauses);
            });
        }
    }

    @api getPreDefinedClauses(){
        return this.preDefinedClauses;
    }

    @api setDefaultDeferredGrant(){
        //set pre-selected grant product from deferred opportunity
        let lineItems = this.deferredOpp.OpportunityLineItems;
        let grants = JSON.parse(JSON.stringify(this.grants));
        if(lineItems){
            grants.forEach((grant)=>{
                lineItems.records.forEach(line => {
                    if(line.Product2.Family == 'Grant' || line.Product2.Family == 'Scolarship'){
                        grant.selected = line.PricebookEntryId === grant.Id;
                    }                        
                });        
            });
        }
        return grants;
        
    }

    getOffers(data){
        this.updateACPs = {};
        let selectedDeferredAcp = JSON.parse(JSON.stringify(this.selectedDeferralList));
        let offerWrapperList = JSON.parse(JSON.stringify(data));
        if(offerWrapperList){
            //set style class for opportunity list
            offerWrapperList.forEach(data =>{
                data["sectionClass"] = (data.latest ? 'slds-accordion__section slds-is-open' : 'slds-accordion__section slds-is-close') ;
                data["disabled"] = !data.latest;
                data.acps.forEach(elem=>{
                    elem.acp["currentOfferingLink"] = "/"+elem.acp.Id;
                    elem.acp["ratainCurrentOffering"] = elem.acp.selectedOffering == elem.acp.Course_Offering__c;
                    elem.acp["selected"] = data.latest;
                    elem.acp["reviewed"] = elem.acp.reviewed;
                    elem.availableOffering.forEach(off=>{
                        off["checked"] = elem.acp.selectedOffering == off.Id;
                        if(off.checked)this.updateACPs[elem.acp.Id] = off;
                        //flag on the previously selected course offering in each ACP
                        //might need it should the business require it
                        /*
                        if(selectedDeferredAcp.length > 0){
                            selectedDeferredAcp[0].acps.forEach(selectedAcp=>{
                                //set selected course offering
                                selectedAcp.availableOffering.forEach(o =>{
                                    if(o.Id == off.Id){
                                        off["checked"] = o.checked;
                                    }
                                });
                                
                                elem.acp["reviewed"] = true;
                            });
                        }
                        */
                        //put selected course offering into map<acpId, course_offering>
                    
                    });

                    //set acp No Change radio option
                    /*
                    if(selectedDeferredAcp.length > 0){  
                        selectedDeferredAcp[0].acps.forEach(c=>{
                            if(c.acp.Id == elem.acp.Id){
                                elem.acp["ratainCurrentOffering"] = c.acp.ratainCurrentOffering;
                                elem.acp["Deferred_Course_Offering__c"] = c.acp.Deferred_Course_Offering__c;
                            }
                        });
                    }
                    */
                    console.log(',,,,,, elem.acp' + JSON.stringify(elem.acp));
                    
                    let selectedAcpOffering = {"selectedCourseOffering": {
                        "courseOfferingId": elem.acp.Course_Offering__c,
                        "startDate": elem.acp.Course_Offering__r.Start_Date__c,
                        "endDate": elem.acp.Course_Offering__r.End_Date__c,
                        "commencementPeriod" : elem.acp.Course_Offering__r.Academic_Year__c + ' - ' + this.formatAnyNullsAsBlank(elem.acp.Course_Offering__r.Commencement_Period__c),
                        "durationUnit": this.isNotBlank(elem.acp.Course_Offering__r.Override_Duration_Unit__c) ? elem.acp.Course_Offering__r.Override_Duration_Unit__c : 'Year(s)'    
                    }};
                    this._selectedAcps[elem.acp.Id] = selectedAcpOffering;

                    fireEvent(this.pageRef, 'acp_course_offering_changed', selectedAcpOffering);
                });
                data.updateACPs = this.updateACPs;
                
            });
            this.offerDeferralList = offerWrapperList;
        }
        console.log('this.updateACPs', this.updateACPs);
        console.log('_selectedAcps: ' + JSON.stringify(this._selectedAcps));
        this.isLoading = false;
    }
    

    onSectionClick(event){
        let id = event.currentTarget.dataset.targetId;
        this.offerDeferralList.forEach(data =>{
            if(data.oppty.Id == id){
                data["isOpen"] = !data.isOpen;
            }
        });
        let targetSection = this.template.querySelector(`[data-section-id="${id}"]`);
        let sectionState = targetSection.getAttribute('class');        
        if(sectionState.includes('slds-is-open')){
            targetSection.setAttribute('class', 'slds-accordion__section slds-is-close');
        }else{
            targetSection.setAttribute('class', 'slds-accordion__section slds-is-open');
        }
        
    }

    onRadioSelect(event){
        let acpId = event.currentTarget.dataset.acpId;
        let selectedOffering = event.currentTarget.value;
        let offerWrapperList = JSON.parse(JSON.stringify(this.offerDeferralList));
        offerWrapperList[0].acps.forEach(elem =>{
            elem.acp["reviewed"] = (elem.acp.reviewed ? elem.acp.reviewed : elem.acp.ratainCurrentOffering);
            if(elem.acp.Id == acpId){
                elem.acp["ratainCurrentOffering"] = (selectedOffering == elem.acp.Course_Offering__c);
                elem.acp["Deferred_Course_Offering__c"] = (selectedOffering != elem.acp.Course_Offering__c ? selectedOffering : '');
                elem.availableOffering.forEach(offering => {
                    offering["checked"] = (offering.Id == selectedOffering);      
                    if(offering.checked){
                        this.updateACPs[acpId] = offering;
                        //elem.acp["Course_Offering__r"] = offering;
                        //elem.acp["Deferred_Course_Offering__r"] = offering;

                        this._selectedAcps[elem.acp.Id] = {"selectedCourseOffering": {
                            "courseOfferingId": offering,
                            "startDate": offering.Start_Date__c,
                            "endDate": offering.End_Date__c,
                            "commencementPeriod" : offering.Academic_Year__c + ' - ' + this.formatAnyNullsAsBlank(offering.Commencement_Period__c),
                            "durationUnit": this.isNotBlank(offering.Override_Duration_Unit__c) ? offering.Override_Duration_Unit__c : 'Year(s)'                                        
                        }};
                    }
                });
                elem.acp["reviewed"] = true;                
                if(elem.acp.ratainCurrentOffering) delete this.updateACPs[acpId];
            }
        });
        offerWrapperList[0].updateACPs = this.updateACPs;
        this.offerDeferralList = offerWrapperList;
        //set the selectedDeferralList as this will be needed to keep the selected course offerings on component reload from screen 1
        this.selectedDeferralList = offerWrapperList;
        console.log('_selectedAcps - radio select: ' + JSON.stringify(this._selectedAcps));
    }

    @api getDeferredAcp(){
        return this.offerDeferralList;
    }
    @api getSelectedCourseOffering(){
        return this.updateACPs;
    }
    @api getSelectedDeferredAcp(){
        return this.selectedDeferralList;
    }

    @api gethasRecords(){
        return this.hasRecords;
    }

    @api validateSelectedCourseOffering(){
        //get latest offer
        let selectedList = JSON.parse(JSON.stringify(this.selectedDeferralList)); 
        let latestOffer = (selectedList.length > 0 ? selectedList[0] : this.offerDeferralList[0]);
        var isValid = true;
        if(latestOffer){
            console.log('latestOffer.updateACPs', JSON.parse(JSON.stringify(latestOffer.updateACPs)));
            //if no new course offering were selceted for available acps return false
            if(Object.entries(latestOffer.updateACPs).length <= 0) isValid = false;

            latestOffer.acps.forEach(elem => {
                let acpColumn = this.template.querySelector(`[data-col-id="${elem.acp.Id}"]`); 
                //set editable acp class with red border when nothing was selected        
                if(!elem.acp.reviewed)isValid = false;
                let updatedClass = (elem.acp.reviewed && isValid ? 'slds-col column-border' : 'slds-col slds-has-error'); 
                acpColumn.setAttribute('class', updatedClass);    

            });
        }
        return isValid;
    }

    formatAnyNullsAsBlank(string) {
        if (string) {
            return string;
        } else {
            return '';
        }
    }

    isNotBlank(string) {
        if (string) {
            return true;
        } else {
            return false;
        }
    }
}