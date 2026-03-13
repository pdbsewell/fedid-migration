({  
    doInit : function(component, event, helper) {
        helper.loadEventList(component, event, helper, "default");
    },

    /**
     * Reset the tab appearance and update the appearance of the clicked tab
     * 
     * @param component     The Events component 
     * @param event         The click which triggered the function
     */
	goToTab : function(component, event, helper) {
        // Clear all show booleans
        helper.clearTabs(component, helper);
        component.set("v." + event.target.getAttribute("data-componentName"), true);

        if(component.get("v.showUpcomingEvents") === true) {
            helper.loadEventList(component, event, helper, "default");
        } else {
            helper.loadEventList(component, event, helper, "myEvents");
        }

        var thisComponent = component.find(event.target.getAttribute("data-componentName"));
        helper.switchTab(thisComponent, true);
    },

    /**
     * Searches Event Listings using text entered into the search box
     * 
     * @param component     The Event component
     */
    searchByInterest : function(component, event, helper) {
        let searchString = component.get("v.searchText");
        if(!searchString) {
            helper.loadEventList(component, event, helper, "default");
        } else {
            helper.loadEventList(component, event, helper, "search");
        }
        // let searchString = component.get("v.searchText");
        // if(!searchString) {
        //     helper.loadEventList(component, event, helper);
        // } else {
        //     let action = component.get('c.SERVER_searchEvents');
        //     action.setParams({
        //         searchTerms : component.get("v.searchText")
        //     });
        //     action.setCallback(this, function(response){
        //         var state = response.getState();

        //         if(state ==="SUCCESS") {
        //             let responseList = response.getReturnValue();
        //             for(let i = 0; i < responseList.length; i++) {
        //                 if(responseList[i].Areas_of_Interest__c) {
        //                     responseList[i].Areas_of_Interest__c = responseList[i].Areas_of_Interest__c.replace(/;/gi, '\n');
        //                 }
        //                 responseList[i].fullLocation = helper.createFullLocation(responseList[i]);
        //             }
        //             component.set("v.eventList", responseList);
        //         } 
        //         else if (state === "INCOMPLETE") {
        //             component.find('notifLib').showNotice({
        //                 "variant": "error",
        //                 "header": "Error",
        //                 "message": "Incomplete error."
        //             });
        //         }
        //         else if (state === "ERROR") {
        //             let error = response.getError();
        //             if (error && error[0] && error[0].message) {
        //                 component.find('notifLib').showNotice({
        //                     "variant": "error",
        //                     "header": "Error",
        //                     "message": error[0].message
        //                 });
        //             }
        //             else {
        //                 component.find('notifLib').showNotice({
        //                     "variant": "error",
        //                     "header": "Error",
        //                     "message": "Error."
        //                 });
        //             }
        //         }
        //         component.set("v.loaded", true);

        //     });
        //     component.set("v.loaded", false);
        //     $A.enqueueAction(action);
        // }
        
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