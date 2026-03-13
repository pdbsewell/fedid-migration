({    
	executeEncryptions : function(component, event, helper) {
        component.set("v.showSpinner",true);
        
        var workspaceAPI = component.find("workspace");
		// Get a reference to the init() function defined in the Apex controller
        
        workspaceAPI.getFocusedTabInfo().then(function(workspaceResponse) {
			var oldTab = workspaceResponse.tabId; 
            var emailMessageId = workspaceResponse.pageReference.attributes.recordId;
            
            if(emailMessageId != undefined){
                var action = component.get("c.manageSensitiveData");
                action.setParams({
                    "emailMessageId": emailMessageId
                });
                
                // Register the callback function
                action.setCallback(this, function(actionResponse) {
                    //store state of response
                    var state = actionResponse.getState();
                    var responseObject = actionResponse.getReturnValue();
                    
                    if(state === "SUCCESS") {
                        component.set("v.showSpinner", false);
                        
                        if(responseObject.hasAccess){
							if(responseObject.isEncrypted){
                                component.set("v.isEncrypted", true);
                            }
                            else{
                                var workspaceAPI = component.find("workspace");
                            
                                workspaceAPI.openSubtab({
                                    parentTabId: workspaceResponse.parentTabId,
                                    pageReference: null,
                                    recordId: responseObject.emailMessageId,
                                    url: null,
                                    focus: true
                                });
                                
                                workspaceAPI.closeTab({tabId: oldTab});                
                                workspaceAPI.refreshTab({tabId: workspaceResponse.parentTabId});
                            }
                        }
                        else{
							component.set("v.noAccess", true);
                        }
                    }
                    else{
                        component.set("v.showSpinner", false);
						component.set("v.hasError", true);
                    }
                });
                // Invoke the service
                $A.enqueueAction(action);			                
            }
            else{
                alert("No Email Message found.");
            }
            
       	})
	}
})