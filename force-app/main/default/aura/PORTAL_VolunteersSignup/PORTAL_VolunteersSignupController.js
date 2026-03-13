({
	doInit : function(component, event, helper) {
        console.log('here');
        /*var picklistAction = component.get("c.SERVER_GetLeadPicklist");

        picklistAction.setCallback(this, function(response) {
            console.log('-----------------');
            var leadPicklistValues = response.getReturnValue();
            var state = response.getState();

            console.log('result: ');
            console.log(leadPicklistValues);
            console.log('state of picklist: ' + state);

            if (state === "SUCCESS") {
                helper.setPicklistOptions(component, event, helper, leadPicklistValues['Volunteer_Skills__c'], "v.skillsOptions", null);
                helper.setPicklistOptions(component, event, helper, leadPicklistValues['Volunteer_Availability__c'], "v.availabilityOptions", null);
                //$A.enqueueAction(contactAction);
            } else {
                alert('Error');
            }
        });
        $A.enqueueAction(picklistAction);*/
        
        var contactAction = component.get("c.SERVER_getContactInfo");

        contactAction.setCallback(this, function(response) {
            //var result = response.getReturnValue();
            var result = JSON.parse(response.getReturnValue());
            var state = response.getState();
            
            //console.log('result: ');
            //console.log(result);
            //console.log('state: ' + state);  

            if (state === "SUCCESS") {
                
                if (result != null) {
                    //component.set("v.contact", result);            
                    console.log('result.contactInfo: ' + result.contactInfo);
                    console.log('result.leadPicklistValues: ' + result.leadPicklistValues);
                    
                    var leadPicklistValues = result.leadPicklistValues;
                    helper.setPicklistOptions(component, event, helper, leadPicklistValues['Volunteer_Skills__c'], "v.skillsOptions", null);
                    helper.setPicklistOptions(component, event, helper, leadPicklistValues['Volunteer_Availability__c'], "v.availabilityOptions", null);    
                    
                    if (result.contactInfo != null) {
                        component.set("v.contact", result.contactInfo);
                    }
                    else {
                        var contact = {
                            FirstName: '', 
                            LastName: '',
                            Email: '', 
                            Phone: '',
                            HomePhone: '',
                            Department: '',
                            Volunteer_Organization__c: '',
                            Volunteer_Skills__c: '',
                            Volunteer_Availability__c: '',
                            Volunteer_Notes__c: ''
                        };
                        
                        component.set("v.contact", contact);
                    }
                }
            }
            else {

            }
        });

        

       $A.enqueueAction(contactAction);
    },

	save : function(component, event, helper) {
        console.log('inside save');
        //event.preventDefault(); // Prevent default submit
        //var fields = event.getParam("fields");

        //alert('fields: ' + fields);
        
        var contact = component.get("v.contact");
        console.log('Contact = ' + contact);

        // For leads.
        contact.Department = contact.Volunteer_Organization__c;
        console.log('2');
        // This is needed if we are creating leads, as Company field is required for lead.
        // Volunteers for Salesforce code will assign contact.Department to lead.Company.
        if (!contact.Department) {
            contact.Department = 'None';
        }
        
        console.log('contact: ' + JSON.stringify(contact));
/*        
        contact.FirstName = fields["FirstName"];
        contact.LastName = fields["LastName"];
        contact.Email = fields["Email"];
        contact.HomePhone = fields["HomePhone"];
        contact.MobilePhone = fields["MobilePhone"];
        contact.Volunteer_Organization__c = fields["Volunteer_Organization__c"];
        contact.Volunteer_Skills__c = fields["Volunteer_Skills__c"];
        contact.Volunteer_Availability__c = fields["Volunteer_Availability__c"];
        contact.Volunteer_Notes__c = fields["Volunteer_Notes__c"];
*/
        var volunteerSignupAction = component.get("c.SERVER_signup");
        var contactJSON = JSON.stringify(component.get("v.contact")); 
        //alert('contact: ' + contactJSON);      
        //volunteerSignupAction.setParams({ "signupContact": component.get("v.contact") });
        volunteerSignupAction.setParams({ "signupContactJSON": contactJSON });

        volunteerSignupAction.setCallback(this, function(response) {
            console.log('volunteerSignupAction Callback');
            var result = response.getReturnValue();
            var state = response.getState();
            console.log('state of the call = ');
            console.log(state);
            console.log('Result of the server call = ');
            console.log(result);
            //alert('state: ' + state);  
            if (state === "SUCCESS") {
                //alert('toast');  
        		var toastEvent = $A.get("e.force:showToast");
        		toastEvent.setParams({"title": "Success!","message": "Thank you for signing up.","type": "success"});
                toastEvent.fire();
            }
            else {
                alert('error');
            }
        });

        $A.enqueueAction(volunteerSignupAction);
        
	},
	
    handleSuccess : function(component, event, helper) {
        		var toastEvent = $A.get("e.force:showToast");
        		toastEvent.setParams({"title": "Success!","message": "Thank you for signing up.","type": "success"});
                toastEvent.fire();
    },
    
    handleSkillsChange: function (component, event) {
        // This will contain an array of the "value" attribute of the selected options
        var selectedOptionValue = event.getParam("value");
        
        var val = selectedOptionValue.join(';');
        
        console.log("Option selected with value: " + val);
        
        component.set("v.contact.Volunteer_Skills__c", val);   
    },
    
    handleAvailabilityChange: function (component, event) {
        // This will contain an array of the "value" attribute of the selected options
        var selectedOptionValue = event.getParam("value");

        var val = selectedOptionValue.join(';');
        
        console.log("Option selected with value: " + val);        
        
        component.set("v.contact.Volunteer_Availability__c", val);
    }      
})