({
	doInit : function(component, event, helper) {
		let retrieveLinks = component.get("c.retrieveUsefulLinks");

		retrieveLinks.setCallback(this, function (response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				let listLinks = response.getReturnValue();
				let usefulLinks = [];

				for(let i = 0; i < listLinks.length; i++){
					usefulLinks.push({
						value:  listLinks[i].URL__c,
						key: listLinks[i].Title__c
					});
				}
				component.set('v.listUsefulLinks', usefulLinks);
			}
		});
		$A.enqueueAction(retrieveLinks);
	}
})