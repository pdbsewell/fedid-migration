({
    doInit : function(component, event, helper) {
        
        var contactId = component.get("v.recordId");
        component.set("v.contactId", contactId);
        //console.log('Contact Id = ' + contactId);
        
        var action = component.get("c.GetContactAlerts");
        action.setParams({"contactId": contactId});
        action.setCallback(this, function(response) {
            var objResults = response.getReturnValue()
            //console.log('asmtPlanId return value:' + objResults.toString());
            
            if(objResults != null)
            {
                for(var key in objResults)
                {
                    //console.log(key + ':' + objResults[key]);
                }
                
                               
                // set attributes
                
                
                // toggle alert message if any are found, for now, only Encumbrances for Contact View
                var anyAlerts = false;                
                var hasEncumbrances = objResults.hasEncumbrances;                
                if(hasEncumbrances == true)
                {
                	component.set("v.hasEncumbrances", true);
                    anyAlerts = true;
                }
                
                /*
                var isUnder18 = objResults.isUnder18;                
                if(isUnder18 == true)
                {
                	component.set("v.isUnder18", true);
                    anyAlerts = true;
                }
                var hasDisabilities = objResults.hasDisabilities;                
                if(hasDisabilities == true)
                {
                	component.set("v.hasDisabilities", true);
                    anyAlerts = true;
                }
                var hasGTEAlert = objResults.hasGTEAlert;                
                if(hasGTEAlert == true)
                {
                	component.set("v.hasGTEAlert", true);
                    anyAlerts = true;
                }
                var hasCitizenshipAlert = objResults.hasCitizenshipAlert;                
                if(hasCitizenshipAlert == true)
                {
                	component.set("v.hasCitizenshipAlert", true);
                    anyAlerts = true;
                }

				*/
                component.set("v.anyAlerts", anyAlerts);
            }

            //Hide component spinner
            component.set('v.showComponentLoader', false);
        });

        $A.enqueueAction(action);
    },
	myAction : function(component, event, helper) {
		
	}
})