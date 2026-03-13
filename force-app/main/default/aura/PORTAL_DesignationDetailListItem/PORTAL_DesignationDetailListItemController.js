({
    deignationDetailRecAmountChanged : function(component, event, helper) {
        var designationDetailListItemEvent = component.getEvent("designationDetailListItemEvent");
        designationDetailListItemEvent.setParams({
            "operation": "modify",
            "source": "designationDetailListItem",
            "target": "designationDetailList",
            "index": -1
        });
        designationDetailListItemEvent.fire();
    }
})