({
    myAction : function(component, event, helper) {

    },

    handleRequestClose : function(component, event) {
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();        
    }
})