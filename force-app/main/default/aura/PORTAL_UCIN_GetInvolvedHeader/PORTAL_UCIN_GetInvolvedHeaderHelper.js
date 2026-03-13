({
    /**
     * Retrieves the listings for the Header section and assigns them to appropriate attributes
     * 
     * @param  component    The GetInvolvedHeader component    
     */
	loadContentMap : function (component, event) {
        let action = component.get("c.getListingMap");
        let categoryList = component.get("v.headerCategory") + "," + component.get("v.featureCategory");
        action.setParams({
            recordTypeAPIName : "Portal_Listing",
            keys : categoryList,
            maxRecords : 999
        });
        action.setCallback(this, function(response) {
            var state = response.getState();

            if(state ==="SUCCESS") {
                const listingMapper = response.getReturnValue();
                component.set("v.headerListing", listingMapper[component.get("v.headerCategory")]);
                component.set("v.featureListing", listingMapper[component.get("v.featureCategory")]);
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