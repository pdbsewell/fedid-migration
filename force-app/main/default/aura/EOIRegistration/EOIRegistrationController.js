({
    doInit :function(component, event, helper)
    {
        console.log('in doInit');
        helper.retrieveCOInfoJS(component);
        helper.populatePicklist(component.get("c.retrieveSalutations"), component.find("title"));
        helper.populatePicklist(component.get("c.retrieveHeardFrom"), component.find("heardfrom"));

        component.set("v.errorMessage", "");
        component.set("v.newContact.title", "");
        component.set("v.newContact.firstname", "");
        component.set("v.newContact.lastname", "");
        component.set("v.newContact.jtitle", "");
        component.set("v.newContact.orga", "");
        component.set("v.newContact.pnumber", "");
        component.set("v.newContact.email", "");
        component.set("v.newContact.heardfrom", "");
        console.log('finished in doInit');
    },

    onChangeGeneralBehaviour: function(component, event, helper) {
         helper.clearError_onChange(component, event);
    },

    saveRecord: function(component, event, helper)
    {

        console.log('in save rec***'+component.get("v.hasValidationErrors"));
        helper.validateForm(component);
        console.log('in save rec***'+component.get("v.hasValidationErrors"));
        if(!component.get("v.hasValidationErrors"))
        {
            console.log('before invoking controller register');
             var eventSource = event.getSource();
             var auraId = eventSource.getLocalId();
             var foundComponent =  component.find(auraId);
             $A.util.addClass(foundComponent, 'disable');
             component.set("v.isLoading", true);
            var action_register = component.get("c.register");

            action_register.setParams({             "title"   : component.get("v.newContact.title"),
                                                    "firstName"   : component.get("v.newContact.firstname"),
                                                    "lastName"   : component.get("v.newContact.lastname"),
                                                    "jobTitle"   : component.get("v.newContact.jtitle"),
                                                    "organisation"   : component.get("v.newContact.orga"),
                                                    "phoneNumber"   : component.get("v.newContact.pnumber"),
                                                    "email" : component.get("v.newContact.email"),
                                                    "hearfrom"   : component.get("v.newContact.heardfrom"),
                                                    "coName"   : component.get("v.courseOffering.Name")

                                                  });


            action_register.setCallback(this, function(a) {
               // component.set("v.isLoading", false);
               //  window.open('/CourseRegistration/EOIThankyouvf?coName='+component.get("v.courseOffering.Name"),'_parent');
                console.log(a.getReturnValue()+'return***');
               if(a.getReturnValue()[3]!='')
                {
                    component.set("v.exception",a.getReturnValue()[3]);
                    component.set("v.isLoading", false);
                }else
                {
                    component.set("v.isLoading", false);
                    window.open('/CourseRegistration/EOIThankyouvf?coName='+component.get("v.courseOffering.Name"),'_parent');
                }
            });
            $A.enqueueAction(action_register);

            //console.log('Enquiry Id : ' + component.get("v.cont.enquiryId"));
            //console.log('Application Id : ' + component.get("v.cont.applicationId"));
            //console.log('Contact Id : ' + component.get("v.cont.contactId"));
            //console.log('Exception : ' + component.get("v.exception"));
        }
    },

    resetError: function(component, event, helper) {
        helper.resetError(component, event);
    }
})