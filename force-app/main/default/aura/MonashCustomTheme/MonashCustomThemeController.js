({
	closeMessage: function(component, event, helper) {
		console.log('closing message...');
		var cmpTarget = component.find('beta-feedback-main');
		$A.util.addClass(cmpTarget, 'slds-hide');
	}
})