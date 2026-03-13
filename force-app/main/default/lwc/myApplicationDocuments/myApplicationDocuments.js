import { LightningElement, api } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import sitePath from "@salesforce/community/basePath";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/**
*  @author Vishal Gupta
*  @date 10-01-2024
*  @group My App Application
*  @description used to hold documentChecklistAssessmentCommunityList LWC which 
*               is used to add/remove the documents related to a particular application 
**/
export default class MyApplicationDocuments extends NavigationMixin(LightningElement) {
    @api applicationId //captures the SF application id
    @api pageTitle //title shows on document screen
    @api pageSubTitle //title description to show on document screen
    isChecklistLoaded = false;
    
    connectedCallback() {
        this.retrieveContextApplicationId()
    }

    /**
    * @description handles the file preview event from child component to open the content document file
    * @return n/a
    **/
    handleFilePreview(event) {
        var siteName = sitePath.substring(0, sitePath.lastIndexOf('/'))
        window.open(siteName+'/sfc/servlet.shepherd/document/download/'+event.detail.documentId)
    }

    /**
    * @description retrieve the application id from URL and redirecting to the review page for application review
    * @return n/a
    **/
    retrieveContextApplicationId() {
        //Parse the URL
        var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var sParameterName;
        var i, j;

        var retrievedAppId = '';
        var isReviewPage = false;
        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('='); //to split the key from the value.
            for (j = 0; j < sParameterName.length; j++) {
                if (sParameterName[j] === 'appId') { //get the app Id from the parameter
                    retrievedAppId = sParameterName[j+1];
                }
                if (sParameterName[j] === 'show') { //determine if the page is in review page
                    isReviewPage = true;
                }
            }
        }

        if (retrievedAppId != '') {
            this.applicationId = retrievedAppId
            //redirect to the new app form url if not in review page
            if(!isReviewPage){
                window.location.href = '/admissions/s/application/' + this.applicationId;
            }
        }
    }

    checklistLoaded() {
        this.isChecklistLoaded = true;
    }

    //public method to be invoked from parent aura to ensure all the required docs are uploaded for Grad Research application
    @api validateDeclaration() { 
        if(!this.isChecklistLoaded)   {
            const event = new ShowToastEvent({
                message: 'Please wait...',
                variant: 'warning'
            });
            this.dispatchEvent(event);     
            return false
        }
        const checklist = this.template.querySelector('c-document-checklist-assessment-community-list');
        if (checklist) {
            if(!checklist.checkMissingDocIds()) {
                const event = new ShowToastEvent({
                    message: 'Please upload all the required documents.',
                    variant: 'error'
                });
                this.dispatchEvent(event);     
                return false
            }   
        }
        return true
    }
}