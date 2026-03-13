({
    // Client-side controller called by the onsort event handler
    urlClicked: function (component, event, helper) {
        var item = component.get('v.item');
        var showAttending = component.get("v.showAttending");
        //alert('here');
        var recordId = item.Id;
        
        var baseUrl = component.get('v.baseUrl');

        var urlString = event.currentTarget.getAttribute("data-urlString");
        console.log('urlString: ' + urlString);
        console.log('recordId: ' + recordId);
        console.log('item: ' + item);

        if (!urlString) {
            urlString = baseUrl + '/s/listing/' + recordId + '?showAttending=' + showAttending;
        }
        
        console.log('updated urlString: ' + urlString);
        
        var action = component.get("c.SERVER_updateRecommendationEngine");
        
        action.setParams({
            contentId : recordId
        });
        //alert('here1');
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            //            alert('state: ' + state);
            
            if (state == "SUCCESS") {
                console.log('in success');
                
            } else if (state == 'INCOMPLETE') {
                console.log('incomplete');
            } else if (state == 'ERROR') {
                var errors = response.getError();
                
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log(errors[0].message);
                    } else {
                        console.log("Failed");
                    }
                }
            }
        });
        //alert('here2');
        $A.enqueueAction(action);
        
        //alert('here3');
        
        var eUrl= $A.get("e.force:navigateToURL");
        
        eUrl.setParams({
            "url": urlString
        });
        
        eUrl.fire();
    },
})