({
    
    qsToEventMap: {
        'startURL'  : 'e.c:setStartUrl'
    },
    
    /**
     * Handle login
     * 
     * @param component     The Login component
     */
    handleLogin: function (component, event) {
        var username = component.find("username").get("v.value");
        var password = component.find("password").get("v.value");
        var usernameLabel = component.get("v.usernameLabel");
        var passwordLabel = component.get("v.passwordLabel");
        var usernameErrorMessage = component.get("v.usernameErrorMessage");
        var passwordErrorMessage = component.get("v.passwordErrorMessage");
        var action = component.get("c.login");
        var startUrl = component.get("v.startUrl");
        var validated = true;
        
        startUrl = decodeURIComponent(startUrl);
        
        component.set("v.usernameErrorMessage", "");
        if ($A.util.isEmpty(username)) {
            validated = false;
            component.set("v.usernameErrorMessage", "Please enter "+usernameLabel+".");
        }
        
        component.set("v.passwordErrorMessage", "");
        if ($A.util.isEmpty(password)) {
            validated = false;
            component.set("v.passwordErrorMessage", "Please enter "+passwordLabel+".");
        }
        
        if (validated) {
            action.setParams({username:username, password:password, startUrl:startUrl});
            action.setCallback(this, function(a){
                var rtnValue = a.getReturnValue();
                var state = a.getState();
                
                if(state ==="SUCCESS") {
                    if (rtnValue !== null) {
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
    },
	
	/**
     * Get username from url
     * 
     * @param component     The Login component
     */
	getUserNameFromUrl : function (component, event) {
        let url = window.location.href;
        if(url.includes('username=')){
            let encodedUrl = decodeURIComponent(url);
            let userName = encodedUrl.substring(encodedUrl.indexOf("username=")+9, encodedUrl.length);  
            component.find("username").set("v.value", userName);
        }
    },
    
    /**
     * Get community forgot password url
     * 
     * @param component     The Login component
     */
    getCommunityForgotPasswordUrl : function (component, event) {
        var action = component.get("c.getForgotPasswordUrl");
        action.setCallback(this, function(a){
            var state = a.getState();

            if(state ==="SUCCESS") {
                var rtnValue = a.getReturnValue();
                if (rtnValue !== null) {
                    component.set('v.communityForgotPasswordUrl',rtnValue);
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
    
})