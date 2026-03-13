import { LightningElement, api, track, wire } from "lwc";
import getCourseSearchInitLoad from "@salesforce/apex/StudyPreferenceServiceGR.getCourseSearchInitLoad";
import addGRTACPs from "@salesforce/apex/StudyPreferenceServiceGR.addGRTACPs";
import removeACP from "@salesforce/apex/StudyPreferenceServiceGR.removeACP";


import getScholarshipRounds from '@salesforce/apex/StudyPreferenceServiceGR.getScholarshipRoundsValues';
import getAcademicValues from '@salesforce/apex/StudyPreferenceServiceGR.getAcademicUnitValues';
import getFacultyValueOptions from '@salesforce/apex/StudyPreferenceServiceGR.getFacultyValues';
import getHDRCourseValues from '@salesforce/apex/StudyPreferenceServiceGR.getHDRCourses';
import getHDRCampusLocationValues from '@salesforce/apex/StudyPreferenceServiceGR.getCampusLocations';
import getAttendanceTypeValues from '@salesforce/apex/StudyPreferenceServiceGR.getAttendanceTypes';
import getAttendanceModeValues from '@salesforce/apex/StudyPreferenceServiceGR.getAttendanceModes';
import getCandidatureCalendar from '@salesforce/apex/StudyPreferenceServiceGR.getCalendarIdCandidature';
import getCalendarIdBasedOnCommencementDate from '@salesforce/apex/StudyPreferenceServiceGR.getCalendarIdBasedOnCommencementDate';


import getCourseAttempts from '@salesforce/apex/StudyPreferenceServiceGR.getCourseAttempts';
import getCourseAttemptsDetails from '@salesforce/apex/StudyPreferenceServiceGR.getCourseAttemptsDetails';

import disableDomesticRoundsLabel from "@salesforce/label/c.GRT_Domestic_Scholarship_Rounds_Unavailable";
import disableInternationalRoundsLabel from "@salesforce/label/c.GRT_International_Scholarship_Rounds_Unavailable";
import disableRoundsWithScholarshipGaps from "@salesforce/label/c.GRT_Scholarship_Rounds_Gaps";


export default class MyGRAppAddCourse extends LightningElement {
    @api applicationId;
    @api source = "";
    @track appId = null;
    @track application = null;
    @track user = null;
    @track citizenshipType;
    @track studyType;
    @track sourceSystem; 
    @track contactId = null;
    @track contact = null;
    @track acps = [];
    @track addedOfferingIds = []; 
    @track acpIdToRemove = "";
    @track showRemoveACP = false;
    @track showSearchSpinner = false;
    @track showOfferingSpinner = false;
    @track offeringsByCourseCode = [];
    @track filteredCourseOfferings = [];
    @track selectedCourseOfferings = [];
    @track selectedAreasOfStudy = [];
    @track currentSelectedAreasOfStudy = [];
    @track showErrorAlert = false;
    @track showSpinner = false;
    @track showInlineSpinner = false;
    @track MAApplication = false;
    @track addAppButton;
    @track isGraduateResearch = false;
    @track scholarshipRoundsOptions = [];
    @track courseOfferingFacultyId = '';
    @track academicValuesOptions = [];
    @track courseOptions = [];
    @track locationCodesOptions = [];
    @track attendanceTypeOptions = [];
    @track attendanceModeOptions = [];
    @track academicUnit = '';
    @track selectedCourse = ''; 
    @track selectedLocation = '';
    @track selectedAttendanceType = ''; 
    @track selectedAttendanceMode= ''; 
    @track showOffCampusNotes = false;
    @track academicUnitName = '';
    @track scholarshipRoundsFound = false;
    @track appCountry = '';
    @track facultyValueOptions = [];
    @track selectedFaculty = '';
    @track selectedLabel = ''; //scholarship rounds label
    @track scholarshipAdditionalDetailsSection = false;
    @track scholarshipRoundsSection = true;
    @track lastAppliedDate = null;
    @track showLastAppliedDate = false;
    @track lastAppliedDateDesc = '';   
    @track showUploadDocumentText = false;
    @track offCampusArrangements = '';
    @track offCampusSelected = true;
    @track proposedCommencementDate = '';
    @track equityScholarship = '';
    @track indigenousScholarship = '';
    @track isAdmissionOnly = false;
    @track isAdmissionScholarship = false;
    @track isScholarshipOnly = false;
    @track selectedScholarshipRound = '';
    @track courseDetailSelected = true;
    @track previousAppliedSelected = false;
    @track displayScholarshipRounds = false;
    @track showPage1 = true;
    @track earlyComDate = '';
    @track latestComDate = '';
    @track selectedScholarshipRoundVal = '';
    @track courseAttempOptions = [];
    @track courseAttemptId = '';
    @track facultyName = '';
    @track courseTitle = '';
    @track selectedAttendanceTypeDesc = '';
    @track selectedAttendanceModeDesc = '';
    @track selectedCourseSCH = '';
    @track showPCDateError = false;
    @track earlyComDateDesc = '';
    @track latestComDateDesc = '';
    @track acceptOfferPriorToShcolarshipFlag = false;
    @track acceptOfferPriorToShcolarshipDate = null;
    @track withScholarshipRounds = false;
    @track parentAppId = null;
    @track validCommencementDate = false;
    earlyDateSelected = false;
    earliestPossibleDate = '';
    earliestPossibleDateText = '';
    disableScholarshipRoundsStatus = '';
    disableDomestic = false;
    disbaleInternational = false;
    withScholarshipGaps = false;
    disableScholarshipRounds = false;
    showPartTimeNotes = false;
    showPartTimeNotesSO = false;
    showEquityNotes = false;
    showAboriginalNotes = false;
    campusLocation = '';
    attendanceModeDescGRT = '';
    showEquityAboriginalQuestions = false
    showChangeToFullTime = false;
    showChangeToInternal = false;
    showUpgradeToMaster = false;
    changeToFullTimeCheck = '';
    masterUpgradeCheck = '';
    changeToInternalCheck = '';
    schCalendarId;
    closingMonthYear;
    error;
    showErrors;

