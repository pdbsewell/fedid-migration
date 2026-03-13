({
	init : function(component, event, helper) {
    },
    enquiryUpdated : function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "CHANGED") {
            component.find('caseRecordLoader').reloadRecord();
        } else if(eventParams.changeType === "LOADED") {
            //Show spinner on load
            component.set('v.logAnActivitySpinner', false);
        } else if(eventParams.changeType === "REMOVED") {
        } else if(eventParams.changeType === "ERROR") {
        }
    },
    submitActivity : function(component, event, helper) {
	    //Show spinner on load
        component.set('v.logAnActivitySpinner', true);
	    component.find('activityTypeField')
	    //Validate activity type
	    if(component.get('v.activityType')){
    	    //Search
    	    var action = component.get("c.commitTask");
    	    
            //Set parameters
            action.setParams({ 
                activityType : component.get('v.activityType'),
                activitySubject : component.get('v.activityType'),
                activityDescription : component.get('v.activityDescription'),
                parentId : component.get('v.recordId'),
                relatedWhoId : component.get('v.currentEnquiry.ContactId')
            });
            
            // Create a callback that is executed after the server-side action returns
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    //Process results
                    var taskResult = response.getReturnValue();
                    
                    console.log(taskResult);
                    
                    //Show success toast
            	    var toastEvent = $A.get('e.force:showToast');
                    toastEvent.setParams({
                        'type': 'success',
                        'title': 'Success!',
                        'message': 'Successfully logged ' + component.get('v.activityType') + ' activity.'
                    });
                    toastEvent.fire();
            		
            		//Refresh standard components on page
            		$A.get('e.force:refreshView').fire();
                    
                    //Clear activity form values
                    component.set('v.activityType', '');
                    component.set('v.activityDescription', '');
                    
                    //Hide spinner on load
                    component.set('v.logAnActivitySpinner', false);
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
                                  
                            //Show error toast
                    	    var toastEvent = $A.get('e.force:showToast');
                            toastEvent.setParams({
                                'type': 'error',
                                'title': 'An error occurred while trying to update the record. Please try again.',
                                'message': errors[0].message
                            });
                            toastEvent.fire();
                                  
                            //Hide spinner on load
                            component.set('v.logAnActivitySpinner', false);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
            });
            
            $A.enqueueAction(action);
        }else{
            //Show error toast
    	    var toastEvent = $A.get('e.force:showToast');
            toastEvent.setParams({
                'type': 'error',
                'title': 'Required fieds error.',
                'message': 'Please select an Activity Type'
            });
            toastEvent.fire();
            
            component.find('activityTypeField').showHelpMessageIfInvalid();
        
            //Hide spinner on load
            component.set('v.logAnActivitySpinner', false);
        }
    }
})