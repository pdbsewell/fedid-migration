({
    init : function(component, event, helper) {
        //Hide spinner
        //component.set('{!v.showSpinner}', false);
    },
    enquiryUpdated : function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "CHANGED") {
        } else if(eventParams.changeType === "LOADED") {
            //Auto link a course on the enquiry if appropriate
            helper.retrieveStudentDetails(component, event, helper);
            //Get course code
            component.set('v.linkedCourse', component.get('v.currentEnquiry').Course_Code__c);
            component.set('{!v.showSpinner}', false);

        } else if(eventParams.changeType === "REMOVED") {
        } else if(eventParams.changeType === "ERROR") {
        }
    },
    linkCourseData : function(component, event, helper) {
        helper.linkCourseOnCaseData(component, event, helper);
    },
    unlinkCourseData : function(component, event, helper) {
        helper.unlinkCourseOnCaseData(component, event, helper);
    },
    navigateToCourse : function(component, event, helper) {
        helper.navigateToCourseData(component, event, helper);
    }
})