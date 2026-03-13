/**
 * Created by rcad0001 on 23/10/2019.
 */

/* LWC services */
import { LightningElement, api, track, wire} from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/* Apex services */
import getData from '@salesforce/apex/PreferenceCentreServices.fetchData';
import updateMySubscriptions from '@salesforce/apex/PreferenceCentreServices.saveCampaignMember';
import updateMyContact from '@salesforce/apex/PreferenceCentreServices.saveContact';

/* Custom Labels */
import header from '@salesforce/label/c.PrefCentre_Header';
import subHeader from '@salesforce/label/c.PrefCentre_Sub_Header';
import channelHeader from '@salesforce/label/c.PrefCentre_Channel_Header';
import preferenceHeader from '@salesforce/label/c.PrefCentre_Preference_Header';

import modalHeaderOptOut from '@salesforce/label/c.PrefCentre_Modal_Header_OputOut';
import modalHeaderSave from '@salesforce/label/c.PrefCentre_Modal_Header_Save';
import modalSubHeaderOptOut from '@salesforce/label/c.PrefCentre_Modal_SubHeader_OptOut';
import modalOptOutChannels from '@salesforce/label/c.PrefCentre_OptOut_Channels';
import modalOptOutSubscriptions from '@salesforce/label/c.PrefCentre_OptOut_Subscriptions';
import modalOptOutReasonHeader from '@salesforce/label/c.PrefCentre_Reason_Header';
import successMessage from '@salesforce/label/c.PrefCentre_Success_Message';
import errorMessage from '@salesforce/label/c.PrefCentre_Error_Message';
import noChangeMessage from '@salesforce/label/c.PrefCentre_No_Change_Message';

export default class PreferenceCentre extends LightningElement {
    /* MODAL PROPERTIES */
    @track openModalBox = false;

    /* API PROPERTIES */
    // person affiliation
    @api affiliation;
    // centre name
    @api centreName;

    /* LOGIC PROPERTIES */
    // contact object
    @track myContact;
    // list of subscription objects
    @track mySubscriptions;
    // subscription
    @track myConsents;
    // wired data
    wiredData;
    // fieldToLabel map
    fieldToLabelMap;

    /* LOGIC PLACEHOLDERS */
    @track listContactOptOuts;
    @track contactHasOptOut;
    @track listSubOptOuts;
    @track subHasOptOut;
    @track hasOptOutFlag;
    @track headerMessage;
    @track optOutReason;
    @track allChangedSubscriptions;
    @track hasSubChanged;
    @track hasConChanged;
    @track isProcessComplete;
    @track reasons;


    // Expose the labels to use in the template.
    label = {
        header,
        subHeader,
        channelHeader,
        preferenceHeader,
        modalHeaderOptOut,
        modalHeaderSave,
        modalSubHeaderOptOut,
        modalOptOutChannels,
        modalOptOutSubscriptions,
        modalOptOutReasonHeader,
        successMessage,
        errorMessage,
        noChangeMessage,
    };

    // method to call apex service to retrieve cached data from database
    @wire( getData, {myAffiliation: '$affiliation'})
    handleData(result) {
        try{
            // get the whole data
            this.wiredData = result;

            if(result !== undefined){
                // success data result
                if(result.data){
                    // if contact object exists, assign to an object list
                    if(result.data.myCurrentContact){

                        // get the contact object from the data
                        this.myContact = Object.assign({}, result.data.myCurrentContact);

                        // if list of subscription object exists, assign to a list
                        if(result.data.myCurrentSubscriptions){
                            // instantiate the subscription list
                            this.mySubscriptions = [];

                            // parse each object first before pushing into the list
                            for(var i=0; i< result.data.myCurrentSubscriptions.length; i++){
                                var thisSub = Object.assign({}, result.data.myCurrentSubscriptions[i]);
                                this.mySubscriptions.push(thisSub);
                            }
                        }
                    }

                    // get the consent object
                    this.myConsents = result.data.myApplicableConsent;
                    this.fieldToLabelMap = result.data.fieldToDisplayMap;
                    this.reasons = result.data.optOutReasons;
                }
            }
        }
        catch(e){console.error(e)}
    }

