({
    handleLoad: function(component, event, helper) {
		console.log('load');
        var recUi = event.getParam("fields");
        console.log('load1: ' + JSON.stringify(recUi));

    },
    
    handleSubmit: function(component, event, helper) {
       
        //event.preventDefault(); // stop form submission
        //event.stopPropagation();
        
        //var eventFields = event.getParam("fields");
        // eventFields["Field__c"] = "Test Value";
        //component.find('myform').submit(eventFields);
    },
    
    handleSuccess: function(component, event, helper) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({"title": "Success!","message": "Mentor application submitted.","type": "success"});
        toastEvent.fire();
        component.find("overlayLibMentorCreate").notifyClose();
        //event.preventDefault();
        //event.stopImmediatePropagation();
    },
    
    handleCancel: function(component, event, helper) {
        console.log('cancel');
		component.find("overlayLibMentorCreate").notifyClose();
        console.log('closed');
    },
})