import { LightningElement, api, track } from 'lwc';
import USER_ID from '@salesforce/user/Id';
import retrieveHomeDetails from '@salesforce/apex/MyAppHomeServices.retrieveHomeDetails';
import createApplication from '@salesforce/apex/MyAppHomeServices.createApplication';
import fetchMyAppFeatureToggle from '@salesforce/apex/ApplicationNavigationController.fetchMyAppFeatureToggle';
import communityMyAppAssets from '@salesforce/resourceUrl/CommunityMyAppAssets';
import { NavigationMixin } from 'lightning/navigation'; 

//constants for modal popup screen for degree selector
const YES = 'Yes'
const NO = 'No'
const ADDMISSION_AND_SCHOLARSHIP = 'Admission and Scholarship'
const ADDMISSION_APPLICATION_ONLY = 'Admission application only'
const SCHOLARSHIP_APPLICATION_ONLY = 'Scholarship application only'
const ADDMISSION_ONLY = 'Admission only'
const SCHOLARSHIP_ONLY = 'Scholarship only'
const SCREEN_COUNTRY = 'Country'
const SCREEN_STUDY_TYPE = 'StudyType'
const SCREEN_GRAD_RESEARCH_QUALIFIER = 'GradResearch_Qualifier'
const SCREEN_SUMMARY = 'Summary'
const SUB_HEADING_SELECT_LOCATION = 'Select a study location'
const SUB_HEADING_SELECT_STUDY_TYPE = 'Select a study type'
const SUB_HEADING_SELECT_APPLICATION_TYPE = 'Select a type of application'
const SUB_HEADING_EXCHANGE = 'By choosing this option you confirm that you are a current student at an institution overseas, '+
                            'and wish to apply for one or two semesters only. Tuition fees are paid to Monash University, '+
                            'and at the end of your time you will not receive a Monash degree or diploma. '+
                            'The study will usually count towards your degree at your home institution. Is this what you intend?'
const SUB_HEADING_ADDMISSION_AND_SCHOLARSHIP = 'Have you received an invitation to apply for scholarship or candidature?'
const SUB_HEADING_SCHOLARSHIP_ONLY = 'Are you currently enrolled as a Graduate Research student at Monash?'
const SUB_HEADING_GRAD_RESEARCH_END = 'Applications for a research degree are by invitation only. If you do not already have an  '+
                                        'invitation to apply, please read the information we provide on '+
                                        '<a target="_blank" href="https://www.monash.edu/graduate-research/study/apply#:~:text=Submit%20an%20expression%20of%20interest&text=If%20your%20EOI%20is%20successful,application%20guide%20for%20further%20information.">how to obtain an invitation<a/>.'
const SUB_HEADING_SCHOLARSHIP_ONLY_END = 'Scholarship-only applications are only available to students enrolled in a Graduate Research '+
                                        'degree at Monash. If you have an invitation to apply, you may apply for admission and a scholarship at the same time.'
const SUB_HEADING_ECHANGE_END = 'If you are a student from a partner institution wanting to study at Monash University as an exchange '+
                                'student for one or two semesters, please speak to your home institution’s exchange office, they must '+
                                'nominate you to Monash University. <br/> <br/> If you want to study at Monash University to receive a '+
                                'Monash degree or diploma, please return to the home screen and choose another tile that best describes your intention.'
const SUB_HEADING_SCHOLARSHIP_ONLY_NO_COURSE_ATTEMPTS = 'Unfortunately the system hasn\'t recognised you as an active Australian graduate research student. If you believe this is a system error, '+ 
                                                        'or if you have questions regarding graduate research studies, please contact the MGRO team at '+
                                                        '<br/>mgro-apply@monash.edu'

/**
*  @modifier    Vishal Gupta
*  @modified    date 11-07-2024
*  @group       My App Application
*  @description used to show the degree selection on my app student portal 
**/
export default class HomeModal extends NavigationMixin(LightningElement) {
    
    currentScreen
    homeDetails
    userDetails
    isLoading = false;
    courseType = '';
    location = '';
    countryOptions = [{label : '', value: '', imageURL:''}]; 
    sTValue;
    sTOptions = [];
    typeOfApplication 
    qualifierOptions = [YES,NO]
    gradResearchAndExchangeOption = []
    gradResearchApplicationType
    toggleFeatures

