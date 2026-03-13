/* eslint-disable handle-callback-err */
/* eslint-disable vars-on-top */
/* eslint-disable dot-notation */
import * as ux from 'c/util';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { LightningElement, api, wire, track } from 'lwc';
import { unregisterAllListeners, fireEvent } from 'c/pubsub';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {NavigationMixin,CurrentPageReference} from 'lightning/navigation';

import Offer_wizard_acp_info from '@salesforce/label/c.Offer_wizard_acp_info';
import makeOffer from '@salesforce/apex/OpportunityService.createOffer';
import findGrants from '@salesforce/apex/PriceBookEntriesSelector.selectActiveGrantsAndScholarships';
import updateBDPStatus from '@salesforce/apex/BulkDataProcessingService.updateBDPStatus';
import getOfferDetails from '@salesforce/apex/OpportunityService.getOffer';

// custom permissions
import createAvenuOffer from '@salesforce/customPermission/Create_Avenu_Offer';

export default class OfferWizard extends NavigationMixin(LightningElement) {// Use alerts instead of toast to notify user
    @track contact;
    @track loaded = false;
    @track withGrant = false;
    @track grants;
    @track displayGrants = false;
    @track opp = {};
    @track oldOpp = {};
    @track acps = [];
    @track selectedacps;
    @track preselectedAcpIds;

    @track destinationACPSubmissionLocation;
    @track destinationAcpAgentName;
    @track hasACP = false;
    @track hasValidACP = false;
    @track selectedClauses = [];
    @track acps = [];
    @track regenerationReason = '';
    @track newOffer = false;
    @track deferOffer = false;
    @track deferredOpp = {};
    @track selectedOfferStep = '';
    @track newOfferId = 'newOffer';
    @track deferOfferId = 'deferOffer';    
    @track deferredACP = [];
    @track selectedDeferralList = [];
    @track grantHasChanged = false;
    @api wizardStepDetail = {};
    @track showNextButton = false;
    @track newDomesticOfferId = 'newDomesticOffer';
    @track newDomesticOffer = false;

    @track offerLapseDate;
    @track acpUpdateList;
    @track bahasaOfferCondition;
    acpUpdatesById;

    @api offerTemplate;

    //public
    @api recordId;
    @api opptyId;
    @api bdpRec;
    @api isDeferral;
    @api offerCategory;

    //private
    ccTransferBDPId = '';
    pricebookExtId;
    selectedGrantId;
    acpInfo = Offer_wizard_acp_info;

    @wire(CurrentPageReference) pageRef;
    //get current contact record
    @wire(getRecord, { recordId: '$recordId', layoutTypes: 'Full', modes: 'View' })
    wireContact({ error, data }) {
        if (data) {
            this.contact = {};
            this.loaded = false; 

            for (let f in data.fields){
                if (Object.prototype.hasOwnProperty.call(data.fields, f)) {
                    this.contact[f] = data.fields[f].value;

                    this.loaded = true;
                }
            }                       
            
            // flag behavior for deferral if initiated from the opportunity
            if(this.isDeferral){                
                this.selectedOfferStep = this.deferOfferId;
                this.startOfferNextHandler();
            }

            this.error = undefined;
        } else if (error) {
            this.showToast('Data load Error', error.body.message, 'error');
            this.contact = undefined;
        }
    }

    getOldOffer(){
        console.log('Fetching Old Offer');
        getOfferDetails({opptyId: this.opptyId})
        .then(result => {
            this.oldOpp = result;
            this.preselectedAcpIds = {};
            this.oldOpp.OpportunityLineItems.forEach( (oli) => {
                if (oli.Application_Course_Preference__c){
                    this.preselectedAcpIds[oli.Application_Course_Preference__c] = true;
                }
                if(oli.PricebookEntry.Product2.Family === 'Grant' || oli.PricebookEntry.Product2.Family === 'Scolarship'){
                    this.selectedGrantId = oli.PricebookEntryId;
                } 
            });
        }).catch(error =>{
            console.log(error);
            this.oldOpp = undefined;
        });
    }

