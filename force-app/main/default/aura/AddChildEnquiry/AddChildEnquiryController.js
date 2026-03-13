({
	init : function(component, event, helper) {
    },
	handleChildEnquiryLoad: function(component, event, helper) {
		//Hide spinner
		component.set('v.showAddChildEnquirySpinner', false);
		
	    //Show submit button
	    var submitChildEnquiryButton = component.find('submitChildEnquiryButton');
        $A.util.removeClass(submitChildEnquiryButton, 'slds-hide');
        $A.util.addClass(submitChildEnquiryButton, 'slds-show');
	},
	handleChildEnquirySubmit : function(component, event, helper) {
	    //Show spinner
		component.set('v.showAddChildEnquirySpinner', true);
		
		//Retrieve Data
        var originInputField = component.find('originField');
        var socialMediaTypeInputField = component.find('socialMediaTypeField');
        
		//Validate Social Media Type when the origin is related to social media
		if(originInputField.get('v.value').toLowerCase().includes('social media')){
		    if(!socialMediaTypeInputField.get('v.value')){
		        event.preventDefault();
		        
		        //Show error toast
        	    var toastEvent = $A.get('e.force:showToast');
                toastEvent.setParams({
                    'type': 'error',
                    'title': 'Validation Error',
                    'message': 'Please fill up required fields.'
                });
                toastEvent.fire();
                
                //Highlight Social Media Type field as required
                $A.util.addClass(socialMediaTypeInputField, 'slds-has-error');
                
		        component.set('v.showAddChildEnquirySpinner', false);
		    }
		}
	},
	handleChildEnquirySuccess : function(component, event, helper) {
	    //Show success toast
	    var toastEvent = $A.get('e.force:showToast');
        toastEvent.setParams({
            'type': 'success',
            'title': 'Success!',
            'message': 'Successfully created child Pre-Application Enquiry'
        });
        toastEvent.fire();
		
		//Refresh standard components on page
		$A.get('e.force:refreshView').fire();
	    
	    var payload = event.getParams().response;
        
        //Navigate to the newly created enquiry
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
          "recordId": payload.id,
          "slideDevName": "related"
        });
        navEvt.fire();
        
		//Reset fields
		component.set('v.saved', true);
	    component.set('v.saved', false);
	    
	    //Hide spinner
		component.set('v.showAddChildEnquirySpinner', false);
	},
	handleChildEnquiryError : function(component, event, helper) {
	    //Hide spinner
		component.set('v.showAddChildEnquirySpinner', false);
		
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

    },
    originChanged : function(component, event, helper) {
        var originInputField = component.find('originField');
    
        //Toggle social media type field being requred when the origin has a social media texts in it   
        if(originInputField.get('v.value').toLowerCase().includes('social media')){
            
            $A.util.addClass(component.find('socialMediaTypeFieldRequired'), 'slds-show');
            $A.util.removeClass(component.find('socialMediaTypeFieldRequired'), 'slds-hide');
            
        }else{
            
            $A.util.addClass(component.find('socialMediaTypeFieldRequired'), 'slds-hide');
            $A.util.removeClass(component.find('socialMediaTypeFieldRequired'), 'slds-show');
            
            //Remove highlighted Social Media Type field as required
            $A.util.removeClass(component.find('socialMediaTypeField'), 'slds-has-error');
            
        }
    }
})