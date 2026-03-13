({
    getUserInfo : function(component, event, helper) {
        //component.set("v.showSpinner",true);
        var action = component.get("c.isUserLoggedIn");   
        var isLoggedInUser;        
        action.setCallback(this, function(a) {
            isLoggedInUser = a.getReturnValue(); 
            if(isLoggedInUser){
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    "url": "/contact"
                });
                urlEvent.fire();
                
            }     
            else {
                component.set("v.isLoggedIn",isLoggedInUser);  
                component.set("v.isOpen",!isLoggedInUser);  
            }
        });
        var action2 = component.get("c.getSSOURL");   
        action2.setCallback(this, function(a) {
            component.set("v.URLSetting",a.getReturnValue()); 
            // component.set("v.showSpinner",false);  
        });
        var x=$A.enqueueAction(action);   
        var x2=$A.enqueueAction(action2);
    }
})