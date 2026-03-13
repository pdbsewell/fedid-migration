({
    doInit : function(component, event, helper) {

    },
    
	cancel : function(component, event, helper) {
        //closes the modal or popover from the component
        component.find("overlayLibVolunteerReportHours").notifyClose();
	},
    
    saveHours: function (component, event, helper) {
        //event.preventDefault(); // Prevent default submit
        
    	var firstNameCheck = component.find('firstName');
        var lastNameCheck = component.find('lastName');
        var emailCheck = component.find('email');
        var startDateCheck = component.find('startDate');
        var endDateCheck = component.find('endDate');
        var hoursWorkedCheck = component.find('hoursWorked');
        
        var allChecksPassed = true;
        
        if (!firstNameCheck.get("v.validity").valid) {
            allChecksPassed = false;
            firstNameCheck.showHelpMessageIfInvalid();
        }
        
        if (!lastNameCheck.get("v.validity").valid) {
            allChecksPassed = false;
            lastNameCheck.showHelpMessageIfInvalid();
        }

        if (!emailCheck.get("v.validity").valid) {
            allChecksPassed = false;
            emailCheck.showHelpMessageIfInvalid();
        }

        if (!startDateCheck.get("v.validity").valid) {
            allChecksPassed = false;
            startDateCheck.showHelpMessageIfInvalid();
        }

        if (!endDateCheck.get("v.validity").valid) {
            allChecksPassed = false;
            endDateCheck.showHelpMessageIfInvalid();
        }

        if (!hoursWorkedCheck.get("v.validity").valid) {
            allChecksPassed = false;
            hoursWorkedCheck.showHelpMessageIfInvalid();
        }        

        if (allChecksPassed) {
            var contact = component.get("v.contact");
            var volunteerHour = component.get("v.volunteerHour");
            var volunteerJobId = component.get("v.volunteerJobId");
            var volunteerShiftId = component.get("v.volunteerShiftId");
            
            var jobStartDateTime = component.get("v.jobStartDateTime");
            var jobEndDateTime = component.get("v.jobEndDateTime");
            var hoursWorked = component.get("v.hoursWorked");
            var comments = component.get("v.comments");
            
            console.log('here1');
            
            //saveHours(Contact reportingContact, Volunteer_Hours__c vhours, String volunteerJobId, String volunteerShiftId) {        
    
            var hourAction = component.get("c.SERVER_saveVolunteerHours");
            
            console.log('contact: ' + JSON.stringify(contact));
    
            //alert('volunteerJobId: ' + volunteerJobId);
            //alert('volunteerShiftId: ' + volunteerShiftId);
    
            hourAction.setParams({"reportingContact": contact,
                                  "volunteerJobId": volunteerJobId,
                                  "volunteerShiftId": volunteerShiftId,
                                  "jobStartDateTime": jobStartDateTime,
                                  "jobEndDateTime": jobEndDateTime,
                                  "hoursWorked": hoursWorked,
                                  "comments": comments});
    
            //alert('calling saveHours()');
       
            hourAction.setCallback(this, function(response) {
                var result = response.getReturnValue();
                var state = response.getState();
                
                //alert('result: ' + JSON.stringify(result));
                //alert('state: ' + state);  
                
                if (state === "SUCCESS") {
                    //alert('result: ' + result);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({"title": "Success!","message": "Thank you for reporting your hours.","type": "success"});
                    toastEvent.fire();
                    component.find("overlayLibVolunteerReportHours").notifyClose();             
                }
                else {
                    alert('error');
                }
            });
    
            $A.enqueueAction(hourAction);
        }
    }
})