    getDefaultClauses(){
        if (!this.oldOpp || !this.oldOpp.OpportunityLineItems || !this.oldOpp.Associated_Clauses__r){
            return;
        }
        let preDefinedClauses = [];
        this.oldOpp.OpportunityLineItems.forEach( (oli) => {
            if (oli.Application_Course_Preference__c){
                let selectedClauseList = [];
                this.oldOpp.Associated_Clauses__r.forEach(elem => {
                    if(elem.ACP__c == oli.Application_Course_Preference__c){
                        elem["selected"] = true;
                        elem["uniqueId"] = elem.ACP__r.Course_Code__c + elem.Mirror_Clause__c;
                        selectedClauseList.push(elem);
                    }
                });

                let mirrorClauses = {}
                mirrorClauses["clauses"] = selectedClauseList;
                mirrorClauses["parentId"] = oli.Application_Course_Preference__c;
                mirrorClauses["parentName"] = oli.Application_Course_Preference__r.Name;
                mirrorClauses["parentObject"] = oli.Application_Course_Preference__r;
                preDefinedClauses.push(mirrorClauses);
            }
        });
        console.log('preDefinedClauses', preDefinedClauses);
        return preDefinedClauses;
    }
    
    connectedCallback(){
        if (this.opptyId !== undefined) this.getOldOffer();
        this.getGrantPrices();
    }

    disconnectedCallback(){
        unregisterAllListeners(this);
    }  

    /****** START OFFER SCREEN *******/
    handlePicker(event){
        this.selectedOfferStep = event.detail.id;
        this.offerTemplate = event.detail.value;
    }

    startOfferNextHandler(){
        this.newOffer = (this.selectedOfferStep == this.newOfferId);        
        this.deferOffer = (this.selectedOfferStep == this.deferOfferId);
        this.newDomesticOffer = (this.selectedOfferStep == this.newDomesticOfferId);
        if(!this.deferOffer && !this.newOffer && !this.newDomesticOffer){
            this.showToast('Warning', 'Please select offer process.', 'warning');
            return false;
        }

        if (this.newOffer) {    
            if(this.offerTemplate === 'Online Coursework - Avenu'){
                this.pricebookExtId ='MO';
            }else{
                this.pricebookExtId ='AU_INT';
            }
        } else if(this.deferOffer){
            this.pricebookExtId ='AU_INT';
        } else if(this.newDomesticOffer) {
            if(this.offerTemplate == 'Domestic Coursework - Indonesia'){
                this.pricebookExtId ='MI_DOM';
            }
            else{
                this.pricebookExtId ='AU_DOM';
            }
        }
     
        // Logic to mark the Opportunity either "International Offer" or "International Deferral" or "Domestic Offer" or "Domestic Deferral"
        if(this.newOffer) this.opp.Offer_Category__c = 'International Offer';
        if(this.deferOffer && (this.offerCategory == 'International Offer' || this.offerCategory == 'International Deferral')) this.opp.Offer_Category__c = 'International Deferral';
        if(this.deferOffer && (this.offerCategory == 'Domestic Offer' || this.offerCategory == 'Domestic Deferral')) this.opp.Offer_Category__c = 'Domestic Deferral';
        if(this.newDomesticOffer) this.opp.Offer_Category__c = 'Domestic Offer';
        if(this.offerTemplate === 'Online Coursework - Avenu'){
            this.opp.Offer_Category__c = 'Online Offer';
        }
        
        this.template.querySelector('c-wizard-step').nextStep();
        this.deferredACP= [];
        this.selectedDeferralList - [];
        this.selectedClauses = [];
        this.grantHasChanged = true;
        this.getGrantPrices();
        return true;
    }

    backToStartScreen(){
        //set the previously selected course offerigns to defer when going back to Start Offer screen
        /*const deferAcpCmp = this.template.querySelector('c-offer-select-defer-acp');
        this.selectedDeferralList = (deferAcpCmp ? deferAcpCmp.getSelectedDeferredAcp() : []);*/
        this.newOffer = false;
        this.deferOffer = false;
        this.newDomesticOffer = false;
        this.offerLapseDate = null; // reset value because the user has started again;
        this.bahasaOfferCondition = null;
        this.acpUpdatesById = null;
        this.template.querySelector('c-wizard-step').previousStep();
    }

