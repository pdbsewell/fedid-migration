({
	doInit : function(component, event, helper) {

		var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var sParameterName;
		var i, j;

        var retrievedAppId = '';
        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('='); //to split the key from the value.
            for (j = 0; j < sParameterName.length; j++) {
                if (sParameterName[j] === 'appId') { //get the app Id from the parameter
                    retrievedAppId = sParameterName[j+1];
                }
            }
		}

		if(!retrievedAppId) {
            retrievedAppId = component.get("v.applicationId");
        } else {
            //redirect to the new app form url
            window.location.href = '/admissions/s/application/' + retrievedAppId;
        }

        if (retrievedAppId != '') {
            component.set("v.appId", retrievedAppId);
		}

        helper.initHelper(component, retrievedAppId);
	},

    /**
	 * @description TODO
	 */
	showHideComponent : function (component, event, helper) {
        var isExpanded = component.get("v.isExpanded");
        
        if (isExpanded) {
            isExpanded = false;
        } else {
            isExpanded = true;
        }
		component.set("v.isExpanded", isExpanded);
    },
    
    /**
	 * @description TODO
	 */
	payFee : function(component, event, helper) {
        //Check to get the information from the form
		var isFeeRequired = component.get("v.feeRequired");
		var appId = component.get("v.appId");
        //Fee is required, continue with the process.
        helper.processPayment(component, appId);
    },

    /**
	 * @description TODO
	 */
    checkValidWaiver : function(component, event, helper) {
        var code = component.get("v.waiverCode");
        component.set("v.verifyWaiverLoading", true);
        helper.validateWaiver(component, code, component.get("v.appId"));
    },
    
    /**
	 * @description TODO
	 */
    submitWaiverCode : function(component, event, helper) {
        var code = component.get("v.waiverCode");
        var appId = component.get("v.appId");
        helper.submitWaiver(component, code, appId);
    },
    
    /**
	 * @description TODO
	 */
    updateOption : function(component, event, helper) {
        //Get the selected option from the user
        var selection = component.get("v.selectedPayment");
        
        component.set("v.westernUnionToggle", false);
        component.set("v.feewaiverToggle", false);
        component.set("v.otherToggle", false);

        if(selection == "Western Union"){
            component.set("v.westernUnionToggle", true);
        } else if(selection == "Application Fee Waiver Code"){
            component.set("v.feewaiverToggle", true);
            var code = component.get("v.waiverCode");
            var appId = component.get("v.appId");
        } else if(selection == "Other"){
            component.set("v.otherToggle", true);
        }

        var action = component.get("c.savePaymentType");
        action.setParams({
            "appId" :  component.get("v.appId"),
            "paymentType" : selection
        });

        action.setCallback(this, function(response) {
            if(response.getState() === 'SUCCESS') { }
        });
        $A.enqueueAction(action);
    },
})