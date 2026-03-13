({
    doInit: function(component, event, helper) {
        //Initialize server class method call
        var action = component.get('c.retrieveToastListenerAutoRedirection');
        
        //Call server class
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set('v.redirectionRules', response.getReturnValue());
            }
            else if (state === "INCOMPLETE") {
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
    toastInfo: function(component, event, helper) {
        //Define which action to take - based on the toast message - for quick actions use the successful message defined on the quick action
        var toastMessage = event.getParams().message;
        //Retrieve redirectionRules from the custom metadata type
        var redirectionRules = component.get('v.redirectionRules');
        
        //Check if there is a rule relevant to the toast message
        if(redirectionRules[toastMessage]){
            
            //Initialize server class method call
            var action = component.get('c.retrieveLatestCreatedRecord');
            
        	//Set Id of Application
            action.setParams({ 
                objectType : redirectionRules[toastMessage]
            });
            
            //Call server class
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var recordId = response.getReturnValue();
                    
                    //Navigate to the newly created object
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": recordId,
                      	"slideDevName": "related"
                    });
                    navEvt.fire();
                }
                else if (state === "INCOMPLETE") {
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
        }
    }
})