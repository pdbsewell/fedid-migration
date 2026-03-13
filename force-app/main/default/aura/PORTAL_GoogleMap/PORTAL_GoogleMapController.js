({
	doInit : function(component, event, helper) {
        
        // Need to initialize with at least two markers to start.
        // Otherwise, map won't show side panel that displays headings for locations.
        component.set('v.mapMarkers', [
            {
                location: {
                    'Street': '230 Commerce',
                    'City': 'Irvine',
                    'State': 'CA',
                    'PostalCode': '92602',
                    'Country': 'USA'
                },

                title: 'UC Innovation HQ',
                description: 'UC Innovation Headquarter.'
            },
            {
                location: {
                    'Street': '895 Dove Street',
                    'City': 'Newport Beach',
                    'State': 'CA',
                    'PostalCode': '92660',
                    'Country': 'USA'
                },

                title: 'UC Innovation First Office',
                description: 'UC Innovation First Office.'
            },
        ]);
/*        
        component.set('v.center', {
            location: {
                City: 'Lebanon',
                State: 'KS',
                Country: 'USA'
            }
        });
*/
        //component.set('v.zoomLevel', 3);
        //component.set('v.markersTitle', "Location");
        //component.set('v.showFooter', true);
	},
    
	markersChanged : function(component, event, helper) {
        var eventName = event.getParam("name");
        var mapMarkers = event.getParam("mapMarkers");
		var inputEventName = component.get("v.inputEventName");
            
        console.log('mapMarkers: ' + JSON.stringify(mapMarkers));
        
        if (eventName == inputEventName) {            
        	component.set('v.mapMarkers', mapMarkers);
        }
    }
})