({

	/**
	 * show/hide the spinner
	 * @param component
	 * @param toShow
	 */
	showDraftSpinner : function(component, toShow) {
		component.set("v.showDraftSpinner", toShow);	
	},
	
    initialise : function(component) {
    	// load
		console.log('appHomeDraftController::doInit');
        
		var action = component.get("c.getInitLoadDrafts");
		action.setCallback(this, function (response) {
			//Get State
			var state = response.getState();
			if (state == "SUCCESS") {
				console.log('appHomeDraftController::getInitLoadDrafts');
				var objResponse = response.getReturnValue();
				this.showDraftTable(component, objResponse);
			}
		});
		$A.enqueueAction(action);
        
	},
	/**
	 * parse the JSON from the apex class, the main field being 'acps' which lists all the acps attached to the draft application
	 * @param component
	 * @param objResponse - the JSON from apex
	 */
	showDraftTable: function (component, objResponse)
	{
		// user
		var objUser = objResponse.user;
		component.set("v.user", objUser);

		var application = objResponse.application;
		component.set("v.application", application);

		if(application)
		{
			// draft applications
			let acps = objResponse.acps;
			component.set('v.acps', acps);
			component.set("v.showComponent", true);
		}

		this.showDraftSpinner(component, false);
	}
})