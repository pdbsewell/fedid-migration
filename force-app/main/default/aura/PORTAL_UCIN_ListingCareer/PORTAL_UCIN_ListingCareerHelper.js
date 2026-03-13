({
    /**
     * Load career listings based on category
     * 
     * @param component     The Listing Career component
     */
    loadListingList : function (component, event) {
        var action = component.get("c.getListings");
        action.setParams({
            recordTypeDeveloperName : component.get("v.recordTypeDeveloperName"),
            category : component.get("v.category"),
            maxNumberOfRecords : component.get("v.maxNumberOfRecords")
        });
        action.setCallback(this, function(a) {
            var state = a.getState();

            if(state ==="SUCCESS") {
                component.set("v.listingList", a.getReturnValue());
            } 
            else if (state === "INCOMPLETE") {
                component.find('notifLib').showNotice({
                    "variant": "error",
                    "header": "Error",
                    "message": "Incomplete error."
                });
            }
            else if (state === "ERROR") {
                let error = response.getError();
                if (error && error[0] && error[0].message) {
                    component.find('notifLib').showNotice({
                        "variant": "error",
                        "header": "Error",
                        "message": error[0].message
                    });
                }
                else {
                    component.find('notifLib').showNotice({
                        "variant": "error",
                        "header": "Error",
                        "message": "Error."
                    });
                }
            }
            component.set("v.loaded", true);
        });

        $A.enqueueAction(action);
        component.set("v.loaded", false);
    }
})