({
	handleSponsorChange : function(component) {
        var app = component.get("v.application");
        if (this.isUnsafe(app)) {
            var appErrors = ["One or more input boxes are not in the expected format."];
            component.set("v.saveErrors", appErrors);
            component.set("v.showErrors", true);
            return;
        } 

        var action = component.get("c.updateApplicationSponsor");
        action.setParams({
            application: app
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // Notify the user with the value returned from the server
                console.log("From server: ");
                console.log(response.getReturnValue());
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
    }, isUnsafe: function(dataObject) {
        const XML_REGEX_PATTERN = /(<.[^(><.)]+>)/g;
         return XML_REGEX_PATTERN.test(JSON.stringify(dataObject));
     }

})