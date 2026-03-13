({
    gettopicList: function(component,event) {
        var action = component.get("c.getTopicList");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                console.log(response.getReturnValue());
                component.set("v.wrapperList", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
    redirectToTopic: function(recId) {
        var navEvt;
        console.log('recId', recId);
        navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": recId,
            "slideDevName": "detail"
        });
        navEvt.fire();
    }
})