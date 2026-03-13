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
*  @date 19-08-2024
*  @group My App Application for graduate research
*  @description used to manage the music section for graduate research applications 
**/
export default class MyGRAppAddMusic extends LightningElement {
    @api applicationId
    statusOptions
    performanceOrComposition
    state = 'START'
    saveErrors
    contactQualification
    contactQualifications = []
    _wiredQualificationResponse
    showSpinner
    showConfirmDelete
    maxDate = new Date().toISOString().slice(0,10)
    showErrors
    qualIdToDelete
    qualIdToEdit
    recTypeDevName = 'Music'
    numberOfPerformerOptions
    percentageOptions
    evidenceType
    numberOfAuthors
    durationPattern = "(?:([01]?[0-9]|2[0-3])(:[0-5]?[0-9])?(:[0-5]?[0-9])?)?$"
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
            this.statusOptions = this.processPicklistOptions(data.MUSIC_STATUS)
            this.performanceOrComposition = this.processPicklistOptions(data.PERFORMANCE_COMPOSITION)
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

    connectedCallback() {
        this.numberOfPerformerOptions = this.processNumberPicklist()
        this.percentageOptions = this.processNumberPicklist()
    }

    processNumberPicklist() {
        var arrOptions = []
        arrOptions.push({
            value:''
            , label:'-- Select --'
        });
        for(var count = 1; count <= 100; count++) {
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
            case "qualificationType":
                this.contactQualification.Evidence_Type__c = e.target.value
                this.evidenceType = e.target.value
                break
            case "duration":
                this.contactQualification.Duration__c = e.target.value
                break
            case "organisation":
                this.contactQualification.Name_of_Publisher_Journal_Org__c = e.target.value
                break
            case "name":
                this.contactQualification.Title_of_Publication_Work_Chapter_Paper__c = e.target.value
                break     
            case "status":
                this.contactQualification.Qualification_Status__c = e.target.value
                break     
            case "contributionPercentage":
                this.contactQualification.Contribution_Percentage__c = e.target.value
                break
            case "numberOfPerformers":
                if(e.target.value) {
                    this.contactQualification.Number_of_Author_Performer__c =  Number(e.target.value)
                    this.numberOfAuthors = Number(e.target.value)
                }
                else {
                    this.contactQualification.Number_of_Author_Performer__c =  ""
                    this.numberOfAuthors = ""
                }
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

    get isPerformance() {
        return this.evidenceType == 'MT-PERFORM' || this.contactQualification.Evidence_Type__c == 'MT-PERFORM'
    }

    get isComposition() {
        return this.evidenceType == 'MT-COMPOSE' || this.contactQualification.Evidence_Type__c == 'MT-COMPOSE'
    }

    get isMoreThanOneAuthor() {
        return this.numberOfAuthors > 1 || this.contactQualification.Number_of_Author_Performer__c > 1
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
     * processSaveFormValues method
     * @description assigning the contact qualification values based on certain selections
     * @returns N/A
     */
    processSaveFormValues() {
        if(this.contactQualification.Number_of_Author_Performer__c == 1) {
            this.contactQualification.Contribution_Percentage__c = ""
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

    /**
     * getValidationErrors method
     * @description  use to check field validity before proceeding to save field
     * @returns array of failed validation messages
     */
    getValidationErrors(){
        var validationErrors = []
        var lightningSelect = ["qualificationType","status","numberOfPerformers","contributionPercentage"]
        lightningSelect.forEach(lightningInputId =>{
            var componentField = this.template.querySelector('lightning-select[data-id="' +lightningInputId+ '"]')
            if(componentField != null && !componentField.checkValidity()){
                var errorMsg = 'Please select the '+ componentField.label
                validationErrors.push(errorMsg)
            }
        })

        var lightningInputIdList = ["duration", "organisation", "name"]
        lightningInputIdList.forEach(lightningInputId =>{
            var componentField = this.template.querySelector('lightning-input[data-id="' +lightningInputId+ '"]')
            if(componentField != null && !componentField.checkValidity()){
                var errorMsg = componentField.label
                errorMsg += ' contains an invalid input'
                validationErrors.push(errorMsg)
            }
        })

        var lightningTextAreaList = ["qualityOfWork", "description"]
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
            let validationMessage = 'Please enter at least one performance to proceed'
            validationErrors.push(validationMessage)
            this.showErrorsOnPage(validationErrors)
            isValid = false
        }
        return isValid
    }
}