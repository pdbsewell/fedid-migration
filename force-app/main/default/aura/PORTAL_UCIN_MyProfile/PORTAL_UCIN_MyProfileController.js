({
    
    doInit : function(component, event, helper) {
        helper.loadContactDetails(component, event);
    },

    /**
     * Reset appearance of all tabs except the one being clicked and set the Boolean tracking it to true
     * 
     * @param component     The MyProfile component
     * @param event         The click which caused the function call
     * @param helper        The MyProfile helper class
     */
    goToTab : function(component, event, helper) {
        // Clear all show booleans
        helper.clearTabs(component, helper);
        component.set("v." + event.target.getAttribute("data-componentName"), true);

        var thisComponent = component.find(event.target.getAttribute("data-componentName"));
        helper.switchTab(thisComponent, true);
    },

    /**
     * Converts areas of interest into a savable format and submits all savable information
     *
     * @param component     The MyProfile component
     * @param event
     * @param helper
     */
    onSave : function(component, event, helper) {
        // validate Personal Email
        helper.experianPersonalEmailValidate(component, event, helper)
            .then(result => {
                if(result){
                    if(result.confidence && result.email){
                        component.set("v.contactMap.emailMap.Personal.Name", result.email);
                        component.set("v.contactMap.emailMap.Personal.Verification_Status__c", result.confidence);
                        if(!result.didYouMean){
                            // Validate Business Email
                            helper.experianBusinessEmailValidate(component, event, helper)
                                .then(result => {
                                    if(result){
                                        if(!result.confidence && result.email){
                                            helper.throwError(component,'A business email address with correct format is required.')
                                        } else{
                                            if(result.confidence && result.email){
                                                component.set("v.contactMap.emailMap.Business.Name", result.email);
                                                component.set("v.contactMap.emailMap.Business.Verification_Status__c", result.confidence);

                                                if(!result.didYouMean){
                                                    // validate Home Phone
                                                    helper.validateMobilePhone(component, event, helper);
                                                }
                                            }else{
                                                component.set("v.contactMap.emailMap.Business.Name", '');
                                                // validate Home Phone
                                                helper.validateMobilePhone(component, event, helper);
                                            }
                                        }
                                    }
                                }).catch(error => {
                                console.error(error);
                            });
                        }
                    } else {
                        helper.throwError(component,'A personal email address with correct format is mandatory. It is required for site log in purposes.')
                    }
                }
            }).catch(error => {
            console.error(error);
        });
    },

    /**
     * For changing the profile picture
     * 
     * @param component 
     */
    toggleEdit : function(component, event, helper) {
        component.set("v.loaded", false);

        $A.createComponent("c:PORTAL_UCIN_ProfilePictureUpload", 
            {
                contactId: component.get("v.contactMap").contact.Id
            }, 
            function(content, status) {
                if(status ==="SUCCESS") {
                    component.find('overlayLib').showCustomModal({
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

    /**
     * For changing consent 
     * 
     * @param component 
     */
    toggleConsent : function(component, event) {
        component.set("v.isEditingMaster", !component.get("v.isEditingMaster"));
    },

    /**
     * Stores the value of the Directory Opt checkbox
     * 
     * @param component     The MyProfile component
     */
    toggleDirectoryOpt : function(component, event, helper) {
        component.set("v.contactMap.userSettings.Directory_Opt_In__c", !(component.get("v.contactMap.userSettings.Directory_Opt_In__c")));
    },

    /**
     * Stores the value of the Messge Opt checkbox
     * 
     * @param component     The MyProfile component
     */
    toggleMessageOpt : function(component, event, helper) {
        component.set("v.contactMap.userSettings.Messaging_Opt_In__c", !(component.get("v.contactMap.userSettings.Messaging_Opt_In__c")));
    }
})