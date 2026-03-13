import { LightningElement, wire, api } from 'lwc';
import getPicklistValues from '@salesforce/apex/MyGRAppAddQualificationController.getPicklistValues';
import upsertQualificationToContact from "@salesforce/apex/MyGRAppAddQualificationController.upsertQualificationToContact";
import getContactQualifications from '@salesforce/apex/MyGRAppAddQualificationController.getContactQualifications';
import deleteContactQualification from '@salesforce/apex/MyGRAppAddQualificationController.deleteContactQualification';
import { refreshApex } from '@salesforce/apex';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import CONTACT_ID from '@salesforce/schema/User.ContactId';
import USER_ID from '@salesforce/user/Id';
import app_DeleteConfirmation from '@salesforce/label/c.App_DeleteConfirmation';

/**
*  @author Vishal Gupta
*  @date 25-07-2024
*  @group My App Application for graduate research
*  @description used to manage the awards for graduate research applications 
**/
export default class MyGRAppAddAwardsAndScholarships extends LightningElement {
    @api applicationId
    awardTypeList
    yearAwardedOptions
    yearAwarded
    state = 'START'
    saveErrors
    contactQualification
    contactQualifications
    _wiredQualificationResponse
    showSpinner
    showConfirmDelete
    maxDate = new Date().toISOString().slice(0,10)
    showErrors
    qualIdToDelete
    qualIdToEdit
    otherAwardType
    recTypeDevName = 'Awards_and_Scholarships'
    @api declarationSigned
    
    label = {
        app_DeleteConfirmation
    }

    //getting the user record to get the contact id
    @wire(getRecord, { recordId: USER_ID, fields: [CONTACT_ID] })
    user;
    get contactId() {
        return getFieldValue(this.user.data, CONTACT_ID);
    }
        
    //get the picklist values for the form {coutries, qualification types}
    @wire(getPicklistValues)
    pickListValues({data,error}){
        if(data){
            this.awardTypeList = this.processPicklistOptions(data.AWARD_NAME)
        }
    }

    processPicklistOptions(response){
        //store the return response from server (List<Map<String, String>>)
        var arrResponse = response;
        // add a default blank
        var arrOptions = [];
        arrOptions.push({
            value:''
            , label:'-- Select --'
        });
        arrOptions.push(...arrResponse)

        return arrOptions;
    }

    connectedCallback() {
        this.yearAwardedOptions = this.processYearPicklist()
    }

    processYearPicklist(){
        var arrOptions = []
        var firstVal = (new Date()).getFullYear()
        var lastVal = firstVal - 100 // last 100 year
        arrOptions.push({
            value:''
            , label:'-- Select --'
        });
        for(var count = firstVal; count >= lastVal; count--) {
            arrOptions.push({
                value:count
                , label:count
            })
        }
        return arrOptions
    }

    //get the existing Graduate Research contact qualifications by application id
    @wire(getContactQualifications, {applicationId:'$applicationId',
            recordTypeName:'$recTypeDevName'})
    getQualifications(result){
        this._wiredQualificationResponse = result
        if(result){
            this.contactQualifications = result.data
            this.showSpinner = false
        }
    }

    get isStateStart() {
        return this.state == 'START'
    }

    get isStateEdit() {
        return this.state == 'EDIT'
    }

    //Add new button will be hidden if the qualifications length is 5
    get isNewDisabled() {
        return this.contactQualifications?.length >= 5
    }

    /**
     * Changes the display state of the component to enter details for a new contact qualifications
     * NB, the record is NOT created yet
     */
	onClickAddNew() {        
		this.contactQualification = {}
        this.yearAwarded = null
		this.state = 'EDIT'
	}

    /**
     * onFieldChange method
     * @description capturing all the field inputs
     * @returns N/A
     */
    onFieldChange(e) {
        const fieldName = e.target.name
        switch(fieldName) {
            case "awardType":
                this.contactQualification.Evidence_Type__c = e.target.value
                this.hideShowOtherAward()
                break
            case "otherAwardType":
                this.contactQualification.Other_Qualification__c = e.target.value
                break
            case "instituteName":
                this.contactQualification.Other_Institution__c = e.target.value
                break    
            case "dateAchieved":
                this.contactQualification.Date_Achieved__c = e.target.value ? new Date("Jan 1 "+e.target.value + ' UTC') : null
                break     
            case "natureOfAward":
                this.contactQualification.Description__c = e.target.value
                break
            case "standingOfAward":
                this.contactQualification.Standing_of_Award__c = e.target.value
                break                                   
            default:
                //nothing selected
        }
    }

    /**
     * saveCurrentQualification method
     * @description action capture on save button
     * @returns N/A
     */
    saveCurrentQualification() {
        // clear previous save errors
        this.saveErrors = [];
        var customFieldErrorList = []
        this.processSaveFormValues()
        
        //getting the validation errors
        var validationErrorList = this.getValidationErrors()
        if(validationErrorList.length > 0){
            customFieldErrorList = customFieldErrorList.concat(validationErrorList)
        }
        
        if(customFieldErrorList.length > 0){
            this.showErrorsOnPage(customFieldErrorList)
            return
        }
        
        // check for errors
        var arrErrors = this.saveErrors;
        if(arrErrors.length > 0)
        {
            
            this.showErrors = true;
        }
        else {
            this.showSpinner = true;
            //if no errors then insert/update the qualifications
            upsertQualificationToContact({
                'contactId': this.contactId,
                'applicationId':this.applicationId,
                'contactQualification':this.contactQualification,
                'recordTypeName':this.recTypeDevName
            }).then(response => {
                var objResponse = response;
                refreshApex(this._wiredQualificationResponse)
                this.state = 'START'

            }).catch((error) => {
                this.showSpinner = false
            })
        }
    }

