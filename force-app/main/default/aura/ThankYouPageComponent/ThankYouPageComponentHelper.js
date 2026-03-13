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
        
        var homePage = component.get("c.getHomePageUrl");
        homePage.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.homePageUrl", response.getReturnValue());
            }
        });
        $A.enqueueAction(homePage);
    },
    redirectHomepage : function(component,event) {
        
        window.open(component.get("v.homePageUrl"), '_self');
    }
})