({
    doInit : function(component, event, helper) {

        var designationRec = component.get("v.designationRec");
        var availableDesignations = component.get("v.availableDesignations");
        var selectedDesignations = component.get("v.selectedDesignations");

        var designationOptions = [];

        var selectedDesignationIdLookupMap = {};
        var designationOptionLookupMap = {};
        for (var oneDesignation of selectedDesignations) {
            if (oneDesignation.Id != null) {
                selectedDesignationIdLookupMap[oneDesignation.Id] = oneDesignation.Name;
            }
        }

        for (var oneDesignation of availableDesignations) {
            if (oneDesignation.Id != null) {
                if (selectedDesignationIdLookupMap[oneDesignation.Id] == null) {
                    designationOptions.push(oneDesignation);
                    designationOptionLookupMap[oneDesignation] = oneDesignation.Name;
                }
            }
        }

        if (designationRec != null && designationRec.Id != null && designationOptionLookupMap[designationRec.Id] == null) {
            var withCurrentSelection = [];
            withCurrentSelection.push(designationRec);
            designationOptions = withCurrentSelection.concat(designationOptions);
        }

        component.set("v.designationOptions", designationOptions);

        if ((designationRec == null || designationRec.Id == null) && designationOptions != null && designationOptions.length > 0) {
            component.set("v.designationRec", designationOptions[0]);

            var event = component.getEvent("designationListItemEvent");
            event.setParams({
                "operation": "modify",
                "source": "designationSelectionListItem",
                "target": "designationSelectionList",
                "index": component.get("v.tableIndexVar"),
                "data": designationOptions[0]
            });
            event.fire();
        }
    },
    deleteDesignation : function(component, event, helper) {
        var event = component.getEvent("designationListItemEvent");
        event.setParams({
            "operation": "remove",
            "source": "designationSelectionListItem",
            "target": "designationSelectionList",
            "index": component.get("v.tableIndexVar")
        });
        event.fire();
    },

    designationChange : function(component, event, helper) {

        var selectedDesignationId = component.find("designationOptions").get("v.value");

        var availableDesignations = component.get("v.availableDesignations");
        var selectedDesignationRec;

        for (var oneDesignation of availableDesignations) {
            if (oneDesignation.Id == selectedDesignationId) {
                selectedDesignationRec = oneDesignation;
                break;
            }
        }

        component.set("v.designationRec", selectedDesignationRec);


        var event = component.getEvent("designationListItemEvent");
        event.setParams({
            "operation": "modify",
            "source": "designationSelectionListItem",
            "target": "designationSelectionList",
            "index": component.get("v.tableIndexVar"),
            "data": selectedDesignationRec
        });
        event.fire();
    },

    selectedDesignationsChanged : function(component, event, helper) {

        var designationRec = component.get("v.designationRec");
        var availableDesignations = component.get("v.availableDesignations");
        var selectedDesignations = component.get("v.selectedDesignations");

        if (selectedDesignations != null) {

            var designationOptions = [];

            var selectedDesignationIdLookupMap = {};
            var designationOptionLookupMap = {};
            for (var oneDesignation of selectedDesignations) {
                if (oneDesignation.Id != null) {
                    selectedDesignationIdLookupMap[oneDesignation.Id] = oneDesignation.Name;
                }
            }

            for (var oneDesignation of availableDesignations) {
                if (oneDesignation.Id != null) {
                    if (selectedDesignationIdLookupMap[oneDesignation.Id] == null) {
                        designationOptions.push(oneDesignation);
                        designationOptionLookupMap[oneDesignation] = oneDesignation.Name;
                    }
                }
            }

            if (designationRec != null && designationRec.Id != null && designationOptionLookupMap[designationRec.Id] == null) {
                var withCurrentSelection = [];
                withCurrentSelection.push(designationRec);
                designationOptions = withCurrentSelection.concat(designationOptions);
            }

            component.set("v.designationOptions", designationOptions);
        }
    }
})