    label = {
        disableDomesticRoundsLabel,
        disableInternationalRoundsLabel,
        disableRoundsWithScholarshipGaps
    };

    @track previousScholarshipOptions = [
        { label: 'Yes', value: 'true' },
        { label: 'No', value: 'false' },
    ];
    @track equityScholarshipOptions = [
        { label: 'Yes', value: 'true' },
        { label: 'No', value: 'false' },
    ];
    @track indScholOptions = [
        { label: 'Yes', value: 'true' },
        { label: 'No', value: 'false' },
    ];
    @track changeToFullTimeOptions = [
        { label: 'Yes', value: 'true' },
        { label: 'No', value: 'false' },
    ];

    @track changeToInternalOptions = [
        { label: 'Yes', value: 'true' },
        { label: 'No', value: 'false' },
    ];

    @track masterUpgradeOptions = [
        { label: 'Yes', value: 'true' },
        { label: 'No', value: 'false' },
    ];
    today;

    connectedCallback() {
        this.today = new Date().toISOString().slice(0,10);
        this.doInit();
    }

    get vMAApplication() {
        return !this.MAApplication;
    }

    get vshowSpinner() {
        return this.showSpinner === true ? "" : "slds-hide";
    }

    get acps_length() {
        return this.acps.length > 0;
    }

    get acps_length_greaterThan_1() {
        return this.acps.length > 1;
    }

    get acps_length_greaterThan_1_slds() {
        return this.acps.length > 1 ? "" : "slds-hide";
    }

    get showRemoveACP_slds() {
        return this.showRemoveACP ? "" : "slds-hide";
    }

    get stateSearchSlds() {
        return this.STATE === "SEARCH" ? "" : "slds-hide";
    }

    get showSearchSpinnerSlds() {
        return this.showSearchSpinner === true ? "" : "slds-hide";
    }

    get showInlineSpinnerSlds() {
        return this.showInlineSpinner === true ? "" : "slds-hide";
    }

    get vshowOfferingSpinner() {
        return this.showOfferingSpinner === true ? "" : "slds-hide";
    }

    get showPCDateError_slds(){
        return this.showPCDateError ? "": "slds-hide";
    }

