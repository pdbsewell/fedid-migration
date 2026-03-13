import { LightningElement, api, track, wire} from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import retrieveApplicationCoursePreference from "@salesforce/apex/ResearchProgramCC.retrieveApplicationCoursePreference";
import saveResearchProgram from "@salesforce/apex/ResearchProgramCC.updateApplicationCoursePreference";
import EXTERNAL_FUNDING_TYPE_FIELD from "@salesforce/schema/Application_Course_Preference__c.External_Funding_Type__c";
import EMPLOYMENT_LOAD_FIELD from "@salesforce/schema/Application_Course_Preference__c.Employment_Load__c";
import EMPLOYMENT_DAYS_FIELD from "@salesforce/schema/Application_Course_Preference__c.Employment_Days__c";

const EMPLOYMENT_LOAD_FULL_TIME = 'Full-Time';

export default class MyGRResearchProgram extends LightningElement {

    @api applicationId;
    @api appId = "";
    @api applicationCoursePreference = null;
    @track supervisorName = '';
    @track researchTitle = '';
    @track researchSummary = '';
    @track items = [
        { label: 'Yes', value: 'true' },
        { label: 'No', value: 'false' },
    ];
    @track externalCandidature = false;
    @track externalSupervisorCheck = '';
    @track researchProgramFunding;
    @track sponsorAwardName = '';
    @track monetaryAmount = '';
    @track researchProgramFundingSelected = '';
    @track researchProgramFundingSelectedCheck = '';
    @track workingCourseSelected = false;
    @track researchProgramFundingFuture = false;
    @track researchProgramFundingFutureCheck = '';
    @track courseResearchAttendance = false;
    @track courseResearchAttendanceCheck = '';
    @track sponsorAwardNameFuture = '';
    @api acpRecordTypeId = '012000000000000AAA'; //alternate record type id if no record type is defined on object
    @track externalFundingOptions = [];
    @track selectedExternalFundingValue = '';
    @track researchDays = '';
    @track externalLoadOptions = [];
    @track selectedExternalLoadValue = '';
    @track externalDaysOptions = [];
    @track selectedExternalDaysValue = '';
    @track partTimeSelected = false;
    showSpinner = false;
    @track employerPosition = '';
    @track hoursPerWeek = '';
    @track employmentDays = [];
    _selected = [];
    @track selectItems = [];
    showErrors;
    saveErrors = [];
    surrenderScholarshipOptions = [];
    surrenderScholarship = '';
    scholarshipApp = false;
    admissionApp = false;
    showNoteSponsorship = false;
    applicationType = '';
    attendanceType = '';
    showExternalCanNotes = false;


    get selected(){
        return this._selected.length ? this._selected: 'none';
    }

    connectedCallback() {
        this.doInit();
    }

    doInit(event) {
        var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var sParameterName;
        var sParamId = '';
        var i;

        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('='); //to split the key from the value.
            for(var x = 0; x < sParameterName.length; x++){
                if(sParameterName[x] === 'appId'){
                   sParamId = sParameterName[x+1] === undefined ? 'Not found' : sParameterName[x+1];
                }
            }
        }
        if(!sParamId){
            sParamId = this.applicationId;
        }else{
            //redirect to the new app form url
            window.location.href = '/admissions/s/application/' + sParamId;
        }

        this.appId = sParamId;
        
