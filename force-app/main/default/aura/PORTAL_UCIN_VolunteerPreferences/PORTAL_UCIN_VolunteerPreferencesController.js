({
    /**
     * Retrieves the Volunteer status, roles, skills, and areas of interest for the user
     * 
     * @param  component    The Volunteer Preferences Component
     */
	doInit : function(component, event) {
		let action = component.get('c.SERVER_getVolunteerPreferences');
        action.setCallback(this, function(response){
            var state = response.getState();

            if(state ==="SUCCESS") {
                if(response.getReturnValue()) {
                    let responseObject = response.getReturnValue();
                    let roleList = [];

                    if(responseObject.volPrefs.Volunteer_Roles__c){
                        component.set('v.rolesSelected', responseObject.volPrefs.Volunteer_Roles__c.split(';'));
                    }
                    if(responseObject.volPrefs.Volunteer_Skills__c){
                        component.set('v.skillsSelected', responseObject.volPrefs.Volunteer_Skills__c.split(';'));
                    }
                    if(responseObject.volPrefs.Volunteer_Areas_of_Interest__c){
                        component.set('v.interestAreasSelected', responseObject.volPrefs.Volunteer_Areas_of_Interest__c.split(';'));
                    }
					let rolesList1 = [];
                    let rolesList2 = [];
                    let halfwayRole = Math.round(responseObject.volRoles.length/2);
                    for(let i = 0; i < responseObject.volRoles.length; i++){
                        if(i < halfwayRole){
							if(responseObject.volPrefs.Volunteer_Roles__c && responseObject.volPrefs.Volunteer_Roles__c.includes(responseObject.volRoles[i])) {
                            	rolesList1.push({'label': responseObject.volRoles[i], 'filled': true});
                        	} else {
                            	rolesList1.push({'label': responseObject.volRoles[i], 'filled': false});
                            }                            
                        } 
                        else{
                             if(responseObject.volPrefs.Volunteer_Roles__c && responseObject.volPrefs.Volunteer_Roles__c.includes(responseObject.volRoles[i])) {
                                rolesList2.push({'label': responseObject.volRoles[i], 'filled': true});
                            } else {
                                rolesList2.push({'label': responseObject.volRoles[i], 'filled': false});
                            }
                        }
                        
                    }
                    component.set('v.rolesListOne', rolesList1);
                    component.set('v.rolesListTwo', rolesList2);
                    
                    responseObject.volRoles.forEach(function(role) {
                        if(responseObject.volPrefs.Volunteer_Roles__c && responseObject.volPrefs.Volunteer_Roles__c.includes(role)) {
                            roleList.push({'label': role, 'filled': true});
                        } else {
                            roleList.push({'label': role, 'filled': false});
                        }
                    });
                    component.set('v.rolesList', roleList);

                    let skillsList1 = [];
                    let skillsList2 = [];
                    let halfway = Math.round(responseObject.volSkills.length/2);
                    for(let i = 0; i < responseObject.volSkills.length; i++){
                        if(i < halfway) {
                            if(responseObject.volPrefs.Volunteer_Skills__c && responseObject.volPrefs.Volunteer_Skills__c.includes(responseObject.volSkills[i])) {
                                skillsList1.push({'label': responseObject.volSkills[i], 'filled': true});
                            } else {
                                skillsList1.push({'label': responseObject.volSkills[i], 'filled': false});
                            }
                        } else {
                            if(responseObject.volPrefs.Volunteer_Skills__c && responseObject.volPrefs.Volunteer_Skills__c.includes(responseObject.volSkills[i])) {
                                skillsList2.push({'label': responseObject.volSkills[i], 'filled': true});
                            } else {
                                skillsList2.push({'label': responseObject.volSkills[i], 'filled': false});
                            }
                        }
                    }
                    component.set('v.skillsListOne', skillsList1);
                    component.set('v.skillsListTwo', skillsList2);
                    
                    let areasList1 = [];
                    let areasList2 = [];
                    let halfwayArea = Math.round(responseObject.volAreas.length/2);
                    for(let i = 0; i < responseObject.volAreas.length; i++){
                        if(i < halfwayArea){
                        	if(responseObject.volPrefs.Volunteer_Areas_of_Interest__c && responseObject.volPrefs.Volunteer_Areas_of_Interest__c.includes(responseObject.volAreas[i])) {
                                areasList1.push({'label': responseObject.volAreas[i], 'filled': true});
                            } else {
                                areasList1.push({'label': responseObject.volAreas[i], 'filled': false});
                            }    
                        }
                        else{
                         	if(responseObject.volPrefs.Volunteer_Areas_of_Interest__c && responseObject.volPrefs.Volunteer_Areas_of_Interest__c.includes(responseObject.volAreas[i])) {
                                areasList2.push({'label': responseObject.volAreas[i], 'filled': true});
                            } else {
                                areasList2.push({'label': responseObject.volAreas[i], 'filled': false});
                            }   
                        }
                    }
                    component.set('v.interestAreasListOne', areasList1);
                    component.set('v.interestAreasListTwo', areasList2);

                    let areasList = [];
                    responseObject.volAreas.forEach(function(area) {
                        if(responseObject.volPrefs.Volunteer_Areas_of_Interest__c && responseObject.volPrefs.Volunteer_Areas_of_Interest__c.includes(area)) {
                            areasList.push({'label': area, 'filled': true});
                        } else {
                            areasList.push({'label': area, 'filled': false});
                        }
                    });
                    component.set('v.interestAreasList', areasList);

                    if(responseObject.volPrefs.Volunteer_Status__c) {
                        component.set('v.volunteerStatus', responseObject.volPrefs.Volunteer_Status__c);
                        if(responseObject.volPrefs.Volunteer_Status__c != "Not Active - Do Not Engage") {
                            if(responseObject.volPrefs.Volunteer_Status__c == "Not Active - Withdrawn")
                            {
                                component.set("v.disableVolunteer", true);
                            } else if (responseObject.volPrefs.Volunteer_Status__c == 'Unknown') {

                            } else {
                                component.set("v.enableVolunteer", true);
                                
                            }
                        }
                    } else {
                        component.set('v.isEnabled', true);
                    }
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
        });
        $A.enqueueAction(action);
    },

    /**
     * Adds or removes a clicked Volunteer Role to the list of currently selected Volunteer roles 
     * 
     * @param component     The VolunteerPreference component
     * @param event         The box click that triggers the function
     */
    checkRoleBox : function(component, event) {
        let boxName = event.target.id;
        let currRoles = component.get('v.rolesSelected');
        if(currRoles.includes(boxName)) {
            currRoles.splice(currRoles.indexOf(boxName), 1);
        } else {
            currRoles.push(boxName);
        }
        component.set('v.rolesSelected', currRoles);
    },

    /**
     * Adds or removes a clicked Volunteer Skill to the list of currently selected Volunteer roles 
     * 
     * @param component     The VolunteerPreference component
     * @param event         The box click that triggers the function
     */
    checkSkillsBox : function(component, event) {
        let boxName = event.target.id;
        let currSkills = component.get('v.skillsSelected');
        if(currSkills.includes(boxName)) {
            currSkills.splice(currSkills.indexOf(boxName), 1);
        } else {
            currSkills.push(boxName);
        }
        component.set('v.skillsSelected', currSkills);
    },

    /**
     * Adds or removes a clicked Area of Interest to the list of currently selected Volunteer roles, limited to 3
     * 
     * @param component     The VolunteerPreference component
     * @param event         The box click that triggers the function
     */
    checkAreasBox : function(component, event) {
        let boxName = event.target.id;
        let currAreas = component.get('v.interestAreasSelected');
        if(currAreas.length < 3) {
            if(currAreas.includes(boxName)) {
                currAreas.splice(currAreas.indexOf(boxName), 1);
            } else {
                currAreas.push(boxName);
            }
            component.set('v.interestAreasSelected', currAreas);
        } else {
            if(currAreas.includes(boxName)) {
                currAreas.splice(currAreas.indexOf(boxName), 1);
            } else {
                event.target.checked = false;
            }
        }
    },

    /**
     * Sets corresponding Volunteer Status based on Radio button
     * 
     * @param component The VolunteerPreferences component
     * @param event     The radio button change
     */
    handleRadio : function(component, event) {
        let value = event.getSource().get("v.id");
        if(value == "trueRadio") {
            component.set("v.volunteerStatus", "Available");
        } else {
            component.set("v.volunteerStatus", "Not Active - Withdrawn");
        }
    },

    /**
     * Saves all changes made to the preferences
     * 
     * @param component     The VolunteerPreferences component 
     */
    savePreferences : function(component, event) {
        let action = component.get('c.SERVER_saveVolunteerPreferences');
        let rolesToSave = "";
        let skillsToSave = "";
        let areasToSave = "";
        
        component.get("v.rolesSelected").forEach(function(role) {
            rolesToSave += role + ";";
        });

        component.get("v.skillsSelected").forEach(function(skill) {
            skillsToSave += skill + ";";
        });

        component.get("v.interestAreasSelected").forEach(function(area) {
            areasToSave += area + ";";
        });

        rolesToSave = rolesToSave.replace(/;$/, '');
        //console.log(rolesToSave +" skills "+skillsToSave+" areas "+areasToSave);
        action.setParams({
            status : component.get("v.volunteerStatus"),
            roleValues : rolesToSave,
            skillValues : skillsToSave,
            areaValues : areasToSave
        });
        action.setCallback(this, function(response){
            var state = response.getState();

            if(state ==="SUCCESS") {
                
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