({
	validateValues : function(component, event, helper) {
	    //Show loader
	    component.set('v.showFutureGeneralEnquirySpinner', true);
	    
	    //Get fields
	    var emailField = component.find('emailField');
	    
	    //Check form values
	    if(component.get('v.enquiryStudentFirstName') && component.get('v.enquiryStudentLastName') && component.get('v.enquiryEmail') && emailField.checkValidity() && 
	       component.get('v.selectedTopic') && component.get('v.enquiryDescription') && 
	       (component.get('v.selectedTopic') != 'Other' || (component.get('v.selectedTopic') == 'Other' && component.get('v.otherTopic')))){
           
            //Enable submit enquiry button
	        component.set('v.disableSubmit', false);
	    }else{
	        //Disable submit enquiry button
	        component.set('v.disableSubmit', true);
	    }
	    
	    //Hide loader
	    component.set('v.showFutureGeneralEnquirySpinner', false);
	},
	saveEnquiry : function(component, helper, event) {
	    //Show loader
	    component.set('v.showFutureGeneralEnquirySpinner', true);
	    
		//Initialize Action
        var action = component.get('c.submitFutureGeneralEnquiry');
        
        //Set enquiry parameters
        action.setParams({ 
            studentFirstName : component.get('v.enquiryStudentFirstName'),
            studentLastName : component.get('v.enquiryStudentLastName'),
            studentEmail : component.get('v.enquiryEmail'),
            selectedTopic : component.get('v.selectedTopic'),
            otherTopic : component.get('v.otherTopic'),
            enteredAdditionalDescription : component.get('v.enquiryDescription')
        });
        
        // Create a callback that is executed after the server-side action returns
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                //Set enquiry case number response
                var enquiryResult = JSON.parse(response.getReturnValue());
                component.set('v.enquiryId', enquiryResult.Id);
                component.set('v.submittedEnquiryCaseNumber', enquiryResult.CaseNumber);
                
                var submitBtn = component.find('sendEnquiryBtn');
                submitBtn.set('v.disabled', true);
                $A.util.removeClass(submitBtn, 'submitBtn'); 
                
                component.set('v.contactId','');
            }
            else if (state === 'INCOMPLETE') {
                console.log(state);
            }
            else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log('Error message: ' + 
                                 errors[0].message);
                    }
                } else {
                    console.log('Unknown error');
                }
            }
            
            //Hide loader
	        component.set('v.showFutureGeneralEnquirySpinner', false);
        });

        $A.enqueueAction(action);
	}
})