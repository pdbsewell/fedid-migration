({
    handleConsentFormChange: function (component, event, helper) {
        var ischecked = event.getSource().get("v.checked")
        component.get("v.newCase").TemporaryConsentForm = ischecked;        
    },
    handleConsentVicGovFormChange: function (component, event, helper) {
        var ischecked = event.getSource().get("v.checked")
        component.get("v.newCase").TemporaryConsentFormVicGov = ischecked;        
    }
})