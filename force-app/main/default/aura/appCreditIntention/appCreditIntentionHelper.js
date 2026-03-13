({
	/*******************************************************************************
    * @author       Ant Custodio
    * @date         19.Jun.2017         
    * @description  retrieve the application Id from the URL
    * @revision     
    *******************************************************************************/
	retrieveAppIdFromURL: function (component) {
        var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var sParameterName;
        var i;
        var windowLoc = window.location.pathname;
        
        if (windowLoc.indexOf("applicationdetail") !=-1 || 
            windowLoc.indexOf("applicationreview") !=-1 ||
            windowLoc.indexOf("applicationprint") !=-1 ||
            windowLoc.indexOf("testpage") !=-1) {

            component.set("v.isEditForm", false);
            if (windowLoc.indexOf("applicationdetail") !=-1) {
                component.set("v.isEditForm", true);
            }
            var retrievedAppId = '';
            for (i = 0; i < sURLVariables.length; i++) {
                sParameterName = sURLVariables[i].split('='); //to split the key from the value.
                for (j = 0; j < sParameterName.length; j++) {
                    if (sParameterName[j] === 'appId') { //get the app Id from the parameter
                        retrievedAppId = sParameterName[j+1];
                    }
                }
            }
            if (retrievedAppId != '') {
                component.set("v.appId", retrievedAppId);
            }
        }
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         19.Jun.2017         
    * @description  retrieve the application record using the retrieved appId
    * @revision     
    *******************************************************************************/
	retrieveApplicationRecord: function (component) {
        var action_retrieveApplication = component.get("c.retrieveApplicationById");
        action_retrieveApplication.setParams({ "appIdParam"   : component.get("v.appId") });
       	
       	action_retrieveApplication.setCallback(this, function(a) {
       		var state = a.getState();
            if (state == "ERROR") {
            	component.set("v.errorMessage", "An Unexpected error has occured. Please contact your Administrator.");
            } else {
            	var appRec = a.getReturnValue();
            	component.set("v.applicationRecord", appRec);
            	//retrieve the selection
		        component.set("v.applyForCredit", appRec.Applying_for_Credit__c);
		        //set the boolean according to the field value
		        component.set("v.showCreditIntentionLabel", false);
		        component.set("v.onlineCreditURL", "");
		        if (appRec.Applying_for_Credit__c == 'Yes') {
		        	component.set("v.showCreditIntentionLabel", true);
		        	component.set("v.onlineCreditURL", appRec.Applicant__r.Online_Credit_Applicant_URL__c);
		        	//this.onlineCreditCalloutById(component);
		        	console.log('onlineCreditURL: ' + component.get("v.onlineCreditURL"));
		        }
            }
        });

        //retrieve application list
        $A.enqueueAction(action_retrieveApplication);
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         19.Jun.2017        
    * @description  populate the yes/no picklist values
    * @revision     
    *******************************************************************************/
    retrieveYESNOPicklistValues : function(component) {
        console.log(component);
        var arrOptions = [
            {"value":"", "label":"choose one..."},
            {"value":"Yes", "label":"Yes"},
            {"value":"No", "label":"No"}
        ];
        component.set("v.picklistOptions", arrOptions);
        console.log(component.get("v.picklistOptions"));

    },


    /*******************************************************************************
    * @author       Ant Custodio
    * @date         19.Jun.2017        
    * @description  shows/hides edit mode
    * @revision     
    *******************************************************************************/
    toggleEditing : function (component) {
        var isEditForm = component.get("v.isEditForm");
        
        if (isEditForm) {
            isEditForm = false;
        } else {
            isEditForm = true;
        }
        component.set("v.isEditForm", isEditForm);
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         19.Jun.2017         
    * @description  update the application record using the retrieved application
    * @revision     
    *******************************************************************************/
	updateApplicationRecord: function (component) {
		this.waiting(component);
        var action_updateApplication = component.get("c.updateApplication");
        var appRec = component.get("v.applicationRecord");
        appRec.Applying_for_Credit__c = component.get("v.applyForCredit");
        console.log(component.get("v.applyForCredit"));
        action_updateApplication.setParams({ "appRecord"   :  appRec});
       	
       	action_updateApplication.setCallback(this, function(a) {
       		var state = a.getState();
            if (state == 'SUCCESS') {
            	var appRecord = a.getReturnValue();
            	component.set("v.applicationRecord", appRecord);
            	component.set("v.showCreditIntentionLabel", false);
            	if (appRecord.Applying_for_Credit__c == 'Yes') {
            		//this.onlineCreditCalloutById(component);
            		component.set("v.showCreditIntentionLabel", true);
            	}
            } else {
            	component.set("v.errorMessage", "An Unexpected error has occured. Please contact your Administrator.");
            }
            this.doneWaiting(component);
        });
        //retrieve application list
        $A.enqueueAction(action_updateApplication);
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         20.Jun.2017       
    * @description  clear the error on change
    * @revision     
    *******************************************************************************/
    clearError_onChange: function(component, event) {
        var eventSource = event.getSource();
        var auraId = eventSource.getLocalId();
        this.clearErrors(component, auraId);
        window.location.hash = '#'+auraId;
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         20.Apr.2017         
    * @description  clears a specific field error
    * @revision     
    *******************************************************************************/
    clearErrors : function(component, auraId) {
        var foundComponent = component.find(auraId);
        if (foundComponent != null) {
            foundComponent.set("v.errors", null);
            $A.util.removeClass(foundComponent, 'has-errors');
        }
    },
    
    /*******************************************************************************
    * @author       Ant Custodio
    * @date         22.Feb.2018
    * @description  using the application Id perform a callout on the Online Credit
	*					API to get a link for the applicants to fill up
    * @revision     
    *******************************************************************************/
    /*onlineCreditCalloutById : function(component) {
    	var action_retrieveOnlineCreditURL = component.get("c.retrieveOnlineCreditURL");
        var appRec = component.get("v.applicationRecord");
        action_retrieveOnlineCreditURL.setParams({ "contactId"	:	appRec.Applicant__c});
        action_retrieveOnlineCreditURL.setCallback(this, function(a) {
       		var state = a.getState();
            if (state == "ERROR") {
            	component.set("v.errorMessage", "An Unexpected error has occured. Please contact your Administrator.");
            } else {
            	var conRec = a.getReturnValue();
            	component.set("v.onlineCreditURL", conRec.Online_Credit_Applicant_URL__c);
            }
        });

        //retrieve application list
        $A.enqueueAction(action_retrieveOnlineCreditURL);
    },*/
    /*******************************************************************************
    * @author       Ant Custodio
    * @date         7.Apr.2017         
    * @description  show the spinner when page is loading
    * @revision     
    *******************************************************************************/
    waiting: function(component) {
    	console.log('waiting');
        var accSpinner = document.getElementById("Accspinner");
        console.log('accSpinner: ' + accSpinner);
        if (accSpinner != null) {
        	console.log('found');
            accSpinner.style.display = "block";
        }
        
    },
    /*******************************************************************************
    * @author       Ant Custodio
    * @date         7.Apr.2017         
    * @description  hide the spinner when finished loading
    * @revision     
    *******************************************************************************/
    doneWaiting: function(component) {
        var accSpinner = document.getElementById("Accspinner");
        if (accSpinner != null) {
            accSpinner.style.display = "none";
        }
    },
})