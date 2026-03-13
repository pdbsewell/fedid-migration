({
    /**
     * Retrieves list of volunteer jobs to be displayed
     * 
     * @param  component    The get involved component
     */
    loadVolunteerJobs : function(component, event, helper) {
        let action = component.get('c.SERVER_getVolunteerJobs');
        action.setParams({
            scope : "",
            sharing : component.get("v.sharing"),
            relevance : "All",
            maxItems : "5"
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
                    responseList[i].fullLocation = helper.createFullLocation(responseList[i])
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
    },
    
    /**
     * Resets the view state of all tabs so any tab clicked will be the only tab with that appearance
     * 
     * @param  component    The GetInvolved component
     * @param  helper       This helper class 
     */
    clearTabs : function(component, helper) {
        component.set("v.showAvailableOpportunities", false);
        component.set("v.showMyOpportunities", false);
        component.set("v.showMyPreferences", false);

        let showAvailableOpportunities = component.find("showAvailableOpportunities");
        helper.switchTab(showAvailableOpportunities, false);

        let showMyOpportunities = component.find("showMyOpportunities");
        helper.switchTab(showMyOpportunities, false);

        let showMyPreferences = component.find("showMyPreferences");
        helper.switchTab(showMyPreferences, false);
	},
    
    /**
     * Updates the class of the specified tab to appear selected or unselected
     * 
     * @param {*} thisComponent     The tab which is being altered
     * @param {Boolean} selected    Whether the specified tab has been clicked
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
     * @param  volJob    The Volunteer Job which is having its location string created
     */
    createFullLocation : function(volJob) {
        let fullLocation = '';
        if(volJob.Location_Street__c) {
            if(volJob.Location_Street__c == 'Online') {
                fullLocation = 'Online';
                return fullLocation;
            }
            fullLocation += volJob.Location_Street__c;
        }
        if(volJob.Location_City__c) {
            if(fullLocation) {
                fullLocation += ', '
            }
            fullLocation += volJob.Location_City__c;
        }
        if(volJob.Country__c) {
            if(fullLocation) {
                fullLocation += ', '
            }
            fullLocation += volJob.Country__c;
        }
        return fullLocation;
    }
})