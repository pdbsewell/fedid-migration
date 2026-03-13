({
	enquiryUpdated : function(component, event, helper) {
		var eventParams = event.getParams();
        if(eventParams.changeType === "CHANGED") {
        } else if(eventParams.changeType === "LOADED") {
            
            //Hide spinner on original component
    	    component.set('v.showEnquiryDescriptionSpinner', false);
            
        } else if(eventParams.changeType === "REMOVED") {
        } else if(eventParams.changeType === "ERROR") {
        }
	}
})