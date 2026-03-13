({
	showSpinner: function (component, event, helper) {
        var spinner = component.find("spinner");
        $A.util.removeClass(spinner, "slds-hide");
    },
     
    hideSpinner: function (component, event, helper) {
        var spinner = component.find("spinner");
        $A.util.addClass(spinner, "slds-hide");
	},

	updateDetails : function(component, details){
		this.showSpinner(component);
		var action = component.get("c.saveApplication");
		action.setParams({
			"app":details
		});
		action.setCallback(this, function(response){
			var state = response.getState();
			if(state === "SUCCESS"){
				component.set("v.application", response.getReturnValue());
			}
			this.hideSpinner(component);
		});
		$A.enqueueAction(action);
	},

	getDetails : function(component, appId){
		var action = component.get("c.getApplicationFields");
		action.setParams({
			"appId": appId
		});
		action.setCallback(this, function(response){
			var state = response.getState();
			if(state === "SUCCESS"){
				var data = response.getReturnValue();
				component.set("v.application", data["Application"]);
				component.set("v.under18", data["Under18"]);
				component.set("v.internationalStudent", data["International"]);
			}
		});
		$A.enqueueAction(action);
	}
})