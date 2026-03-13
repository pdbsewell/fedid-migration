({
    // Load current profile picture
    doInit: function(component, event, helper) {
        var getBaseURL = component.get("c.SERVER_getBaseUrl");
        getBaseURL.setCallback(this, function(a) {
            component.set("v.baseURL", a.getReturnValue());
            var action = component.get("c.getProfilePictureInfoFromConstituentOrOrganization");
            action.setParams({
                recordId: component.get("v.recordId"),
            });

            action.setCallback(this, function(response) {
                var profilePictureInfoMap = response.getReturnValue();
                var actionStatus = response.getState();
                
                if (actionStatus === "SUCCESS") {
                    helper.setPictureInfo(component, helper, profilePictureInfoMap);
                } else if (actionStatus === "INCOMPLETE") {
                    console.log('incomplete');
                } else if (actionStatus == "ERROR") {
                    var errors = response.getError();
                    console.log(errors);
                }
            });
            $A.enqueueAction(action);
        });
        $A.enqueueAction(getBaseURL);
    },

    renderPicture : function(component, event, helper) {
        var profilePictureInfoMap = event.getParam("arguments").profilePictureInfoMap;

        helper.setPictureInfo(component, helper, profilePictureInfoMap);
    },
})