({
    doInit : function(component, event, helper) {
        //Initialize Action
        var action = component.get("c.getIsAgentVerified");
        
        //Set Id of enquiry
        action.setParams({ enquiryId : component.get("v.recordId") });
        
        // Create a callback that is executed after the server-side action returns
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                //Set if agent is verified
                component.set('v.isAgentVerified', response.getReturnValue());
                
                //Stop the loading spinner
                helper.hide(component, event);
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
    verifyClick : function (component, event, helper) {
        //Stop the loading spinner
        helper.show(component, event);
        
        //Initialize Action
        var action = component.get("c.getAgentName");
        
        //Set Id of enquiry
        action.setParams({ enquiryId : component.get("v.recordId") });
        
        // Create a callback that is executed after the server-side action returns
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                //Set agent name
                component.set('v.agentName', response.getReturnValue());
                
                //Toggle View
                component.set('v.showConfirmation', true);
                
                //Stop the loading spinner
                helper.hide(component, event);
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
    confirmVerification : function (component, event, helper) {
        //Stop the loading spinner
        helper.show(component, event);
        
        //Initialize Action
        var action = component.get("c.verifyAgent");
        
        //Set Id of enquiry
        action.setParams({ enquiryId : component.get("v.recordId") });
        
        // Create a callback that is executed after the server-side action returns
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {   
                //Toggle View Agent is verified
                component.set('v.isAgentVerified', true);                
                
                //Toggle View
                component.set('v.showConfirmation', false);
                
                //Stop the loading spinner
                helper.hide(component, event);
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
            	var errors = response.getError();
                if (errors) {
                	if (errors[0] && errors[0].message) {
                    	console.log("Error message: " + errors[0].message);
                    }
                } else {
                	console.log("Unknown error");
                }
            }
        });
        
        $A.enqueueAction(action);
    },
    cancelVerification : function (component, event, helper) {
        //Stop the loading spinner
        helper.show(component, event);
        
        //Initialize Action
        var action = component.get("c.getAgentName");
        
        //Set Id of enquiry
        action.setParams({ enquiryId : component.get("v.recordId") });
        
        // Create a callback that is executed after the server-side action returns
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                //Set agent name
                component.set('v.agentName', response.getReturnValue());
                
                //Toggle View
                component.set('v.showConfirmation', false);
                
                //Stop the loading spinner
                helper.hide(component, event);
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
            	var errors = response.getError();
                if (errors) {
                	if (errors[0] && errors[0].message) {
                    	console.log("Error message: " + errors[0].message);
                    }
                } else {
                	console.log("Unknown error");
                }
            }
        });
        
        $A.enqueueAction(action);
    },
    handleRecordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "LOADED") {
            // record is loaded (render other component which needs record data value)
            console.log("Record is loaded successfully.");
        } else if(eventParams.changeType === "CHANGED") {
            // record is changed
        } else if(eventParams.changeType === "REMOVED") {
            // record is deleted
        } else if(eventParams.changeType === "ERROR") {
            // there’s an error while loading, saving, or deleting the record
        }
    }
})