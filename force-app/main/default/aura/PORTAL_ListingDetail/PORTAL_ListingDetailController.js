({
    doInit : function(component, event, helper) {
        
        // the function that reads the url parameters
        var getUrlParameter = function getUrlParameter(sParam) {
            var sPageURL = decodeURIComponent(window.location.search.substring(1)),
                sURLVariables = sPageURL.split('&'),
                sParameterName,
                i;
            
            for (i = 0; i < sURLVariables.length; i++) {
                sParameterName = sURLVariables[i].split('=');
                
                if (sParameterName[0] === sParam) {
                    return sParameterName[1] === undefined ? true : sParameterName[1];
                }
            }
        };
        
        //set the src param value to my src attribute
        component.set("v.showAttending", getUrlParameter('showAttending'));        
        
        helper.getListingItem(component, event, helper, true);
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