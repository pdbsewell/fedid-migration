({
	doInit : function(component, event, helper){
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
                }
            }
		}
		
        if (retrievedAppId != '') {
            component.set("v.application.Id", retrievedAppId);
		}
		helper.getDetails(component, retrievedAppId);
	},

	showHideComponent : function (component, event, helper) {
        var isExpanded = component.get("v.isExpanded");
        
        if (isExpanded) {
            isExpanded = false;
        } else {
            isExpanded = true;
        }
		component.set("v.isExpanded", isExpanded);
    },

	//Updates the guardian details into the Application form
	updateGuardian : function(component, event, helper){
		var guardianDetails = component.get("v.application");
		helper.updateDetails(component, guardianDetails);
    }
})