    //retrieve static resource images
    iconFileCertificate = communityMyAppAssets + '/images/IconCourses.png';
    iconLanguage = communityMyAppAssets + '/images/IconEnglish.png';
    iconDiploma = communityMyAppAssets + '/images/IconCourses.png';
    iconPlane = communityMyAppAssets + '/images/IconExchange.png';

    countryScreen
    studyTypeScreen
    gradResearchQualifierScreen
    summaryScreen
    qualifierScreen
    blankScreen = false
    isSSOUser = false;
    hasCourseAttempts = false;
    scholarshipOnlyScreenSummaryButton = false;
    hasRendered = false;
    
    connectedCallback() {
        this.isLoading = true
        this.retrieveFeatureToggle()
        this.retrieveUserDetails()        
    }

    /**
    * @description get the feature toggle for Grad Research program
    * @return n/a
    **/
    retrieveFeatureToggle() {
        fetchMyAppFeatureToggle()//getting the feature toggle custom settings
        .then(result => {            
            this.toggleFeatures = result
        }).catch(error => {
            console.log('Error: ' + JSON.stringify(error));
        });        
    }

    /**
    * @description get the study locations and study type for degree selection
    * @return n/a
    **/
    retrieveUserDetails()
    {
        retrieveHomeDetails({ communityUserId : USER_ID })
        .then(constructorResult => {
                       
            this.homeDetails = new Map(Object.entries(constructorResult));
            this.isSSOUser = this.homeDetails.get('IS_SSO_USER');
            var countries = this.homeDetails.get('campusLocations')
            if(!this.toggleFeatures.Graduate_Research__c && !this.homeDetails.get('BYPASS_GRADRES_SWTICH')) {
                countries = countries.filter(function( obj ) {
                    return obj.label !== 'China';
                });                
            } else if(!this.toggleFeatures.Graduate_Research_China__c) {
                countries = countries.filter(function( obj ) {
                    return obj.label !== 'China';
                });
            }

            if(this.isSSOUser && this.toggleFeatures.Scholarship_Application_Only_Enabled_GR__c) {//for sso user only Australia country should be displayed
                countries = countries.filter(function( obj ) {
                    return obj.label == 'Australia';
                });
            }

            this.countryOptions = countries
            this.countryOptions.forEach((element) => {
                element.imageURL = communityMyAppAssets + '/images/'+element.label+'.png'; //retrieve country images from static resource
            })
            this.userDetails = this.homeDetails.get('CURRENT_USER_DETAILS')
            this.setCorrectScreenType(SCREEN_COUNTRY, SUB_HEADING_SELECT_LOCATION)
            this.isLoading = false;
            
            this.hasCourseAttempts = this.homeDetails.get('CourseAttempts');
        }).catch(constructorError => {
            console.log('Error: ' + JSON.stringify(constructorError));
        });
    }
    
    /**
    * @description close the modal screen
    * @return n/a
    **/
    closeAppForm() {
        const cancelEvent = new CustomEvent('cancelappform');
        //Dispatch event
        this.dispatchEvent(cancelEvent);
    }

    /**
    * @description form the study types to show on modal screen 
    * @return n/a
    **/
    getStudyType(studyOptions, bypassGRSwitch) {
        this.sTOptions = []
        let dataMap = studyOptions
        let dataArray = []
        dataMap.forEach( (element) => {
            if(element.label == 'Undergraduate' || element.label == 'Graduate Coursework' || element.label == 'Graduate Research') {
                if(!this.toggleFeatures.Graduate_Research__c && element.label == 'Graduate Research' && !bypassGRSwitch) {
                    return
                }
                element.image = this.iconFileCertificate
            }else if(element.label == 'Diploma') {
                element.image = this.iconDiploma
            } else if (element.label == 'Preparatory Course') {
                element.image = this.iconLanguage
            } else if(element.label == 'Exchange / Study Abroad') {
                element.image = this.iconPlane
            }
            element.value = this.homeDetails.get(element.label)
            dataArray.push(element)
        });
        if(this.isSSOUser && this.toggleFeatures.Scholarship_Application_Only_Enabled_GR__c) {//for sso user only Graduate Research should be displayed
            dataArray = dataArray.filter(function( obj ) {
                return obj.label == 'Graduate Research';
            });
        }
        this.sTOptions = dataArray
        this.setCorrectScreenType(SCREEN_STUDY_TYPE, SUB_HEADING_SELECT_STUDY_TYPE)
    }

