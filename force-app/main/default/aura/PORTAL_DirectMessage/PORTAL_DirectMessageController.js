({
	cancel : function(component, event, helper) {
        //closes the modal or popover from the component
        component.find("overlaySendDirectMessage").notifyClose();
	},
    
    send : function(component, event, helper) {
        var contact = component.get("v.contact");
        var subject = component.get("v.subject");
        var body = component.get("v.body");

        var action = component.get("c.sendDirectMessage");
        
      	action.setParams({"toContactId": contact.Id,
                          "subject": subject,
                          "body": body});

        action.setCallback(this,function(response) {
            var state = response.getState();
            var response = response.getReturnValue();
            
            //alert(JSON.stringify(response));
            
            if (state === "SUCCESS") {                
        		var toastEvent = $A.get("e.force:showToast");
        		toastEvent.setParams({"title": "Success!","message": "Message sent.","type": "success"});
                toastEvent.fire();
                component.find("overlaySendDirectMessage").notifyClose();
            }
        });
        
        $A.enqueueAction(action);   
    }
})