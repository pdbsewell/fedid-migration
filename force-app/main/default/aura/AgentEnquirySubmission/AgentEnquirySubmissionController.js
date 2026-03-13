({
    doInit: function(component, event, helper) {             
    	//Set Breadcrumbs - TopicMap
    	component.set("v.topicMap", new Map());
    	component.get("v.topicMap").set('1', 'Acceptance process');
		component.get("v.topicMap").set('2', 'Application Progress follow-up');
        component.get("v.topicMap").set('3', 'Confirmation of Enrolment (CoE)');
        component.get("v.topicMap").set('4', 'Details Regarding Offer');
        component.get("v.topicMap").set('5', 'Other');
        component.get("v.topicMap").set('6', 'Pending / Required documents');
        component.get("v.topicMap").set('7', 'Packaging of English Language Program');
        component.get("v.topicMap").set('8', 'Late Enrolment/Arrival');
        
        //Set Breadcrumbs - CategoryMap
        component.set("v.categoryMap", new Map());
        component.get("v.categoryMap").set('1', 'Enquiry and advise');
        component.get("v.categoryMap").set('2', 'Enquiry and advise');
        component.get("v.categoryMap").set('3', 'Enquiry and advise');
        component.get("v.categoryMap").set('4', 'Enquiry and advise');
        component.get("v.categoryMap").set('5', 'Enquiry and advise');
        component.get("v.categoryMap").set('6', 'Enquiry and advise');
        component.get("v.categoryMap").set('7', 'Enquiry and advise');
        component.get("v.categoryMap").set('8', 'Request');
        
        //Set topic and category
        component.set('v.EnquiryTopic', component.get('v.topicMap').get(component.get('v.TopicCode')));
        component.set('v.EnquiryTopicCategory', component.get('v.categoryMap').get(component.get('v.TopicCode')));
             	
        //Set Enquiry Details Section Header
        var enquiryDetailsSectionHeader;
        //Set Enquiry Description Label
        var enquiryDescriptionLabel;
        
        //Set page details
		if(component.get('v.TopicCode') == '8'){
            /*Show details for late enrolment*/
            
            enquiryDescriptionLabel = 'Reason for Late Enrolment/Arrival';
            enquiryDetailsSectionHeader = 'Late Enrolment/Arrival Details';
                        
        }else{
            /*Show details for non late enrolment*/
            
            enquiryDescriptionLabel = 'Message';
            enquiryDetailsSectionHeader = 'Enquiry Details';
        }
        
        //Set form details
        component.set('v.enquiryDescriptionLabel', enquiryDescriptionLabel);
        component.set('v.enquiryDetailsSectionHeader', enquiryDetailsSectionHeader);
                
        //Get Application Details
        helper.retrieveApplicationDetails(component, event);
    },
    handleSubmitEnquiry: function (component, event, helper) { 
        var allformfieldValid = component.find('formField').reduce(function (validSoFar, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();

            //return true if the form field has a valid value or it is not rendered on the page (has class slds-show)
            return validSoFar && inputCmp.get('v.validity').valid;
        }, true);
        
        //start spinner
        helper.show(component,event);
	        
        //Call server for creating enquiry record
        var action = component.get("c.submitAgentEnquiry");
        //Set parameters
        action.setParams({ 
            applicationId : component.get("v.ApplicationId"), 
            agencyId : component.get("v.ApplicationDetails.Agent__c"), 
            agencyCountry : component.get("v.ApplicationDetails.Agent__r.BillingCountry"), 
            applicantId : component.get("v.ApplicationDetails.Applicant__c"), 
            agentFirstName : component.get("v.agentFirstName"), 
            agentLastName : component.get("v.agentLastName"), 
            agentEmail : component.get("v.agentEmail"), 
            enquirySubject : component.get("v.enquirySubject"), 
            enquiryDescription : component.get("v.enquiryDescription"), 
            enquirySummary : component.get("v.EnquiryTopic"),
            enquiryCourseName  : component.get("v.enquiryCourseName"),
            enquiryDateOfArrival : component.get("v.enquiryDateOfArrival")
        });
        
        // Create a callback that is executed after 
        // the server-side action returns
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log("From server: " + response.getReturnValue());
                
                var toast = component.find("SuccessToast");
                $A.util.removeClass(toast, "slds-hide");
                $A.util.addClass(toast, "slds-show");
                
                var submitButton = component.find("submitbutton");
                $A.util.removeClass(submitButton, "slds-show");
                $A.util.addClass(submitButton, "slds-hide");
                                
                component.set("v.isSubmitted", true)
                
                //Stop spinner
                helper.hide(component, event);
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
        
        if(allformfieldValid){
            $A.enqueueAction(action);
        }else{
            helper.hide(component, event);
        }
    },
    checkPopulatedFields: function(component, event, helper) {
    	var allformfieldValid = component.find('formField').reduce(function (validSoFar, inputCmp) {
            //return true if the form field has a valid value or it is not rendered on the page (has class slds-show)
            return validSoFar && inputCmp.get('v.validity').valid;
        }, true);
        //Enable submit button if all form fields has been populated correctly
        component.find("submitbutton").set('v.disabled', !allformfieldValid);
    }
})