({
   
	cancel : function(component, event, helper) {
        //closes the modal or popover from the component
        component.find("overlayLibVolunteerJobSignup").notifyClose();
	},

    saveShiftSignUp : function(component, event, helper) {
//        event.preventDefault(); // Prevent default submit

//        var fields = event.getParam("fields");

//        alert('fields: ' + fields);
        
        var contact = component.get("v.contact");      
//        contact.FirstName = fields["FirstName"];
//        contact.LastName = fields["LastName"];
//        contact.Email = fields["Email"];
//        contact.HomePhone = fields["HomePhone"];
//        contact.MobilePhone = fields["MobilePhone"];
        
        var volunteerJobId = component.get("v.volunteerJobId");  
        var volunteerSlotId = component.get("v.volunteerSlotId");  
        
        //alert('volunteerJobId: ' + volunteerJobId);
        //alert('volunteerSlotId: ' + volunteerSlotId);
        //alert('contact: ' + JSON.stringify(contact));  

        var shiftSignUpAction = component.get("c.SERVER_shiftSignUp");
        //alert('contact2: ' + JSON.stringify(contact));      
        
       
        shiftSignUpAction.setParams({"signupContact": component.get("v.contact"),
                                     "jobIdSignUp": volunteerJobId,
                                     "shiftIdSignUp": volunteerSlotId});
   
        shiftSignUpAction.setCallback(this, function(response) {
            var result = response.getReturnValue();
            var state = response.getState();
            //alert('state: ' + state);  
            if (state === "SUCCESS") {
                //alert('toast');  
        		var toastEvent = $A.get("e.force:showToast");
        		toastEvent.setParams({"title": "Success!","message": "Thank you for signing up.","type": "success"});
                toastEvent.fire();
                component.find("overlayLibVolunteerJobSignup").notifyClose();
            }
            else {
                alert('error');
            }
        });

        $A.enqueueAction(shiftSignUpAction);
    }
})