import { LightningElement, api, wire } from 'lwc';
import getFullApplication from '@salesforce/apex/ApplicationReviewController.GetFullApplication'; 
import validateAndSubmitApplication from '@salesforce/apex/AppDeclarationFormCC.validateAndSubmitApplication';
import { NavigationMixin } from 'lightning/navigation';
import fetchDeclarationOptions from '@salesforce/apex/MyGRAppAddQualificationController.fetchDeclarationOptions';


/**
*  @author Vishal Gupta
*  @date 5-09-2024
*  @group My App GR Application
*  @description used to the snapshot of overall application form 
**/
export default class MyGRApplicationReview extends NavigationMixin(LightningElement) {

    @api applicationId
    showSpinner
    courses
    course
    englishDataArray
    englishData
    qualData
    awardsData
    expData
    refData
    publicationData
    creativeData
    musicData
    exhibitionData
    theatreData
    miscData
    fullApplication
    errorData = []
    value = []
    declarationOptions = []
    attendanceMode
    residencyStatus

    @wire(fetchDeclarationOptions)
    declarationRecords({ error, data }) {
        if (data) {
            let arrayItems = data
            if(arrayItems) 
            {
                let options = []
                arrayItems.forEach(item => {
                    options.push({
                        label: item.Declaration_Text__c,
                        value: item.Declaration_Option_Order__c
                    })
                })
                this.declarationOptions = options
            }
        } else if (error) {
            this.errorData = error
        }
    }

    connectedCallback() {
		this.showSpinner = true
		this.getApplication()
    }

    /**
    * @description fetch all the related application records
    * @return n/a
    **/
	getApplication() {
		getFullApplication({
			appId: this.applicationId
		}).then(data => { 
			if(data) {
                this.fullApplication = JSON.parse(data)

                if(this.fullApplication.Application.Residency_Status__c == 'I hold or will be getting an Australian Student Visa'){
                    this.residencyStatus = 'Other Nationality';
                }else{
                    this.residencyStatus = this.fullApplication.Application.Residency_Status__c;
                }
                
                if(this.fullApplication?.Preferences?.length > 0) {                    
                    this.course = this.fullApplication.Preferences?.find((element) => element.Research_Supervisors__c != null)
                    if(this.course.Attendance_Mode__c == 'EX'){
                        this.attendanceMode = 'External (off-campus)';
                    }
                    if(this.course.Attendance_Mode__c == 'IN'){
                        this.attendanceMode = 'Internal (on-campus)';
                    }
                }
                this.englishDataArray = this.fullApplication.Qualifications['English Test']
                this.prepareQualificationFileNames(this.englishDataArray, 'english')
                if(this.englishDataArray?.length > 0) {
                    this.englishData = this.englishDataArray[0]
                }
                    
				this.qualData = this.fullApplication.Qualifications['Tertiary Education']
                if(this.qualData?.length == 0) {
                    this.errorData.push('Any application requires at least one qualification to be recorded.')
                } 
                this.awardsData = this.fullApplication.Qualifications['Awards, Prizes and Scholarships']
                this.expData = this.fullApplication.Qualifications['Employment and Research Experience']
                this.refData = this.fullApplication.Qualifications['Referees']
                if(this.refData?.length < 2) {
                    this.errorData.push('Any application requires at least two referees to be recorded.')
                }
                this.publicationData = this.fullApplication.Qualifications['Publications']
                this.exhibitionData = this.fullApplication.Qualifications['Exhibitions']
                this.creativeData = this.fullApplication.Qualifications['Creative Works']
                this.musicData = this.fullApplication.Qualifications['Music']
                this.theatreData = this.fullApplication.Qualifications['Theatre Performance'] 
                this.miscData = this.fullApplication.Qualifications['Other Qualification']
                if(this.fullApplication.docData) {
                    this.prepareDocNames(this.fullApplication.docData)
                }
                
                //preparing the uploaded documents file name
                this.prepareQualificationFileNames(this.qualData, 'qualifications')                
                this.prepareQualificationFileNames(this.awardsData, 'awards')                
                this.prepareQualificationFileNames(this.expData, 'experiences')                
                this.prepareQualificationFileNames(this.refData, 'referees')                
                this.prepareQualificationFileNames(this.publicationData, 'publications')                
                this.prepareQualificationFileNames(this.exhibitionData, 'exhibitions')                
                this.prepareQualificationFileNames(this.creativeData, 'creative works')                
                this.prepareQualificationFileNames(this.musicData, 'music')                
                this.prepareQualificationFileNames(this.theatreData, 'theatre performances')
                this.prepareQualificationFileNames(this.miscData, 'additional supporting information')
				this.showSpinner = false

			}
		})
	}

