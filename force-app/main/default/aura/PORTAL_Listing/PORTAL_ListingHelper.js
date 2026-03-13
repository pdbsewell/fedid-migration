({
	getListingList : function(component, event, helper, fireEvent) {       
        var recordType = component.get("v.recordType");
        var scope = component.get("v.scope");
        var sharing = component.get("v.sharing");
        var relevance = component.get("v.relevance");
        var maxItems = component.get("v.maxItems");
		var searchText = component.get("v.searchText");        
        var currentDate = component.get("v.currentDate");
        var portalZone = component.get("v.portalZone");
        
        //component.set('v.zoomLevel', 4);
        //component.set('v.markersTitle', 'Salesforce locations in United States');
        //component.set('v.showFooter', true);
        
        var action = component.get("c.SERVER_getListings");

        action.setParams({"recordType": recordType,
                          "scope": scope,
                          "sharing": sharing,
                          "relevance": relevance,
                          "maxItems": maxItems,
                          "searchText": searchText,
                          "currentDate": currentDate,
                          "portalZone": portalZone});
   
        action.setCallback(this, function(response) {
            var result = response.getReturnValue();
            var state = response.getState();
            
            //alert('result: ' + JSON.stringify(result));
            //alert('state: ' + state);      
        
            if (state === "SUCCESS") {
                component.set("v.listingList", result);

                var itemsPerPage = component.get("v.itemsPerPage");
                var listingListToDisplay = result;

                if (itemsPerPage < result.length) {
                    listingListToDisplay = result.slice(0, itemsPerPage);
                }

                component.set("v.totalNumberOfPages", Math.ceil(result.length / itemsPerPage));

                console.log(listingListToDisplay);
                component.set("v.listingListToDisplay", listingListToDisplay);
                

	            var locationList = [];
                var calendarListingList = [];
                
                for (var i = 0; i < result.length; i++) {
                    var listingRec = result[i];
                    
                    console.log('listingRec: ' + JSON.stringify(listingRec));
                    
                    locationList.push({
                        location: {
                            'Street': listingRec.Street__c,
                            'City': listingRec.City__c,
                            'PostalCode': listingRec.Postal_Code__c,
                            'State': listingRec.State__c,
                            'Country': listingRec.Country__c
                        },
                        title: listingRec.Name
                    });
                    
                    calendarListingList.push({StartDateTime: listingRec.Start_Date_Time__c});
                }
                
                //alert(JSON.stringify(locationList));
                
                if (searchText == "" && sharing == "All" && fireEvent == true) {
                    var outputEventName = component.get("v.outputEventName");
                    
                    var googleMapEvent = $A.get("e.c:PORTAL_EVT_GoogleMap");
                    googleMapEvent.setParams({
                        name: outputEventName,
                        mapMarkers: locationList
                    });
                    googleMapEvent.fire();
    
                    var calendarEvent = $A.get("e.c:PORTAL_EVT_Calendar");
                    calendarEvent.setParams({
                        name: outputEventName,
                        listingList: calendarListingList
                    });
                    calendarEvent.fire();  
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