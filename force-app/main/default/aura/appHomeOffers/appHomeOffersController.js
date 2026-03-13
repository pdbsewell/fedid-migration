({

    /**
     * Initial loading function. Main logic is in helper.formatACPs, see comments there.
     * @param component
     * @param event
     * @param helper
     */
	doInit : function(component, event, helper) {
		helper.showOffersSpinner(component, true);

		var action = component.get("c.getInitLoadOffers");
		action.setCallback(this, function (response) {
			//Get State
			var state = response.getState();

			if (state == "SUCCESS") {
				var objResponse = response.getReturnValue();

				// user
				var objUser = objResponse.user;
				component.set("v.user", objUser);

				// submitted applications
				var applications = objResponse.submittedApplications;

				helper.formatACPs(component, applications);

                helper.showOffersSpinner(component, false);

			}
		});
		$A.enqueueAction(action);
	}

    /**
     * On clicking the 'respond to offer' button, we need to retrieve the related ACP by the Id stored on the button,
     * then show the popup.
     * @param component
     * @param event
     * @param helper
     */
	, respondToACP:function(component, event, helper)
	{
        var btn = event.getSource();
        var acpId = btn.get('v.name');
        component.set("v.selectedACPId", acpId);
		helper.getACPById(component, acpId);
        helper.mockFullOffer(component);
        component.set("v.showResponsePopup", true);
	},

    /**
     * close the popup and clear the temp attribute
     * @param component
     * @param event
     * @param helper
     */
	closeRespondPopup:function (component, event, helper)
	{
		component.set("v.selectedACPId", null);
		component.set("v.showResponsePopup", false);
    },
    closeConfirmPopup:function(component)
    {
            component.set("v.showConfirmPopup", false);
            component.set("v.selectedACPId", null);
    },


    closeCongratsPopup:function (component, event, helper)
	{
		component.set("v.selectedACPId", null);
		component.set("v.showCongratsPopup", false);
    },

    /**
     * On clicking reject offoer, show the confirm rejection popup
     * @param component
     * @param event
     * @param helper
     */
    rejectACP:function (component, event, helper)
	{
        component.set("v.showResponsePopup", false);
		component.set("v.showConfirmReject", true);
    }

    /**
     * Close the confirm rejection popup
     * @param component
     * @param event
     * @param helper
     */
    , closeConfirmReject:function (component ,event, helper)
	{
        component.set("v.showConfirmReject", false);
        component.set("v.showResponsePopup", true);
           //component.set("v.selectedACP", null);
           //     component.set("v.selectedACPId", null);
    }

    /**
     * On confirmation of rejecting the offer:
     * 1. make an apex call to update the ACP status
     * 2. reload the list of ACPs
     * @param component
     * @param event
     * @param helper
     */
    , confirmReject:function(component, event, helper)
	{
        helper.showOffersSpinner(component, true);
        var acp = component.get("v.selectedACP");

        var action = component.get("c.doRejectACP");
        action.setParams({
            "acp": acp
        });
        action.setCallback(this, function (response) {
            //Get State
            var state = response.getState();
            if (state == "SUCCESS") {

                var objResponse = response.getReturnValue();

                // submitted applications
                var applications = objResponse.submittedApplications;
                helper.formatACPs(component, applications);
                helper.backToOffersStart(component, 'reject');
            }
        });
        $A.enqueueAction(action);
	},


    /**
     * On accepting an offer:
     * 1. make an apex call to update the ACP status
     * 2. reload the list of ACPs
     * @param component
     * @param event
     * @param helper
     */
    acceptACP:function (component, event, helper)
	{
        helper.showOffersSpinner(component, true);
        var acp = component.get("v.selectedACP");

        var action = component.get("c.doAcceptACP");
        action.setParams({
            "acp": acp
        });
        action.setCallback(this, function (response) {
            //Get State
            var state = response.getState();
            if (state == "SUCCESS") {
                var objResponse = response.getReturnValue();

                // submitted applications
                var applications = objResponse.submittedApplications;
                helper.formatACPs(component, applications);

                helper.backToOffersStart(component, 'accept');
            }
        });
        $A.enqueueAction(action);
    }


    /**
     * On clicking 'Add Document' button, redirect to the Application Review page for this Application, and anchored
     * to the documents div
     * @param component
     * @param event
     * @param helper
     */
    , addDocument:function (component, event, helper)
    {
        var btn = event.getSource();
        var appId = btn.get('v.name');
        var path = '/applicationreview';
        var url = path + '?appId=' + appId +'&show=documents';

        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": url,
            "isredirect" :false
        });
        urlEvent.fire();
    },

    goToApplicationDetails : function (component, event, helper)
    {
        var btn = event.getSource();
        var appId = btn.get('v.name');
        var path = '/applicationreview';
        var url = path + '?appId=' + appId +'&show=details';

        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": url,
            "isredirect" :false
        });
        urlEvent.fire();
    }
})