    /**
    * @description handle the event for changing the study location
    * @return n/a
    **/
    handleCountryChange(event) {
        this.location = event.currentTarget.dataset.id;
        this.getStudyType(this.homeDetails.get(this.location), this.homeDetails.get('BYPASS_GRADRES_SWTICH'));   
    }

    /**
    * @description toggeling between the different sections of modal based on the current screen type
    * @return n/a
    **/
    handleBack() {
        this.resetScreens()
        switch(this.currentScreen) {
            case SCREEN_COUNTRY : 
                this.currentScreen = ''
                this.closeAppForm()
                break
            case SCREEN_STUDY_TYPE :
                this.countryScreen = true
                this.modalSubHeading = SUB_HEADING_SELECT_LOCATION
                this.currentScreen = SCREEN_COUNTRY
                break
            case SCREEN_GRAD_RESEARCH_QUALIFIER :
                this.studyTypeScreen = true
                this.modalSubHeading = SUB_HEADING_SELECT_STUDY_TYPE
                this.currentScreen = SCREEN_STUDY_TYPE
                break
            case SCREEN_SUMMARY:
                this.studyTypeScreen = true
                this.modalSubHeading = SUB_HEADING_SELECT_STUDY_TYPE
                this.currentScreen = SCREEN_STUDY_TYPE
                break              
        }
    }

    /**
    * @description handle the event for study type change and show the appropreate screen based on the study type selection
    * @return n/a
    **/
    handleStudyTypeChange(event)
    {
        this.sTValue = event.currentTarget.dataset.id
        switch(this.sTValue) {
            case 'Graduate Research':
                this.gradResearchAndExchangeOption = this.getTypeOfApplication()
                this.setCorrectScreenType(SCREEN_GRAD_RESEARCH_QUALIFIER, SUB_HEADING_SELECT_APPLICATION_TYPE)
                break;
            case 'Exchange / Study Abroad':
                this.gradResearchAndExchangeOption = this.qualifierOptions
                this.setCorrectScreenType(SCREEN_GRAD_RESEARCH_QUALIFIER, SUB_HEADING_EXCHANGE)
                break;    
            default:
                this.setCorrectScreenType(SCREEN_SUMMARY, SCREEN_SUMMARY)
        }
    }

    getTypeOfApplication() {
        if(this.location == 'Australia') {
            if(this.isSSOUser && this.toggleFeatures.Scholarship_Application_Only_Enabled_GR__c) {//for sso user only SCHOLARSHIP_ONLY should be displayed
                this.typeOfApplication = [SCHOLARSHIP_ONLY]
            }else if(this.toggleFeatures.Enable_GRT_Admission_Scholarship_App__c && this.toggleFeatures.Scholarship_Application_Only_Enabled_GR__c){
                this.typeOfApplication = [ADDMISSION_AND_SCHOLARSHIP,ADDMISSION_ONLY,SCHOLARSHIP_ONLY]
            }else if(this.toggleFeatures.Scholarship_Application_Only_Enabled_GR__c){
                this.typeOfApplication = [ADDMISSION_ONLY,SCHOLARSHIP_ONLY]
            }else if(this.toggleFeatures.Enable_GRT_Admission_Scholarship_App__c){
                this.typeOfApplication = [ADDMISSION_AND_SCHOLARSHIP,ADDMISSION_ONLY]
            }else{
                this.typeOfApplication = [ADDMISSION_ONLY]
            }
        } else {
            this.typeOfApplication = [ADDMISSION_ONLY]
        }
        return this.typeOfApplication
    }
    
