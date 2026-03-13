import { LightningElement, api, wire } from 'lwc'
import getContactQualifications from "@salesforce/apex/MyGRAppAddQualificationController.getContactQualifications"

/**
*  @author Sethu Venna
*  @date 23-08-2024
*  @group My App Application GR
*  @description used to manage the item declaration if the applicant wants to add any items like publication, music, awards etc. 
**/
export default class MyGRAppDeclaration extends LightningElement {
    
    //global variables
    @api applicationId
    @api qualificationName
    @api recordTypeName
    declaredValue = 'false'
    recordCount
    showErrors
    error

    declarationOptions = [
        { label: 'Yes', value: 'true' },
        { label: 'No', value: 'false' },
    ]

    //local variables
    showError
    errorMessage

    //get an existing contact qualification if it already exists
    @wire(getContactQualifications, {
        applicationId:'$applicationId',
        recordTypeName:'$recordTypeName'
    })
    contactQualifications(result) {
        if (result.data) {
            let records = result.data
            this.recordCount = records?.length
            records.forEach(item => {
                this.declaredValue = 'true'
                this.dispatchChangeEvent()
            })
            
        } else if (result.error) {
            this.showError = true
            this.errorMessage = result.error.body.message
        }
    }

    //handler when declaration is changed on the UI
    handleDeclarationChange(event) {
        if(this.recordCount > 0 && event.target.value == 'false') {
            event.target.value = 'true';
            this.error = 'You currently have '+this.getPageName()+', please remove these before updating from Yes to No';
            this.showErrors = true
        } else {
            this.declaredValue = event.target.value
        }        
        this.dispatchChangeEvent()
    }

    //disptach declaration change event
    dispatchChangeEvent() {
        const declarationChangeEvent = new CustomEvent("declarationchange", {
            detail: { 
                value : this.declaredValue === 'true' ? true : false
            },
        })
        this.dispatchEvent(declarationChangeEvent)
    }

    onClickCloseErrors(){
        this.showErrors = false
    }

    getPageName() {
        var qualName
        switch(this.recordTypeName){
            case "Other_Qualification":
                qualName = 'additional supporting information'
                break;
            case "Employment_and_Research":
                qualName = 'employment or research experience'
                break;
            case "Awards_and_Scholarships":
                qualName = 'awards, prizes or scholarships'
                break;
            case "Creative_Works":
                qualName = 'creative works'
                break;
            case "Theatre_Performance":
                qualName = 'theatre performance'
                break;   
            default:
                qualName = this.recordTypeName.toLowerCase()
        }
        return qualName
    }
}