    get startTitle(){
        if (this.newOffer) {
            return 'Create a new offer for international applicants';
        }
        if (this.deferOffer) {
            return 'Defer an existing offer';
        }
        return 'Create a new domestic offer'; 
    }

    get wizardHeader(){
        let header = 'Start Offer';
        if(this.newOffer )header = 'New Offer';
        if(this.deferOffer )header = 'Defer Offer';
        if(this.newDomesticOffer )header = 'New Domestic Offer';
        return header;
    }
    /****** NEW OR DEFER OFFER SCREEN *******/
    getDeferredAcp(deferAcpCmp){
        let defaultClauses = deferAcpCmp.getPreDefinedClauses(); //get pre-defined clauses from offer's associated clauses
        let defaultGrant = deferAcpCmp.setDefaultDeferredGrant(); //get pre-defined clauses from offer's grant product
        let hasSelectedClauses = (this.selectedClauses != undefined && this.selectedClauses.length > 0);
        this.selectedClauses = (hasSelectedClauses > 0 ? this.selectedClauses : defaultClauses);
        this.grants = (this.grantHasChanged ? this.grants : defaultGrant);
        //this.selectedDeferralList = deferAcpCmp.getSelectedDeferredAcp();
        this.deferredACP = deferAcpCmp.getDeferredAcp();
        this.deferredOpp = (this.deferredACP.length > 0 ? this.deferredACP[0] : null);
        this.offerTemplate = this.deferredOpp.oppty.Template_Type__c;
          if(this.offerTemplate == 'Domestic Coursework Indonesia' )
          {
              this.pricebookExtId ='MI_DOM';
          }
        this.deferredACP.forEach(elem =>{
            elem.acps.forEach(data =>{
                if (data.acp.selected)this.selectedacps.push(data.acp);
            });
            
        });
    }

    validateACP(){
        var validateAcpCmp = this.template.querySelector('c-offer-validate-acp');
        let isScreenInputValid = validateAcpCmp.isInputsValid();
        let offerLapseDate = validateAcpCmp.getOfferLapseDate();
        this.hasValidACP = this.hasACP && isScreenInputValid;
        if (isScreenInputValid) {
            this.offerLapseDate = offerLapseDate;            
            let acpUpdateMap = {};
            validateAcpCmp.getAcpCardUpdates().forEach( (acp) => {

                acpUpdateMap[acp.id] =  {
                    "id": acp.id,
                    "Approved_Credit_Points__c": acp.approvedCreditPoints,
                    "Credit_Adjusted_Course_Duration__c": acp.adjustedCourseDuration,
                    "Agreed_Start_Date__c" : acp.revisedStartDate,
                    "Revised_End_Date__c": acp.revisedEndDate
                };

            });
            this.acpUpdatesById = acpUpdateMap;

            // we need to update selectedacps because that's what the package duration component requires as input
            let selectedAcpsToBeUpdated = [];
            this.selectedacps.forEach( (acp) => {
                if (this.acpUpdatesById[acp.Id]) {
                    acp.Approved_Credit_Points__c = acpUpdateMap[acp.Id].Approved_Credit_Points__c;
                    acp.Course_Start_Date_Updated__c = acpUpdateMap[acp.Id].Agreed_Start_Date__c;
                    acp.Course_End_Date_Updated__c = acpUpdateMap[acp.Id].Revised_End_Date__c;
                }
                selectedAcpsToBeUpdated.push(acp);
            });

            this.selectedacps = JSON.parse(JSON.stringify(selectedAcpsToBeUpdated));

            fireEvent(this.pageRef, 'selectedacps', this.selectedacps);

            this.template.querySelector('c-wizard-step').nextStep();
            return true;
        } else {
            return false;
        }
    }

