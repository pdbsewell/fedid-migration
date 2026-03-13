import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { updateRecord } from 'lightning/uiRecordApi';
import retrieveAcpDetailsAndCourseOfferings from '@salesforce/apex/ApplicationCoursePreferenceWizard.retrieveAcpDetailsAndCourseOfferings';
import searchCourseOfferingsEdit from '@salesforce/apex/ApplicationCoursePreferenceWizard.searchCourseOfferingsEdit';
import editAcpContinuation from '@salesforce/apexContinuation/ApplicationCoursePreferenceWizard.editAcpContinuation';

export default class editApplicationCoursePreferenceWizard extends NavigationMixin(LightningElement) {
    @api acpId;
    @api selectedCitizenshipType;
    @track firstAcp;
    @track currentCourseOffering;
    @track courseOfferings;
    @track selectedOffering;
    @track selectedYear;
    @track selectedSemester;
    @track dataLoaded;
    @track loadedCourseOfferings;
    @track filteredCourseOfferings;
    @track showedCourseOfferings;
    @track searchFilter;
    @track delayTimeout;
    @track isSearching;
    @track maxDisplayLimitCount;
    @track leastSearchTextLimitCount;
    @track latestChanged;
    @track editAcpDisabled; 
    @track showConfirmation;
    @track isSubmittingACP;
    @track message;

    @track courseDisabled;
    @track calendarDisabled;
    @track admissionCategoryDisabled;

    @track currentIsShown;
    @track currentCourseOfferingId;

    get selectedOfferingAttendanceType(){
        return this.convertAttendanceTypeName(this.firstAcp.Attendance_Type__c);
    }
    get selectedOfferingAttendanceMode(){
        return this.convertAttendanceModeName(this.selectedOffering.Attendance_Mode__c);
    }

    /* Constructor after the component is hooked on the parent component */
    connectedCallback() {
        //Retrieve application and course offering records on server acpId
        this.maxDisplayLimitCount = 10;
        this.leastSearchTextLimitCount = 2;
        this.dataLoaded = false;
        this.editAcpDisabled = true;
        this.filteredCourseOfferings = [];
        this.showConfirmation = false;
        this.isSubmittingACP = false;

        //retrieve details from server
        retrieveAcpDetailsAndCourseOfferings({
            acpId : this.acpId
        })
        .then(result => {
            this.firstAcp = result.ApplicationCoursePreference;

            //Set default citizenship type
            this.selectedCitizenshipType = this.firstAcp.Application__r.Residency_Status__c;

            //Set admission year
            this.selectedAdmissionYear = (this.firstAcp.Course_Offering__r.Academic_Year__c).toString(10);

            //Set attendance mode and type
            this.selectedAttendanceModeType = this.buildAttendanceTypeMode(this.firstAcp.Attendance_Type__c, this.firstAcp.Attendance_Mode__c);

            //Set current course offering
            this.currentCourseOffering = result.CurrentCourseOffering;
            this.currentCourseOfferingId = this.currentCourseOffering.Id;

            //Reset filter fields
            this.reset();
            
            //Set current details
            this.selectedCourse = this.firstAcp.Course_Offering__r.Course_Code__c + ' - ' + this.firstAcp.Course_Offering__r.Course_Title__c; 
            this.selectedCalendar = this.firstAcp.Course_Offering__r.Admission_Calendar_Description__c;
            this.selectedAdmissionCategory = this.firstAcp.Course_Offering__r.Admission_Category__c;
            this.selectedLocation = this.firstAcp.Course_Offering__r.Location_Code__c;
            this.selectedUnitSet = (this.firstAcp.Course_Offering__r.Unit_Set_Code__c ? this.firstAcp.Course_Offering__r.Unit_Set_Code__c + (this.firstAcp.Course_Offering__r.Unit_Set_Description__c ?  ' - ' + this.firstAcp.Course_Offering__r.Unit_Set_Description__c : '') : '');

            //Disable fields
            this.courseDisabled = true;
            this.calendarDisabled = true;
            this.admissionCategoryDisabled = true;

            this.searchFilter = {
                citizenshipType : this.selectedCitizenshipType,
                admissionYear : this.selectedAdmissionYear,
                attendanceMode : this.findAttendanceMode(this.selectedAttendanceModeType),
                attendanceType : this.findAttendanceType(this.selectedAttendanceModeType),
                course : this.selectedCourse,
                calendar : this.selectedCalendar,
                admissionCategory : this.selectedAdmissionCategory,
                location : this.selectedLocation,
                unitSet : this.selectedUnitSet,
                version : this.selectedVersion
            };

            //Retrieve and format course offering records
            this.formatCourseOfferings(result.CourseOfferings);

            //Ready the form
            this.dataLoaded = true;
        })
        .catch((error) => {
            this.message = 'Error received: ' + JSON.stringify(error);
        });
    }