    /**
    * @description handles the event for Grad research and study abroad selection and show the appropreate screen based on the selection
    * @return n/a
    **/
    handleGradResearchAndExchange(event) {
        switch(event.currentTarget.dataset.id) {
            case ADDMISSION_AND_SCHOLARSHIP:
                this.gradResearchApplicationType = ADDMISSION_AND_SCHOLARSHIP
                this.gradResearchAndExchangeOption = this.qualifierOptions
                this.setCorrectScreenType(SCREEN_GRAD_RESEARCH_QUALIFIER, SUB_HEADING_ADDMISSION_AND_SCHOLARSHIP)
                break
            case ADDMISSION_ONLY:
                this.gradResearchAndExchangeOption = this.qualifierOptions
                this.gradResearchApplicationType = ADDMISSION_APPLICATION_ONLY
                this.setCorrectScreenType(SCREEN_GRAD_RESEARCH_QUALIFIER, SUB_HEADING_ADDMISSION_AND_SCHOLARSHIP)
                break
            case SCHOLARSHIP_ONLY:
                this.gradResearchAndExchangeOption = this.qualifierOptions
                this.gradResearchApplicationType = SCHOLARSHIP_APPLICATION_ONLY
                if(this.hasCourseAttempts){
                    this.setCorrectScreenType(SCREEN_GRAD_RESEARCH_QUALIFIER, SUB_HEADING_SCHOLARSHIP_ONLY)
                }else{
                    this.blankScreen = true;
                    this.setCorrectScreenType('', SUB_HEADING_SCHOLARSHIP_ONLY_NO_COURSE_ATTEMPTS);
                }
                break   
            case YES:
                this.setCorrectScreenType(SCREEN_SUMMARY, SCREEN_SUMMARY)
                break
            case NO:
                this.blankScreen = true
                if(this.gradResearchApplicationType == SCHOLARSHIP_APPLICATION_ONLY) {
                    this.setCorrectScreenType('', SUB_HEADING_SCHOLARSHIP_ONLY_END)
                } else if(this.gradResearchApplicationType == ADDMISSION_AND_SCHOLARSHIP || this.gradResearchApplicationType == ADDMISSION_APPLICATION_ONLY) {
                    this.setCorrectScreenType('', SUB_HEADING_GRAD_RESEARCH_END)
                } else if(this.sTValue == 'Exchange / Study Abroad') {
                    this.setCorrectScreenType('', SUB_HEADING_ECHANGE_END)
                }     
                break      
        }

    }

    /**
    * @description creates the draft application base on the location and study type
    * @return n/a
    **/
    createDraftApplication() {
        this.isLoading = true;
        this.setCourseType()
        let redURL
        if(this.sTValue == 'Graduate Research') {
            redURL = 'gradresearchapplication?recordId='
        } else {
            redURL = 'application/'
        }
        createApplication({
            contactId : this.userDetails.ContactId,
            location : this.location,
            courseType : this.courseType
        }).then(createApplicationResult => {
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__webPage',
                attributes: {
                    url: '/admissions/s/' + redURL + createApplicationResult
                }
            }).then(url => {
                console.log('url');
                window.location.href = url;
            });
        })
        .catch(createApplicationError =>{
            //Expose error
            console.log('Error: ' + JSON.stringify(createApplicationError));
            //enable new application button
        });
    } 
    
    setCourseType() {
        switch(this.sTValue) {
            case 'Graduate Research':
                this.courseType = 'Graduate Research' + ';' + this.gradResearchApplicationType
                break;
            case 'Exchange / Study Abroad':
                this.courseType = 'Study Abroad'  
                break
            default:
                this.courseType = 'Coursework'      
        }
    }

    resetScreens(){
        this.countryScreen = false
        this.studyTypeScreen = false
        this.summaryScreen = false
        this.gradResearchQualifierScreen = false
        this.qualifierScreen = false
    }

    /**
    * @description set the correct modal screen section based on the study type and location selection
    * @return n/a
    **/
    setCorrectScreenType(screenName, subHeading) {
        this.resetScreens()
        this.modalSubHeading = subHeading
        switch(screenName) {
            case SCREEN_COUNTRY : 
                this.countryScreen = true
                this.currentScreen = SCREEN_COUNTRY
                break
            case SCREEN_STUDY_TYPE :
                this.studyTypeScreen = true
                this.currentScreen = SCREEN_STUDY_TYPE
                break
            case SCREEN_GRAD_RESEARCH_QUALIFIER :
                this.gradResearchQualifierScreen = true
                this.currentScreen = SCREEN_GRAD_RESEARCH_QUALIFIER
                break  
            case SCREEN_SUMMARY :
                this.summaryScreen = true
                this.currentScreen = SCREEN_SUMMARY
                break
        }
    }

    get isResearchInMalaysia() {
        return this.sTValue == 'Graduate Research' && this.location == 'Malaysia' && this.summaryScreen
    }

    handleKeydown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            event.currentTarget.click();
        }
    }
    
    renderedCallback() {
        // Avoid focusing repeatedly
        if (this.hasRendered) return;
        this.hasRendered = true;
        //focus on close button as soon as the modal is rendered
        const closeBtn = this.template.querySelector('button.slds-modal__close');
        if (closeBtn) {
            closeBtn.focus();
        }
    }
    
}