({
    doInit : function(component, event, helper) {
        helper.queryContact(component, helper);
    },

    closeModal : function(component, event, helper) {
        component.find("overlayModal").notifyClose();
    },

    SendMessage: function(component, event, helper) {
        helper.sendMessage(component, helper);
    }
})