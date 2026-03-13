({
    createEvent : function(component, event, helper) {
        var action = component.get("c.syncMembers");

        action.setParams({
            "campaignId" : component.get("v.recordId")
        });


        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('testing');
            if (state == "SUCCESS") {
                var retVal = response.getReturnValue();
                component.set("v.returnString", retVal);
                
                if (retVal && retVal != '') {
                    component.set("v.showError", true);
                }

            } else if (state == 'INCOMPLETE') {
                //TBD: Implement Incomplete handling
                console.log('incomplete');
            } else if (state == 'ERROR') {
                //TBD: Implement Error handling
                console.log('error');
            }
        });

        $A.enqueueAction(action); 
    }
})