    doInit(event) {
        this.showCourseSearchSpinner(true);
        this.getCourseSearchAppId();
        this.addAppButton = true;
        var appId = this.appId;
        if(!appId){
            appId = this.applicationId;
        }else{
            //redirect to the new app form url
            window.location.href = '/admissions/s/application/' + appId;
        }

        if(appId) {
            var action = getCourseSearchInitLoad;
            action({
                "appId": appId
            }).then(response => {
                var objResponse = response;

                // user
                var objUser = objResponse.user;
                this.user = objUser;


                // contact/applicant
                var contactId = objResponse.contactId;
                this.contactId = contactId;

                var contact = objResponse.contact;
                this.contact = contact;

                //check if scholarship rounds is disabled
                this.disableScholarshipRoundsStatus = objResponse.CheckRounds;
                if(this.disableScholarshipRoundsStatus != '' && this.disableScholarshipRoundsStatus != undefined){
                    if(this.disableScholarshipRoundsStatus == 'DisableDomestic'){
                        this.disableDomestic = true;
                    }

                    if(this.disableScholarshipRoundsStatus == 'DisableInternational'){
                        this.disableInternational = true;
                    }

                    if(this.disableScholarshipRoundsStatus == 'WithScholarshipGaps'){
                        this.withScholarshipGaps = true;
                    }
                    this.disableScholarshipRounds = true;
                }


                // store country location
                this.appCountry = objResponse.application.Campus_Location__c;
                // store the citizenship type, subject to change
                this.citizenshipType = objResponse.application.Residency_Status__c;
                this.studyType = objResponse.application.Type_of_Study__c;
                
                if(this.studyType == 'Graduate Research'){
                    this.isGraduateResearch = true;
                }
                if(objResponse.application.Graduate_Research_Application_Type__c == 'Admission and Scholarship'){
                    this.isAdmissionScholarship = true;
                    this.withScholarshipRounds = true;
                }
                else if(objResponse.application.Graduate_Research_Application_Type__c == 'Admission application only'){
                    this.isAdmissionOnly = true;
                    this.withScholarshipRounds = false;
                }else if(objResponse.application.Graduate_Research_Application_Type__c == 'Scholarship application only'){
                    this.isScholarshipOnly = true;
                    this.withScholarshipRounds = true;

                }

                if(this.isAdmissionScholarship || this.isScholarshipOnly){
                    this.displayScholarshipRounds = true;
                }

                if(this.citizenshipType == 'DOM-AUS' || this.citizenshipType == 'DOM-PR' || this.citizenshipType == 'DOM-NZ'){
                    this.showEquityAboriginalQuestions = true;
                }
                
                
                this.sourceSystem = objResponse.application.Source_System__c;
                this.campusLocation = objResponse.application.Campus_Location__c;
                // store the application for fields, eg campus location
                this.application = objResponse.application;
               

                // store the current ACPs
                var arrACPs = objResponse.acps;
                var acpsLength=arrACPs.length;
                this.acps = arrACPs.map(item => ({
                    ...item, //all other properties will be copied.
                    courseOfferingActiveFalse: item.Course_Offering__r.Active__c == false,
                    unitSetDescNull: item.Unit_Set_Description__c != null,
                    index_equals_0: item.Preference_Number__c == 1 ? 'slds-hide acpButton':'acpButton',
                    index_equals_acps_length: item.Preference_Number__c == acpsLength ? 'slds-hide acpButton' : 'acpButton',
                    courseCodeTitleDesc: item.Course_Code__c +' - '+item.Course_Title__c+'/ '+item.Unit_Set_Description__c,
                    courseCodeTitle: item.Course_Code__c +' - '+item.Course_Title__c,
                    attendanceType: item.Attendance_Type_Description__c+', '+item.Attendance_Mode_Description__c,
                    courseOfferingFacultyId: item.Course_Offering__r.Faculty__c,
                    attendanceModeDescGRT: item.Attendance_Mode__c == 'EX' ? 'External (off-campus)' : item.Attendance_Mode__c == 'IN' ? 'Internal (on-campus)' : ''
                 }));


                this.showCourseSearchSpinner(false);
            });
        }
        else {
            this.showCourseSearchSpinner(false);
        }

    }
    //Add Application Course Preference
    @api
    addCourseOfferings(event) {
        this.showCourseSearchSpinner(true);
        var appId = this.appId;
        if(!appId){
            appId = this.applicationId;
        }

        // get all the selected Ids
        var courseOfferingIds = this.selectedCourseOfferings;
        var selectedAreas = this.selectedAreasOfStudy;
        courseOfferingIds = courseOfferingIds.concat(selectedAreas);

        var acps = this.acps;
        var acpCap = this.MAApplication?1:5;

        if(acps.length + courseOfferingIds.length > acpCap)
        {
            // show alert box
            this.showErrorAlert = true;
            this.showCourseSearchSpinner(false);
        }
        else
        {   if(this.isScholarshipOnly){
                this.academicUnit = null;
            }
            var action = addGRTACPs;

            action({
                "courseOfferingIds":courseOfferingIds,
                "appId": appId,
                "calendarId": this.selectedScholarshipRound,
                "schCalendarId":this.schCalendarId,
                "pcDate": this.proposedCommencementDate,
                "orgUnit": this.academicUnit,
                "externalAttendanceText": this.offCampusArrangements,
                "equityScholarship": this.equityScholarship,
                "indigenousScholarship": this.indigenousScholarship,
                "lastAppliedDate": this.lastAppliedDate,
                "lastAppliedDateDesc": this.lastAppliedDateDesc,
                "courseLabel": this.selectedCourse,
                "locationCode": this.selectedLocation,
                "attendanceType": this.selectedAttendanceType,
                "attendanceMode": this.selectedAttendanceMode,
                "facultyId": this.courseOfferingFacultyId,
                "citizenshipType":this.citizenshipType,
                "scholarshipRound": this.selectedLabel,
                "acceptPriorScholarshipFlag": this.acceptOfferPriorToShcolarshipFlag,
                "parentAppId": this.parentAppId,
                "changeToFullTime": this.changeToFullTimeCheck,
                "masterUpgrade": this.masterUpgradeCheck,
                "changeToInternal": this.changeToInternalCheck,
                "schClosingMonthYear":this.closingMonthYear
            }).then(response => {
                var courseEvent = new CustomEvent("acpEvent", {
                    detail: {
                        "eventType" : "AddACP" 
                    }
                });

                this.dispatchEvent(courseEvent);
                var objResponse = response;
                if(objResponse.error) {
                    this.error = 'You have already submitted an application for the admission period that aligns with your proposed commencement date and/or scholarship round.\n'+
                                'Before this application can be submitted, you will need to change the proposed commencement date or request that your previously submitted application to be withdrawn.';
                    this.showErrors = true   
                    this.showCourseSearchSpinner(false);  
                    let saveSuccess = false;
                    const saveEvent = new CustomEvent("savesuccess", {
                        detail: { saveSuccess },
                    });
                    this.dispatchEvent(saveEvent);
                    return false 
                }
                // refresh the acp list
                var acpsReceived = objResponse.acps;
                
                var acpsLength=acpsReceived.length;
                this.acps = acpsReceived.map(item => ({
                    ...item, //all other properties will be copied.
                    courseOfferingActiveFalse: item.Course_Offering__r.Active__c == false,
                    unitSetDescNull: item.Unit_Set_Description__c != null,
                    index_equals_0: item.Preference_Number__c == 1 ? 'slds-hide acpButton':'acpButton',
                    index_equals_acps_length: item.Preference_Number__c == acpsLength ? 'slds-hide acpButton' : 'acpButton',
                    courseCodeTitleDesc: item.Course_Code__c +' - '+item.Course_Title__c+'/ '+item.Unit_Set_Description__c,
                    courseCodeTitle: item.Course_Code__c +' - '+item.Course_Title__c,
                    attendanceType: item.Attendance_Type_Description__c+', '+item.Attendance_Mode_Description__c
                }));
                this.storeAddedOfferingIds();

                // go back to search state
             

                this.showCourseSearchSpinner(false);
             

                this.dispatchEvent(new CustomEvent("reformsteps"));//resetting the step components after course selection
                
                let saveSuccess = true;
                const saveEvent = new CustomEvent("savesuccess", {
                    detail: { saveSuccess },
                });
                this.dispatchEvent(saveEvent);
                
            })
        }


    }

