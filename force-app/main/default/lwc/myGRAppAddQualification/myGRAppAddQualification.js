import { LightningElement, api, wire } from 'lwc';
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
*  @description used to manage the contact qualifactions for graduate research applications 
**/
export default class MyGRAppAddQualification extends LightningElement {
    @api applicationId
    state = 'START'
    saveErrors
    qualificationTypeList
    countryOptions
    contactQualification
    qualTertiaryAwardingBody
    isCountrySelected
    objInstitute
    showSpinner
    contactQualifications
    _wiredQualificationResponse
    yesNoOptions = [{label:'Yes',value:'Yes'}, 
        {label:'No',value:'No'}]
    continueWithMonash
    instituteName
    recTypeDevName = 'Tertiary_Education'
    tabIdInstitute = "INSTITUTE_SEARCH"
    intendToCompleteWithSameInstitute
    qualificationCompleted
    transferToMonash
    transferToMonashResearch
    qualificationNotCompleted
    showConfirmDelete
    maxDate = new Date().toISOString().slice(0,10)
    completionWithdrawalDateLabel = 'Completion date'
    showErrors
    qualIdToDelete
    qualIdToEdit
    otherQualificationType
    intendToCompleteWithSameInstituteBoolean

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
            this.countryOptions = this.processPicklistOptions(data.COUNTRY_OPTIONS)
            this.qualificationTypeList = this.processPicklistOptions(data.QUAL_TYPE)
        }
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
		this.state = 'EDIT'
        this.instituteName = ''
        this.qualificationCompleted = ''
        this.intendToCompleteWithSameInstitute = ''
        this.transferToMonash = ''
        this.isCountrySelected = false
        this.showHideResearchTransfer()
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
        this.loadDraftQualificationIntoForm();
    }

    /**
     * loadDraftQualificationIntoForm method
     * @description populating the form values on edit qualifications
     * @returns N/A
     */
    loadDraftQualificationIntoForm() {
         var qualification = this.contactQualifications.find((element) => element.Id == this.qualIdToEdit)
         this.contactQualification = {...qualification}
        this.isCountrySelected = true
        this.transferToMonash = ''
        this.qualificationCompleted = ''
        this.intendToCompleteWithSameInstitute = ''
        if(this.contactQualification.Institution_Name__c != null) {
            this.instituteName = this.contactQualification.Institution_Name__c
            this.tabIdInstitute = 'INSTITUTE_SEARCH'
        } else if(this.contactQualification.Other_Institution__c != null) {
            this.instituteName = ''
            this.tabIdInstitute = 'INSTITUTE_MANUAL'
        }
        
        if(this.contactQualification.isTestCompleted__c) {
            this.qualificationCompleted = 'Yes'
            this.intendToCompleteWithSameInstitute = ''
            this.transferToMonash = ''
        } else {
            this.qualificationCompleted = 'No'
            if(this.contactQualification.Former_Supervisor_Details__c) {//if the supervisor details are enetered, means user wants to transfer it to monash
                this.intendToCompleteWithSameInstitute = 'No'
                this.transferToMonash = 'Yes'
            } else {//check if the Evidence_Type__c is PHD or Masters then check if the status is withdrawal
                if(this.contactQualification?.Evidence_Type__c == 'PHD' || this.contactQualification?.Evidence_Type__c == 'MASTER-RES') {
                    //if satisfies then they had selected not to transfer to Monash
                    this.intendToCompleteWithSameInstitute = 'No'
                    this.transferToMonash = 'No'
                } else {
                    // if the status is withdrawal then they had selected they don't want to complete with the same institute
                    if(this.contactQualification.Qualification_Status__c == 'WITHDREWCL') {
                        this.intendToCompleteWithSameInstitute = 'No'
                    } else {
                        this.intendToCompleteWithSameInstitute = 'Yes'
                    }
                }                
            }
        }

        this.showHideResearchTransfer()
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

    /**
     * onTabSelectInstitution method
     * @description toggle between the tabs of the institute selection
     * @returns N/A
     */
    onTabSelectInstitution(event) {
        if(!this.contactQualification.Id) {
            var searchInstitute = this.findElement('searchInstitute')
            if(searchInstitute)
                searchInstitute.clearValues()
        }        
    }

    /**
     * onFieldChange method
     * @description capturing all the field inputs
     * @returns N/A
     */
    onFieldChange(e) {
        const fieldName = e.target.name
        switch(fieldName) {
            case "startDate":
                this.contactQualification.Commencement_Date__c = e.target.value
                break
            case "endDate":
                this.contactQualification.Completion_Withdrawal_Date__c = e.target.value
                break
            case "country":
                this.contactQualification.Qualification_Country__c = e.target.value
                this.isCountrySelected = true;
                var searchInstitute = this.findElement('searchInstitute')
                this.findElement('searchInstitute').whereValue0 = e.target.value
                if(searchInstitute)
                    searchInstitute.clearValues();
                break
            case "otherInstitute":
                this.contactQualification.Other_Institution__c = e.target.value
                break    
            case "researchDescription":
                this.contactQualification.Description__c = e.target.value
                break     
            case "qualificationName":
                this.contactQualification.Other_Qualification__c = e.target.value
                break
            case "courseLength":
                this.contactQualification.Course_Length__c = e.target.value
                break    
            case "qualificationType":
                this.contactQualification.Evidence_Type__c = e.target.value
                if(this.contactQualification.Evidence_Type__c != 'OTHER') {
                    this.contactQualification.Other_Evidence_Type__c = ''
                }
                this.showHideResearchTransfer()
                break
            case "otherQualificationType":
                this.contactQualification.Other_Evidence_Type__c = e.target.value
                break  
            case "qualificationCompleted":
                this.qualificationCompleted = e.target.value 
                this.intendToCompleteWithSameInstitute = ''
                this.transferToMonash = ''
                this.showHideResearchTransfer()
                break
            case "intendToCompleteWithSameInstitute":
                this.transferToMonash = ''
                this.intendToCompleteWithSameInstitute = e.target.value
                this.showHideResearchTransfer()
                break  
            case "transferToMonash":
                this.transferToMonash = e.target.value  
                this.showHideResearchTransfer()               
                break  
            case "formerSupervisor":
                this.contactQualification.Former_Supervisor_Details__c = e.target.value
                break  
            case "formerThesisTopic":
                this.contactQualification.Former_Thesis_Topic__c = e.target.value
                break
            case "reasonForTransfer":
                this.contactQualification.Reasons_for_transfer__c = e.target.value
                break
            case "additionalDescription":
                this.contactQualification.Transfer_Description__c = e.target.value
                break                                 
            default:
                //nothing selected
        }
    }
    
    /**
     * processSaveFormValues method
     * @description assigning the contact qualification values based on certain selections
     * @returns N/A
     */
    processSaveFormValues() {

        if(this.contactQualification.Other_Institution__c) {
            this.contactQualification.Institution_Name__c = ''
            this.contactQualification.Institution_Code__c = ''
        }
        else if(this.objInstitute) {
            this.contactQualification.Institution_Name__c = this.objInstitute.Institution_Name__c
            this.contactQualification.Institution_Code__c = this.objInstitute.Institution_Code__c
            this.contactQualification.Other_Institution__c = ''
        }

        if(!this.continueWithMonash) {
            this.contactQualification.Former_Supervisor_Details__c = ''
            this.contactQualification.Former_Thesis_Topic__c = ''
            this.contactQualification.Reasons_for_transfer__c = ''
            this.contactQualification.Transfer_Description__c = ''
        } else {
            this.contactQualification.Completion_Withdrawal_Date__c = null
        }

        if(this.qualificationCompleted == 'Yes') {
            this.contactQualification.isTestCompleted__c = true
            this.contactQualification.Qualification_Status__c = 'COMPLETED'
            this.contactQualification.Status__c = 'SUCCESSFULLY COMPLETED AND OBTAINED'
        } else {
            this.contactQualification.isTestCompleted__c = false
            if(this.intendToCompleteWithSameInstitute == 'Yes') {
                this.contactQualification.Qualification_Status__c = 'CONTINUING'
                this.contactQualification.Status__c = 'CURRENTLY STUDYING'
            } else {
                this.contactQualification.Status__c = 'ATTEMPTED BUT WAS NOT COMPLETED'
                if(this.transferToMonash == 'Yes') {
                    this.contactQualification.Qualification_Status__c = 'WANTS2TFER'
                } else {
                    this.contactQualification.Qualification_Status__c = 'WITHDREWCL'
                }
            }
        }

        this.contactQualification.First_Year_Enrolled__c = this.contactQualification.Commencement_Date__c != null ? (new Date(this.contactQualification.Commencement_Date__c)).getFullYear().toString() : ''
        this.contactQualification.Last_Year_Enrolled__c = this.contactQualification.Completion_Withdrawal_Date__c != null ? (new Date(this.contactQualification.Completion_Withdrawal_Date__c)).getFullYear().toString() : ''
    }
    
    /**
     * showHideResearchTransfer method
     * @description showing / hiding the research transfer section based on the radio button selections
     * @returns N/A
     */
    showHideResearchTransfer() {
        this.completionWithdrawalDateLabel = 'Completion date'
        this.transferToMonashResearch = false
        this.continueWithMonash = false
        this.qualificationNotCompleted = false
        this.otherQualificationType = false
        if(this.contactQualification?.Evidence_Type__c == 'OTHER') {
            this.otherQualificationType = true
        } 

        if(this.qualificationCompleted == 'No') {
            this.qualificationNotCompleted = true
        }
        if((this.contactQualification?.Evidence_Type__c == 'PHD' || 
            this.contactQualification?.Evidence_Type__c == 'MASTER-RES') && 
            this.intendToCompleteWithSameInstitute == 'No' && 
            this.qualificationCompleted == 'No') {
                this.transferToMonashResearch = true
                if(this.transferToMonash == 'Yes') {
                    this.continueWithMonash = true
                    this.intendToCompleteWithSameInstituteBoolean = false
                } else {
                    this.intendToCompleteWithSameInstituteBoolean = true
                    this.completionWithdrawalDateLabel = 'Actual or Expected withdrawal date'
                }
        } else if(this.intendToCompleteWithSameInstitute == 'Yes') {
            this.intendToCompleteWithSameInstituteBoolean = false
            this.completionWithdrawalDateLabel = 'Expected completion date'
        } else if(this.intendToCompleteWithSameInstitute == 'No') {
            this.intendToCompleteWithSameInstituteBoolean = true
            this.completionWithdrawalDateLabel = 'Actual or Expected withdrawal date'
        }
    }

    //populating the institution name on the selection of lookup
    onSearchSelectInstitute(event) {
        var objSelected = event.detail.sObject;
        this.objInstitute = objSelected;
    }

    findElement(cmpId) {
        return this.template.querySelector(`[data-id="${cmpId}"]`);
    }

    /**
     * onClickCancel method
     * @description reset the form on click of cancel button
     * @returns N/A
     */
    onClickCancel() {
        this.contactQualification = {}
        this.showHideResearchTransfer()
        this.state = 'START'
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
     * showErrorsOnPage method
     * @description showing the errors on the UI if any
     * @returns N/A
     */
    showErrorsOnPage(errors) {
        this.saveErrors = errors
        this.showErrors = true
        this.showSpinner = false
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

    onClickCancelDelete() {
        // clear temp variable
        this.qualIdToDelete = null
        // close confirm box
        this.showConfirmDelete = false
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
        var lightningInputIdList = ["qualificationName", "courseLength", "startDate"]
        lightningInputIdList.forEach(lightningInputId =>{
            var componentField = this.template.querySelector('lightning-input[data-id="' +lightningInputId+ '"]')
            if(componentField != null && !componentField.checkValidity()){
                var errorMsg = componentField.label
                errorMsg += ' contains an invalid input'
                validationErrors.push(errorMsg)
            }
        })
        
        if(!this.contactQualification.Evidence_Type__c) {
            validationErrors.push('Please select the Qualification Type')
        } else {
            if(this.contactQualification.Evidence_Type__c == 'OTHER') {
                if(!this.contactQualification.Other_Evidence_Type__c) {
                    validationErrors.push('Please specify the Qualification Type')
                }
            }
        }
        
        if(!this.contactQualification.Qualification_Country__c) {
            validationErrors.push('Please select the Country')
        } else {
            if(!this.contactQualification.Other_Institution__c && !this.contactQualification.Institution_Name__c) {
                validationErrors.push('Please select the Institution Name or enter manually')
            } else {
                var searchInstitute = this.findElement('searchInstitute')
                if(searchInstitute && !searchInstitute.searchText && !this.contactQualification.Other_Institution__c) {
                    validationErrors.push('Please select the Institution Name or enter manually')
                }
            }
        }
        if(!this.contactQualification.Description__c) {
            validationErrors.push('Please enter the Research Component')
        }
        if(!this.qualificationCompleted) {
            validationErrors.push('Please select if you have completed this Qualification')
        }else if(this.qualificationCompleted == 'No') {
            if(this.qualificationNotCompleted && !this.intendToCompleteWithSameInstitute) {
                validationErrors.push('Please select if you intend to complete this qualification at the same institution')
            }
            else if(this.transferToMonashResearch && !this.transferToMonash) {
                validationErrors.push('Please select if wish to transfer this research project/topic to Monash')
            }
        }
        if(!this.continueWithMonash) {
            if(!this.contactQualification.Completion_Withdrawal_Date__c) {
                validationErrors.push(this.completionWithdrawalDateLabel+' contains an invalid input')
            } else if(this.contactQualification.Completion_Withdrawal_Date__c && this.contactQualification.Commencement_Date__c && this.contactQualification.Completion_Withdrawal_Date__c < this.contactQualification.Commencement_Date__c) {
                validationErrors.push(this.completionWithdrawalDateLabel+' must be after the Commencement Date')
            }
        } else {
            if(!this.contactQualification.Former_Supervisor_Details__c) {
                validationErrors.push('Please enter the Former Supervisor details')
            }
            if(!this.contactQualification.Reasons_for_transfer__c) {
                validationErrors.push('Please enter the Reasons for transfer')
            }
        }

        return validationErrors
    }

     //public method to be invoked from parent aura to ensure at least one contact qualification is selected before save and continue 
     @api validateDeclaration() {
        let validationErrors = []
        let isValid = true
        if (this.contactQualifications?.length < 1) {
            let validationMessage = 'An application requires at least one qualification to be recorded. You currently have no qualifications associated with this application. Please return to the Qualifications section and add at least one qualification to your application.'
            validationErrors.push(validationMessage)
            this.showErrorsOnPage(validationErrors)
            isValid = false
        }
        return isValid
    }

    onClickCloseErrors() {
        this.showErrors = false
    }
}