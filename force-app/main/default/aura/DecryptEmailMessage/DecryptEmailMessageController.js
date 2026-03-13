({
	doInit : function(component, event, helper) {
         // show spinner
		component.set("v.showSpinner",true);
        
        // get email message record Id
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(workspaceResponse) {
            var emailMessageId = workspaceResponse.pageReference.attributes.recordId;
            
            // call init
            var action = component.get("c.manageSensitiveData");
            
            action.setParams({
                "emailMessageId": emailMessageId
            });
            
            // Register the callback function
            action.setCallback(this, function(actionResponse) {
                
                //store state of response
                var state = actionResponse.getState();
                
                if(state === "SUCCESS") {
                    var responseObject = actionResponse.getReturnValue();
                    
                    if(responseObject.hasAccess){
                        component.set("v.decryptedData", responseObject.encryptedData);
                    	component.set("v.hasAccess", true);
					}
                    else{
                        component.set("v.noAccess", true);
					}
                }
            });
            
            // Invoke the service
            $A.enqueueAction(action);
            
        });
        // hide spinner
        component.set("v.showSpinner",false);
	}
})