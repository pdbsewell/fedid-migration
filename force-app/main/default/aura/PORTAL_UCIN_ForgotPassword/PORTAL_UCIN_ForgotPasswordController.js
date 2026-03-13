({
    /**
     * On init
     * 
     * @param component     The Donation Form component
     */
    onInit: function(component, event, helper) {
        
    },
    
    /**
     * On submit button clicked
     * 
     * @param component     The Donation Form component
     */
    handleForgotPassword: function (component, event, helper) {
        helper.handleForgotPassword(component, event, helper);
    },
        
    /**
     * On username text input keyup
     * 
     * @param component     The Forgot Password component
     */
    onKeyUp: function(component, event, helper){
        //checks for "enter" key
        if (event.getParam('keyCode')===13) {
            helper.handleForgotPassword(component, event, helper);
        }
    }
})