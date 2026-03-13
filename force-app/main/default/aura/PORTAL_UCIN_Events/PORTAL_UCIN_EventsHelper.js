({
    queryEvents: function (component, event, helper, baseURL, eventTypeToPictureMap) {
        // Enqueue this action after we finish getting the map
        // Get all event list
        let action = component.get("c.getEventList");
        action.setParams({
            recordTypeAPIName : "Event",
            maxRecords : 999
        });
        action.setCallback(this, function(actionResponse) {
            var actionState = actionResponse.getState();

            if(actionState === "SUCCESS") {
                let eventList = actionResponse.getReturnValue();
                eventList.forEach(evnt => {
                    if(evnt.Areas_of_Interest__c) {
                        evnt.Areas_of_Interest__c = evnt.Areas_of_Interest__c.replace(/;/gi, '\n');
                    }
                    // Check if event's type is in the eventTypetoPictureMap
                    // If in the map, then set 'pictureSrc' field to the contentversion ID
                    if (eventTypeToPictureMap[evnt.Type__c]) {
                        evnt.pictureSrc = baseURL + '/sfc/servlet.shepherd/version/download/' + eventTypeToPictureMap[evnt.Type__c];
                        
                    }
                    evnt.fullLocation = helper.createFullLocation(evnt);

                });
                component.set("v.eventList", eventList);                     
            } 
            else if (actionState === "INCOMPLETE") {
                component.find('notifLib').showNotice({
                    "variant": "error",
                    "header": "Error",
                    "message": "Incomplete error."
                });
            }
            else if (actionState === "ERROR") {
                let error = actionResponse.getError();
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

    constructEventPictureMap: function (component, event, helper, baseURL, type) {
        // Grab map of event types to contentversionid
        let SERVER_searchEventPicture = component.get("c.SERVER_searchEventPicture");
        SERVER_searchEventPicture.setCallback(this, function(response) {
            var state = response.getState();         
            if (state === "SUCCESS") {
                let eventTypeToPictureMap = response.getReturnValue();
                if(type == "search") {
                    helper.loadEventSearch(component, event, helper, baseURL, eventTypeToPictureMap);
                } else if(type == "myEvents") {
                    helper.loadMyEventList(component, event, helper, baseURL, eventTypeToPictureMap);
                } else {
                    helper.queryEvents(component, event, helper, baseURL, eventTypeToPictureMap);
                }
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
     * Loads the list of available events
     * 
     * @param component  The Events component 
     */
    loadEventList : function (component, event, helper, type) {
        // Get baseURL
        let SERVER_getBaseUrl = component.get("c.SERVER_getBaseUrl");
        SERVER_getBaseUrl.setCallback(this, function(response) {
            var state = response.getState();         
            if (state === "SUCCESS") {
                let baseURL = response.getReturnValue();
                // Construct Event Picture Map

                helper.constructEventPictureMap(component, event, helper, baseURL, type);
                
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
     * Loads the list of events the user is going to
     * 
     * @param component  The Events component 
     */
    loadMyEventList : function (component, event, helper, baseURL, eventTypeToPictureMap) {
        let action = component.get("c.getMyEventList");
        action.setParams({
            recordTypeAPIName : "Event",
            maxRecords : 999
        });
        action.setCallback(this, function(response) {
            var state = response.getState();

            if(state ==="SUCCESS") {
                let eventWrapperList = response.getReturnValue();
                let eventList = [];
                eventWrapperList.forEach(evnt => {
                    if(evnt.eventDetails.Areas_of_Interest__c) {
                        evnt.eventDetails.Areas_of_Interest__c = evnt.eventDetails.Areas_of_Interest__c.replace(/;/gi, '\n');
                    }

                    // Check if event's type is in the eventTypetoPictureMap
                    // If in the map, then set 'pictureSrc' field to the contentversion ID
                    if (eventTypeToPictureMap[evnt.eventDetails.Type__c]) {
                        evnt.eventDetails.pictureSrc = baseURL + '/sfc/servlet.shepherd/version/download/' + eventTypeToPictureMap[evnt.eventDetails.Type__c];
                        
                    }

                    evnt.eventDetails.fullLocation = helper.createFullLocation(evnt.eventDetails);
                    evnt.eventDetails.status = evnt.status;
                    eventList.push(evnt.eventDetails);
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

    loadEventSearch : function(component, event, helper, baseURL, eventTypeToPictureMap) {
        let searchString = component.get("v.searchText");
        let action = component.get('c.SERVER_searchEvents');
        action.setParams({
            searchTerms : component.get("v.searchText")
        });
        action.setCallback(this, function(response){
            var state = response.getState();

            if(state ==="SUCCESS") {
                let responseList = response.getReturnValue();
                for(let i = 0; i < responseList.length; i++) {
                    if(responseList[i].Areas_of_Interest__c) {
                        responseList[i].Areas_of_Interest__c = responseList[i].Areas_of_Interest__c.replace(/;/gi, '\n');
                    }
                    // Check if event's type is in the eventTypetoPictureMap
                    // If in the map, then set 'pictureSrc' field to the contentversion ID
                    if (eventTypeToPictureMap[responseList[i].Type__c]) {
                        responseList[i].pictureSrc = baseURL + '/sfc/servlet.shepherd/version/download/' + eventTypeToPictureMap[responseList[i].Type__c];
                        
                    }
                    responseList[i].fullLocation = helper.createFullLocation(responseList[i]);
                }
                component.set("v.eventList", responseList);
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
        component.set("v.loaded", false);
        $A.enqueueAction(action);
        
    },

    /**
     * Resets the appearance of all tabs
     * 
     * @param component  The Events component 
     */
    clearTabs : function(component, helper) {
        component.set("v.showUpcomingEvents", false);
        component.set("v.showMyEvents", false);

        var showUpcomingEvents = component.find("showUpcomingEvents");
        helper.switchTab(showUpcomingEvents, false);

        var showMyEvents = component.find("showMyEvents");
        helper.switchTab(showMyEvents, false);
    },

    /**
     * Sets the styling of a tab depending on the value of selected
     * 
     * @param thisComponent     The tab which is to be updated
     * @param selected          Boolean whether to make the tab appear clicked or not
     */
    switchTab : function(thisComponent, selected) {
        if (selected) {
            $A.util.addClass(thisComponent, 'bg-gray');
            $A.util.addClass(thisComponent, 'text-blue');
            $A.util.addClass(thisComponent, 'border-t-4');
            $A.util.addClass(thisComponent, 'font-medium');
            $A.util.addClass(thisComponent, 'border-blue');
            $A.util.addClass(thisComponent, 'bg-gray-mon');
            $A.util.removeClass(thisComponent, 'border-b-4');
            $A.util.removeClass(thisComponent, 'border-dark-grey');
        } else {
            $A.util.removeClass(thisComponent, 'bg-gray');
            $A.util.removeClass(thisComponent, 'text-blue');
            $A.util.removeClass(thisComponent, 'border-t-4');
            $A.util.removeClass(thisComponent, 'font-medium');
            $A.util.removeClass(thisComponent, 'border-blue');
            $A.util.removeClass(thisComponent, 'bg-gray-mon');
            $A.util.addClass(thisComponent, 'border-b-4');
            $A.util.addClass(thisComponent, 'border-dark-grey');
        }
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