({
	/**
	 * @description fetches all the data necessary to initialise the component
	 */
	initHelper : function(component, applicationId) {
		let action = component.get("c.getInitData");
		action.setParams({
			"applicationId" : applicationId
		});

		action.setCallback(this, function(response) {

			if(response.getState() == "SUCCESS") {

				let initData = response.getReturnValue();

				// set fee data
				let feeRequired = (initData.feeAmount > 0) ? true : false;
				component.set("v.feeRequired", feeRequired);
				component.set("v.feeAmount", initData.feeAmount);

				// set international student
				component.set("v.internationalStudent", initData.isInternationalStudent);

				// set waiver code
				component.set("v.waiverCode", initData.waiverCode);

				// set payment mode
				component.set("v.selectedPayment", initData.feePaymentMode);
				component.set("v.westernUnionToggle", false);
				component.set("v.feeWaiverToggle", false);
				component.set("v.otherToggle", false);

				// determine toggle based on payment mode
				if(initData.feePaymentMode == "Western Union" || initData.feePaymentMode == undefined) {
					component.set("v.westernUnionToggle", true);
				} else if(initData.feePaymentMode == "Application Fee Waiver Code") {
					component.set("v.feeWaiverToggle", true);
				} else if(initData.feePaymentMode == "Other") {
					component.set("v.otherToggle", true);
				}

				// set source system to help determine processing fee amount label to be shown
				component.set("v.sourceSystem", initData.sourceSystem);
				component.set("v.processingFeeLabel", initData.processingFeeAmountLabel);

				// set campusLocation and studyType
				component.set("v.campusLocation", initData.campusLocation);
				component.set("v.studyType", initData.studyType);
				try{
					if (
						initData.paymentMaintenanceConfig &&
						Object.keys(initData.paymentMaintenanceConfig).length > 0 &&
						initData.paymentMaintenanceConfig.Status__c.toLowerCase() === 'under maintenance'
					) {
						let configs = initData.paymentMaintenanceConfig;
						switch (configs.DeveloperName) {
							case 'CallistaFeeWaiverNotAvailable':
								// Messaging displayed to end user is based on the callista config metadata
								component.set(
									'v.callistaMaintenanceMessage ',
									JSON.parse(configs.Messages__c.replace(/[\r\n\t]/g, ''))
										.feeWaiverMessaging
								);
								// Payment dropdown options are enabled/disabled based on the callista config metadata
								component.set(
									'v.paymentOptions ',
									JSON.parse(configs.Configs__c.replace(/[\r\n\t]/g, ''))
										.myAppPaymentOptions
								);
								// component.set(
								// 	'v.feeWaiverToggle ',false
								// );
								component.set(
									'v.isCallistaUnderMaintenance ',true
								);
								break;
							default:
								break;
						}
					}
				}catch(e){
					console.error('Error parsing configs: ', e);
				}	
			}else{
				console.log('Failed to load data payload');
				console.log(response.getError());
			}

			// finished loading data
			component.set('v.hasPageLoaded', true);
		});
		$A.enqueueAction(action);
	},

	/**
	 * @description TODO
	 */
	validateWaiver : function(component, code, appId){
		if(code != null && code != '') {
			var action = component.get("c.WaiverCodeAvailiable");
			action.setParams({
				"waiverCode" : code,
				"appId" : appId
			});

			action.setCallback(this, function(response){
				component.set("v.verifyWaiverLoading", false);

				if(response.getState() === 'SUCCESS') {
					
                    if(response.getReturnValue() === 'Error' ) {
                        component.set("v.errorDetails", "This code " + code +" is invalid and cannot be redeemed.Please enter a new valid code.");
                        component.set("v.invalidWaiver", true);
                        component.set("v.validWaiver", false);
                    } else if(response.getReturnValue() === 'Redeemed') {
                        component.set("v.errorDetails", "This code "+code+" has already been redeemed. Please enter a new valid code.");
                        component.set("v.invalidWaiver", true);
                        component.set("v.validWaiver", false);
                    } else if(response.getReturnValue() === 'Expired') {
                        component.set("v.errorDetails", "This code "+code+" has expired and cannot be used.Please enter a new valid code.");
                        component.set("v.invalidWaiver", true);
                        component.set("v.validWaiver", false);
                        component.set("v.feeAmount", "100");
                    } else {
                        component.set("v.feeAmount", "0");
                        component.set("v.invalidWaiver", false);
                        component.set("v.validWaiver", true);
                        component.set("v.successDetails", "This code is valid & will be reconfirmed on submission");
                    }
				} else {
                    component.set("v.errorDetails", "There was an issue redeeming your code.");
                    component.set("v.invalidWaiver", true);
                    component.set("v.validWaiver", false);
				}
			});
            
			$A.enqueueAction(action);
		} else {
			component.set("v.verifyWaiverLoading", false);
			component.set("v.errorDetails", "Waiver code must be entered.");
        	component.set("v.invalidWaiver", true);
        	component.set("v.validWaiver", false);

			var actionCl = component.get("c.clearFeeWaiverCode");
			actionCl.setParams({
				"appId" : appId
			});
            $A.enqueueAction(actionCl);
        }
	},

	/**
	 * @description TODO
	 */
	submitWaiver : function(component, waiverCode, appId)
	{
		var action = component.get("c.RedeemWaiverCode");
		action.setParams({
			"waiverCode" : waiverCode,
			"appId" : appId
		});

		action.setCallback(this, function(response){
			if(response.getState() == "SUCCESS"){
				var response = response.getReturnValue();
				if(response.includes("expired")){
					component.set("v.errorDetails", response);
					component.set("v.invalidWaiver", true);
					component.set("v.validWaiver", false);
				}else if(response.includes("re-enter")){
					component.set("v.errorDetails", response);
					component.set("v.invalidWaiver", true);
					component.set("v.validWaiver", false);
				}
				else{
					component.set("v.invalidWaiver", false);
					component.set("v.validWaiver", true);
					component.set("v.successDetails", "Success - Code has been redeemed");
				}
			}
		});

		$A.enqueueAction(action);
	},

	/**
	 * @description TODO
	 */
	processPayment : function(component, appId){
		var action = component.get("c.GetRequest");
		action.setParams({
			"appId": appId
		});
		action.setCallback(this, function(response){
			var state = response.getState();
			if(state == "SUCCESS"){
				//Call the Western Union
				var URL = response.getReturnValue();
				window.open(URL);
			}
		});
		$A.enqueueAction(action);
	}
})