import {api, LightningElement, track, wire} from "lwc";
import getCurrentUserAndQualifications from "@salesforce/apex/appAddQualificationCC.getCurrentUserAndQualifications";
import getQualificationRecordTypeOptions
    from "@salesforce/apex/appAddQualificationCC.getQualificationRecordTypeOptions";
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
import handleValidation from "@salesforce/apex/EnglishTestApiService.handleValidation";
import getEnglishProficiencyPicklistValues
    from '@salesforce/apex/appAddQualificationCC.getEnglishProficiencyPicklistValues';
import getRecordTypeIdForEnglishTest from '@salesforce/apex/appAddQualificationCC.getRecordTypeIdForEnglishTest';
import getLanguageOfInstruction from '@salesforce/apex/appAddQualificationCC.getLanguageOfInstruction';

import App_DeleteConfirmation from '@salesforce/label/c.App_DeleteConfirmation';
import App_DeleteQualificationLabel from '@salesforce/label/c.App_DeleteQualificationLabel';
import App_EnglishTestDetails_1 from '@salesforce/label/c.App_EnglishTestDetails_1';
import App_TertiaryEducationDetails from '@salesforce/label/c.App_TertiaryEducationDetails';
import App_TertiaryEducationDetails_2 from '@salesforce/label/c.App_TertiaryEducationDetails_2';
import App_InstructedInEnglish from '@salesforce/label/c.App_InstructedInEnglish';

// English Test Custom Labels
import myAppEnglishTestWillCompleteNotes from '@salesforce/label/c.myAppEnglishTestWillCompleteNotes';
import myAppEnglishTestVerificationSuccessMessage from '@salesforce/label/c.myAppEnglishTestVerificationSuccessMessage';
import myAppEnglishTestVerificationFailMessage from '@salesforce/label/c.myAppEnglishTestVerificationFailMessage';
import myAppEnglishTestVerifyHelpText from '@salesforce/label/c.myAppEnglishTestVerifyHelpText';
import myAppEnglishTestMonashProgramConsideration from '@salesforce/label/c.myAppEnglishTestMonashProgramConsideration';
import myAppEnglishTestAddNewEnglishTest from '@salesforce/label/c.myAppEnglishTestAddNewEnglishTest';
import myAppEnglishTestSatisfyEnglishRequirement from '@salesforce/label/c.myAppEnglishTestSatisfyEnglishRequirement';
import myAppEnglishTestEnglishMeasure from '@salesforce/label/c.myAppEnglishTestEnglishMeasure';
import myAppEnglishTestEnglishProficiencyHeader from '@salesforce/label/c.myAppEnglishTestEnglishProficiencyHeader';
import myAppEnglishTestSixYearSchooling from '@salesforce/label/c.myAppEnglishTestSixYearSchooling';
import myAppEnglishTestCreditText from '@salesforce/label/c.myAppEnglishTestCreditText';
import myAppEnglishTestCreditQuestion from '@salesforce/label/c.myAppEnglishTestCreditQuestion';

export default class myAppAddQualificationNew extends LightningElement{
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
    @api editingEnglishDraft = false;
    @api contactQualification;

    // English Verification

    // Filtered list for all qualification except 'English Test' records
    get filteredQualListHistorical() {
        if (!this.qualListHistorical || this.qualListHistorical.length === 0) {
            return []; // Return an empty array if undefined, null, or empty
        }
        // Filter the list to exclude records with recordTypeLabel "English Test"
        return this.qualListHistorical.filter(
            (qualRec) => qualRec.recordTypeLabel !== 'English Test'
        );
    }
    // Filtered list for all qualification except 'English Test' records
    get filteredQualListDraft() {
        if (!this.qualListDraft || this.qualListDraft.length === 0) {
            return []; // Return an empty array if undefined or empty
        }
        return this.qualListDraft.filter(
            (qualRec) => qualRec.recordTypeLabel !== 'English Test'
        );
    }

    // Getter for filtered English Test records
    get filteredEngQualListDraft() {
        if (!this.qualListDraft || this.qualListDraft.length === 0) {
            return []; // Return an empty array if undefined, null, or empty
        }
        return this.qualListDraft
            .filter((qualRec) => qualRec.recordTypeLabel === 'English Test')
            .map((qualRec) => {
                // Determine and update Verification_Status__c based on the conditions
                let updatedStatus;
                switch (qualRec.Verification_Status__c) {
                    case 'Unverified':
                        updatedStatus = 'Unknown';
                        break;
                    case 'Score Verified':
                    case 'Verified':
                        updatedStatus = 'Score Verified';
                        break;
                    case 'Unknown':
                        updatedStatus = 'Unknown';
                        break;
                    default:
                        updatedStatus = 'Unknown'; //set other values to Unknown
                }

                // Return the updated record
                return {
                    ...qualRec,
                    Verification_Status__c: updatedStatus, // Update the Verification_Status__c
                    variant: qualRec.variant || 'border'  // Default variant
                };
            });
    }

    // Filtered list for 'English Test' records
    get filteredEngQualListHistorical() {
        if (!this.qualListHistorical || this.qualListHistorical.length === 0) {
            return []; // Return an empty array if undefined or empty
        }
        return this.qualListHistorical
            .filter((qualRec) => qualRec.recordTypeLabel === 'English Test')
            .map((qualRec) => {
                // Update Verification_Status__c based on the conditions
                let updatedStatus;
                switch (qualRec.Verification_Status__c) {
                    case 'Unverified':
                        updatedStatus = 'Unknown';
                        break;
                    case 'Score Verified':
                    case 'Verified':
                        updatedStatus = 'Score Verified';
                        break;
                    case 'Unknown':
                        updatedStatus = 'Unknown';
                        break;
                    default:
                        updatedStatus  = 'Unknown'; //set other values to Unknown
                }

                // Return updated record
                return {
                    ...qualRec,
                    Verification_Status__c: updatedStatus // Update Verification_Status__c
                };
            });
    }

    get verifyButtonDynamicClass() {
        return this.verifyDisabled ? 'primaryButtonDisable slds-m-right_medium' : 'primaryButton slds-m-right_medium';
    }

    get shouldShowTemplate() {
        return this.showVerifyButton ||
            this.showAddTestDetailButton ||
            this.showAddTestDetailButtonAfterFailedVerification ||
            this.showDateExpected ||
            this.showCancelEditButton;
    }


    @track englishOptions;

    @wire(getEnglishProficiencyPicklistValues)
    wiredPicklistValues({ data, error }) {
        if (data) {
            // Parse the picklist data (label and value)
            this.englishOptions = data
                .filter(({ value }) => ['TEST-DONE', 'TEST-TODO', 'NO-TEST'].includes(value))
                .map(({ label, value }) => ({ label, value }));
        } else if (error) {
            console.error('Error fetching picklist values: ', error);
            this.englishOptions = [];
        }
    }

    @wire(getRecordTypeIdForEnglishTest)
    wiredRecordTypeId({ error, data }) {
        if (data) {
            this.englishTypeRecordTypeId = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.recordTypeId = undefined;
        }
    }

    @wire(getLanguageOfInstruction)
    wiredLanguageOfInstruction({ error, data }) {
        if (data) {
            this.languageOfInstruction = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.languageOfInstruction = undefined;
        }
    }

    @track testReportForm = {
        TestReportNumber: '',
        Provider: '',
        TestType: '',
        DOB: '',
        FirstName: '',
        LastName: '',
        PreviousFirstName: '',
        PreviousLastName: '',
        DateCompleted: ''
    };

    /*
    Current state of the component
    START = show add button and list
    SELECT_TYPE = show qualification type drop down
    FORM_DETAILS = form for ADDING/EDITING qualification
    SAVING = saving details
    */

