({
	init : function(component, event, helper) {
	    //Setup the correct form format
	    helper.prepopulateContact(component, event, helper);
	},
	userUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "CHANGED") {
        } else if(eventParams.changeType === "LOADED") {
            //Default My Information details to the enquiry form
            helper.defaultEnquiryMyInformation(component, event);
            
            //Set Progress Indicator
            component.set('v.progressCurrentStep', '2');
            component.set('v.progressDescription', 'Defaulting Enquiry Values');
        } else if(eventParams.changeType === "REMOVED") {
        } else if(eventParams.changeType === "ERROR") {
        }
    },
    handleLoad: function(component, event, helper) {
	    //Set Progress Indicator
        component.set('v.progressCurrentStep', '3');
        component.set('v.progressDescription', 'Generating Enquiry');
		// MC-815 - APRivera - Prod Defect:Fix Enquiry Duplication
        if(component.get('v.isProcessed') === undefined || component.get('v.isProcessed') === false){
            //Submit form after successfull load
            component.find('quickCreateEnquiryForm').submit();
            component.set('v.isProcessed', true);
        }
	},
	handleSubmit : function(component, event, helper) {
	    
	},
	handleSuccess : function(component, event, helper) {
	    //Show success toast
	    var toastEvent = $A.get('e.force:showToast');
        toastEvent.setParams({
            'type': 'success',
            'title': 'Success!',
            'message': 'Successfully created Enquiry.'
        });
        toastEvent.fire();
        
        var payload = event.getParams().response;
        
        //Navigate to the newly created enquiry
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
          "recordId": payload.id,
          "slideDevName": "related"
        });
        navEvt.fire();
		
		var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
	}
})