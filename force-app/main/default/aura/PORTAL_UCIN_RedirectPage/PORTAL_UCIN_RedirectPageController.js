({
	/**
     * On init, navigate to message page
     * 
     * @param component     The RedirectPage component
     */
    onInit : function (component, event, helper) {
        let getBaseURL = component.get("c.SERVER_getDomainName");
		getBaseURL.setCallback(this, function(response) {
            let url = response.getReturnValue() + '/s/monash-messages/';
            window.location.replace(url); 
		});
        $A.enqueueAction(getBaseURL);
    }
})