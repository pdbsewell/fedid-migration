import { LightningElement, api, track } from "lwc";
import getCurrentUserAndQualifications from "@salesforce/apex/appAddQualificationCC.getCurrentUserAndQualifications";
import getQualificationRecordTypeOptions from "@salesforce/apex/appAddQualificationCC.getQualificationRecordTypeOptions";
import getAdmissionTestOptions from "@salesforce/apex/appAddQualificationCC.getAdmissionTestOptions";
import getCountryAttributes from "@salesforce/apex/appAddQualificationCC.getCountryAttributes";
import getAusStateOptions from "@salesforce/apex/appAddQualificationCC.getAusStateOptions";
import getCompletionStatusOptions from "@salesforce/apex/appAddQualificationCC.getCompletionStatusOptions";
import getDraftQualifications from "@salesforce/apex/appAddQualificationCC.getDraftQualifications";
import upsertQualificationToContact from "@salesforce/apex/appAddQualificationCC.upsertQualificationToContact";
import deleteContactAndAppQualification from '@salesforce/apex/appAddQualificationCC.deleteContactAndAppQualification';
import saveCreditIntention from '@salesforce/apex/appAddQualificationCC.saveCreditIntention';
import updateApplication from '@salesforce/apex/appAddQualificationCC.updateApplication';
import getCountryNameById from "@salesforce/apex/appAddQualificationCC.getCountryNameById";

import App_DeleteConfirmation from '@salesforce/label/c.App_DeleteConfirmation';
import App_DeleteQualificationLabel from '@salesforce/label/c.App_DeleteQualificationLabel';
import App_EnglishTestDetails_1 from '@salesforce/label/c.App_EnglishTestDetails_1';
import App_TertiaryEducationDetails from '@salesforce/label/c.App_TertiaryEducationDetails';
import App_TertiaryEducationDetails_2 from '@salesforce/label/c.App_TertiaryEducationDetails_2';
import App_InstructedInEnglish from '@salesforce/label/c.App_InstructedInEnglish';

export default class MyAppAddQualification extends LightningElement{
    @api recordId = null;

    @api DEBUGGING = false;

    @api EARLIEST_EXPECTED_DATE = null;
    @api LATEST_COMPLETED_DATE = null;

    @api studyType;
    @api applicantId;

    @api itemsToLoad = 0;
    @api userInfo;
    @api applicationId;
    @api editingDraft = false;
    @api contactQualification;

    /*
    Current state of the component
    START = show add button and list
    SELECT_TYPE = show qualification type drop down
    FORM_DETAILS = form for ADDING/EDITING qualification
    SAVING = saving details
    */
    @track state = "START"; //.. replaced with true/fasle

    //using on application form or my details
    @track isAppComponent = true;

    //the list of added contact qualifications
    @track qualListHistorical;
    @track qualListDraft;
    @track institutionList;

    //the qualification type
    @track qualRecordTypes;
    @track selectedQualRecordTypeId;
    @track qualRecordTypeMap;
    @track selectedQualTypeName;

    //credit intent
    @track showCreditIntention = false;
    @track creditIntention;

    //english language proficiency
    @track englishLanguageProficiency;

    //START - Qualification Fields
    //country
    @track countryOptions;
    @track countryMap;
    @track qualTertiaryCountryId;
    @track qualTertiaryCountry;
    @track qualSecondaryCountryId;
    @track qualSecondaryCountry;

    //Country code (TBC)
    //state is only for Australia
    @track ausStateOptions;
    @track qualTertiaryState;
    @track qualSecondaryState;

    // state_province is only for China or India
    @track qualTertiaryStateProvince;
    @track qualSecondaryStateProvince;
    // qualification name (assessment Type, Overseas Qualification, Title, etc)
    @track qualTertiaryName;

    //controlling which pane to show
    @track tabIdSecondaryType = "SEC_QUAL_NAME_SEARCH";
    @track qualSecondaryType;
    @track qualSecondaryTypeId;

    //Other qualification (free text version )
    @track qualSecondaryTypeOther;

    @track qualAdmissionsName;

    @track englishTestOptions;
    @track qualEnglishTestId;
    @track qualEnglishTestName;
    @track qualEnglishTestTypeMap;

    //Institution (picklist)
    @track tabIdCurrentInstitution = "INSTITUTION_SEARCH";
    @track currentInstitution;
    @track currentInstitutionOther;
    @track mapCurrentInstitutions;
    @track objCurrentInstitution;
    @track showInstitutionSpinner = true;
    @track agencyId;
    @track accountPartnerRecordTypeId;
    @track agencyName;
    @track isApplicationCreatedByPartner = false;
    @track institutionName;
    @track institutionOptions;

    //Awarding Body / Institution (picklist)
    @track tabIdTertiaryAwardingBody = "AUS_TER_SEARCH";
    @track qualTertiaryAwardingBody;
    @track mapTertiaryAwardingBody;
    @track objTertiaryAwardingBody;
    //Other Awarding Body / Institution (free text)
    @track qualTertiaryAwardingBodyOther;

    //School / College / University
    @track tabIdSecondarySchool = "AUS_SEC_SEARCH";
    @track qualSecondarySchool;
    @track mapSecondarySchool;
    @track objSecondarySchool;
    @track qualSecondarySchoolOther;

    //Qualification Completed?
    //Level of Completion
    @track completionLevelOptions;
    @track qualTertiaryLevelOfCompletion;

    //First Year of Enrollment
    @track firstYearEnrolmentOptions;
    @track qualTertiaryFirstYearEnrolled;

    //Which Year did you complete your qualification?
    @track yearCompletedOptions;
    @track qualTertiaryLastYearEnrolled;
    @track qualSecondaryYearCompleted;
    @track qualSecondaryCompleted;
    @track qualSecondaryDateExpected;
    @track errorMsgSecondaryDateExpected = false;

    @track qualEnglishCompleted;
    @track qualEnglishTestDateCompleted;
    @track qualEnglishTestDateExpected;
    @track errorMsgEnglishTestDateExpected;
    @track qualEnglishTestScoreReading;
    @track qualEnglishTestScoreListening;
    @track qualEnglishTestScoreWriting;
    @track qualEnglishTestScoreSpeaking;

    @track qualAdmissionsCompleted = true;
    @track qualAdmissionsDateCompleted;
    @track qualAdmissionsDateExpected;

    @track MAX_COMMENTS_LENGTH = 140;
    @track qualTertiaryComments;
    @track qualSecondaryComments;
    @track qualEnglishComments;
    @track qualAdmissionsComments;

    //Is English the ONLY language of instruction and testing for all courses at the institution where you completed your studies?
    @track qualTertiaryEnglishOnly;
    @track qualSecondaryEnglishOnly;
    @track qualSecondaryScore;

    //score/GPA result
    @track qualTertiaryGPAResult;
    @track qualAdmissionsGPAResult;
    @track qualEnglishGPAResult;
    //END - Qualification Fields

    //current previous notification message
    @track currentpPreviousNotification;

    //global spinner
    @track showSpinner = false;
    @track saveErrors = [];
    @track showErrors = false;

    //setting this to true allows the users to delete on the list
    @track allowDelete = true; 
    @track qualIdToDelete;
    @track showConfirmDelete = false;

    // TODO - show/hide for view only qualifications UNUSED
    @track showViewOnlyPopup = false;

    // yes or no options
    @track yesNoOptions = [{value:'Yes',label:'Yes'},{value:'No',label:'No'}];

    @track hasSavedSection = false;

    //Show hide controls
    @track showMain = false;
    @track showSave = false;
    @track showCancel = false;
    @track noQualificationFound = false;
    @track isNotAbroadType = false;
    @track isAbroadType = false;
    @track showQualificationTypeSelect = false;
    @track showNewQualfiication = false;
    @track showRequiredEng = false;
    @track loadDraftSearchWDropdown = false;

    //qualification type show/hide
    @track terEducQualType = false;
    @track secEducQualType = false;
    @track engTestQualType = false;
    @track otherQualType = false;

    //secondary country show/hide
    @track isAustralia = false;
    @track isChinaOrIndia = false;

    //english test show/hide
    @track showinputQualEngGPAResult = false;
    @track showinputQualEngFourScores = false;
    courseWorkRecordTypes = ['English Test','Other Qualification','Secondary Education','Tertiary Education']
    
    //.. Expose the labels to use in the template.
    label = {
        App_DeleteConfirmation,
        App_DeleteQualificationLabel,
        App_EnglishTestDetails_1,
        App_TertiaryEducationDetails,
        App_TertiaryEducationDetails_2,
        App_InstructedInEnglish
    };
    
