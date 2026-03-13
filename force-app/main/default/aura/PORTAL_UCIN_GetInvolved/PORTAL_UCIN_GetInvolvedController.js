({
    doInit : function(component, event, helper) {
        helper.loadVolunteerJobs(component, event, helper);
    },

    /**
     * Resets all tab appearances but the being visited, retrieves volunteer jobs if necessary, and sets active tab
     * 
     * @param component     The GetInvolved component
     * @param event         The click that caused the function call
     * @param helper        The GetInvolved helper class
     */
	goToTab : function(component, event, helper) {
        helper.clearTabs(component, helper);
        component.set("v." + event.target.getAttribute("data-componentName"), true);

        if(component.get("v.showMyOpportunities") === true) {
            component.set("v.sharing", "Me");
        } else {
            component.set("v.sharing", "All");
        }
        if(!component.get("v.showMyPreferences")) {
            helper.loadVolunteerJobs(component, event, helper);
        }

        var thisComponent = component.find(event.target.getAttribute("data-componentName"));
        helper.switchTab(thisComponent, true);
    },

    /**
     * Create a Volunteer_hours record for the opportunity
     * Opens a GetInvolvedModal when the Express Interest button is pressed
     * 
     * @param component     The GetInvolved component 
     */
    openSignupModal : function(component, event, helper) {
        let elem = event.target;
        if(!elem.id) {
            elem = elem.parentNode;
        }
        let action = component.get('c.SERVER_expressInterest');
        action.setParams({
            jobId : elem.id
        });
        action.setCallback(this, function(response){
            var state = response.getState();

            if(state ==="SUCCESS") {
                helper.loadVolunteerJobs(component, event, helper);
                $A.createComponent("c:PORTAL_UCIN_GetInvolvedModal", {}, function(content, status) {
                    if(status ==="SUCCESS") {
                        component.find('overlayLib').showCustomModal({
                            body:content,
                            showCloseButton: false,
                            closeCallback: function() {
        
                            }
                        })
                    } else {
                        console.log("ERROR");
                    }
                });
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
     * Searches Volunteer jobs using text entered into the search box
     * 
     * @param component     The GetInvolved component
     */
    searchByInterest : function(component, event, helper) {
        let searchString = component.get("v.searchText");
        if(!searchString) {
            helper.loadVolunteerJobs(component, event, helper);
        } else {
            let action = component.get('c.SERVER_searchVolunteerJob');
            action.setParams({
                searchTerms : searchString
            });
            action.setCallback(this, function(response){
                var state = response.getState();

                if(state ==="SUCCESS") {
                    let responseList = response.getReturnValue();
                    for(let i = 0; i < responseList.length; i++) {
                        if(responseList[i].Volunteer_Hours__r){
                            if(responseList[i].Volunteer_Hours__r[0].Status__c == "Web Sign Up") {
                                responseList[i].Volunteer_Hours__r[0].Status__c = "Expressed Interest";
                            } else if(responseList[i].Volunteer_Hours__r[0].Status__c == "Rejected") {
                                responseList[i].Volunteer_Hours__r[0].Status__c = "No Availability";
                            }
                        }
                        if(responseList[i].Areas_of_Interest__c) {
                            responseList[i].Areas_of_Interest__c = responseList[i].Areas_of_Interest__c.replace(/;/gi, '\n');
                        }
                        responseList[i].fullLocation = helper.createFullLocation(responseList[i]);
                    }
                    component.set("v.volunteerJobList", responseList);
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
        
    },

    /**
     * Updates the searchText attribute for use when the search button is pressed
     * 
     * @param component     The GetInvolved component
     * @param event         The triggering event
     */

    updateSearchText : function(component, event) {
        component.set("v.searchText", event.target.value);
    }
})