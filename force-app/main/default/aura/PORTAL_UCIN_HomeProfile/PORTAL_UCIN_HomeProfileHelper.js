({
    /**
     * Retrieves the content to be displayed in the profile tile.
     * 
     * @param component     The HomeProfile component
     */
	getProfileInfo : function(component, event) {
		let action = component.get("c.SERVER_getUserInfo");
        action.setCallback(this, function(response) {
			var state = response.getState();

			if(state ==="SUCCESS") {
                let respMap = response.getReturnValue();
                if(respMap !== null){
                    component.set("v.contact", respMap['contact']);
                    component.set("v.affil", respMap['affiliations']);
                    if (respMap['contact'].Volunteer_Areas_of_Interest__c != undefined) {
                        let aOfInterests = respMap['contact'].Volunteer_Areas_of_Interest__c.split(';');
                        let areas3 = [];
                        for(let i = 0; i < aOfInterests.length; i++){
                            if(i < 3 ) {
                                areas3.push(aOfInterests[i]);
                            } else {
                                break;
                            }
                        }
                        component.set("v.areasOfInterest", areas3);
                    }
                    
                    let firstAndLastName = respMap['preferredName'].First_Name__c + ' ' + respMap['preferredName'].Last_Name__c;
                    component.set("v.firstAndLastName", firstAndLastName);
                    
                    let degrees = [];
                    if (respMap['contact'].Contact_Qualifications__r != undefined) {
                        for(let i = 0; i < respMap['contact'].Contact_Qualifications__r.length; i++){
                            if(i < 2 ) {
                                let degreeName = respMap['contact'].Contact_Qualifications__r[i].Qualification_Name__c.replace(/<[^>]+>/gi,'');
                                degrees.push({'name': degreeName, 'year' : respMap['contact'].Contact_Qualifications__r[i].Date_Achieved__c});
                            } else {
                                break;
                            }
                        }
                    }
                    
                    component.set("v.degreeList", degrees);
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
		$A.enqueueAction(action);
		component.set("v.loaded", false);
	}
})