    connectedCallback() {
        this.DEBUGGING = true;

        this.saveErrors = [];
      
        this.showMain = true;
        
        var msInADay = 24 * 60 * 60 * 1000;
        
        var dateToday = new Date();        
        //var dateOffset = new Date(dateToday.getTime() - (msInADay));
        var sDateToday = this.formatDateString(dateToday);
        this.EARLIEST_EXPECTED_DATE = sDateToday;        

        // today + 100 days
        var dateMax = new Date(dateToday.getTime() + (1 * msInADay));
        var sDateMax = this.formatDateString(dateMax);
        
        console.log('min = ' + sDateToday + ', max = ' + sDateMax);
        this.LATEST_COMPLETED_DATE = sDateMax;

        this.itemsToLoad = 0;

        //helper.showSpinner(component, true);
        // initial load
        this.loadUserAndQualifications();
        

        // populate year dropdowns
        var dateNow = new Date();
        var yearNow = dateNow.getFullYear();
        var yearsToDisplay = 15;
        this.yearCompletedOptions = this.populateYearPicklist(yearNow - yearsToDisplay,
                                                            yearNow + yearsToDisplay,
                                                            true,
                                                            '--Select--'
                                                        );

        this.firstYearEnrolmentOptions = this.populateYearPicklist(yearNow - yearsToDisplay,
                                                                yearNow + yearsToDisplay,
                                                                true,
                                                                '--Select--'
                                                            );
                                                            

        // load Qualification type options
        this.incrementItemsToLoadCounter('getQualificationRecordTypeOptions');
        getQualificationRecordTypeOptions().then(response => {
            var recordTypes = response.filter((element) => this.courseWorkRecordTypes.includes(element.label))
            this.qualRecordTypes = this.processPicklistOptions(recordTypes, true);
            this.qualRecordTypeMap = this.storeValueLabelMap(this.qualRecordTypes);
            this.itemFinishedLoading('getQualificationRecordTypeOptions');
        });

        // load English Test (Admission Tests in Callista) options
        this.incrementItemsToLoadCounter('getAdmissionTestOptions');
        getAdmissionTestOptions().then(response => {
            this.englishTestOptions = this.processPicklistOptions(response, true);
            this.qualEnglishTestTypeMap = this.storeValueLabelMap(this.englishTestOptions);
            this.itemFinishedLoading('getAdmissionTestOptions');
        });

        // countries=
        this.incrementItemsToLoadCounter('getCountryAttributes');
        getCountryAttributes().then(response => {
            this.countryOptions = this.processPicklistOptions(response, true);
            this.countryMap = this.storeValueLabelMap(this.countryOptions);
            this.itemFinishedLoading('getCountryAttributes');
        });

        // australian states
        this.incrementItemsToLoadCounter('getAusStateOptions');
        getAusStateOptions().then(response => {
            this.ausStateOptions = this.processPicklistOptions(response, true);
            this.itemFinishedLoading('getAusStateOptions');
        });

        // completion statuses
        this.incrementItemsToLoadCounter('getCompletionStatusOptions');
        getCompletionStatusOptions().then(response => {
            this.completionLevelOptions = this.processPicklistOptions(response, true);
            this.itemFinishedLoading('getCompletionStatusOptions');
        });
        this.showSpinner=false;
    }

    renderedCallback(){
        if(this.loadDraftSearchWDropdown == true){
            this.populateSearchDropdowns();
        }
        this.loadDraftSearchWDropdown = false;

    }

    @api
    validateFields(callback) {
        // start loading
        this.showSpinner = true;  

        let result = {
            hasError: false,
            errorMessage: ''
        };

        let englishLanguageProficiency = this.englishLanguageProficiency;
        let missingRequiredError = 'Please ensure that the following fields are completed:<br/>';
        let hasMissingRequiredField = false;

        // english language proficiency
        console.log('*** englishLanguageProficiency ');
        console.log( englishLanguageProficiency );

        if(englishLanguageProficiency === '' || !englishLanguageProficiency){
            hasMissingRequiredField = true;
            missingRequiredError = missingRequiredError + '<span style="padding-left: 1em;">• English Language Proficiency</span><br/>';
            
            //scroll to top
            this.FindElement("englishLanguageProficiency").scrollTop = 0; 
            window.scroll({
                top: 0, 
                left: 0, 
                behavior: 'smooth'
            });
        }
        // current institution must be filled for Study Abroad and Exchange applications
        let currentInstitution = this.institutionName;
        let studyType = this.studyType;
        if ((studyType === 'Study Abroad' || studyType === 'Exchange' ) && ( currentInstitution === '' || !currentInstitution )) {
            hasMissingRequiredField = true;
            missingRequiredError = missingRequiredError + '<span style="padding-left: 1em;">• Current Institution</span><br/>';

            //scroll to top
            this.FindElement("currentInstitution").scrollTop = 0; 
            window.scroll({
                top: 0,
                left: 0,
                behavior: 'smooth'
            });
        }

        // Tertiary Qualification is Mandatory
        if (studyType === 'Study Abroad' || studyType === 'Exchange') {
            let tertiaryQualification = false;
            // check Contact's existing Qualifications (from previous applications)
            let qualifications = this.qualListHistorical;
            if (qualifications !== null && qualifications !== undefined && qualifications.length > 0 && qualifications.find(qual => qual.RecordType.Name === 'Tertiary Education')) {
                tertiaryQualification = true;
            }
            // check Qualifications in the current application
            if (!tertiaryQualification){
                qualifications = this.qualListDraft;
                if (qualifications !== null && qualifications !== undefined && qualifications.length >0 && qualifications.find(qual => qual.RecordType.Name === 'Tertiary Education')) {
                    tertiaryQualification = true;
                }
            }
            if (!tertiaryQualification) {
                hasMissingRequiredField = true;
                missingRequiredError = missingRequiredError + '<span style="padding-left: 1em;">• Tertiary Qualification / Post Secondary</span><br/>';
            }
        }
    
        // save application changes
        if(!hasMissingRequiredField){
            // start saveApplication();
                    
            // construct application record
            let applicationRecord = {
                Id : this.applicationId, 
                English_Language_Proficiency__c : this.englishLanguageProficiency,
                Partner_Name__c : this.institutionName
            }

            updateApplication({"application" : JSON.stringify(applicationRecord)})
                .then(response => {
                    var state = response.STATUS;
                    
                    if(state == 'SUCCESS'){
                        var objResponse = response; 
                    } 

                    //result return
                    result = {
                        "hasError" : false, 
                        "errorMessage" : ""
                    };
                });
            
            //end saveApplication();
        }else{
            result.hasError = hasMissingRequiredField;
            result.errorMessage = missingRequiredError;
        }

        this.hasSavedSection = true;


        // Simulating asynchronous operation (e.g., API call)
        // Promise needed for aura response capture
        setTimeout(() => {
            // end loading
            this.showSpinner = false; 

            // Invoke callback with result
            callback(result);
        }, 9000); // Simulating delay for asynchronous operation
    }

    onClickAddNew() {
        this.setStateTo('SELECT_TYPE');
	}

    onClickSave() {
        this.saveCurrentQualification();
    }

    onClickCancel() {
        // TODO - clear all attributes
        this.clearComponentAttributes();
        this.setStateTo('START');
    }

    onClickDelete(event) {
        var buttonName = event.currentTarget.name;
        console.log('clicked delete for :' + buttonName);
        this.qualIdToDelete = buttonName;

        this.showConfirmDelete = true;
    }

    onClickConfirmDelete() {
        this.showConfirmDelete = false;
        this.setStateTo('DELETING');
        this.showSpinner = true;

        // DELETE and wait for setstate to clear
        this.deleteContactQualification();
    }

    onClickCancelDelete() {
        // clear temp variable
        this.qualIdToDelete = null;

        // close confirm box
        this.showConfirmDelete = false;
    }

    onClickEdit(event) {
        // get the qualification record Id
        var qualificationId = event.currentTarget.name;

        this.editingDraft = true;

        // show the form
        this.setStateTo('FORM_DETAILS');

        // populate the form
        this.loadDraftQualificationIntoForm(qualificationId);


    }

    onSelectQualificationType(event) {
        // clear to-save variable
        this.contactQualification = null;
            
        // update the qualification readable name
        this.selectedQualRecordTypeId = event.detail.value;
        var qualTypeId = this.selectedQualRecordTypeId;
        var qualRecordTypeMap = this.qualRecordTypeMap;
        this.selectedQualTypeName = qualRecordTypeMap[qualTypeId];
        this.showHideQualType(this.selectedQualTypeName);//NS
        console.log('appAddQualificationCtller:: selectedQualTypeName = ' + this.selectedQualTypeName);

        this.setStateTo('FORM_DETAILS');
    }

    onSelectTertiaryCountry(event) {

        // set the name attribute via the map
        this.qualTertiaryCountryId = event.detail.value;
        var countryMap = this.countryMap;

        var selectedId = this.qualTertiaryCountryId;
        this.getcountryname(selectedId);
        var countryName = countryMap[selectedId]
        //this.qualTertiaryCountry = countryName; //Removed bcoz of US-0001162
        
        // Instruction in English Only needs to be set for Australia
        if(countryName == 'Australia')
        {
            this.qualTertiaryEnglishOnly = true;
        }
    }

    getcountryname(selectedId){
        getCountryNameById({
            'countryId': selectedId,
            'format': 'Country__c'
        }).then(response => {
            // response from server 
            var objResponse = response;
            //set qualTertiaryCountry with the response
            this.qualTertiaryCountry = objResponse;
        });
    }