    validate(){
        try{
            let selectAcpErrorTitle = 'ACP Selection Error';
            let selectAcpError = 'You must select at least one ACP';
            let deferOfferError = 'Please review existing offer to defer';
            let noDataTitle = 'Data not found';
            let noDataMessage = 'No data was found for this contact, please contact your administrator.';
            let onlyOneAcpForDomesticMessage = 'You must select only one ACP';
            
            //find selected acp's from new offer select acp 
            this.selectedacps = [];
            this.acps = [];
            let errorMsg = selectAcpError;
            let errorTitle = selectAcpErrorTitle;
            if(this.newOffer){ 
                var acpCmp = this.template.querySelector('c-offer-select-acp');
                this.regenerationReason = acpCmp.regenerationReasonValue();
                this.acps = acpCmp.getSelectedAcps();
                //sort dates to get least end date
                if (this.acps && this.acps.length > 1)this.sortData('Course_End_Date_Updated__c', 'desc');
                //sort dates to get latest start date
                if (this.acps && this.acps.length > 1)this.sortData('Course_Start_Date_Updated__c', 'asc');
                this.acps.forEach((elem)=>{ 
                    if (elem.selected)this.selectedacps.push(elem);
                });
                if(this.acps.length <=0){
                    errorTitle = noDataTitle;
                    errorMsg = noDataMessage;
                }
                let defaultClauses = this.oldOpp ? this.getDefaultClauses() : acpCmp.getPreDefinedClauses(); //get pre-defined clauses from associated clauses
                if (defaultClauses) {
                    this.selectedClauses = defaultClauses;
                }
                let bdpRecord = acpCmp.getBDPrecord();
                this.bdpRec = (!this.bdpRec ? bdpRecord : this.bdpRec);
                //pre select grant if coming from existin offer
                this.setSelectedGrant();
            }else if (this.deferOffer){
                errorMsg = deferOfferError;
                //or from defer acp options 
                const deferAcpCmp = this.template.querySelector('c-offer-select-defer-acp');
                if(deferAcpCmp.validateSelectedCourseOffering()){
                    this.getDeferredAcp(deferAcpCmp);            
                    if(this.deferredACP.length <=0){
                        errorTitle = noDataTitle;
                        errorMsg = noDataMessage;
                    } 
                }      

            }else{
                var acpCmp = this.template.querySelector('c-offer-select-domestic-acp');
                this.acps = acpCmp.getSelectedAcps();
                //sort dates to get least end date
                if (this.acps && this.acps.length > 1)this.sortData('Course_End_Date_Updated__c', 'desc');
                //sort dates to get latest start date
                if (this.acps && this.acps.length > 1)this.sortData('Course_Start_Date_Updated__c', 'asc');
                this.acps.forEach((elem)=>{ 
                    if (elem.selected)this.selectedacps.push(elem);
                });
                if(this.acps.length <=0){
                    errorTitle = noDataTitle;
                    errorMsg = noDataMessage;
                }/* else if(this.selectedacps != undefined && this.selectedacps.length > 1){
                    errorTitle = selectAcpErrorTitle;
                    errorMsg = onlyOneAcpForDomesticMessage;
                }*/
            }
            
            //any acp's selected ? If so go to next step 
            if ((this.selectedacps.length > 0 && !this.newDomesticOffer) || (this.newDomesticOffer && this.selectedacps.length > 0)){
                this.hasACP = true;
                // sort through the acp list to get the destination ACP submission 
                // location
                // the destination ACP being the ACP with the latest course start
                // date updated
                
                // null check in case of bad data
                if (this.selectedacps[this.selectedacps.length - 1].Application__r.Submission_Location_Country__c) {
                    this.destinationACPSubmissionLocation = this.selectedacps[this.selectedacps.length - 1].Application__r.Submission_Location_Country__r.Name;
                }
                if (this.selectedacps[this.selectedacps.length - 1].Application__r.Agent__c) {
                    this.destinationAcpAgentName = this.selectedacps[this.selectedacps.length - 1].Application__r.Agent__r.Name;
                } else {
                    // handle no agent e.g. if user goes back and selects another ACP
                    this.destinationAcpAgentName = '';
                }
                
                if (this.newOffer)  this.offerLapseDate = this.selectedacps[this.selectedacps.length - 1].Offer_Response_Date__c;
                //
                if (this.newOffer) {
                    this.acpUpdateList = [];
                    this.acps.forEach(acp => {
                        if (acp.selected) {     // need to filter because list contains all ACP selections for new offers
                            this.acpUpdateList.push({
                                "id": acp.Id,
                                "acpNumber": acp.ACP_ID__c,
                                "courseTitle": acp.Course_Title__c,
                                "courseOfferingCommercementPeriod": acp.Commencement_Period__c,
                                "approvedCreditPoints": acp.Approved_Credit_Points__c,
                                "adjustedCourseDuration": acp.Credit_Adjusted_Course_Duration__c,
                                "adjustedCourseDurationUnit": acp.Credit_Adjusted_Course_Duration_Type__c,
                                "revisedStartDate": acp.Course_Start_Date_Updated__c, 
                                "revisedEndDate": acp.Course_End_Date_Updated__c
                            });
                        }
                    });
                    console.log('this.acpUpdateList: ' + this.acpUpdateList);
                }

                // have to see what we can do to get the course offering selected if it is a deferral
                let selectedDeferredAcps = null;
                if (this.deferOffer){

                    const deferAcpCmp = this.template.querySelector('c-offer-select-defer-acp');
                    selectedDeferredAcps = deferAcpCmp.getSelectedAcps();
                    this.courseOfferingByAcpId = deferAcpCmp.getSelectedCourseOffering();
                    console.log('@@@selected courseOfferingByAcpId', JSON.stringify(this.courseOfferingByAcpId));
                    
                    this.acpUpdateList = [];
                    this.selectedacps.forEach(selectedAcp => {
                        this.acpUpdateList.push({
                            "id": selectedAcp.Id,
                            "acpNumber": selectedAcp.ACP_ID__c,
                            "courseTitle": selectedAcp.Course_Title__c,
                            "courseOfferingCommercementPeriod": selectedDeferredAcps[selectedAcp.Id].selectedCourseOffering.commencementPeriod,
                            "approvedCreditPoints": selectedAcp.Approved_Credit_Points__c,
                            "adjustedCourseDuration": selectedAcp.Credit_Adjusted_Course_Duration__c,
                            "adjustedCourseDurationUnit": selectedDeferredAcps[selectedAcp.Id].selectedCourseOffering.durationUnit,
                            "revisedStartDate": selectedDeferredAcps[selectedAcp.Id].selectedCourseOffering.startDate, 
                            "revisedEndDate": selectedDeferredAcps[selectedAcp.Id].selectedCourseOffering.endDate
                        });
                    });
                    console.log('this.acpUpdateList: ' + this.acpUpdateList);
                }

                // DOMESTIC
                if (this.newDomesticOffer)  this.offerLapseDate = this.selectedacps[this.selectedacps.length - 1].Offer_Response_Date__c;
                if (this.newDomesticOffer) {
                    this.acpUpdateList = [];
                    this.acps.forEach(acp => {
                        if (acp.selected) {     // need to filter because list contains all ACP selections for new offers
                            this.acpUpdateList.push({
                                "id": acp.Id,
                                "acpNumber": acp.ACP_ID__c,
                                "courseTitle": acp.Course_Title__c,
                                "courseOfferingCommercementPeriod": acp.Commencement_Period__c,
                                "approvedCreditPoints": acp.Approved_Credit_Points__c,
                                "adjustedCourseDuration": acp.Credit_Adjusted_Course_Duration__c,
                                "adjustedCourseDurationUnit": acp.Credit_Adjusted_Course_Duration_Type__c,
                                "revisedStartDate": acp.Course_Start_Date_Updated__c, 
                                "revisedEndDate": acp.Course_End_Date_Updated__c
                            });
                        }
                    });
                }

                fireEvent(this.pageRef, 'selectedacps', this.selectedacps);
                this.template.querySelector('c-wizard-step').nextStep();
                return true;
            }
            this.selectedacps = undefined;
            //show error has not acp's selected
            this.showToast(errorTitle, errorMsg, 'warning');
        }catch(err){
            console.log(err);
        }
        return false;
    }

