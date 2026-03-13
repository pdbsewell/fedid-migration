import * as util from 'c/util';
import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import OFFER_OBJ from '@salesforce/schema/SBQQ__Quote__c';
import RELATIONSHIP_TYPE from '@salesforce/schema/SBQQ__Quote__c.Guardian_Relationship_Type__c';
import GUARDIAN_HAS_EMAIL_FIELD from '@salesforce/schema/SBQQ__Quote__c.Guardian_has_Email_Address__c';
import static_resource from '@salesforce/resourceUrl/admission_assets'
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';

export default class offerUnder18Form extends LightningElement {
    @api quoteClauses;
    @api offerRecord;
    @api contactId;
    @api content;
    @track guardianInfo = {};
    @track spinner = false;
    @track hasError = false;
    @track disabledAttr;
    @track contactObj;
    @track guardianHasEmail;

    @wire(CurrentPageReference) pageRef;
    
    isGuardianHavingEmail = null;
    isGuardianNotHavingEmail = null;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: GUARDIAN_HAS_EMAIL_FIELD })
    isGuardianHavingEmailRadioGroupOptions;

    connectedCallback() {
        this.guardianInfo.Guardian_Relationship_Type__c = this.offerRecord.Guardian_Relationship_Type__c.value;
        this.disabledAttr = (this.guardianInfo.Guardian_Relationship_Type__c === 'Other' && !this.isDisabled ? false : true);
        //this.guardianHasEmail = (this.isDisabled || this.offerRecord.Guardian_Email__c.value != null ? true : false);
        this.guardianInfo.Guardian_First_Name__c = this.offerRecord.Guardian_First_Name__c.value;
        this.guardianInfo.Guardian_Last_Name__c = this.offerRecord.Guardian_Last_Name__c.value;
        this.guardianInfo.Guardian_Email__c = this.offerRecord.Guardian_Email__c.value;
        this.guardianInfo.Guardian_Other_Relationship_Type__c = this.offerRecord.Guardian_Other_Relationship_Type__c.value;
        //this.guardianInfo.Guardian_Email_Provided__c = this.offerRecord.Guardian_Email_Provided__c.value;
        this.guardianInfo.Guardian_has_Email_Address__c =  this.offerRecord.Guardian_has_Email_Address__c.value;
        if (this.offerRecord.Guardian_has_Email_Address__c.value === 'Yes') {
            this.isGuardianHavingEmail = true;
            this.isGuardianNotHavingEmail = false;
        } else if (this.offerRecord.Guardian_has_Email_Address__c.value === 'No') {
            this.isGuardianHavingEmail = false;
            this.isGuardianNotHavingEmail = true;
        }
        // subscribe to pageNavigate event from navigationComponent
        registerListener('SaveUnder18', this.handleSave, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    get updatedContent(){
        if(this.offerRecord && this.content){
            this.content = this.content.replace('#OFFER_RESPONSE_DATE#', this.offerRecord.Offer_Response_Date__c.value);
            this.content = this.content.replace('#WARNING#', static_resource + '/screen-icons/warning-medium.png');
            this.content = this.content.replace('#DOCUMENT_ICON#', static_resource + '/screen-icons/document-icon.png');
        }
        return this.content;
    }

    /***** GET RELATIONSHIP TYPE PICKLIST OPTION VALUES  *****/
    @wire(getObjectInfo, { objectApiName: OFFER_OBJ })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: RELATIONSHIP_TYPE})
    TypePicklistValues;

    @wire(getRecord, { recordId: '$contactId', fields:  'Contact.Email'})
    wiredContact({error, data}){
        if(data){
            this.contactObj = data.fields;
        }else if(error){
            console.log(error);
        }
    }

    handleGuardianHasEmailChange(event) {
        // Need two different variable for having/not having emails
        // due to how template renders and its truthy condition
        let selectedValue = event.detail.value;
        if (selectedValue === 'Yes') {
            this.isGuardianHavingEmail = true;
            this.isGuardianNotHavingEmail = false;
        } else if (selectedValue === 'No') {
            this.isGuardianHavingEmail = false;
            this.isGuardianNotHavingEmail = true;
            // Also clear out any details if there were any if the user 
            // changes their mind
            this.resetGuardianValues()
        }
        this.guardianInfo.Guardian_has_Email_Address__c = selectedValue;
    }

    /*** HANDLE ACTION WHEN INPUT TEXT VALUE WAS CHANGED ****/
    handleTextChange(event){
        this.guardianInfo[event.target.name] = event.target.value;
        
        // if(event.target.name === 'Guardian_Email__c' && event.target.value !== ''){
        //     this.guardianHasEmail = true;
        //     this.guardianInfo.Guardian_Email_Provided__c = false;
        // }
        // else{ //if(event.target.name === 'Guardian_Email__c' && event.target.value === ''){
        //     this.guardianHasEmail = false;
        // }
    }

    /*** HANDLE ACTION WHEN INPUT CHECKBOX VALUE WAS CHANGED ****/
    // handleCheckboxChange(event){
    //     this.guardianInfo[event.target.name] = event.target.checked;
    // }

    /*** HANDLE ACTION WHEN SELECT OPTION VALUE WAS CHANGED ****/
    handlePicklistChange(event) {
        this.guardianInfo.Guardian_Relationship_Type__c = event.detail.value;
        if(event.detail.value === 'Other'){
            this.disabledAttr = false;
        }else{
            this.disabledAttr = true;
            this.guardianInfo.Guardian_Other_Relationship_Type__c = '';
        }
    }

    get isDisabled(){
        return util.isOfferReadOnly(this.offerRecord) || util.disableButton(this.offerRecord);
    }

    trimInputs(){
        if (this.guardianInfo.Guardian_First_Name__c) this.guardianInfo.Guardian_First_Name__c = this.guardianInfo.Guardian_First_Name__c.trim();
        if (this.guardianInfo.Guardian_Last_Name__c) this.guardianInfo.Guardian_Last_Name__c = this.guardianInfo.Guardian_Last_Name__c.trim();
        if (this.guardianInfo.Guardian_Email__c) this.guardianInfo.Guardian_Email__c = this.guardianInfo.Guardian_Email__c.trim();
        if (this.guardianInfo.Guardian_Other_Relationship_Type__c) this.guardianInfo.Guardian_Other_Relationship_Type__c = this.guardianInfo.Guardian_Other_Relationship_Type__c.trim();
    }
    /*** VALIDATE FORM INPUTS ****/
    get validateInputs(){
        
        this.trimInputs();

        // Make sure user has explicitly selected whether their guardian has email address
        if (this.isGuardianHavingEmail === null || this.isGuardianNotHavingEmail == null) {
            this.errorHandling('Error', 'Please select if your guardian has an email address.', 'error');
            return false;
        }

        // Let the user proceed if their guardian has no email address
        // The validations for the other fields are not required in this scenario
        if (this.isGuardianNotHavingEmail == true) {
            return true;
        }

        if(!this.guardianInfo.Guardian_First_Name__c || !this.guardianInfo.Guardian_Last_Name__c || !this.guardianInfo.Guardian_Relationship_Type__c){
            this.errorHandling('Error', 'Please fill out all fields.', 'error');
            return false;

        }else if((this.guardianInfo.Guardian_Email__c === '' || this.guardianInfo.Guardian_Email__c === null) ){
                    // && !this.guardianInfo.Guardian_Email_Provided__c){
            this.errorHandling('Error', 'Please enter your email address', 'error');
            return false;

        }else if(!this.validateEmail(this.guardianInfo.Guardian_Email__c)){ // && !this.guardianInfo.Guardian_Email_Provided__c
            this.errorHandling('Error', 'You have entered an invalid email format', 'error');
            return false;

        }else if(this.contactObj.Email.value === this.guardianInfo.Guardian_Email__c){
            this.errorHandling('Error', 'Your guardian\'s email address cannot be the same as your email address', 'error');
            return false;

        }else if(this.guardianInfo.Guardian_Relationship_Type__c === 'Other' 
                && (this.guardianInfo.Guardian_Other_Relationship_Type__c == ''
                    || this.guardianInfo.Guardian_Other_Relationship_Type__c == null)){
            this.errorHandling('Error', 'Please indicate relationship to guardian', 'error');
            return false;

        }
        return true;
    }

    validateEmail(email) {
        var re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        return re.test(String(email).toLowerCase());
    }

    /*** VALIDATE IF FORM WAS UPDATED OR NOT ****/
    get infoHasChanged(){
        if(this.guardianInfo.Guardian_First_Name__c === this.offerRecord.Guardian_First_Name__c.value
            && this.guardianInfo.Guardian_Last_Name__c === this.offerRecord.Guardian_Last_Name__c.value
            && this.guardianInfo.Guardian_Email__c === this.offerRecord.Guardian_Email__c.value
            && this.guardianInfo.Guardian_Relationship_Type__c === this.offerRecord.Guardian_Relationship_Type__c.value
            && this.guardianInfo.Guardian_Other_Relationship_Type__c === this.offerRecord.Guardian_Other_Relationship_Type__c.value
            // && this.guardianInfo.Guardian_Email_Provided__c === this.offerRecord.Guardian_Email_Provided__c.value
            // && this.initialGuardianEmailChoice === this.offerRecord.Guardian_has_Email_Address__c.value
            && this.guardianInfo.Guardian_has_Email_Address__c === this.offerRecord.Guardian_has_Email_Address__c.value
            ){ 
                return false;
        }
        return true;
    }

    /*** FIRE THIS EVENT WHEN NAVIGATION WAS CLICKED AND UPDATED OFFER RECORD ****/
    handleSave(data){
        let isValid = this.validateInputs;
        let hasUpdate = this.infoHasChanged;        
        let subStatus = util.subStatusTriggerConga;
        if(isValid){

            if(!hasUpdate){
                util.log('*** GO TO NEXT PAGE ***');
                fireEvent(this.pageRef, 'ContinueFromUnder18', data); 
            } else{
                this.spinner = true;
                let offerFieldUpdate = {
                    fields:{
                        Id: this.offerRecord.Id.value,
                        Guardian_First_Name__c: this.guardianInfo.Guardian_First_Name__c,
                        Guardian_Last_Name__c: this.guardianInfo.Guardian_Last_Name__c,
                        Guardian_Email__c: this.guardianInfo.Guardian_Email__c,
                        Guardian_Relationship_Type__c: this.guardianInfo.Guardian_Relationship_Type__c,
                        Guardian_Other_Relationship_Type__c: this.guardianInfo.Guardian_Other_Relationship_Type__c,
                        // Guardian_Email_Provided__c: this.guardianInfo.Guardian_Email_Provided__c,
                        Sub_Status__c: subStatus,
                        Guardian_has_Email_Address__c: this.guardianInfo.Guardian_has_Email_Address__c
                    }
                };
                util.log(offerFieldUpdate);
                updateRecord(offerFieldUpdate)
                    .then(() => {
                        this.spinner = false;
                        util.log('*** Success Under 18 update ***');       
                        fireEvent(this.pageRef, 'ContinueFromUnder18', data);          
                    })
                    .catch(error => {
                        var exception = JSON.parse(JSON.stringify(error));  
                        util.log('*** Error ***' );
                        util.logJson(exception);
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: exception.body.message, 
                                variant: 'error',
                            }),
                        );  
                            
                    });
            }

        }
    }

    errorHandling(title, message, type){
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message, 
                variant: type
            }),
        ); 
    }

    resetGuardianValues() {
        this.guardianInfo.Guardian_Relationship_Type__c = '';
        this.guardianInfo.Guardian_First_Name__c = '';
        this.guardianInfo.Guardian_Last_Name__c = '';
        this.guardianInfo.Guardian_Email__c = '';
        this.guardianInfo.Guardian_Other_Relationship_Type__c = '';
    }
}