        if (sParamId !== '') {
            var action = retrieveApplicationCoursePreference;
            action({'appId'   : sParamId}).then(response => {
                var data = response;

                // Set the appRecord with the server response
                this.applicationCoursePreference = data["acp"];
                this.surrenderScholarshipOptions = data["surrender_scholarship"];
                this.supervisorName = this.applicationCoursePreference.Research_Supervisors__c;
                this.researchTitle = this.applicationCoursePreference.Research_Title__c;
                this.researchSummary = this.applicationCoursePreference.Research_Summary__c;
                this.applicationType = this.applicationCoursePreference.Graduate_Research_Application_Type__c ;
                this.attendanceType = this.applicationCoursePreference.Attendance_Type__c;
                if(this.applicationCoursePreference.Graduate_Research_Application_Type__c == 'Admission'){
                    this.admissionApp = true;
                    this.scholarshipApp = false;
                }else{
                    this.scholarshipApp = true;
                    this.admissionApp = false;
                }
                
            
                
                this.externalCandidature = this.applicationCoursePreference.External_Supervisor__c;
                if(this.applicationCoursePreference.Research_Supervisors__c != undefined){
                    if(this.externalCandidature){
                        this.externalSupervisorCheck = 'true';
                        this.showExternalCanNotes = true;
                    }else{
                        this.externalSupervisorCheck = 'false';
                    }
                }
                
                this.researchProgramFundingSelected = this.applicationCoursePreference.External_Funding__c;
                if(this.applicationCoursePreference.Research_Supervisors__c != undefined){
                    if(this.researchProgramFundingSelected){
                        this.researchProgramFundingSelectedCheck = 'true';
                    }else{
                        this.researchProgramFundingSelectedCheck = 'false';
                    }
                }
                if(this.scholarshipApp && this.researchProgramFundingSelectedCheck == 'false'){
                    this.showNoteSponsorship = true;
                }
                
                this.selectedExternalFundingValue = this.applicationCoursePreference.External_Funding_Type__c;
                this.sponsorAwardName = this.applicationCoursePreference.External_Funding_Name__c;
                this.monetaryAmount = this.applicationCoursePreference.External_Fund_Duration_Value__c;
                this.surrenderScholarship = this.applicationCoursePreference.Surrender_External_Fund__c;
               
                this.researchProgramFundingFuture = this.applicationCoursePreference.Applied_for_External_Scholarship__c;
                if(this.applicationCoursePreference.Research_Supervisors__c != undefined){

                    if(this.researchProgramFundingFuture){
                        this.researchProgramFundingFutureCheck = 'true';
                    }else{
                        this.researchProgramFundingFutureCheck = 'false';
                    }
                }
                
                this.sponsorAwardNameFuture = this.applicationCoursePreference.Applied_for_External_Scholarship_Name__c;
    
                this.courseResearchAttendance = this.applicationCoursePreference.Employment_During_Research__c;
                if(this.applicationCoursePreference.Research_Supervisors__c != undefined){

                    if(this.courseResearchAttendance){
                        this.courseResearchAttendanceCheck = 'true';
                    }else{
                        this.courseResearchAttendanceCheck = 'false';
                    }
                }
                this.employerPosition = this.applicationCoursePreference.Employer_and_Position__c; 
                
                this.selectedExternalLoadValue = this.applicationCoursePreference.Employment_Load__c;
                if(this.selectedExternalLoadValue == 'Part-Time/Casual'){
                    this.partTimeSelected = true;
                }else{
                    this.partTimeSelected = false;
                }
                this.hoursPerWeek = this.applicationCoursePreference.Employment_Hours__c;
                this.researchDays = this.applicationCoursePreference.Research_Days__c;

                if(this.partTimeSelected && this.applicationCoursePreference.Employment_Days__c != '' && this.applicationCoursePreference.Employment_Days__c != undefined){
                    this.selectItems = this.applicationCoursePreference.Employment_Days__c.split(';');
                    this._selected = this.selectItems;
                }
               
               
            });   
       }
    }

    //Handle field changes
    onFieldChange(e) {
        const fieldName = e.target.name
        switch(fieldName) {
            case "supervisorName":
                this.supervisorName = e.target.value
                break
            case "researchTitle":
                this.researchTitle = e.target.value
                break
            case "researchSummary":
                this.researchSummary = e.target.value
                break
            case "externalCandidature":
                this.setBooleanValue(e.target.name, e.target.value)
                break
            case "researchProgramFunding":
                this.setBooleanValue(e.target.name, e.target.value)
                break
            case "sponsorAwardName":
                this.sponsorAwardName = e.target.value;
                break
            case "monetaryAmount":
                this.monetaryAmount = e.target.value
                break
            case "courseResearchAttendance":
                this.setBooleanValue(e.target.name, e.target.value)
                break
            case "researchProgramFundingFuture":
                this.setBooleanValue(e.target.name, e.target.value)
                break
            case "sponsorAwardNameFuture":
                this.sponsorAwardNameFuture = e.target.value
                break
            case "sponsorshipType":
                this.selectedExternalFundingValue = e.target.value
                break
            case "researchDays":
                this.researchDays = e.target.value
                break
            case "employmentLoad":
                this.selectedExternalLoadValue = e.target.value
                this.checkEmploymentLoad(e.target.value)
                break
            case "employmentDays":
                this.selectedExternalDaysValue = e.target.value
                break
            case "employerPosition":
                this.employerPosition = e.target.value
                break
            case "hoursPerWeek":
                this.hoursPerWeek = e.target.value
                break
            case "surrenderScholarship":
                this.surrenderScholarship = e.target.value
                break
            default:
                //nothing selected
        }
    }

    //display/hide work times during week 
    checkEmploymentLoad(selectedValue){
        if(selectedValue == 'Part-Time/Casual'){
            this.partTimeSelected = true;
        }else{
            if( this.attendanceType== 'FT' && selectedValue == EMPLOYMENT_LOAD_FULL_TIME && 
                this.courseResearchAttendance === true ) {
                let validationErrors = [];
                let validationMessage = 'You have stated that you plan to work full-time while also being enrolled full-time. Given this, your application is unlikely to be successful. It is advised that you consider changing to part-time enrolment or reassess your employment commitment.';
                validationErrors.push(validationMessage);
                this.showErrorsOnPage(validationErrors);
            }
            this.selectItems = [];
            this.partTimeSelected = false;
            this.hoursPerWeek = null;
        }
    }

    //set the boolean values based on triggering field
    setBooleanValue(fieldName, selectedValue){
        if(fieldName == 'externalCandidature'){
            if(selectedValue == 'true'){
                this.externalCandidature = true;
                this.showExternalCanNotes = true;
            }else{
                this.externalCandidature = false;
                this.showExternalCanNotes = false;
            }
        }

        if(fieldName == 'researchProgramFunding'){
            if(selectedValue == 'true'){
                this.researchProgramFundingSelected = true;
                this.showNoteSponsorship = false;
            }else{
                this.selectedExternalFundingValue = '';
                this.sponsorAwardName = '';
                this.monetaryAmount = '';
                this.surrenderScholarship = '';
                this.researchProgramFundingSelected = false;
                if(this.applicationType != 'Admission'){
                    this.showNoteSponsorship = true;
                }
            }
        }

        if(fieldName == 'courseResearchAttendance'){
            if(selectedValue == 'true'){
                this.courseResearchAttendance = true;
            }else{
                this.employerPosition = '';
                this.selectedExternalLoadValue = '';
                this.selectItems = [];
                this.hoursPerWeek = '';
                this.courseResearchAttendance = false;
                this.partTimeSelected = false;
            }
        }

        if(fieldName == 'researchProgramFundingFuture'){
            if(selectedValue == 'true'){
                this.researchProgramFundingFuture = true;
            }else{
                this.sponsorAwardNameFuture = '';
                this.researchProgramFundingFuture = false;
            }
        }


    }

    //check page validity when save and continue button is clicked
    @api
    checkValidity() {
        const allValid = [
            ...this.template.querySelectorAll('lightning-input'),
            ...this.template.querySelectorAll('lightning-select'),
            ...this.template.querySelectorAll('lightning-radio-group'),
            ...this.template.querySelectorAll('lightning-textarea'),
            ...this.template.querySelectorAll('lightning-dual-listbox'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        return allValid;
    }

    //util method to create Select Options from picklist values
    makeSelectOptions(picklistValues) {
        let returnOptions = [];
        returnOptions.push({
            value: '',
            label: '--None--'
        });
        picklistValues.forEach((item) => {
            returnOptions.push({
                label: item.label,
                value: item.value
            });
        });
        return returnOptions;
    }

     //store picklist values to show English Proficiency options on the UI
     @wire(getPicklistValues, {
        recordTypeId: '$acpRecordTypeId',
        fieldApiName: EXTERNAL_FUNDING_TYPE_FIELD
    })
    picklistResults({ error, data }) {
        if (data) {
            this.externalFundingOptions = this.makeSelectOptions(data.values);
        } else if (error) {
            console.log(JSON.stringify(error));
        }
    };

    //display employment load options
    @wire(getPicklistValues, {
        recordTypeId: '$acpRecordTypeId',
        fieldApiName: EMPLOYMENT_LOAD_FIELD
    })
    employmentLoads({ error, data }) {
        if (data) {
            this.externalLoadOptions = this.makeSelectOptions(data.values);
        } else if (error) {
            console.log(JSON.stringify(error));
        }
    };

     //commit the updates to the database via apex controller updateApplicationSponsor
     @api
     saveResearchProgram() {
        var acp = this.applicationCoursePreference;
        this.showSpinner = true;
        var action = saveResearchProgram;
        action({
            acp: acp,
            supervisor: this.supervisorName,
            title: this.researchTitle,
            summary: this.researchSummary,
            externalSupervisor: this.externalCandidature,
            externalFunding: this.researchProgramFundingSelected,
            externalFundingType: this.selectedExternalFundingValue,
            externalFundingName: this.sponsorAwardName,
            externalDuration: this.monetaryAmount,
            appliedForExternalScholarshipCheck: this.researchProgramFundingFuture,
            externalScholarshipName: this.sponsorAwardNameFuture,
            employmentDuringResearchCheck: this.courseResearchAttendance,
            employmentPosition: this.employerPosition,
            employmentDays: this._selected,
            employmentLoad: this.selectedExternalLoadValue,
            employmentHours: this.hoursPerWeek,
            researchDays: this.researchDays,
            surrenderFund: this.surrenderScholarship
        }).then(response => {
            this.showSpinner = false;
            let saveSuccess = true;
            const saveEvent = new CustomEvent("savesuccess", {
                detail: { saveSuccess },
              });
            this.dispatchEvent(saveEvent);
        }).catch(response => {
            this.showSpinner = false;
            var errors = response;
            if (errors) {
                if (errors[0] && errors[0].message) {
                    console.log("Error message: " + 
                             errors[0].message);
                }
            } else {
                console.log("Unknown error");
            }
        });
    }

    //Retrieved employment days values
    @wire(getPicklistValues, {
        recordTypeId: '$acpRecordTypeId',
        fieldApiName: EMPLOYMENT_DAYS_FIELD
    })
    employmentdays({ error, data }) {
        if (data) {
            this.externalDaysOptions = this.makeSelectOptions(data.values);
        } else if (error) {
            console.log(JSON.stringify(error));
        }
    };

    //Handle employment days change    
    handleEmploymentDaysChange(event){
        var slect =[];
        this._selected = event.detail.value;
        var options = event.target.options;
        var details = event.detail;
        var i,j;
        for(i=0; i < details.value.length; i++){
            for(j=0; j < details.value.length; j++){
                if(options[i].value == details.value[j]){
                    slect.push(options[i]);
                }
            }
        }   
        this.selectItems.push(slect);
    }

    /**
     * showErrorsOnPage method
     * @description showing the errors on the UI if any
     * @returns N/A
     */
    showErrorsOnPage(errors) {
        this.saveErrors = errors;
        this.showErrors = true;
        this.showSpinner = false;
    }

    onClickCloseErrors() {
        this.showErrors = false;
    }
            
}