    /***** START: MANUAL CLAUSE METHODS *****/

    /*getSelectedClauses(clauses){
        this.selectedClauses = clauses;
    }*/

    getClausesOnNext(){
        this.selectedClauses = this.template.querySelector('c-offer-manual-clause').getSelectedClauses();
      
        this.template.querySelector('c-wizard-step').nextStep();
        return true;
         /*
         //SFTG-1960 For Monash Abroad offers, the Additional clause is mandatory apart from Manual Clauses
        let fillAddtnlClauseError = 'Additional Clause(s) not filled';
        let addtnlClauseErrorMsg = 'For Monash Abroad offers, a valid study plan must be entered in addition to Manual clauses';
        let key= Object.keys(this.additionalACPClauses)[0];
        if (!this.additionalACPClauses[key] =='') { 
            this.template.querySelector('c-wizard-step').nextStep();
            return true;
        } else {
            this.showToast(fillAddtnlClauseError, addtnlClauseErrorMsg, 'error');
        }
        return false;*/

    }

    getClausesOnPrevious(){
        this.selectedClauses = this.template.querySelector('c-offer-manual-clause').getSelectedClauses();
        this.template.querySelector('c-wizard-step').previousStep();
        return true;
    }

    get additionalACPClauses(){
        let notes = this.template.querySelector('c-offer-manual-clause').getACPnotes();
        return notes;
    }

