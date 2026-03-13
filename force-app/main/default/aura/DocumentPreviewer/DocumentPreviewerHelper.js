({
    retrieveDocumentChecklistSetting : function(component, event, helper) {
        //Set version
        var action = component.get("c.retrieveDocumentChecklistSettings");
        action.setCallback(this, function(response){
            var state = response.getState();         
            if(state === 'SUCCESS'){
                var result = response.getReturnValue();                    
                component.set('v.layoutVersion', result.Document_Previewer_Version__c);
                component.set('v.initializeReady', true);
            }
        });

        $A.enqueueAction(action);
    }
})