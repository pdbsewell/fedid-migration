({
	doInit : function(component, event, helper) {
		var item = component.get("v.item");
        
        console.log('item: ' + item);
	},
    
    handleAttendingChange : function(component, event, helper) {

        var target = event.getSource();  
        
        //var eventId = target.get("v.name") ;
        
        var item = component.get("v.item");
        
        var selectedOptionValue = event.getParam("value");

        var action = component.get("c.SERVER_updateListingParticipation");
        
        //alert('item: ' + JSON.stringify(item));
        //alert('event: ' + eventId);
        //alert('attending: ' + selectedOptionValue);
        
        action.setParams({"listingId": item.Id,
                          "attending": selectedOptionValue});
        
        action.setCallback(this, function(response) {
            var result = response.getReturnValue();
            var state = response.getState();
            
            //alert('result: ' + JSON.stringify(result));
            //alert('state: ' + state);  
            
            if (state === "SUCCESS") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({"title": "Success!","message": "Thank you for your update.","type": "success"});
                toastEvent.fire();
                
                //window.open(window.location,  "_self");
            }
            else if (state === "INCOMPLETE") {
                MessageHandlingService.incompleteServerCall();
            }
            else if (state === "ERROR") {
                let error = response.getError();
                
                if (error && error[0] && error[0].message) {
                    MessageHandlingService.errorServerCall(error[0].message);
                }
                else {
                     MessageHandlingService.errorServerCall();
                }
            }
        });
        
        $A.enqueueAction(action);
    },
        
})