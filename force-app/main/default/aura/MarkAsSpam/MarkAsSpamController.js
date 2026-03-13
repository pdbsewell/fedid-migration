({
    init: function (component, event, helper) {

    },
    cancel: function (component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    confirm: function (component, event, helper) {
        component.set("v.isLoading", true);

        let action = component.get("c.markAsSpam");
        action.setParams({
            "recordId": component.get("v.recordId")
        });

        action.setCallback(this, function (response) {
            component.set("v.isLoading", false);

            let state = response.getState();
            
            if (state === "SUCCESS") {
                $A.get("e.force:refreshView").fire();
                $A.get("e.force:closeQuickAction").fire();
            } else if (state === "ERROR") {
                let errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        let toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "message": errors[0].message
                        });
                        toastEvent.fire();
                    }
                } else {
                    console.log("Unknown error");
                }
            } else {
                console.log(state);
            }
        });

        $A.enqueueAction(action);
    }
})