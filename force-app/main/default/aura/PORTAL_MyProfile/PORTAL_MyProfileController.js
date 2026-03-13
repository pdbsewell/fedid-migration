({
	doInit : function(component, event, helper) {
        var action = component.get("c.SERVER_getUserInfo");

        action.setCallback(this, function(response) {
            

            var resultMap = response.getReturnValue();
            var state = response.getState();

            //var result = resultMap["isNewsletter"];
            
            console.log('resultMap: ' + JSON.stringify(resultMap));
            
            console.log('state: ' + state);

            if (state === "SUCCESS") {
                var contact = resultMap["contact"];
                
              	component.set("v.contact", contact);

                console.log('cont: ' + JSON.stringify(contact));
                
                // Create two copies instead of using reference to the same object.
                var originalContact = JSON.parse(JSON.stringify(resultMap["contact"]));
                
                component.set("v.originalContact", originalContact);

                console.log('originalContact: ' + JSON.stringify(originalContact));
                
                component.set("v.orginalIsDirectorySearch", resultMap["isDirectorySearch"]);  
                component.set("v.originalIsNewsletter", resultMap["isNewsletter"]);  

                component.set("v.isDirectorySearch", resultMap["isDirectorySearch"]);  
                component.set("v.isNewsletter", resultMap["isNewsletter"]);
            }
            else {
        		var toastEvent = $A.get("e.force:showToast");
        		toastEvent.setParams({"title": "Failed.","message": "Something went wrong.","type": "error"});
                toastEvent.fire();
            }
            
        });

        $A.enqueueAction(action);
	},
    
	edit : function(component, event, helper) {
        var toggleText = component.find("viewMode");
 		$A.util.addClass(toggleText, "slds-hide");
        
        var toggleText = component.find("editMode");
 		$A.util.removeClass(toggleText, "slds-hide");
    },
    
	save : function(component, event, helper) {        
                
        var action = component.get("c.SERVER_saveUserInfo");          

        action.setParams({"updatedContact": component.get("v.contact"),
                          "isDirectorySearch": component.get("v.isDirectorySearch"),
                          "isNewsletter": component.get("v.isNewsletter")});
   
        action.setCallback(this, function(response) {
            var result = response.getReturnValue();
            var state = response.getState();
            
            //alert('result: ' + JSON.stringify(result));
            //alert('state: ' + state);  

            if (state === "SUCCESS") {
                
                var toggleText = component.find("editMode");
                $A.util.addClass(toggleText, "slds-hide");
        
                var toggleText = component.find("viewMode");
                $A.util.removeClass(toggleText, "slds-hide");   
                
                component.set("v.originalContact", component.get("v.contact"));
                
                component.set("v.orginalIsDirectorySearch", component.get("v.isDirectorySearch"));  
                component.set("v.originalIsNewsletter", component.get("v.isNewsletter"));  
                
        		var toastEvent = $A.get("e.force:showToast");
        		toastEvent.setParams({"title": "Success!","message": "Thank you for updating your contact information.","type": "success"});
                toastEvent.fire();
                component.find("overlayLibVolunteerJobSignup").notifyClose();     
            }
            else {

            }
            
        });

        $A.enqueueAction(action);
    },
    
	cancel : function(component, event, helper) {
        var originalContact = component.get("v.originalContact");
        
        //alert(JSON.stringify(originalContact));
        
        // Create two copies instead of using reference to the same object.
        component.set("v.contact", JSON.parse(JSON.stringify(originalContact)));
        
        var orginalIsDirectorySearch = component.get("v.orginalIsDirectorySearch");
        var originalIsNewsletter = component.get("v.originalIsNewsletter");
        
        component.set("v.isDirectorySearch", orginalIsDirectorySearch);
        component.set("v.isNewsletter", originalIsNewsletter);
        
        
        var toggleText = component.find("editMode");
 		$A.util.addClass(toggleText, "slds-hide");

        var toggleText = component.find("viewMode");
 		$A.util.removeClass(toggleText, "slds-hide");
    },
    
    addScocialMediaAccount: function(component, event, helper) {
        console.log("here5");
        var newSocialMedia = JSON.parse(JSON.stringify(component.get("v.newSocialMedia")));
        var socialMediaList = component.get("v.socialMediaList");
        socialMediaList.push(newSocialMedia);
        component.set("v.socialMediaList", socialMediaList);
    }
})