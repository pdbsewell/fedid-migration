({
    closeModal : function(component, event, helper) {
        component.find("overlayModal").notifyClose();
    },

    doInit: function(component, event, helper) {
        helper.queryContact(component, helper);
    },

    openMessaging: function(component, event, helper) {
        component.set("v.loaded", false);

        // Dynamically create child component. This opens the popup for messaging.
        $A.createComponent("c:PORTAL_UCIN_Messaging", 
            {
                contactId: component.get("v.contactId")
            }, 
            function(content, status) {
                if(status ==="SUCCESS") {
                    component.find('overlayMessaging').showCustomModal({
                        body:content,
                        showCloseButton: false,
                        closeCallback: function() {

                        }
                    });
                } else {
                    //console.log("ERROR");
                }
                component.set("v.loaded", true);
            }
        );
    },
    
    showAllSkills: function(component, event, helper) {
        component.set("v.showAllSkills", true);
    }

})