    // Tracks the selected option
    @track selectedEnglishRequirement = '';
    @track selectedEnglishRequirementLabel = '';
    @track englishLanguageProficiency;
    @track englishLanguageConsideration = false;
    @track noEnglishProficiencyFound = false;
    @track showIeltsForm = false;
    @track showEnglishTypeOption = false;
    @track showEnglishProgramConsideration = false;
    @track showEnglishTestScores = false;
    @track showEnglishProficiencySection = true;
    @track showEnglishRequirementSection = true;
    @track showEnglishVerificationForm = false;
    @track addNewEnglishProficiency = 'No';
    @track showAddNewEnglishProficiency = false;
    @track showTestReportNumber = false;
    @track showVerifyButton = false;
    @track showAddTestDetailButtonAfterFailedVerification = false;
    @track showAddTestDetailButton = false;
    @track showDateCompleted = false;
    @track showDateExpected = false;
    @track showEnglishTestOverallScore = false;
    @track errorMsgExpectedDate = false;
    @track errorMsgCompletedDate = false;
    @track testReportNumber='';
    // @track englishTestPhotoFlag= false; TODO for Pearson
    @track previousFirstName='';
    @track previousLastName='';
    @track birthDate='';
    @track firstName='';
    @track lastName='';
    @track applicant_Id='';
    @track englishTestProvider='';
    @track validationResponse;
    @track validationResultMessage;
    @track validationResultStatus;
    @track showValidationResultSuccess;
    @track showValidationResultFail;
    @track verifyDisabled = true;
    @track englishTypeRecordTypeId;
    @track languageOfInstruction;
    @track selectedEnglishTypeId;
    @track showEnglishTestQualifications = false;
    @track disableEnglishLanguageRequirements = false;
    @track disableDateInput = false;
    @track disableScoreInput = false;
    @track disableTestReportFormInput = false;
    @track addTestButtonLabel = 'Add Test Detail';
    @track showCancelEditButton= false;
    @track showSaveButton= false;
    @track cancelCloseButtonLabel= 'Cancel';
    @track isNewQualification = true;
    @track editButtonVariant = 'border';
    @track successfulVerificationMessage = '';
    @track unsuccessfulVerificationMessage = '';
    @track userSelectedEnglishRequirement = false;
    @track englishWillCompleteNotes = myAppEnglishTestWillCompleteNotes;
    @track monashEnglishProgramConsideration = myAppEnglishTestMonashProgramConsideration;
    @track satisfyEnglishRequirement = myAppEnglishTestSatisfyEnglishRequirement;
    @track addNewEnglishTest = myAppEnglishTestAddNewEnglishTest;
    @track verificationSuccessMessage = myAppEnglishTestVerificationSuccessMessage;
    @track verificationFailMessage = myAppEnglishTestVerificationFailMessage;
    @track testReportNumberLabel = 'Test Report Form Number';
    @track englishTestVerifyHelpText = '';

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
    @track currentPreviousNotification;

    //global spinner
    @track showSpinner = false;
    @track saveErrors = [];
    @track showErrors = false;

    //setting this to true allows the users to delete on the list
    @track allowDelete = true;
    @track qualIdToDelete;
    @track showConfirmDelete = false;

    @track showViewOnlyPopup = false;

    // yes or no options
    @track yesNoOptions = [{value:'Yes',label:'Yes'},{value:'No',label:'No'}];
    @track trueFalseOptions = [{value:'true',label:'Yes'},{value:'false',label:'No'}];

    @track hasSavedSection = false;

