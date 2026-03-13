({

	doInit : function(component, event, helper) {
		helper.doInitImpl(component);

		helper.retrieveCourse(component);
	},

	handleEnquiry : function(component, event, helper) {
		alert('Hang in there buddy. The Enquiry component is coming soon !!!!!');
	},

	handleWaitListing : function(component, event, helper) {

		var state = 'waitlist';
		component.set("v.state", state);
	    component.set("v.progression", "Progress: 50%");

		var selectedOffering = event.getSource().get("v.value");
	    console.log(selectedOffering);

	    // Change progress on progress bar
	    var progressBar = component.find('progressIndicator');
	    $A.util.removeClass(progressBar, 'progress25');
	    $A.util.addClass(progressBar, 'progress50');

	   var evt = $A.get("e.c:NavigateToRegistration");
          evt.setParams({ "selectedCourseOffering": selectedOffering,
           					"currentState": state});
      	evt.fire();
	},

     handleEOI : function(component, event, helper) {
		var state = 'Expression of Interest';
		component.set("v.state", state);
		var selectedOffering = event.getSource().get("v.value");
	    console.log(selectedOffering.Status__c+'***= STATUS');
        var evt = $A.get("e.c:NavigateToEOI");
      	evt.setParams({ "selectedCourseOffering": selectedOffering,
      					"currentState": state });
      	evt.fire();
	},

	handleRegistration : function(component, event, helper) {
		var state = 'register';
	    component.set("v.state", state);
	    component.set("v.progression", "Progress: 50%");

	    var selectedOffering = event.getSource().get("v.value");
	    console.log(selectedOffering);

	    // Change progress on progress bar
	    var progressBar = component.find('progressIndicator');
	    $A.util.removeClass(progressBar, 'progress25');
	    $A.util.addClass(progressBar, 'progress50');

	    var evt = $A.get("e.c:NavigateToRegistration");
      	evt.setParams({ "selectedCourseOffering": selectedOffering,
      					"currentState": state});
      	evt.fire();
	},

    NavigateToRegistrationCmp : function(component,event,helper) {
            var co = event.getParam("selectedCourseOffering");
            var state = event.getParam("currentState");
            window.open('/CourseRegistration/Registration?coName='+co.Name,'_parent');
        },
	/*NavigateToRegistrationCmp : function(component,event,helper) {
        var co = event.getParam("selectedCourseOffering");
        var state = event.getParam("currentState");
        window.open('/CourseRegistration/StdRegistration?state='+state+'&coName='+co.Name,'_parent');
    },*/

    NavigateToEOICmp : function(component,event,helper) {
        var co = event.getParam("selectedCourseOffering");
         window.open('/CourseRegistration/EOIReg?coName='+co.Name,'_parent');
     }

})