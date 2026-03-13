({
	init : function(component, event, helper) {
		
	},
	enquiryUpdated : function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "CHANGED") {
	        component.find('caseRecordLoader').reloadRecord();
        } else if(eventParams.changeType === "LOADED") {
            
            //Hide spinner on original component
    	    component.set('v.showManageContactSpinner', false);
    	    
    	    //Set if the manage contact button is called on an enquiry without a contact
            component.set('v.isNewContact', false);
            if(!component.get('v.currentEnquiry.ContactId')){
                component.set('v.isNewContact', true);
                
                //Setup search details
                helper.setupContactSearch(component, event);
            }
        } else if(eventParams.changeType === "REMOVED") {
        } else if(eventParams.changeType === "ERROR") {
        }
    },
    showModal : function(component, event, helper) {
	    //Show Modal
	    component.set('v.showModal', true);
	},
	cancelModal : function(component, event, helper) {
	    //Hide Modal
	    component.set('v.showModal', false);	
	},
	handleContactLoad : function(component, event, helper) {
	    //Hide spinner on contact manage layout
	    component.set('v.showManageEnquiryContactSpinner', false);
	},
    // 18/12/2019 - APRivera - Prod Defect Fix - Avoid duplication of Role Email Contact
    validateEmail : function(component, event, helper) {
        var monashDomains = ["climateworksaustralia.org", "hudson.org.au", "iitbmonash.org", "monash.edu", "monashcollege.edu.au", "monsu.org", "student.monash.edu"];
        var eId = component.find("contactEmail").get("v.value");
        var roleEmail;
        for (var i = 0; i < monashDomains.length; i++){
            if(eId.includes(monashDomains[i])){
                roleEmail=true;
                break;
            }
        }
        if(roleEmail){
            component.set('v.isValidEmail',false);
        }else{
            component.set('v.isValidEmail',true);
        }
    },

	handleContactSubmit : function(component, event, helper) {
	    //Show spinner
		component.set('v.showManageEnquiryContactSpinner', true);
	},
   
	handleContactError : function(component, event, helper) {       
        //Hide spinner
        component.set('v.showManageEnquiryContactSpinner', false);
	},
	handleContactSuccess : function(component, event, helper) {
	    var payload = event.getParams().response;
	    //Update the page enquiry's contact
	    component.set('v.currentEnquiry.ContactId', payload.id);
	    
	    //Save page enquiry
	    component.find("caseRecordLoader").saveRecord($A.getCallback(function(saveResult) {
            // NOTE: If you want a specific behavior(an action or UI behavior) when this action is successful 
            // then handle that in a callback (generic logic when record is changed should be handled in recordUpdated event handler)
            if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
        	    //Show success toast
        	    var toastEvent = $A.get('e.force:showToast');
                toastEvent.setParams({
                    'type': 'success',
                    'title': 'Success!',
                    'message': "Successfully updated the enquiry's contact."
                });
                toastEvent.fire();
                
        	    //Hide spinner
        		component.set('v.showManageEnquiryContactSpinner', false);
        		
        		//Hide Modal
                component.set('v.showModal', false);
            } else if (saveResult.state === "INCOMPLETE") {
                console.log("User is offline, device doesn't support drafts.");
            } else if (saveResult.state === "ERROR") {
                console.log('Problem saving record, error: ' + JSON.stringify(saveResult.error));
            } else {
                console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
            }
        }));
	},
	doContactSearch : function(component, event, helper) {
	    helper.retrieveContacts(component, event);
    },
	sortData : function(component, event, helper) {
        component.set('v.isLoading', true);
        // We use the setTimeout method here to simulate the async
        // process of the sorting data, so that user will see the
        // spinner loading when the data is being sorted.
        setTimeout(function() {
            var fieldName = event.getParam('fieldName');
            var sortDirection = event.getParam('sortDirection');
            component.set("v.sortedBy", fieldName);
            component.set("v.sortedDirection", sortDirection);
            helper.sortData(component, fieldName, sortDirection);
            component.set('v.isTableLoading', false);
        }, 0);
	},
	selectContact : function(component, event, helper) {
	    component.set('v.showSearchContactModalSpinner', true);
	    
	    //Save selected contactId
	    var selectedContactId = component.find('contactSearchTable').getSelectedRows()[0];
	    
	    console.log(selectedContactId);
	    
	    //Update the page enquiry's contact
	    component.set('v.currentEnquiry.ContactId', selectedContactId);
	    
	    //Save page enquiry
	    component.find("caseRecordLoader").saveRecord($A.getCallback(function(saveResult) {
            // NOTE: If you want a specific behavior(an action or UI behavior) when this action is successful 
            // then handle that in a callback (generic logic when record is changed should be handled in recordUpdated event handler)
            if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                //Show success toast
        	    var toastEvent = $A.get('e.force:showToast');
                toastEvent.setParams({
                    'type': 'success',
                    'title': 'Success!',
                    'message': "Successfully updated the enquiry's contact."
                });
                toastEvent.fire();
                
        	    //Hide spinner
        		component.set('v.showSearchContactModalSpinner', false);
        		
        		//Hide Modal
	            component.set('v.showModal', false);
            } else if (saveResult.state === "INCOMPLETE") {
                console.log("User is offline, device doesn't support drafts.");
            } else if (saveResult.state === "ERROR") {
                console.log('Problem saving record, error: ' + JSON.stringify(saveResult.error));
            } else {
                console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
            }
        }));
	},
	openCreateContact : function(component, event, helper) {
	    component.set('v.isNewContact', false);
	},
	openSearchContact : function(component, event, helper) {
	    component.set('v.isNewContact', true);
	},
	onContactSelect : function(component, event, helper) {
	    component.set('v.showSearchContactModalSpinner', true);
	    var eventString = JSON.stringify(event);
	    var selectedContactId = eventString.substr((eventString.search('\"Id\":\"') + 6), 18);
	    
	    //Update the page enquiry's contact
	    component.set('v.currentEnquiry.ContactId', selectedContactId);
	    
	    //Save page enquiry
	    component.find("caseRecordLoader").saveRecord($A.getCallback(function(saveResult) {
            // NOTE: If you want a specific behavior(an action or UI behavior) when this action is successful 
            // then handle that in a callback (generic logic when record is changed should be handled in recordUpdated event handler)
            if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                //Show success toast
        	    var toastEvent = $A.get('e.force:showToast');
                toastEvent.setParams({
                    'type': 'success',
                    'title': 'Success!',
                    'message': "Successfully updated the enquiry's contact."
                });
                toastEvent.fire();
                
        	    //Hide spinner
        		component.set('v.showSearchContactModalSpinner', false);
        		
        		//Hide Modal
	            component.set('v.showModal', false);
            } else if (saveResult.state === "INCOMPLETE") {
                console.log("User is offline, device doesn't support drafts.");
            } else if (saveResult.state === "ERROR") {
                console.log('Problem saving record, error: ' + JSON.stringify(saveResult.error));
            } else {
                console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
            }
        }));
	},
	copyFromEnquiry : function(component, event, helper) {
	    component.set('v.showManageEnquiryContactSpinner', true);
	    
	    //Default contact fields based on the enquiry's supplied info details
	    helper.copyFromEnquiry(component, event, helper);
	}
})