    /*
        open modal logic
        1) Identify any option changes in both contact and subscription (if existing) levels
        2) Once the changes have been identified,
            a) Store it in a list for display (opt-outs only)
            b) tick all the necessary flags for front-end navigation
            c) change the necessary labels for front-end display
    */
    openModal() {
        this.openModalBox = true;

        // Identify the opt in/outs
        // contact level
        var oldContact = this.wiredData.data.myCurrentContact;

        var contactOptIns = [];
        var contactOptouts = [];
        this.hasConChanged = false;
        for(var prop in this.myContact){
            var newValue = this.myContact[prop];
            var priorValue = oldContact[prop];

            if(typeof oldContact[prop] === "boolean"){
                if(newValue !== priorValue){
                    this.hasConChanged = true;
                    var label = this.fieldToLabelMap[prop].Display_Label__c;
                    if(label !== undefined){
                        if(newValue == true){

                            if(prop == "HasOptedOutOfEmail" || prop == "SMS_Opt_Out__c" || prop == "DoNotCall" || prop == "Direct_Mail_Opt_Out__c" || prop == "Commercial_Opt_Out__c"){
                                // opt out
                                contactOptouts.push(label);
                            }
                            else{
                                // opt in
                                contactOptIns.push(label);
                            }
                        }
                        else{
                            if(prop == "HasOptedOutOfEmail" || prop == "SMS_Opt_Out__c" || prop == "DoNotCall" || prop == "Direct_Mail_Opt_Out__c" || prop == "Commercial_Opt_Out__c"){
                                // opt out
                                contactOptIns.push(label);
                            }
                            else{
                                // opt in
                                contactOptouts.push(label);
                            }
                        }
                    }
                }
            }
        }

        // subscription level
        var subOptIn = [];
        var subOptOut = [];
        this.hasSubChanged = false;
        if(this.mySubscriptions){
            this.allChangedSubscriptions = [];
            for(var i=0; i < this.wiredData.data.myCurrentSubscriptions.length; i++){
                for(var i2=0; i2 < this.mySubscriptions.length; i2++){
                    var oldSub = this.wiredData.data.myCurrentSubscriptions[i];
                    var newSub = this.mySubscriptions[i2];
                    if(oldSub.Id == newSub.Id){
                        if(oldSub.Active__c != newSub.Active__c){
                            if(newSub.Active__c == true){
                                subOptIn.push(newSub.Campaign.External_Label__c);
                            }
                            else{
                                subOptOut.push(newSub.Campaign.External_Label__c);
                            }
                            this.hasSubChanged = true;
                            this.allChangedSubscriptions.push(newSub);
                        }
                    }
                }
            }
        }

        // if has at least one opt out from either contact / subscription level, tick a flag
        this.contactHasOptOut = false;
        this.subHasOptOut = false;
        this.hasOptOutFlag = false;

        var hasOptOut = false;
        var hasContactOptOut = false;
        var hasSubOptOut = false;

        if(contactOptouts.length > 0){
            hasContactOptOut = true;
            hasOptOut = true;
            this.listContactOptOuts = contactOptouts;
        }
        if(subOptOut.length > 0){
            hasSubOptOut = true;
            hasOptOut = true;
            this.listSubOptOuts = subOptOut;
        }

        this.hasOptOutFlag = hasOptOut;
        this.contactHasOptOut = hasContactOptOut;
        this.subHasOptOut = hasSubOptOut;

        if(this.hasOptOutFlag){
            this.headerMessage = this.label.modalHeaderOptOut;
            this.optOutReason = this.options[0].value;
        }
        else{
            this.optOutReason = undefined;
            this.handleSave();
        }
    }

