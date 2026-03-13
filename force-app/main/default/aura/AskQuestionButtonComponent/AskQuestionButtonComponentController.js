({
    redirectContactSupport : function(component, event, helper) {      
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/member-visitor"
        });
        urlEvent.fire();
    }
})