({
	doInit : function (component, event, helper) {
        helper.loadTiles(component, event);
        helper.getBaseURL(component, event, helper);
        helper.getSSOACSURL(component, event, helper);

        component.set("v.formFactor", $A.get('$Browser.formFactor'));
    }
})