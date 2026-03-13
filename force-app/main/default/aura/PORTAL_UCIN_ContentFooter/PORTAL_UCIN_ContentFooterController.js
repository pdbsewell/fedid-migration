({
	doInit : function(component, event, helper) {
		component.set("v.isDesktop", $A.get('$Browser.isDesktop'));
	}
})