    //Call when elements are ready
    @track initialized = false;
    @track hasAutoFocused = false;
    renderedCallback(){     
        if (this.initialized) {
            return;
        }

        if(!this.hasAutoFocused){  
            let thisContent = this;
            //Auto focus course field            
            //Iterate through each file child then send data to the correct one
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(function(){ 
                thisContent.template.querySelectorAll("c-input-type-ahead").forEach(function(element) {
                    if(element.name === 'course'){                        
                        element.focus();
                        thisContent.hasAutoFocused = true;
                    }
                });            
            }, 500);
        }
    }

    //retrieve details from server
    retrieveAllDetails(){
        //retrieve details from server
        searchCourseOfferingsEdit({
            citizenshipType : this.selectedCitizenshipType,
            attendanceMode : this.findAttendanceMode(this.selectedAttendanceModeType),
            attendanceType : this.findAttendanceType(this.selectedAttendanceModeType),
            academicYear : this.selectedAdmissionYear,
            courseCode : this.selectedCourse.split(' - ')[0],
            courseTitle : this.selectedCourse.split(' - ')[1],
            admissionCalendarDescription : this.selectedCalendar,
            admissionCategory : this.selectedAdmissionCategory
        })
        .then(result => {
            //Reset filter fields
            this.reset();
            //Retrieve and format course offering records
            this.formatCourseOfferings(result);

            //Ready the form
            this.dataLoaded = true;
        })
        .catch((error) => {
            this.message = 'Error received: ' + JSON.stringify(error);
        });        
    }

    //build search criteria
    filterCourseOfferings(){
        let thisContent = this;
        this.isSearching = true;

        //clear day
        clearTimeout(thisContent.delayTimeout);

        //start delay
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        thisContent.delayTimeout = setTimeout(function () {
            //preset filters
            switch(thisContent.latestChanged) {
                case 'course':
                    //clear options
                    //thisContent.searchFilter.calendar = '';
                    //thisContent.searchFilter.admissionCategory = '';
                    thisContent.searchFilter.location = '';
                    thisContent.searchFilter.unitSet = '';
                    thisContent.searchFilter.version = '';
                    //clear options
                    //thisContent.selectedCalendar = '';
                    //thisContent.selectedAdmissionCategory = '';
                    thisContent.selectedLocation = '';
                    thisContent.selectedUnitSet = '';
                    thisContent.selectedVersion = '';
                    break;
                case 'calendar':
                    //clear options
                    //thisContent.searchFilter.admissionCategory = '';
                    thisContent.searchFilter.location = '';
                    thisContent.searchFilter.unitSet = '';
                    thisContent.searchFilter.version = '';
                    //clear options
                    //thisContent.selectedAdmissionCategory = '';
                    thisContent.selectedLocation = '';
                    thisContent.selectedUnitSet = '';
                    thisContent.selectedVersion = '';
                    break;
                case 'admissionCategory':
                    //clear options
                    thisContent.searchFilter.location = '';
                    thisContent.searchFilter.unitSet = '';
                    thisContent.searchFilter.version = '';
                    //clear options
                    thisContent.selectedLocation = '';
                    thisContent.selectedUnitSet = '';
                    thisContent.selectedVersion = '';
                    break;
                case 'location':
                    //clear options
                    thisContent.searchFilter.unitSet = '';
                    thisContent.searchFilter.version = '';
                    //clear options
                    thisContent.selectedUnitSet = '';
                    thisContent.selectedVersion = '';
                    break;
                case 'unitSet':
                    //clear options
                    thisContent.searchFilter.version = '';
                    //clear options
                    thisContent.selectedVersion = '';
                    break;
                case 'version':
                    break
                default:
            }

            //start filtering
            let filterOfferings = thisContent.loadedCourseOfferings.filter(function(courseOffering) {
                let isMatch = true;

                //filter by courses
                if(thisContent.searchFilter.course !== ''){
                    let courseCodeTitle = courseOffering.Course_Code__c.toLowerCase() + ' - ' + courseOffering.Course_Title__c.toLowerCase();
                    if(!courseCodeTitle.includes(thisContent.searchFilter.course.toLowerCase())){
                        isMatch = false;
                    }
                }

                //filter by calendar           
                if(thisContent.searchFilter.calendar !== ''){
                    if(!courseOffering.Admission_Calendar_Description__c.toLowerCase().includes(thisContent.searchFilter.calendar.toLowerCase())){
                        isMatch = false;
                    }
                }

                //filter by admission category
                if(thisContent.searchFilter.admissionCategory !== ''){
                    if(!courseOffering.Admission_Category__c.toLowerCase().includes(thisContent.searchFilter.admissionCategory.toLowerCase())){
                        isMatch = false;
                    }
                }    
                
                //filter by location
                if(thisContent.searchFilter.location !== ''){
                    if(!courseOffering.Location_Code__c.toLowerCase().includes(thisContent.searchFilter.location.toLowerCase())){
                        isMatch = false;
                    }
                } 

                //filter by unit set
                if(thisContent.searchFilter.unitSet !== ''){
                    //default to not matched if value undefined
                    if(courseOffering.Unit_Set_Code__c === undefined){
                        isMatch = false;
                    }else{
                        let courseUnitSet = courseOffering.Unit_Set_Code__c.toLowerCase() + ' - ' + courseOffering.Unit_Set_Description__c.toLowerCase();
                        if(!courseUnitSet.includes(thisContent.searchFilter.unitSet.toLowerCase())){
                            isMatch = false;
                        }
                    }
                }

                //filter by version
                if(thisContent.searchFilter.version !== ''){
                    //default to not matched if value undefined
                    if(courseOffering.Unit_Set_Version__c === undefined){
                        isMatch = false;
                    }else{
                        if(!courseOffering.Unit_Set_Version__c.toString(10).toLowerCase().includes(thisContent.searchFilter.version.toLowerCase())){
                            isMatch = false;
                        }
                    }
                } 

                return isMatch;
            }, thisContent);

            thisContent.isSearching = false;
            thisContent.filteredCourseOfferings = filterOfferings;

            let counter = 0;
            let maxDisplayLimit = thisContent.maxDisplayLimitCount;

            let showedOfferings = [];
            filterOfferings.forEach(function(element) {  
                if(thisContent.currentCourseOffering.Id === element.Id){
                    thisContent.currentIsShown = true;
                }
                if(thisContent.currentCourseOffering.Id !== element.Id){
                    if(counter < maxDisplayLimit){
                        showedOfferings.push(element);
                        counter = counter + 1;                
                    }
                }
            });
            thisContent.showedCourseOfferings = showedOfferings;

            //Build filters
            switch(thisContent.latestChanged) {
                case 'course':
                    //rebuild options
                    thisContent.buildCalendarOption();
                    thisContent.buildAdmissionCategoryOption();
                    thisContent.buildLocationOption();
                    thisContent.buildUnitSetOption();
                    thisContent.buildVersionOption();
                    break;
                case 'calendar':
                    //rebuild options
                    thisContent.buildAdmissionCategoryOption();
                    thisContent.buildLocationOption();
                    thisContent.buildUnitSetOption();
                    thisContent.buildVersionOption();
                    break;
                case 'admissionCategory':
                    //rebuild options
                    thisContent.buildLocationOption();
                    thisContent.buildUnitSetOption();
                    thisContent.buildVersionOption();
                    break;
                case 'location':
                    //rebuild options
                    thisContent.buildUnitSetOption();
                    thisContent.buildVersionOption();
                    break;
                case 'unitSet':
                    //rebuild options
                    thisContent.buildVersionOption();
                    break;
                case 'version':
                    break;
                default:
            }

            //clear selections
            thisContent.clearSelectedResults();
        }, 750);
    }

