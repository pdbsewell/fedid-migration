({
	getListingItem : function(component, event, helper, fireEvent) {       
        var recordId = component.get("v.recordId");
        var portalZone = component.get("v.portalZone");
        
        //component.set('v.zoomLevel', 4);
        //component.set('v.markersTitle', 'Salesforce locations in United States');
        //component.set('v.showFooter', true);
        
        var action = component.get("c.SERVER_getListingItem");

        action.setParams({"recordId": recordId,
                          "portalZone": portalZone});
   
        action.setCallback(this, function(response) {
            var result = response.getReturnValue();
            var state = response.getState();
            
            //alert('result: ' + JSON.stringify(result));
            //alert('state: ' + state);      
        
            if (state === "SUCCESS") {             
                var item = result;
                
                component.set("v.item", item);
                
                console.log('item: ' + JSON.stringify(item));
                
                var userId = $A.get("$SObjectType.CurrentUser.Id");
                
                if (userId != null) {
                    component.set("v.isLoggedInUser", true);
                }

                //alert(JSON.stringify(item));
                
                if (item.Participations_Listing__r != null) {
                    //alert(JSON.stringify(item.Participations_Listing__r[0]));
                    component.set("v.participation", item.Participations_Listing__r[0]);
                }
                else {
                    var participation = [];
                    participation.push({'sobjectType':'Participation__c','Id':''});
                    component.set("v.participation", participation);
                }
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