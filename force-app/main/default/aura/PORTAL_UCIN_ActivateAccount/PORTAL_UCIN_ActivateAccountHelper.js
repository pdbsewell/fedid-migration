({
    /**
     * Load contact qualification degree levels
     * 
     * @param component     The Activate Account component
     */
	loadDegrees: function(component, event){
        var action = component.get("c.getContactQualificationDegreeLevels");
        action.setCallback(this, function(a){
            var state = a.getState();

            if(state ==="SUCCESS") {
                component.set("v.degreeOptions", a.getReturnValue());
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
    },
    
    /**
     * Load Date of Birth dropdown selections
     * 
     * @param component     The Activate Account component
     */
	loadDateSelectors: function(component, event){
        var today = new Date();
        var years = [];
        for (var y=today.getYear()-13; y>today.getYear()-200; y--) {
            years.push(1900+y);
        }
        component.set("v.birthdateYearOptions", years);
    },
    
    /**
     * Handle Account Activation
     * 
     * @param component     The Activate Account component
     */
	handleActivateAccount: function (component, event) {
        var verificationCode = document.getElementById("tbxVerificationCode").value;
        var firstname = document.getElementById("tbxFirstname").value;
        var lastname = document.getElementById("tbxLastname").value;
        var birthdateDay = document.getElementById("ddlBirthdateDay").options[document.getElementById("ddlBirthdateDay").selectedIndex].value;
        var birthdateMonth = document.getElementById("ddlBirthdateMonth").options[document.getElementById("ddlBirthdateMonth").selectedIndex].value;
        var birthdateYear = document.getElementById("ddlBirthdateYear").options[document.getElementById("ddlBirthdateYear").selectedIndex].value;
        var birthdate = "";
        var degree = document.getElementById("ddlDegree").options[document.getElementById("ddlDegree").selectedIndex].value;
        var verificationCodeLabel = component.get("v.verificationCodeLabel");
        var firstnameLabel = component.get("v.firstnameLabel");
        var lastnameLabel = component.get("v.lastnameLabel");
        var birthdateLabel = component.get("v.birthdateLabel");
        var degreeLabel = component.get("v.degreeLabel");
        var verificationCodeErrorMessage = component.get("v.verificationCodeErrorMessage");
        var firstnameErrorMessage = component.get("v.firstnameErrorMessage");
        var lastnameErrorMessage = component.get("v.lastnameErrorMessage");
        var birthdateErrorMessage = component.get("v.birthdateErrorMessage");
        var degreeErrorMessage = component.get("v.degreeErrorMessage");
        var action = component.get("c.activateAccount");
        var checkEmailUrl = component.get("v.checkEmailUrl");
        var validated = true;
        
        checkEmailUrl = decodeURIComponent(checkEmailUrl);
        
        component.set("v.verificationCodeErrorMessage", "");
        if ($A.util.isEmpty(verificationCode)) {
            validated = false;
            component.set("v.verificationCodeErrorMessage", "Please enter "+verificationCodeLabel+".");
        }
        
        component.set("v.firstnameErrorMessage", "");
        if ($A.util.isEmpty(firstname)) {
            validated = false;
            component.set("v.firstnameErrorMessage", "Please enter "+firstnameLabel+".");
        }
        
        component.set("v.lastnameErrorMessage", "");
        if ($A.util.isEmpty(lastname)) {
            validated = false;
            component.set("v.lastnameErrorMessage", "Please enter "+lastnameLabel+".");
        }
        
        component.set("v.birthdateErrorMessage", "");
        if ($A.util.isEmpty(birthdateDay) || $A.util.isEmpty(birthdateMonth) || $A.util.isEmpty(birthdateYear)) {
            validated = false;
            component.set("v.birthdateErrorMessage", "Please select "+birthdateLabel+".");
        } else {
            birthdate = birthdateYear.toString()+"-"+birthdateMonth.toString()+"-"+birthdateDay.toString();
        }
        
        component.set("v.degreeErrorMessage", "");
        if ($A.util.isEmpty(degree)) {
            validated = false;
            component.set("v.degreeErrorMessage", "Please select "+degreeLabel+".");
        }
        
        if (validated) {
            action.setParams({
                verificationCode:verificationCode, 
                firstname:firstname, 
                lastname:lastname, 
                birthdate:birthdate, 
                degree:degree, 
                checkEmailUrl:checkEmailUrl
            });
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
                
                this.enableSubmitButton(component, event);
                component.set("v.loaded", true);
            });
            $A.enqueueAction(action);
            component.set("v.loaded", false);
        } else {
            this.enableSubmitButton(component, event);
        }
    },
    
    /**
     * Enable Activate Account button
     * 
     * @param component     The Activate Account component
     */
    enableSubmitButton: function(component, event){
        var btn = component.find("btnSubmit");
        var submitButtonLabel = component.get("v.submitButtonLabel");
        
        if (btn != null) {
            component.set("v.btnSubmitDisabled", false);
            component.set("v.btnSubmitLabel", submitButtonLabel);
        }
    },
    
    /**
     * Disable Activate Account button
     * 
     * @param component     The Activate Account component
     */
    disableSubmitButton: function(component, event){
        var btn = component.find("btnSubmit");
        if (btn != null) {
            component.set("v.btnSubmitDisabled", true);
            component.set("v.btnSubmitLabel", "Processing...");
        }
    },
    
    /**
     * Get Verification Code from the current page querystring
     * 
     * @param component     The Activate Account component
     */
    GetParams: function(component, event){
        var sPageURL = decodeURIComponent(window.location.search.substring(1)),
        sURLVariables = sPageURL.split("&"),
        sParameterName,
        i;

        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split("=");
            if (sParameterName[0] === "tc") {
                component.set("v.activationToken", sParameterName[1]);
            }
        }
    }
})