    //clear selected course offerings
    clearSelectedResults(){
        //Iterate through result child then unselect necessary records
        this.template.querySelectorAll("c-add-application-course-preference-wizard-result").forEach(function(element) {  
            element.unselectCard();
        });
        this.selectedOffering = undefined;
        this.selectedYear = undefined;
        this.selectedSemester = undefined;
        this.editAcpDisabled = true;
    }

    //Check if there are search results
    get hasSearchResult() {
        return this.filteredCourseOfferings.length > 0 || this.currentIsShown;
    }

    //Check if there are search results
    get searchLength() {
        let resultMessage;
        if(this.filteredCourseOfferings.length === 1){
            resultMessage = this.thousandsSeparators(this.filteredCourseOfferings.length) + ' result found';
        }else{
            resultMessage = this.thousandsSeparators(this.filteredCourseOfferings.length) + ' results found';
        }
        return resultMessage;
    }

    //Format with thousand separator
    thousandsSeparators(num){
        var num_parts = num.toString().split(".");
        num_parts[0] = num_parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",");
        return num_parts.join(".");
    }

    //Check if there are search results are more than 100
    get isLargeResults() {
        return this.filteredCourseOfferings.length > this.maxDisplayLimitCount;
    }

    //large result message
    get largeResultMessage() {
        return 'Showing ' + this.maxDisplayLimitCount +' / ' + this.thousandsSeparators(this.searchLength) + ' - Please apply more filter criteria to narrow your search';
    }
    
    /* default filter fields */
    reset(){
        //Default fields
        //this.selectedCourse = '';
        //this.selectedCalendar = '';
        //this.selectedAdmissionCategory = '';
        this.selectedLocation = '';
        this.selectedUnitSet = '';
        this.selectedVersion = '';
    }

    /* format data */
    formatCourseOfferings(courseOfferings){
        let thisContent = this;
        let counter = 0;
        let maxDisplayLimit = this.maxDisplayLimitCount;

        let offerings = [];
        let filterOfferings = [];
        let showedOfferings = [];
        courseOfferings.forEach(function(element) { 
            if(thisContent.currentCourseOffering.Id === element.Id){
                thisContent.currentIsShown = true;
            }
            if(thisContent.currentCourseOffering.Id !== element.Id){
                offerings.push(element);
                filterOfferings.push(element);

                if(counter < maxDisplayLimit){
                    showedOfferings.push(element);
                    counter = counter + 1;                
                }
            }
        });
        this.loadedCourseOfferings = offerings;
        this.filteredCourseOfferings = filterOfferings;
        this.showedCourseOfferings = showedOfferings;

        //Build filters
        this.buildCalendarOption();
        this.buildAdmissionCategoryOption();
        this.buildLocationOption();
        this.buildUnitSetOption();
        this.buildVersionOption();
    }

    /* remove duplicates */
    removeDuplicates(collection) {
        return collection.filter(function(item, index){
            return collection.indexOf(item) >= index;
        });
    }

    /* for converting attendance type and mode friendly name */
    buildAttendanceTypeMode(attendanceType, attendanceMode){
        return this.convertAttendanceTypeName(attendanceType) + ' - ' + this.convertAttendanceModeName(attendanceMode);
    }

    /* for converting attendance mode friendly name */
    convertAttendanceModeName(attendanceMode){
        let name;
        switch(attendanceMode) {
            case 'IN':
                name = 'On Campus';
                break;
            case 'EX':
                name = 'Off Campus';
                break;
            case 'MO':
                name = 'Online';
                break;
            case 'MM':
                name = 'Multi Modal';
                break;
            default:
        }

        return name;
    }

    /* get attendance mode from attendance mode type */
    findAttendanceMode(attendanceModeType){
        let attendanceMode = attendanceModeType.split(' - ')[1];
        switch(attendanceMode) {
            case 'On Campus':
                attendanceMode = 'IN';
                break;
            case 'Off Campus':
                attendanceMode = 'EX';
                break;
            case 'Online':
                attendanceMode = 'MO';
                break;
            case 'Multi Modal':
                attendanceMode = 'MM';
                break;
            default:
        }
        return attendanceMode;
    }

    /* for converting attendance type friendly name */
    convertAttendanceTypeName(attendanceType){
        let name;
        switch(attendanceType) {
            case 'FT':
                name = 'Full time';
                break;
            case 'PT':
                name = 'Part time';
                break;
            default:
        }

        return name;
    }

    /* get attendance type from attendance mode type */
    findAttendanceType(attendanceModeType){
        let attendanceType = attendanceModeType.split(' - ')[0];
        switch(attendanceType) {
            case 'Full time':
                attendanceType = 'FT';
                break;
            case 'Part time':
                attendanceType = 'PT';
                break;
            default:
        }
        return attendanceType;
    }

    /* admission year */
    @api selectedAdmissionYear;
    get admissionYearOption() {
        let checklistOptions = [];

        let currentYear = new Date();
        for(let yearCounter = currentYear.getFullYear(); yearCounter < currentYear.getFullYear() + 4; yearCounter++){
            checklistOptions.push({ 
                label: yearCounter.toString(10), 
                value: yearCounter.toString(10)
            });
        }

        return checklistOptions;
    }
    handleAdmissionChange(event) {        
        let newValue = event.detail.value;
        if(this.selectedAdmissionYear !== newValue){
            //Reset filter fields
            this.reset();
            this.filteredCourseOfferings = [];
        }
        this.selectedAdmissionYear = newValue;

        //Clear attendance mode on change
        this.selectedAttendanceModeType = '';
    }

    /* attendance mode & type */
    @api selectedAttendanceModeType;
    get attendanceModeTypeOption() {
        let checklistOptions = [];
        checklistOptions.push({ label: 'Full time - On Campus', value: 'Full time - On Campus' });
        checklistOptions.push({ label: 'Full time - Off Campus', value: 'Full time - Off Campus' });
        checklistOptions.push({ label: 'Full time - Online', value: 'Full time - Online' });
        checklistOptions.push({ label: 'Full time - Multi Modal', value: 'Full time - Multi Modal' });
        checklistOptions.push({ label: 'Part time - On Campus', value: 'Part time - On Campus' });
        checklistOptions.push({ label: 'Part time - Off Campus', value: 'Part time - Off Campus' });
        checklistOptions.push({ label: 'Part time - Online', value: 'Part time - Online' });    
        checklistOptions.push({ label: 'Part time - Multi Modal', value: 'Part time - Multi Modal' });    

        return checklistOptions;
    }
    handleAttendanceModeTypeChange(event) {
        this.selectedAttendanceModeType = event.detail.value;

        //retrieve details from server
        this.dataLoaded = false;
        this.retrieveAllDetails();
    }

    /***************************** course start *****************************/
    @api selectedCourse;
    get courseOption() {
        let checklistOptions = [];
        let courseCodes = this.loadedCourseOfferings.map(function (courseOffering) {
            return courseOffering.Course_Code__c + ' - ' + courseOffering.Course_Title__c;
        });
        
        let uniqueCourseCodes = this.removeDuplicates(courseCodes);

        //Retrieve options
        uniqueCourseCodes.forEach(function(courseCodeTitle) {
            //Include course options
            if(courseCodeTitle !== undefined){
                checklistOptions.push({ 
                    label: courseCodeTitle, 
                    value: courseCodeTitle
                });            
            }
        });

        return checklistOptions;
    }
    handleCourseChange(event) {
        let thisContent = this;

        //on change pass focus to calendar
        if(event.detail.value !== ''){
            thisContent.template.querySelectorAll("c-input-type-ahead").forEach(function(element) {
                if(element.name === 'calendar'){                        
                    element.focus();
                }
            });  
        }

        //do filter
        this.changeCourse(event);
    }
    handleCourseKeyUp(event) {
        this.changeCourse(event);
    }
    changeCourse(event){
        let newValue = event.detail.value;
        if(newValue !== undefined){
            //detect changes
            let hasChanged = false;
            if(this.selectedCourse !== newValue){
                hasChanged = true;
            }
            //assign new value
            this.selectedCourse = newValue;

            //check if new value has more than 3 characters or no characters before filtering
            if(newValue.length > this.leastSearchTextLimitCount || newValue.length === 0){
                //continue filtering if changes were detected
                if(hasChanged){
                    this.searchFilter.course = this.selectedCourse;
                    this.latestChanged = 'course';
                    this.filterCourseOfferings();
                }
            }
        }
    }
    /***************************** course end *****************************/

    /***************************** calendar start *****************************/
    @api selectedCalendar;
    @api calendarOption;
    buildCalendarOption() {
        let checklistOptions = [];
        let courseCalendars = this.filteredCourseOfferings.map(function (courseOffering) {
            return courseOffering.Admission_Calendar_Description__c;
        });
        
        let uniqueCourseCalendars = this.removeDuplicates(courseCalendars);

        //Retrieve options
        uniqueCourseCalendars.forEach(function(courseCalendar) {
            //Include course options
            if(courseCalendar !== undefined){
                checklistOptions.push({ 
                    label: courseCalendar, 
                    value: courseCalendar
                });            
            }
        });

        this.calendarOption = checklistOptions;
    }
    handleCalendarChange(event) {
        let thisContent = this;

        //on change pass focus to calendar
        if(event.detail.value !== ''){
            thisContent.template.querySelectorAll("c-input-type-ahead").forEach(function(element) {
                if(element.name === 'admissionCategory'){                        
                    element.focus();
                }
            });  
        }

        //do filter
        this.calendarChange(event);
    }
    handleCalendarKeyUp(event) {
        this.calendarChange(event);
    }
    calendarChange(event) {
        let newValue = event.detail.value;
        if(newValue !== undefined){     
            //detect changes
            let hasChanged = false;
            if(this.selectedCalendar !== newValue){
                hasChanged = true;
            }
            //assign new value
            this.selectedCalendar = newValue;

            //check if new value has more than 3 characters or no characters before filtering
            if(newValue.length > this.leastSearchTextLimitCount || newValue.length === 0){
                //continue filtering if changes were detected
                if(hasChanged){
                    this.searchFilter.calendar = this.selectedCalendar;
                    this.latestChanged = 'calendar';
                    this.filterCourseOfferings();
                }
            }
        }
    }
    /***************************** calendar end *****************************/

    /***************************** admission category start *****************************/
    @api selectedAdmissionCategory;
    @api admissionCategoryOption;
    buildAdmissionCategoryOption() {
        let checklistOptions = [];
        let courseAdmissionCategories = this.filteredCourseOfferings.map(function (courseOffering) {
            return courseOffering.Admission_Category__c;
        });
        
        let uniqueCourseAdmissionCategories = this.removeDuplicates(courseAdmissionCategories);

        //Retrieve options
        uniqueCourseAdmissionCategories.forEach(function(courseAdmissionCategory) {
            //Include course options
            if(courseAdmissionCategory !== undefined){
                checklistOptions.push({ 
                    label: courseAdmissionCategory, 
                    value: courseAdmissionCategory
                });          
            }  
        });

        this.admissionCategoryOption = checklistOptions;
    }
    handleAdmissionCategoryChange(event) {
        let thisContent = this;

        //on change pass focus to calendar
        if(event.detail.value !== ''){
            thisContent.template.querySelectorAll("c-input-type-ahead").forEach(function(element) {
                if(element.name === 'location'){                        
                    element.focus();
                }
            });  
        }

        //do filter
        this.admissionCategoryChange(event);
    }
    handleAdmissionCategoryKeyUp(event) {
        this.admissionCategoryChange(event);
    }
    admissionCategoryChange(event) {
        let newValue = event.detail.value;
        if(newValue !== undefined){       
            //detect changes
            let hasChanged = false;
            if(this.selectedAdmissionCategory !== newValue){
                hasChanged = true;
            }
            //assign new value
            this.selectedAdmissionCategory = newValue;
            //check if new value has more than 3 characters or no characters before filtering
            if(newValue.length > this.leastSearchTextLimitCount || newValue.length === 0){
                //continue filtering if changes were detected
                if(hasChanged){
                    this.searchFilter.admissionCategory = this.selectedAdmissionCategory;
                    this.latestChanged = 'admissionCategory';
                    this.filterCourseOfferings();
                }
            }
        }
    }
    /***************************** admission category end *****************************/

    /***************************** location start *****************************/
    @api selectedLocation;
    @api locationOption;
    buildLocationOption() {
        let checklistOptions = [];
        let courseLocations = this.filteredCourseOfferings.map(function (courseOffering) {
            return courseOffering.Location_Code__c;
        });
        
        let uniqueCourseLocations = this.removeDuplicates(courseLocations);

        //Retrieve options
        uniqueCourseLocations.forEach(function(courseLocation) {
            //Include course options
            if(courseLocation !== undefined){
                checklistOptions.push({ 
                    label: courseLocation,
                    value: courseLocation
                });            
            }
        });

        this.locationOption = checklistOptions;
    }
    handleLocationChange(event) {
        let thisContent = this;

        //on change pass focus to calendar
        if(event.detail.value !== ''){
            thisContent.template.querySelectorAll("c-input-type-ahead").forEach(function(element) {
                if(element.name === 'unitSet'){                        
                    element.focus();
                }
            }); 
        } 

        //do filter
        this.locationChange(event);
    }
    handleLocationKeyUp(event) {
        this.locationChange(event);
    }
    locationChange(event) {
        let newValue = event.detail.value;
        if(newValue !== undefined){      
            //detect changes  
            let hasChanged = false;
            if(this.selectedLocation !== newValue){
                hasChanged = true;
            }
            //assign new value
            this.selectedLocation = newValue;
            //check if new value has more than 3 characters or no characters before filtering
            if(newValue.length > this.leastSearchTextLimitCount  || newValue.length === 0){
                //continue filtering if changes were detected
                if(hasChanged){
                    this.searchFilter.location = this.selectedLocation;
                    this.latestChanged = 'location';
                    this.filterCourseOfferings();
                }
            }
        }
    }
    get locationDisabled() {
        return !this.selectedCitizenshipType || !this.selectedAdmissionYear || !this.selectedAttendanceModeType;
    }
    /***************************** location end *****************************/

    /***************************** unit set start *****************************/
    @api selectedUnitSet;
    @api unitSetOption;
    buildUnitSetOption() {
        let checklistOptions = [];
        let courseUnitSets = this.filteredCourseOfferings.map(function (courseOffering) {
            return courseOffering.Unit_Set_Code__c + ' - ' + courseOffering.Unit_Set_Description__c;
        });
        
        let uniqueCourseUnitSets = this.removeDuplicates(courseUnitSets);

        //Retrieve options
        uniqueCourseUnitSets.forEach(function(courseUnitSet) {
            //Include course options
            if(!courseUnitSet.includes('undefined')){
                checklistOptions.push({ 
                    label: courseUnitSet,
                    value: courseUnitSet
                });        
            }    
        });

        this.unitSetOption = checklistOptions;
    }
    handleUnitSetChange(event) {
        let thisContent = this;

        //on change pass focus to calendar
        if(event.detail.value !== ''){
            thisContent.template.querySelectorAll("c-input-type-ahead").forEach(function(element) {
                if(element.name === 'version'){                        
                    element.focus();
                }
            });  
        }

        //do filter
        this.unitSetChange(event);
    }
    handleUnitSetKeyUp(event) {
        this.unitSetChange(event);
    }
    unitSetChange(event) {
        let newValue = event.detail.value;
        if(event.detail.value !== undefined){     
            //detect changes  
            let hasChanged = false;
            if(this.selectedUnitSet !== newValue){
                hasChanged = true;
            }
            //assign new value
            this.selectedUnitSet = newValue;
            //check if new value has more than 3 characters or no characters before filtering
            if(newValue.length > this.leastSearchTextLimitCount || newValue.length === 0){
                //continue filtering if changes were detected
                if(hasChanged){
                    this.searchFilter.unitSet = this.selectedUnitSet;
                    this.latestChanged = 'unitSet';
                    this.filterCourseOfferings();
                }
            }
        }
    }
    get unitSetDisabled() {
        return !this.selectedCitizenshipType || !this.selectedAdmissionYear || !this.selectedAttendanceModeType;
    }
    /***************************** unit set end *****************************/

    /***************************** version start *****************************/
    @api selectedVersion;
    @api versionOption;
    buildVersionOption() {
        let checklistOptions = [];
        let courseVersions = this.filteredCourseOfferings.map(function (courseOffering) {
            return courseOffering.Unit_Set_Version__c;
        });
        
        let uniqueCourseVersions = this.removeDuplicates(courseVersions);

        //Retrieve options
        uniqueCourseVersions.forEach(function(courseVersion) {
            //Include course options
            if(courseVersion !== undefined){
                checklistOptions.push({ 
                    label: courseVersion.toString(10),
                    value: courseVersion.toString(10)
                });            
            }
        });

        this.versionOption = checklistOptions;
    }
    handleVersionChange(event) {
        this.versionChange(event);
    }
    handleVersionKeyUp(event) {
        this.versionChange(event);
    }
    versionChange(event) {
        let newValue = event.detail.value;
        if(event.detail.value !== undefined){       
            //detect changes  
            let hasChanged = false;
            if(this.selectedVersion !== newValue){
                hasChanged = true;
            }
            //assign new value
            this.selectedVersion = newValue;
            //ignore character check on version
            //continue filtering if changes were detected
            if(hasChanged){
                this.searchFilter.version = this.selectedVersion;
                this.latestChanged = 'version';
                this.filterCourseOfferings();
            }
        }
    }
    get versionDisabled() {
        return !this.selectedCitizenshipType || !this.selectedAdmissionYear || !this.selectedAttendanceModeType;
    }
    /***************************** version end *****************************/

    //action when a result has been selected
    handleSelected(event){
        let thisContent = this;

        if(event.detail.parameters.selected){
            //Iterate through result child then unselect necessary records
            this.template.querySelectorAll("c-add-application-course-preference-wizard-result").forEach(function(element) {  
                if(element.courseOffering.Id !== event.detail.parameters.courseOfferingId){
                    element.unselectCard();
                }else{
                    thisContent.selectedOffering = element.courseOffering;
                    let calendarDescription = thisContent.selectedOffering.Admission_Calendar_Description__c.split(' ')
                    thisContent.selectedYear = calendarDescription[0];
                    
                    //remove first element
                    calendarDescription.shift()
                    thisContent.selectedSemester = calendarDescription.join(' ');
                }
            });
            this.editAcpDisabled = false;
        }else{
            thisContent.selectedOffering = undefined;
            thisContent.selectedYear = undefined;
            thisContent.selectedSemester = undefined;
            this.editAcpDisabled = true;
        }
    }

    //close form
    handleCancel(){
        const action = 'close';
        //request subtab to be closed
        const dispatchEvent = new CustomEvent('requestclose', {
            detail: { action }
        });
        this.dispatchEvent(dispatchEvent);
    }

    //default filters
    handleDefault(){
        //retrieve details from server
        retrieveAcpDetailsAndCourseOfferings({
            acpId : this.acpId
        })
        .then(result => {
            this.firstAcp = result.ApplicationCoursePreference;

            //Set default citizenship type
            this.selectedCitizenshipType = this.firstAcp.Application__r.Residency_Status__c;

            //Set admission year
            this.selectedAdmissionYear = (this.firstAcp.Course_Offering__r.Academic_Year__c).toString(10);

            //Set attendance mode and type
            this.selectedAttendanceModeType = this.buildAttendanceTypeMode(this.firstAcp.Attendance_Type__c, this.firstAcp.Attendance_Mode__c);

            //Set current course offering
            this.currentCourseOffering = result.CurrentCourseOffering;
            this.currentCourseOfferingId = this.currentCourseOffering.Id;

            //Reset filter fields
            this.reset();
            
            //Set current details
            this.selectedCourse = this.firstAcp.Course_Offering__r.Course_Code__c + ' - ' + this.firstAcp.Course_Offering__r.Course_Title__c; 
            this.selectedCalendar = this.firstAcp.Course_Offering__r.Admission_Calendar_Description__c;
            this.selectedAdmissionCategory = this.firstAcp.Course_Offering__r.Admission_Category__c;
            this.selectedLocation = this.firstAcp.Course_Offering__r.Location_Code__c;
            this.selectedUnitSet = (this.firstAcp.Course_Offering__r.Unit_Set_Code__c ? this.firstAcp.Course_Offering__r.Unit_Set_Code__c + (this.firstAcp.Course_Offering__r.Unit_Set_Description__c ?  ' - ' + this.firstAcp.Course_Offering__r.Unit_Set_Description__c : '') : '');

            //Disable fields
            this.courseDisabled = true;
            this.calendarDisabled = true;
            this.admissionCategoryDisabled = true;

            this.searchFilter = {
                citizenshipType : this.selectedCitizenshipType,
                admissionYear : this.selectedAdmissionYear,
                attendanceMode : this.findAttendanceMode(this.selectedAttendanceModeType),
                attendanceType : this.findAttendanceType(this.selectedAttendanceModeType),
                course : this.selectedCourse,
                calendar : this.selectedCalendar,
                admissionCategory : this.selectedAdmissionCategory,
                location : this.selectedLocation,
                unitSet : this.selectedUnitSet,
                version : this.selectedVersion
            };

            //Retrieve and format course offering records
            this.formatCourseOfferings(result.CourseOfferings);

            //Ready the form
            this.dataLoaded = true;
        })
        .catch((error) => {
            this.message = 'Error received: ' + JSON.stringify(error);
        });
    }

    //edit acp record
    editApplicationCourcePreference(){
        try{
            this.isSubmittingACP = true;
            this.editAcpDisabled = true;

            let updateACP = {
                fields: {
                    Id: this.acpId,
                    Course_Offering__c: this.selectedOffering.Id
                },
            };
            //revert course offering state
            updateRecord(updateACP)
            .then(() => {
                //Show error
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Course Offering successfully updated',
                        message: 'Successfully associated the selected Course Offering to the Application Course Preference.',
                        variant: 'success'
                    })
                );  
                this.isSubmittingACP = false;
                this.showConfirmation = false;
                this.handleDefault();
            })
            .catch(error => {
                this.message = JSON.stringify(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'There was an issue on updating the Application Course Preference.',
                        variant: 'error',
                    }),
                );
            });
        }catch(ex){
            console.log(ex);
        }
    }
    
    //edit acp record
    editApplicationCourcePreferenceContinuation(){
        let thisContext = this;
        this.isSubmittingACP = true;
        this.editAcpDisabled = true;

        //retrieve details from server
        editAcpContinuation({
            acpId : this.acpId,
            newCourseOfferingId : this.selectedOffering.Id
        }).then(result => {
            //catch no adm key error
            if(result === null){
                //Show error
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Unable to add the ACP record as there is no Person ID/ADM key for ' + thisContext.acpId,
                        variant: 'error',
                        mode: 'sticky'
                    })
                );   
                this.isSubmittingACP = false;
                this.showConfirmation = false;
                this.handleDefault();
            }
            //process results
            if(result.state === 'success'){
                let resultMessage = JSON.parse(result.message);
                if(resultMessage.applications){                        
                    //Show toast for successful status update
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Course Offering successfully updated',
                            message: 'Successfully associated the selected Course Offering to the Application Course Preference.',
                            variant: 'success'
                        })
                    );
                    this.isSubmittingACP = false;
                    this.showConfirmation = false;
                    this.handleDefault();
                }else{
                    let revertRecord = {
                        fields: {
                            Id: thisContext.acpId,
                            Course_Offering__c: thisContext.currentCourseOfferingId
                        },
                    };
                    //revert course offering state
                    updateRecord(revertRecord)
                    .then(() => {
                        //Show error
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: thisContext.parseErrorMessage(resultMessage),
                                variant: 'error',
                                mode: 'sticky'
                            })
                        );   
                        this.isSubmittingACP = false;
                        this.showConfirmation = false;
                        this.handleDefault();
                    })
                    .catch(error => {
                        this.message = JSON.stringify(error);
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: 'Error on reverting the ACP Course Offering.',
                                variant: 'error',
                            }),
                        );
                    });
                }
            }else{
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Salesforce error occured on updating the Application Course Preference.',
                        variant: 'error',
                    }),
                );
            }
        })
        .catch((error) => {
            this.message = 'Error received: ' + JSON.stringify(error);
        });
    }

    //show add acp confirmation modal
    showConfirmationModal(){
        this.showConfirmation = true;
    }

    //show add acp confirmation modal
    hideConfirmationModal(){
        this.showConfirmation = false;
    }

    //parse error message
    parseErrorMessage(resultMessage){
        let errorMessage = '';
        if(resultMessage.errors){
            errorMessage = resultMessage.errors[0].errorDetails;
        }else if(resultMessage.errorDetails){
            if(resultMessage.errorDetails.message){
                errorMessage = resultMessage.message;
            }else{
                errorMessage = resultMessage.errorDetails;
            }
        }else{
            errorMessage = JSON.stringify(resultMessage);
        }
        return errorMessage;
    }
}