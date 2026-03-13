({
    doInit : function(component, event, helper) {
        
    }, 

    /**
     * Checks selected area of interest if fewer than 3 are selected
     * Unchecks any checked area of interest
     * 
     * @param component     The Bio Details component
     * @param event         The click which caused the function to trigger 
     */
    toggleCheck : function(component, event) {
        let name = event.target.id;
        let areas = component.get("v.interestAreasList");
        let count = 0;
        areas.forEach(function(area) {
            if(area.filled) {
                count++;
            }
        });
        if(count < 3) {
            for(let i = 0; i < areas.length; i++) {
                if(areas[i].label == name) {
                    areas[i].filled = !areas[i].filled;
                }
            }
        } else {
            for(let i = 0; i < areas.length; i++) {
                if(areas[i].label == name && areas[i].filled === true) {
                    areas[i].filled = !areas[i].filled;
                }
            }
            event.target.checked = false;
        }
        component.set("v.interestAreasList", areas);
    },

    /**
     * Toggle ability to edit fields on the page
     * 
     * @param component     The Bio Details component
     */
    toggleEdit : function(component, event) {
        component.set("v.isEditing", !component.get("v.isEditing"));
    },

    /**
     * Update value of the salutation field
     * 
     * @param component     The Bio Details component
     */
    updateSalutation : function(component, event) {
        component.set("v.contactMap.preferredName.Salutation__c", component.find("salutationList").get("v.value"));
    },

    /**
     * Update value of the Gender field
     * 
     * @param component     The Bio Details component
     */
    updateGender : function(component, event) {
        component.set("v.contactBioDetails.Gender__c", component.find("genderList").get("v.value"));
    }, 
	
	/**
     * Update value of the Preferred pronoun field
     * 
     * @param component     The Bio Details component
     */
    updatePronoun : function(component, event) {
        component.set("v.contactMap.contact.Pronouns_V2__c", component.find("pronounList").get("v.value"));
    },

    /**
     * Update value of the text field that changed
     * 
     * @param component     The Bio Details component
     * @param event         The field change which triggered the function
     */
    updateText : function(component, event) {
        let idToChange = event.getSource().get("v.name");
        if(idToChange == "firstNameInput") {
            component.set("v.contactMap.preferredName.First_Name__c", event.getSource().get("v.value"));
        //} else if(idToChange == "prefNameInput") {
        //    component.set("v.contactBioDetails.Preferred_Name__c", event.getSource().get("v.value"));
        } else if(idToChange == "lastNameInput") {
            component.set("v.contactMap.preferredName.Last_Name__c", event.getSource().get("v.value"));
        } else if(idToChange == "suffixInput") {
            component.set("v.contactMap.preferredName.Suffix__c", event.getSource().get("v.value"));
        } else if(idToChange == "preferredNameInput") {
            component.set("v.contactMap.contact.Preferred_Name__c", event.getSource().get("v.value"));
        }else if(idToChange == "aboutme") {
            component.set("v.userDetails.AboutMe", event.getSource().get("v.value"));
        }
    }

})