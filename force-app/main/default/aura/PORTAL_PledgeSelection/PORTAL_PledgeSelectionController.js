({
    doInit : function(component, event, helper) {
        helper.getDataHelper(component, event, helper);
    },

    pledgeSelected : function(component, event, helper) {
        var selectedRows = event.getParam('selectedRows');
        if (selectedRows != null && selectedRows[0] != null && selectedRows[0].Id != null) {
            component.set("v.selectedPledgeRec", selectedRows[0]);
        }
    },

    validatePledgeSelectionInfomationSync : function(component, event, helper) {
        let MessageHandlingService = component.find("MessageHandlingService");
        var selectedPledgeRec = component.get("v.selectedPledgeRec");

        if (selectedPledgeRec == null || selectedPledgeRec.Id == null) {
            MessageHandlingService.validationError("Please make sure at least one pledge is selected.");
            return false;
        }

        return true;
    }
})