({

	doInitImpl : function(component, actionToRun, input) {
		
		// Get Course Code from URL parameters
		var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var sParameterName;
        var windowLoc = window.location.pathname;
        var courseCode = '';
        for (var i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('='); //to split the key from the value.
            for (var j = 0; j < sParameterName.length; j++) {
                if (sParameterName[j] === 'courseCode') { //get the course code from the parameter
                    courseCode = sParameterName[j+1];
                }
            }
        }
        component.set("v.courseCode", courseCode);
		
		// Retrieve Course Offerings
        var action_courseOfferingsList = component.get("c.getCourseOffering");
        action_courseOfferingsList.setParams({ "courseCode"   : component.get("v.courseCode") });
		
        action_courseOfferingsList.setCallback(this, function(a) {
        	var cos = a.getReturnValue();
            component.set("v.courseOfferings", cos);
            if(cos == null) {

               var facultyEmail = component.get("c.retrieveFacultyEmail");
               facultyEmail.setParams({ "courseCode"   : component.get("v.courseCode") });
               facultyEmail.setCallback(this, function(a) {
                    var email1 = a.getReturnValue();
                    console.log('email1=='+email1);
                    component.set("v.facultyEmail",email1);
                });
                $A.enqueueAction(facultyEmail);
                component.set("v.showInstructions", false);              
            } else {
                console.log('cos=='+cos[0].Name);

                //PRODEV-456 | 06-02-2020 | Nadula Karunaratna
                var facultyData = component.get("c.retrieveFacultyData");
                facultyData.setParams({ "courseCode"   : component.get("v.courseCode") });
                facultyData.setCallback(this, function(a) {
                    var fData = a.getReturnValue();
                    component.set("v.FacultyCustomData", fData);
                    console.log('FacultyCustomData=='+fData[0].Managing_Faculty__c);
                });
                $A.enqueueAction(facultyData);  
            }
        });
        $A.enqueueAction(action_courseOfferingsList);
	},

    retrieveCourse : function(component) {
        //Retrieve course details
        var action_courseDetails = component.get("c.getCourseDetails");
        action_courseDetails.setParams({"courseCode" : component.get("v.courseCode")});
        action_courseDetails.setCallback(this, function(a) {
            var cors = a.getReturnValue();
            if(cors != null){
                component.set("v.courseDescription", cors.Course_Description__c);
            }
        });
        $A.enqueueAction(action_courseDetails);
    },

    handleRegistrationImpl : function(cmp) {
        $A.createComponent(
            "lightning:button",
            {
                "aura:id": "findableAuraId",
                "label": "Press Me",
                "onclick": cmp.getReference("c.handlePress")
            },
            function(newButton, status, errorMessage){
                //Add the new button to the body array
                if (status === "SUCCESS") {
                    var body = cmp.get("v.enrolmentDetails");
                    body.push(newButton);
                    cmp.set("v.enrolmentDetails", body);
                }
                else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                    // Show offline error
                }
                else if (status === "ERROR") {
                    console.log("Error: " + errorMessage);
                    // Show error message
                }
            }
        );
    },

    handlePress : function(cmp) {
        alert("button pressed");
    }

})