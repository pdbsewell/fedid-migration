({
    /**
     * Retrieves and maps the Listings that contain information on the home page.
     * 
     * @param component     The Home component
     */
	loadTiles : function (component, event) {
        let action = component.get("c.getListingMap");
        let categoryList = component.get("v.category1") + "," + component.get("v.category2") + 
                            ","+ component.get("v.category3") + "," + component.get("v.category4") + "," + component.get("v.category5");
        action.setParams({
            recordTypeAPIName : "Portal_Listing",
            keys : categoryList,
            maxRecords : 999
        });
        action.setCallback(this, function(response) {
            var state = response.getState();

            if(state ==="SUCCESS") {
                const listingMapper = response.getReturnValue();
                component.set("v.headerListing", listingMapper[component.get("v.category1")]);
                component.set("v.tile1Listing", listingMapper[component.get("v.category2")]);
                component.set("v.tile2Listing", listingMapper[component.get("v.category3")]);
                component.set("v.tile3Listing", listingMapper[component.get("v.category4")]);
                component.set("v.tile5Listing", listingMapper[component.get("v.category5")]);
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
    },

    loadEvents : function(component, event, helper, baseURL, eventTypeToPictureMap) {
        let action = component.get("c.getEventList");
        action.setParams({
            recordTypeAPIName : "Event",
            maxRecords : 3
        });
        action.setCallback(this, function(response) {
            var state = response.getState();

            if(state ==="SUCCESS") {
                let eventList = response.getReturnValue();
                eventList.forEach(evnt => {
                    // Check if event's type is in the eventTypetoPictureMap
                    // If in the map, then set 'pictureSrc' field to the contentversion ID
                    if (eventTypeToPictureMap[evnt.Type__c]) {
                        evnt.pictureSrc = baseURL + '/sfc/servlet.shepherd/version/download/' + eventTypeToPictureMap[evnt.Type__c];
                        
                    }
                    evnt.fullLocation = helper.createFullLocation(evnt);

                });
                component.set("v.eventList", eventList);        
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
    },

    /**
     * Loads the list of available events
     * 
     * @param component  The Events component 
     */
    getBaseURL : function (component, event, helper) {
        // Get baseURL
        let SERVER_getBaseUrl = component.get("c.SERVER_getBaseUrl");
        SERVER_getBaseUrl.setCallback(this, function(response) {
            var state = response.getState();         
            if (state === "SUCCESS") {
                let baseURL = response.getReturnValue();
                // Construct Event Picture Map

                helper.constructEventPictureMap(component, event, helper, baseURL);
                
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
        $A.enqueueAction(SERVER_getBaseUrl);
        component.set("v.loaded", false);
    },

    /**
     * Loads the ACS URL from the custom setting
     * 
     * @param component  The Events component 
     */
    getSSOACSURL : function (component, event, helper) {
        // Get Single Sign-on ACS URL
        let getLoginACSURL = component.get("c.getACSURL");
        getLoginACSURL.setCallback(this, function(response) {
            var state = response.getState();         
            if (state === "SUCCESS") {
                let authUrl = response.getReturnValue();
                component.set("v.libraryACSURL", authUrl);
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
        $A.enqueueAction(getLoginACSURL);
        component.set("v.loaded", false);
    },

    constructEventPictureMap: function (component, event, helper, baseURL) {
        // Grab map of event types to contentversionid
        let SERVER_searchEventPicture = component.get("c.SERVER_searchEventPicture");
        SERVER_searchEventPicture.setCallback(this, function(response) {
            var state = response.getState();         
            if (state === "SUCCESS") {
                let eventTypeToPictureMap = response.getReturnValue();
                helper.loadEvents(component, event, helper, baseURL, eventTypeToPictureMap);
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

        $A.enqueueAction(SERVER_searchEventPicture);
        component.set("v.loaded", false);
    },

    /**
     * Creates a single string with the concatenated location details
     * 
     * @param  eventListing    The Volunteer Job which is having its location string created
     */
    createFullLocation : function(eventListing) {
        let fullLocation = '';
        if(eventListing.Street__c) {
            fullLocation += eventListing.Street__c;
        }
        if(eventListing.City__c) {
            if(fullLocation) {
                fullLocation += ', '
            }
            fullLocation += eventListing.City__c;
        }
        if(eventListing.State__c) {
            if(fullLocation) {
                fullLocation += ', '
            }
            fullLocation += eventListing.State__c;
        }
        if(eventListing.Country__c) {
            if(fullLocation) {
                fullLocation += ', '
            }
            fullLocation += eventListing.Country__c;
        }
        return fullLocation;
    }
})