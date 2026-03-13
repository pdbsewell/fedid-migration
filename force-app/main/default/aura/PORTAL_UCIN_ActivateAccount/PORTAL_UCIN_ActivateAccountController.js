({
    /**
     * On init
     * 
     * @param component     The Activate Account component
     */
    onInit: function(component, event, helper) {
        helper.GetParams(component, event);
        helper.loadDateSelectors(component, event);
        helper.loadDegrees(component, event);
        helper.enableSubmitButton(component, event);
    },
    
    /**
     * On component render, pre-populate Verification Code
     * 
     * @param component     The Activate Account component
     */
    onRender: function(component, event, helper) {
        //Input verification code when loaded
        var activationToken = component.get("v.activationToken");
        if (activationToken != null && document.getElementById("tbxVerificationCode") != null) {
            if (activationToken != "") {
                document.getElementById("tbxVerificationCode").value = activationToken;
                component.set("v.activationToken", "");
            }
        }
    },
    
    /**
     * On Activate Account button clicked, disable button and perform activation
     * 
     * @param component     The Activate Account component
     */
    onActivateAccount: function (component, event, helper) {
        helper.disableSubmitButton(component, event);
        helper.handleActivateAccount(component, event);
    }
})