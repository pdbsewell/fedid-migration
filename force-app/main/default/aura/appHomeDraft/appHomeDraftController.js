({

	/**
	 * Initial loading function, retrieves a JSON from the apex CC, helper function then updates the attributes to
	 * display the draft application (as a list of ACPs) in a table
	 * @param component
	 * @param event
	 * @param helper
	 */
	doInit: function (component, event, helper) {
		helper.showDraftSpinner(component, true);
        helper.initialise(component);
	},

	/**
	 * based on the progress status of the draft application, redirects to the appropriate page
	 * @param component
	 * @param event
	 * @param helper
	 */
	editApplication:function (component, event, helper)
	{
		helper.showDraftSpinner(component, true);

		var app = component.get("v.application");
		var status = app.Submission_Progress__c;

		//console.log('app progress = ' + status);

		var path = '';
		switch (status) {
			case 'Study Preferences':
				path = '/course-selection';
			case 'Declaration':
				path ='/signup-declaration';
			case 'Personal Details':
				path = '/personal-details';
			case 'Credentials':
				path = '/qualifications-work-experience';
			case 'Scholarship':
				path = '/external-scholarship';
			case 'Documents':
				path = '/document-upload';
			case 'Application Fee':
				path = '/payment';
			case 'Submit':
				path = '/submission-declaration';
			case 'Review':
				path = '/review';
			default:
				path = '/signup-declaration';
		}

		var address = path + '?appId=' + app.Id;
		var urlEvent = $A.get("e.force:navigateToURL");
		urlEvent.setParams({
			"url": address,
			"isredirect" :false
		});
		urlEvent.fire();
	},

	/**
	 * On clicking 'cancel application', show the cancel confirmation popup
	 * @param component
	 * @param event
	 * @param helper
	 */
	showCancelModal:function (component, event, helper)
	{
		component.set("v.showConfirmCancel", true);
	},

	/**
	 * close the confirmation popup
	 * @param component
	 * @param event
	 * @param helper
	 */
	closeConfirmCancel:function(component, event, helper)
	{
		component.set("v.showConfirmCancel", false);
	},

	/**
	 * Cancel the application by making an apex call to delete the record.
	 * On completion, refreshes the table (which should be blank)
	 * @param component
	 * @param event
	 * @param helper
	 */
	confirmCancel:function(component, event, helper)
	{
		helper.showDraftSpinner(component, true);

		var appToDelete = component.get("v.application");
		var action = component.get("c.cancelApplication");
		action.setParams(
			{
				"application": appToDelete
			}
		)
		action.setCallback(this, function (response) {
			//Get State
			var state = response.getState();
			if (state == "SUCCESS") {
				console.log('appHomeDraftController::cancelApplication');
				$A.get('e.force:refreshView').fire();
			}
		});
		$A.enqueueAction(action);
        component.set("v.showConfirmCancel", false);
	}

})