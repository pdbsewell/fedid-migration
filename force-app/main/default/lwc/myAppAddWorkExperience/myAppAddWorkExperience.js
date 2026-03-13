import { LightningElement, api } from 'lwc';
import getInitLoad from '@salesforce/apex/appAddWorkExperienceCC.getInitLoad'; 
import retrieveWorkExpForEdit from '@salesforce/apex/appAddWorkExperienceCC.retrieveWorkExpForEdit';
import deleteWorkExp from '@salesforce/apex/appAddWorkExperienceCC.deleteWorkExp';
import saveWorkExperience from '@salesforce/apex/appAddWorkExperienceCC.saveWorkExperience';
// Import custom labels
import app_DeleteConfirmation from "@salesforce/label/c.App_DeleteConfirmation";
import app_ContactPersonDetailsLabel from "@salesforce/label/c.App_ContactPersonDetailsLabel";

/**
*  @author Vishal Gupta
*  @date 24-06-2024
*  @group My App Application
*  @description used to add the work experiences for student application 
**/
export default class MyAppAddWorkExperience extends LightningElement {
    @api applicationId
    user = {}
    state = 'START'
    workExperiences = []
    historicalWorkExperiences = []
    workExp = {}
    addRef = false
    countryOptions
    idToDelete
    showConfirmDelete = false
    showSpinner = false
    showErrors = false
    saveErrors = []
    employmentRegExp
    employmentPatterMsg
    refereeRegExp
    refereePatterMsg
    maxDate = new Date().toISOString().slice(0,10)

    // Expose the labels to use in the template.
    label = {
        app_DeleteConfirmation,
        app_ContactPersonDetailsLabel,
    }
    
    connectedCallback() {
        this.setFieldPatterns()
        this.doInit()
    }

    /**
     * Changes the display state of the component to enter details for a new Work Exp record
     * NB, the record is NOT created yet
     */
    doInit() {
        this.showSpinner = true
        getInitLoad({
            appId: this.applicationId
        }).then(response => {
            if (response) {
                var objResponse = response

                // user
                this.user = objResponse.user

                this.workExperiences = objResponse.workExperiences

                this.historicalWorkExperiences = objResponse.historicalWorkExperiences

                var countryOptions = objResponse.countryOptions
                countryOptions.unshift({"label":"choose one",
                "value":""})
                this.countryOptions = countryOptions

                this.showSpinner = false
            } 
        }).catch((error) => {
            this.showSpinner = false
        })
    }

    setFieldPatterns(){
        var employmentRegExp = "[^`=~$%^\\\;:\\/\\{\\}\\|:<>]*"
        this.employmentRegExp = employmentRegExp
        this.employmentPatterMsg = "The following special characters are not permitted: `=~$%^\\;:\/\{\}\|:<>" //does not allow `=~$%^\;:/{}|:<>

        var refereeRegExp = "[^0-9`=~$%^\\\;:\\/\\{\\}\\|:<>!@#&*\\(\\)_+\\[\\],.\"?]*"
        this.refereeRegExp = refereeRegExp 
        this.refereePatterMsg = "No numbers, symbols or special characters: `=~!@#$%^&*\(\)_+\[\]\\;,.\/\{\}\|:“<>?"//does not allow numbers nor \`=~!@#$%^&*()_+[]\\;,./{}|:“<>?
    }

    get isStateStart() {
        return this.state == 'START'
    }

    get isStateEdit() {
        return this.state == 'EDIT'
    }

    /**
     * Changes the display state of the component to enter details for a new Work Exp record
     * NB, the record is NOT created yet
     */
	onClickAddNew() {
		this.workExp = {}
		this.state = 'EDIT'
	}

    /**
     * Retrieves the target record for editing. Apex CC returns a JSON with the following field
     * workExperiences: a list with a single element, which is the target record for editing.
     *
     * then changes the display to editing mode (ie, new mode pre-populated)
     */
	onClickEdit(e) {
		this.showSpinner = true
        var workExpId = e.target.name // returns the id
        retrieveWorkExpForEdit({
            workExpId: workExpId
        }).then(response => {
            if (response) {
                var objResponse = response

                var listWorkExps = objResponse.workExperiences

                if(listWorkExps.length == 1)
				{
					var objWorkExp = listWorkExps[0]
                    this.workExp = objWorkExp

                    // show/hide the referee panel
					if(objWorkExp.Contact_Person_First_Name__c
						|| objWorkExp.Contact_Person_Last_Name__c
						|| objWorkExp.Contact_Person_Email__c
						|| objWorkExp.Contact_Person_Phone__c
					)
					{
						this.addRef = true
					}
                    this.state = 'EDIT'
				}

                this.showSpinner = false
            } 
        }).catch((error) => {
            this.showSpinner = false
        })
	}

    onFieldChange(e) {
        const fieldName = e.target.name
        switch(fieldName) {
            case "position":
                this.workExp.Position__c = e.target.value
                break
            case "employer":
                this.workExp.Employer_Name__c = e.target.value
                break
            case "startDate":
                this.workExp.Start_Date__c = e.target.value
                break
            case "endDate":
                this.workExp.End_Date__c = e.target.value
                break
            case "country":
                this.workExp.Country__c = e.target.value
                break
            case "givenName":
                this.workExp.Contact_Person_First_Name__c = e.target.value
                break
            case "familyName":
                this.workExp.Contact_Person_Last_Name__c = e.target.value
                break  
            case "email":
                this.workExp.Contact_Person_Email__c = e.target.value
                break  
            case "phone":
                this.workExp.Contact_Person_Phone__c = e.target.value
                break          
            default:
                //nothing selected
        }
    }

