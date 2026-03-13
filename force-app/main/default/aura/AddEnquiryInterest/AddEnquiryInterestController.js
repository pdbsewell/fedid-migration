({
	init : function(component, event, helper) {
    },
	handleInterestLoad: function(component, event, helper) {
		//Hide spinner
		component.set('v.showAddEnquirySpinner', false);
	},
	handleInterestSubmit : function(component, event, helper) {
	    //Show spinner
		component.set('v.showAddEnquirySpinner', true);
	},
	handleInterestSuccess : function(component, event, helper) {
	    //Show success toast
	    var toastEvent = $A.get('e.force:showToast');
        toastEvent.setParams({
            'type': 'success',
            'title': 'Success!',
            'message': 'Successfully added Enquiry Interest.'
        });
        toastEvent.fire();
		
		//Refresh standard components on page
		$A.get('e.force:refreshView').fire();
	    
		//Reset fields
		component.set('v.saved', true);
	    component.set('v.saved', false);
	},
	handleInterestError : function(component, event, helper) {
	    //Hide spinner
		component.set('v.showAddEnquirySpinner', false);
		
		//Show error toast
	    var toastEvent = $A.get('e.force:showToast');
        toastEvent.setParams({
            'type': 'error',
            'title': JSON.stringify(event._params.message).replace(new RegExp('"', 'g'), ''),
            'message': JSON.stringify(event._params.detail).replace(new RegExp('"', 'g'), '')
        });
        toastEvent.fire();
	},
	showForm : function(component, event, helper) {
	    component.set('v.saved', false);
	},
	enquiryUpdated : function(component, event, helper) {

    }
})