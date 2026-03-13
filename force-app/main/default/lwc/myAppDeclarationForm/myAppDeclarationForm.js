import { LightningElement, api } from 'lwc';
import saveIconURL from "@salesforce/resourceUrl/myappsaveicon";
import retrieveApplication from '@salesforce/apex/AppDeclarationFormCC.retrieveApplication'; 
import validateAndSubmitApplication from '@salesforce/apex/AppDeclarationFormCC.validateAndSubmitApplication';
import validateApplication from '@salesforce/apex/AppDeclarationFormCC.validateApplication';
import updateApplicationWithStudentDeclarationAccepted from '@salesforce/apex/AppDeclarationFormCC.updateApplicationWithStudentDeclarationAccepted';
import { NavigationMixin } from 'lightning/navigation';

/**
*  @author Vishal Gupta
*  @date 01-07-2024
*  @group My App Application
*  @description Application declaration page which allows the students/agents to submit the application 
**/
export default class MyAppDeclarationForm extends NavigationMixin(LightningElement) {

    @api applicationId
    appRecord
    backDisabled
    submitDisabled
    acceptDisabled
    showCCButton
    fullName
    listErrorItems = []
    showErrors
    showPayment
    showSpinner = false

    saveIcon = saveIconURL

    connectedCallback() {
        this.doInit()
    }

    /**
     * fetch the application record from database
     */
    doInit() {
        this.showSpinner = true
        retrieveApplication({
            applicationId: this.applicationId
        }).then(response => {
            if (response) {
                var appRecord = response
                
				this.appRecord = appRecord
                this.showCCButton = (appRecord.Source_System__c !='AgentPortal' &&
                               appRecord.Fee_Payment_Mode__c == 'Credit Card' && appRecord.Fee_Payment__c == false)
	            if (appRecord.Status__c != 'Draft' && !component.get('v.applicationId')) {
	            	//redirect to dashboard
        			this.navigateToHomePage()
	            }
                // handle Mononymous names
                if (appRecord.Applicant__r.First_Name__c && appRecord.Applicant__r.First_Name__c.trim()) {
                    this.fullname =  appRecord.Applicant__r.First_Name__c + ' ' +appRecord.Applicant__r.Last_Name__c
                }else{
                    this.fullname = appRecord.Applicant__r.Last_Name__c
                }

                this.showSpinner = false
            } 
        }).catch((error) => {
            this.showSpinner = false
        })
    }

    get isNotAgentPortal() {
        return this.appRecord.Source_System__c != 'AgentPortal'
    }

    backToPaymentOrReview() {
		this.fireNavigationEvent('payment')
	}

    /**
     * submit the application and catch errors, if any
     */
    submitApplication() {
        this.showSpinner = true
        this.backDisabled = true
        this.submitDisabled = true

        validateAndSubmitApplication({
            applicationId: this.applicationId
        }).then(response => {
            if (response) {
				var arrErrors = response.errors
                if(arrErrors && arrErrors.length > 0) {
                    this.showErrorComponent(arrErrors)
                }
                else {
                    // on success
                    this.fireNavigationEvent('receipt')
                }

                this.showSpinner = false
            } 
        }).catch((error) => {
            this.showSpinner = false
        })
	}

    /**
     * fire the naviation event and has been handled in the parent app to chanhge the screen sections
     */
    fireNavigationEvent(sectionName) {
        this.dispatchEvent(new CustomEvent('changesection', {
            detail: {
                arguments : {
                    sectionName: sectionName
                }
            }
        })); 
    }

    /**
     * show the error popup on the declaration page
     */
    showErrorComponent(arrErrors) {
        this.showErrors = true
        this.backDisabled = false
        this.submitDisabled = false
        
        var iLen = arrErrors.length

        var TOO_MANY_ERRORS = ['Multiple errors in this section']

        var arrErrorItems = []
        for(var i = 0; i < iLen; ++i)
        {
            var tupleError = arrErrors[i]

            var section = tupleError.section
            var sectionLabel = tupleError.label
            var errors = tupleError.errors
            // truncate if more than 3
            if(errors.length > 3) {
                tupleError.errors = TOO_MANY_ERRORS
            }

            var sectionUrl = '/'
            switch(section) {
                case 'online_credit':
                    sectionUrl = 'applicationsuccess'
                    break
                case 'course_preference':
                    sectionUrl = 'course-selection'
                    break
                case 'qualifications':
                    sectionUrl = 'qualifications-work-experience'
                    break
                case 'contact':
                case 'citizenship':
                case 'under_18':
                    sectionUrl = 'personal-details'
                    break
                case 'sponsorship':
                    sectionUrl = 'external-scholarship'
                    break
                case 'payment':
                   sectionUrl = 'payment'
                   break
            }
            sectionUrl += '?appId=' + this.applicationId
            tupleError.url = sectionUrl
            arrErrorItems.push(tupleError)
        }
        this.listErrorItems = arrErrorItems
    }

    /**
     * open the payment screen popup and submit the application
     */
    pay() {   
        this.showSpinner = true
        validateApplication({
            applicationId: this.applicationId
        }).then(response => {
            if (response) {
                
				var arrErrors = response.errors
                if(arrErrors && arrErrors.length > 0) {
                    this.showErrorComponent(arrErrors)
                }else{
                    //Process Payment
                    this.showPayment = true
                }

                this.showSpinner = false
            } 
        }).catch((error) => {
            this.showSpinner = false
        })
    }

    closePayment() {
        this.showPayment = false
    }

    onClickCloseAlert() {
        this.showErrors = false
    }

    /**
     * navigate the different pages for any error links
     */
    navigateToSection(e) {
        var sectionName = e.target.name
        this.fireNavigationEvent(sectionName)
    }

    saveandExit() {
        this.navigateToHomePage()
    }

    //Navigate to home page
    navigateToHomePage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'home'
            },
        });
    }

    /**
     * submit the agent portal application and catch errors, if any
     */
    sendToAgent() {
		this.showSpinner = true
        this.backDisabled = true
        this.acceptDisabled = true
        validateApplication({
            applicationId: this.applicationId
        }).then(response => {
            if (response) {                
				var arrErrors = response.errors
                if(arrErrors && arrErrors.length > 0) {
                    this.showErrorComponent(arrErrors)
                }else{
                    this.showSpinner = true
                    updateApplicationWithStudentDeclarationAccepted({
                        applicationId: this.applicationId
                    }).then(declarationResponse => {
                        if (declarationResponse) {
                            
                            var arrErrors = declarationResponse.errors
                            if(arrErrors && arrErrors.length > 0) {
                                this.showErrorComponent(arrErrors)
                            }
                            else {
                                this.fireNavigationEvent('receipt')
                            }
            
                            this.showSpinner = false
                        } 
                    }).catch((error) => {
                        this.showSpinner = false
                    })
                }

                this.showSpinner = false
            } 
        }).catch((error) => {
            this.showSpinner = false
        })
    }
}