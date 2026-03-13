({
    handleLoad : function(component, event, helper) {
        component.set("v.showSpinner", false);
    },
    handleSubmit : function(component, event, helper) {
        component.set("v.showSpinner", true);
    },
    handleSuccess : function(component, event, helper) {
        component.set("v.showSpinner", false);
        location.reload();
    }
})