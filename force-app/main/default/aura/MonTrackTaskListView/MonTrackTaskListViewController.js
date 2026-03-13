({
    init : function (component, event, helper) {
        // Get a reference to the doInit() function defined in the Apex controller
		var action = component.get("c.doInit");
        
        action.setParams({
            //set apex method parameters here
        });
        
        // Register the callback function
        action.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();            
            if(state === "SUCCESS") {
                // Set the component attributes using values returned by the API call
                component.set("v.taskListViews", response.getReturnValue().lstMonTrackListViews);
            }
        });
        // Invoke the service
        $A.enqueueAction(action);
	},
    
	gotoList : function (component, event, helper) {
        // Get a reference to the doInit() function defined in the Apex controller
		var action = component.get("c.getMonTrackListViewId");
     	var listViewname = event.currentTarget.name;
        action.setParams({
            //set apex method parameters here
            "ListViewName" : listViewname
        });
        
        // Register the callback function
        action.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();
            console.log('State: '+ state);
            if(state === "SUCCESS") {
                // Set the component attributes using values returned by the API call                
                var navEvent = $A.get("e.force:navigateToList");
                navEvent.setParams({
                    "listViewId": response.getReturnValue(),
                    "listViewName": listViewname,
                    "scope": "Task"
                });
                navEvent.fire();                
            }
        });
        // Invoke the service
        $A.enqueueAction(action);
	}
})