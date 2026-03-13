({
	retrieveOwnerDraft : function(component, event, helper) {
		//Show table loading
        component.set('v.showDraftSpinner', true);
        
	    //Call server method
	    var action = component.get("c.retrieveOwnerDraftEmailMessageHtmlBody");
        
        //Set parameters
        action.setParams({ 
            enquiryId : component.get('v.recordId'),
            ownerId : component.get('v.currentEnquiry').OwnerId,
        });
        
        // Create a callback that is executed after 
        // the server-side action returns
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                //Process results
                var emailContent = response.getReturnValue();
                
                component.set('v.draftEmailMessage', emailContent);
                
                //Increase size of the modal if there are contents
                if(emailContent){
                    var draftModal = component.find('draftModal');
                    $A.util.removeClass(draftModal, 'slds-modal_small');
                    $A.util.addClass(draftModal, 'slds-modal_medium');
                }else{
                    component.set('v.showNoDraft', true);
                }
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
            
            component.set('v.showDraftSpinner', false);
        });
        
        $A.enqueueAction(action);
	},
	retrieveEmailComposer : function(component, event, helper) {
	    //Call server method
	    var action = component.get("c.retrieveRelevantEmailComposer");
        
        //Set parameters
        action.setParams({ 
            enquiryRecordTypeDeveloperName : component.get('v.currentEnquiry').RecordType.DeveloperName
        });
        
        // Create a callback that is executed after 
        // the server-side action returns
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                //Process results
                var emailComposerName = response.getReturnValue();
                
                //Set email composer name
                component.set('v.emailComposerApiName', emailComposerName);
                
                
                component.set('v.disableCopyToEmailComposer', true);
                    
                //Enable copy to email composer button
                if(emailComposerName){
                    component.set('v.disableCopyToEmailComposer', false);
                }
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        
        $A.enqueueAction(action);
	},
	copyToEmailComposer : function(component, event, helper) {
		var actionAPI = component.find('quickActionAPI');
        var fields = { HtmlBody: {value : component.get('v.draftEmailMessage') }};
        var args = { actionName: component.get('v.emailComposerApiName'), targetFields: fields };
        actionAPI.setActionFieldValues(args);
        
        //Close Draft Email Message Modal
        component.set('v.showModalDraft', false);
	}
})