import { CurrentPageReference } from 'lightning/navigation';
import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {loadStyle} from 'lightning/platformResourceLoader';
import banner4Image from '@salesforce/contentAssetUrl/unknown_content_asset';
import monashPortalCssMinified from '@salesforce/resourceUrl/Monash_Portal_CSS_Minified';

/* APEX SERVICES */
import validateContactInfo from "@salesforce/apex/OnBoardAlumniController.validateContactInfo";
import setupAlumniUser from "@salesforce/apex/OnBoardAlumniController.setupAlumniUser";
import extendUserAsAlumni from "@salesforce/apex/OnBoardAlumniController.extendUserAsAlumni";
import createEnquiry from "@salesforce/apex/OnBoardAlumniController.createEnquiry";

export default class OnBoardAlumni extends NavigationMixin(LightningElement) {
    urlParameters;
    id;
    caseNumber;
    freshUser = false;
    alumniUser = false;
    nonAlumniUser = false;
    validUrl = false;
    validatedUser = false;
    fname;
    lname;
    uname;
    dateOfBirth;
    dataLoaded = false;
    dateToday;
    token;
    brthVldnFailreCnt = 0;
    brthVldnFailed = false;
    caseCreated = false;
    onBoarded = false;
    preExistingAlumni = false;
    onBoardingMessage = '';
    // Expose the asset file URL for use in the template
    banner4 = banner4Image;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
    if (currentPageReference) {
            this.urlParameters = currentPageReference.state;
            this.id = currentPageReference.state.Id;
        }
    }

    get backgroundStyle() {
        return `padding:1em;background-image:url(${this.banner4})`; 
    }

    connectedCallback(){ 
        if(this.id){
            // Load CSS
            Promise.all([
                loadStyle(this, monashPortalCssMinified)
            ]).then(() => {
                this.resourcesReady = true;
            });
            this.dataLoaded = true;
        }     
    } 

    validateContactInfo(){
        if(this.token){
            if(this.validateDate()){
                if(this.id){
                    // GET Contact Information
                    this.dataLoaded = false;
                    validateContactInfo({
                        s_id : this.id, s_dateOfBirth : this.dateOfBirth, s_captchaTokenKey : this.token
                    })
                    .then((result) => {
                        this.validatedUser = true;
                        if(result.s_userStatus == 'FreshUser'){
                        this.freshUser = true; 
                        }   
                        if(result.s_userStatus == 'AlumniUser'){
                            this.alumniUser = true; 
                            this.showToast("Success","You are an existing Alumni, please Login or reset you password","Success");
                            this.onBoarded = true;
                            this.preExistingAlumni = true;
                            this.onBoardingMessage = 'You already have an alumni portal account. ';
                        } 
                        if(result.s_userStatus == 'NonAlumniUser'){
                            this.nonAlumniUser = true; 
                        } 
                        this.validUrl = true;
                        this.fname = result.s_firstname;
                        this.lname = result.s_lastname;
                        this.uname = result.s_userName;
                        this.dataLoaded = true;
                    })
                    .catch((error) => {
                        this.showToast("Error", error.body.message,"Error");
                        this.dataLoaded = true;
                        this.validateContactInfoErrorHandling(error.body.message);
                    });
                }
            }else{
                this.showToast("Error","Please enter a valid Date ","Error");
            }
        }else{
            this.showToast("Error","Please tick 'I'm not a robot' to proceed","Error");
        }
        
    }

    createUser(){
        if(this.id){
            this.dataLoaded = false;
            setupAlumniUser({
                s_id : this.id,
                s_firstname : this.fname,
                s_lastname : this.lname,
                s_userName : this.uname, 
                s_dateOfBirth : this.dateOfBirth
            })
            .then((result) => {
                this.dataLoaded = true;
                this.showToast("Success","New User created, please check your InBox","Success");
                this.onBoarded = true;
                this.onBoardingMessage = 'Please check your email inbox to finalise your alumni portal access.';
            })
            .catch((error) => {
                this.showToast(
                    "Error", error.body.message, "Error"
                );
                this.dataLoaded = true;
            });
        }        
    } 

    extendUserAsAlumni(){
        if(this.id){
            this.dataLoaded = false;
            extendUserAsAlumni({
                s_id : this.id,
                s_dateOfBirth : this.dateOfBirth
            })
            .then((result) => {
                this.dataLoaded = true;
                this.showToast("Success","Please check your InBox for the Welcome Email","Success");
                this.onBoarded = true;
                this.onBoardingMessage = 'Please check your email inbox to finalise your alumni portal access.';
            })
            .catch((error) => {
                this.showToast(
                    "Error", error.body.message,"Error"
                );
                this.dataLoaded = true;
            });
        }        
    } 

    validateContactInfoErrorHandling(errorMessage){
        // If InValid URL redirect to Login Page
        if(errorMessage === 'You do not have a valid URL'){
            this.navigateToLoginPage();
        } 
        // If InValid URL redirect to Login Page
        if(errorMessage === 'Date of birth does not match our records, please try again'){
            this.brthVldnFailreCnt = this.brthVldnFailreCnt + 1;
        }
        // if the date of Birth Validation has failed twice then allow case creation
        if(this.brthVldnFailreCnt == 2){
            this.brthVldnFailed = true;
        }
    }

    validateDate(){
        let isValidDate = Date.parse(this.dateOfBirth);
        if (isNaN(isValidDate)) {
            // when is not valid date logic
            return false;
        }else{
            return true;
        }
    }

    handleDispatchCaptchaEvent(event) {
        this.token = event.detail.token;
        let bypasstoken = event.detail.bypasstoken;
        let disabledBtn = event.detail.disabled;
    }

    handleDateChangeEvent(event){
        this.dateOfBirth = event.target.value;
    }

    createEnquiry(){
        // Check if the case is created for the last 24 hr 
        if(this.id){
            this.dataLoaded = false;
            createEnquiry({
                s_id : this.id,
                s_dateOfBirth : this.dateOfBirth
            })
            .then((result) => {
                this.dataLoaded = true;
                this.showToast("Success","Our team will be in contact within two business days","Success");
                this.brthVldnFailed = false;
                this.caseCreated = true;
                this.caseNumber = result;
            })
            .catch((error) => {
                this.showToast("Error", error.body.message,"Error");
                this.dataLoaded = true;
            });
        } 
    }

    //Navigate to home page
    navigateToResetPasswordPage() {
        this[NavigationMixin.Navigate]({
            'type' : 'standard__webPage',
            'attributes': {
                'url' : '/login/ForgotPassword'
            }
        });
    }

    //Navigate to home page
    navigateToLoginPage() {
        this[NavigationMixin.Navigate]({
            'type' : 'standard__webPage',
            'attributes': {
                'url' : '/login'
            }
        });
    }
    
    /*
     * Method Name: showToast
     * Description: method to show toast
     */
    showToast(title, message, type){
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message, 
                variant: type,
                mode: 'dismissible'
            }),
        ); 
    }

}