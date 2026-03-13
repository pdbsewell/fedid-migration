({
    queryContact : function(component, helper) {
        var action = component.get("c.SERVER_getContactInfo");
        //console.log(component.get("v.contactId"));
        action.setParams({"contactId": component.get("v.contactId")});
        action.setCallback(this,function(response) {
            var state = response.getState();
            var result = response.getReturnValue();

            //console.log('State: ' + state);

            if(state ==="SUCCESS") {
                // Convert Date Achieved to degree year for each degree
                if (result.Contact_Qualifications__r != undefined && result.Contact_Qualifications__r.length > 0) {
                    for (var eachDegree of result.Contact_Qualifications__r) {
                        var dt = new Date(eachDegree.Date_Achieved__c);
                        eachDegree.degreeYear = dt.getFullYear();
                    }                        
                }

                // Split skills & expertise and areas of interest into arrays
                if (result.Volunteer_Areas_of_Interest__c != undefined) {
                    var array = [];
                    array = result.Volunteer_Areas_of_Interest__c.split(';');
                    result.AOIArray = array;
                }
                if (result.Volunteer_Skills__c != undefined) {
                    var array = [];
                    array = result.Volunteer_Skills__c.split(';');
                    result.SkillsArray = array;
                }

                component.set("v.contact", result);
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
    }
})