({
    doInit : function(component, event, helper) {
        let processInterimAction = component.get("c.SERVER_processInterim");
        processInterimAction.setParams({"params":{}});
        processInterimAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                setTimeout(function() {
                    $A.get("e.force:closeQuickAction").fire();
                }, 100);
            } else if (state === "INCOMPLETE") {
                console.log('incomplete');
            } else if (state == "ERROR") {
                console.log('error');
            }
        });
        $A.enqueueAction(processInterimAction);
    }
})