    get additionalBahasaACPClauses(){
        let notes = this.template.querySelector('c-offer-manual-clause').getACPBahasanotes();
        return notes;
    }
    
    

    /***** START: SELECT GRANT SCREEN *****/
    searchGrants(evt){
        var keywords = evt.target.value;
        var i = 0;
        this.grants.forEach( element => { 
            var hidden = false;
            if (keywords) {
                keywords.split(',').forEach( k => {
                    if ( (  ( !element.Product2.Name || element.Product2.Name.toLowerCase().indexOf( k.toLowerCase() ) < 0 ) && 
                            ( !element.Product2.Description || element.Product2.Description.toLowerCase().indexOf( k.toLowerCase() ) < 0 ) &&
                            ( !element.Product2.Keywords__c || element.Product2.Keywords__c.toLowerCase().indexOf( k.toLowerCase() ) < 0 ) ) ) {
                        hidden = true; 
                    }
                });
            }
            element.hidden = hidden;
            if (hidden) i++;
        } );
        this.displayGrants = this.grants.length !== i;
    }

    
    getGrantPrices(){
        findGrants( { pricebookExtId: this.pricebookExtId })
        .then(results => {
            this.grants = [];
            results.forEach(element => {
                element["selected"] = false;
                element["quotaOver"] = false;
                element["hidden"] = false;
                element["quotaNearlyOver"] = false;
                element["viewUrl"] = "/"+element.Product2Id;
                if(element.Product2.Type__c === 'Capped' && element.Product2.Quota_Available__c <= 0){
                    element["quotaOver"] = true;
                }else if(element.Product2.Type__c === 'Capped' && element.Product2.Quota_Available__c <= 2){
                    element["quotaNearlyOver"] = true;
                }
                if (element.Product2.Expiry_days__c != null && element.Product2.Expiry_days__c != undefined ) {
                    var expDate = new Date();
                    expDate.setDate(expDate.getDate() + element.Product2.Expiry_days__c);
                    element["projectedExpiryDate"] = expDate.toLocaleDateString();
                }
                this.grants.push(element);
                this.displayGrants = true;
            });
        }).catch((err) => {
            ux.log(err);
            this.showToast('Data load Error', 'Grants & Scholarship not found.', 'error');
        });
    }

    setSelectedGrant(){
        console.log(this.selectedGrantId);
        let grantList = JSON.parse(JSON.stringify(this.grants));
        grantList.forEach((elem)=>{
            if(elem.Product2.Quota_Available__c > 0 || this.oldOpp){
                elem.selected = this.selectedGrantId === elem.Id;
                this.grantHasChanged = true;
            }
        });
        this.grants = grantList;
    }
    
    selectGrantRow(evt){
        const selectedId = evt.currentTarget.id.substring(0,18);
        this.selectedGrantId = selectedId !== this.selectedGrantId ? selectedId : undefined; 
        this.setSelectedGrant();
    }