    /**
    * @description fetch all the related document file names, 
    *               if file names are not found then add into error details
    * @param data : document checklist related to the application
    **/
    prepareDocNames(data) {
        data.forEach(element => {
            switch(element.docChecklist.Checklist_Requirement__c) {
                case 'Proof of Residency / Citizenship':
                    if(element.fileName) {
                        this.fullApplication.Residency_Status_File = element.fileName
                    } else {
                        this.errorData.push('Proof of residency is missing')
                    }
                    break;   
                case 'Previous Application with Monash':
                    if(element.fileName) {
                        this.fullApplication.Previous_Application_File = element.fileName
                    } else {
                        this.errorData.push('Please provide a summary of differences, if any, between this application and prior application')
                    }
                    break;
                case 'Curriculum Vitae':
                    if(element.fileName) {
                        this.fullApplication.CV_File = element.fileName
                    } else {
                        this.errorData.push('Curriculum Vitae is missing')                        
                    }  
                    break;
                case 'Nomination of Agent Form':
                    if(element.fileName) {
                        this.fullApplication.Agent_File = element.fileName
                    } else {
                        this.errorData.push('Nomination of agent form is missing')                        
                    }  
                    break;
                case 'Attendance and Employment Commitments':
                    if(element.fileName) {
                        this.fullApplication.Attendance_File = element.fileName
                    } else {
                        this.errorData.push('Attendance and Appointment Commitments document is missing')                        
                    }  
                    break; 
                case 'Equity, Diversity, and Inclusion Scholarship/Humanitarian Scholarship Supplementary Form':
                    if(element.fileName) {
                        this.fullApplication.Equity_Scholarship_File = element.fileName
                    } else {
                        this.errorData.push('Equity Scholarship Application Form is missing')                        
                    }  
                    break; 
                case 'On-Site Supervisor Form':
                    if(element.fileName) {
                        this.fullApplication.Supervisor_File = element.fileName
                    } else {
                        this.errorData.push('On-Site Supervisor Form is missing')                        
                    }  
                    break; 
                case 'Research Program Invitation Details':
                    if(element.fileName) {
                        this.fullApplication.Research_Invitation_File = element.fileName
                    } else {
                        this.errorData.push('Research Program Invitation Details document is missing')                        
                    }  
                    break; 
                case 'Research Program Research Proposal':
                    if(element.fileName) {
                        this.fullApplication.Research_Proposal_File = element.fileName
                    } else {
                        this.errorData.push('Research Program Research Proposal is missing')                        
                    }  
                    break;
                case 'Sponsorship/Scholarship Letter':
                    if(element.fileName) {
                        this.fullApplication.Sponsor_File = element.fileName
                    } else {
                        this.errorData.push('Sponsorship/Scholarship Letter is missing')                        
                    }  
                    break;                   
            }
        });
    }
    
    /**
    * @description fetch all the related document file names, 
    *               if file names are not found then add into error details
    * @param data : document checklist related to the Contact Qualification
    **/
    prepareQualificationFileNames(qualData, step) {
        qualData.forEach(element => {
            let documentData = this.fullApplication.docData?.find((docElement) => docElement.docChecklist.Contact_Qualification__c == element.Id)
            
            let errorDesc = 'At least one of your '+step+' does not have a supporting document'
            if(documentData) {
                if(documentData.fileName) {
                    element.File_Name = documentData?.fileName
                } else {
                    if (step != 'english' && !this.errorData.includes(errorDesc) && step != 'referees') {
                        this.errorData.push(errorDesc)
                    }else if(step == 'english') {
                        this.errorData.push('You have not provided documents or results supporting your claimed English Proficiency')
                    }
                }              
            } else if(step != 'english' && step != 'referees' && step != 'qualifications') {//there are some doc checklist exceptions for english, referees and tertiary education, so they might not have any doc checklist populated
                if(!this.errorData.includes(errorDesc))
                    this.errorData.push(errorDesc)
            }
        })
    }

    //show/hide AboriginalTorresStraitIslander section
	get isAboriginalTorresStraitIslander() {
		return Boolean(this.fullApplication.Application?.Applicant__r.Aboriginal_or_Torres_Strait_Islander__c != null && this.fullApplication.Residency_Value == 'DOM-AUS')
	}

    //show/hide Residency status section
	get isResidencyStatusOnSite() {
		return Boolean(this.fullApplication.Application?.Residency_Status__c != null && this.fullApplication.Application?.Campus_Location__c != 'Online')
	}

    get isMononymousName() {
        return this.fullApplication.Application?.Applicant__r?.First_Name__c == undefined
    }

    get isQualData(){
        return this.qualData?.length > 0
    }

    get isAwardsData(){
        return this.awardsData?.length > 0
    }

    get isExpData(){
        return this.expData?.length > 0
    }

    get isRefData(){
        return this.refData?.length > 0
    }

    get isPublicationData(){
        return this.publicationData?.length > 0
    }

    get isExhibitionData(){
        return this.exhibitionData?.length > 0
    }

    get isCreativeData(){
        return this.creativeData?.length > 0
    }

    get isMusicData(){
        return this.musicData?.length > 0
    }

    get isTheatreData(){
        return this.theatreData?.length > 0
    }

    get isMiscData() {
        return this.miscData?.length > 0
    }

    //show/hide submit button and declaration
	get isSubmitEnabled() {
		return this.fullApplication?.Application?.Status__c == 'Draft' && this.errorData.length == 0
	}

    //is application draft
	get isApplicationDraft() {
		return this.fullApplication?.Application?.Status__c == 'Draft'
	}

    //is application not in draft
	get isApplicationNotInDraft() {
		return this.fullApplication?.Application?.Status__c != null && this.fullApplication?.Application?.Status__c != 'Draft'
	}

    get isErrorData(){
        return this.errorData.length > 0 && this.fullApplication?.Application?.Status__c == 'Draft'
    }

    /**
    * @description submit the GR application
    * @return n/a
    **/
    submitApplication(){
        const allValid = [
            ...this.template.querySelectorAll('lightning-input'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        if(allValid) {
            this.showSpinner = true
            //code for submit
            validateAndSubmitApplication({
                applicationId: this.applicationId
            }).then(declarationResponse => {
                if (declarationResponse) {
                    var arrErrors = declarationResponse.errors
                    if(arrErrors && arrErrors.length > 0) {
                        
                    }
                    else {
                        this[NavigationMixin.Navigate]({
                            type: 'comm__namedPage',
                            attributes: {
                                name: 'Home'
                            }
                        })
                    }
    
                    this.showSpinner = false
                } 
            }).catch((error) => {
                this.showSpinner = false
            })
        }
    }
}