import { LightningElement, api, track } from 'lwc';
import retrieveApplication from "@salesforce/apex/SponsorshipCC.retrieveApplication";
import updateApplicationSponsor from "@salesforce/apex/SponsorshipCC.updateApplicationSponsor";

export default class MyAppSponsorship extends LightningElement {
    @api application = null;

    @api sponsorshipType;

    @api applicationId;

    @api appId = "";

    @api sponsorshipOptions = [];

    @api showErrors = false;

    @api saveErrors = [];

    @track isSponsorship = false;

    @track isProxy = false;

    @track sponsorName = '';

    @track sponsorOrg = '';

    @track proxyName = '';

    @track proxyOrg = '';

    @track sponsorEmail = '';

    @track proxyEmail = '';

    
    connectedCallback() {
        this.doInit();
    }

    //Retrieve the application via application id and set the values
    doInit() {
		var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var sParameterName;
        var sParamId = '';
        var i;

        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('='); //to split the key from the value.
            for(var x = 0; x < sParameterName.length; x++){
                if(sParameterName[x] === 'appId'){
                   sParamId = sParameterName[x+1] === undefined ? 'Not found' : sParameterName[x+1];
                }
            }
        }
        if(!sParamId){
            sParamId = this.applicationId;
        }else{
            //redirect to the new app form url
            window.location.href = '/admissions/s/application/' + sParamId;
        }

        this.appId = sParamId;
        
        if (sParamId !== '') {
            var action = retrieveApplication;
            action({'appId'   : sParamId}).then(response => {
                var data = response;

                // Set the appRecord with the server response
                this.application = data["application"];
                this.sponsorshipOptions = data['sponsor_pick'];
                if(this.application.Sponsorship_Type__c == 'Sponsorship'){
                    this.isSponsorship = true;
                    this.isProxy = false;

                    this.sponsorName = this.application.Sponsor_Name__c;
                    this.sponsorOrg = this.application.Sponsor_Scholarship_organisation__c;
                    this.sponsorEmail = this.application.Sponsor_Email_Address__c;
                }
                else if(this.application.Sponsorship_Type__c == 'Proxy'){
                    this.isProxy = true;
                    this.isSponsorship = false;
                    this.proxyName = this.application.Sponsor_Name__c;
                    this.proxyOrg = this.application.Sponsor_Scholarship_organisation__c;
                    this.proxyEmail = this.application.Proxy_Email_Address__c;
        
                }else{
                    this.isProxy = false;
                    this.isSponsorship = false;            
                }
               
                this.selectedOption =   this.application.Sponsorship_Type__c;
            });
        }
    }

    //Reset the values and set the sponsorship type to display sponsorship or proxy template
    updateMySelection(event){
        var app = this.application;
        app.Sponsor_Scholarship_organisation__c = '';
        app.Sponsor_Name__c = '';
        app.Proxy_Email_Address__c = '';
        app.Sponsor_Email_Address__c = '';
        this.application = app;
        this.selectedOption = event.detail.value;
        app.Sponsorship_Type__c = this.selectedOption;
        if(app.Sponsorship_Type__c == 'Sponsorship'){
            this.sponsorEmail= '';
            this.sponsorName = '';
            this.sponsorOrg = '';
            this.isSponsorship = true;
            this.isProxy = false;
        }
        else if(app.Sponsorship_Type__c == 'Proxy'){
            this.proxyEmail ='';
            this.proxyName = '';
            this.proxyOrg = '';
            this.isProxy = true;
            this.isSponsorship = false;

        }else{
            this.isProxy = false;
            this.isSponsorship = false;            
        }
       
        this.handleSponsorChange();
    }

    //Update the application with sponsorship and proxy values every onchange of the input fields
    updateApplication(event) {
        var app = this.application;
        app.Sponsorship_Type__c = this.selectedOption;
        if(app.Sponsorship_Type__c == 'Sponsorship'){
            if(event.target.name == 'sponsorTypeName')
                app.Sponsor_Name__c = event.target.value;
            if(event.target.name == 'sponsorTypeOrg')
                app.Sponsor_Scholarship_organisation__c = event.target.value;
            if(event.target.name == 'sponsorTypeEmail')
                app.Sponsor_Email_Address__c = event.target.value;
        }
        else if(app.Sponsorship_Type__c == 'Proxy'){
            if(event.target.name == 'proxyTypeName')
                app.Sponsor_Name__c = event.target.value;
            if(event.target.name == 'proxyTypeOrg')
                app.Sponsor_Scholarship_organisation__c = event.target.value;
            if(event.target.name == 'proxyTypeEmail')
                app.Proxy_Email_Address__c = event.target.value;
        }
        this.application = app;
        this.handleSponsorChange();
    }

    //commit the updates to the database via apex controller updateApplicationSponsor
    handleSponsorChange() {
        var app = this.application;
        if (this.isUnsafe(app)) {
            var appErrors = ["One or more input boxes are not in the expected format."];
            this.saveErrors = appErrors;
            this.showErrors = true;
            return;
        }
        var action = updateApplicationSponsor;
        action({
            application: app
        }).then(response => {
            // Notify the user with the value returned from the server
            console.log("From server: ");
            console.log(response);
        }).catch(response => {
            var errors = response;
            if (errors) {
                if (errors[0] && errors[0].message) {
                    console.log("Error message: " + 
                             errors[0].message);
                }
            } else {
                console.log("Unknown error");
            }
        });
    }

    //check of data input is unsafe
    isUnsafe(dataObject) {
        const XML_REGEX_PATTERN = /(<.[^(><.)]+>)/g;
        return XML_REGEX_PATTERN.test(JSON.stringify(dataObject));
    }

    //close error pop up
    onClickCloseErrors() {
        this.showErrors = false;
    }

}