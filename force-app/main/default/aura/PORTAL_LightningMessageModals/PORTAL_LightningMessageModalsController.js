({
    handleComponentMessageEvent : function(component, event, helper) {
        helper.handleMessage(component, event, helper);
    },

    handleApplicationMessageEvent : function(component, event, helper) {
        helper.handleMessage(component, event, helper);
    },

    // ************* When user clicks 'ok' to the System Error Message *************
    okButtonClickedForSysError : function(component, event, helper) {

        component.set("v.messageExists", false);
        var messageBox = component.find("sysErrorMessage");
        $A.util.removeClass(messageBox, 'slds-show');
        $A.util.addClass(messageBox, 'slds-hide');
    },

    // ************* When user clicks 'ok' to the System Error Message *************
    okButtonClickedForValidationError : function(component, event, helper) {

        component.set("v.messageExists", false);
        var messageBox = component.find("validationErrorMessage");
        $A.util.removeClass(messageBox, 'slds-show');
        $A.util.addClass(messageBox, 'slds-hide');
    },

    // ************* When user clicks 'ok' to the System Wanring Message *************
    okButtonClickedForWarningError : function(component, event, helper) {

        component.set("v.messageExists", false);
        var messageBox = component.find("warningErrorMessage");
        $A.util.removeClass(messageBox, 'slds-show');
        $A.util.addClass(messageBox, 'slds-hide');
    },
    // ************* When user clicks 'ok' to the Confirmation Message *************
    okButtonClickedForConfirmation: function(component, event, helper) {

        component.set("v.messageExists", false);
        var messageBox = component.find("confirmationMessage");
        $A.util.removeClass(messageBox, 'slds-show');
        $A.util.addClass(messageBox, 'slds-hide');
    }
})