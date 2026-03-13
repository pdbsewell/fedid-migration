({
    showSpinner:function(component, toShow)
    {
        component.set("v.showSpinner", toShow);
    }
    
	,doReloadComponent : function(component) {
        
        var action = component.get("c.retrieveApplicantCitizenship");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // Notify the user with the value returned from the server
                console.log("From server: ");
                console.log(response.getReturnValue());
                if(response.getReturnValue() === "INT-TEP" || response.getReturnValue() == 'INTRNTNL')
                    component.set("v.residency_Status", "true");
            }
            else if (state === "INCOMPLETE") {
                console.log("From server: " + 'INCOMPLETE');
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
		
	},

	getAndSetTheAppID : function(component)
    {
        var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var sParameterName;
		var i, j;

        var retrievedAppId = '';
        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('='); //to split the key from the value.
            for (j = 0; j < sParameterName.length; j++) {
                if (sParameterName[j] === 'appId') { //get the app Id from the parameter
                    retrievedAppId = sParameterName[j+1];
                    component.set("v.appId", retrievedAppId);
                }
            }
		}
    }
})