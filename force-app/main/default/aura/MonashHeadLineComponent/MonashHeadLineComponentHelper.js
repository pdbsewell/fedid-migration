({
    getUserFirstName : function(component) {
        var action = component.get("c.getUserFirstName");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.firstName", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    }
})