    onSelectSecondaryCountry(event) {
        // selected the country for Secondary
        // set the name attribute via the map
        this.qualSecondaryCountryId = event.detail.value;
        var countryMap = this.countryMap;
        var selectedId = this.qualSecondaryCountryId;
        var countryName = countryMap[selectedId];

        if(countryName != this.qualSecondaryCountry){
            //clear values on country change
            var cmpSearchSecondaryAusQualification = this.FindElement('searchSecondaryAusQualification');
            if(cmpSearchSecondaryAusQualification)
                cmpSearchSecondaryAusQualification.clearValues();

            var cmpSearchSecondaryIntlQualification = this.FindElement('searchSecondaryIntlQualification');
            if(cmpSearchSecondaryIntlQualification)
                cmpSearchSecondaryIntlQualification.clearValues();

            this.qualSecondaryStateProvince = null;
            this.qualSecondaryState = null;
            this.qualSecondaryType = null;
            this.qualSecondaryTypeId = null;
            this.qualSecondaryTypeOther = null;
            this.searchSecondarySchool = null;
            this.qualSecondarySchool = null;
            this.qualSecondarySchoolOther = null;
        }

        this.qualSecondaryCountry = countryName;

        this.showHideSecondaryCountry();
        
        if(countryName == 'Australia')
        {
            this.qualSecondaryEnglishOnly = true;
        }
    }

    onSelectAusState(event){
        this.qualSecondaryState = event.detail.value;
    }
    onSelectStateProvince(event){
        this.qualSecondaryStateProvince = event.detail.value;
    }

    toggleComplete(event) {
        this.qualEnglishCompleted=event.target.checked;
        this.clearScore();
    }

    onSelectEnglishTestType(event) {
        // set the name attribute via the map
        this.qualEnglishTestId = event.detail.value;
        var engTestMap = this.qualEnglishTestTypeMap;
        console.log(JSON.stringify(engTestMap));
        var selectedId = this.qualEnglishTestId;
        this.qualEnglishTestName = engTestMap[selectedId];
        this.showEngTestScore(this.qualEnglishTestName);
        this.clearScore();
    }

    onTabSelectQualification(event) {
        if(!this.loadDraftSearchWDropdown){
            // clear all qualification name values
            this.qualSecondaryType = null;
            this.qualSecondaryTypeId = null;
            this.qualSecondaryTypeOther = null;


            var cmpSearchAusQualification = this.FindElement('searchSecondaryAusQualification');
            if(cmpSearchAusQualification)
                cmpSearchAusQualification.clearValues();
            var cmpSearchIntlQualification = this.FindElement('searchSecondaryIntlQualification');
            if(cmpSearchIntlQualification)
                cmpSearchIntlQualification.clearValues();
        }
    }

    onTabSelectInstitution(event) {
        if(!this.loadDraftSearchWDropdown){
            this.qualSecondarySchoolOther = null;
            this.qualSecondarySchool = null;
            this.objSecondarySchool = null;

            this.qualTertiaryAwardingBody = null;
            this.qualTertiaryAwardingBodyOther = null;
            this.objTertiaryAwardingBody = null;
            
            var cmpSearchTerAwardingBody = this.FindElement('searchTertiaryAwardingBody');
            if(cmpSearchTerAwardingBody)
                cmpSearchTerAwardingBody.clearValues();

            var cmpSearchSecSchool = this.FindElement('searchSecondarySchool');
            if(cmpSearchSecSchool)
                cmpSearchSecSchool.clearValues();
        }
    }

    onChangeSecondaryDateExpected(event) {
        var dateSelected = event.target.value;
        this.qualSecondaryDateExpected = dateSelected;
        if(this.isDatePast(dateSelected))
        {
            this.errorMsgSecondaryDateExpected = true;
        }
        else
        {
            this.errorMsgSecondaryDateExpected = false;
        }
    }

    onChangeEnglishExpected(event) {
        var dateSelected = event.target.value;
        this.qualEnglishTestDateExpected = dateSelected;
        if(this.isDatePast(dateSelected))
        {
            this.errorMsgEnglishTestDateExpected = true;
        }
        else
        {
            this.errorMsgEnglishTestDateExpected = false;
        }
    }
    
    onSearchSelectSecondaryQualification(event) {
        var objSelected = event.detail.sObject;
        this.qualSecondaryType = objSelected;
        this.qualSecondaryTypeId = objSelected.Id;
    }
    
    onSearchSelectSecondarySchool(event) {
        var objSelected = event.detail.sObject;
        this.objSecondarySchool = objSelected; 
    }

    onSearchSelectTertiaryAwardingBody(event) {
        var objSelected = event.detail.sObject;
        //console.log('objSelected = ' + objSelected);
        this.objTertiaryAwardingBody = objSelected;
    }

    onClickCloseAlert() {
        this.clearSaveErrors();
    }

    onChangeCreditIntention(event) {
        this.creditIntention = event.target.checked;
        // update the application credit intention state
    	this.appSaveCreditIntention();
    }

    onChangeEnglishLanguageProficiency(event) {
        this.englishLanguageProficiency = event.detail.value;
        // update the application's english language proficiency field

        console.log('*** onChangeEnglishLanguageProficiency;')

        // start saveApplication();
    	// construct application record
        let applicationRecord = {
            Id : this.applicationId, 
            English_Language_Proficiency__c : this.englishLanguageProficiency,
            Partner_Name__c : this.institutionName
        }
        
        this.incrementItemsToLoadCounter('updateEnglishLanguageProficiency');
        updateApplication({"application" : JSON.stringify(applicationRecord)})
            .then(response => {
                var state = response.STATUS;
                if(state == 'SUCCESS'){
                    var objResponse = response; 
                } 
                this.itemFinishedLoading('updateEnglishLanguageProficiency');
            });
        // end saveApplication();
    }

    onToggleAdmissionsCompleted(event) {
        console.log('on toggle admissions completed');
        this.qualAdmissionsCompleted=event.target.checked;
       
    }

    onSelectCompletionLevel(event) {
        this.qualTertiaryLevelOfCompletion = event.detail.value;
    }

    handleInstitutionChange(event) {
        // set selected current institution
        if(event.detail.target === 'institution'){
            this.institutionName = event.detail.value; //CHECK
        }else{
            this.institutionName = '';
        }
        console.log(JSON.stringify(event));
    }

    handleInstitutionKeyUp(event) {
        // set selected current institution
        if(event.detail.target === 'institution'){
            this.institutionName = event.detail.value; //CHECK
        }
    }

    setStateTo(sState) {
        var currState = this.state;
        
        switch (sState) {
            case 'START':
                // close confirm modals
                this.showConfirmDelete = false;

                // going back to start state, reload
                if(currState != 'START')
                {
                    // clear everything
                    this.clearComponentAttributes();

                    // reload the attached qualifications (historical list will not change)
                    this.loadDraftQualifications();

                }

                this.showMain = true;
                this.showSave = false;
                this.showCancel = false;
                this.showQualificationTypeSelect = false;
                this.showNewQualfiication = false;
                break;

            case 'FORM_DETAILS':

                this.clearSaveErrors();

                this.showMain = false;
                this.showSave = true;
                this.showCancel = true;
                this.showQualificationTypeSelect = true;
                this.showNewQualfiication = true;
                break;

            case 'DELETING':

                this.showMain = false;
                this.showSave = false;
                this.showCancel = false;
                this.showQualificationTypeSelect = false;
                this.showNewQualfiication = false;
                break;

            case 'SELECT_TYPE':

                this.showMain = false;
                this.showSave = false;
                this.showCancel = true;
                this.showQualificationTypeSelect = true;
                this.showNewQualfiication = false;
                break;

            default:

                this.showMain = true;
                this.showSave = false;
                this.showCancel = false;
                this.showQualificationTypeSelect = false;
                this.showNewQualfiication = false;
                break;

        }
	    console.log('appAddQualHelper::setStateTo:' + sState);
		this.state = sState;
	}
    
    clearScore() {
        this.qualEnglishGPAResult = null;
        this.qualEnglishTestScoreReading = null;
        this.qualEnglishTestScoreListening = null;
        this.qualEnglishTestScoreWriting = null;
        this.qualEnglishTestScoreSpeaking = null;
        this.qualEnglishTestDateCompleted = null;
        this.qualEnglishTestDateExpected = null;
        this.qualEnglishComments = null;
    }

    incrementItemsToLoadCounter(calledBy) {
        var iCount = this.itemsToLoad;
        iCount++;
        this.itemsToLoad = iCount;
        console.log('INCREMENT::items to load = ' + iCount + ' from ' + calledBy);
        if(iCount > 0)
        {
            this.showSpinner = true;
        }
    }

    itemFinishedLoading(calledBy) {
        var iCount = this.itemsToLoad;
        iCount --;
        this.itemsToLoad = iCount;

        console.log('LOADED::items to load = ' + iCount + ' from ' + calledBy);
        if(iCount == 0)
        {
            this.showSpinner = false;
        }
    }

