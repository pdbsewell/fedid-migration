({
    doInit : function(component, event, helper) {
        var opts = [];
        let tributeRec = component.get("v.tributeRec");
        var selectedTributeType;
        if (tributeRec != null && tributeRec.ucinn_ascendv2__Tribute_Type__c != null && tributeRec.ucinn_ascendv2__Tribute_Type__c != '') {
            selectedTributeType = tributeRec.ucinn_ascendv2__Tribute_Type__c;
        } 
        let tributeTypePicklistValues = ["","In Honor of","In Memory of"];
        for (var i = 0; i < tributeTypePicklistValues.length; i++) {
            if (tributeTypePicklistValues[i] == selectedTributeType) {
                opts.push({
                    'label': tributeTypePicklistValues[i],
                    'value': tributeTypePicklistValues[i],
                    'selected': 'true',
                    'class': 'optionClass'
                });
            }
            else {
                opts.push({
                    'label': tributeTypePicklistValues[i],
                    'value': tributeTypePicklistValues[i],
                    'class': 'optionClass'
                });
            }
        }

        component.find("inputSelectDynamic").set("v.options", opts);
    },
    deleteTribute : function(component, event, helper) {
        var tributeListItemEvent = component.getEvent("tributeListItemEvent");
        tributeListItemEvent.setParams({
            "operation": "remove",
            "source": "tributeListItem",
            "target": "tributeList",
            "index": component.get("v.tableIndexVar")
        });
        tributeListItemEvent.fire();
    },
    onSelectChange : function(component, event, helper) {
        var selected = component.find("inputSelectDynamic").get("v.value");
        component.set("v.tributeRec.ucinn_ascendv2__Tribute_Type__c", selected);
    }
})