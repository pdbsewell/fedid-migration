({
	init : function(component, event, helper) {
        var today = new Date();
        var monthDigit = today.getMonth() + 1;
        if (monthDigit <= 9) {
            monthDigit = '0' + monthDigit;
        }
        component.set('v.today', today.getFullYear() + "-" + monthDigit + "-" + (('0' + today.getDate()).slice(-2)));
        //Hide spinner
		component.set('{!v.showSpinner}', false);
    },
    userUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "CHANGED") {
            // get the fields that are changed for this record
            //var changedFields = eventParams.changedFields;
            //console.log('Fields that are changed: ' + JSON.stringify(changedFields));
            //console.log("Record is successfully updated.");
        } else if(eventParams.changeType === "LOADED") {
            //console.log("Record is loaded successfully.");
        } else if(eventParams.changeType === "REMOVED") {
            //var resultsToast = $A.get("e.force:showToast");
            //resultsToast.setParams({
            //    "title": "Deleted",
            //    "message": "The record was deleted."
            //});
            //resultsToast.fire();
        } else if(eventParams.changeType === "ERROR") {
            //console.log('Error: ' + component.get("v.error"));
        }
    },
	handleLoad: function(component, event, helper) {
	    //Retrive current user fields
		// var currentUserQueue = event.getParam('recordUi').record.fields.Queue__c.value;
        // var currentUserLocation = event.getParam('recordUi').record.fields.Location__c.value;
        // var currentUserEnquiryRole = event.getParam('recordUi').record.fields.Enquiry_Role__c.value;
        
		//Open utility bar if not all of the my information fields are populated
		//if(currentUserQueue == null || currentUserLocation == null || currentUserEnquiryRole == null){
    	//	var utilityAPI = component.find('utilitybar');
        //    utilityAPI.openUtility();
		//}
		
		//Hide spinner
		component.set('{!v.showSpinner}', false);
	},
	handleSubmit : function(component, event, helper) {
	    //Show spinner
		component.set('{!v.showSpinner}', true);
		
	    //Initialize variables
	    var currentUserQueue = event.getParam('fields').Queue__c;
        var currentUserLocation = event.getParam('fields').Location__c;
        var currentUserEnquiryRole = event.getParam('fields').Enquiry_Role__c;
        
        //Close utility bar if all of the my information fields are populated
		if(!currentUserQueue || !currentUserLocation || !currentUserEnquiryRole){
		    //Show error toast
    	    var toastEvent = $A.get('e.force:showToast');
            toastEvent.setParams({
                'type': 'error',
                'title': 'Error!',
                'message': 'Please populate My Information enquiry defaults fields.'
            });
            toastEvent.fire();
	    
    	    //Hide spinner
    		component.set('{!v.showSpinner}', false);
            
            //Stop form submission
            event.preventDefault();
		}
	    
	    //Highlight queue field as error
	    if(!currentUserQueue){
	        $A.util.addClass(component.find('userQueueField'), 'slds-has-error');
	    }else{
	        $A.util.removeClass(component.find('userQueueField'), 'slds-has-error');
	    }
	    //Highlight location field as error
	    if(!currentUserLocation){
	        $A.util.addClass(component.find('userLocationField'), 'slds-has-error');
	    }else{
	        $A.util.removeClass(component.find('userLocationField'), 'slds-has-error');
	    }
	    //Highlight enquiry role field as error
	    if(!currentUserEnquiryRole){
	        $A.util.addClass(component.find('userEnquiryRoleField'), 'slds-has-error');
	    }else{
	        $A.util.removeClass(component.find('userEnquiryRoleField'), 'slds-has-error');
	    }
	},
	handleSuccess : function(component, event, helper) {
	    //Initialize variables
	    var currentUserQueue = component.get('{!v.currentUser}').Queue__c;
        var currentUserLocation = component.get('{!v.currentUser}').Location__c;
        var currentUserEnquiryRole = component.get('{!v.currentUser}').Enquiry_Role__c;
        
	    //Show success toast
	    var toastEvent = $A.get('e.force:showToast');
        toastEvent.setParams({
            'type': 'success',
            'title': 'Success!',
            'message': 'Successfully updated your enquiry defaults.'
        });
        toastEvent.fire();
        
        //Close utility bar if all of the my information fields are populated
        var utilityAPI = component.find('utilitybar');
        utilityAPI.minimizeUtility();
		
	    //Hide spinner
		component.set('{!v.showSpinner}', false);
	}
})