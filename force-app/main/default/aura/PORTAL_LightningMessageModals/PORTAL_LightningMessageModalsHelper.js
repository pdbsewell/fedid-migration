({
    // ************* On fired of an PORTAL_EVT_LightningMessage *************
    handleMessage : function(component, event, helper) {
        //If component Event, else is application event
        var message;
        var messageType;

        var params = event.getParam('arguments');

        if (params && "message" in params) {
            message = params.message;
            messageType = params.messageType;
        } else {
            message = event.getParam("message");
            messageType = event.getParam("messageType");
        }

        var messageExists = component.get("v.messageExists");
        var currentMessageType = component.get("v.messageType");

        if (message != undefined && messageType != undefined && (messageExists == false || (messageType == 'SystemError' && currentMessageType != 'SystemError'))) {

            if (document.getElementById("spinner")) {
                document.getElementById("spinner").className = "slds-hide";
            }

            if (messageType === 'SystemError') {

                // System takes highese priority to be shown

                // Set the exists to be true, not allowing other over-writing the existing
                // TODO: Append to the log, so user can see more according ordered by the time (oldest first)
                component.set("v.messageExists", true);
                component.set("v.messageType", messageType);

                // Set the received message
                component.set("v.message", message);

                // Show the block
                var messageBox = component.find("sysErrorMessage");
                $A.util.removeClass(messageBox, 'slds-hide');
                $A.util.addClass(messageBox, 'slds-show');
            }
            else if (messageType === 'ValidationError') {
                // Set the exists to be true, not allowing other over-writing the existing
                // TODO: Append to the log, so user can see more according ordered by the time (oldest first)
                component.set("v.messageExists", true);
                component.set("v.messageType", messageType);

                // Set the received message
                component.set("v.message", message);

                // Show the block
                var messageBox = component.find("validationErrorMessage");
                $A.util.removeClass(messageBox, 'slds-hide');
                $A.util.addClass(messageBox, 'slds-show');
            }
            else if (messageType === 'WarningError') {
                component.set("v.messageExists", true);
                component.set("v.messageType", messageType);

                // Set the received message
                component.set("v.message", message);

                // Show the block
                var messageBox = component.find("warningErrorMessage");
                $A.util.removeClass(messageBox, 'slds-hide');
                $A.util.addClass(messageBox, 'slds-show');
            }
            else if (messageType === 'Confirmation') {
                // TODO: Feature Requested
                component.set("v.messageExists", true);
                component.set("v.messageType", messageType);

                // Set the received message
                component.set("v.message", message);

                // Show the block
                var messageBox = component.find("confirmationMessage");
                $A.util.removeClass(messageBox, 'slds-hide');
                $A.util.addClass(messageBox, 'slds-show');
            }
        }
    }
})