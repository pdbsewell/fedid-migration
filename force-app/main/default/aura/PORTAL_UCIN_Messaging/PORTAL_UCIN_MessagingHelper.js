({
    queryContact : function(component, helper) {
        var action = component.get("c.SERVER_getContactInfo");
       // console.log(component.get("v.contactId"));
        action.setParams({"contactId": component.get("v.contactId")});
        action.setCallback(this,function(response) {
            var state = response.getState();
            var result = response.getReturnValue();

           // console.log('State: ' + state);

            if(state ==="SUCCESS") {
                component.set("v.contact", result);
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
                        "message": "Error."
                    });
                   // console.log(error[0].message)
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
        component.set("v.loaded", false);
        $A.enqueueAction(action);
    },

    sendMessage: function(component, helper) {
        var action = component.get("c.SERVER_sendDirectMessage");
        action.setParams({
            "toContactId": component.get("v.contactId"),
            "subject": component.get("v.subject"),
            "body": component.get("v.body")
        });
        action.setCallback(this,function(response) {
            var state = response.getState();
            var result = response.getReturnValue();

           // console.log('State: ' + state);

            if(state ==="SUCCESS") {
                // Show success toast
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "type": "Success",
                    "message": "Message Sent."
                });
                toastEvent.fire();
                component.find("overlayModal").notifyClose();
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
        component.set("v.loaded", false);
        $A.enqueueAction(action);
    }
})