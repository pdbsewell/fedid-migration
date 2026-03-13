({  
    /**
     * Handle forgot password
     * 
     * @param component     The Donation Form component
     */
    handleForgotPassword: function (component, event, helper) {
        var username = component.find("username").get("v.value");
        var usernameLabel = component.get("v.usernameLabel");
        var usernameErrorMessage = component.get("v.usernameErrorMessage");
        var checkEmailUrl = component.get("v.checkEmailUrl");
        var action = component.get("c.forgotPassword");
        var validated = true;
        
        component.set("v.usernameErrorMessage", "");
        if ($A.util.isEmpty(username)) {
            validated = false;
            component.set("v.usernameErrorMessage", "Please enter "+usernameLabel+".");
        }
        
        if (validated) {
            action.setParams({username:username, checkEmailUrl:checkEmailUrl});
            action.setCallback(this, function(a) {
                var rtnValue = a.getReturnValue();
                var state = a.getState();

                if(state ==="SUCCESS") {
                    if (rtnValue != null) {
                        component.find('notifLib').showNotice({
                            "variant": "error",
                            "header": "Error",
                            "message": rtnValue
                        });
                    }
                } 
                else if (state === "INCOMPLETE") {
                    component.find('notifLib').showNotice({
                        "variant": "error",
                        "header": "Error",
                        "message": "Incomplete error."
                    });
                }
                else if (state === "ERROR") {
                    let error = response.getError();
                    if (error && error[0] && error[0].message) {
                        component.find('notifLib').showNotice({
                            "variant": "error",
                            "header": "Error",
                            "message": error[0].message
                        });
                    }
                    else {
                        component.find('notifLib').showNotice({
                            "variant": "error",
                            "header": "Error",
                            "message": "Error."
                        });
                    }
                }                
                component.set("v.loaded", true);

            });
            $A.enqueueAction(action);
            component.set("v.loaded", false);
        }
    }
})