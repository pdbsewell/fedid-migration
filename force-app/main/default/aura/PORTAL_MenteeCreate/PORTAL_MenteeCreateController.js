({
    doInit : function(component, event, helper) {
        var mentorRecId = component.get("v.mentorRecId");
        var contactId = component.get("v.contactId");        
        
        var action = component.get("c.SERVER_getMentee");
        
        action.setParams({"mentorRecId": mentorRecId,
                          "contactId": contactId});        
        
        action.setCallback(this, function(response) {

            var state = response.getState();
            
            //alert('result: ' + JSON.stringify(result));
            console.log('mentee state: ' + state);      
            
            if (state === "SUCCESS") {
                var mentee = response.getReturnValue();
                
                console.log('result: ' + JSON.stringify(mentee));
                
                var recordId = mentee.Id;
                component.set("v.recordId", recordId);
            }
            else {
                
            }
        });
        
        $A.enqueueAction(action);
    },
    
    handleLoad: function(component, event, helper) {
        var mentorRecId = component.get("v.mentorRecId");
        var contactId = component.get("v.contactId");
        
		console.log('load');
        var record = event.getParam('record');
        console.log('record: ' + JSON.stringify(record));
/*
        record.fields.Topics_of_Interest__c.value = "test";
        record.fields.Topics_of_Interest__c.displayValue = "test";
        
        event.setParam('record', record);
*/      
    },
    
    handleSubmit: function(component, event, helper) {
        var mentorRecId = component.get("v.mentorRecId");
        var contactId = component.get("v.contactId");        
       
        event.preventDefault(); // stop form submission
        event.stopPropagation();
        
        var eventFields = event.getParam("fields");
        eventFields["Mentor__c"] = mentorRecId;
        eventFields["Mentee__c"] = contactId;
        component.find('myform').submit(eventFields);
    },
    
    handleSuccess: function(component, event, helper) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({"title": "Success!","message": "Mentee application submitted.","type": "success"});
        toastEvent.fire();
        component.find("overlayLibMenteeCreate").notifyClose();
        //event.preventDefault();
        //event.stopImmediatePropagation();
    },
    
    handleCancel: function(component, event, helper) {
        console.log('cancel');
		component.find("overlayLibMenteeCreate").notifyClose();
        console.log('closed');
    },
})