    //Show hide controls
    @track showMain = false;
    @track showSave = false;
    @track showCancel = false;
    @track noQualificationFound = false;
    @track isNotAbroadType = false;
    @track isAbroadType = false;
    @track showQualificationTypeSelect = false;
    @track showNewQualification = false;
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
        App_InstructedInEnglish,
        myAppEnglishTestEnglishMeasure,
        myAppEnglishTestEnglishProficiencyHeader,
        myAppEnglishTestSixYearSchooling,
        myAppEnglishTestCreditText,
        myAppEnglishTestCreditQuestion,
        myAppEnglishTestVerifyHelpText
    };

    connectedCallback() {
        this.DEBUGGING = true;

        this.saveErrors = [];

        this.showMain = true;
        this.noQualificationFound = true;

        var msInADay = 24 * 60 * 60 * 1000;

        var dateToday = new Date();
        //var dateOffset = new Date(dateToday.getTime() - (msInADay));
        this.EARLIEST_EXPECTED_DATE = this.formatDateString(dateToday);

        // today + 100 days
        var dateMax = new Date(dateToday.getTime() + (msInADay));
        this.LATEST_COMPLETED_DATE = this.formatDateString(dateMax);

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
            var recordTypes = response.filter((element) =>
                this.courseWorkRecordTypes.includes(element.label) && element.label !== 'English Test'
            );
            this.qualRecordTypes = this.processPicklistOptions(recordTypes, true);
            this.qualRecordTypeMap = this.storeValueLabelMap(this.qualRecordTypes);
            this.itemFinishedLoading('getQualificationRecordTypeOptions');
        });

        // load English Test (Admission Tests in Callista) options
        this.incrementItemsToLoadCounter('getAdmissionTestOptions');
        getAdmissionTestOptions().then(response => {
            this.englishTestOptions = this.processPicklistOptions(response, false);
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
        if(this.loadDraftSearchWDropdown === true){
            this.populateSearchDropdowns();
        }
        this.loadDraftSearchWDropdown = false;
    }

    @api
    validateFields(callback)  {
        // start loading
        this.showSpinner = true;

        let result = {
            hasError: false,
            errorMessage: ''
        };

        let englishLanguageProficiency = this.englishLanguageProficiency;
        let missingRequiredError = 'Please ensure that the following are completed:<br/>';
        let hasMissingRequiredField = false;

        // english language proficiency
        if (!englishLanguageProficiency) {
            hasMissingRequiredField = true;
            missingRequiredError += '<span style="padding-left: 1em;">• Six (6) years of schooling question</span><br/>';

            // Scroll to top
            const element = this.FindElement("englishLanguageProficiency");
            if (element) {
                element.scrollIntoView({ behavior: "smooth", block: "center" });
            }
        }

        // Validate English Test and Language Requirements
        if (this.selectedEnglishRequirement !== 'NO-TEST' && this.userSelectedEnglishRequirement &&
            (!this.englishLanguageConsideration && !this.noEnglishProficiencyFound)) {
            hasMissingRequiredField = true;
            missingRequiredError += '<span style="padding-left: 1em;">• Monash English program consideration</span><br/>';
        }

        if(!this.userSelectedEnglishRequirement && !this.englishLanguageConsideration && !this.noEnglishProficiencyFound){
            hasMissingRequiredField = true;
            missingRequiredError += '<span style="padding-left: 1em;">• Monash English program consideration</span><br/>';
        }

        if (this.selectedEnglishRequirement === 'TEST-TODO' && this.userSelectedEnglishRequirement) {
            const { qualEnglishTestId: englishTestType, qualEnglishTestDateExpected: dateExpected } = this;
            if (!englishTestType || !dateExpected) {
                hasMissingRequiredField = true;
                if (!englishTestType) {
                    missingRequiredError += '<span style="padding-left: 1em;">• English Test Type</span><br/>';
                }
                if (!dateExpected) {
                    missingRequiredError += '<span style="padding-left: 1em;">• Date expected to be completed</span><br/>';
                }
            }
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
        if (!hasMissingRequiredField) {
            if(this.selectedEnglishRequirement){
                // Construct application record
                const applicationRecord = {
                    Id: this.applicationId,
                    English_Language_Proficiency__c: this.englishLanguageProficiency,
                    Partner_Name__c: this.institutionName,
                    English_Proficiency_Requirement__c: this.selectedEnglishRequirement,
                    Credit_Intention__c: this.creditIntention
                };

                updateApplication({ application: JSON.stringify(applicationRecord) })
                    .then(response => {
                        if (response.STATUS === 'SUCCESS') {
                            result = { hasError: false, errorMessage: "" };
                        }
                    }).finally(() => {
                    // const createContactQualification= this.selectedEnglishRequirement && !['TEST-DONE'].includes(this.selectedEnglishRequirement);
                    // if(createContactQualification){
                    //     this.saveCurrentQualification(); When Save & Continue is clicked
                    // }
                });
            }
        } else {
            result = { hasError: hasMissingRequiredField, errorMessage: missingRequiredError };
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
        this.clearComponentAttributes();
        this.setStateTo('START');
    }

    onClickDelete(event) {
        var buttonName = event.currentTarget.name;
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

    onClickEditEnglishTest(event) {
        const clickedRecordId = event.target.dataset.id; // Get the Id of the clicked button

        // Update the qualListDraft array so only the clicked button is 'brand'
        this.qualListDraft = this.qualListDraft.map((qualRec) => {
            if (qualRec.Id === clickedRecordId) {
                // Set clicked button's variant to 'brand'
                qualRec.variant = 'brand';
            } else {
                // Reset all other buttons to 'border'
                qualRec.variant = 'border';
            }
            return qualRec; // Return updated record
        });


        this.setStateTo('CANCEL_EDIT_ENGLISH_FORM');

        var qualificationId = event.currentTarget.name;

        this.addTestButtonLabel = 'Save'
        this.editingEnglishDraft = true;
        let objCQ  = {};
        objCQ = this.qualListDraft.find(conQual => conQual.Id === qualificationId);
        let levelOfProficiency =  objCQ.isTestCompleted__c ? 'TEST-DONE' : 'TEST-TODO';
        let testType = objCQ.Qualification__r.Qualification_Name__c;
        this.testReportNumberLabel = testType.includes('TOEFL') ? 'Appointment Number' : 'Test Report Form Number';

        // check first the level of proficiency
        switch (levelOfProficiency) {
            case 'TEST-DONE':
                // check the qualification type
                const tests = ['IELTS', 'TOEFL'];
                const isToShowResults = tests.some(test => testType.includes(test));

                if(isToShowResults){
                    //check the verification status
                    if (objCQ.Source_Channel__c !== 'Manual' && objCQ.Verification_Status__c === 'Score Verified') {
                        this.setStateTo('EDIT_ENGLISH_FORM_VERIFIED');
                    } else{
                        this.setStateTo('EDIT_ENGLISH_FORM_UNVERIFIED');
                    }
                } else{
                    this.setStateTo('EDIT_ENGLISH_FORM_UNVERIFIED');
                }

                break;

            case 'TEST-TODO':
                this.setStateTo('EDIT_TEST_TODO');
                break

            default:
                this.setStateTo('EDIT_LOI');
                this.showEnglishTestScores = false;
                break;
        }

        // populate the form
        this.loadDraftQualificationIntoForm(qualificationId);
    }

    onclickCancelEditButton() {
        // Reset all button variants to 'border'
        this.qualListDraft = this.qualListDraft.map((qualRec) => {
            qualRec.variant = 'border'; // Reset to default variant
            return qualRec;
        });

        // Hide the form or perform other Cancel-related actions
        this.setStateTo('CANCEL_EDIT_ENGLISH_FORM');
    }

    onClickAddTestOnFailedVerification(){
        this.showAddTestDetailButton = true;
        this.showAddTestDetailButtonAfterFailedVerification = false;
        this.showTestReportNumber = false;
        this.showEnglishTestScores = true;
        this.showEnglishTestOverallScore = true;
        this.showVerifyButton = false;
        this.showValidationResultFail = false;
    }

    onSelectQualificationType(event) {
        // clear to-save variable
        this.contactQualification = null;

        // update the qualification readable name
        this.selectedQualRecordTypeId = event.detail.value;
        var qualTypeId = this.selectedQualRecordTypeId;
        var qualRecordTypeMap = this.qualRecordTypeMap;
        this.selectedQualTypeName = qualRecordTypeMap[qualTypeId];
        this.showHideQualType(this.selectedQualTypeName);

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
        if(countryName === 'Australia')
        {
            this.qualTertiaryEnglishOnly = true;
        }
    }

    getcountryname(selectedId){
        getCountryNameById({
            'countryId': selectedId,
            'format': 'Country__c'
        }).then(response => {
            //set qualTertiaryCountry with the response
            this.qualTertiaryCountry = response;
        });
    }

    onSelectSecondaryCountry(event) {
        // selected the country for Secondary
        // set the name attribute via the map
        this.qualSecondaryCountryId = event.detail.value;
        var countryMap = this.countryMap;
        var selectedId = this.qualSecondaryCountryId;
        var countryName = countryMap[selectedId];

        if(countryName !== this.qualSecondaryCountry){
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

        if(countryName === 'Australia')
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
        this.qualEnglishTestId = event.detail.value;
        const selectedId = this.qualEnglishTestId;
        this.qualEnglishTestName = this.qualEnglishTestTypeMap[selectedId];
        this.selectedEnglishTypeId = selectedId;

        if (this.isNewQualification) {
            const isTestRequirementValid = this.selectedEnglishRequirement !== "TEST-TODO";
            this.showSaveButton = !isTestRequirementValid;

            if (isTestRequirementValid) {
                const tests = ['IELTS', 'TOEFL'];
                const isToVerify = tests.some(test => this.qualEnglishTestName.includes(test));

                Object.assign(this, {
                    showTestReportNumber: isToVerify,
                    showEnglishTestScores: !isToVerify,
                    showEnglishTestOverallScore: !isToVerify,
                    showVerifyButton: isToVerify,
                    showAddTestDetailButton: !isToVerify,
                    qualEnglishTestId: null,
                    testReportNumber: null,
                    showValidationResultSuccess: false,
                    showValidationResultFail: false,
                    addNewEnglishProficiency: 'No',
                    showAddTestDetailButtonAfterFailedVerification: false,
                    qualEnglishTestScoreReading: null,
                    qualEnglishTestScoreListening: null,
                    qualEnglishTestScoreWriting: null,
                    qualEnglishTestScoreSpeaking: null,
                    qualAdmissionsGPAResult: null,
                    qualEnglishTestDateCompleted: null,
                    qualEnglishTestDateExpected: null,
                    qualEnglishComments: null
                });
            }
        }

        Object.assign(this, {
            showEnglishProgramConsideration: true,
            showCancelEditButton: true
        });

        this.setTestType(this.qualEnglishTestName);

        this.testReportNumberLabel = this.englishTestProvider === 'TOEFL' ? 'Appointment Number' : 'Test Report Form Number';

        this.englishTestVerifyHelpText = this.label.myAppEnglishTestVerifyHelpText + ' ' +   this.englishTestProvider + ' account via the booking portal.';
    }

    onChangeEnglishTestDateExpected(event) {
        const dateSelected = event.target.value;
        this.qualEnglishTestDateExpected = dateSelected;
        this.toggleVerifyTestButton(false);
        this.errorMsgExpectedDate = this.isDatePast(dateSelected);
    }

    onChangeEnglishTestDateCompleted(event) {
        const dateSelected = event.target.value;
        this.qualEnglishTestDateCompleted = dateSelected;
        const todayFormattedDate = this.formatDateString(new Date());

        this.toggleVerifyTestButton(true);
        // Check if the date is today or earlier
        this.errorMsgCompletedDate = dateSelected > todayFormattedDate;
    }

    toggleVerifyTestButton(isCompleted){
        if(isCompleted){
            this.verifyDisabled = this.qualEnglishTestDateCompleted === null && this.testReportNumber === null;
        } else{
            this.verifyDisabled = this.qualEnglishTestDateExpected === null && this.testReportNumber === null;
        }
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
        const dateSelected = event.target.value;
        this.qualSecondaryDateExpected = dateSelected;
        this.errorMsgSecondaryDateExpected = this.isDatePast(dateSelected);
    }

    onSelectEnglishLanguageReq(event) {
        this.selectedEnglishRequirementLabel = this.getLabelByValue(event.detail.value);
        this.selectedEnglishRequirement = event.detail.value;
        this.userSelectedEnglishRequirement = true;
        // Call the method to handle form visibility
        this.showHideEnglishTypeForm(this.selectedEnglishRequirement);
        this.clearEnglishForm();
    }

    getLabelByValue(value) {
        const option = this.englishOptions.find(option => option.value === value);
        return option.label; // Return label if found, otherwise null
    }

    getValueByLabel(label) {
        const option = this.englishOptions.find(option => option.label === label );
        return option?.value || null; // Return value if found, otherwise null
    }

    getEnglishTypeValueByLabel(label) {
        const option = this.englishTestOptions.find(option => option.label === label );
        return option?.value || null; // Return value if found, otherwise null
    }

    showHideEnglishTypeForm(EnglishTypeName) {
        // Use a switch-case structure to handle different scenarios
        switch (EnglishTypeName) {
            case 'TEST-DONE':
                Object.assign(this, {
                    showEnglishVerificationForm: true,
                    showEnglishTypeOption: true,
                    showEnglishTestScores: false,
                    showAddTestDetailButton: false,
                    showVerifyButton: false,
                    showDateExpected: false,
                    showSaveButton: false,
                    showDateCompleted: true,
                    showTestReportNumber: false,
                    showEnglishTestOverallScore: false,
                    qualEnglishCompleted: true,
                    qualEnglishTestId: null,
                    showCancelEditButton: true
                });
                break;
            case 'TEST-TODO':
                Object.assign(this, {
                    showEnglishTypeOption: true,
                    showAddTestDetailButton: false,
                    showEnglishTestScores: false,
                    showTestReportNumber: false,
                    showEnglishTestOverallScore: false,
                    showVerifyButton: false,
                    showDateExpected: true,
                    showDateCompleted: false,
                    qualEnglishCompleted: false,
                    qualEnglishTestId: null,
                    showCancelEditButton: true
                });
                break;
            case 'NO-TEST':
                Object.assign(this, {
                    showEnglishTypeOption: false,
                    showAddTestDetailButton: false,
                    showEnglishTestScores: false,
                    showTestReportNumber: false,
                    showEnglishTestOverallScore: false,
                    showVerifyButton: false,
                    showDateExpected: false,
                    showDateCompleted: false,
                    qualEnglishCompleted: false,
                    qualEnglishTestId: null,
                    showCancelEditButton: false,
                    showEnglishProgramConsideration: false
                });
                break;
            default:
                Object.assign(this, {
                    showEnglishTypeOption: false,
                    showEnglishTestScores: false,
                    showAddTestDetailButton: false,
                    showTestReportNumber: false,
                    showEnglishTestOverallScore: false,
                    showVerifyButton: false,
                    showDateExpected: false,
                    showSaveButton: false,
                    showDateCompleted: false,
                    qualEnglishTestId: null,
                    showCancelEditButton: false,
                    showEnglishProgramConsideration: false
                });
                break;
        }
    }

    onChangeAddNewEnglishProficiency(event) {
        this.addNewEnglishProficiency = event.detail.value;
        // Call the method to handle form visibility
        this.showHideEnglishProficiencySection(this.addNewEnglishProficiency);
        this.showEnglishTestQualifications = false;
        this.contactQualification = null;
        // this.showEnglishProgramConsideration = false;
    }

    showHideEnglishProficiencySection(SelectedOption) {
        switch (SelectedOption) {
            case 'Yes':
                this.showEnglishProficiencySection = true;
                this.showEnglishRequirementSection = true;
                this.showAddNewEnglishProficiency = false
                this.showCancelEditButton = true;
                this.selectedEnglishRequirement = '';
                this.userSelectedEnglishRequirement = false;
                this.qualEnglishTestId = null;
                break;
            case 'No':
                this.showEnglishProficiencySection = false;
                this.showEnglishRequirementSection = false;
                this.showAddNewEnglishProficiency = true
                this.showCancelEditButton = false;
                break;
            default:
        }
    }

    onSearchSelectSecondaryQualification(event) {
        var objSelected = event.detail.sObject;
        this.qualSecondaryType = objSelected;
        this.qualSecondaryTypeId = objSelected.Id;
    }

    onSearchSelectSecondarySchool(event) {
        this.objSecondarySchool = event.detail.sObject;
    }

    onSearchSelectTertiaryAwardingBody(event) {
        this.objTertiaryAwardingBody = event.detail.sObject;
    }

    onClickCloseAlert() {
        this.clearSaveErrors();
    }

    onChangeCreditIntention(event) {
        this.creditIntention = event.detail.value;
        // update the application credit intention state
        this.appSaveCreditIntention();
    }

    onChangeEnglishLanguageProficiency(event) {
        this.englishLanguageProficiency = event.detail.value;
        // update the application's english language proficiency field

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
                if(state === 'SUCCESS'){
                    var objResponse = response;
                }
                this.itemFinishedLoading('updateEnglishLanguageProficiency');
            });
        // end saveApplication();
    }

    onChangeEnglishLanguageConsideration(event) {
        this.englishLanguageConsideration = event.detail.value;
        const applicationRecord = {
            Id: this.applicationId,
            English_Program_Consideration__c: this.englishLanguageConsideration,
        };

        this.incrementItemsToLoadCounter('updateEnglishLanguageConsideration');

        updateApplication({ application: JSON.stringify(applicationRecord) })
            .then(response => {
                if (response.STATUS === 'SUCCESS') {
                }
            })
            .finally(() => {
                this.itemFinishedLoading('updateEnglishLanguageConsideration');
            });
    }

    onToggleAdmissionsCompleted(event) {
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
                // Reset to start state if needed
                if (currState !== 'START') {
                    this.clearComponentAttributes(); // Clear everything
                    this.loadDraftQualifications();  // Reload attached qualifications
                }

                Object.assign(this, {
                    showConfirmDelete: false,
                    showMain: true,
                    showSave: false,
                    showCancel: false,
                    showQualificationTypeSelect: false,
                    showNewQualification: false,
                    selectedEnglishRequirement: '',
                    userSelectedEnglishRequirement:false
                });
                break;

            case 'FORM_DETAILS':
                this.clearSaveErrors();
                Object.assign(this, {
                    showMain: true,
                    showSave: true,
                    showCancel: true,
                    showQualificationTypeSelect: true,
                    showNewQualification: true,
                    selectedEnglishRequirement: '',
                    userSelectedEnglishRequirement:false
                });
                break;

            case 'DELETING':
                Object.assign(this, {
                    showMain: false,
                    showSave: false,
                    showCancel: false,
                    showQualificationTypeSelect: false,
                    showNewQualification: false,
                    selectedEnglishRequirement: '',
                    userSelectedEnglishRequirement:false,
                    disableEnglishLanguageRequirements: false
                });
                break;

            case 'SELECT_TYPE':
                Object.assign(this, {
                    showMain: true,
                    showSave: false,
                    showCancel: true,
                    showQualificationTypeSelect: true,
                    showNewQualification: false,
                    selectedEnglishRequirement: '',
                    userSelectedEnglishRequirement:false
                });
                break;

            case 'EDIT_ENGLISH_FORM_VERIFIED':
                Object.assign(this, {
                    showEnglishRequirementSection: true,
                    showEnglishProficiencySection: true,
                    showEnglishTypeOption: true,
                    showEnglishProgramConsideration: true,
                    showDateCompleted: true,
                    showEnglishTestScores: true,
                    disableScoreInput: true,
                    showAddTestDetailButton: false,
                    disableEnglishLanguageRequirements: true,
                    disableTestReportFormInput: true,
                    disableDateInput: true,
                    showAddNewEnglishProficiency: false,
                    showCancelEditButton: true,
                    showVerifyButton: false,
                    showDateExpected: false,
                    showSaveButton: false,
                    showTestReportNumber: true,
                    showEnglishTestOverallScore: true
                });
                break;

            case 'EDIT_ENGLISH_FORM_UNVERIFIED':
                Object.assign(this, {
                    showTestReportNumber: false,
                    showEnglishTestOverallScore: true,
                    showEnglishRequirementSection: true,
                    showEnglishProficiencySection: true,
                    showVerifyButton: false,
                    showEnglishTypeOption: true,
                    showEnglishProgramConsideration: true,
                    showDateCompleted: true,
                    showEnglishTestScores: true,
                    showAddTestDetailButton: true,
                    disableEnglishLanguageRequirements: true,
                    showAddNewEnglishProficiency: false,
                    showCancelEditButton: true,
                    disableDateInput: false,
                    disableTestReportFormInput: false,
                    showDateExpected : false,
                    showSaveButton: false
                });
                break;

            case 'EDIT_LOI':
                Object.assign(this, {
                    showTestReportNumber: false,
                    showEnglishRequirementSection: true,
                    showEnglishProficiencySection: true,
                    disableEnglishLanguageRequirements: true,
                    showVerifyButton: false,
                    showEnglishTypeOption: false,
                    showEnglishProgramConsideration: false,
                    showDateCompleted: false,
                    showEnglishTestScores: false,
                    showAddTestDetailButton: false,
                    showAddNewEnglishProficiency: false,
                    showCancelEditButton: true,
                    showDateExpected: false,
                    showSaveButton: false,
                    showEnglishTestOverallScore: false
                });
                break;

            case 'EDIT_TEST_TODO':
                Object.assign(this, {
                    showTestReportNumber: false,
                    showEnglishRequirementSection: true,
                    showEnglishProficiencySection: true,
                    showVerifyButton: false,
                    showEnglishTypeOption: true,
                    showEnglishProgramConsideration: true,
                    showDateCompleted: false,
                    showEnglishTestScores: false,
                    showAddTestDetailButton: true,
                    showAddNewEnglishProficiency: false,
                    showCancelEditButton: true,
                    showDateExpected : true,
                    showSaveButton: false,
                    disableEnglishLanguageRequirements : true,
                    showEnglishTestOverallScore: false
                });
                break;

            case 'CANCEL_EDIT_ENGLISH_FORM':
                if (this.cancelCloseButtonLabel !== 'Cancel') {
                    this.loadUserAndQualifications();
                    this.cancelCloseButtonLabel = 'Cancel';
                }

                const show = !this.noEnglishProficiencyFound;
                this.showAddNewEnglishProficiency = show;
                this.showEnglishProgramConsideration = show;

                this.showEnglishRequirementSection = this.noEnglishProficiencyFound;

                // Resetting visibility and state properties
                Object.assign(this, {
                    showEnglishProficiencySection: true,
                    showEnglishTypeOption: false,
                    showDateCompleted: false,
                    showDateExpected: false,
                    showEnglishTestScores: false,
                    showAddTestDetailButton: false,
                    disableEnglishLanguageRequirements: false,
                    disableDateInput: false,
                    disableTestReportFormInput: false,
                    showCancelEditButton: false,
                    addNewEnglishProficiency: 'No',
                    showEnglishTestQualifications: true,
                    selectedEnglishRequirement: '',
                    userSelectedEnglishRequirement:false,
                    showTestReportNumber: false,
                    testReportNumber: '',
                    showVerifyButton: false,
                    showSaveButton: false,
                    showAddTestDetailButtonAfterFailedVerification: false,
                    showValidationResultFail: false,
                    showValidationResultSuccess: false,
                    contactQualification: null,
                    addTestButtonLabel: 'Add Test Detail',
                    disableScoreInput:false,
                    showEnglishTestOverallScore: false
                });
                break;

            default:
                Object.assign(this, {
                    showMain: true,
                    showSave: false,
                    showCancel: false,
                    showQualificationTypeSelect: false,
                    showNewQualification: false
                });
                break;

        }
        this.state = sState;
    }

    clearEnglishForm() {
        Object.assign(this, {
            qualEnglishTestId: null,
            testReportNumber: null,
            showValidationResultSuccess: false,
            showValidationResultFail: false,
            verifyDisabled: true,
            addNewEnglishProficiency: 'No',
            showAddTestDetailButtonAfterFailedVerification: false,
            showEnglishTestOverallScore: false
        });
        this.clearScore();
    }

    clearScore() {
        Object.assign(this, {
            qualAdmissionsGPAResult: null,
            qualEnglishTestScoreReading: null,
            qualEnglishTestScoreListening: null,
            qualEnglishTestScoreWriting: null,
            qualEnglishTestScoreSpeaking: null,
            qualEnglishTestDateCompleted: null,
            qualEnglishTestDateExpected: null,
            qualEnglishComments: null
        });
    }

    incrementItemsToLoadCounter(calledBy) {
        var iCount = this.itemsToLoad;
        iCount++;
        this.itemsToLoad = iCount;
        if(iCount > 0)
        {
            this.showSpinner = true;
        }
    }

    itemFinishedLoading(calledBy) {
        var iCount = this.itemsToLoad;
        iCount --;
        this.itemsToLoad = iCount;

        if(iCount === 0)
        {
            this.showSpinner = false;
        }
    }

    loadUserAndQualifications() {
        var appId = this.parseApplicationIdFromUrl();
        if(!appId){
            appId = this.applicationId;
        }
        else{
            //redirect to the new app form url
            window.location.href = '/admissions/s/application/' + appId;
        }
        if(!appId)
        {
            console.error('appAddQualificationHelper::loadUserAndQualification:: no app Id');
            return;
        }
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

                // get the static ones
                var arrHistoricalQualifications = objResponse['historical_qualifications'];
                this.qualListHistorical = arrHistoricalQualifications;
                this.enrichQualification(this.qualListHistorical);
                this.checkQualifications();

                var listInstitutions = objResponse['draft_institutions'];
                this.institutionList = listInstitutions;

                // credit intention
                var application = objResponse.application;
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
                this.creditIntention = application.Credit_Intention__c === true ? 'true' : 'false';
                console.log('Credit Intention: ' + this.creditIntention);
                console.log('application.Credit_Intention__c: ' + application.Credit_Intention__c);

                // english language proficiency
                this.englishLanguageProficiency = application.English_Language_Proficiency__c;
                this.englishLanguageConsideration = application.English_Program_Consideration__c;
                this.selectedEnglishRequirement = application.English_Proficiency_Requirement__c;

                var applicationApplicant = objResponse.APPLICATION_CONTACT;
                this.applicant_Id = applicationApplicant.Applicant__c;
                this.birthDate = objResponse?.APPLICANT_Birthdate ?? '';
                this.firstName = objResponse?.APPLICANT_FirstName ?? '';
                this.lastName = objResponse?.APPLICANT_LastName ?? '';
                this.previousFirstName = objResponse?.APPLICANT_PreviousFirstName ?? '';
                this.previousLastName = objResponse?.APPLICANT_PreviousLastName ?? '';

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

    processPicklistOptions(response, insertDefault){
        // Store the return response from server (List<Map<String, String>>)
        var arrResponse = response;

        // Add a default "-- Select --" option
        var arrOptions = [];
        if (insertDefault) {
            arrOptions.push({
                value: 'default', // Set a clear default value for the '-- Select --' option
                label: '-- Select --'
            });
        }

        // Iterate through response and add options to the picklist
        var iLen = arrResponse.length;
        for (var i = 0; i < iLen; ++i) {
            var mapOption = arrResponse[i];
            // Modify label if needed
            if (mapOption.label === 'Tertiary Education') {
                mapOption.label = mapOption.label + '/Post Secondary';
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

    setTestType(englishTypeName) {
        const testTypeMappings = {
            'IELTS': 'IELTS',
            'Pearson': 'PEARSON',
            'TOEFL': 'TOEFL',
        };

        for (const key in testTypeMappings) {
            if (englishTypeName.includes(key)) {
                this.englishTestProvider = testTypeMappings[key];
                return; // Exit early once a match is found
            }
        }
    }

    handleVerification(){
        this.saveErrors = [
            ...(this.testReportNumber === null ? [this.testReportNumberLabel] : []),
            ...(this.qualEnglishTestDateCompleted === null ? ['Date Completed'] : [])
        ];

        // check for errors
        if (this.saveErrors.length > 0) {
            this.showErrors = true;
        } else {
            // Reset validation/result states
            Object.assign(this, {
                showValidationResultSuccess: false,
                showValidationResultFail: false,
                showAddTestDetailButton: false,
                showAddTestDetailButtonAfterFailedVerification: false
            });

            // Prepare input data
            this.setTestType(this.qualEnglishTestName);

            const testReportForm = {
                Provider: this.englishTestProvider,
                TestType: this.qualEnglishTestName,
                TestReportNumber: this.testReportNumber = this.testReportNumber?.trim(),
                DOB: this.birthDate,
                FirstName: this.firstName,
                LastName: this.lastName,
                PreviousFirstName: this.previousFirstName,
                PreviousLastName: this.previousLastName,
                DateCompleted: this.qualEnglishTestDateCompleted
            };
            // Call the Apex method
            this.incrementItemsToLoadCounter('handleVerification');

            console.log('@@@ this.englishTestProvider:' + this.englishTestProvider);
            handleValidation({
                incomingTestReportForm: JSON.stringify(testReportForm),
                contactId: this.applicantId,
                applicationId:this.applicationId,
                qualification: this.selectedEnglishTypeId,
                isCompleted: this.qualEnglishCompleted,
                provider: this.englishTestProvider,
                englishRequirement: this.selectedEnglishRequirementLabel
            })
                .then((response) => {
                    Object.assign(this, {
                        showValidationResultSuccess: response.success,
                        showValidationResultFail: !response.success,
                        showAddTestDetailButtonAfterFailedVerification: !response.success,
                        verifyDisabled: !!response.success,
                        validationResultMessage: response.message,
                        validationResultStatus: response.success,
                    });

                    // call method to save the verified test result
                    if(response.success){
                        this.updateLevelOfEnglishProficiency(this.selectedEnglishRequirement);
                        Object.assign(this, {
                            cancelCloseButtonLabel: 'Close',
                            disableEnglishLanguageRequirements: true,
                            disableTestReportFormInput: true,
                            disableDateInput: true,
                            noEnglishProficiencyFound: false,
                            showVerifyButton: false,
                            showEnglishTestScores: true,
                            disableScoreInput: true,
                            showEnglishTestOverallScore:true,
                            qualAdmissionsGPAResult: response.overallScore,
                            qualEnglishTestScoreListening: response.listeningScore,
                            qualEnglishTestScoreReading: response.readingScore,
                            qualEnglishTestScoreWriting: response.writingScore,
                            qualEnglishTestScoreSpeaking: response.speakingScore
                        });
                    } else{
                        // Finalize loading and update state
                        this.setStateTo('FAIL'); // Adjust state based on success
                    }
                    this.itemFinishedLoading('handleVerification');
                })
                .catch((error) => {
                    console.error('Validation Error:', error);

                    // Finalize loading and set error state
                    this.itemFinishedLoading('handleVerification');
                    this.setStateTo('ERROR');
                });
        }
    }

    saveCurrentQualification() {
        // clear previous save errors
        this.saveErrors = [];

        // get the record type
        var recTypeId = this.selectedQualRecordTypeId;
        var isEnglishTest= false;
        // set the record type id of English Test
        if(this.selectedEnglishRequirement !== ''){
            recTypeId = this.englishTypeRecordTypeId;
            isEnglishTest = true;
        }

        // get the attributes relevant to this record type
        var objContactQualification = this.populateContactQualificationForSave(recTypeId);

        // check for errors
        var arrErrors = this.saveErrors;
        if (arrErrors.length > 0) {
            this.showErrors = true;
        }
        else{
            this.incrementItemsToLoadCounter('saveCurrentQualification');
            upsertQualificationToContact({
                'contactId': this.applicantId,
                'applicationId':this.applicationId,
                'contactQualification':objContactQualification
            }).then(response => {
                this.debugObject(response, 'UpsertQualification');
                if (response.message.includes( 'Success')) {
                    //store the return response from server (List<Map<String, String>>)
                    Object.assign(this, {
                        showEnglishTypeOption: false,
                        showDateCompleted: false,
                        showDateExpected: false,
                        showSaveButton: false,
                        showTestReportNumber: false,
                        showEnglishTestScores: false,
                        showVerifyButton: false,
                        showAddTestDetailButton: false,
                        disableEnglishLanguageRequirements : false,
                        addTestButtonLabel : 'Add Test Detail',
                        noEnglishProficiencyFound: false
                    });

                    if(isEnglishTest){
                        this.updateLevelOfEnglishProficiency(this.selectedEnglishRequirement);
                    }
                    
                    this.clearEnglishForm();
                    this.setStateTo('START');
                    this.loadUserAndQualifications();
                    this.itemFinishedLoading('saveCurrentQualification');
                } else if (response.message.includes('Error')) {
                    console.error('An error occurred during the upsert operation on Contact Qualification.');
                }
            });
        }
    }

    updateLevelOfEnglishProficiency(englishProficiency) {

        const applicationRecord = {
            Id: this.applicationId,
            English_Proficiency_Requirement__c: englishProficiency
        };

        this.incrementItemsToLoadCounter('updateLevelOfEnglishProficiency');
        this.debugObject(applicationRecord, 'applicationRecord');
        updateApplication({ application: JSON.stringify(applicationRecord) })
            .then(response => {
                if (response.STATUS === 'SUCCESS') {
                }
            })
            .finally(() => {
                this.itemFinishedLoading('updateLevelOfEnglishProficiency');
            });
    }

    populateContactQualificationForSave(recTypeId) {
        let objCQ = this.contactQualification || {};
        objCQ.RecordTypeId = objCQ.RecordTypeId || recTypeId;

        objCQ.Contact__c = this.applicantId;

        // Determine the record type name
        const recTypeMap = this.qualRecordTypeMap;
        let recTypeName = this.selectedEnglishRequirement !== '' ? 'English Test' : recTypeMap[recTypeId];
        // Handle based on record type name
        switch (recTypeName) {
            case 'Tertiary Education/Post Secondary':
                this.populateContactQualificationTertiarySave(objCQ);
                break;
            case 'Secondary Education':
                this.populateContactQualificationSecondarySave(objCQ);
                break;
            case 'English Test':
                const createLOIContactQualification= !['TEST-DONE','TEST-TODO'].includes(this.selectedEnglishRequirement);
                this.selectedEnglishRequirementLabel = this.getLabelByValue(this.selectedEnglishRequirement);
                if(createLOIContactQualification){
                    this.populateContactQualificationLOI(objCQ);
                } else{
                    this.setTestType(this.qualEnglishTestName);
                    this.populateContactQualificationEnglishSave(objCQ);
                }
                break;
            case 'Other Qualification':
                this.populateContactQualificationAdmissionsSave(objCQ);
                break;
            default:
                console.error(`appAddQualificationHelper:: record type "${recTypeName}" not found`);
        }

        this.debugObject(objCQ, 'populateContactQualificationForSave');

        // Update the page-level qualification
        this.contactQualification = objCQ;
        return objCQ;
    }

    isUnsafe(dataObject) {
        const XML_REGEX_PATTERN = /(<.[^(><.)]+>)/g;
        return XML_REGEX_PATTERN.test(JSON.stringify(dataObject));
    }

    captureInputs(event){
        if(event.target.name==='inputQualTertiaryName'){
            this.qualTertiaryName=event.target.value;
        }else if(event.target.name==='inputQualAwardingBodyOther'){
            this.qualTertiaryAwardingBodyOther=event.target.value;
        }else if(event.target.name==='inputQualTertiaryEnglishOnly'){
            this.qualTertiaryEnglishOnly=event.target.checked;
        }else if(event.target.name==='inputQualTertiaryFirstYearEnrolment'){
            this.qualTertiaryFirstYearEnrolled=event.target.value;
        }else if(event.target.name==='inputQualTertiaryLastYearEnrolment'){
            this.qualTertiaryLastYearEnrolled=event.target.value;
        }else if(event.target.name==='inputQualTertiaryComments'){
            this.qualTertiaryComments=event.target.value;
        }else if(event.target.name==='inputQualSecondaryOther'){
            this.qualSecondaryTypeOther=event.target.value;
        }else if(event.target.name==='inputQualAwardingBodyOtherSec'){
            this.qualSecondarySchoolOther=event.target.value;
        }else if(event.target.name==='inputQualSecondaryEnglishOnly'){
            this.qualSecondaryEnglishOnly=event.target.checked;
        }else if(event.target.name==='inputQualSecondaryIsCompleted'){
            this.qualSecondaryCompleted=event.target.checked;
        }else if(event.target.name==='inputQualSecondaryYearCompleted'){
            this.qualSecondaryYearCompleted=event.target.value;
        }else if(event.target.name==='inputQualSecondaryComments'){
            this.qualSecondaryComments=event.target.value;
        }else if(event.target.name==='inputQualAdmissionsName'){
            this.qualAdmissionsName=event.target.value;
        }else if(event.target.name==='inputQualAdmissionsDateCompleted'){
            this.qualAdmissionsDateCompleted=event.target.value;
        }else if(event.target.name==='inputQualAdmissionsDateExpected'){
            this.qualAdmissionsDateExpected=event.target.value;
        }else if(event.target.name==='inputQualAdmissionsComments'){
            this.qualAdmissionsComments=event.target.value;
        }else if(event.target.name==='inputQualEnglishTestDateCompleted'){
            this.qualEnglishTestDateCompleted=event.target.value;
        }else if(event.target.name==='inputQualEnglishComments'){
            this.qualEnglishComments=event.target.value;
        }else if(event.target.name==='inputQualEnglishGPAResult'){
            this.qualAdmissionsGPAResult=event.target.value;
        }else if(event.target.name==='inputQualEnglishListeningScore'){
            this.qualEnglishTestScoreListening=event.target.value;
        }else if(event.target.name==='inputQualEnglishReadingScore'){
            this.qualEnglishTestScoreReading=event.target.value;
        }else if(event.target.name==='inputQualEnglishWritingScore'){
            this.qualEnglishTestScoreWriting=event.target.value;
        }else if(event.target.name==='inputQualEnglishSpeakingScore'){
            this.qualEnglishTestScoreSpeaking=event.target.value;
        }else if(event.target.name==='testReportNumber'){
            this.testReportNumber=event.target.value;
            this.verifyDisabled = (this.testReportNumber === null);
        }else if(event.target.name==='englishTestType'){
            this.qualEnglishTestName=event.target.value;
        }
    }

    populateContactQualificationLOI(objCQ) {
        objCQ.RecordTypeId = this.englishTypeRecordTypeId;
        objCQ.Qualification__c = this.languageOfInstruction; // this needs to be set to LOI\
        objCQ.Other_Qualification_Comments__c = this.selectedEnglishRequirementLabel;
        objCQ.Source_Channel__c = 'Manual';
    }

    populateContactQualificationEnglishSave(objCQ) {
        const arrSaveErrors = [];
        const englishTestType = this.selectedEnglishTypeId;

        // Validate English Test Type
        if (!englishTestType) arrSaveErrors.push('English Test Type');
        objCQ.Qualification__c = englishTestType;
        objCQ.RecordTypeId = this.englishTypeRecordTypeId;

        const isComplete = this.selectedEnglishRequirement === 'TEST-DONE';
        let verificationStatus = '';
        objCQ.isTestCompleted__c = isComplete;

        if (isComplete) {
            const dateAchieved = this.qualEnglishTestDateCompleted;

            // Validate "Date Achieved"
            if (!dateAchieved) {
                arrSaveErrors.push('Date Completed');
            } else if (!this.isCompletedDateValid(dateAchieved)) {
                arrSaveErrors.push('Date Completed is invalid');
            } else {
                objCQ.Date_Achieved__c = dateAchieved;
                verificationStatus ='Unverified';
            }

            // Validate English Test Scores
            this.validateEnglishScores(objCQ, arrSaveErrors);
        }
        else {
            const dateExpected = this.qualEnglishTestDateExpected;

            // Validate "Expected Date of Completion"
            if (!dateExpected) {
                arrSaveErrors.push('Date expected to be completed');
            } else if (this.isDatePast(dateExpected)) {
                this.addErrorMessageExpectedDatePast(arrSaveErrors);
            } else {
                objCQ.Expected_date_of_completion__c = dateExpected;
                verificationStatus ='Unknown';
            }
        }
        let appComments = this.selectedEnglishRequirementLabel;

        // Add general information
        Object.assign(objCQ, {
            Other_Qualification_Comments__c: appComments,
            Source_Channel__c: 'Manual',
            Verification_Status__c: verificationStatus
        });

        // Validate for unsafe inputs
        if (this.isUnsafe(objCQ)) arrSaveErrors.push('One or more input boxes are not in the expected format.');

        // Save errors
        this.saveErrors = arrSaveErrors;
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
        if(!secondaryState && countryName === 'Australia')
        {
            arrSaveErrors.push('State');
        }
        else if(!secondaryStateProvince
            && (countryName === 'China (excludes SARs and Taiwan)' || countryName ==='India'))
        {
            arrSaveErrors.push('State/Province');
        }

        // name of qualification
        var qualSecondaryTypeOther = this.qualSecondaryTypeOther;
        var qualSecondary = this.qualSecondaryType;
        var qualSecondaryId = this.qualSecondaryTypeId;
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
        return objCQ;
    }

    addErrorMessageExpectedDatePast(arrSaveErrors) {
        arrSaveErrors.push('Expected Date of Completion is in the past');
    }

    loadDraftSecondary(objCQ) {
        var mapCountry = this.countryMap;
        // country/state
        this.qualSecondaryCountryId = objCQ.Qualification_Country__c;
        this.qualSecondaryCountry = mapCountry[objCQ.Qualification_Country__c];
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
        // Find the draft qualification by ID
        const objCQ = this.qualListDraft.find(conQual => conQual.Id === contactQualificationId);

        if (!objCQ) {
            console.error(`appAddQualificationHelper::loadDraftQualification - could not find draft record ${contactQualificationId}`);
            return;
        }

        // Set the page attributes
        this.contactQualification = objCQ;
        this.selectedQualRecordTypeId = objCQ.RecordTypeId;
        this.selectedQualTypeName = objCQ.recordTypeLabel;

        // Handle record type-specific logic
        switch (this.selectedQualTypeName) {
            case 'Tertiary Education/Post Secondary':
                this.loadDraftTertiary(objCQ);
                this.loadDraftSearchWDropdown = true;
                break;
            case 'Secondary Education':
                this.loadDraftSecondary(objCQ);
                this.loadDraftSearchWDropdown = true;
                break;
            case 'English Test':
                this.loadDraftEnglish(objCQ);
                break;
            case 'Other Qualification':
                this.loadDraftAdmissions(objCQ);
                break;
            default:
                console.error(`appAddQualificationHelper:: record type "${this.selectedQualTypeName}" not found`);
        }

        // Finalize by showing/hiding qualification type
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
        this.qualEnglishTestId = objCQ.Qualification__r.Id;
        this.selectedEnglishTypeId = this.qualEnglishTestId;
        this.selectedEnglishRequirement = objCQ.isTestCompleted__c ? 'TEST-DONE' : 'TEST-TODO';

        var qualification = objCQ.Qualification__r;
        if (qualification) {
            this.qualEnglishTestName = qualification.Qualification_Name__c;
        }

        var isComplete = objCQ.isTestCompleted__c;
        this.qualEnglishCompleted = isComplete;

        this[isComplete ? 'qualEnglishTestDateCompleted' : 'qualEnglishTestDateExpected'] =
            isComplete ? objCQ.Date_Achieved__c : objCQ.Expected_date_of_completion__c;

        this.qualAdmissionsGPAResult = objCQ.Score__c;
        this.qualEnglishTestScoreListening = objCQ.Listening__c;
        this.qualEnglishTestScoreReading = objCQ.Reading__c;
        this.qualEnglishTestScoreSpeaking = objCQ.Speaking__c;
        this.qualEnglishTestScoreWriting = objCQ.Writing__c;
        this.testReportNumber =  objCQ.English_Test_Number__c;
    }

    loadDraftAdmissions(objCQ) {
        this.qualAdmissionsName = objCQ.Other_Qualification__c;
        this.qualAdmissionsGPAResult = objCQ.Score__c;


        var isCompleted = objCQ.isTestCompleted__c;
        this.qualAdmissionsCompleted = isCompleted;

        // if completed or expecting completion
        this[isCompleted ? 'qualAdmissionsDateCompleted' : 'qualAdmissionsDateExpected'] = isCompleted
            ? objCQ.Date_Achieved__c
            : objCQ.Expected_date_of_completion__c;

        this.qualAdmissionsComments = objCQ.Other_Qualification_Comments__c;
    }

    lookupInstitution(objCQ) {
        var institutionCode = objCQ.Institution_Code__c;
        var institutionName = objCQ.Institution_Name__c;

        var institutionList = this.institutionList;
        for( var i = 0; i < institutionList.length; ++i)
        {
            var objInstitution = institutionList[i];
            if(objInstitution.Institution_Code__c === institutionCode && objInstitution.Institution_Name__c === institutionName)
            {
                return objInstitution;
            }
        }
        return null;
    }

    validateEnglishScores(objCQ, arrSaveErrors) {

        const scores = [
            { input: 'inputQualEnglishListeningScore', field: 'Listening__c', value: this.qualEnglishTestScoreListening, error: 'English Listening Score' },
            { input: 'inputQualEnglishReadingScore', field: 'Reading__c', value: this.qualEnglishTestScoreReading, error: 'English Reading Score' },
            { input: 'inputQualEnglishSpeakingScore', field: 'Speaking__c', value: this.qualEnglishTestScoreSpeaking, error: 'English Speaking Score' },
            { input: 'inputQualEnglishWritingScore', field: 'Writing__c', value: this.qualEnglishTestScoreWriting, error: 'English Writing Score' },
            { input: 'inputQualEnglishGPAResult', field: 'Score__c', value: this.qualAdmissionsGPAResult, error: 'Overall Score' }
        ];

        scores.forEach(score => {
            if (this.isInputValid(score.input)) {
                objCQ[score.field] = score.value;
            } else {
                arrSaveErrors.push(score.error);
            }
        });
    }

    isCompletedDateValid(dateString) {
        var dateToday = new Date();
        var dateValue = new Date(dateString);
        return dateValue <= dateToday;

    }

    isExpectedDateValid(dateString) {
        var dateToday = new Date();
        var dateValue = new Date(dateString);
        return dateValue >= dateToday;

    }

    isInputValid(cmpId) {
        // expected/completed dates
        var cmpInput = this.FindElement(cmpId);
        if(cmpInput != null){
            return cmpInput.checkValidity();
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
            if(obj[searchField] === searchValue)
                return obj;
        }
        // error, not found
        console.error('appAddQualificationHelper:: ' + searchField + '=' + searchValue+ ', not found');
    }

    reverseLookupInstitutionId(component, mapAttrName, institutionName, institutionCode) {
        var mapInstitutions = component.get(mapAttrName);

        for(var instId in mapInstitutions)
        {
            var objInstitute = mapInstitutions[instId];
            if(objInstitute.Institution_Name__c === institutionName &&
                objInstitute.Institution_Code__c === institutionCode)
            {
                return instId;
            }
        }

        // if you got here, not found
        console.error('appAddQualificationHelper:: id for ' + institutionName + ', ' + institutionCode + ', not found');
    }

    clearComponentAttributes() {
        // Reset variables
        Object.assign(this, {
            contactQualification: null,
            editingDraft: false,
            selectedQualRecordTypeId: 'default',
            qualTertiaryCountryId: null,
            qualTertiaryCountry: null,
            qualSecondaryCountryId: null,
            qualSecondaryCountry: null,
            qualTertiaryState: null,
            qualSecondaryState: null,
            qualTertiaryName: null,
            tabIdSecondaryType: 'SEC_QUAL_NAME_SEARCH',
            qualSecondaryType: null,
            qualSecondaryTypeId: null,
            qualSecondaryTypeOther: null,
            qualAdmissionsName: null,
            qualEnglishTestName: null,
            tabIdTertiaryAwardingBody: 'AUS_TER_SEARCH',
            qualTertiaryAwardingBody: null,
            qualTertiaryAwardingBodyOther: null,
            objTertiaryAwardingBody: null,
            currentInstitution: null,
            mapCurrentInstitutions: null,
            tabIdSecondarySchool: 'AUS_SEC_SEARCH',
            qualSecondarySchool: null,
            qualSecondarySchoolOther: null,
            objSecondarySchool: null,
            qualTertiaryLevelOfCompletion: null,
            qualTertiaryFirstYearEnrolled: null,
            qualTertiaryLastYearEnrolled: null,
            qualTertiaryComments: null,
            qualSecondaryCompleted: null,
            qualSecondaryYearCompleted: null,
            qualSecondaryDateExpected: null,
            qualSecondaryComments: null,
            errorMsgSecondaryDateExpected: false,
            qualAdmissionsCompleted: null,
            qualAdmissionsDateExpected: null,
            qualAdmissionsDateCompleted: null,
            qualEnglishCompleted: null,
            qualEnglishTestDateCompleted: null,
            qualEnglishTestDateExpected: null,
            errorMsgEnglishTestDateExpected: false,
            qualAdmissionsComments: null,
            qualTertiaryEnglishOnly: null,
            qualSecondaryEnglishOnly: null,
            qualSecondaryScore: null,
            qualTertiaryGPAResult: null,
            showEnglishTypeOption: false,
            showDateCompleted: false,
            showDateExpected: false,
            showTestReportNumber: false,
            showEnglishTestScores: false,
            showVerifyButton: false,
            showAddTestDetailButton: false,
            showAddTestDetailButtonAfterFailedVerification: false
        });

        // Clear English score and form
        this.clearScore();
        this.clearEnglishForm();

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
        return yyyy + '-' + mm + '-' + dd;
    }

    isDatePast(aDate) {
        if (!aDate) return false;
        const todayFormattedDate = this.formatDateString(new Date());
        return aDate < todayFormattedDate;

    }

    debugObject(objDebug, functionName) {
        if(this.DEBUGGING === true)
        {
            console.log(functionName + ':object {');
            for(var k in objDebug)
            {
                console.log(k + ' : ' + objDebug[k]);
            }
            console.log('}');
        }
    }

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
            if(recType && recType.Name === 'Tertiary Education')
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
                if(recType && recType.Name === 'Tertiary Education')
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
            if(recType && recType.Name === 'Tertiary Education'){
                qualDraftList[i].recordTypeLabel = 'Tertiary Education/Post Secondary';
            }else{
                qualDraftList[i].recordTypeLabel = objCQ.RecordType.Name;
            }
        }
    }

    checkEngProfRequire(){
        this.showRequiredEng = (this.englishLanguageProficiency && this.englishLanguageProficiency === 'No') && this.hasSavedSection;
    }

    checkQualifications(){
        this.noQualificationFound =
            !(this.filteredQualListDraft && this.filteredQualListDraft.length > 0) &&
            !(this.filteredQualListHistorical && this.filteredQualListHistorical.length > 0);

        this.noEnglishProficiencyFound =
            !(this.filteredEngQualListDraft && this.filteredEngQualListDraft.length > 0) &&
            !(this.filteredEngQualListHistorical && this.filteredEngQualListHistorical.length > 0);

        if (this.noEnglishProficiencyFound) {
            this.showEnglishRequirementSection = true;
            this.showAddNewEnglishProficiency = false;
            this.showEnglishProgramConsideration = false;
        } else {
            this.showEnglishTestQualifications = true;
            this.showEnglishRequirementSection = false;
            this.showAddNewEnglishProficiency = true;
            this.showEnglishProgramConsideration = true;
        }
    }

    showHideStudyType(){
        this.isAbroadType = (this.studyType === 'Study Abroad' || this.studyType === 'Exchange');
        this.isNotAbroadType = !this.isAbroadType;
    }

    /**
     * @description Toggles qualification type visibility based on the provided record type name.
     * @param qualRecTypeName The name of the qualification record type.
     */
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