    //Check all fields validation during save and continue 
    @api
    checkValidity() {
        const commencementDateComp = this.template.querySelector('[data-id="expectedCommencementDate"]');
        let isCommencementDateValid = true
        if(commencementDateComp && this.isScholarshipOnly && this.proposedCommencementDate != undefined && this.earlyComDate != undefined && this.latestComDate != undefined) {
            if(new Date(this.proposedCommencementDate) < new Date(this.earlyComDate) || new Date(this.proposedCommencementDate) > new Date(this.latestComDate)) {
                commencementDateComp.setCustomValidity('Please select a date between '+this.earlyComDateDesc +' and '+this.latestComDateDesc);
                isCommencementDateValid = false;
            } else {
                commencementDateComp.setCustomValidity(''); // Clear any previous errors
            }
            commencementDateComp.reportValidity();
        } 
        const allValid = [
            ...this.template.querySelectorAll('lightning-input'),
            ...this.template.querySelectorAll('lightning-select'),
            ...this.template.querySelectorAll('lightning-radio-group'),
            ...this.template.querySelectorAll('lightning-textarea'),
            ...this.template.querySelectorAll('lightning-combobox'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity() && isCommencementDateValid;
        }, true);
        return allValid;
    }

    @api
    checkIfHasACPS(){
        var acps = this.acps;
        if(acps.length > 0){
            return true;
        }else{
            return false;
        }
    }

    //confirm to remove/reselect acp record
    confirmRemoveACP(event) {
        this.showCourseSearchSpinner(true);
        var appId = this.appId;
        if(!appId){
            appId = this.applicationId;
        }

        // get the selected ACP Id
        var acpId = this.acpIdToRemove;

        var action = removeACP;
        action({
            "acpId" :acpId,
            "appId" : appId
        }).then(response => {
            var objResponse = response;

            // refresh the acp list
            var acpsReceived = objResponse.acps;
            var acpsLength=acpsReceived.length;
            this.acps = acpsReceived.map(item => ({
                ...item, //all other properties will be copied.
                courseOfferingActiveFalse: item.Course_Offering__r.Active__c == false,
                unitSetDescNull: item.Unit_Set_Description__c != null,
                index_equals_0: item.Preference_Number__c == 1 ? 'slds-hide acpButton':'acpButton',
                index_equals_acps_length: item.Preference_Number__c == acpsLength ? 'slds-hide acpButton' : 'acpButton',
                courseCodeTitleDesc: item.Course_Code__c +' - '+item.Course_Title__c+'/ '+item.Unit_Set_Description__c,
                courseCodeTitle: item.Course_Code__c +' - '+item.Course_Title__c,
                attendanceType: item.Attendance_Type_Description__c+', '+item.Attendance_Mode_Description__c
             }));
            this.storeAddedOfferingIds();

            // close the modal box
            this.showRemoveACP = false;

            // go back to search state
            this.clearApplicationForms();
            const selectedEvent = new CustomEvent('reformsteps', {
                detail: { stepName: 'Application Details' }
            });
            this.dispatchEvent(selectedEvent);//resetting the step components after course selection
            
            var courseEvent = new CustomEvent("acpEvent", {
                detail: {
                    "eventType" : "RemoveACP" 
                }
            });

            this.dispatchEvent(courseEvent);

            this.showCourseSearchSpinner(false);
        });
    }

    //Display remove acp pop-up
    showRemovePopup(event) {
        var acpId = event.currentTarget.name;
        this.acpIdToRemove = acpId;
        this.showRemoveACP = true;
    }

    //Close remove acp pop-up
    cancelRemoveACP(event) {
        this.acpIdToRemove = null;
        this.showRemoveACP = false;
    }

    //Display copurse spinner
    showCourseSearchSpinner(toShow) {
        this.showSpinner = toShow;
    }