    /**
     * If referee details need to be added (not mandatory)
     */
	onClickAddReferee() {
		this.addRef = true
    }

    /**
     * On clicking delete, prompt the user with a confirmation dialogue. The Id of the delete target needs
     * to be stored in a temp attribute (v.idToDelete)
     */
	showConfirmDeletePopup(e) {
        var workExId = e.target.name // returns the id
		this.idToDelete = workExId
        this.showConfirmDelete = true
	}

    /**
     * On confirmation of delete, apex CC function deletes the record and returns JSON similar to the initial load
     * workExperiences: the list of current work experience records added to this application, ie editable
     * historicalWorkExperiences: the list of work experience records from previous applications
     */
	onClickConfirmDelete(){
        this.showSpinner = true
        deleteWorkExp({
            workExpId : this.idToDelete,
			appId : this.applicationId
        }).then(response => {
            if (response) {
                var objResponse = response
                this.workExperiences = objResponse.workExperiences
                this.historicalWorkExperiences = objResponse.historicalWorkExperiences
                this.clearWorkExpState()
                this.state = 'START'
                this.showSpinner = false
            } 
        }).catch((error) => {
            this.showSpinner = false
        })
	}

    /**
     * close the confirmation box
     */
	onClickCancelDelete() {
		this.clearWorkExpState()
		this.showConfirmDelete = false
	}

    /**
     * Attempt to save the work experience record, if there are errors, it is not saved, and an error popup is displayed.
     * If successful, refreshes the display in a similar way to the initial load
     * 
     * @revision
     *           12.04.2024 - Arnie Ug - Adding Validation Rules/RegEx to a Position, Employer, Given and Family Names fields
     */
	onClickSave() {
        this.showSpinner = true
        var objWorkExp = this.workExp
        
        //Validate that start date should be earlier than the end date
        var customFieldErrorList = []

        var endDateField = this.template.querySelector('lightning-input[data-id=endDate]')
        if(objWorkExp.Start_Date__c > objWorkExp.End_Date__c){
            var endDateMsg = "Start Date should not be later than the End Date."
            endDateField.setCustomValidity(endDateMsg)
            endDateField.reportValidity()

            customFieldErrorList.push(endDateMsg)
        }

        var fieldsForValidationList = ["startDate", "endDate", "position", "employer", "givenName", "familyName"]
        var validationErrorList = this.getValidationErrors(fieldsForValidationList)
        if(validationErrorList.length > 0){
            customFieldErrorList = customFieldErrorList.concat(validationErrorList)
        }
        
        if(customFieldErrorList.length > 0){
            this.showErrorsOnPage(customFieldErrorList)
            return
        }

        if (this.isUnsafe(objWorkExp)) {
            var appErrors = ["One or more input boxes are not in the expected format."]
            this.showErrorsOnPage(appErrors)
            return
        } 

        saveWorkExperience({
            workExp : objWorkExp,
			appId : this.applicationId
        }).then(response => {
            if (response) {
                var objResponse = response
                var saveStatus = objResponse.saveStatus
                if(saveStatus == 'success')	{
					// save completed, back to start
                    this.workExperiences = objResponse.workExperiences
                    this.historicalWorkExperiences = objResponse.historicalWorkExperiences
                    this.clearWorkExpState()
                    this.state = 'START'
				}
				else {
					// show errors
					var arrErrors = objResponse.errors
                    if(typeof objResponse.errors == 'undefined'){
                        arrErrors = objResponse.message
                    }
                    this.showErrorsOnPage(arrErrors)
				}
                this.showSpinner = false
            } 
        }).catch((error) => {
            this.showSpinner = false
        })
    }

    showErrorsOnPage(errors) {
        this.saveErrors = errors
        this.showErrors = true
        this.showSpinner = false
    }

    /**
     * getValidationErrors method
     * @author       Arnie Ug
     * @date         12.04.2024        
     * @description  use to check field validity before proceeding to save field
     * @param String[] lightningInputIdList
     * @returns array of failed validation messages
     */
    getValidationErrors(lightningInputIdList){
        var validationErrors = []

        lightningInputIdList.forEach(lightningInputId =>{
            var componentField = this.template.querySelector('lightning-input[data-id="' +lightningInputId+ '"]')
            if(componentField != null && !componentField.checkValidity()){
                var errorMsg = componentField.label.includes('End Date') ? 'End Date' :  componentField.label
                errorMsg += ' contains an invalid input'
                validationErrors.push(errorMsg)
            }
        })

        return validationErrors
    }

    /**
     * Close the error popup
     */
    onClickCloseErrors() {
		this.showErrors = false
	}


    /**
     * cancel editing/creating of the current Work Experience record
     */
    onClickCancel() {
    	// clear all
		this.clearWorkExpState()
        this.state = 'START'
    }

    clearWorkExpState() {
        this.workExp = {}
        this.showErrors = false
        this.showConfirmDelete = false
        this.idToDelete = null
        this.addRef = false
	}
    
    isUnsafe(dataObject) {
        const XML_REGEX_PATTERN = /(<.[^(><.)]+>)/g
         return XML_REGEX_PATTERN.test(JSON.stringify(dataObject))
    }
}