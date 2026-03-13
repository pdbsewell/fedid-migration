({
    /**
     * On init, set Forgot Password Url
     * 
     * @param component     The Login component
     */
    onInit: function(component, event, helper) {
        $A.get("e.siteforce:registerQueryEventMap").setParams({"qsToEvent" : helper.qsToEventMap}).fire();   
        component.set("v.communityForgotPasswordUrl", helper.getCommunityForgotPasswordUrl(component, event, helper));
		helper.getUserNameFromUrl(component, event);
    },
    
    
    /**
     * On Login button clicked
     * 
     * @param component     The Login component
     */
    onLogin: function (component, event, helper) {
        helper.handleLogin(component, event);
    },
    
    /**
     * Set the Start Url
     * 
     * @param component     The Login component
     */
    setStartUrl: function (component, event, helper) {
        var startUrl = event.getParam('startURL');
        if(startUrl) {
            component.set("v.startUrl", startUrl);
        }
    },
    
    /**
     * On text input (username, password) keyup
     * 
     * @param component     The Login component
     */
    onKeyUp: function(component, event, helper){
        //checks for "enter" key
        if (event.getParam('keyCode')===13) {
            helper.handleLogin(component, event);
        }
    },
    
    /**
     * Redirect to Forgot Password page
     * 
     * @param component     The Login component
     */
    navigateToForgotPassword: function(cmp, event, helper) {
        var forgotPwdUrl = cmp.get("v.communityForgotPasswordUrl");
        if ($A.util.isUndefinedOrNull(forgotPwdUrl)) {
            forgotPwdUrl = cmp.get("v.forgotPasswordUrl");
        }
        var startUrl = cmp.get("v.startUrl");
        if(startUrl){
            if(forgotPwdUrl.indexOf("?") === -1) {
                forgotPwdUrl = forgotPwdUrl + '?startURL=' + decodeURIComponent(startUrl);
            } else {
                forgotPwdUrl = forgotPwdUrl + '&startURL=' + decodeURIComponent(startUrl);
            }
        }
        var attributes = { url: forgotPwdUrl };
        $A.get("e.force:navigateToURL").setParams(attributes).fire();
    },
    
    /**
     * Redirect to Activate Account page
     * 
     * @param component     The Login component
     */
    navigateToActivateAccount: function(cmp, event, helper) {
        var activateAccountUrl = cmp.get("v.communityActivateAccountUrl");
        if (activateAccountUrl == null) {
            activateAccountUrl = cmp.get("v.activateAccountUrl");
        }
        var startUrl = cmp.get("v.startUrl");
        if(startUrl){
            if(activateAccountUrl.indexOf("?") === -1) {
                activateAccountUrl = activateAccountUrl + '?startURL=' + decodeURIComponent(startUrl);
            } else {
                activateAccountUrl = activateAccountUrl + '&startURL=' + decodeURIComponent(startUrl);
            }
        }
        var attributes = { url: activateAccountUrl };
        $A.get("e.force:navigateToURL").setParams(attributes).fire();
    },
    
    /**
     * Login with Facebook
     * 
     * @param component     The Login component
     */
    navigateToConnectWithFacebook: function(cmp, event, helper) {
        var connectWithFacebookUrl = cmp.get("v.connectWithFacebookUrl");
        var attributes = { url: connectWithFacebookUrl };
        $A.get("e.force:navigateToURL").setParams(attributes).fire();
    },
    
    
    /**
     * Login with LinkedIn
     * 
     * @param component     The Login component
     */
    navigateToConnectWithLinkedIn: function(cmp, event, helper) {
        var connectWithLinkedInUrl = cmp.get("v.connectWithLinkedInUrl");
        var attributes = { url: connectWithLinkedInUrl };
        $A.get("e.force:navigateToURL").setParams(attributes).fire();
    }
})