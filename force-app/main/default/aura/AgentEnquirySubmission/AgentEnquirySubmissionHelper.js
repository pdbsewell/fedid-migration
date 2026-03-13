({
	retrieveApplicationDetails : function(component, helper, event) {
		//Initialize Action
        var action = component.get("c.getApplicationDetails");
        
        //Set Id of Application
        action.setParams({ applicationId : component.get("v.ApplicationId") });

        // Create a callback that is executed after 
        // the server-side action returns
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                //Set response to a ApplicationDetails
                component.set("v.ApplicationDetails", response.getReturnValue());

                //Set Enquiry Subject
                var applicantReference;
                if(component.get('v.ApplicationDetails.Callista_Student_Id__c')){
                    applicantReference = 'Monash Student ID: ' + component.get('v.ApplicationDetails.Callista_Student_Id__c');
                }else{
                    applicantReference = 'Monash Applicant ID: ' + component.get('v.ApplicationDetails.Callista_Applicant_Id__c');
                }
                component.set("v.enquirySubject", applicantReference + ' - ' + component.get('v.ApplicationDetails.Applicant__r.Name') + ' - ' + component.get("v.topicMap").get(component.get('v.TopicCode')));
                
                this.hide(component, event);
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });

        $A.enqueueAction(action);
	},
    show: function (component, event) {
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
        $A.util.addClass(spinner, "slds-show");
    },
    hide:function (component, event) {
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-show");
        $A.util.addClass(spinner, "slds-hide");
    }
})