    loadUserAndQualifications() {
        var appId = this.parseApplicationIdFromUrl();
        if(!appId){
            appId = this.applicationId;
        }else{
            //redirect to the new app form url
            window.location.href = '/admissions/s/application/' + appId;
        }
        if(!appId)
        {
            console.error('appAddQualificationHelper::loadUserAndQualification:: no app Id');
            return;
        }
        console.log(appId);

        this.incrementItemsToLoadCounter('loadUserAndQualifications');
        getCurrentUserAndQualifications({applicationId: this.applicationId})
            .then(response =>{
                
                var objResponse = response;

                //Retrieve student status and set current / previous notification message
                if(objResponse.STUDENT_STATUS === 'CurrentMatch'){
                    this.currentPreviousNotification = "As you are a current Monash student, you only need to inform us of any non-Monash qualifications that you are currently undertaking."                    
                }else if(objResponse.STUDENT_STATUS === 'PreviousMatch'){
                    this.currentPreviousNotification = "As you are a past Monash student, you only need to inform us of qualifications obtained since last studying at Monash."         
                }

                // get the user info
                this.userInfo = objResponse.user;
                
                this.debugObject(objResponse, 'getCurrentUserAndQualifications');

                // get the editable/deletable qualifications
                var arrDraftQualifications = objResponse['draft_qualifications'];
                this.qualListDraft = arrDraftQualifications;
                this.enrichQualification(this.qualListDraft);
                this.checkQualifications();

                //this.debugArray(component, arrDraftQualifications, 'getCurrentUserAndQualifications::drafts');

                // get the static ones
                var arrHistoricalQualifications = objResponse['historical_qualifications'];
                this.qualListHistorical = arrHistoricalQualifications;
                this.enrichQualification(this.qualListHistorical);
                this.checkQualifications();

                var listInstitutions = objResponse['draft_institutions'];
                this.institutionList = listInstitutions;
                
                // credit intention
                var application = objResponse.application;
                this.creditIntention = application.Credit_Intention__c;
                if(application.AgentName__c){
                    this.institutionName = application.AgentName__c;
                }else if(application.Partner_Name__c){
                    this.institutionName = application.Partner_Name__c;
                }else{
                    this.institutionName = '';
                }
                this.showHideCreditIntention();
                
                // add application study type
                this.studyType = application.Type_of_Study__c;
                this.showHideStudyType();
                this.agencyId = application.Agent__c;
                this.agencyName = application.AgentName__c;             
                this.applicantId = objResponse.APPLICANT; 
                this.isApplicationCreatedByPartner = objResponse.ApplicationCreatedByProfile.toLowerCase().includes('partner');      
                this.accountPartnerRecordTypeId = objResponse.ACCOUNT_PARTNER_RECORDTYPE_ID; 
                this.showInstitutionSpinner = false;

                // english language proficiency             
                this.englishLanguageProficiency = application.English_Language_Proficiency__c;

                // institution options
                var resultInstitutionOptions = objResponse.PARTNER_ACCOUNTS;
                this.institutionOptions = [];
                var institutionOptions = this.institutionOptions;
                if(resultInstitutionOptions){
                    resultInstitutionOptions.forEach(function(institutionOption) {
                        institutionOptions.push({ 
                            label: institutionOption, 
                            value: institutionOption
                        }); 
                    });
                }
                this.institutionOptions = institutionOptions;
                
                this.itemFinishedLoading('loadUserAndQualifications');
            })
            .catch(errors => {
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.error('appAddQualificationHelper::getCurrentUserAndQualifications:' + errors[0].message);
                    }
                }
            });
    }

    parseApplicationIdFromUrl() {
        var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var sParameterName;
        
        var appId;
        for (var i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('=');
            //to split the key from the value.
            for (var j = 0; j < sParameterName.length; j++) {
                if (sParameterName[j] === 'appId') {
                    //get the app Id from the parameter
                    appId = sParameterName[j+1];
                    this.applicationId = appId;
                    return appId;
                }
            }
        }
        
        return null;
    }

    loadDraftQualifications() {
        getDraftQualifications({ applicationId: this.applicationId })
            .then(response => {
                var objResponse = response;

                // set the response
                var arrDraftQualifications = objResponse['draft_qualifications'];
                this.qualListDraft = arrDraftQualifications;
                this.enrichQualification(this.qualListDraft);
                this.checkQualifications();

                var listInstitutions = objResponse['draft_institutions'];
                this.institutionList = listInstitutions;
                
                this.showHideCreditIntention();
            });
    }

    /*loadPicklistOptions(actionName, insertDefault, mapAttrName) { //deprecated for processPicklistOptions
        var action = actionName;

        action().then(response => {

            //store the return response from server (List<Map<String, String>>)
            var arrResponse = response;
            // add a default blank
            var arrOptions = [];
            if(insertDefault)
            {
                arrOptions.push({
                    value:''
                    , label:'-- Select --'
                });
            }

            var iLen = arrResponse.length;
            for(var i = 0; i < iLen; ++i)
            {
                var mapOption = arrResponse[i];
                arrOptions.push(mapOption);
            }

            // if required, store an (id:label) map for lookups later
            if(mapAttrName)
            {
                this.storeValueLabelMap(arrOptions, mapAttrName);
            }

            this.optionAttributeName = arrOptions;
            this.itemFinishedLoading('loadPicklistOptions');
        });
        //this.incrementItemsToLoadCounter('loadPicklistOptions');
    }*/

    processPicklistOptions(response, insertDefault){
        //store the return response from server (List<Map<String, String>>)
        var arrResponse = response;
        // add a default blank
        var arrOptions = [];
        if(insertDefault)
        {
            arrOptions.push({
                value:''
                , label:'-- Select --'
            });
        }

        var iLen = arrResponse.length;
        for(var i = 0; i < iLen; ++i)
        {
            var mapOption = arrResponse[i];
            if(mapOption.label == "Tertiary Education"){
                mapOption.label = mapOption.label + "/Post Secondary";
            }
            arrOptions.push(mapOption);
        }
        return arrOptions;
    }

    storeValueLabelMap(arrOptions) {
        var mapObj = {};
        var iLen = arrOptions.length;
        for(var i = 0; i < iLen; ++i)
        {
            var objOption = arrOptions[i];
            // there may be a blank value
            if(objOption.value) {
                mapObj[objOption.value] = objOption.label;
            }
        }
        this.mapAttrName = mapObj;
        return mapObj;
    }

    populateYearPicklist(earliestYear, latestYear, isAscending, placeHolder) {
        var arrOptions = [];
        arrOptions.push({
            value:''
            , label:placeHolder
        });

        if(isAscending)
        {
            for(var iYear = earliestYear; iYear <= latestYear; ++iYear)
            {
                arrOptions.push({
                    value:iYear
                    , label:iYear
                });
            }
        }
        else
        {
            for(var iYear = latestYear; iYear >= earliestYear; --iYear)
            {
                arrOptions.push({
                    value:iYear
                    , label:iYear
                });
            }
        }

        return arrOptions;
    }

    saveCurrentQualification() {
        // clear previous save errors
        this.saveErrors = [];
        
        // get the record type
        var recTypeId = this.selectedQualRecordTypeId;

        // get the attributes relevant to this record type
        var objContactQualification = this.populateContactQualificationForSave(recTypeId);


        // check for errors
        var arrErrors = this.saveErrors;
        if(arrErrors.length > 0)
        {
            for(var i = 0; i < arrErrors.length; ++i)
            {
                console.log(i + ":" + arrErrors[i]);
            }
            console.log("]");
            
            this.showErrors = true;
        }
        else
        {
            this.incrementItemsToLoadCounter('saveCurrentQualification');
            upsertQualificationToContact({
                'contactId': this.applicantId,
                'applicationId':this.applicationId,
                'contactQualification':objContactQualification
            }).then(response => {
                //store the return response from server (List<Map<String, String>>)
                var objResponse = response;
                this.debugObject(objResponse, 'UpsertQualification');
                this.itemFinishedLoading('saveCurrentQualification');
                this.setStateTo('START');
            });
        }
    }

    populateContactQualificationForSave(recTypeId) {
        var objCQ = this.contactQualification;

        if(!objCQ)
        {
            // saving a new record
            objCQ = {};
            objCQ.RecordTypeId = recTypeId;
        }
        else
        {
            //updating a record
        }

        var objUser = this.userInfo;
        objCQ.Contact__c = this.applicantId;

        // get the corresponding recTypeName
        var recTypeMap = this.qualRecordTypeMap;
        var recTypeName = recTypeMap[recTypeId];

        if(recTypeName == 'Tertiary Education/Post Secondary')
        {
            this.populateContactQualificationTertiarySave(objCQ);
        }
        else if(recTypeName == 'Secondary Education')
        {
            this.populateContactQualificationSecondarySave(objCQ);
        }
        else if(recTypeName == 'English Test')
        {
            this.populateContactQualificationEnglishSave(objCQ);
        }
        else if(recTypeName == 'Other Qualification')
        {
            this.populateContactQualificationAdmissionsSave(objCQ);
        }
        else
        {
            console.error('appAddQualificationHelper:: record type ' + recTypeName + ' not found');
        }

        this.debugObject(objCQ, 'populateContactQualificationForSave');

        // set it back into the page level
        this.contactQualification = objCQ;
        return objCQ;
    }

    isUnsafe(dataObject) {
        const XML_REGEX_PATTERN = /(<.[^(><.)]+>)/g;
        return XML_REGEX_PATTERN.test(JSON.stringify(dataObject));
    }

    captureInputs(event){
        if(event.target.name=='inputQualTertiaryName'){
            this.qualTertiaryName=event.target.value;
        }else if(event.target.name=='inputQualAwardingBodyOther'){
            this.qualTertiaryAwardingBodyOther=event.target.value;
        }else if(event.target.name=='inputQualTertiaryEnglishOnly'){
            this.qualTertiaryEnglishOnly=event.target.checked;
        }else if(event.target.name=='inputQualTertiaryFirstYearEnrolment'){
            this.qualTertiaryFirstYearEnrolled=event.target.value;
        }else if(event.target.name=='inputQualTertiaryLastYearEnrolment'){
            this.qualTertiaryLastYearEnrolled=event.target.value;
        }else if(event.target.name=='inputQualTertiaryComments'){
            this.qualTertiaryComments=event.target.value;
        }else if(event.target.name=='inputQualSecondaryOther'){
            this.qualSecondaryTypeOther=event.target.value;
        }else if(event.target.name=='inputQualAwardingBodyOtherSec'){
            this.qualSecondarySchoolOther=event.target.value;
        }else if(event.target.name=='inputQualSecondaryEnglishOnly'){
            this.qualSecondaryEnglishOnly=event.target.checked;
        }else if(event.target.name=='inputQualSecondaryIsCompleted'){
            this.qualSecondaryCompleted=event.target.checked;
        }else if(event.target.name=='inputQualSecondaryYearCompleted'){
            this.qualSecondaryYearCompleted=event.target.value;
        }else if(event.target.name=='inputQualSecondaryComments'){
            this.qualSecondaryComments=event.target.value;
        }else if(event.target.name=='inputQualAdmissionsName'){
            this.qualAdmissionsName=event.target.value;
        }else if(event.target.name=='inputQualAdmissionsDateCompleted'){
            this.qualAdmissionsDateCompleted=event.target.value;
        }else if(event.target.name=='inputQualAdmissionsDateExpected'){
            this.qualAdmissionsDateExpected=event.target.value;
        }else if(event.target.name=='inputQualAdmissionsComments'){
            this.qualAdmissionsComments=event.target.value;
        }else if(event.target.name=='inputQualEnglishTestDateCompleted'){
            this.qualEnglishTestDateCompleted=event.target.value;
        }else if(event.target.name=='inputQualEnglishComments'){
            this.qualEnglishComments=event.target.value;
        }else if(event.target.name=='inputQualEnglishGPAResult'){
            this.qualEnglishGPAResult=event.target.value;
        }else if(event.target.name=='inputQualEnglishListeningScore'){
            this.qualEnglishTestScoreListening=event.target.value;
        }else if(event.target.name=='inputQualEnglishReadingScore'){
            this.qualEnglishTestScoreReading=event.target.value;
        }else if(event.target.name=='inputQualEnglishWritingScore'){
            this.qualEnglishTestScoreWriting=event.target.value;
        }else if(event.target.name=='inputQualEnglishSpeakingScore'){
            this.qualEnglishTestScoreSpeaking=event.target.value;
        }
    }

    populateContactQualificationTertiarySave(objCQ) {
        var arrSaveErrors = [];        
        
        // country/state
        var country = this.qualTertiaryCountryId;
        if(!country)
        {
            arrSaveErrors.push('Country');
        }
        objCQ.Qualification_Country__c = country;


        var tertiaryState = this.qualTertiaryState;
        var tertiaryStateProvince = this.qualTertiaryStateProvince;
        if(tertiaryState)
            objCQ.State__c = tertiaryState;
        else if(tertiaryStateProvince)
            objCQ.State_Province__c = tertiaryStateProvince;

        // name of qualification - always free text for tertiary
        var qualName = this.qualTertiaryName;
        objCQ.Other_Qualification__c = qualName;
        if(!qualName)
        {
            arrSaveErrors.push('Qualification Type');
        }

        // awarding body
        var qualTertiaryAwardingBodyOther = this.qualTertiaryAwardingBodyOther;
        var objInstitution = this.objTertiaryAwardingBody;
        if(qualTertiaryAwardingBodyOther)
        {
            // free text version
            objCQ.Other_Institution__c = this.qualTertiaryAwardingBodyOther;
            objCQ.Institution_Name__c = null;
            objCQ.Institution_Code__c = null;
        }
        else if(objInstitution)
        {
            objCQ.Institution_Name__c = objInstitution.Institution_Name__c;
            objCQ.Institution_Code__c = objInstitution.Institution_Code__c;
            objCQ.Other_Institution__c = null;
        }
        else
        {
            arrSaveErrors.push('Awarding Body or Institution');
        }

        // years of enrolment
        var firstYear = this.qualTertiaryFirstYearEnrolled;
        objCQ.First_Year_Enrolled__c = firstYear;
        if(!firstYear || !this.isInputValid("inputQualTertiaryFirstYearEnrolment") )
        {            
            arrSaveErrors.push('First year enrolled');
        }
        
        var lastYear = this.qualTertiaryLastYearEnrolled;
        objCQ.Last_Year_Enrolled__c = lastYear;
        if(!lastYear || !this.isInputValid("inputQualTertiaryLastYearEnrolment"))
        {
            arrSaveErrors.push('Last year enrolled');
        }
        
        if(firstYear > lastYear)
        {
            arrSaveErrors.push('Last year enrolled must be later than your first');
        }

        // level of completion - using integrated field 'Status__c'
        var levelOfCompletion = this.qualTertiaryLevelOfCompletion;        
        objCQ.Status__c = levelOfCompletion;
        if(!levelOfCompletion)
        {
            arrSaveErrors.push('Level of Completion')
        }

        // is it english only
        objCQ.Instruction_in_English__c = this.qualTertiaryEnglishOnly;
        // comments
        objCQ.Other_Qualification_Comments__c = this.qualTertiaryComments;
        // score
        objCQ.Score__c = this.qualTertiaryGPAResult;
        
        if (this.isUnsafe(objCQ)) arrSaveErrors.push('One or more input boxes are not in the expected format.');
        
        this.saveErrors = arrSaveErrors;
        return objCQ;
    }

    populateContactQualificationSecondarySave(objCQ) {
        console.log('*** objCQ');
        console.log(objCQ);
        var arrSaveErrors = [];

        // country/state
        var country = this.qualSecondaryCountryId;
        if(!country)
        {
            arrSaveErrors.push('Country');
        }
        objCQ.Qualification_Country__c = country;

        var secondaryState = this.qualSecondaryState;
        var secondaryStateProvince = this.qualSecondaryStateProvince;
        if(secondaryState)
            objCQ.State__c = secondaryState;
        else if(secondaryStateProvince)
            objCQ.State_Province__c = secondaryStateProvince;

		var countryName = this.qualSecondaryCountry;    
        if(!secondaryState && countryName == 'Australia')
        {
            arrSaveErrors.push('State');
        }
        else if(!secondaryStateProvince
                && (countryName == 'China (excludes SARs and Taiwan)' || countryName =='India'))
        {
            arrSaveErrors.push('State/Province');
        }

        // name of qualification
        var qualSecondaryTypeOther = this.qualSecondaryTypeOther;
        var qualSecondary = this.qualSecondaryType;
        var qualSecondaryId = this.qualSecondaryTypeId;
        console.log('*** qualSecondaryTypeOther');
        console.log(qualSecondaryTypeOther);
        console.log('*** qualSecondary');
        console.log(qualSecondary);
        console.log('*** qualSecondaryId');
        console.log(qualSecondaryId);
        if(qualSecondaryTypeOther) {
            objCQ.Other_Qualification__c = this.qualSecondaryTypeOther;
            objCQ.Qualification__c = null;
            objCQ.Qualification__r = null;
        }
        else if(qualSecondaryId){
            objCQ.Qualification__c = qualSecondaryId;
            objCQ.Qualification__r = qualSecondary;
            objCQ.Other_Qualification__c = null;
        }
        else
        {
            arrSaveErrors.push('Qualification Name');
        }
        

        // school
        var qualSecondarySchoolOther = this.qualSecondarySchoolOther;
        var objSecondarySchool = this.objSecondarySchool;   
        if(qualSecondarySchoolOther) {
            // free text
            objCQ.Other_Institution__c = this.qualSecondarySchoolOther;

            // clear the search version
            objCQ.Institution_Code__c = null;
            objCQ.Institution_Name__c = null;
        }
        else if(objSecondarySchool)
        {
            // store the values from the sObject
            objCQ.Institution_Name__c = objSecondarySchool.Institution_Name__c;
            objCQ.Institution_Code__c = objSecondarySchool.Institution_Code__c;

            objCQ.Other_Institution__c = null;
        }
        else if(!qualSecondarySchoolOther && !objSecondarySchool)
        {
            arrSaveErrors.push('School/Institution');
        }

        // completed / expected

        var isComplete = this.qualSecondaryCompleted;
        if(isComplete)
        {
            var yearCompleted = this.qualSecondaryYearCompleted;
            
            if(!yearCompleted || !this.isInputValid("inputQualSecondaryYearCompleted"))
            {
                arrSaveErrors.push('Year of completion');
            }

            //Set completion year
            var yearCompletionCurrentDate = new Date();
            yearCompletionCurrentDate.setFullYear(parseInt(yearCompleted));

            //Set current year
            var currentDate = new Date();

            //Compare years
            if(yearCompletionCurrentDate > currentDate){
                arrSaveErrors.push('Completion Year must be less than or equal to the Current Year');
            }

            objCQ.Year_of_Completion__c = yearCompleted;
            objCQ.Expected_date_of_completion__c = null;
        }
        else
        {
            objCQ.Year_of_Completion__c = null;

            // validate that it is not a date in the past
            var dateExpected = this.qualSecondaryDateExpected;
            if(!dateExpected)
            {
                arrSaveErrors.push('Expected date of completion');
            }
            else if(!this.isExpectedDateValid(dateExpected))
            {
                this.addErrorMessageExpectedDatePast(arrSaveErrors);
            }
            else
            {
                objCQ.Expected_date_of_completion__c = dateExpected;
            }
        }
        
        // comments
        objCQ.Other_Qualification_Comments__c = this.qualSecondaryComments;

        // score, always 0
        objCQ.Score__c = "0";

        // is it english only
        objCQ.Instruction_in_English__c = this.qualSecondaryEnglishOnly;
         if (this.isUnsafe(objCQ)) arrSaveErrors.push('One or more input boxes are not in the expected format.');
        this.saveErrors = arrSaveErrors;

        console.log('*** return objCQ');
        console.log(objCQ);
        
        return objCQ;
    }

    addErrorMessageExpectedDatePast(arrSaveErrors) {
        arrSaveErrors.push('Expected Date of Completion is in the past');
    }

    loadDraftSecondary(objCQ) {
        var mapCountry = this.countryMap;
        // country/state
        this.qualSecondaryCountryId = objCQ.Qualification_Country__c;

        var countryName = mapCountry[objCQ.Qualification_Country__c];
        this.qualSecondaryCountry = countryName;
        this.showHideSecondaryCountry();

        if(objCQ.State_Province__c)
            this.qualSecondaryStateProvince = objCQ.State_Province__c;
        if(objCQ.State__c)
            this.qualSecondaryState = objCQ.State__c;

        // name of qualification
        if(objCQ.Other_Qualification__c )
        {
            this.tabIdSecondaryType = 'SEC_QUAL_NAME_MANUAL';
            this.qualSecondaryTypeOther = objCQ.Other_Qualification__c;
        }
        else
        {
            this.tabIdSecondaryType = 'SEC_QUAL_NAME_SEARCH';

            if(objCQ.Qualification__c) {
                // from drop down
                this.qualSecondaryType = objCQ.Qualification__r;
                this.qualSecondaryTypeId = objCQ.Qualification__c;

            }
        }

        // secondary school
        if(objCQ.Other_Institution__c)
        {
            this.tabIdSecondarySchool = 'AUS_SEC_MANUAL';
            this.qualSecondarySchoolOther = objCQ.Other_Institution__c;
        }
        else if(objCQ.Institution_Code__c && objCQ.Institution_Name__c)
        {
            this.tabIdSecondarySchool = 'AUS_SEC_SEARCH';

            var objSecondarySchool = this.lookupInstitution(objCQ);
            this.qualSecondarySchool = objSecondarySchool.Id;
            this.objSecondarySchool = objSecondarySchool;

        }
        else
        {
        }

        // years of enrolment
        var secondaryYearCompleted = objCQ.Year_of_Completion__c;
        if(secondaryYearCompleted)
        {
            this.qualSecondaryCompleted = true;
            this.qualSecondaryDateExpected = null;
            this.qualSecondaryYearCompleted = secondaryYearCompleted;

        }
        else
        {
            this.qualSecondaryCompleted = false;
            this.qualSecondaryDateExpected = objCQ.Expected_date_of_completion__c;
            this.qualSecondaryYearCompleted = null;
        }

        // comments
        this.qualSecondaryComments = objCQ.Other_Qualification_Comments__c;
        
        // level of completion
        this.qualSecondaryScore = objCQ.Score__c;
        // is it english only
        this.qualSecondaryEnglishOnly = objCQ.Instruction_in_English__c;

    }

    deleteContactQualification() {
        this.incrementItemsToLoadCounter('deleteContactQualification');
        deleteContactAndAppQualification({
            'contactQualificationId': this.qualIdToDelete,
            'applicationId':this.applicationId
        }).then(response => {
            //store the return response from server (List<Map<String, String>>)
            var objResponse = response;
            this.debugObject(objResponse, 'deleteContactQualification');

            // check if we need to clear and hide the credit intention
            var application = objResponse.application;
            this.creditIntention = application.Credit_Intention__c;
            this.itemFinishedLoading('deleteContactQualification');

            // back to original state
            this.setStateTo('START');
        }).catch(errors => {
            if (errors) {
                if (errors[0] && errors[0].message) {
                    console.error('appAddQualificationHelper::deleteContactQualification ' + errors[0].message);
                }
            }
        });
    }

    loadDraftQualificationIntoForm(contactQualificationId) {
        // populate the fields from an existing draft qualification
        var qualListDraft = this.qualListDraft;
        var objCQ;

        for(var i = 0; i < qualListDraft.length; ++i)
        {
            var conQual = qualListDraft[i];
            if(conQual.Id == contactQualificationId)
            {
                objCQ = conQual;
                break;
            }
        }
        if(objCQ)
        {
            // set the page attribute
            this.contactQualification = objCQ;

            var recTypeName = objCQ.recordTypeLabel;
            this.selectedQualRecordTypeId = objCQ.RecordTypeId;
            this.selectedQualTypeName = recTypeName;

            if(recTypeName == 'Tertiary Education/Post Secondary')
            {
                this.loadDraftTertiary(objCQ); 
                this.loadDraftSearchWDropdown = true;
            }
            else if(recTypeName == 'Secondary Education')
            {
                this.loadDraftSecondary(objCQ);
                this.loadDraftSearchWDropdown = true;
            }
            else if(recTypeName == 'English Test')
            {
                this.loadDraftEnglish(objCQ);

            }
            else if(recTypeName == 'Other Qualification')
            {
                this.loadDraftAdmissions(objCQ);
            }
            else
            {
                console.error('appAddQualificationHelper:: record type ' + recTypeName + ' not found');
            }
        }
        else
        {
            console.error('appAddqualificationHelper::loadDraftQualification - could not find draft record ' + contactQualificationId);
        }
        
        this.showHideQualType(this.selectedQualTypeName);
    }

    loadDraftTertiary(objCQ) {
        var mapCountry = this.countryMap;
        // country/state
        this.qualTertiaryCountryId = objCQ.Qualification_Country__c;
        //this.qualTertiaryCountry = mapCountry[objCQ.Qualification_Country__c]; Commented as part of US-0001162
        this.getcountryname(this.qualTertiaryCountryId);

        // name of qualification - always free text for tertiary
        this.qualTertiaryName = objCQ.Other_Qualification__c;

        // awarding body
        if(objCQ.Other_Institution__c)
        {
            // switch the tab first, because it will clear the values
            this.tabIdTertiaryAwardingBody = 'AUS_TER_MANUAL';
            this.qualTertiaryAwardingBodyOther = objCQ.Other_Institution__c;
        }
        else
        {
            // switch the tab first, because it will clear the values
            this.tabIdTertiaryAwardingBody = 'AUS_TER_SEARCH';
            if(objCQ.Institution_Code__c) {
                var objTertiaryBody = this.lookupInstitution(objCQ);
                this.qualTertiaryAwardingBody = objTertiaryBody.Id;
                this.objTertiaryAwardingBody = objTertiaryBody;
            }

        }

        // years of enrolment
        this.qualTertiaryFirstYearEnrolled = objCQ.First_Year_Enrolled__c;
        this.qualTertiaryLastYearEnrolled = objCQ.Last_Year_Enrolled__c;

        // level of completion - using integrated field 'Status__c'
        this.qualTertiaryLevelOfCompletion = objCQ.Status__c;        

        // is it english only
        this.qualTertiaryEnglishOnly = objCQ.Instruction_in_English__c;

        // comments
        this.qualTertiaryComments = objCQ.Other_Qualification_Comments__c;
        
        // score
        this.qualTertiaryGPAResult = objCQ.Score__c;

    }

    loadDraftEnglish(objCQ) {
        this.qualEnglishTestId = objCQ.Qualification__c;
        var qualification = objCQ.Qualification__r;
        if (qualification) {
            this.qualEnglishTestName = qualification.Qualification_Name__c;
            this.showEngTestScore(this.qualEnglishTestName);
        }

        var isComplete = objCQ.isTestCompleted__c;
        this.qualEnglishCompleted = isComplete;
        
        
        // if completed or expecting completion
        var dateAchieved = objCQ.Date_Achieved__c;
        if(isComplete) {
            this.qualEnglishTestDateCompleted = objCQ.Date_Achieved__c;            
        }
        else {
            this.qualEnglishTestDateExpected = objCQ.Expected_date_of_completion__c;
        }

        // comments
        this.qualEnglishComments = objCQ.Other_Qualification_Comments__c;        
        
        this.qualEnglishGPAResult = objCQ.Score__c;
        this.qualEnglishTestScoreListening = objCQ.Listening__c;
        this.qualEnglishTestScoreReading = objCQ.Reading__c;
        this.qualEnglishTestScoreSpeaking = objCQ.Speaking__c;
        this.qualEnglishTestScoreWriting = objCQ.Writing__c;
    }

    loadDraftAdmissions(objCQ) {
        this.qualAdmissionsName = objCQ.Other_Qualification__c;
        this.qualAdmissionsGPAResult = objCQ.Score__c;


        var isCompleted = objCQ.isTestCompleted__c;
        this.qualAdmissionsCompleted = isCompleted;

        // if completed or expecting completion
        if(isCompleted)
        {
            var dateAchieved = objCQ.Date_Achieved__c;
            this.qualAdmissionsDateCompleted = objCQ.Date_Achieved__c;
        }
        else
        {
            this.qualAdmissionsDateExpected = objCQ.Expected_date_of_completion__c;
        }
        this.qualAdmissionsComments = objCQ.Other_Qualification_Comments__c;
    }

    lookupInstitution(objCQ) {
        var institutionCode = objCQ.Institution_Code__c;
        var institutionName = objCQ.Institution_Name__c;

        var institutionList = this.institutionList;
        for( var i = 0; i < institutionList.length; ++i)
        {
            var objInstitution = institutionList[i];
            if(objInstitution.Institution_Code__c == institutionCode && objInstitution.Institution_Name__c == institutionName)
            {
                return objInstitution;
            }
        }
        return null;
    }

    populateContactQualificationEnglishSave(objCQ) {
        var arrSaveErrors = [];
        var englishTestType = this.qualEnglishTestId;

        if(!englishTestType)
        {
            arrSaveErrors.push('English Test Type');
        }    
        objCQ.Qualification__c = englishTestType;

        var isComplete = this.qualEnglishCompleted;
        objCQ.isTestCompleted__c = isComplete;
        if(isComplete) 
        {
            var dateAchieved = this.qualEnglishTestDateCompleted;

            if(!dateAchieved)
            {
                arrSaveErrors.push('Date Achieved');
            }
            else if(!this.isCompletedDateValid(dateAchieved))
            {
                arrSaveErrors.push('Date Achieved is invalid');
            }
            else
            {
                objCQ.Date_Achieved__c = dateAchieved;
            }
            objCQ.Expected_date_of_completion__c = null;


            this.validateEnglishScores(objCQ, arrSaveErrors);
        }
        else
        {
            var dateExpected = this.qualEnglishTestDateExpected;
            if(!dateExpected)
            {
                arrSaveErrors.push('Expected Date of Completion');
            }
            else if(this.isDatePast(dateExpected))
            {
                this.addErrorMessageExpectedDatePast(arrSaveErrors);
            }
            else
            {
                objCQ.Expected_date_of_completion__c = dateExpected;
            }
            objCQ.Date_Achieved__c = null;

            // all scores to be sending 0
            objCQ.Score__c = "0";
            objCQ.Listening__c = "0";
            objCQ.Writing__c = "0";
            objCQ.Speaking__c = "0";
            objCQ.Reading__c = "0";
        }

        
        // comments
        objCQ.Other_Qualification_Comments__c = this.qualEnglishComments;
        if (this.isUnsafe(objCQ)) arrSaveErrors.push('One or more input boxes are not in the expected format.');
        this.saveErrors = arrSaveErrors;
    }

    validateEnglishScores(objCQ, arrSaveErrors) {
        if(this.isInputValid('inputQualEnglishGPAResult'))
        {
            objCQ.Score__c = this.qualEnglishGPAResult;
        }
        else
        {
            arrSaveErrors.push('English Score/Result - Incorrect format or missing information');
        }

        if(this.isInputValid('inputQualEnglishListeningScore'))
        {
            objCQ.Listening__c = this.qualEnglishTestScoreListening;
        }
        else
        {
            arrSaveErrors.push('English Listening Score');
        }

        // Reading
        if(this.isInputValid('inputQualEnglishReadingScore'))
        {
            objCQ.Reading__c = this.qualEnglishTestScoreReading;
        }
        else
        {
            arrSaveErrors.push('English Reading Score');
        }

        // speaking
        if(this.isInputValid('inputQualEnglishSpeakingScore'))
        {
            objCQ.Speaking__c = this.qualEnglishTestScoreSpeaking;
        }
        else
        {
            arrSaveErrors.push('English Speaking Score');
        }

        // writing
        if(this.isInputValid('inputQualEnglishWritingScore'))
        {
            objCQ.Writing__c = this.qualEnglishTestScoreWriting;
        }
        else
        {
            arrSaveErrors.push('English Writing Score is not valid');
        }
    }

    isCompletedDateValid(dateString) {
        var dateToday = new Date();
        var dateValue = new Date(dateString);
        if(dateValue > dateToday)
            return false;
        return true;
    }

    isExpectedDateValid(dateString) {
        var dateToday = new Date();
        var dateValue = new Date(dateString);
        if(dateValue < dateToday)
            return false;
        return true;
    }

    isInputValid(cmpId) {
        // expected/completed dates
        var cmpInput = this.FindElement(cmpId);
        if(cmpInput != null){
            var valid = cmpInput.checkValidity();
            return valid;
        }
        return true;

    }

    populateContactQualificationAdmissionsSave(objCQ) {   
        var arrSaveErrors = [];
        
        var qualName = this.qualAdmissionsName;
        objCQ.Other_Qualification__c = qualName;
        if(!qualName)
        {
            arrSaveErrors.push('Qualification Name');
        }        
        
        objCQ.Score__c = this.qualAdmissionsGPAResult;
        
        var isComplete = this.qualAdmissionsCompleted;
        objCQ.isTestCompleted__c = isComplete;
        if(isComplete) 
        {
            var dateAchieved = this.qualAdmissionsDateCompleted;            
            objCQ.Date_Achieved__c = dateAchieved;
            if(!dateAchieved || !this.isCompletedDateValid(dateAchieved))
            {
                arrSaveErrors.push('Date Achieved');
            }
            objCQ.Expected_date_of_completion__c = null;
        }
        else
        {
            var dateExpected = this.qualAdmissionsDateExpected;
            objCQ.Expected_date_of_completion__c = dateExpected;
            if(!dateExpected || !this.isExpectedDateValid(dateExpected))
            {
                arrSaveErrors.push('Expected Date of Completion');
            }
            objCQ.Date_Achieved__c = null;
        }        
            objCQ.Other_Qualification_Comments__c = this.qualAdmissionsComments;
            if (this.isUnsafe(objCQ)) arrSaveErrors.push('One or more input boxes are not in the expected format.');
            this.saveErrors = arrSaveErrors;
    }

    reverseLookupFromMap(component, mapAttrName, searchField, searchValue) {
        var mapLookup = component.get(mapAttrName);
        for(var key in mapLookup)
        {
            var obj = mapLookup[key];
            if(obj[searchField] == searchValue)
                return obj;
        }
        // error, not found
        console.error('appAddQualifcationHelper:: ' + searchField + '=' + searchValue+ ', not found');
    }

    reverseLookupInstitutionId(component, mapAttrName, institutionName, institutionCode) {
        var mapInstitutions = component.get(mapAttrName);

        for(var instId in mapInstitutions)
        {
            var objInstitute = mapInstitutions[instId];
            if(objInstitute.Institution_Name__c == institutionName &&
            objInstitute.Institution_Code__c == institutionCode)
            {
                return instId;
            }
        }

        // if you got here, not found
        console.error('appAddQualifcationHelper:: id for ' + institutionName + ', ' + institutionCode + ', not found');
    }

    clearComponentAttributes() {
        // clear to-save variable
        this.contactQualification = null;

        // not editing
        this.editingDraft = false;

        // record type
        this.selectedQualRecordTypeId = null;
        this.qualTertiaryCountryId = null;
        this.qualTertiaryCountry = null;
        this.qualSecondaryCountryId = null;
        this.qualSecondaryCountry = null;
        this.qualTertiaryState = null;
        this.qualSecondaryState = null;

        this.qualTertiaryName = null;

        this.tabIdSecondaryType = 'SEC_QUAL_NAME_SEARCH';
        this.qualSecondaryType = null;
        this.qualSecondaryTypeId = null;
        this.qualSecondaryTypeOther = null;
        this.qualAdmissionsName = null;
        this.qualEnglishTestId = null;
        this.qualEnglishTestName = null;

        this.tabIdTertiaryAwardingBody = 'AUS_TER_SEARCH';
        this.qualTertiaryAwardingBody = null;
        this.qualTertiaryAwardingBodyOther = null;
        this.objTertiaryAwardingBody = null;

        this.currentInstitution = null;        
        this.mapCurrentInstitutions = null;

        this.tabIdSecondarySchool = 'AUS_SEC_SEARCH';
        this.qualSecondarySchool = null;
        this.qualSecondarySchoolOther = null;
        this.objSecondarySchool = null;


        this.qualTertiaryLevelOfCompletion = null;
        this.qualTertiaryFirstYearEnrolled = null;
        this.qualTertiaryLastYearEnrolled = null;
        this.qualTertiaryComments = null;

        this.qualSecondaryCompleted = null;
        this.qualSecondaryYearCompleted = null;
        this.qualSecondaryDateExpected = null;
        this.qualSecondaryComments = null;
        
        this.errorMsgSecondaryDateExpected = false;

        this.qualAdmissionsCompleted = null;
        this.qualAdmissionsDateExpected = null;
        this.qualAdmissionsDateCompleted = null;
        this.qualEnglishCompleted = null;
        this.qualEnglishTestDateCompleted = null;
        this.qualEnglishTestDateExpected = null;
        this.errorMsgEnglishTestDateExpected = false;

        //Clears English Score
        this.clearScore();
        
        this.qualAdmissionsComments = null;

        this.qualTertiaryEnglishOnly = null;
        this.qualSecondaryEnglishOnly = null;
        this.qualSecondaryScore = null;
        this.qualTertiaryGPAResult = null;
        
        var cmpSearchAusQualification = this.FindElement('searchSecondaryAusQualification');
        if(cmpSearchAusQualification)
            cmpSearchAusQualification.clearValues();
        
        var cmpSearchIntlQualification = this.FindElement('searchSecondaryIntlQualification');
        if(cmpSearchIntlQualification)
            cmpSearchIntlQualification.clearValues();
        
        var cmpSearchTerAwardingBody = this.FindElement('searchTertiaryAwardingBody');
        if(cmpSearchTerAwardingBody)
            cmpSearchTerAwardingBody.clearValues();

        var cmpSearchSecSchool = this.FindElement('searchSecondarySchool');
        if(cmpSearchSecSchool)
            cmpSearchSecSchool.clearValues();
    }

	formatDateString(aDate) {
        var dd = aDate.getDate();
        var mm = aDate.getMonth() + 1; //January is 0!
        var yyyy = aDate.getFullYear();
        // if date is less then 10, then append 0 before date
        if(dd < 10){
            dd = '0' + dd;
        }
        // if month is less then 10, then append 0 before date
        if(mm < 10){
            mm = '0' + mm;
        }

        var sFormattedDate = yyyy+'-'+mm+'-'+dd;
        return sFormattedDate;
	}

    isDatePast(aDate) {
        if(!aDate) {
            // early out, no error
            return false;
        }

        var today = new Date();
        var todayFormattedDate = this.formatDateString(today);
        
        if(aDate < todayFormattedDate)
        {
            console.error(aDate + " < " + todayFormattedDate);
            return true;
        }
        return false;
    }

    debugObject(objDebug, functionName) {
        if(this.DEBUGGING == true)
        {
            console.log(functionName + ':object {');
            for(var k in objDebug)
            {
                console.log(k + ' : ' + objDebug[k]);
            }
            console.log('}');
        }
    }

    /*debugArray(component, arr, functionName) {
        if(component.get('v.DEBUGGING') == true)
        {
            console.log(functionName + ' array :')

            var iLen = arr.length;
            for(var i = 0; i < iLen; ++i)
            {
                var objDebug = arr[i];
                if(objDebug instanceof Object)
                {
                    this.debugObject(component, objDebug, functionName + '[' + i + ']');
                }
                else
                    console.log('[' + i + ']:' + arr[i]);
            }
            console.log(']');
        }
    }*/

    clearSaveErrors() {
        this.showErrors = false;
        this.saveErrors = [];
    }

    showHideCreditIntention() {
        var qualsHistorical = this.qualListHistorical;
        
        var showCredit = false;
        for(var i = 0; i < qualsHistorical.length; ++i)
        {
            var objCQ = qualsHistorical[i];

            var recType = objCQ.RecordType;
            if(recType && recType.Name == 'Tertiary Education')
            {
                showCredit = true;
                break;
            }
        }
        
        if(!showCredit)
        {
            var qualsDraft = this.qualListDraft;
            // loop through drafts
        	for(var i = 0; i < qualsDraft.length; ++i)
            {
                var objCQ = qualsDraft[i];

                var recType = objCQ.RecordType;
                if(recType && recType.Name == 'Tertiary Education')
                {
                    showCredit = true;
                    break;
                }
            }
        }
        this.showCreditIntention = showCredit;
    }

    appSaveCreditIntention() {
        var creditInt = this.creditIntention;
        var appId = this.applicationId;

        
        this.incrementItemsToLoadCounter('appSaveCreditIntention');
        saveCreditIntention({
            applicationId:appId,
            creditIntent:creditInt
        }).then(response => {
            var objResponse = response; 
            this.itemFinishedLoading('appSaveCreditIntention');

        });
    }

    FindElement(cmpId) {
        return this.template.querySelector(`[data-id="${cmpId}"]`);
    }

    enrichQualification(qualDraftList){
        //crate a recordTypeLabel
        for(var i = 0; i < qualDraftList.length; ++i){
            var objCQ = qualDraftList[i];

            var recType = objCQ.RecordType;
            if(recType && recType.Name == 'Tertiary Education'){
                qualDraftList[i].recordTypeLabel = 'Tertiary Education/Post Secondary';
            }else{
                qualDraftList[i].recordTypeLabel = objCQ.RecordType.Name;
            }
        }
    }

    checkEngProfRequire(){
        this.showRequiredEng = false;
        if((this.englishLanguageProficiency && this.englishLanguageProficiency === 'No') && this.hasSavedSection){
            this.showRequiredEng = true;
        }
    }

    checkQualifications(){
        var isNotFound = true;
        if(this.qualListDraft && this.qualListDraft.length > 0){
            isNotFound = false;
        }
        if(this.qualListHistorical && this.qualListHistorical.length > 0){
            isNotFound = false;
        }
        this.noQualificationFound = isNotFound;
    }

    showHideStudyType(){
        this.isAbroadType = (this.studyType == 'Study Abroad' || this.studyType == 'Exchange');
        this.isNotAbroadType = !this.isAbroadType;
    }

    showHideQualType(qualRecTypeName){
        if(qualRecTypeName){
            switch (qualRecTypeName){
                case 'Tertiary Education/Post Secondary':
                    this.terEducQualType = true;
                    this.secEducQualType = false;
                    this.engTestQualType = false;
                    this.otherQualType = false;
                    break;
                case 'Secondary Education':
                    this.terEducQualType = false;
                    this.secEducQualType = true;
                    this.engTestQualType = false;
                    this.otherQualType = false;
                    break;
                case 'English Test':
                    this.terEducQualType = false;
                    this.secEducQualType = false;
                    this.engTestQualType = true;
                    this.otherQualType = false;
                    break;
                case 'Other Qualification':
                    this.terEducQualType = false;
                    this.secEducQualType = false;
                    this.engTestQualType = false;
                    this.otherQualType = true;
                    break;
                default:
                    break;

            }
        }
    }

    showHideSecondaryCountry(){
        var countryName = this.qualSecondaryCountry;
        if(countryName){
            switch (countryName){
                case 'China (excludes SARs and Taiwan)':
                    this.isAustralia = false;
                    this.isChinaOrIndia = true;
                    break;
                case 'India':
                    this.isAustralia = false;
                    this.isChinaOrIndia = true;
                    break;
                case 'Australia':
                    this.isAustralia = true;
                    this.isChinaOrIndia = false;
                    break;
                default:
                    this.isAustralia = false;
                    this.isChinaOrIndia = false;
                    break;

            }
        }
    }
    
    showEngTestScore(qualEngTestName){
        if(qualEngTestName){
            this.showinputQualEngGPAResult = false;
            if(qualEngTestName == 'IELTS (International English Language Testing Service)' || qualEngTestName == 'Paper based TOEFL (Test of English as a Foreign Language)' || qualEngTestName == 'Cambridge Linguaskill'){
                this.showinputQualEngGPAResult = true;
            }

            this.showinputQualEngFourScores = false;
            if(qualEngTestName !='Paper based TOEFL (Test of English as a Foreign Language)' && qualEngTestName != 'Monash English Language Placement test - MUELC only' && qualEngTestName != 'Cambridge Linguaskill'){
                this.showinputQualEngFourScores = true;
            }
        }
    }

    populateSearchDropdowns(){
        // prepopulate the search dropdown
        var cmpSearchTertiary = this.FindElement('searchTertiaryAwardingBody');
        if(cmpSearchTertiary){
            cmpSearchTertiary.prePopulate(); 
        }
        
        // prepopulate the search dropdown
        var cmpSearchSecondary = this.FindElement('searchSecondarySchool');
        if(cmpSearchSecondary){
            cmpSearchSecondary.prePopulate();
        }

        var cmpSearchQualificationAU = this.FindElement('searchSecondaryAusQualification');
        if(cmpSearchQualificationAU){
            cmpSearchQualificationAU.prePopulate();
        }
        
        var cmpSearchQualification = this.FindElement('searchSecondaryIntlQualification');
        if(cmpSearchQualification){
            cmpSearchQualification.prePopulate();
        }   
    }
}