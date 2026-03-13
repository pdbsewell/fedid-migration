import { LightningElement, api, wire } from 'lwc';
import getFullApplication from '@salesforce/apex/ApplicationReviewController.GetFullApplication'; 

/**
*  @author Vishal Gupta
*  @date 18-06-2024
*  @group My App Application
*  @description used to the snapshot of overall application form 
**/
export default class MyApplicationReview extends LightningElement {

    @api applicationId
    fullApplication = {}
    preferences = []
	tertiaryQualifications = []
	secondaryQualifications = []
	otherQualifications = []
	englishQualifications = []
	UnitPreferenceList = []
	selectedSem1RowsList = []
	selectedSem2RowsList = []
	upList = []
	sem1StudyPlanDesc
	sem2StudyPlanDesc
	showPreReq = false
	showSpinner = false
	showUnitsSection = false
	durationAvailable = false
	oneSem = false
	twoSem = false
	preferencesAvailable = false
	salutation
	isMononymousName = false
	minimumUnits
	maximumUnits

    connectedCallback() {
		this.showSpinner = true
        var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var sParameterName
        var sParamId = ''
        var i

        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('=') //to split the key from the value.
            for(var x = 0; x < sParameterName.length; x++){
                if(sParameterName[x] === 'appId'){
                    sParamId = sParameterName[x+1] === undefined ? 'Not found' : sParameterName[x+1]
                }
            }
        }

        if(sParamId && this.applicationId == undefined){
            this.applicationId = sParamId
        }

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
				if (this.fullApplication.Application.Source_System__c === 'CCT') {
					//redirect to the home page when user trying to access Course Transfer Application
					window.location.href = '/admissions/s/'
				}
				
				this.tertiaryQualifications = this.fullApplication.Qualifications['Tertiary Education']
				this.secondaryQualifications = this.fullApplication.Qualifications['Secondary Education']
				this.otherQualifications = this.fullApplication.Qualifications['Other Qualification']
				this.englishQualifications = this.fullApplication.Qualifications['English Test']
							
				if (this.fullApplication.Application.Duration_of_Study__c == '1' || this.fullApplication.Application.Duration_of_Study__c == '2') {
				this.durationAvailable = true
				if(this.fullApplication.Application.Duration_of_Study__c == '1') {
					this.oneSem = true
				}
				else if(this.fullApplication.Application.Duration_of_Study__c == '2') {
					this.twoSem = true
				}
				}

				if ( this.fullApplication.UnitPreferenceList != null && this.fullApplication.UnitPreferenceList.length != 0 ) {
				this.showUnitsSection = true
				this.UnitPreferenceList = this.fullApplication.UnitPreferenceList
				} else {
				this.showUnitsSection = false
				}

				var acpList = this.fullApplication.Preferences
				if (acpList != null && acpList.length !=0){
					this.preferencesAvailable = true
					if(this.fullApplication.Application.Type_of_Study__c=='Study Abroad' || this.fullApplication.Application.Type_of_Study__c=='Exchange')
					{
						this.loadStudyPlan( acpList[0].Course_Offering__r.Start_Date__c)
						this.populateStudyPlanTables(acpList[0].Calendar_Code__r.Type__c, acpList[0].Calendar_Code__r.Year__c)
					}
				} else {
					this.preferencesAvailable = false
				}

				// set minimum and maximum units
				this.minimumUnits = this.fullApplication.minimumUnits
				this.maximumUnits = this.fullApplication.maximumUnits

				// Handle Salutation when blank
				var title = this.fullApplication.Application.Applicant__r.Salutation
				this.salutation = title ? title : '-'
				
				// Handle Mononymous names
				var firstname = this.fullApplication.Application.Applicant__r.First_Name__c
				if (firstname = undefined) {
					this.isMononymousName = true
				}
				
				this.showSpinner = false
			}
		})
	}

    loadStudyPlan (stdt) {
		var upList = this.UnitPreferenceList
		var newList = []
		let rowColor =''
		var preReq
		upList.forEach(function (uo) {
			if(uo.MA_Status__c!=null && (uo.MA_Status__c.toLowerCase() =='red' || uo.MA_Status__c.toLowerCase() =='yellow'))
				{
					rowColor = "color:#FF0000"
					preReq = true
				}else{
					rowColor = "color:black"
				}
				newList.push({
				Id: uo.Id,
				UnitCode: uo.Unit_Code__c,
				UnitTitle: uo.Title__c,
				FacName: uo.Managing_Faculty_Name__c,
				Campus: uo.Location__c,
				Year: uo.Academic_Year__c,
				TP: uo.Calendar_Name__c,
				PreReq:rowColor,
				UnitOffering: uo.UO_ID__c,
				StDt: uo.Start_Date__c
			})
		})
		if(preReq) {
			this.showPreReq = true
		}
		this.upList = newList
	}
	populateStudyPlanTables(aCPAdmType, aCPAdmYr) {
        var sem1text = "";
        if(aCPAdmType == 'ADM-2')
        { 
          sem1text =
          "Semester of study (July - December " +
		  	aCPAdmYr +")";
        }else if(aCPAdmType == 'ADM-1'){
          sem1text =
          "Semester of study (January - June " +
		  	aCPAdmYr +")";
        }
        this.sem1StudyPlanDesc = sem1text
        let sem1RowsList = []
        let fullList = this.upList
        fullList.forEach((item) => {
          	sem1RowsList.push(item)
        })
        this.selectedSem1RowsList = sem1RowsList
    }

	//show/hide Semester 1 section
	get isSem1RowListFound() {
		return this.selectedSem1RowsList.length > 0
	}

	//show/hide Residency status section
	get isResidencyStatusOnSite() {
		return Boolean(this.fullApplication.Application.Residency_Status__c != null && this.fullApplication.Application.Campus_Location__c != 'Online')
	}

	//show/hide AboriginalTorresStraitIslander section
	get isAboriginalTorresStraitIslander() {
		return Boolean(this.fullApplication.Application.Applicant__r.Aboriginal_or_Torres_Strait_Islander__c != null && this.fullApplication.Residency_Value == 'DOM-AUS')
	}

	//show/hide StudyAbroadOrExchange section
	get isStudyAbroadOrExchange() {
		return Boolean(this.fullApplication.Application.Type_of_Study__c =='Study Abroad' || this.fullApplication.Application.Type_of_Study__c =='Exchange')
	}

	//show/hide SecondaryQualification section
	get isSecondaryQualification() {
		return this.secondaryQualifications.length > 0
	}

	//show/hide TertiaryQualification section
	get isTertiaryQualification() {
		return this.tertiaryQualifications.length > 0
	}

	//show/hide SponsorshipOrProxy section
	get isSponsorshipOrProxy() {
		return Boolean(this.fullApplication.Application.Sponsorship_Type__c != 'No')
	}

	//show/hide Sponsorship section
	get isSponsorship() {
		return Boolean(this.fullApplication.Application.Sponsorship_Type__c == 'Sponsorship')
	}

	//show/hide OtherQualification section
	get isOtherQualification() {
		return this.otherQualifications.length > 0
	}

	//show/hide EnglighQualification section
	get isEnglighQualification() {
		return this.englishQualifications.length > 0
	}

	//show/hide WorkExperience section
	get hasWorkExperience() {
		return this.fullApplication.Experience.length > 0
	}
}