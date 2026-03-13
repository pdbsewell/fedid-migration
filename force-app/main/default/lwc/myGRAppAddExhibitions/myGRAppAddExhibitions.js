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
*  @date 27-08-2024
*  @group My App Application for graduate research
*  @description used to manage the exhibitions for graduate research applications 
**/
export default class MyGRAppAddExhibitions extends LightningElement {
    @api applicationId
    languageOptions
    exhibitionTypeOptions
    soloOrGroupOptions
    state = 'START'
    saveErrors
    contactQualification
    contactQualifications
    contactQualificationsUI
    _wiredQualificationResponse
    showSpinner
    showConfirmDelete
    showErrors
    qualIdToDelete
    qualIdToEdit
    recTypeDevName = 'Exhibitions'
    yesNoOptions = [{label:'Yes',value:'Yes'}, 
        {label:'No',value:'No'}]
    publicationInEnglish 
    @api declarationSigned
    
    label = {
        app_DeleteConfirmation
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
            this.languageOptions = this.processPicklistOptions(data.LANGUAGE)
            this.exhibitionTypeOptions = this.processPicklistOptions(data.EXHIBITION_TYPE)
            this.soloOrGroupOptions = this.processPicklistOptions(data.EXHIBITION_SOLO_GROUP)
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

    processYearPicklist(){
        var arrOptions = []
        var firstVal = (new Date()).getFullYear() + 1 //next consecutive year
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
        this.publicationInEnglish = null
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
            case "exhibitionType":
                this.contactQualification.Evidence_Type__c = e.target.value
                break
            case "publicationInEnglish":
                this.publicationInEnglish = e.target.value
                this.contactQualification.Is_in_English__c = this.publicationInEnglish == 'Yes' ? true : false
                break
            case "name":
                this.contactQualification.Other_Qualification__c = e.target.value
                break 
            case "venue":
                this.contactQualification.Location_Venue__c = e.target.value
                break
            case "soloOrGroup":
                this.contactQualification.Solo_or_Group_Exhibition__c = e.target.value
                break
            case "nonEnglishLanguages":
                this.contactQualification.Language__c = e.target.value
                break
            case "qualityOfWork":
                this.contactQualification.Quality_of_work__c = e.target.value
                break
            case "description":
                this.contactQualification.Description__c = e.target.value
                break                          
            default:
                //nothing selected
        }
    }

    get publicationNonEnglist() {
        if(this.contactQualification?.Is_in_English__c) {
            return this.publicationInEnglish == 'No' || !this.contactQualification.Is_in_English__c
        } else {
            return this.publicationInEnglish == 'No'
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
                var objResponse = response                
                refreshApex(this._wiredQualificationResponse)
                this.state = 'START'

            }).catch((error) => {
                this.showSpinner = false
            })
        }
    }
    
    /**
     * processSaveFormValues method
     * @description assigning the contact qualification values based on certain selections
     * @returns N/A
     */
    processSaveFormValues() {
        if(this.contactQualification.Is_in_English__c) {
            this.contactQualification.Language__c = null
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
    }

    /**
     * loadDraftQualificationIntoForm method
     * @description populating the form values on edit qualifications
     * @returns N/A
     */
    loadDraftQualificationIntoForm() {
        var qualification = this.contactQualifications.find((element) => element.Id == this.qualIdToEdit)
        this.contactQualification = {...qualification}
        this.publicationInEnglish = this.contactQualification.Is_in_English__c ? "Yes" : "No"
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
            var objResponse = response            
            refreshApex(this._wiredQualificationResponse)
        }).catch((error) => {
            this.showSpinner = false
        })
    }

    /**
     * getValidationErrors method
     * @description  use to check field validity before proceeding to save field
     * @returns array of failed validation messages
     */
    getValidationErrors(){
        var validationErrors = []
        var lightningSelect = ["exhibitionType","soloOrGroup","nonEnglishLanguages"]
        lightningSelect.forEach(lightningInputId =>{
            var componentField = this.template.querySelector('lightning-select[data-id="' +lightningInputId+ '"]')
            if(componentField != null && !componentField.checkValidity()){
                var errorMsg = 'Please select the '+ componentField.label
                validationErrors.push(errorMsg)
            }
        })

        var lightningInputIdList = ["name","venue"]
        lightningInputIdList.forEach(lightningInputId =>{
            var componentField = this.template.querySelector('lightning-input[data-id="' +lightningInputId+ '"]')
            if(componentField != null && !componentField.checkValidity()){
                var errorMsg = componentField.label
                errorMsg += ' contains an invalid input'
                validationErrors.push(errorMsg)
            }
        })

        var lightningTextAreaList = ["qualityOfWork","description"]
        lightningTextAreaList.forEach(lightningInputId =>{
            var componentField = this.template.querySelector('lightning-textarea[data-id="' +lightningInputId+ '"]')
            if(componentField != null && !componentField.checkValidity()){
                var errorMsg = componentField.label
                errorMsg += ' contains an invalid input'
                validationErrors.push(errorMsg)
            }
        })
        if(!this.publicationInEnglish) {
            validationErrors.push('Please select the language')
        }
        
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
            let validationMessage = 'Please enter at least one exhibition to proceed'
            validationErrors.push(validationMessage)
            this.showErrorsOnPage(validationErrors)
            isValid = false
        }
        return isValid
    }
}