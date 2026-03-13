/* eslint-disable dot-notation */
/* eslint-disable guard-for-in */
/* eslint-disable no-console */
/* eslint-disable eqeqeq */
/* eslint-disable vars-on-top */
import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import calculateDates from '@salesforce/apex/OpportunityService.calculateVisaDates';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

export default class PackageOfferDuration extends LightningElement {
    @api acpList;
    @api acpRPL;
    @api opportunityRecord;
    @api offerCategory;
    @api offerTemplate;
    @api agentName;
    @track oppRec;
    @track monthsBetween;
    @track sortedAcpList;
    @track signatureType;
    @track defaultSignType = false;


    /*********************************************************************************
     * Init method to gather ACP with RPL Points and set Opportunity Record values
     */
    connectedCallback(){

        // SFTG-1960 If this is a Monash Abroad offer, Signature type to be defaulted to 'Wet Signature' 
        if (this.acpList[0].Application__r.Type_of_Study__c == 'Study Abroad' 
            || this.acpList[0].Application__r.Type_of_Study__c == 'Exchange') {
            this.signatureType = 'Wet Signature';
            this.defaultSignType = true;
        }
        //When Offer template is of type domestic, then default the signature type 
        if(!this.isNotDomesticOffer)
        {
            this.signatureType = 'Wet Signature';
            this.defaultSignType = true;
        }
        //SFTG-2175 Signature type defaulted to Not Applicable for Deferral Offers
        if (this.isDomesticDeferral) {
            if(this.offerTemplate == 'Domestic Coursework Indonesia') 
            {
                this.signatureType = 'Wet Signature';
            }else{
                this.signatureType = 'Not Applicable';
            }
            this.defaultSignType = true;
        }
        // subscribe to acps selection event from offerWizard
        registerListener('selectedacps', this.refreshedSelectedAcps, this);
        //run first load
        this.refreshedSelectedAcps(this.acpList);
    }

    disconnectedCallback() {
        // unsubscribe all events;
        unregisterAllListeners(this);
    }

    @wire(getObjectInfo, { objectApiName: 'Opportunity' })
    objectInfo;

    get currentStudentFieldInfo()
    {
        return (this.objectInfo === undefined || this.objectInfo.data === undefined) ? {} : this.objectInfo.data.fields['Is_Current_MU_Student__c'];
    }
    refreshedSelectedAcps(acps){
        if(acps){
            let data = JSON.parse(JSON.stringify(acps));
            this.oppRec = {};
            this.opportunityRecord = {};
            this.acpRPL =[];
            for(var i=0; i < data.length; i++){
                data[i]['Approved_Credit_Points__c'] = (data[i]['Approved_Credit_Points__c'] != null ? data[i]['Approved_Credit_Points__c'] : 0);
                delete data[i].selected;
                if(data[i]['Approved_Credit_Points__c'] > 0){
                    this.acpRPL.push(data[i]);
                }
            }            
            this.sortedAcpList = data;

            //sort dates to get least end date
            if (this.sortedAcpList.length > 1)this.sortData('Course_End_Date_Updated__c', 'desc');
            this.oppRec.Offer_End_Date__c = this.sortedAcpList[0].Course_End_Date_Updated__c;  
            let endDate = new Date(this.sortedAcpList[0].Course_End_Date_Updated__c);  
            
            //sort dates to get latest start date
            if (this.sortedAcpList.length > 1)this.sortData('Course_Start_Date_Updated__c', 'asc');
            this.oppRec.Offer_Start_Date__c = this.sortedAcpList[0].Course_Start_Date_Updated__c;  
            let startDate = new Date(this.sortedAcpList[0].Course_Start_Date_Updated__c);

            //calculate months between
            this.monthsBetween = this.monthDiff(startDate, endDate);
            this.monthsBetween += (this.monthsBetween > 1 ? ' months' : ' month');

            calculateDates( { 
                    startDate: startDate,
                    endDate:  endDate
                }).then(results => {
                    console.log(results);
                    this.oppRec.Visa_Start_Date__c = results.startDate;
                    this.oppRec.Visa_End_Date__c = results.endDate;
                    this.opportunityRecord = this.oppRec;
                }).catch((err) => {
                    console.error(err);
                });
        }
    }