    /*
        close modal method
     */
    closeModal(){
        this.openModalBox = false;
    }

    /*
        capture and handle the changes in the subscriptions
     */
    handleSubscriptionChange(event){
        var thisKey = event.target.name;
        var thisValue = event.target.checked;

        this.handleCampaignMembershipChange(thisKey, thisValue);
    }

    /*
        capture and handle the channel changes
     */
    handleChannelChange(event){
        var thisField = event.target.dataset.identifier;
        var thisValue = !event.target.checked;
        this.handleContactChange(thisField, thisValue);
    }

    /*
        capture and handle the preferences changes
     */
    handlePreferenceChange(event){
        var thisField = event.target.dataset.identifier;
        var thisValue = event.target.checked;
        this.handleContactChange(thisField, thisValue);
    }

    /*
        apply the changes into the contact data
     */
    handleContactChange(field, value){
        this.myContact[field] = value;
    }

    /*
        apply the changes in the subscription list data
     */
    handleCampaignMembershipChange(recordId, value){
        for(var i=0; i<this.mySubscriptions.length;i++){
            if(this.mySubscriptions[i]){
                if(this.mySubscriptions[i].Id == recordId){
                    this.mySubscriptions[i].Active__c = value;
                }
            }
        }
    }

    /*
        capture and handle changes in the opt out reason selection
     */
    handleOptOutReason(event){
        this.optOutReason = event.target.value;
    }

    /*
        save method
        1) for any subscription/contact change, fire the apex service to commit the changes into the database
        2) fire the toast after the whole process finishes
        3) if no changes are made, fire the toast with different message
     */
    handleSave(){
        // front-end defaults
        this.isProcessComplete = false;
        this.hasOptOutFlag = false;
        this.headerMessage = this.label.modalHeaderSave;

        // update subscription
        if(this.hasSubChanged){
            // call save of subscriptions
            updateMySubscriptions({subs: this.allChangedSubscriptions, reason: this.optOutReason, source: this.centreName})
                .then(() => {

                    // if the changes are made in the subscription level only, fire the toast
                    if(!this.hasConChanged){
                        this.fireSuccessToast(this.label.successMessage);
                    }

                })
                .catch(error => {
                    console.error(error);
                    this.fireErrorToast();
        });
        }

        // update contact
        if(this.hasConChanged){

            updateMyContact({con: this.myContact, reason: this.optOutReason, source: this.centreName})
                .then(() => {
                    this.fireSuccessToast(this.label.successMessage);
                })
                .catch(error => {
                    this.fireErrorToast();
            });
        }

        // if no changes have been made from either contact or subscription level, fire the toast
        if(!this.hasSubChanged && !this.hasConChanged){
            this.fireSuccessToast(this.label.noChangeMessage);
        }
    }

    /*
        method to fire the toast
     */
    fireSuccessToast(message){
        // fire toast
        const showSuccess = new ShowToastEvent({
            title: 'Success!',
            message: message,
            variant: 'Success',
        });

        this.openModalBox = false;
        this.dispatchEvent(showSuccess);
        this.refreshData();
    }

    /*
        method to fire the error toast
     */

    fireErrorToast(){
        // fire toast
        const showError = new ShowToastEvent({
            title: 'Error',
            message: this.label.errorMessage,
            variant: 'error',
        });
        this.dispatchEvent(showError);
    }

    /*
        refresh data programmatically
     */
    refreshData() {
        return refreshApex(this.wiredData);
    }

    /* GETTER METHODS */
    get emailOptOut(){
        return !this.myContact.HasOptedOutOfEmail;
    }

    get smsOptOut(){
        return !this.myContact.SMS_Opt_Out__c;
    }

    get phoneOptOut(){
        return !this.myContact.DoNotCall;
    }

    get mailOptOut() {
        return !this.myContact.Direct_Mail_Opt_Out__c;
    }

    get commercialOptOut() {
        return !this.myContact.Commercial_Opt_Out__c;
    }
}