({
    inputKeyUp : function(component, event, helper) {
        if (event.type == 'keyup' && event.keyCode != 13) {
            return;
        }
        
        component.set("v.enterKeyNotification", !component.get("v.enterKeyNotification"));
    }
})