    /**
     * edit the existing contact qualification record
     */
    onClickEdit(event) {
        this.contactQualification = {}
        // get the qualification record Id
        this.qualIdToEdit = event.currentTarget.name;

        // show the form
        this.state = 'EDIT'

        // populate the form
        this.loadDraftQualificationIntoForm()
        this.hideShowOtherAward()
    }

    /**
     * loadDraftQualificationIntoForm method
     * @description populating the form values on edit qualifications
     * @returns N/A
     */
    loadDraftQualificationIntoForm() {
        var qualification = this.contactQualifications.find((element) => element.Id == this.qualIdToEdit)
        this.contactQualification = {...qualification}
        this.yearAwarded = (new Date(this.contactQualification.Date_Achieved__c)).getFullYear()
   }

    processSaveFormValues(){
        var evidenceTypeVal = this.awardTypeList.find(item => item.value === this.contactQualification.Evidence_Type__c).label
        this.contactQualification.Other_Qualification__c = evidenceTypeVal.includes('Other') ? this.contactQualification.Other_Qualification__c : evidenceTypeVal                                                                                      
    }
    
    onClickCancelDelete() {
        // clear temp variable
        this.qualIdToDelete = null
        // close confirm box
        this.showConfirmDelete = false
    }

    onClickDelete(event) {
        this.qualIdToDelete = event.currentTarget.name
        this.showConfirmDelete = true
    }

    onClickConfirmDelete() {
        this.showConfirmDelete = false        
        this.showSpinner = true
        // DELETE and wait for setstate to clear
        this.deleteQualification()
    }

    /**
     * deleteQualification method
     * @description  deleting the qualication based on the selection of qualificatio
     * @returns N/A
     */
    deleteQualification() {        
        this.showSpinner = true
        deleteContactQualification({            
            'contactQualificationId':this.qualIdToDelete,
            'applicationId':this.applicationId
        }).then(response => {
            var objResponse = response;
            refreshApex(this._wiredQualificationResponse)
        }).catch((error) => {
            this.showSpinner = false
        })
    }

    hideShowOtherAward() {
        this.otherAwardType = false
        if(this.contactQualification.Evidence_Type__c == 'OTHER') {
            this.otherAwardType = true
        }
    }

    /**
     * getValidationErrors method
     * @description  use to check field validity before proceeding to save field
     * @returns array of failed validation messages
     */
    getValidationErrors(){
        var validationErrors = []
        var lightningSelect = ["awardType","dateAchieved"]
        lightningSelect.forEach(lightningInputId =>{
            var componentField = this.template.querySelector('lightning-select[data-id="' +lightningInputId+ '"]')
            if(componentField != null && !componentField.checkValidity()){
                var errorMsg = 'Please select the '+ componentField.label
                validationErrors.push(errorMsg)
            }
        })

        var lightningInputIdList = ["otherAwardType", "instituteName"]
        lightningInputIdList.forEach(lightningInputId =>{
            var componentField = this.template.querySelector('lightning-input[data-id="' +lightningInputId+ '"]')
            if(componentField != null && !componentField.checkValidity()){
                var errorMsg = componentField.label
                errorMsg += ' contains an invalid input'
                validationErrors.push(errorMsg)
            }
        })

        var lightningTextAreaList = ["natureOfAward", "standingOfAward"]
        lightningTextAreaList.forEach(lightningInputId =>{
            var componentField = this.template.querySelector('lightning-textarea[data-id="' +lightningInputId+ '"]')
            if(componentField != null && !componentField.checkValidity()){
                var errorMsg = componentField.label
                errorMsg += ' contains an invalid input'
                validationErrors.push(errorMsg)
            }
        })
        
        
        return validationErrors
    }

    onClickCloseErrors() {
        this.showErrors = false
    }

    /**
     * showErrorsOnPage method
     * @description showing the errors on the UI if any
     * @returns N/A
     */
    showErrorsOnPage(errors) {
        this.saveErrors = errors
        this.showErrors = true
        this.showSpinner = false
    }

    /**
     * onClickCancel method
     * @description reset the form on click of cancel button
     * @returns N/A
     */
    onClickCancel() {
        // TODO - clear all attributes
        this.contactQualification = {}
        this.state = 'START'
    }

    //handler for change declaration Event in child myGRAppDeclaration component
    handleDeclarationChange(event) {
        this.declarationSigned = event.detail.value
    }

    //public method to be invoked from parent aura to ensure at least one contact qualification is selected before save and continue 
    @api validateDeclaration() {
        let validationErrors = []
        let isValid = true
        if (this.declarationSigned === true && !this.contactQualifications?.length) {
            let validationMessage = 'Please enter at least one award, prize or scholarship to proceed'
            validationErrors.push(validationMessage)
            this.showErrorsOnPage(validationErrors)
            isValid = false
        }
        return isValid
    }
}