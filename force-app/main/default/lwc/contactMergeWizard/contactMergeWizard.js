/**
 * Created by rcad0001 on 29/09/2020. 
 */
/* LWC SERVICES */
import {
    LightningElement,
    api,
    track,
    wire
} from "lwc";
import {
    reduceErrors
} from "c/ldsUtils";
import {
    ShowToastEvent
} from "lightning/platformShowToastEvent";

import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';

/* APEX SERVICES */
import getEntityData from "@salesforce/apex/ContactMergeController.getEntityData";
import mergeUserRecords from "@salesforce/apex/ContactMergeController.mergeUser";
import mergeAccountRecords from "@salesforce/apex/ContactMergeController.mergeAccount";
import mergeContactRecords from "@salesforce/apex/ContactMergeController.mergeContact";
import mergeLeadRecords from "@salesforce/apex/ContactMergeController.recalculatePrimaryLeads";
import recalCulateContactPoints from "@salesforce/apex/ContactMergeController.recalCulateContactPoints";
import evaluateCulateContactPoints from "@salesforce/apex/ContactMergeController.evaluateCulateContactPoints";
import sendMergeConfirmation from "@salesforce/apex/ContactMergeController.sendMergeConfirmation";
import elevatePermissions from "@salesforce/apex/ContactMergeController.elevatePermissions";
import updateUserMergeStatus from "@salesforce/apex/ContactMergeController.updateUserMergeStatus";
import hasValidationBypass from "@salesforce/apex/ContactMergeController.hasValidationBypass";
import getContactData from "@salesforce/apex/ContactMergeController.getContactData";

const statusCols = [
        { label: 'sObject', fieldName: 'sObjectType'},
        { label: 'Is Primary', fieldName: 'isPrimary', type: "boolean"},
        { label: 'Record Id', fieldName: 'recordLink', type: 'url', typeAttributes: { 
            label: { fieldName: 'recordId'},
            target: '_blank' }},
        { label: 'Status', fieldName: 'status' },
        { label: 'Message', fieldName: 'errorMessage'}
    ];


export default class ContactMergeWizard extends NavigationMixin(LightningElement) {
    // form variables
    @track email = "";
    @track fname = "";
    @track lname = "";
    @track personid = "";
    @track conid = "";
    @track showSpinner = false;
    @track data = [];
    @track hasData = false;
    @track areAllSelected;
    @track openModal = false;

    // step progress indicators
    @track currentStepDesc = "";
    @track currentStep = "1";
    @track currentSubStepDesc = "";

    // object merging indices
    @track userMergeIndex = 0;
    @track accountMergeIndex = 0;
    @track contactMergeIndex = 0;

    // user id containers
    @track primaryUserId;
    @track primaryPermSetIds = [];
    @track duplicateUsers = [];
    @track duplicatePermSetIds = [];
    @track dupUserNames = [];
    @track userIdAskMonash = new Set();
    // account id containers
    @track primaryAccountId;
    @track duplicateAccountIds = [];
    // contact id containers
    @track primaryContactId;
    @track duplicateContactIds = [];
    //Status and Retry
    mergestatusList = new Map();
    @track mergestatusValues = [];
    // entity container
    @track primaryEntity;
    //Timer
    @track timeVal = '0:0:0:0';
    timeIntervalInstance;
    totalMilliseconds = 0;
    hasNonHouseholdAccounts = false;
    //Do not reset values of bypass
    hasBypassValidation = false;
    
    excludedFromMerge = false;

    // Array of dplicate contact Ids
    conIds = [];
    // Contact values at the time of display and at the time of save(used to identify data updates)
    oldValues = {};
    newValues = {};