    /***** START: FINALIZE OFFER SCREEN *****/  
    createOffer(evt){
        this.loaded = false;
        const offerWizardData = {};
        const actionName = evt.currentTarget.name;
        try{
            const cmp = this.template.querySelector("c-package-offer-duration");
            if(cmp.validateDates()){
                this.deferredOpp = (this.deferredACP.length > 0 ? this.deferredACP[0] : null);
                //OPPORTUNITY CREATE LOGIC
                this.opp = cmp.opportunityRecord;
                let sortAcps = cmp.sortedACPs();
                const destinationACP = sortAcps[sortAcps.length - 1];

                this.opp.Destination_ACP__c = destinationACP.Id;
                // Opportunity Name generation logic -- START
                this.opp.Name = '';
                // First Name - handle mononymous names
                if (this.contact.First_Name__c && this.contact.First_Name__c.trim().length != 0) {
                    this.opp.Name = this.contact.First_Name__c.substring(0, 40) + ' ';
                }
                // Last Name
                this.opp.Name += this.contact.Last_Name__c.substring(0, 30);                
                // Course Code
                this.opp.Name += '-' + destinationACP.Course_Code__c.substring(0, 6);
                // Course Start date
                this.opp.Name += '-' + destinationACP.Course_Start_Date_Updated__c;
                // Opportunity Name generation logic -- END

                this.opp.Destination_Course_Name__c = destinationACP.Course_Title__c;
                this.opp.AccountId = this.contact.AccountId;
                this.opp.Fee_Category__c = this.pricebookExtId;
                this.opp.Agent_Account__c = destinationACP.Application__r.Agent__c;
                this.opp.Pricebook2 = {External_ID__c : this.pricebookExtId};
                this.opp.StageName = 'New Offer';
                this.opp.Offer_Type__c = destinationACP.Outcome_Status_LOV__r.System_Code__c;
                this.opp.PrimaryContact__c = this.recordId;
                this.opp.Regeneration_Reason__c = this.regenerationReason;
                this.opp.Signature_Type__c = cmp.getSelectedSignatureType();
                //add offer template value        
                this.opp.Offer_Template__c = this.offerTemplate;
                //Logic to extend OFFER_PROV as a Full Offer 
                if(destinationACP.Outcome_Status_LOV__r.Value__c === 'OFFER-PROV'){
                    this.opp.Offer_Type__c = 'OFFER'; 
                }else if(destinationACP.Outcome_Status_LOV__r.System_Code__c === 'COND-OFFER' && (destinationACP.Conditional_Offer_Status_LOV__r.Value__c === 'WAIVED' || destinationACP.Conditional_Offer_Status_LOV__r.Value__c === 'SATISFIED' )){
                    this.opp.Offer_Type__c = 'OFFER'; 
                }
                // Logic to mark the Opportunity either "International Offer" or "International Defer Offer" or "Domestic Offer" or "Domestic Deferral"
                if(this.newOffer) this.opp.Offer_Category__c = 'International Offer';
                if(this.deferOffer && (this.offerCategory == 'International Offer' || this.offerCategory == 'International Deferral')) this.opp.Offer_Category__c = 'International Deferral';
                if(this.deferOffer && (this.offerCategory == 'Domestic Offer' || this.offerCategory == 'Domestic Deferral')) this.opp.Offer_Category__c = 'Domestic Deferral';
                if(this.newDomesticOffer) {
                    this.opp.Offer_Category__c = 'Domestic Offer';
                    this.opp.Visa_Start_Date__c = null;
                    this.opp.Visa_End_Date__c = null;
                }
                if(this.offerTemplate === 'Online Coursework - Avenu'){
                    this.opp.Offer_Category__c = 'Online Offer';
                }

                sortAcps.forEach(acp =>{
                    let hasBDP = (acp.Application__r.Transfer_Type__c != null
                                    && acp.Application__r.Transfer_Type__c != 'Offer'
                                    && acp.Bulk_Data_Processing__c != null);
                    if(hasBDP){
                        //set bdp id value for BDP status update
                        if(acp.Bulk_Data_Processing__r.Status__c != 'Processing Offer'){
                            this.ccTransferBDPId = acp.Bulk_Data_Processing__c;  
                        }                                   
                        this.opp.Bulk_Data_Processing__c = acp.Bulk_Data_Processing__c;
                        this.opp.Offer_Type__c = 'TRANSFER';
                        return false; //exit loop
                    }
                });
                if (this.deferOffer){
                    this.opp.Original_Offer__c = this.deferredOpp.oppty.Id;
                    // SFTG-2177 Deferral Wizard to include Template ID and Type from the Parent Opportunity
                    this.opp.Offer_Template__c = this.deferredOpp.oppty.Offer_Template__c; 
                    this.opp.Template_Type__c = this.deferredOpp.oppty.Template_Type__c;

                }
                offerWizardData["courseOfferingByAcpId"] = this.getCourseOfferingByAcp(sortAcps);

                offerWizardData["opptyRecord"] = this.opp;
                offerWizardData["selectedACPList"] = sortAcps;
                offerWizardData["additionalProducts"] = this.selectedGrantIds();
                offerWizardData["selectedClauses"] = this.selectedClauses;
                offerWizardData["additionalACPClauses"] = this.additionalACPClauses;
                offerWizardData["additionalBahasaACPClauses"] = this.additionalBahasaACPClauses;
                offerWizardData["offerLapsedDate"] = this.offerLapseDate;
                offerWizardData["updatedACPs"] = this.acpUpdatesById;
                
                makeOffer( { offerRequest: JSON.stringify(offerWizardData) })
                    .then(results => {
                        this.loaded = true;
                        this.showToast('Success!!!', 'Opportunity created Successfully!!.', 'success');
                        if(actionName == 'Finish'){
                            this.navigateToRecord(results);
                        }else{
                            this.closeQuickAction();
                        }
                        
                    }).catch((err) => {
                        this.loaded = true;
                        if (err && err.body && err.body.message){
                            err = JSON.parse(err.body.message);
                            this.showToast(err.name,err.message,err.variant,'sticky');
                        }else{
                            this.showToast('Unknown Error','Something went wrong!','error','sticky');
                        }
                        console.log(err);
                    });
            } else {
                this.loaded = true;
            }
        }catch(err){
            this.loaded = true;
            console.log(err);
            this.showToast('Unknown Error','Something went wrong!','error','sticky');
        }
    }
    sortData(fieldName, sortDirection){
        let data = JSON.parse(JSON.stringify(this.acps));
        //function to return the value stored in the field
        const key = (a) => {
            let fieldValue = a[fieldName] ? a[fieldName] : '';
           return fieldValue; 
        }
        let reverse = sortDirection === 'asc' ? 1: -1;

        //set sorted data to acplist
        this.acps = data.sort((a,b) => {
            return reverse * ((key(a) > key(b)) - (key(b) > key(a)));
        });          
        
    }
    get targetCourse(){
        return sortAcps ? sortAcps[sortAcps.length - 1] : null;
    }
    getCourseOfferingByAcp(acps){
        var tmp = {};
        acps.forEach(r => {
            if (this.courseOfferingByAcpId && this.courseOfferingByAcpId[r.Id] ){
                tmp[r.Id] = this.courseOfferingByAcpId[r.Id];
            }else{
                tmp[r.Id] = r.Course_Offering__r;
            }
            console.log(JSON.stringify(tmp[r.Id]));
            if (!tmp[r.Id]){
                throw 'Course Offering not found for ' + r.Course_Title__c + '.';
            }
        });
        return tmp;
    }
    
    selectedGrantIds(){
        let t = [];
        this.grants.forEach((elem)=>{
            if (elem.selected){
                var obj = {...elem}
                delete obj.selected;
                t.push(obj);
            }
        });
        return t;
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

    navigateToRecord(results){ 
        if(this.ccTransferBDPId) this.updateBDP();
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: results.Id,
                objectApiName: 'Opportunity',
                actionName: 'view'
            }
        });
    }

    closeQuickAction() {
        if(this.ccTransferBDPId) this.updateBDP();
        const closeModal = new CustomEvent('close');
        // Dispatches the event.
        this.dispatchEvent(closeModal);
    }

    updateBDP(){
        updateBDPStatus( { bdpId: this.ccTransferBDPId, status: 'Processing Offer' })
            .then(results => {
                console.log('BDP successfully updated');
                console.log(JSON.parse(results));                
            }).catch((err) => {
                console.log(err);
            });
    }

    get canCreateAvenuOffer() {
        return createAvenuOffer;
    }
}