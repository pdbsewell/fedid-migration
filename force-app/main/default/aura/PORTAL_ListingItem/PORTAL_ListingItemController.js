({
    doInit : function(component, event, helper) {
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        
        if (userId != null) {
            component.set("v.isLoggedInUser", true);
        }

        var item = component.get("v.item");
    
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
            
        //var participation = component.get("v.participation");
        //alert(JSON.stringify(participation));
    },

})