    /********************************
     * Sorting method
     */
    sortData(fieldName, sortDirection){
        let data = JSON.parse(JSON.stringify(this.sortedAcpList));
        //function to return the value stored in the field
        const key = (a) => {
            let fieldValue = a[fieldName] ? a[fieldName] : '';
           return fieldValue; 
        }
        let reverse = sortDirection === 'asc' ? 1: -1;

        //set sorted data to acplist
        this.sortedAcpList = data.sort((a,b) => {
            return reverse * ((key(a) > key(b)) - (key(b) > key(a)));
        });          
        
    }

    @api
    sortedACPs(){
        console.log(this.sortedAcpList);
        return this.sortedAcpList;
    }

    /********************************
     * Set offer duration label
     */
    get offerDurationLabel(){
        var textDisplay = 'Offer duration without RPLs';
        if(this.acpRPL.length > 0){
            textDisplay = 'Adjusted Offer duration (with RPL)';
        }
        return textDisplay;
    }


    /********************************
     * Handles onchange event on input
     */
    handleDateChange(event){
        if(event.target.name == 'startDateInput'){
            this.oppRec.Visa_Start_Date__c = event.target.value;
        }
        else if(event.target.name == 'lastDateInput'){       
            this.oppRec.Visa_End_Date__c = event.target.value;    
        }

        if(this.oppRec.Visa_Start_Date__c > this.oppRec.Visa_End_Date__c){
            this.errorHandling('Error', 'End date should not be earlier than start date.', 'error');
            
        }else{
            //calculate months between
            this.monthsBetween = this.monthDiff(new Date(this.oppRec.Visa_Start_Date__c), new Date(this.oppRec.Visa_End_Date__c));            
            this.monthsBetween += (this.monthsBetween > 1 ? ' months' : ' month');
            this.opportunityRecord = this.oppRec;
        }
    }
    /**
     * Handles change
     */
    handleCurrentStudentChange(event){
        this.oppRec.Is_Current_MU_Student__c = event.target.checked;
        this.opportunityRecord = this.oppRec;
    }

    /********************************
     * Handles wizard validation before opportunity create
     */
    @api validateDates(){
        if(!this.oppRec.Visa_Start_Date__c || !this.oppRec.Visa_End_Date__c){
            this.errorHandling('Offer Error', 'Visa Start and End Dates are mandatory', 'error');
            return false;
        }
        if(this.oppRec.Visa_Start_Date__c > this.oppRec.Visa_End_Date__c){
            this.errorHandling('Offer Error', 'End Date should not be earlier than Start Date.', 'error');
            return false;
        }
        if (!this.signatureType){
            this.errorHandling('Offer Error','Please select a Signature Type', 'error');
            return false;
        }
        return true;
    }
    @api getSelectedSignatureType(){
        return this.signatureType;
    }
    handleSignatureSelection(event) {
        this.signatureType = event.detail.value;
    }
    get signatypeTypeOptions() {
        var signList;
       if(this.isNotDomesticOffer)
        {
            if(this.isDomesticDeferral) {
                if(this.offerTemplate == 'Domestic Coursework Indonesia') 
                {
                    signList =  [
                        { label: 'N/A', value: 'Wet Signature' }
                    ];
                }else{
                    signList =  [
                        { label: 'N/A', value: 'Not Applicable' }
                    ];
                }
             
            } else {
                signList =  [
                    { label: 'Digital Signature', value: 'Digital Signature' },
                    { label: 'Wet Signature', value: 'Wet Signature' }
                ];
            }
        } else {
            signList =  [
                { label: 'N/A', value: 'Wet Signature' }
            ];
        }

        return   signList;
           
    }
    /********************************
     * Calculate the months between two dates considering dates
     */
    monthDiff(d1, d2) {
        //return dateTo.getMonth() - dateFrom.getMonth() +  (12 * (dateTo.getFullYear() - dateFrom.getFullYear()))
        
        var ydiff = d2.getYear() - d1.getYear();
        var mdiff = d2.getMonth() - d1.getMonth();
        var ddiff = 1 + d2.getDate() - d1.getDate();
        
        var months = (ydiff*12 + mdiff);
        var diff = (months + ".") + ddiff;
        return ddiff < 0 ? (months-1) : months;
    }

    errorHandling(title, message, type){
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message, 
                variant: type,
            }),
        ); 
    }

    get isNotDomesticOffer() {
        if (this.offerCategory == 'Domestic Offer' || this.offerTemplate === 'Online Coursework - Avenu') {
            return false;
        }
        return true;
    }

    get isDomesticDeferral() {
        if (this.offerCategory == 'Domestic Deferral') {
            return true;
        }
        return false;
    }

}