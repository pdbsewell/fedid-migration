({    
    doInit : function(component, event, helper) {
        // Get a reference to the init() function defined in the Apex controller
        var action = component.get("c.init");
        
        //Pass enquiry Id to server
        action.setParams({
            recordId : component.get('v.recordId')
        });
        
        // Register the callback function
        action.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();
            if(state === "SUCCESS") {
                // Set the component attributes using values returned by the API call
                var thisWrapper = response.getReturnValue();
                component.set('v.lstEmailFrom', thisWrapper.lstEmailFrom);
                component.set('v.graduateResearchUserPermission', thisWrapper.graduateResearchUserPermission);
                console.log('lstEmailFrom@@ '+component.get('v.lstEmailFrom'));
            }
        });
        // Invoke the service
        $A.enqueueAction(action);
    },
  
    updateFrom : function(component, event, helper) {       
        var emailQuickAction = event.currentTarget.dataset.quickactionname;
        var actionAPI = component.find('quickActionAPI');
        var fields = {FromAddress: {value : event.currentTarget.dataset.emailvalue }};
        var args = {actionName: emailQuickAction, targetFields: fields};
        actionAPI.setActionFieldValues(args);
        //Added for Default Email Address
        component.set('v.selectedEmail', event.currentTarget.dataset.emailvalue);
        var customPermission = component.get('v.graduateResearchUserPermission');
        if(customPermission){
            var action = component.get('c.saveFromAddress');
        	$A.enqueueAction(action);
        }else{
            console.log('no custom permission To Default From Address');
        }
    },
    saveFromAddress : function(component, event, helper) {
         // Get a reference to the saveLatestEnquiryFromAddress() function defined in the Apex controller
        var action = component.get("c.saveLatestEnquiryFromAddress");

        //Pass selectedEmail to server
        action.setParams({
            defaultEmail : component.get('v.selectedEmail')
        });
        
        // Register the callback function
        action.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();
            if(state === "SUCCESS") {
                // Set the component attributes using values returned by the API call
                console.log('Default Email Set ');
            }
        });
        // Invoke the service
        $A.enqueueAction(action);      
 }
})