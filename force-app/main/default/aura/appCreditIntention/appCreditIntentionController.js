({
	/*******************************************************************************
    * @author       Ant Custodio
    * @date         19.Jun.2017         
    * @description  initial actions on page load - retrieve the application record
    * @revision     
    *******************************************************************************/
    doInit : function(component, event, helper) {
        //get appId from URL
        helper.retrieveAppIdFromURL(component);

        //retrieve the application record
        helper.retrieveApplicationRecord(component);

        helper.retrieveYESNOPicklistValues(component);
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         19.Jun.2017        
    * @description  shows/hides panel
    * @revision     
    *******************************************************************************/
    showHideComponent : function (component, event, helper) {
        var isExpanded = component.get("v.isExpanded");
        
        if (isExpanded) {
            isExpanded = false;
        } else {
            isExpanded = true;
        }
        component.set("v.isExpanded", isExpanded);
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         19.Jun.2017        
    * @description  edits the credit intention form
    * @revision     
    *******************************************************************************/
    editCreditIntention : function (component, event, helper) {
        //helper.toggleEditing(component);
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         19.Jun.2017        
    * @description  cancels edit mode
    * @revision     
    *******************************************************************************/
    cancelEdit : function (component, event, helper) {
        var appRec = component.get("v.applicationRecord");
        component.set("v.applyForCredit", appRec.Applying_for_Credit__c);
        //helper.toggleEditing(component);
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         19.Jun.2017        
    * @description  saves the credit intention
    * @revision     
    *******************************************************************************/
    saveCreditIntention : function (component, event, helper) {
        var applyForCredit = component.get("v.applyForCredit");
        if (applyForCredit == '' || applyForCredit == null) {
            var creditOptions = component.find("creditOptions");
            creditOptions.set("v.errors", [{message:"Credit intention is required"}]);
            component.set("v.errorMessage", 'There are errors on your page. Please review your form.');
            window.location.hash = '#ci_errorDiv';
        } else {
            helper.clearError_onChange(component, event);
        }
        helper.updateApplicationRecord(component);
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         9.Apr.2017         
    * @description  set value on change of country 
    * @revision     
    *******************************************************************************/
    creditOptions_onChange: function(component, event, helper) {
        helper.clearError_onChange(component, event);
    },
    
    /*******************************************************************************
    * @author       Ant Custodio
    * @date         22.Feb.2018        
    * @description  this method sends an API callout to online credit then opens 
	*					a new tab for the applicants to fill up
    * @revision     
    *******************************************************************************/
    /*openOnlineCreditForm : function (component, event, helper) {
    	helper.onlineCreditCalloutById(component);
    },*/
})