    getCourseSearchAppId() {
        var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var sParameterName;
        var i, j;

        var retrievedAppId = '';
        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('='); //to split the key from the value.
            for (j = 0; j < sParameterName.length; j++) {
                if (sParameterName[j] === 'appId') { //get the app Id from the parameter
                    retrievedAppId = sParameterName[j+1];
                    this.appId = retrievedAppId;
                    return;
                }
            }
        }
    }

    storeAddedOfferingIds() {
        var acps = this.acps;
        var offeringIds = [];
        for(var i = 0; i < acps.length; ++i)
        {
            var acp = acps[i];
            offeringIds.push(acp.Course_Offering__c);
        }
        this.addedOfferingIds = offeringIds;
        
    }
    
    //Retrieved calendar id for admission application only
    getCandidatureCalendar(){
        if(this.isAdmissionOnly){
            var action = getCandidatureCalendar;
            action({
                "citizenship": this.citizenshipType,
                "pcDate": this.proposedCommencementDate            
            }).then(response => {
                this.selectedScholarshipRound = response;
            }).catch(err =>{
                console.log('Error while getting calendar id');
            });
        }
    
    }

    //Retrieved calendar id for admission application only
    getScholarshipRoundsBasedOnProposedDate(){
        if(this.withScholarshipRounds && this.earlyDateSelected){
            var action = getCalendarIdBasedOnCommencementDate;
            action({
                "proposedDate": this.proposedCommencementDate            
            }).then(response => {
                this.selectedScholarshipRound = response;
            }).catch(err =>{
                console.log('Error while getting calendar id');
            });
        }
    
    }

    //Retrieved scholarship rounds and calendar for admission and scholarship application
    @wire(getScholarshipRounds, {citizenship: '$citizenshipType', withScholarship: '$withScholarshipRounds', disableScholarshipRounds: '$disableScholarshipRounds'})
    scholarshipRounds({ error, data }) {
        // If data is returned from the wire function
        if (data) {
            // Map the data to an array of options
            this.scholarshipRoundsOptions = data.map(option => {
                return {
                    label: option.label,
                    value: option.value
                };
            });

            this.scholarshipRoundsFound = true;
        }
        // If there is an error
        else if (error) {
            // Log the error to the console
            console.error(error);
        }
    }

    //Retrieved academic org units based on selected faculty
    @wire(getAcademicValues, {facultyId:'$courseOfferingFacultyId',appCountry:'$appCountry'})
    academicValues({ error, data }) {
        // If data is returned from the wire function
        if (data) {
            // Map the data to an array of options
            this.academicValuesOptions = data.map(option => {
                return {
                    label: option.label,
                    value: option.value
                };
            });

        }
        
        // If there is an error
        else if (error) {
            // Log the error to the console
            console.error(error);
        }
    }

    //Retrieved faculty values
    @wire(getHDRCourseValues, {facultyId:'$courseOfferingFacultyId',calendarId:'$selectedScholarshipRound',  citizenshipType:'$citizenshipType', campusLocation:'$campusLocation'})
    courseValues({ error, data }) {
        // If data is returned from the wire function
        if (data) {
            // Map the data to an array of options
            this.courseOptions = data.map(option => {
                return {
                    label: option.label,
                    value: option.value
                };
            });

        }
        
        // If there is an error
        else if (error) {
            // Log the error to the console
            console.error(error);
        }
    }

    //Retrieved location codes based on selected course
    @wire(getHDRCampusLocationValues, {facultyId:'$courseOfferingFacultyId',calendarId:'$selectedScholarshipRound',  citizenshipType:'$citizenshipType', 
        courseLabel:'$selectedCourse', campusLocation:'$campusLocation'})
    locationCodes({ error, data }) {
        // If data is returned from the wire function
        if (data) {
            // Map the data to an array of options
            this.locationCodesOptions = data.map(option => {
                return {
                    label: option.label,
                    value: option.value
                };
            });

        }
        
        // If there is an error
        else if (error) {
            // Log the error to the console
            console.error(error);
        }
    }

    //Retrieved attendance types based on selected course
    @wire(getAttendanceTypeValues, {facultyId:'$courseOfferingFacultyId',calendarId:'$selectedScholarshipRound',  citizenshipType:'$citizenshipType', 
        courseLabel:'$selectedCourse', locationCode:'$selectedLocation'})
    attendanceTypes({ error, data }) {
        // If data is returned from the wire function
        if (data) {
            // Map the data to an array of options
            this.attendanceTypeOptions = data.map(option => {
                return {
                    label: option.label,
                    value: option.value
                };
            });

        }
        // If there is an error
        else if (error) {
            // Log the error to the console
            console.error(error);
        }
    }

    //Retrieved attendance modes based on selected course
    @wire(getAttendanceModeValues, {facultyId:'$courseOfferingFacultyId',calendarId:'$selectedScholarshipRound',  citizenshipType:'$citizenshipType', 
        courseLabel:'$selectedCourse', locationCode:'$selectedLocation', attendanceType:'$selectedAttendanceType'})
        attendanceModes({ error, data }) {
        // If data is returned from the wire function
        if (data) {
            // Map the data to an array of options
            this.attendanceModeOptions = data.map(option => {
                return {
                    label: option.label,
                    value: option.value
                };
            });
        }
        // If there is an error
        else if (error) {
            // Log the error to the console
            console.error(error);
        }
    }

    //Retrieved faculty values
    @wire(getFacultyValueOptions, {appCountry:'$appCountry'})
    facultyValues({ error, data }) {
        // If data is returned from the wire function
        if (data) {
            // Map the data to an array of options
            this.facultyValueOptions = data.map(option => {
                return {
                    label: option.label,
                    value: option.value
                };
            });

        }
        // If there is an error
        else if (error) {
            // Log the error to the console
            console.error(error);
        }
    }

    //Reset application forms after course reselection
    clearApplicationForms(){
        this.selectedScholarshipRoundVal = '';
        this.selectedScholarshipRound = '';
        this.proposedCommencementDate = '';
        this.academicUnit = '';
        this.courseOfferingFacultyId = '';
        this.offCampusArrangements = '';
        this.lastAppliedDate = null;
        this.lastAppliedDateDesc = '';
        this.indigenousScholarship = '';
        this.selectedCourse = '';
        this.selectedLocation = '';
        this.selectedAttendanceType = '';
        this.selectedAttendanceMode = '';
        this.showLastAppliedDate = false;
        this.equityScholarship = false;
        this.showUploadDocumentText = false;
        this.showOffCampusNotes = false;
        this.scholarshipRoundsSection = true;
        this.scholarshipAdditionalDetailsSection = false;
        this.courseAttemptId = '';
        this.facultyName = '';
        this.courseTitle = '';
        this.selectedAttendanceTypeDesc = '';
        this.selectedAttendanceModeDesc = '';
    }
    
    //handle field change for each field
    onFieldChange(e) {
        const fieldName = e.target.name
        switch(fieldName) {
            case "proposedCommencementDate":
                this.proposedCommencementDate = e.target.value
                this.clearPicklistOptions('CommencementDate')
                this.validateCommencementDate(e.target.value)
                break
            case "expectedCommencementDate":
                this.proposedCommencementDate = e.target.value
                break     
            case "proposedCommencementDateAd":
                this.proposedCommencementDate = e.target.value
                this.clearPicklistOptions('CommencementDate')
                this.validateCommencementDate(e.target.value)
                break
            case "scholarshipRound":
                this.setScholarshipRoundAndDatesValues(e.target.value)
                this.selectedLabel = e.target.options.find(opt => opt.value === e.detail.value).label;
                this.selectedScholarshipRoundVal = e.target.value;
                break
            case "scholarshipRoundSCH":
                this.setScholarshipRoundAndDatesValues(e.target.value)
                this.selectedLabel = e.target.options.find(opt => opt.value === e.detail.value).label;
                this.selectedScholarshipRoundVal = e.target.value;
                break
            case "academicUnit":
                this.academicUnit = e.target.value
                this.clearPicklistOptions('AcademicUnit')
                break
            case "courseOfferingFaculty":
                this.courseOfferingFacultyId = e.target.value
                this.clearPicklistOptions('Faculty')
                break
            case "previouslyApplied":
                this.checkPreviousApplied(e.target.value)
                break
            case "equityScholarship":
                this.setEquityValue(e.target.value)
                break
            case "offCampusText":
                this.offCampusArrangements = e.target.value
                break
            case "lastAppliedDate":
                this.lastAppliedDate = e.target.value
                break
            case "lastAppliedDateDesc":
                this.lastAppliedDateDesc = e.target.value
                break
            case "indigenousScholarship":
                this.indigenousScholarship = e.target.value
                this.setIndigenousValue(e.target.value)
                break
            case "course":
                this.selectedCourse = e.target.value
                this.clearPicklistOptions('Course')
                break
            case "campus":
                this.selectedLocation = e.target.value
                this.clearPicklistOptions('Campus')
                break
            case "attendanceType":
                this.selectedAttendanceType = e.target.value
                this.setAttendanceType(e.target.value)
                this.clearPicklistOptions('AttendanceType')
                break
            case "attendanceMode":
                this.selectedAttendanceMode = e.target.value
                this.setAttendanceMode(e.target.value)
                this.clearPicklistOptions('AttendanceMode')
                break
            case "courseAttempts":
                    this.courseAttemptId = e.target.value
                    this.getCourseAttemptDetails()
                    break
            case "changeToFullTime":
                 this.setChangeToFullTimeValue(e.target.value)
                 break
            case "changeToInternal":
                this.setChangeToInternalValue(e.target.value)
                break
            case "masterUpgrade":
                    this.setMasterUpgradeValue(e.target.value)
                    break
            default:
                //nothing selected
        }
    }

    //Set scholarship rounds and commencement dates
    setScholarshipRoundAndDatesValues(selectedValue){
        if(selectedValue != ''){
            let scholarshipVal = selectedValue.split("=");
            this.selectedScholarshipRound = scholarshipVal[0];
            this.schCalendarId = this.selectedScholarshipRound;
            this.earlyComDate = scholarshipVal[1];
            this.earlyComDateDesc = scholarshipVal[2];
            this.latestComDate = scholarshipVal[3];
            this.latestComDateDesc = scholarshipVal[4];
            this.earliestPossibleDate = scholarshipVal[5];
            this.earliestPossibleDateText = scholarshipVal[6];
            this.closingMonthYear = scholarshipVal[7];
        }
    }

    //display or hide off campus notes
    setAttendanceMode(selectedValue){
        if(selectedValue == 'EX'){
            this.showOffCampusNotes = true;
        }else{
            this.showOffCampusNotes = false;
        }
    }

    //display or hide part time notes
    setAttendanceType(selectedValue){
        if(selectedValue == 'PT' && this.withScholarshipRounds){
            this.showPartTimeNotes = true;
            this.showChangeToFullTime = true;
        }else{
            this.showPartTimeNotes = false;
            this.showChangeToFullTime = false;
        }
    }
    
    //Check and show components if previously applied scholarship value is set
    checkPreviousApplied(selectedValue){
        if(selectedValue == 'true'){
            this.showLastAppliedDate = true;
        }else{
            this.showLastAppliedDate = false;
        }
        this.previousAppliedSelected = true;
    }

    //Display or hide the upload document text if equity is set
    setEquityValue(selectedValue){
        if(selectedValue == 'true'){
            this.equityScholarship = true;
            this.showUploadDocumentText = true;
            this.showEquityNotes = true;
        }else{
            this.equityScholarship = false;
            this.showUploadDocumentText = false;
            this.showEquityNotes = false;
        }
        
    }


    setChangeToFullTimeValue(selectedValue){
        if(selectedValue == 'true'){
            this.changeToFullTimeCheck = true;
            this.showPartTimeNotesSO = false;
        }else{
            this.changeToFullTimeCheck = false;
            this.showPartTimeNotesSO = true;
        }
    }

    setChangeToInternalValue(selectedValue){
        if(selectedValue == 'true'){
            this.changeToInternalCheck = true;
        }else{
            this.changeToInternalCheck = false;
        }
    }

    setMasterUpgradeValue(selectedValue){
        if(selectedValue == 'true'){
            this.masterUpgradeCheck = true;
        }else{
            this.masterUpgradeCheck = false;
        }
    }

    //Set the indigenous scholarship value
    setIndigenousValue(selectedValue){
        if(selectedValue == 'true'){
            this.indigenousScholarship = true;
            this.showAboriginalNotes = true;
        }else{
            this.indigenousScholarship = false;
            this.showAboriginalNotes = false;
        }
    }

    //Move to additional scholarship details section
    showAdditionalDetailsSection(){
        this.scholarshipAdditionalDetailsSection = true;
        this.scholarshipRoundsSection = false;

    }

    //Back to scholarship rounds section
    showScholarshipRounds(){
        this.scholarshipRoundsSection = true;
        this.scholarshipAdditionalDetailsSection = false;
    }

    clearPicklistOptions(field){
        if(field == 'CommencementDate'){
            this.courseOfferingFacultyId = '';
            this.academicUnit = '';
            this.selectedCourse = '';
            this.courseOptions = [];
            this.selectedLocation = '';
            this.selectedAttendanceType = '';
            this.selectedAttendanceMode = '';
            this.offCampusArrangements = '';
            this.showOffCampusNotes = false;
            this.showPartTimeNotes = false;
        }else if(field == 'Faculty'){
            this.academicUnit = '';
            this.selectedCourse = '';
            this.selectedLocation = '';
            this.selectedAttendanceType = '';
            this.selectedAttendanceMode = '';
            this.offCampusArrangements = '';
            this.showOffCampusNotes = false;
            this.showPartTimeNotes = false;
        }else if(field == 'AcademicUnit'){
            this.selectedCourse = '';
            this.selectedLocation = '';
            this.selectedAttendanceType = '';
            this.selectedAttendanceMode = '';
            this.offCampusArrangements = '';
            this.showOffCampusNotes = false;
            this.showPartTimeNotes = false;
        }else if(field == 'Course'){
            this.selectedLocation = '';
            this.selectedAttendanceType = '';
            this.selectedAttendanceMode = '';
            this.offCampusArrangements = '';
            this.showOffCampusNotes = false;
            this.showPartTimeNotes = false;
        }else if(field == 'Campus'){
            this.selectedAttendanceType = '';
            this.selectedAttendanceMode = '';
            this.offCampusArrangements = '';
            this.showOffCampusNotes = false;
            this.showPartTimeNotes = false;
        }else if(field == 'AttendanceType'){
            this.selectedAttendanceMode = '';
            this.offCampusArrangements = '';
            this.showOffCampusNotes = false;
        }else if(field == 'AttendanceMode'){
            this.offCampusArrangements = '';
        }
    }


    //Get course attempts for scholarship only application
    @wire(getCourseAttempts, {contactId:'$contactId'})
    courseAttempValues({ error, data }) {
        // If data is returned from the wire function
        if (data) {
            // Map the data to an array of options
            this.courseAttempOptions = data.map(option => {
                return {
                    label: option.label,
                    value: option.value
                };
            });

        }
        // If there is an error
        else if (error) {
            // Log the error to the console
            console.error(error);
        }
    }

    //Get course attempt details
    getCourseAttemptDetails(){
        if(this.courseAttemptId) {
            var action = getCourseAttemptsDetails;
            action({
                "attemptId": this.courseAttemptId
            }).then(response => {
                var objResponse = response;

                this.facultyName = objResponse.CourseAttempts.Course__r.Faculty__r.Name;
                this.courseOfferingFacultyId = objResponse.CourseAttempts.Course__r.Faculty__c;
                this.courseTitle = objResponse.CourseAttempts.Application_Course_Preference__r.Course_Code__c +' - '+ objResponse.CourseAttempts.Application_Course_Preference__r.Course_Title__c;
                this.selectedLocation = objResponse.CourseAttempts.Application_Course_Preference__r.Location_Code__c;
                this.selectedAttendanceTypeDesc = objResponse.CourseAttempts.Application_Course_Preference__r.Attendance_Type_Description__c;
              
                this.selectedAttendanceType = objResponse.CourseAttempts.Application_Course_Preference__r.Attendance_Type__c;
                if(this.selectedAttendanceType == 'PT'){
                    this.showChangeToFullTime = true;
                }
                
                this.selectedAttendanceMode = objResponse.CourseAttempts.Application_Course_Preference__r.Attendance_Mode__c;
                if(this.selectedAttendanceMode == 'EX'){
                    this.selectedAttendanceModeDesc = 'External (off-campus)';
                    this.showChangeToInternal = true;
                }
                if(this.selectedAttendanceMode == 'IN'){
                    this.selectedAttendanceModeDesc = 'Internal (on-campus)';
                }
                this.selectedCourse = objResponse.CourseAttempts.Application_Course_Preference__r.Course_Code__c+"="+objResponse.CourseAttempts.Application_Course_Preference__r.Course_Title__c;
                this.selectedCourseSCH = objResponse.CourseAttempts.Course__c; 
                this.parentAppId = objResponse.CourseAttempts.Application_Course_Preference__r.Application__c;

                if(objResponse.CourseAttempts.Application_Course_Preference__r.Course_Offering__r.Course_Type__c == '03'){
                    this.showUpgradeToMaster = true;
                }
                
            });
        }
    }

    //check if commencement date is within rounds depending on the application type
    validateCommencementDate(val){
        let dateCmp = this.template.querySelector(".dateCmp");
        let dateVal = dateCmp.value;
        
        var pcDate = new Date(dateVal);
        pcDate.setHours(0, 0, 0, 0);
        
        var dateToday = new Date();
        dateToday.setHours(0, 0, 0, 0);
        
        var tom = new Date(dateToday);
        tom.setDate(dateToday.getDate()+1);
        tom.setHours(0, 0, 0, 0);
        var valid = true;
        if(this.isAdmissionOnly){
            var earlyDate = new Date();
            earlyDate.setHours(0, 0, 0, 0);
            var latestDate = new Date(earlyDate.setMonth(earlyDate.getMonth() + 7));
            latestDate.setHours(0, 0, 0, 0);
            if(pcDate >= tom && pcDate <= latestDate){
                valid = true;
                dateCmp.setCustomValidity("");
            }else{
                dateCmp.setCustomValidity("Please select a date from tomorrow or a date within 7 months from today.");
                valid = false;
            }
            dateCmp.reportValidity();
        }

        if(this.isAdmissionScholarship){
            let earlyPCDate = new Date(this.earlyComDate);
            earlyPCDate.setHours(0, 0, 0, 0);
            let latestPCDate = new Date(this.latestComDate);
            latestPCDate.setHours(0, 0, 0, 0);
            let earliestPosDate = new Date(this.earliestPossibleDate);
            earliestPosDate.setHours(0, 0, 0, 0);
            let errMessage  = 'Please select a date later than today and later than ' +this.earliestPossibleDateText+ ', or dates within the Scholarship round commencement date.';
            if(pcDate <= dateToday){
                dateCmp.setCustomValidity(errMessage);
                valid = false;
            }else if(pcDate > latestPCDate){
                dateCmp.setCustomValidity(errMessage);
                valid = false;
            }else if(pcDate >= earliestPosDate && pcDate < dateToday){
                dateCmp.setCustomValidity(errMessage);
                valid = false;
            }else if(pcDate >= dateToday && pcDate < earliestPosDate){
                dateCmp.setCustomValidity(errMessage);
                valid = false;
            }else if(pcDate >= earliestPosDate && pcDate < earlyPCDate){
                dateCmp.setCustomValidity("");
                this.showPCDateError = true;
                this.earlyDateSelected = true;
                valid = true;
            }else{
                valid = true;
                this.showPCDateError = false;
                dateCmp.setCustomValidity("");
            }
            dateCmp.reportValidity();

        }

        if(valid){
            this.validCommencementDate = true;
            this.getScholarshipRoundsBasedOnProposedDate();
            this.getCandidatureCalendar();
        }else{
            this.validCommencementDate = false;
        }
    }

    cancelPCDateError(event) {
        this.showPCDateError = false;
        this.proposedCommencementDate = null;
    }


    confirmEarlyCommencementDate(event){
        this.acceptOfferPriorToShcolarshipFlag = true;
        this.showPCDateError = false;
    }

    
    onClickCloseErrors(){
        this.showErrors = false
    }
}