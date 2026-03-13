import { LightningElement, wire, api } from 'lwc';
import getPicklistValues from '@salesforce/apex/MyGRAppAddQualificationController.getPicklistValues';
import getSearchResults from "@salesforce/apex/MyAppWithoutSharingController.getSearchResults";
import updateRecord from "@salesforce/apex/MyAppWithoutSharingController.updateApplication";

/**
*  @author Vishal Gupta
*  @date 10-09-2024
*  @group My App Application for graduate research
*  @description used to manage the agent details for graduate research applications 
**/
export default class MyGRApplicationAgent extends LightningElement {
    @api applicationId
    countryOptions
    selectedCountry
    agentPicklistOptions
    showSpinner
    address
    agents
    isAgent
    application = {}
    agentName
    saveErrors =false
    showErrors
    items = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' },
    ];

    connectedCallback(){
        this.getCountryOptions()        
    }


    getCountryOptions() {        
        this.showSpinner = true
        getPicklistValues().then(data => {
            this.countryOptions = this.processPicklistOptions(data.COUNTRY_OPTIONS)
            this.getExistingAgentDetails()
            
        }).catch((error) => {
            this.showSpinner = false
        })
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

    //get All Qualification records by Admission Test record type to show Test Name options on the UI
    getAgentDetails() {
        this.showSpinner = true
        getSearchResults({
            fieldsToReturn: ['Id','Name', 'ShippingAddress'],
            objectAPIName: 'Account',
            whereFields: ['Country_Lookup__c', 'RecordType.Name', 'Status__c'],
            whereValues: [this.selectedCountry, 'Agency', 'Appointed'],
            optionalWhereFields: [],
            searchFields: ['Name'],   
            searchText: ''
        }).
        then(response => {
            this.showSpinner = false
            if (response) {
                this.agents = response
                let records = [];
                records.push({
                    value: '',
                    label: '--None--'
                });
                response.forEach((item) => {
                    records.push({
                        value: item.Id,
                        label: item.Name
                    });
                });
                if(records){
                    this.agentPicklistOptions = records;
                }
            }
        }).catch(errors => {
            if (errors) {
                this.showSpinner = false
            }
        });
    }

    //get All Qualification records by Admission Test record type to show Test Name options on the UI
    getExistingAgentDetails() {
        this.showSpinner = true
        getSearchResults({
            fieldsToReturn: ['Id','Agent__c', 'Agent_Org_Unit_Code__c', 'Agent_Staff_Email__c', 'Agent_Staff_Details__c','Agent_Country__c','Applicant_Agent__c'],
            objectAPIName: 'Application__c',
            whereFields: ['Id'],
            whereValues: [this.applicationId],
            optionalWhereFields: [],
            searchFields: [],   
            searchText: ''
        }).
        then(response => {
            this.showSpinner = false
            if (response) {
                this.application = response[0]
                if(this.application.Applicant_Agent__c == 'Yes') {
                    this.isAgent = 'Yes'
                    this.agentName = this.application.Agent__c
                    this.selectedCountry = this.application.Agent_Country__c
                    this.getAgentDetails()
                } else if(this.application.Applicant_Agent__c == 'No') {
                    this.isAgent = 'No'
                }
            }
        }).catch(errors => {
            if (errors) {
                this.showSpinner = false
            }
        });
    }

    /**
     * onFieldChange method
     * @description capturing all the field inputs
     * @returns N/A
     */
    onFieldChange(e) {
        const fieldName = e.target.name
        switch(fieldName) {
            case "agentName":
                this.agentName = e.target.value
                let agent = this.agents.find((element) => element.Id == e.target.value)
                if(agent && agent.ShippingAddress) {
                    let street = agent.ShippingAddress.street != undefined ? agent.ShippingAddress.street + ' ' : ''
                    let city = agent.ShippingAddress.city != undefined ? agent.ShippingAddress.city + ' ' : ''
                    let state = agent.ShippingAddress.state != undefined ? agent.ShippingAddress.state + ' ' : ''
                    let country = agent.ShippingAddress.country != undefined ? agent.ShippingAddress.country + ' ' : ''
                    let postalCode = agent.ShippingAddress.postalCode != undefined ? agent.ShippingAddress.postalCode : ''
                    this.address = street + city + state + country + postalCode
                }  
                this.clearAgentFields('agentName')              
                break
            case "country":
                this.selectedCountry = e.target.value
                this.getAgentDetails()
                this.address = ''
                this.clearAgentFields('country')              
                break
            case "isAgent":
                this.isAgent = e.target.value
                this.clearAgentFields(e.target.value)
                break
            case "agentContact":
                this.application.Agent_Staff_Details__c = e.target.value
                break     
            case "email":
                this.application.Agent_Staff_Email__c = e.target.value
                break                               
            default:
                //nothing selected
        }
    }

    clearAgentFields(selected){
        if(selected == 'No'){
            this.agentName  = ''
            this.selectedCountry = ''
            this.application.Agent_Staff_Details__c =  ''           
            this.application.Agent_Staff_Email__c = ''
            this.application.Agent_Org_Unit_Code__c = ''
        }
        if(selected=='agentName'){
            this.application.Agent_Staff_Details__c =  ''           
            this.application.Agent_Staff_Email__c = ''
            this.application.Agent_Org_Unit_Code__c = ''
        }
        if(selected=='country'){
             this.agentName  = ''
            this.application.Agent_Staff_Details__c =  ''           
            this.application.Agent_Staff_Email__c = ''
            this.application.Agent_Org_Unit_Code__c = ''
        }
    }

    @api
    handleUpdate() {
        this.showSpinner = true
        this.saveErrors = [];
        var customFieldErrorList = []
        
        //getting the validation errors
        var validationErrorList = this.getValidationErrors()
        if(validationErrorList.length > 0){
            customFieldErrorList = customFieldErrorList.concat(validationErrorList)
        }
        
        if(customFieldErrorList.length > 0){
            this.showErrorsOnPage(customFieldErrorList)
            return false
        }

        if(this.isAgent == 'No') {
            this.application.Agent__c = ''
            this.application.Agent_Staff_Email__c = ''
            this.application.Agent_Staff_Details__c = ''
            this.application.Applicant_Agent__c = 'No'
            this.application.Agent_Org_Unit_Code__c = ''
        } else {
            this.application.Agent__c = this.agentName
            this.application.Applicant_Agent__c = 'Yes'
        }
        this.application.Id = this.applicationId;

        updateRecord({objData : this.application})
            .then((data) => {
                // Record is updated successfully
                this.showSpinner = false
                let saveSuccess = true
                const saveEvent = new CustomEvent("savesuccess", {
                    detail: { saveSuccess },
                  });
                this.dispatchEvent(saveEvent);
            })

            .catch(error => {
                this.showSpinner = false
                return false
            });
    }
    
    onClickCloseErrors() {
        this.showErrors = false
    }

    get showAgentForm() {
        return this.isAgent == 'Yes'
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
     * getValidationErrors method
     * @description  use to check field validity before proceeding to save field
     * @returns array of failed validation messages
     */
    getValidationErrors(){
        var validationErrors = []
        if(!this.isAgent) {
            validationErrors.push('Please select if you are applying via the services of an education agent.')
        }else if(this.isAgent == 'Yes' && !this.selectedCountry){
            validationErrors.push('Please select the country')
        }else if(this.isAgent == 'Yes' && !this.agentName) {
            validationErrors.push('Please select the agent')
        }
        var lightningInputIdList = ["email"]
        lightningInputIdList.forEach(lightningInputId =>{
            var componentField = this.template.querySelector('lightning-input[data-id="' +lightningInputId+ '"]')
            if(componentField != null && !componentField.checkValidity()){
                var errorMsg = componentField.label
                errorMsg += ' contains an invalid input'
                validationErrors.push(errorMsg)
            }
        })
        return validationErrors
    }
}