    @track currentPageReference;
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
    }

    //Getter
    get isLastStep() {
        let bvAl = false;
        if (this.currentStep === "9") {
            bvAl = true;
        }
        return bvAl;
    }

    get passedfname() {
        return this.currentPageReference?.state?.c__fname;
    }

    get passedlname() {
        return this.currentPageReference?.state?.c__lname;
    }

    get passedemail() {
        return this.currentPageReference?.state?.c__email;
    }

    get passedpersonid() {
        return this.currentPageReference?.state?.c__personid;
    }

    progressSteps = [{
            label: "Initialisation",
            value: "1"
        },
        {
            label: "User",
            value: "2"
        },
        {
            label: "Accounts",
            value: "3"
        },
        {
            label: "Contacts",
            value: "4"
        },
        {
            label: "Leads",
            value: "5"
        },
        {
            label: "Evaluate Contact Points",
            value: "6"
        },
        {
            label: "Re-calculate Contact Points",
            value: "7"
        },
        {
            label: "Sending Notification",
            value: "8"
        },
        {
            label: "Completed",
            value: "9"
        }
    ];

    statusCols = statusCols;
    /*
    * Init 
    */
    connectedCallback() {
        //Checks for CustomPermission - Contact_Merge_Bypass_Check
        hasValidationBypass()
        .then((result) => {
            this.hasBypassValidation = result;
            console.log('Can Bypass',this.hasBypassValidation);
            this.fname = this.passedfname == undefined ? '' : this.passedfname;
            this.lname = this.passedlname == undefined ? '' : this.passedlname;
            this.email = this.passedemail == undefined ? '' : this.passedemail;
            this.personid = this.passedpersonid == undefined ? '' : this.passedpersonid;
            if(this.fname || this.lname || this.email || this.personid){
                this.searchOnClick();
            }
        })
        .catch((error) => {
            console.error(error);
        });
    }

    /*
     * Method Name: searchOnClick
     * Description: method to query entity data from controller with some pre-invocation validations
     */
    searchOnClick() {
        this.hasData = false;
        //field validations
        if (
            this.fname == "" &&
            this.lname == "" &&
            this.email == "" &&
            this.personid == "" &&
            this.conid == ""

        ) {
            this.showToast("Error", "Please enter search parameter.", "Error");
        } else if (this.fname != "" && this.lname == "") {
            this.showToast("Error", "Please enter Last Name.", "Error");
        }else {
            if (this.conid != "" && (this.conid.length != 15 && this.conid.length != 18) ) {
                this.showToast(
                    "Error",
                    "Please enter 15 or 18 digit Contact Id.",
                    "Error"
                );
            }
            else {
                this.getData();
            }
        }
    }

    /*
     * Method Name: setValue
     * Description: method to set value from the UI to search parameter variables
     */
    setValue(event) {
        let fieldname = event.target.name;
        let fieldvalue = event.detail.value;

        if (fieldname == "fname") {
            this.fname = fieldvalue.trim();
        }
        if (fieldname == "lname") {
            this.lname = fieldvalue.trim();
        }
        if (fieldname == "email") {
            var input = this.template.querySelector(".input");
            if(input.validity.valid){
                this.email = fieldvalue.trim();
            }
            else{
                input.reportValidity();
            }
        }
        if (fieldname == "personid") {
            this.personid = fieldvalue.trim();
        }
        if (fieldname == "conid") {
             this.conid = fieldvalue.trim();
        }
    }

    /*
     * Method Name: showToast
     * Description: method to show toast
     */
    showToast(toastTitle, toastMessage, toastVariant) {
        const toast = new ShowToastEvent({
            title: toastTitle,
            message: toastMessage,
            variant: toastVariant,
        });
        this.dispatchEvent(toast);
    }

    /*
     * Method Name: getData
     * Description: method to call apex function passing parameters from the UI
     */
    getData() {
        this.showSpinner = true;
        getEntityData({
                firstName: this.fname,
                lastName: this.lname,
                email: this.email,
                personId: this.personid,
                contactId: this.conid
            })
            .then((result) => {
                let datalist = result;
                if (datalist.length > 0) {
                    this.data = [];
                    this.data = datalist;
                    this.hasData = true;
                    this.areAllSelected = true;
                    this.showSpinner = false;

                    // Collect duplicate contact Ids and related data
                    this.data.forEach((rec) => {
                        this.conIds.push(rec.contactRecord.Id );
                        this.oldValues[rec.contactRecord.Id] = rec.contactRecord.Exclude_From_Merge__c;
                    });

                } else {
                    // fire toast
                    this.showToast("Error", "No matching duplicates found.", "Error");
                    this.hasData = false;
                    this.showSpinner = false;
                }
            })
            .catch((error) => {
                this.showToast(
                    "Error",
                    "An error has occurred: " + error.body.message,
                    "Error"
                );
                this.hasData = false;
                this.showSpinner = false;
            });
    }

    /*
     * Method Name: getConData
     * Description: method to call apex function passing parameters from the UI
     */
    getConData() {
        getContactData({
                contactIds: this.conIds
            })
            .then((result) => {
                if(result){
                    console.log(JSON.parse(JSON.stringify(result)));
                    result.forEach((rec) => {
                        this.newValues[rec.Id] = rec.Exclude_From_Merge__c;
                    });
                }
                let noChange = this.deepEqual(this.oldValues, this.newValues);
                // If data was not modified, validate and process merge selection
                if(noChange){
                    this.validateAndProcess();
                }
                // If data was modified, refresh data displayed and warn user
                else{
                    // Method to refresh UI data
                    this.getData();
                    this.showToast(
                        "Error",
                        "Contact data was modified, review selection.",
                        "Error"
                    );
                }
            })
            .catch((error) => {
                this.showToast(
                    "Error",
                    "An error has occurred: " + error.body.message,
                    "Error"
                );
            });
    }

    /*
     * Method Name: resetAll
     * Description: method to reset container variables
     */
    resetAll() {
        this.showSpinner = true;
        this.email = "";
        this.fname = "";
        this.lname = "";
        this.personid = "";
        this.conid = "";
        this.data = [];
        this.hasData = false;

        this.currentStepDesc = "";
        this.currentStep = "1";
        this.currentSubStepDesc = "";

        // object merging indices
        this.userMergeIndex = 0;
        this.accountMergeIndex = 0;
        this.contactMergeIndex = 0;

        // user id containers
        this.primaryUserId = undefined;
        this.primaryPermSetIds = [];
        this.duplicateUsers = [];
        this.duplicatePermSetIds = [];
        this.dupUserNames = [];
        this.userIdAskMonash = new Set();
        // account id containers
        this.primaryAccountId = undefined;
        this.duplicateAccountIds = [];

        // contact id containers
        this.primaryContactId = undefined;
        this.duplicateContactIds = [];
        this.mergestatusList = new Map();
        this.mergestatusValues = [];
        // entity container
        this.primaryEntity = undefined;

        this.showSpinner = false;
        this.hasNonHouseholdAccounts = false;
        //
        this.stopTimer();
        this.resetTimer();
    }

    /*
     * Method Name: toggleInclusion
     * Description: method to toggle data isIncluded flag and the include button class based from the ui selection
     */
    toggleInclusion(event) {
        let recid = event.target.dataset.recid;

        this.data.forEach((rec) => {
            // set data value
            if (rec.contactRecord.Id === recid) {
                rec.isIncluded = !rec.isIncluded;
            }

            // set include button class when selected
            if (rec.isIncluded) {
                rec.includeClass = "success";
            }
            // set include button class when unselected
            else {
                rec.includeClass = "neutral";

                // if the record is unselected but primary, revert the unselection
                if (rec.isPrimary) {
                    rec.isIncluded = true;
                    rec.includeClass = "success";
                }
            }
        });
    }
    /*
     * Method Name: togglePrimary
     * Description: method to toggle data isPrimary flag and the primary button class based from the ui selection
     */
    togglePrimary(event) {
        let recid = event.target.dataset.recid;

        let hasPrimary = false;
        // toggle own button
        this.data.forEach((rec) => {
            // set data value
            if (rec.contactRecord.Id === recid) {
                rec.isPrimary = !rec.isPrimary;
            } else {
                rec.isPrimary = false;
            }

            // set primary button class when selected
            if (rec.isPrimary) {
                rec.primaryClass = "success";
                // if the record is selected as primary, force include it
                if (!rec.isIncluded) {
                    rec.isIncluded = true;
                    rec.includeClass = "success";
                }
            }
            //set include button class when unselected
            else {
                rec.primaryClass = "neutral";
            }
            // boolean checker that the list has a primary record
            if (rec.isPrimary) {
                hasPrimary = true;
            }
        });

        // check if none is toggled as primary, if true then force primary the first in the list
        if (!hasPrimary) {
            this.data[0].isIncluded = true;
            this.data[0].includeClass = "success";
            this.data[0].isPrimary = true;
            this.data[0].primaryClass = "success";
        }
    }

    /*
     * Method Name: toggleAllSelected
     * Description: method to toggle all cards
     */
    toggleAllSelected() {
        if (this.areAllSelected) {
            this.data.forEach((rec) => {
                // set data value
                if (!rec.isPrimary) {
                    rec.isIncluded = false;
                    rec.includeClass = "neutral";
                }
            });
            this.areAllSelected = false;
        } else if (!this.areAllSelected) {
            this.data.forEach((rec) => {
                // set data value
                rec.isIncluded = true;
                rec.includeClass = "success";
            });

            this.areAllSelected = true;
        }
    }

    /*
     * Method Name: mergeOnClick
     * Description: method to start the merge process
     */
    mergeOnClick() {
        this.getConData();
    }

    /*
     * Method Name: validateAndProcess
     * Description: method to validate and start the merge process
     */
    validateAndProcess(){
        this.resetTimer();
        if (this.doValidation()) {
            //Begin Timer
            this.startTimer();
            //
            this.showModal()
                .then((res) => {
                    //Activate Session Permissions
                    return elevatePermissions({
                        isElev:true
                    });
                })
                .then((res) => {
                    // set current step to 2 (User record merging)
                    this.currentStep = "2";
                    this.currentStepDesc = "(2/9) Updating user records...";
                    return this.mergeUsers();
                })
                .then((res) => {
                    // set current step to 3 (Account record merging)
                    this.currentStep = "3";
                    this.currentStepDesc = "(3/9) Merging account records...";
                    return this.mergeAccounts();
                })
                .then((res) => {
                    // set current step to 4 (Contact record merging)
                    this.currentStep = "4";
                    this.currentStepDesc = "(4/9) Merging contact records...";
                    return this.mergeContacts();
                })
                .then((res) => {
                    // set current step to 5 (User record merging)
                    this.currentStep = "5";
                    this.currentStepDesc = "(5/9) Updating lead records...";
                    return this.mergeLeads();
                })
                .then((res) => {
                    // recalculate contact points
                    this.currentStep = "6";
                    this.currentStepDesc =
                        "(6/9) Evaluate Contact Points for Surviving Contact...";
                    return this.reEvalContactPoints();
                })
                .then((res) => {
                    // recalculate contact points
                    this.currentStep = "7";
                    this.currentStepDesc =
                        "(7/9) Recalculating Contact Points for Surviving Contact...";
                    return this.recomputeContactPoints();
                })
                .then((res) => {
                    //Update merge status on User to 'Complete'
                    return this.updateUserMergeStatusToComplete();
                })
                .then((res) => {
                    // sendNotification
                    this.currentStep = "8";
                    if(this.dupUserNames.length > 0){
                        this.currentStepDesc = "(8/9) Sending Notification...";
                    }else{
                        this.currentStepDesc = "(8/9) Skipped Sending Notification...";
                    }
                    return this.sendNotification();
                })
                .then((res) => {
                    //Deactivate Session Permissions
                    return elevatePermissions({
                        isElev:false
                    });
                })
                .then((res) => {
                    // Define Summary
                    if(this.mergestatusList != null && this.mergestatusList.size > 0){
                        this.mergestatusList.forEach((val,_ind,_mp)=>{
                            this.mergestatusValues.push(val);
                        });
                    }
                    //
                    this.currentStep = "9";
                    this.currentStepDesc = "(9/9) Summary Report";
                    this.stopTimer();
                })
                .catch((error) => {
                    //De-activate Session Permissions
                    elevatePermissions({
                        isElev:false
                    });
                    //
                    this.showToast(
                        "Error",
                        "An error has occurred. Message: " + error.reason,
                        "Error"
                    );
                    this.stopTimer();
                    this.resetTimer();
                });
        }
    }

    showModal() {
        // open modal
        this.openModal = true;
        // show warning toast
        this.showToast(
            "Warning",
            "Performing merge. Please do not refresh/close the window.",
            "Warning"
        );
        return Promise.resolve(true);
    }

    closeModal() {
        // open modal
        this.openModal = false;
        this.resetAll();
        return Promise.resolve(true);
    }

    doValidation() {
        // flush values first before assigning
        let result = false;
        let selectCount = 0;
        let index = 0;

        this.primaryUserId = undefined;
        this.primaryPermSetIds = [];
        this.duplicateUsers = [];
        this.duplicatePermSetIds = [];
        this.dupUserNames = [];
        this.primaryAccountId = undefined;
        this.duplicateAccountIds = [];
        this.userIdAskMonash = new Set();
        this.primaryContactId = undefined;
        this.duplicateContactIds = [];

        this.mergestatusValues = [];
        this.personIds = new Set();
        this.hasNonHouseholdAccounts = false;
        this.excludedFromMerge = false;
        try{
            this.data.forEach((rec) => {
                if (rec.isIncluded) {
                    selectCount++;
                    if(rec.contactRecord.Person_ID__c !== null && rec.contactRecord.Person_ID__c !== '' && rec.contactRecord.Person_ID__c !== undefined){
                        this.personIds.add(rec.contactRecord.Person_ID__c); 
                    }        
                    if (rec.isPrimary) {
                        // identity primary entity
                        this.primaryEntity = rec;
                        // identity primary user and permission sets
                        if (rec.userRecord != undefined) {
                            this.primaryUserId = rec.userRecord.Id;
                            this.primaryPermSetIds = rec.permissionSetIds;
                        }

                        // identify primary account
                        this.primaryAccountId = rec.accountRecord.Id;

                        // identify primary contact
                        this.primaryContactId = rec.contactRecord.Id;
                    } else {
                        // identify duplicate users and permission sets
                        if (rec.userRecord != undefined) {
                            this.duplicateUsers[index] = rec.userRecord.Id;
                            this.duplicatePermSetIds[index] = rec.permissionSetIds;
                            //Checks for ASkMonash on Duplicates to exclude
                            
                            if(rec.communityAccesses.length == 1){
                                if(rec.communityAccesses.includes('Ask Monash')){
                                    this.userIdAskMonash.add(rec.userRecord.Id);
                                }
                            }
                        }

                        // identify duplicate accounts
                        this.duplicateAccountIds[index] = rec.accountRecord.Id;

                        // identify duplicate contacts
                        this.duplicateContactIds[index] = rec.contactRecord.Id;
                        index++;
                    }
                    //Check for Non-Household accounts selected for merge
                    let accountRecType = rec.contactRecord.Account.RecordType.Name;
                    if(accountRecType && accountRecType !== 'Household'){
                        this.hasNonHouseholdAccounts = true;
                    }

                    // Check for contacts excluded from merging
                    if(rec.excludedFromMerge === "Yes"){
                        this.excludedFromMerge = true;
                    }
                }
            });
        }catch(err){
            this.showToast(
				"Error",
				"An error has occurred: " + err.body.message,
				"Error"
			);
        }
        
        let hasPrimaryUserFavorable = false;

        if(this.primaryUserId == undefined){
            this.data.forEach((rec) => {
                if(rec.isIncluded){
                    if(rec.userRecord != undefined){
                        hasPrimaryUserFavorable = true;
                    }
                }
            });
        }

        if(this.personIds.size > 1){
            this.showToast(
                "Error",
                "The included contacts cannot have different Person Ids.",
                "Error"
            );
        }
        else if(hasPrimaryUserFavorable){
            this.showToast(
                "Error",
                "When merging portal enabled accounts, the master record must be portal enabled.",
                "Error"
            );
        }
        else if (selectCount < 2) {
            this.showToast(
                "Error",
                "Please select at least two records to perform the merge.",
                "Error"
            );
        }
        else if (this.hasBypassValidation === false && this.hasNonHouseholdAccounts === true) {
            this.showToast(
                "Error",
                "Please select only Household Accounts to perform the merge.",
                "Error"
            );
        } 
        else if (this.excludedFromMerge === true) {
            this.showToast(
                "Error",
                "One of the contacts have been marked to be excluded from merging.",
                "Error"
            );
        } else {
            result = true;
        }

        return result;
    }

    /* USER PROCESS MERGING METHODS */
    async mergeUsers() {
        this.currentSubStepDesc = "";
        let indexC = 0;
        if(this.primaryUserId != undefined){
            this.mergestatusList.set(this.primaryUserId,{
                "isPrimary":true,
                "status":"Retained",
                "sObjectType":"User",
                "recordId":this.primaryUserId,
                "recordLink":"/"+this.primaryUserId,
                "errorMessage":""
            });
        }

        if(this.primaryUserId != undefined && this.duplicateUsers.length > 0){
            for(let du of this.duplicateUsers){
                if(du != null){
                    let respVal;
                    let dUserId = du;
                    let dPermSetIds = this.duplicatePermSetIds[indexC];
                    let result = {
                        "status":'fulfilled',
                        "reason":""
                    };
                    this.currentSubStepDesc = (indexC+1)+' of '+this.duplicateUsers.length+' User Records';
                    respVal = await mergeUserRecords({
                        primaryUserId: this.primaryUserId,
                        duplicateUserId: dUserId,
                        primaryPermSetIds: this.primaryPermSetIds,
                        duplicatePermSetIds: dPermSetIds,
                    }).catch((err)=>{
                        result = {
                            "status":"rejected",
                            "reason":err
                        };
                    });

                    if(respVal !== null && respVal !== ''){
                        let marr = this.dupUserNames;
                        if(this.userIdAskMonash.has(respVal.userId) === false){
                            marr.push(respVal);
                        }
                        this.dupUserNames = marr;
                    }
                    //
                    this.setMergeStatus('User', dUserId, result);
                    indexC++;
                }
            }
        }
        return Promise.resolve("Success");
    }
    /* ACCOUNT PROCESS MERGING METHOD */
    async mergeAccounts() {
        let indexC = 0;
        this.currentSubStepDesc = "";
        this.mergestatusList.set(this.primaryAccountId,{
            "isPrimary":true,
            "status":"Retained",
            "sObjectType":"Account",
            "recordId":this.primaryAccountId,
            "recordLink":"/"+this.primaryAccountId,
            "errorMessage":""
        });
        for(let du of this.duplicateAccountIds){
            let respVal;
            let dAccountId = du;
            let result = {
                "status":'fulfilled',
                "reason":""
            };
            this.currentSubStepDesc = (indexC+1)+' of '+this.duplicateAccountIds.length+' Account Records';
            respVal = await mergeAccountRecords({
                primaryAccountId: this.primaryAccountId,
                duplicateAccountId: dAccountId,
                primaryContactId: this.primaryContactId
            }).catch((err)=>{
                result = {
                    "status":"rejected",
                    "reason":err
                };
            });
            this.setMergeStatus('Account', dAccountId, result);
            indexC++;
        }
        return Promise.resolve("Success");
    }

    /* CONTACT PROCESS MERGING METHODS */
    async mergeContacts() {
        let indexC = 0;
        this.currentSubStepDesc = "";
        this.mergestatusList.set(this.primaryContactId,{
            "isPrimary":true,
            "status":"Retained",
            "sObjectType":"Contact",
            "recordId":this.primaryContactId,
            "recordLink":"/"+this.primaryContactId,
            "errorMessage":""
        });
        for(let du of this.duplicateContactIds){
            let respVal;
            let dContactId = du;
            let result = {
                "status":'fulfilled',
                "reason":""
            };
            this.currentSubStepDesc = (indexC+1)+' of '+this.duplicateContactIds.length+' Contact Records';
            respVal = await mergeContactRecords({
                primaryContactId: this.primaryContactId,
                duplicateContactId: dContactId,
            }).catch((err)=>{
                result = {
                    "status":"rejected",
                    "reason":err
                };
            });
            this.setMergeStatus('Contact', dContactId, result);
            indexC++;
        }
        return Promise.resolve("Success");
    }

    async mergeLeads() {
        this.currentSubStepDesc = "";
        let lresp = await mergeLeadRecords({
                primaryContactId: this.primaryContactId,
            }).catch((error) => {
                this.mergestatusList.set("Lead Reparent"+this.primaryContactId,{
                   "isPrimary":true,
                   "status":"Failed",
                   "sObjectType":"Lead",
                   "recordId":this.primaryContactId,
                   "errorMessage":error.reason
                });
            });
        return Promise.resolve(this.primaryContactId);
    }

    async recomputeContactPoints() {
        this.currentSubStepDesc = "";
        let lresp = await recalCulateContactPoints({
                primaryContactId: this.primaryContactId,
                byPass: false
            }).catch((error) => {
                this.mergestatusList.set("Contact Points "+this.primaryContactId,{
                   "isPrimary":true,
                   "status":"Failed",
                   "sObjectType":"Contact Points",
                   "recordId":this.primaryContactId,
                   "errorMessage":error.reason
                });
            });
        return Promise.resolve(this.primaryContactId);
    }
    async reEvalContactPoints() {
        this.currentSubStepDesc = "";
        let lresp = await evaluateCulateContactPoints({
                primaryContactId: this.primaryContactId,
            }).catch((error) => {
                this.mergestatusList.set("Evaluate "+this.primaryContactId,{
                   "isPrimary":true,
                   "status":"Failed",
                   "sObjectType":"Contact Points",
                   "recordId":this.primaryContactId,
                   "errorMessage":error.reason
                });
            });
        return Promise.resolve(this.primaryContactId);
    }
    async sendNotification() {
        this.currentSubStepDesc = "";
        let strMergeUsers = JSON.stringify(this.dupUserNames);
        
        let lresp = await sendMergeConfirmation({
                primaryUserId: this.primaryUserId,
                dupAccountEmails: strMergeUsers
            }).catch((error) => {
                this.mergestatusList.set("Notification "+this.primaryUserId,{
                   "isPrimary":false,
                   "status":"Failed",
                   "sObjectType":"EmailMessage",
                   "recordId":this.primaryUserId,
                   "errorMessage":error.reason
                });
            });
        return Promise.resolve(this.primaryUserId);
    }

    async updateUserMergeStatusToComplete() {
        let lresp = await updateUserMergeStatus({
            primaryContactUserId: this.primaryUserId,
            }).catch((error) => {
                result = {
                    "status":"rejected",
                    "reason":error
                };
            });
        return Promise.resolve(this.primaryUserId);
    }

    //
    setMergeStatus(sObjectType, dupeId, res) {
        this.data.forEach((rec) => {
            if (
                (sObjectType == "User" && rec.userRecord != undefined && rec.userRecord.Id == dupeId) ||
                (sObjectType == "Account" && rec.accountRecord.Id == dupeId) ||
                (sObjectType == "Contact" && rec.contactRecord.Id == dupeId)
            ) {
                
                let sStConv = 'Merged';
                if(sObjectType == "User"){
                    sStConv = "Deactivated";
                }
                if (res.status == 'fulfilled') {
                    this.mergestatusList.set(dupeId,{
                        "isPrimary":false,
                        "status":sStConv,
                        "sObjectType":sObjectType,
                        "recordId":dupeId,
                        "recordLink":"/"+dupeId,
                        "errorMessage":""
                    });
                } else {
                    let excepTnMsg = this.parseError(res.reason);
                    if (res.status == 'rejected') {
                        this.mergestatusList.set(dupeId, {
                            "isPrimary":false,
                            "status":"Failed",
                            "sObjectType":sObjectType,
                            "recordId":dupeId,
                            "recordLink":"/"+dupeId,
                            "errorMessage": excepTnMsg
                        });
                    }
                }
            }
        });
    }
    parseError(objErr) {
        let errMsg;
        if (objErr != null) {
            let errArr = reduceErrors(objErr);
            if (Array.isArray(errArr)) {
                errMsg = errArr[0];
            }
        }
        return errMsg;
    }
    handleKeyPress({
        code
    }) {
        if (code === 'Enter') {
            this.searchOnClick();
        }
    }
    startTimer() {
        let parentThis = this;
        // Run timer code in every 100 milliseconds
        this.timeIntervalInstance = setInterval(function() {

            // Time calculations for hours, minutes, seconds and milliseconds
            let hours = Math.floor((parentThis.totalMilliseconds % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
            let minutes = Math.floor((parentThis.totalMilliseconds % (1000 * 60 * 60)) / (1000 * 60));
            let seconds = Math.floor((parentThis.totalMilliseconds % (1000 * 60)) / 1000);
            let milliseconds = Math.floor((parentThis.totalMilliseconds % (1000)));
            
            // Output the result in the timeVal variable
            parentThis.timeVal = hours + ":" + minutes + ":" + seconds + ":" + milliseconds; 
            parentThis.totalMilliseconds += 100;
        }, 100);
    }

    stopTimer() {
        this.showStartBtn = true;
        clearInterval(this.timeIntervalInstance);
    }

    resetTimer() {
        this.showStartBtn = true;
        this.timeVal = '0:0:0:0';
        this.totalMilliseconds = 0;
        clearInterval(this.timeIntervalInstance);
    }
    
    /*
     * Method Name: deepEqual
     * Description: Deep compare js objects
     */
    deepEqual(object1, object2) {
        const keys1 = Object.keys(object1);
        const keys2 = Object.keys(object2);
      
        if (keys1.length !== keys2.length) {
          return false;
        }
      
        for (const key of keys1) {
          const val1 = object1[key];
          const val2 = object2[key];
          const areObjects = this.isObject(val1) && this.isObject(val2);
          if (
            areObjects && !deepEqual(val1, val2) ||
            !areObjects && val1 !== val2
          ) {
            return false;
          }
        }
      
        return true;
    }
      
    isObject(object) {
        return object != null && typeof object === 'object';
    }
}