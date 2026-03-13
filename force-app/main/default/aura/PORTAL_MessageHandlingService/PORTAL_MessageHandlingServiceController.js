({
    errorServerCall: function(component, event) {
        var params = event.getParam('arguments');
        var displayMessage = "Server-side Error occurred";
        if (typeof(params.message) !== "undefined") {
            displayMessage = params.message;
        }
        // var messageEvent = component.getEvent("lightningMessageEvent");
        var messageEvent = $A.get("e.c:PORTAL_EVT_LightningMessage");
        messageEvent.setParams({
            "message": displayMessage,
            "messageType": "SystemError"
        });
        messageEvent.fire();
    },
    incompleteServerCall: function(component, event) {
        var params = event.getParam('arguments');
        var displayMessage = "The operation was incomplete";
        if (typeof(params.message) !== "undefined") {
            displayMessage = params.message;
        }
        // var messageEvent = component.getEvent("lightningMessageEvent");
        var messageEvent = $A.get("e.c:PORTAL_EVT_LightningMessage");
        messageEvent.setParams({
            "message": displayMessage,
            "messageType": "SystemError"
        });
        messageEvent.fire();
    },
    successServerCall: function(component, event) {
        var params = event.getParam('arguments');
        var displayMessage = "Success";
        if (typeof(params.message) !== "undefined") {
            displayMessage = params.message;
        }
        // var messageEvent = component.getEvent("lightningMessageEvent");
        var messageEvent = $A.get("e.c:PORTAL_EVT_LightningMessage");
        messageEvent.setParams({
            "message": displayMessage,
            "messageType": "Confirmation"
        });
        messageEvent.fire();
    },
    validationError: function(component, event) {
        var params = event.getParam('arguments');
        var displayMessage = "Validation Error";
        if (typeof(params.message) !== "undefined") {
            displayMessage = params.message;
        }
        // var messageEvent = component.getEvent("lightningMessageEvent");
        var messageEvent = $A.get("e.c:PORTAL_EVT_LightningMessage");
        messageEvent.setParams({
            "message": displayMessage,
            "messageType": "ValidationError"
        });
        messageEvent.fire();
    },
    warningError: function(component, event) {
        var params = event.getParam('arguments');
        var displayMessage = "Warning";
        if (typeof(params.message) !== "undefined") {
            displayMessage = params.message;
        }
        // var messageEvent = component.getEvent("lightningMessageEvent");
        var messageEvent = $A.get("e.c:PORTAL_EVT_LightningMessage");
        messageEvent.setParams({
            "message": displayMessage,
            "messageType": "WarningError"
        });
        messageEvent.fire();
    }
})